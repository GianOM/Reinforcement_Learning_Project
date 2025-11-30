import asyncio
import websockets

async def handler(websocket):

    print("Godot connected!")

    async for message in websocket:

        print("Message from Godot:", message)
        await websocket.send("Message received: " + message)

async def main():

    async with websockets.serve(handler, "0.0.0.0", 8080):
        
        print("Python WebSocket server running on port 8080")
        await asyncio.Future()  # Keep running forever

asyncio.run(main())