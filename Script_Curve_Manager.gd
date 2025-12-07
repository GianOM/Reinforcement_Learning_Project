extends Path2D


@export var Player_Car: Car

var Num_of_Checkpoints: int

func _ready() -> void:
	Num_of_Checkpoints = get_child_count()


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	
	#Distance_to_Closest_Checkpoint(Player_Car)
	Direction_to_Closest_Checkpoint(Player_Car)
	
	
#func Distance_to_Closest_Checkpoint(Car_Instance: Car) -> void:
	#
	##var Temp_Path_Follow: PathFollow2D = get_child(Car_Instance.Car_Checkpoints_Collected % Num_of_Checkpoints)
	#
	##Car_Instance.Car_Distance_to_Next_Checkpoint = Temp_Path_Follow.global_position.distance_to(Car_Instance.global_position)
	#
	#Car_Instance.Distance_Traveled = Car_Instance.Start_Position.distance_to(Car_Instance.global_position)
	#print(Car_Instance.Car_Distance_to_Next_Checkpoint)
	
func Direction_to_Closest_Checkpoint(Car_Instance: Car) -> void:
	
	var Temp_Path_Follow: PathFollow2D = get_child(Car_Instance.Car_Checkpoints_Collected % Num_of_Checkpoints)
	
	
	var Checkpoint_to_Car_Direction: Vector2 = (Car_Instance.global_position - Temp_Path_Follow.global_position).normalized()
	var Normalized_Car_Front_Vector: Vector2 = (Car_Instance.Front_Vector).normalized()
	
	
	
	##Quando o carro do Player aponta para o proximo checkpoint, tem o seu valor maximo 1.0
	##quando a traseira do carro aponta pro checkpoint, tem o seu valor minimo -1.0
	Car_Instance.Car_Direction_to_Next_Checkpoing = Normalized_Car_Front_Vector.dot(Checkpoint_to_Car_Direction)
	
