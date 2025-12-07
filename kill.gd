extends PathFollow2D


func _ready() -> void:
	Game_Manager.RESET_CAR.connect(_reset_Progress)


func _reset_Progress():
	progress_ratio = 0.94


func _physics_process(delta: float) -> void:
	progress_ratio += 0.008 * delta
