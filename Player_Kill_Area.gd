extends Area2D

func _on_body_entered(body: Node2D) -> void:
	
	
	if body is Car:
		
		if not (body.My_Car_Mode == Car.Car_Mode.REPLAY_MODE):
		
			
			body.is_Car_Crashed = true
			
			
			if body.My_Car_Mode == Car.Car_Mode.PLAYER_CONTROLLED:
				Game_Manager.Send_Rewards_Stats.emit(body.Distance_Traveled)
				print("Teste")
