class_name Car
extends CharacterBody2D 

var acceleration := 3.0          # How fast the car accelerates

var max_speed := 120.0             # Max forward speed


var turn_speed := 2.0            # How fast the car rotates

var friction := 2.5           # Resistance when no input



var drift := 0.9                  # 1 = no drift, 0 = very slippery


var Car_Checkpoints_Collected: int = 0

var Car_Distance_to_Next_Checkpoint: float = 0


##Usado para penalizar o carro ficar parado
var Tick_Penality: float = 0

var Reward: float = 0

#TODO:
# Posicao dele no Espaco


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
		
		velocity = Vector2.ZERO
		
		is_Car_in_Replay_Mode = true
		

func _physics_process(delta: float) -> void:
	
	if not is_Car_in_Replay_Mode:
		var input_forward : float = Input.get_action_strength("Forward_Key") - Input.get_action_strength("Backward_Key")
		var input_turn :float  = Input.get_action_strength("Left_Side_Turn_Key") - Input.get_action_strength("Right_Side_Turn_Key")
		
		handle_acceleration(input_forward, delta)
		handle_steering(input_turn, delta)
		
		position += velocity 
		
		Input_List.append(Vector2(input_forward, input_turn))
		
		Tick_Penality -= 0.1
		
	else:
		
		if Input_Replay_Iterator < Input_List.size():
		
			handle_acceleration(Input_List[Input_Replay_Iterator].x, delta)
			handle_steering(Input_List[Input_Replay_Iterator].y, delta)
			
			position += velocity 
			
			Input_Replay_Iterator += 1
		
		
		
		
		
func handle_acceleration(Forward_Input_Amount: float,delta_Time: float) -> void:
	
	
	if Forward_Input_Amount > 0:
		
		velocity -= transform.y * Forward_Input_Amount * acceleration * delta_Time
		velocity = velocity.normalized() * 2
		
	else:
		# Natural slowing when no input
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta_Time)
		
		
		
func handle_steering(Steering_Input_Amount: float ,delta_Time: float) -> void:
	
	if velocity.length() > 0.05:  # Don't rotate when standing still
		
		rotation -= Steering_Input_Amount * turn_speed * delta_Time
		
		# Drift / sliding feel
		#var forward = transform.y * velocity.dot(transform.y)
		#var sideways = transform.x * velocity.dot(transform.x)
		#
		#sideways *= drift  # reduce sideways movement (grip)
		#velocity = forward + sideways
	
	
func Kill_Car():
	
	#print(Score)
	
	global_position = Vector2(1101.0, 864.0)
	rotation = 1.32626593112946
		
	velocity = Vector2.ZERO
		
	is_Car_in_Replay_Mode = true
	
	
	
	
	
	
