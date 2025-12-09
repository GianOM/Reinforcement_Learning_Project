extends Label


@export var Car_Ref: Car
@onready var Rewards_Container: VBoxContainer = $ScrollContainer/Box_Container_List
@onready var scroll_container: ScrollContainer = $ScrollContainer

@onready var media: Label = $Media


var Ultimas_Recompensas: Array[float] = []

func _ready() -> void:
	
	Game_Manager.Send_Rewards_Stats.connect(_on_Car_Reward_Recieved)
	
	
func _on_Car_Reward_Recieved(Car_Reward: float):
	
	#@warning_ignore("narrowing_conversion")
	#scroll_container.ensure_control_visible(Rewards_Container.get_child(0))
	#Total_of_Cars += 1
	Ultimas_Recompensas.append(Car_Reward)
	
	if Ultimas_Recompensas.size() > 20:
		Ultimas_Recompensas.pop_front()
	
	
	var Temp_Label: Label = Label.new()
	Temp_Label.text = "Carro #" + str(Car_Ref.Car_Number) + "  ->  " + str(Car_Reward)
	Temp_Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Temp_Label.add_theme_font_size_override("font_size", 27)
	Rewards_Container.add_child(Temp_Label)
	
	while Temp_Label.get_parent() == null:
		await get_tree().process_frame
	
	
	Rewards_Container.move_child(Temp_Label, 0)
	
	Game_Manager.RESET_CAR.emit()
	
	_calculate_average()
	
	
func _calculate_average():
	
	if Ultimas_Recompensas.is_empty():
		media.text = "Média (20 carros) : 0.000"
		return
		
	var avg : float = 0.0
	for Recompensa in Ultimas_Recompensas:
		avg += Recompensa
	avg = avg / Ultimas_Recompensas.size()
	
	media.text = "Média (20 carros) : %.3f" % [avg]
	
	
