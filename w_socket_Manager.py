import asyncio
import websockets
import torch
from dqn_agent import DQNAgent, build_state_vector, ACTION_MEANINGS

# Store active connections
connected_clients = set()

# Global agent instance
agent = None
TRAIN_AGENT = True  # Toggle training mode

# Training state variables
last_state = None
last_action = None
last_distance = None

# Reward configuration
REWARD_DISTANCE_SCALE = 0.02
REWARD_SPEED_SCALE = 0.001
REWARD_CRASH = 2.5
REWARD_FINISH = 10.0
CHECKPOINT_REWARD = 48


def initialize_agent():
    """Initialize the DQN agent."""
    global agent
    if agent is None:
        agent = DQNAgent()
        print("DQN Agent initialized")


async def handler(websocket):
    """Handle WebSocket connection from Godot."""
    global last_state, last_action, last_distance
    
    print("Godot connected!")
    connected_clients.add(websocket)
    
    # Reset training state for new connection
    last_state = None
    last_action = None
    last_distance = None

    try:
        async for message in websocket:
            # Parse incoming car state from Godot
            car_data = parse_car_agent_state(message)
            
            # Build state tensor for DQN
            current_state = build_state_vector(
                ray_distances={
                    "front": car_data["front_collision"],
                    "rear": car_data["back_collision"],
                    "left": car_data["left_collision"],
                    "right": car_data["right_collision"],
                },
                distance_to_finish=car_data["distance_traveled"],

                #O valor abaixo é normalizado e nao em radianos
                angle_to_finish_rad=car_data["checkpoint_angle"],

                orientation_rad=car_data["car_rotation"],

                speed=car_data["car_speed"],
            )
            
            # Select action using DQN agent
            action_index = agent.select_action(current_state, deterministic=not TRAIN_AGENT)
            action_name = ACTION_MEANINGS[action_index]
            
            # Convert action to Godot control format (throttle, steering)
            throttle, steering = action_to_godot_control(action_index)
            
            # Handle training if enabled
            if TRAIN_AGENT and last_state is not None:

                current_distance = car_data["distance_traveled"]
                
                # Compute reward
                reward = compute_reward(

                    checkpoint_bonus=car_data.get("checkpoint_bonus", 0.0),

                    crashed=car_data.get("crashed", False),

                    distance_traveled=car_data.get("distance_traveled", 0.0)


                )
                
                # Check if episode is done
                done = car_data.get("crashed")
                
                # Store transition in replay buffer
                agent.store_transition(last_state, last_action, reward, current_state, done)
                
                # Train the agent
                agent.train_step()
                
                # Reset training state if episode ended
                if done:
                    last_state = None
                    last_action = None
                    last_distance = None
                    print(f"Episode ended. Reward: {reward:.2f}")
                    await send_message(f"RESET,{reward:.3f}")
                else:
                    last_distance = current_distance
            
            # Update last state and action for next iteration
            #if not car_data.get("crashed", False) and not car_data.get("finished", False):
            if not car_data.get("crashed"):

                last_state = current_state
                last_action = action_index

                if last_distance is None:
                    last_distance = car_data["distance_traveled"]
            
                # Send action to Godot (throttle, steering)
                message_to_godot = f"{throttle},{steering}"
                await send_message(message_to_godot)
                
                # Debug output
                #print(f"Action: {action_name} | Throttle: {throttle} | Steering: {steering}")

    finally:

        connected_clients.remove(websocket)

        print("Godot disconnected!")


def action_to_godot_control(action_index: int) -> tuple[float, float]:
    """
    Convert DQN action index to Godot control format.
    Returns: (throttle, steering)
    
    ACTION_MEANINGS:
        0: "idle"              -> (0.0, 0.0)
        1: "throttle"          -> (1.0, 0.0)
        2: "steer_left"        -> (0.0, 1.0)
        3: "steer_right"       -> (0.0, -1.0)
        4: "reverse"           -> (-1.0, 0.0)
    """
    action_map = {
        #Talvez adicionar a possibilidade de dar RE
        #0: (0.0, 0.0),   # idle
        0: (1.0, 0.0),   # throttle
        1: (0.0, 1.0),   # steer left
        2: (0.0, -1.0),  # steer right
        3: (-1.0, 0.0),   # reverse
    }
    return action_map.get(action_index, (0.0, 0.0))


def compute_reward(
    checkpoint_bonus: int,
    crashed: bool,
    distance_traveled: float
) -> float:
    """Compute reward for the current state transition."""
    
    reward = 0.0

    # Numero de Checkpoints coletados
    reward += distance_traveled * ((1 + checkpoint_bonus))
    
    # Large negative reward for crashing
    if crashed:

        # Batidas em alta velocidade sao MAIS penalizadas
        #reward += REWARD_CRASH / (1.0 + car_speed)
        reward = (reward / REWARD_CRASH)
    
    return reward

def parse_car_agent_state(state_string: str) -> dict:
    """
    Receives a car agent state string in the format:
    "speed,rotation,distance_traveled,checkpoint_angle,
     front_ray,back_ray,left_ray,right_ray,crashed,finished,checkpoint_bonus"
    
    Returns a dictionary with each value converted to appropriate type.
    """
    # Split string into pieces
    values = state_string.split(",")
    
    # Convert to appropriate types
    data = {
        "car_speed": float(values[0]),
        "car_rotation": float(values[1]),
        "distance_traveled": float(values[2]),
        "checkpoint_angle": float(values[3]),
        "front_collision": float(values[4]),
        "back_collision": float(values[5]),
        "left_collision": float(values[6]),
        "right_collision": float(values[7]),
    }
    
    # Optional fields for training

    if len(values) > 8:

        data["crashed"] = bool(int(values[8])) # 1 se bateu, 0 se nao bateu

    if len(values) > 9:

        # Quantidade de Check Points que a IA Coletou Normalizada
        data["checkpoint_bonus"] = float(values[9]) 

    if len(values) > 10:
       data["ticks"] = float(values[10])
    
    return data


# Convenience function to save agent
def save_agent_model(filename: str = "trained_model.pth"):
    """Save the current agent model."""
    if agent is not None:
        agent.save(filename)
        print(f"Model saved to {filename}")
    else:
        print("No agent to save!")


# Convenience function to load agent
def load_agent_model(filename: str = "final_model.pth"):
    """Load a pre-trained agent model."""
    global agent
    initialize_agent()
    try:
        agent.load(filename)
        print(f"Model loaded from {filename}")
    except FileNotFoundError:
        print(f"Model file {filename} not found!")

async def send_message(message: str):
    """Broadcast a message to all connected WebSocket clients."""
    if not connected_clients:
        print("No clients connected. Message not sent.")
        return
    
    # Send asynchronously to all clients
    await asyncio.gather(*(client.send(message) for client in connected_clients))


async def start_server(host="0.0.0.0", port=8080):
    """Starts the WebSocket server and keeps it running."""
    initialize_agent()
    #load_agent_model("final_model.pth")
    async with websockets.serve(handler, host, port):
        print(f"Python WebSocket server running on {host}:{port}")
        print(f"Training mode: {'ENABLED' if TRAIN_AGENT else 'DISABLED'}")
        await asyncio.Future()  # Run forever