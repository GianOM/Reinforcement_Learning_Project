class_name Car
extends CharacterBody2D 


@warning_ignore("unused_signal")
signal Checkpoint_Collected()# Acessado pela Checkpoint Stuff


enum Car_Mode{
	AI_CONTROLLED,
	PLAYER_CONTROLLED,
	REPLAY_MODE
}

var RNG: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var curva: Path2D = $"../Curva"

@export var My_Car_Mode: Car_Mode = Car_Mode.AI_CONTROLLED

@onready var lidar_manager: Node2D = $Lidar_Manager

var acceleration :float = 0.01       # How fast the car accelerates
var reverse_speed: float = 0.03
var turn_speed :float = 40.0            # How fast the car rotates
var friction :float = 0.99           # Resistance when no input

var Car_Checkpoints_Collected: float = 0.0

var Car_Number: int = 0

# As duas variaveis abaixo sao escritas pelo "Script_Cuve_Manager"
var Distance_Traveled: float = 0
var Car_Direction_to_Next_Checkpoing: float = 0

var is_Car_Crashed: bool = false


##Usado para penalizar o carro ficar parado
var Tick_Penality: float = 0.0

#TODO:
# Posicao dele no Espaco
var Front_Vector : Vector2 = Vector2.ZERO
var Front_Aceleration: float = 0.0

var Replay_Buffer: Array[Vector3]

var input_forward : float
var input_turn :float

var Curve_Points: PackedVector2Array

func _ready() -> void:
	
	Game_Manager.Send_Inputs_to_Car.connect(Receive_AI_Inputs)
	Game_Manager.RESET_CAR.connect(Kill_Car)
	Curve_Points = curva.curve.get_baked_points()
	
func Receive_AI_Inputs(Forward: float, Turn: float):
	
	
	input_forward = Forward
	input_turn = Turn
	
	#print("Input Changed")
	
	
func _physics_process(delta: float) -> void:
	
	match My_Car_Mode:
		
		Car_Mode.AI_CONTROLLED:
			
			if not is_Car_Crashed:
			
				handle_steering(input_turn, delta)
				handle_acceleration(input_forward, delta)
				
				position -= Front_Vector * Front_Aceleration
				Distance_Traveled += Front_Aceleration
				
				#print(Distance_Traveled)
				Tick_Penality -= 0.1
				
			
		Car_Mode.PLAYER_CONTROLLED:
			
			if not is_Car_Crashed:
				
				input_forward = Input.get_action_strength("Forward_Key") - Input.get_action_strength("Backward_Key")
				input_turn  = Input.get_action_strength("Left_Side_Turn_Key") - Input.get_action_strength("Right_Side_Turn_Key")
				
				handle_steering(input_turn, delta)
				handle_acceleration(input_forward, delta)
				
				
				position -= Front_Vector * Front_Aceleration
				Distance_Traveled += Front_Aceleration
				
				Tick_Penality -= 0.1
			
		#Car_Mode.REPLAY_MODE:
			#
			#if Input_Replay_Iterator < Replay_Buffer.size():
			#
				#handle_steering(Input_List[Input_Replay_Iterator].y, delta)
				#handle_acceleration(Input_List[Input_Replay_Iterator].x, delta)
				#
				#
				#position -= Front_Vector * Front_Aceleration
				#
				#Input_Replay_Iterator += 1
		
		
	#green_arrow.look_at(position + velocity)
	#green_arrow.global_position = global_position + velocity
	#green_arrow.rotation_degrees += 90
		
func handle_acceleration(Forward_Input_Amount: float,delta_Time: float) -> void:
	
	
	Front_Vector = transform.y
	#Front_Aceleration = Forward_Input_Amount
	
	if Forward_Input_Amount > 0.05:
		
		
		#Maxima velocidade quando esta indo pra frente
		if Front_Aceleration < 0.05:
			
			Front_Aceleration += Forward_Input_Amount * acceleration * delta_Time
			
			
		else:
			
			#Se o carro atinge o limite de velocidade, adicionar pouca velocidade a ele
			Front_Aceleration += Forward_Input_Amount * acceleration * delta_Time * 0.01
			
		
	else:
		
		if Forward_Input_Amount < -0.05:
			
			#Maxima velocidade quando esta dando Re
			if Front_Aceleration < -0.01:
				
				#Se o carro atinge o limite de velocidade de re, adicionar 
				#pouca velocidade a ele
				Front_Aceleration += Forward_Input_Amount * reverse_speed * delta_Time * 0.01
			
			
			else:
				
				#Freio
				Front_Aceleration += Forward_Input_Amount * reverse_speed * delta_Time
			
		else:
			
			#Aplica Friccao
			Front_Aceleration *= 0.99
			
			
		
	#print(Front_Aceleration)
		
func handle_steering(Steering_Input_Amount: float ,delta_Time: float) -> void:
	
	
	if abs(Front_Aceleration) >= 0.005:
		rotation -= Steering_Input_Amount * 0.9 * delta_Time
	else:
		rotation -= Steering_Input_Amount * 40 * Front_Aceleration * delta_Time
	
func Kill_Car():
	
	var Next_Point: int = RNG.randi_range(0, Curve_Points.size() - 1)
	var Next_Baked_Point: Vector2 = Curve_Points[Next_Point]
	
	curva.Update_Goals(Next_Baked_Point)
	
	# Adiciona um offset lateral para impedir que o carro sempre renasça no centro da pista
	global_position = Next_Baked_Point + (transform.x * RNG.randf_range(-0.05,0.05))
	
	#Incluimos uma rotacao aleatoria de +-45º para uma melhor generalizacao
	rotation = (curva.get_child(1).rotation + PI/2) + RNG.randf_range(-PI/8,PI/8)
	
	
	Front_Vector = transform.y
	Front_Aceleration = RNG.randf_range(-0.01,0.035)
	
	is_Car_Crashed = false
		
	Car_Checkpoints_Collected = 0.0
	# As duas variaveis abaixo sao escritas pelo "Script_Cuve_Manager"
	#print(Distance_Traveled)
	Distance_Traveled = 0.0
	Car_Direction_to_Next_Checkpoing = 0.0
		
		
	##Usado para penalizar o carro ficar parado
	Tick_Penality = 0.0
	
	Car_Number += 1
	
	lidar_manager.has_AI_Car_Crashed = false
	
