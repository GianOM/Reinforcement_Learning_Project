extends Path2D


func Distance_to_Closest_Checkpoint(Car_Instance: Car) -> void:
	
	var Temp_Path_Follow: PathFollow2D = get_child(Car_Instance.Car_Checkpoints_Collected)
	
	
	print(Temp_Path_Follow.name)
	
	Car_Instance.Car_Distance_to_Next_Checkpoint = Temp_Path_Follow.global_position.distance_to(Car_Instance.global_position)
	
		
		
