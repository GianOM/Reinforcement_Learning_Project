extends Node2D

class Ray_Cast_State:
	
	var Front_Collision_Point: Vector2
	var Left_Side_Collision_Point: Vector2
	var Back_Collision_Point: Vector2
	var Right_Side_Collision_Point: Vector2
	
	
	func _to_string() -> String:
		
		return str(Front_Collision_Point) + "," + str(Left_Side_Collision_Point) + "," + str(Back_Collision_Point) + "," + str(Right_Side_Collision_Point)
	
	
	
@onready var front_ray_cast: RayCast2D = $Front_Ray_Cast
@onready var left_side_ray_cast: RayCast2D = $Left_Side_Ray_Cast
@onready var back_ray_cast: RayCast2D = $Back_Ray_Cast
@onready var right_side_ray_cast: RayCast2D = $Right_Side_Ray_Cast



@onready var front_ball: MeshInstance2D = $"../Front_Ball"
@onready var left_ball: MeshInstance2D = $"../Left_Ball"
@onready var back_ball: MeshInstance2D = $"../Back_Ball"
@onready var right_ball: MeshInstance2D = $"../Right_Ball"



var Ray_Casts_States: Array[Ray_Cast_State]

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	
	var Tick_Ray_State: Ray_Cast_State = Ray_Cast_State.new()
	
	if front_ray_cast.is_colliding():
		
		Tick_Ray_State.Front_Collision_Point = front_ray_cast.get_collision_point()
		front_ball.global_position = front_ray_cast.get_collision_point()
		
	if left_side_ray_cast.is_colliding():
		
		Tick_Ray_State.Left_Side_Collision_Point = left_side_ray_cast.get_collision_point()
		left_ball.global_position = left_side_ray_cast.get_collision_point()
		
	if back_ray_cast.is_colliding():
		
		Tick_Ray_State.Back_Collision_Point = back_ray_cast.get_collision_point()
		back_ball.global_position = back_ray_cast.get_collision_point()
		
	if right_side_ray_cast.is_colliding():
		
		Tick_Ray_State.Right_Side_Collision_Point = right_side_ray_cast.get_collision_point()
		right_ball.global_position = right_side_ray_cast.get_collision_point()
		
		
	#print(Tick_Ray_State)
