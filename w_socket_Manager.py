import asyncio
import websockets

# Store active connections
connected_clients = set()

godot_ref = any

My_Data = dict


async def handler(websocket):

    print("Godot connected!")

    connected_clients.add(websocket)

    godot_ref = websocket

    try:

        async for message in websocket:



            #print("Message from Godot:", message)

            My_Data = parse_car_agent_state(message)
            print(My_Data)

            # Para mandarmos uma mensagem ao Godot, usar o comando abaixo
            front = My_Data["front_collision"]
            back = My_Data["back_collision"]

            # Compare front and back collision
            if front > back:
                await send_message("1.0,0.0")   # Move forward
            elif front <= back:
                await send_message("-1.0,0.0")  # Move backward
            #else:
                #await send_message("0.0,0.0")   # Equal → no movement (optional)

            

    finally:

        connected_clients.remove(websocket)

        print("Godot disconnected!")

async def send_message(message: str):
    """
    Broadcast a message to all connected WebSocket clients.
    """
    if not connected_clients:
        print("No clients connected. Message not sent.")
        return
    
    # Send asynchronously to all clients
    await asyncio.gather(*(client.send(message) for client in connected_clients))
    print(f"Sent to {len(connected_clients)} client(s): {message}")



async def start_server(host="0.0.0.0", port=8080):
    """Starts the WebSocket server and keeps it running."""
    async with websockets.serve(handler, host, port):
        print(f"Python WebSocket server running on {host}:{port}")
        await asyncio.Future()  # Run forever




def parse_car_agent_state(state_string: str):
    """
    Receives a car agent state string in the format:
    "speed,rotation,checkpoint_distance,checkpoint_angle,
     front_ray,back_ray,left_ray,right_ray"
    Returns a dictionary with each value converted to float.
    """

    # Split string into pieces
    values = state_string.split(",")

    # Convert all pieces to float
    values = [float(v) for v in values]

    # Map values to variables
    data = {
        "car_speed": values[0],
        "car_rotation": values[1],
        "checkpoint_distance": values[2],
        "checkpoint_angle": values[3],
        "front_collision": values[4],
        "back_collision": values[5],
        "left_collision": values[6],
        "right_collision": values[7],
    }

    return data