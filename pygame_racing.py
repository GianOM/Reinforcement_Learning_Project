import math
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional
import asyncio

import pygame
from torch import Tensor

from dqn_agent import ACTION_MEANINGS, DQNAgent, build_state_vector
from w_socket_Manager import start_server, send_message

WINDOW_WIDTH = 900
WINDOW_HEIGHT = 700
FPS = 60

CORRIDOR_WIDTH = 260
FINISH_LINE_Y = 80

BG_COLOR = (15, 15, 20)
CORRIDOR_COLOR = (45, 45, 45)
WALL_COLOR = (90, 10, 10)
FINISH_COLOR = (250, 225, 0)
CHECKPOINT_COLOR = (120, 200, 255)
TEXT_COLOR = (240, 240, 240)
RAY_COLOR = (120, 220, 255)

AI_CONTROL_ENABLED = True
TRAIN_AGENT = False
TRACK_TYPE = "uturn"  # change to "uturn" for the U-turn scene

MAX_SENSOR_RANGE = WINDOW_HEIGHT
BASE_MAX_FINISH_DISTANCE = int(WINDOW_HEIGHT * 1.5)

REWARD_DISTANCE_SCALE = 0.02
REWARD_SPEED_SCALE = 0.001
REWARD_CRASH = -5.0
REWARD_FINISH = 10.0
CHECKPOINT_REWARD = 5.0

CORRIDOR_LEFT = (WINDOW_WIDTH - CORRIDOR_WIDTH) / 2
CORRIDOR_RECT = pygame.Rect(CORRIDOR_LEFT, 0, CORRIDOR_WIDTH, WINDOW_HEIGHT)

ACTION_CONTROL_MAP = {
    0: (False, 0.0),   # idle
    1: (True, 0.0),    # throttle
    2: (False, 1.0),   # steer left
    3: (False, -1.0),  # steer right
    4: (True, 1.0),    # throttle left
    5: (True, -1.0),   # throttle right
}

MODEL_DIR = Path("Model")
MODEL_DIR.mkdir(parents=True, exist_ok=True)


def build_track_config(track_type: str) -> Dict[str, Any]:
    """Create geometry and checkpoints for supported scenes."""
    track_lower = track_type.lower()
    spawn_position = pygame.Vector2(WINDOW_WIDTH / 2, WINDOW_HEIGHT - 120)
    spawn_heading = 0.0
    rects: list[pygame.Rect] = []
    checkpoints: list[Dict[str, Any]] = []

    if track_lower == "uturn":
        top_margin = 70
        leg_height = WINDOW_HEIGHT - top_margin - 90
        gap_width = int(CORRIDOR_WIDTH * 2.0)
        left_x = int(WINDOW_WIDTH / 2 - gap_width / 2 - CORRIDOR_WIDTH)
        right_x = int(WINDOW_WIDTH / 2 + gap_width / 2)

        right_rect = pygame.Rect(right_x, top_margin, CORRIDOR_WIDTH, leg_height)
        left_rect = pygame.Rect(left_x, top_margin, CORRIDOR_WIDTH, leg_height + 40)
        top_rect = pygame.Rect(left_rect.left, top_margin, right_rect.right - left_rect.left, CORRIDOR_WIDTH)

        rects = [right_rect, top_rect, left_rect]

        top_checkpoint_height = 18
        top_checkpoint_rect = pygame.Rect(
            left_rect.left,
            top_rect.bottom - top_checkpoint_height,
            top_rect.width,
            top_checkpoint_height,
        )
        finish_rect = pygame.Rect(
            left_rect.left,
            left_rect.bottom - 18,
            left_rect.width,
            18,
        )

        checkpoints.append(
            {
                "name": "top",
                "rect": top_checkpoint_rect,
                "orientation": "horizontal",
                "reward": CHECKPOINT_REWARD,
                "is_finish": False,
            }
        )
        checkpoints.append(
            {
                "name": "finish",
                "rect": finish_rect,
                "orientation": "horizontal",
                "reward": REWARD_FINISH,
                "is_finish": True,
            }
        )

        spawn_position = pygame.Vector2(right_rect.centerx, right_rect.bottom - 40)
    else:
        corridor_rect = CORRIDOR_RECT.copy()
        rects = [corridor_rect]
        finish_rect = pygame.Rect(corridor_rect.left, FINISH_LINE_Y - 8, corridor_rect.width, 16)
        checkpoints.append(
            {
                "name": "finish",
                "rect": finish_rect,
                "orientation": "horizontal",
                "reward": REWARD_FINISH,
                "is_finish": True,
            }
        )

    finish_target = pygame.Vector2(checkpoints[-1]["rect"].centerx, checkpoints[-1]["rect"].centery)
    max_finish_distance = max(
        BASE_MAX_FINISH_DISTANCE,
        finish_target.distance_to(spawn_position) + CORRIDOR_WIDTH,
    )

    return {
        "type": track_lower,
        "rects": rects,
        "checkpoints": checkpoints,
        "spawn_position": spawn_position,
        "spawn_heading": spawn_heading,
        "max_finish_distance": max_finish_distance,
    }


TRACK_CONFIG = build_track_config(TRACK_TYPE)


class Car:
    def __init__(self) -> None:
        self.acceleration = 320.0  # pixels per second^2
        self.max_speed = 420.0     # pixels per second
        self.turn_speed = 160.0    # degrees per second
        self.coast_decel = 220.0   # passive slowdown

        self.image = pygame.Surface((36, 58), pygame.SRCALPHA)
        self._paint_car()
        self.collision_radius = (self.image.get_width() ** 2 + self.image.get_height() ** 2) ** 0.5 / 2
        self.front_extent = self.image.get_height() / 2
        self.side_extent = self.image.get_width() / 2

        self.position = pygame.Vector2()
        self.velocity = pygame.Vector2()
        self.heading_deg = 0.0
        self.speed = 0.0
        self.ray_distances = {"front": 0.0, "rear": 0.0, "left": 0.0, "right": 0.0}
        self.ray_origins: Dict[str, pygame.Vector2] = {}
        self.ray_endpoints: Dict[str, pygame.Vector2] = {}
        self.spawn_position = pygame.Vector2(WINDOW_WIDTH / 2, WINDOW_HEIGHT - 120)
        self.spawn_heading = 0.0
        self.reset()

    def _paint_car(self) -> None:
        body_rect = self.image.get_rect()
        pygame.draw.rect(self.image, (220, 220, 220), body_rect, border_radius=10)
        pygame.draw.rect(self.image, (50, 120, 255), (8, 4, body_rect.width - 16, 18), border_radius=6)
        pygame.draw.rect(self.image, (255, 60, 60), (body_rect.width // 2 - 6, body_rect.height - 18, 12, 12), border_radius=4)

    def set_spawn(self, position: pygame.Vector2, heading_deg: float) -> None:
        self.spawn_position = position.copy()
        self.spawn_heading = heading_deg
        self.reset()

    def reset(self) -> None:
        self.position.update(self.spawn_position.x, self.spawn_position.y)
        self.heading_deg = self.spawn_heading
        self.speed = 0.0
        self.velocity.update(0, 0)
        for key in self.ray_distances:
            self.ray_distances[key] = 0.0
        self.ray_origins.clear()
        self.ray_endpoints.clear()

    def update(
        self,
        keys: pygame.key.ScancodeWrapper | None,
        dt: float,
        control_override: tuple[bool, float] | None = None,
    ) -> None:
        if control_override is not None:
            accelerating, turn_input = control_override
        else:
            accelerating = bool(keys[pygame.K_w]) if keys else False
            turn_input = float(keys[pygame.K_a]) - float(keys[pygame.K_d]) if keys else 0.0

        self._apply_acceleration(accelerating, dt)
        self._apply_turning(turn_input, dt)
        forward_vector = self.forward_vector()
        self.velocity = forward_vector * self.speed
        self.position += self.velocity * dt

    def _apply_acceleration(self, accelerating: bool, dt: float) -> None:
        if accelerating:
            self.speed += self.acceleration * dt
        else:
            self.speed -= self.coast_decel * dt

        if self.speed < 0.0:
            self.speed = 0.0
        if self.speed > self.max_speed:
            self.speed = self.max_speed

    def _apply_turning(self, turn_input: float, dt: float) -> None:
        if abs(turn_input) > 0.0 and self.speed > 30.0:
            turn_strength = self.speed / self.max_speed
            self.heading_deg += turn_input * self.turn_speed * turn_strength * dt

    def forward_vector(self) -> pygame.Vector2:
        return pygame.Vector2(0, -1).rotate(-self.heading_deg)

    def front_position(self) -> pygame.Vector2:
        return self.position + self.forward_vector() * self.front_extent

    def orientation_radians(self) -> float:
        rad = math.radians(self.heading_deg)
        return (rad + math.pi) % (2 * math.pi) - math.pi

    def update_rays(self, track_config: Dict[str, Any]) -> None:
        forward = self.forward_vector()
        right = forward.rotate(90)
        directions = {
            "front": forward,
            "rear": -forward,
            "left": -right,
            "right": right,
        }
        extents = {
            "front": self.front_extent,
            "rear": self.front_extent,
            "left": self.side_extent,
            "right": self.side_extent,
        }

        for name, vector in directions.items():
            if vector.length_squared() == 0:
                continue
            dir_vec = vector.normalize()
            origin = self.position + dir_vec * extents[name]
            distance, endpoint = self._distance_to_track_boundary(origin, dir_vec, track_config)

            self.ray_distances[name] = distance
            self.ray_origins[name] = origin
            self.ray_endpoints[name] = endpoint

    def _distance_to_track_boundary(
        self,
        origin: pygame.Vector2,
        direction: pygame.Vector2,
        track_config: Dict[str, Any],
    ) -> tuple[float, pygame.Vector2]:
        max_distance = max(WINDOW_WIDTH, WINDOW_HEIGHT) * 2
        step = 4.0
        distance = 0.0
        point = origin.copy()
        while distance < max_distance:
            point += direction * step
            distance += step
            if not _point_in_track(point, track_config):
                return distance, point
        return float("inf"), origin + direction * max_distance

    def draw(self, surface: pygame.Surface) -> None:
        rotated = pygame.transform.rotozoom(self.image, self.heading_deg, 1.0)
        rect = rotated.get_rect(center=self.position)
        surface.blit(rotated, rect)

    def draw_rays(self, surface: pygame.Surface) -> None:
        if not self.ray_origins:
            return
        for name in ("front", "right", "rear", "left"):
            if name in self.ray_origins and name in self.ray_endpoints:
                pygame.draw.line(surface, RAY_COLOR, self.ray_origins[name], self.ray_endpoints[name], 2)
                pygame.draw.circle(surface, RAY_COLOR, self.ray_endpoints[name], 3)


def draw_track(surface: pygame.Surface, track_config: Dict[str, Any]) -> None:
    surface.fill(BG_COLOR)
    for rect in track_config["rects"]:
        pygame.draw.rect(surface, CORRIDOR_COLOR, rect)
        pygame.draw.rect(surface, WALL_COLOR, rect, width=4)
    for checkpoint in track_config["checkpoints"]:
        color = FINISH_COLOR if checkpoint.get("is_finish") else CHECKPOINT_COLOR
        orientation = checkpoint.get("orientation", "horizontal")
        _draw_striped_band(surface, checkpoint["rect"], orientation, color)


def _draw_striped_band(surface: pygame.Surface, rect: pygame.Rect, orientation: str, color: tuple[int, int, int]) -> None:
    step = 20
    if orientation == "vertical":
        for i in range(0, rect.height, step):
            tile_color = color if (i // step) % 2 == 0 else (30, 30, 30)
            stripe = pygame.Rect(
                rect.left,
                rect.top + i,
                rect.width,
                min(step, rect.height - i),
            )
            pygame.draw.rect(surface, tile_color, stripe)
    else:
        for i in range(0, rect.width, step):
            tile_color = color if (i // step) % 2 == 0 else (30, 30, 30)
            stripe = pygame.Rect(
                rect.left + i,
                rect.top,
                min(step, rect.width - i),
                rect.height,
            )
            pygame.draw.rect(surface, tile_color, stripe)


def action_controls(action_index: int) -> tuple[bool, float]:
    return ACTION_CONTROL_MAP.get(action_index, (False, 0.0))


def _point_in_track(point: pygame.Vector2, track_config: Dict[str, Any]) -> bool:
    return any(rect.collidepoint(point.x, point.y) for rect in track_config["rects"])


def check_wall_collision(car: Car, track_config: Dict[str, Any]) -> bool:
    forward = car.forward_vector()
    right = forward.rotate(90)
    samples = [
        car.position,
        car.front_position(),
        car.position - forward * car.front_extent,
        car.position + right.normalize() * car.side_extent,
        car.position - right.normalize() * car.side_extent,
    ]
    return not all(_point_in_track(point, track_config) for point in samples)


def get_checkpoint_target(track_config: Dict[str, Any], checkpoint_progress: int) -> pygame.Vector2:
    checkpoints = track_config["checkpoints"]
    if not checkpoints:
        return pygame.Vector2()
    index = min(max(checkpoint_progress, 0), len(checkpoints) - 1)
    rect = checkpoints[index]["rect"]
    return pygame.Vector2(rect.centerx, rect.centery)


def track_distance_to_target(car: Car, track_config: Dict[str, Any], checkpoint_progress: int) -> float:
    target = get_checkpoint_target(track_config, checkpoint_progress)
    return car.front_position().distance_to(target)


def track_angle_to_target(car: Car, track_config: Dict[str, Any], checkpoint_progress: int) -> float:
    front = car.front_position()
    target = get_checkpoint_target(track_config, checkpoint_progress)
    to_target = target - front
    if to_target.length_squared() == 0.0:
        return 0.0
    to_target = to_target.normalize()
    forward = car.forward_vector().normalize()
    dot = max(-1.0, min(1.0, forward.dot(to_target)))
    det = forward.x * to_target.y - forward.y * to_target.x
    return math.atan2(det, dot)


def check_checkpoint_hit(car: Car, track_config: Dict[str, Any], checkpoint_progress: int) -> bool:
    checkpoints = track_config["checkpoints"]
    if checkpoint_progress >= len(checkpoints):
        return False
    rect = checkpoints[checkpoint_progress]["rect"]
    return rect.collidepoint(car.front_position())


def build_agent_state(car: Car, track_config: Dict[str, Any], checkpoint_progress: int) -> Tensor:
    return build_state_vector(

        #PARAMETROS DE ENTRADA DO CARRO
        ray_distances=car.ray_distances,

        distance_to_finish = track_distance_to_target(car, track_config, checkpoint_progress),

        angle_to_finish_rad = track_angle_to_target(car, track_config, checkpoint_progress),

        orientation_rad=car.orientation_radians(),

        speed=car.speed,

        #max_sensor_range=MAX_SENSOR_RANGE,

        #max_finish_distance=track_config["max_finish_distance"],

        #max_speed=car.max_speed,
    )


def compute_reward(
    previous_distance: float,
    current_distance: float,
    speed: float,
    crashed: bool,
    finished: bool,
    dt: float,
    checkpoint_bonus: float = 0.0,
) -> float:
    reward = REWARD_DISTANCE_SCALE * (previous_distance - current_distance)
    reward += REWARD_SPEED_SCALE * speed * dt
    if crashed:
        reward += REWARD_CRASH
    if finished:
        reward += REWARD_FINISH
    reward += checkpoint_bonus
    return reward


def draw_hud(
    surface: pygame.Surface,
    font: pygame.font.Font,
    state: str,
    car: Car,
    ai_enabled: bool,
    training_enabled: bool,
    action_label: str,
    track_config: Dict[str, Any],
    checkpoint_progress: int,
) -> None:
    instructions = "W: throttle  |  A/D: steer  |  P: reset  |  M: toggle AI  |  T: toggle train"
    text = font.render(instructions, True, TEXT_COLOR)
    surface.blit(text, (20, WINDOW_HEIGHT - 40))

    if state == "running":
        status = "Reach the finish line without touching the walls!"
    elif state == "finished":
        status = "Finished! Press P to reset."
    else:
        status = "Crash! Press P to try again."

    status_text = font.render(status, True, TEXT_COLOR)
    surface.blit(status_text, (20, 20))

    def fmt(label: str) -> str:
        value = car.ray_distances.get(label)
        if value is None or value == float("inf"):
            return "inf"
        return f"{int(value):3d}px"

    ai_status = f"AI: {'ON' if ai_enabled else 'OFF'}  Training: {'ON' if training_enabled else 'OFF'}  Scene: {track_config['type']}"
    ai_text = font.render(ai_status, True, TEXT_COLOR)
    surface.blit(ai_text, (20, 80))

    action_text = font.render(f"AI action: {action_label}", True, TEXT_COLOR)
    surface.blit(action_text, (20, 108))

    sensor_text = f"Front {fmt('front')}  Rear {fmt('rear')}  Left {fmt('left')}  Right {fmt('right')}"
    sensor_surface = font.render(sensor_text, True, TEXT_COLOR)
    surface.blit(sensor_surface, (20, 52))

    checkpoints = track_config["checkpoints"]
    if checkpoints:
        total = len(checkpoints)
        if checkpoint_progress >= total and state == "finished":
            checkpoint_text = "Checkpoints: complete"
        else:
            target_index = min(checkpoint_progress, total - 1)
            target_name = checkpoints[target_index]["name"]
            checkpoint_text = f"Target: {target_name} ({min(checkpoint_progress + 1, total)}/{total})"
        cp_surface = font.render(checkpoint_text, True, TEXT_COLOR)
        surface.blit(cp_surface, (20, 136))


def save_agent_checkpoint(agent: DQNAgent, reason: str) -> None:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = MODEL_DIR / f"{timestamp}_{reason}.pth"
    agent.save(str(filename))


def main() -> None:
    pygame.init()
    screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
    pygame.display.set_caption("Pygame Racing Corridor")
    clock = pygame.time.Clock()
    font = pygame.font.SysFont("consolas", 22)

    track_config = TRACK_CONFIG
    car = Car()
    car.set_spawn(track_config["spawn_position"], track_config["spawn_heading"])
    car.update_rays(track_config)

    game_state = "running"  # running, crashed, finished
    ai_control = AI_CONTROL_ENABLED
    training_enabled = TRAIN_AGENT
    agent = DQNAgent()
    checkpoint_progress = 0  # index of next checkpoint to reach
    last_distance = track_distance_to_target(car, track_config, checkpoint_progress)
    last_action_label = "Manual"

    while True:
        dt = clock.tick(FPS) / 1000.0
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                save_agent_checkpoint(agent, "session")
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_p:
                    car.reset()
                    car.update_rays(track_config)
                    checkpoint_progress = 0
                    last_distance = track_distance_to_target(car, track_config, checkpoint_progress)
                    game_state = "running"
                elif event.key == pygame.K_m:
                    ai_control = not ai_control
                    if not ai_control:
                        last_action_label = "Manual"
                    checkpoint_progress = 0
                    last_distance = track_distance_to_target(car, track_config, checkpoint_progress)
                elif event.key == pygame.K_t:
                    training_enabled = not training_enabled

        keys = pygame.key.get_pressed()
        action_index: Optional[int] = None
        state_tensor: Optional[Tensor] = None
        control_override = None

        if ai_control and game_state == "running":
            #Constroi o vetor de Features
            state_tensor = build_agent_state(car, track_config, checkpoint_progress)

            #Alimenta o modelo para escolher uma saida
            action_index = agent.select_action(state_tensor, deterministic=not training_enabled)


            control_override = action_controls(action_index)
            last_action_label = ACTION_MEANINGS[action_index]


        elif not ai_control:
            last_action_label = "Manual"

        input_keys = keys if control_override is None else None
        if game_state == "running":
            car.update(input_keys, dt, control_override)

        car.update_rays(track_config)

        crashed = False
        finished = False

        if game_state == "running" and check_wall_collision(car, track_config):
            game_state = "crashed"
            crashed = True

        checkpoint_bonus = 0.0
        current_distance = track_distance_to_target(car, track_config, checkpoint_progress)
        current_distance_after = current_distance
        if (
            game_state == "running"
            and not crashed
            and checkpoint_progress < len(track_config["checkpoints"])
            and check_checkpoint_hit(car, track_config, checkpoint_progress)
        ):
            checkpoint = track_config["checkpoints"][checkpoint_progress]
            checkpoint_bonus = checkpoint.get("reward", 0.0)
            checkpoint_progress += 1
            if checkpoint.get("is_finish") or checkpoint_progress >= len(track_config["checkpoints"]):
                finished = True
            current_distance_after = track_distance_to_target(car, track_config, checkpoint_progress)
        else:
            current_distance_after = current_distance

        if finished and game_state == "running":
            game_state = "finished"

        if ai_control and state_tensor is not None and action_index is not None:
            next_state = build_agent_state(car, track_config, checkpoint_progress)
            reward = compute_reward(
                last_distance,
                current_distance,
                car.speed,
                crashed,
                finished,
                dt,
                checkpoint_bonus,
            )
            done = crashed or finished
            agent.store_transition(state_tensor, action_index, reward, next_state, done)
            if training_enabled:
                agent.train_step()
            last_distance = (
                track_distance_to_target(car, track_config, checkpoint_progress) if done else current_distance_after
            )
            if done:
                car.reset()
                car.update_rays(track_config)
                checkpoint_progress = 0
                last_distance = track_distance_to_target(car, track_config, checkpoint_progress)
                game_state = "running"
                continue

        draw_track(screen, track_config)
        car.draw_rays(screen)
        car.draw(screen)

        draw_hud(
            screen,
            font,
            game_state,
            car,
            ai_control,
            training_enabled,
            last_action_label,
            track_config,
            checkpoint_progress,
        )
        pygame.display.flip()


async def main():
    
    await start_server()

    await asyncio.sleep(2)  # Wait for server to initialize

    # Send a message to Godot
    await send_message("Hello from Python!")



if __name__ == "__main__":

    asyncio.run(main())

    

    #main()

