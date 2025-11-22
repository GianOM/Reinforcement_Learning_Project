extends Path2D


func Distance_to_Closest_Checkpoint(Car_Instance: Car) -> void:
	
	
	#BUG: Se pegarmos mais de 15 checkpoints RIP
	var Temp_Path_Follow: PathFollow2D = get_child(Car_Instance.Car_Checkpoints_Collected % 15)
	
	
	print(Temp_Path_Follow.name)
	
	Car_Instance.Car_Distance_to_Next_Checkpoint = 100.0 / Temp_Path_Follow.global_position.distance_to(Car_Instance.global_position)
	
		
		
