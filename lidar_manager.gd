extends Node2D

class Car_Agent_State:
	
	var Car_Speed: float
	var Car_rotation: float
	
	var Distance_Traveled: float
	# Dot product entre o Front Vector e o Vetor que une o Checkpoint ao carro.
	# A ideia é saber se o carro esta apontando pra direcao do checkpoint
	var Chepoint_Angle: float
	
	var Front_Collision_Ray_Distance: float
	var Back_Collision_Ray_Distance: float
	var Left_Side_Collision_Ray_Distance: float
	var Right_Side_Collision_Ray_Distance: float
	
	# 1 se o Carro bateu
	# 0 se o Carro não bateu
	var Crashed: int = 0
	
	var Num_of_Checkpoints: int = 0
	
	var Penalidade_Ticks: float = 0
	
	func _to_string() -> String:
		
		var Temp_Text: String = ""
		
		##Car Speed:
		#Temp_Text += "Car Speed:" + str(Car_Speed) + "\n"
		Temp_Text += str(Car_Speed) + ","
		
		##Car Rotation:
		#Temp_Text += "Car Rotation:" + str(Car_rotation) + "\n"
		Temp_Text += str(Car_rotation) + ","
		
		##Checkpoint Distance:
		#Temp_Text += "Checkpoint Distance:" + str(Checkpoint_Distance) + "\n"
		Temp_Text += str(Distance_Traveled) + ","
		
		##Checkpoint Angle:
		#Temp_Text += "Chepoint Angle:" + str(Chepoint_Angle) + "\n"
		Temp_Text += str(Chepoint_Angle) + ","
		
		##Front, Back, Left, Right Ray Distances:
		Temp_Text += str(Front_Collision_Ray_Distance) + "," + str(Back_Collision_Ray_Distance) + "," + str(Left_Side_Collision_Ray_Distance) + "," + str(Right_Side_Collision_Ray_Distance) + ","
		
		
		Temp_Text += str(Crashed) + ","
		
		Temp_Text += str(Num_of_Checkpoints) + ","
		
		Temp_Text += str(Penalidade_Ticks)
		
		return Temp_Text
	
	
	
@onready var player_character_car: Car = $".."
	
	
@onready var front_ray_cast: RayCast2D = $Front_Ray_Cast
@onready var left_side_ray_cast: RayCast2D = $Left_Side_Ray_Cast
@onready var back_ray_cast: RayCast2D = $Back_Ray_Cast
@onready var right_side_ray_cast: RayCast2D = $Right_Side_Ray_Cast

@onready var front_ball: MeshInstance2D = $"../Front_Ball"
@onready var left_ball: MeshInstance2D = $"../Left_Ball"
@onready var back_ball: MeshInstance2D = $"../Back_Ball"
@onready var right_ball: MeshInstance2D = $"../Right_Ball"

var Ray_Casts_States: Array[Car_Agent_State]
var Car_Frame_State: Car_Agent_State

var has_AI_Car_Crashed: bool = false

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	
	if not has_AI_Car_Crashed:
	
		Car_Frame_State = Car_Agent_State.new()
		
		
		Car_Frame_State.Car_Speed = (player_character_car.Front_Aceleration / 0.05)
		Car_Frame_State.Car_rotation = sin(player_character_car.rotation)
		
		Car_Frame_State.Distance_Traveled = player_character_car.Distance_Traveled
		
		Car_Frame_State.Chepoint_Angle = player_character_car.Car_Direction_to_Next_Checkpoing
		
		if player_character_car.is_Car_Crashed:
			
			Car_Frame_State.Crashed = 1
			has_AI_Car_Crashed = true
			
		else:
			
			Car_Frame_State.Crashed = 0
			
			
			
		Car_Frame_State.Num_of_Checkpoints = player_character_car.Car_Checkpoints_Collected
		
		Car_Frame_State.Penalidade_Ticks = player_character_car.Tick_Penality
		
		if front_ray_cast.is_colliding():
			
			Car_Frame_State.Front_Collision_Ray_Distance = front_ray_cast.get_collision_point().distance_to(player_character_car.global_position)
			front_ball.global_position = front_ray_cast.get_collision_point()
			
		if left_side_ray_cast.is_colliding():
			
			Car_Frame_State.Left_Side_Collision_Ray_Distance = left_side_ray_cast.get_collision_point().distance_to(player_character_car.global_position)
			left_ball.global_position = left_side_ray_cast.get_collision_point()
			
		if back_ray_cast.is_colliding():
			
			Car_Frame_State.Back_Collision_Ray_Distance = back_ray_cast.get_collision_point().distance_to(player_character_car.global_position)
			back_ball.global_position = back_ray_cast.get_collision_point()
			
		if right_side_ray_cast.is_colliding():
			
			Car_Frame_State.Right_Side_Collision_Ray_Distance = right_side_ray_cast.get_collision_point().distance_to(player_character_car.global_position)
			right_ball.global_position = right_side_ray_cast.get_collision_point()
			
			
			
		WSocket.Send_Message(str(Car_Frame_State))
		#print(Car_Frame_State)
	
