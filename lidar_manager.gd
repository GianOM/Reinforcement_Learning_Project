extends Node2D

class Car_Agent_State:
	
	var Car_Speed: float
	var Car_rotation: float
	
	var Checkpoint_Distance: float
	# Dot product entre o Front Vector e o Vetor que une o Checkpoint ao carro.
	# A ideia é saber se o carro esta apontando pra direcao do checkpoint
	var Chepoint_Angle: float
	
	var Front_Collision_Ray_Distance: float
	var Back_Collision_Ray_Distance: float
	var Left_Side_Collision_Ray_Distance: float
	var Right_Side_Collision_Ray_Distance: float
	
	func _to_string() -> String:
		
		var Temp_Text: String = ""
		
		Temp_Text += "Car Speed:" + str(Car_Speed) + "\n"
		Temp_Text += "Car Rotation:" + str(Car_rotation) + "\n"
		
		Temp_Text += "Checkpoint Distance:" + str(Checkpoint_Distance) + "\n"
		Temp_Text += "Chepoint Angle:" + str(Chepoint_Angle) + "\n"
		
		Temp_Text += "Front, Back, Left, Right Ray Distances: " + str(Front_Collision_Ray_Distance) + "," + str(Back_Collision_Ray_Distance) + "," + str(Left_Side_Collision_Ray_Distance) + "," + str(Right_Side_Collision_Ray_Distance) + "\n"
		
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

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	
	var Car_Frame_State: Car_Agent_State = Car_Agent_State.new()
	
	
	Car_Frame_State.Car_Speed = (player_character_car.Front_Aceleration / 0.05)
	Car_Frame_State.Car_rotation = sin(player_character_car.rotation)
	
	Car_Frame_State.Checkpoint_Distance = player_character_car.Car_Distance_to_Next_Checkpoint
	Car_Frame_State.Chepoint_Angle = player_character_car.Car_Direction_to_Next_Checkpoing
	
	
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
		
	print(Car_Frame_State)
	
