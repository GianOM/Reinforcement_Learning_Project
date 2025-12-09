extends Path2D


@export var Player_Car: Car

var Current_Checkpoint: int = 1

var Num_of_Checkpoints: int

func _ready() -> void:
	Num_of_Checkpoints = get_child_count() - 1 #O primeiro Path Follow é o apressador
	Player_Car.Checkpoint_Collected.connect(Car_Checkpoint_Collected)
	Game_Manager.RESET_CAR.connect(Reset_Checkpoints)


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	
	Activate_Next_Checkpoint()
	Direction_to_Closest_Checkpoint(Player_Car)

	
#func Distance_to_Closest_Checkpoint(Car_Instance: Car) -> void:
	#
	##var Temp_Path_Follow: PathFollow2D = get_child(Car_Instance.Car_Checkpoints_Collected % Num_of_Checkpoints)
	#
	##Car_Instance.Car_Distance_to_Next_Checkpoint = Temp_Path_Follow.global_position.distance_to(Car_Instance.global_position)
	#
	#Car_Instance.Distance_Traveled = Car_Instance.Start_Position.distance_to(Car_Instance.global_position)
	#print(Car_Instance.Car_Distance_to_Next_Checkpoint)
	
	
func Activate_Next_Checkpoint():
	
	
	var Temp_Path_Follow: CheckPoint
	
	for i in range(1, Num_of_Checkpoints + 1):
		
		Temp_Path_Follow = get_child(i)
		
		if i == Current_Checkpoint:
			
			Temp_Path_Follow.Enable_Checkpoint()
			
		else:
			
			Temp_Path_Follow.Disable_Checkpoint()
	
	
	
func Direction_to_Closest_Checkpoint(Car_Instance: Car) -> void:
	
	var Temp_Path_Follow: PathFollow2D = get_child(1 + (int(Car_Instance.Car_Checkpoints_Collected) % Num_of_Checkpoints))#O primeiro Path Follow é o apressador
	
	
	var Checkpoint_to_Car_Direction: Vector2 = (Car_Instance.global_position - Temp_Path_Follow.global_position).normalized()
	var Normalized_Car_Front_Vector: Vector2 = (Car_Instance.Front_Vector).normalized()
	
	
	
	##Quando o carro do Player aponta para o proximo checkpoint, tem o seu valor maximo 1.0
	##quando a traseira do carro aponta pro checkpoint, tem o seu valor minimo -1.0
	Car_Instance.Car_Direction_to_Next_Checkpoing = Normalized_Car_Front_Vector.dot(Checkpoint_to_Car_Direction)
	#print(Normalized_Car_Front_Vector.dot(Checkpoint_to_Car_Direction))
	
	
func Update_Goals(New_Position: Vector2):
	#O primeiro Path Follow é o apressador
	var Temp_Path_Follow: PathFollow2D = get_child(0)
	var Progress_Offset: float = curve.get_closest_offset(New_Position)
		
	Temp_Path_Follow.Reset_Progress(Progress_Offset)
		
	
	for i in range(1, Num_of_Checkpoints + 1):
		Temp_Path_Follow = get_child(i)
		
		Progress_Offset = curve.get_closest_offset(New_Position)
		
		Temp_Path_Follow.progress = Progress_Offset
		Temp_Path_Follow.progress_ratio += 0.02 * i
		
		
func Car_Checkpoint_Collected():
	
	Current_Checkpoint += 1
	
	if Current_Checkpoint > 49:
		
		Current_Checkpoint = 1
		
	#print(Current_Checkpoint)
func Reset_Checkpoints():
	Current_Checkpoint = 1
	
