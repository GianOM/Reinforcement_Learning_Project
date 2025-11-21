extends Area2D





func _on_body_entered(body: Node2D) -> void:
	
	if body is Car:
		
		#print(body)
		
		body.Car_Checkpoints_Collected += 1
	
	
