import asyncio
import websockets

# Store active connections
connected_clients = set()

godot_ref = any


async def handler(websocket):

    print("Godot connected!")

    connected_clients.add(websocket)

    godot_ref = websocket

    try:

        async for message in websocket:

            print("Message from Godot:", message)

            # Para mandarmos uma mensagem ao Godot, usar o comando abaixo
            #await send_message("ABOBA")

            

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