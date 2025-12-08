extends PathFollow2D


#func _ready() -> void:
	#Game_Manager.RESET_CAR.connect(_reset_Progress)


func Reset_Progress(New_Progress_Ration:float):
	progress = New_Progress_Ration
	progress_ratio -= 0.06
	
func _physics_process(delta: float) -> void:
	progress_ratio += 0.008 * delta
