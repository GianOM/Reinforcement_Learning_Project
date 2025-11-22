extends Area2D

@onready var you_lost_text: Label = $"../You Lost Text"

@onready var score_text: Label = $"../You Lost Text/Score Text"

@onready var curva: Path2D = $"../Curva"


func _on_body_entered(body: Node2D) -> void:
	
	
	if body is Car:
		
		if not body.is_Car_in_Replay_Mode:
		
			you_lost_text.show()
			
			
			curva.Distance_to_Closest_Checkpoint(body)
			
			score_text.text = "Number of Checkpoints: %d" % body.Car_Checkpoints_Collected
			
			score_text.text += "\n Distance to Closest Checkpoint: %f" % body.Car_Distance_to_Next_Checkpoint
			
			score_text.text += "\n Number of Ticks: %f" % body.Tick_Penality
			
			body.Kill_Car()
			
			JSON_Exporter.Export_Car_States(body)
			
			get_tree().paused = true
			
