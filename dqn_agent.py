"""Deep Q-Network agent for the Pygame racing corridor.

The state vector expected by this module matches the telemetry exported by
``pygame_racing.Car``:
    1. Front ray distance to wall
    2. Rear ray distance to wall
    3. Left ray distance to wall
    4. Right ray distance to wall
    5. Distance from the car's nose to the finish line
    6. Signed angle from the car to the finish line (radians)
    7. Car orientation / heading (radians)
    8. Current forward speed (pixels per second)

The agent's objective is to reach the finish line while avoiding walls. Actions
are modeled as discrete choices that can be mapped onto keyboard events in the
game loop (see ``ACTION_MEANINGS`` below).
"""

from __future__ import annotations

import random
from collections import deque
from dataclasses import dataclass, field
from typing import Deque, Dict, Iterable, Sequence, Tuple

import torch
from torch import Tensor, nn
from torch.optim import Adam


NUM_RAY_FEATURES = 4
STATE_SIZE = 8  # rays + distance + angle + heading + speed
ACTION_MEANINGS: Tuple[str, ...] = (
    "idle",              # No throttle or steering
    "throttle",          # Accelerate straight
    "steer_left",        # Steer left without throttle
    "steer_right",       # Steer right without throttle
    "throttle_left",     # Accelerate while steering left
    "throttle_right",    # Accelerate while steering right
)


class QNetwork(nn.Module):
    """Simple MLP that maps state features to Q-values for each discrete action."""

    def __init__(self, input_dim: int, output_dim: int, hidden_sizes: Sequence[int] = (256, 256)) -> None:
        super().__init__()
        layers = []
        last_dim = input_dim
        for hidden_dim in hidden_sizes:
            layers.append(nn.Linear(last_dim, hidden_dim))
            layers.append(nn.ReLU())
            last_dim = hidden_dim
        layers.append(nn.Linear(last_dim, output_dim))
        self.model = nn.Sequential(*layers)

    def forward(self, x: Tensor) -> Tensor:  # noqa: D401 - standard NN forward pass
        return self.model(x)


@dataclass
class DQNConfig:
    gamma: float = 0.99
    lr: float = 3e-4
    batch_size: int = 128
    buffer_size: int = 100_000
    tau: float = 5e-3
    epsilon_start: float = 1.0
    epsilon_final: float = 0.05
    epsilon_decay: float = 5e-5  # per training step
    device: str = "cpu"
    hidden_sizes: Sequence[int] = field(default_factory=lambda: (256, 256))


class ReplayBuffer:
    """FIFO buffer storing (state, action, reward, next_state, done) tuples."""

    def __init__(self, capacity: int, state_dim: int) -> None:
        self.capacity = capacity
        self.state_dim = state_dim
        self.buffer: Deque[Tuple[Tensor, int, float, Tensor, bool]] = deque(maxlen=capacity)

    def push(self, state: Tensor, action: int, reward: float, next_state: Tensor, done: bool) -> None:
        self.buffer.append((state.detach().clone(), int(action), float(reward), next_state.detach().clone(), bool(done)))

    def sample(self, batch_size: int, device: torch.device) -> Tuple[Tensor, Tensor, Tensor, Tensor, Tensor]:
        batch = random.sample(self.buffer, batch_size)
        states, actions, rewards, next_states, dones = zip(*batch)
        return (
            torch.stack(states).to(device),
            torch.tensor(actions, dtype=torch.long, device=device),
            torch.tensor(rewards, dtype=torch.float32, device=device),
            torch.stack(next_states).to(device),
            torch.tensor(dones, dtype=torch.float32, device=device),
        )

    def __len__(self) -> int:
        return len(self.buffer)


class DQNAgent:
    """Deep Q-Network agent tailored to the racing corridor telemetry."""

    def __init__(self, config: DQNConfig | None = None) -> None:
        self.config = config or DQNConfig()
        self.device = torch.device(self.config.device)
        self.state_dim = STATE_SIZE
        self.action_dim = len(ACTION_MEANINGS)

        self.policy_net = QNetwork(self.state_dim, self.action_dim, self.config.hidden_sizes).to(self.device)
        self.target_net = QNetwork(self.state_dim, self.action_dim, self.config.hidden_sizes).to(self.device)
        self.target_net.load_state_dict(self.policy_net.state_dict())
        self.target_net.eval()

        self.optimizer = Adam(self.policy_net.parameters(), lr=self.config.lr)
        self.memory = ReplayBuffer(self.config.buffer_size, self.state_dim)

        self.epsilon = self.config.epsilon_start
        self.training_steps = 0

    def select_action(self, state: Tensor, deterministic: bool = False) -> int:
        """Epsilon-greedy policy over the current Q-network."""
        state = state.to(self.device)
        if deterministic or random.random() > self.epsilon:
            with torch.no_grad():
                q_values = self.policy_net(state.unsqueeze(0))
            return int(torch.argmax(q_values, dim=1).item())
        return random.randrange(self.action_dim)

    def store_transition(self, state: Tensor, action: int, reward: float, next_state: Tensor, done: bool) -> None:
        self.memory.push(state, action, reward, next_state, done)

    def train_step(self) -> None:
        if len(self.memory) < self.config.batch_size:
            return

        states, actions, rewards, next_states, dones = self.memory.sample(self.config.batch_size, self.device)

        # Current Q estimates
        q_values = self.policy_net(states).gather(1, actions.view(-1, 1)).squeeze(1)

        with torch.no_grad():
            next_q = self.target_net(next_states).max(1)[0]
            target_q = rewards + (1.0 - dones) * self.config.gamma * next_q

        loss = nn.functional.mse_loss(q_values, target_q)
        self.optimizer.zero_grad(set_to_none=True)
        loss.backward()
        nn.utils.clip_grad_norm_(self.policy_net.parameters(), 5.0)
        self.optimizer.step()

        self._soft_update_target()
        self._decay_epsilon()

    def _soft_update_target(self) -> None:
        with torch.no_grad():
            for target_param, policy_param in zip(self.target_net.parameters(), self.policy_net.parameters()):
                target_param.data.copy_(
                    self.config.tau * policy_param.data + (1.0 - self.config.tau) * target_param.data
                )

    def _decay_epsilon(self) -> None:
        if self.epsilon > self.config.epsilon_final:
            self.epsilon -= self.config.epsilon_decay
            self.epsilon = max(self.epsilon, self.config.epsilon_final)

    def save(self, path: str) -> None:
        torch.save(
            {
                "policy_state_dict": self.policy_net.state_dict(),
                "target_state_dict": self.target_net.state_dict(),
                "optimizer_state_dict": self.optimizer.state_dict(),
                "epsilon": self.epsilon,
                "config": self.config,
            },
            path,
        )

    def load(self, path: str) -> None:
        checkpoint = torch.load(path, map_location=self.device)
        self.policy_net.load_state_dict(checkpoint["policy_state_dict"])
        self.target_net.load_state_dict(checkpoint["target_state_dict"])
        self.optimizer.load_state_dict(checkpoint["optimizer_state_dict"])
        self.epsilon = checkpoint.get("epsilon", self.epsilon)


def build_state_vector(
    ray_distances: Dict[str, float],
    distance_to_finish: float,
    angle_to_finish_rad: float,
    orientation_rad: float,
    speed: float,
    *,
    max_sensor_range: float,
    max_finish_distance: float,
    max_speed: float,
) -> Tensor:
    """Create a normalized feature tensor matching the state layout.

    Args:
        ray_distances: Dict with ``front``, ``rear``, ``left``, ``right`` keys.
        distance_to_finish: Euclidean distance from car to finish line (pixels).
        angle_to_finish_rad: Signed bearing difference to finish line (radians).
        orientation_rad: Car heading within [-pi, pi].
        speed: Forward speed (pixels per second).
        max_sensor_range: Maximum measurable ray distance for normalization.
        max_finish_distance: Maximum relevant distance to finish line.
        max_speed: Maximum achievable speed used to scale the feature.
    """

    def clamp_norm(value: float, max_value: float) -> float:
        return max(0.0, min(1.0, value / max_value if max_value > 0 else 0.0))

    front = clamp_norm(ray_distances.get("front", 0.0), max_sensor_range)
    rear = clamp_norm(ray_distances.get("rear", 0.0), max_sensor_range)
    left = clamp_norm(ray_distances.get("left", 0.0), max_sensor_range)
    right = clamp_norm(ray_distances.get("right", 0.0), max_sensor_range)
    distance = clamp_norm(distance_to_finish, max_finish_distance)
    angle = torch.tanh(torch.tensor([angle_to_finish_rad], dtype=torch.float32)).item()  # [-1, 1]
    heading = torch.sin(torch.tensor([orientation_rad], dtype=torch.float32)).item()
    speed_norm = clamp_norm(speed, max_speed)

    state = torch.tensor(
        [front, rear, left, right, distance, angle, heading, speed_norm],
        dtype=torch.float32,
    )
    return state

