extends Node

@export var websocket_url: String = "ws://127.0.0.1:8080"

var Teste_Tensor: String = "0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0"

# Our WebSocketClient instance.
var socket = WebSocketPeer.new()

func _ready():
	
	# Initiate connection to the given URL.
	var err = socket.connect_to_url(websocket_url)
	
	print(str(Teste_Tensor))
	
	if err == OK:
		print("Connecting to %s..." % websocket_url)
		# Wait for the socket to connect.
		await get_tree().create_timer(4.0).timeout
		
		# Send data.
		print("> Sending test packet.")
		
		#err = socket.send_text("Test packet")
		
		err = socket.send_text(str(Teste_Tensor))
		
		socket.poll()
		
		#print("Erro:" + err)
	else:
		push_error("Unable to connect.")
		set_process(false)


func _process(_delta):
	# Call this in `_process()` or `_physics_process()`.
	# Data transfer and state updates will only happen when calling this function.
	socket.poll()

	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()
	
	# `WebSocketPeer.STATE_OPEN` means the socket is connected and ready
	# to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			if socket.was_string_packet():
				var packet_text: String = packet.get_string_from_utf8()
				
				if packet_text == "RESET":
					Game_Manager.RESET_CAR.emit()
				
				else:
					var Input_Vector = parse_floats(packet_text)
					Game_Manager.Send_Inputs_to_Car.emit(Input_Vector.x,Input_Vector.y)
				
				#print("< Got text data from server: %s" % packet_text)
				
			#else:
				#print("< Got binary data from server: %d bytes" % packet.size())

	# `WebSocketPeer.STATE_CLOSING` means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		pass

	# `WebSocketPeer.STATE_CLOSED` means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be `-1` if the disconnection was not properly notified by the remote peer.
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false) # Stop processing.
		
		
func Send_Message(Message_to_Send: String):
	
	socket.poll()
	
	var state = socket.get_ready_state()
	
	
	
	# `WebSocketPeer.STATE_OPEN` means the socket is connected and ready
	# to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		
		#var err:Error
		#err = socket.send_text(str(Time.get_ticks_msec()))
		@warning_ignore("unused_variable")
		var err:Error = socket.send_text(Message_to_Send)
		
		
		while socket.get_available_packet_count():
			
			var packet = socket.get_packet()
			
			if socket.was_string_packet():
				
				var packet_text = packet.get_string_from_utf8()
				#var Input_Vector = parse_floats(packet_text)
				
				#Game_Manager.Send_Inputs_to_Car.emit(Input_Vector.x,Input_Vector.y)
				
				#print("< Got text data from server: %s" % packet_text)
				
			#else:
				
				#print("< Got binary data from server: %d bytes" % packet.size())
				
				
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be `-1` if the disconnection was not properly notified by the remote peer.
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false) # Stop processing.
	
	
	pass
	
	
func parse_floats(input_string: String) -> Vector2:
	var parts = input_string.split(",")
	if parts.size() != 2:
		push_error("Invalid float pair: %s" % input_string)
		return Vector2.ZERO
		
	var x = parts[0].to_float()
	var y = parts[1].to_float()
	return Vector2(x, y)
