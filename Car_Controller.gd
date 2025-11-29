class_name Car
extends CharacterBody2D 

@onready var green_arrow: Sprite2D = $"Green Arrow"

var acceleration :float = 0.01       # How fast the car accelerates
var reverse_speed: float = 0.03

var max_speed := 120.0             # Max forward speed


var turn_speed := 0.9            # How fast the car rotates

var friction := 2.5           # Resistance when no input



var drift := 0.9                  # 1 = no drift, 0 = very slippery


var Car_Checkpoints_Collected: int = 0

var Car_Distance_to_Next_Checkpoint: float = 0


##Usado para penalizar o carro ficar parado
var Tick_Penality: float = 0

var Reward: float = 0

#TODO:
# Posicao dele no Espaco
var Front_Vector : Vector2 = Vector2.ZERO
var Front_Aceleration: float = 0.0


var Input_Replay_Iterator: int = 0
var Input_List: Array[Vector2]

var is_Car_in_Replay_Mode: bool = false

func _ready() -> void:
	print(rotation)
	

@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("P_Key"):
		
		global_position = Vector2(1101.0, 864.0)
		rotation = 1.32626593112946
		
		Front_Vector = transform.y
		Front_Aceleration = 0.0
		
		
		is_Car_in_Replay_Mode = true
		

func _physics_process(delta: float) -> void:
	
	if not is_Car_in_Replay_Mode:
		
		var input_forward : float = Input.get_action_strength("Forward_Key") - Input.get_action_strength("Backward_Key")
		var input_turn :float  = Input.get_action_strength("Left_Side_Turn_Key") - Input.get_action_strength("Right_Side_Turn_Key")
		
		handle_steering(input_turn, delta)
		handle_acceleration(input_forward, delta)
		
		
		
		position -= Front_Vector * Front_Aceleration
		
		Input_List.append(Vector2(input_forward, input_turn))
		
		Tick_Penality -= 0.005
		
	else:
		
		if Input_Replay_Iterator < Input_List.size():
			
			handle_steering(Input_List[Input_Replay_Iterator].y, delta)
			handle_acceleration(Input_List[Input_Replay_Iterator].x, delta)
			
			
			position -= Front_Vector * Front_Aceleration
			
			Input_Replay_Iterator += 1
		
		
	#green_arrow.look_at(position + velocity)
	#green_arrow.global_position = global_position + velocity
	#green_arrow.rotation_degrees += 90
		
func handle_acceleration(Forward_Input_Amount: float,delta_Time: float) -> void:
	
	
	Front_Vector = transform.y
	#Front_Aceleration = Forward_Input_Amount
	
	if Forward_Input_Amount > 0.05:
		
		if Front_Aceleration < 0.05:
			
			Front_Aceleration += Forward_Input_Amount * acceleration * delta_Time
			
			
		else:
			
			#Se o carro atinge o limite de velocidade, adicionar pouca velocidade a ele
			Front_Aceleration += Forward_Input_Amount * acceleration * delta_Time * 0.01
			
		
	else:
		
		if Forward_Input_Amount < -0.05:
			
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
			
			
		
	print(Front_Aceleration)
		
func handle_steering(Steering_Input_Amount: float ,delta_Time: float) -> void:
	
	rotation -= Steering_Input_Amount * turn_speed * delta_Time
	
	
	
	
	
func Kill_Car():
	
	#print(Score)
	
	global_position = Vector2(1101.0, 864.0)
	rotation = 1.32626593112946
		
	Front_Vector = transform.y
	Front_Aceleration = 0.0
		
	is_Car_in_Replay_Mode = true
	
	
	
	
	
	
