extends Area2D

@onready var curva: Path2D = $"../../../Curva"

func _on_body_entered(body: Node2D) -> void:
	
	if body is Car:
		
		if not (body.My_Car_Mode == Car.Car_Mode.REPLAY_MODE):
		
			curva.Distance_to_Closest_Checkpoint(body)
			
			#score_text.text = "Number of Checkpoints: %d" % body.Car_Checkpoints_Collected
			#score_text.text += "\n Distance to Closest Checkpoint: %f" % body.Car_Distance_to_Next_Checkpoint
			#score_text.text += "\n Number of Ticks: %f" % body.Tick_Penality
			
			body.is_Car_Crashed = true
			
			#Game_Manager.RESET_CAR.emit()
