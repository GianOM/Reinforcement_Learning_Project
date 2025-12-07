import asyncio
import signal
import sys
from w_socket_Manager import start_server, save_agent_model, TRAIN_AGENT

def signal_handler(sig, frame):
    """Handle Ctrl+C gracefully and save the model."""
    print("\n\nShutting down server...")
    if TRAIN_AGENT:
        print("Saving trained model...")
        save_agent_model("final_model.pth")
    print("Server stopped.")
    sys.exit(0)

async def main():
    """Main entry point for the WebSocket server."""
    print("=" * 60)
    print("DQN Agent WebSocket Server for Godot")
    print("=" * 60)
    print("\nPress Ctrl+C to stop the server and save the model\n")
    
    # Register signal handler for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)
    
    # Start the WebSocket server
    await start_server(host="0.0.0.0", port=8080)

if __name__ == "__main__":
    asyncio.run(main())