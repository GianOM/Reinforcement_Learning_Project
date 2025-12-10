class_name Podium
extends Label

@onready var top_1: Label = $VBoxContainer/Top_1
@onready var top_2: Label = $VBoxContainer/Top_2
@onready var top_3: Label = $VBoxContainer/Top_3

var Podium_Rewards: Dictionary = {} # key: "Carro #1", value: reward

@onready var media: Label = $Media


func Dado_Recebido(Car_Ref: Car, Car_Reward: float):
	
	# Add the new score
	var key :String = "Carro #" + str(Car_Ref.Car_Number)
	Podium_Rewards[key] = Car_Reward
	
	update_labels()
	
func update_labels() -> void:
	# Convert dictionary into an array of [key, value] pairs
	var entries :Array = get_sorted_entries()

	# Fill the top 3 labels
	if entries.size() > 0:
		top_1.text = entries[0][0] + ": " + str(entries[0][1])
	else:
		top_1.text = "----"

	if entries.size() > 1:
		top_2.text = entries[1][0] + ": " + str(entries[1][1])
	else:
		top_2.text = "----"

	if entries.size() > 2:
		top_3.text = entries[2][0] + ": " + str(entries[2][1])
	else:
		top_3.text = "----"
		
		
	media.text = "Média:" + get_top3_average()
		
func get_sorted_entries() -> Array:
	var entries := []

	for key in Podium_Rewards.keys():
		entries.append([key, Podium_Rewards[key]])

	entries.sort_custom(func(a, b):
		return a[1] > b[1]
	)

	return entries
		
		
		
func get_top3_average() -> String:
	
	var entries := get_sorted_entries()

	if entries.size() == 0:
		return str(0.0)
	if entries.size() == 1:
		return str(entries[0][1])
	if entries.size() == 2:
		return str((entries[0][1] + entries[1][1]) / 2.0)

	# entries.size() >= 3
	return str((entries[0][1] + entries[1][1] + entries[2][1]) / 3.0)
