extends Area2D

func _on_body_entered(body: Node2D) -> void:
	
	if body is Car:
		
		#WSocket.Send_Message(str(body.lidar_manager.Car_Frame_State))
		
		body.Car_Checkpoints_Collected += 1.0
		body.Checkpoint_Collected.emit()
	
	
