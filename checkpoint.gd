class_name CheckPoint
extends PathFollow2D

const ENABLED_COLOR: Color = Color(0.345, 0.741, 0.125, 1.0)
const DISABLED_COLOR: Color = Color(0.2, 0.063, 0.035, 1.0)


@onready var color_rect: ColorRect = $ColorRect
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

func Enable_Checkpoint():
	
	process_mode = Node.PROCESS_MODE_INHERIT
	color_rect.color = ENABLED_COLOR
	collision_shape_2d.debug_color = ENABLED_COLOR
	
func Disable_Checkpoint():
	
	
	process_mode = Node.PROCESS_MODE_DISABLED
	color_rect.color = DISABLED_COLOR
	collision_shape_2d.debug_color = DISABLED_COLOR
	
