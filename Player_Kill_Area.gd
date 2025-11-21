extends Area2D

@onready var label: Label = $"../Label"



func _on_body_entered(body: Node2D) -> void:
	
	
	if body is Car:
		
		label.show()
		
		body.Kill_Car()
		
		get_tree().paused = true
	
	print(body.name)
	
	
	pass # Replace with function body.
