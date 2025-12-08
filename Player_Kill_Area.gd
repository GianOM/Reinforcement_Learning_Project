extends Area2D

@onready var you_lost_text: Label = $"../You Lost Text"

@onready var score_text: Label = $"../You Lost Text/Score Text"

@onready var curva: Path2D = $"../Curva"


func _on_body_entered(body: Node2D) -> void:
	
	
	if body is Car:
		
		if not (body.My_Car_Mode == Car.Car_Mode.REPLAY_MODE):
		

			
			body.is_Car_Crashed = true
			
			#Game_Manager.RESET_CAR.emit()
