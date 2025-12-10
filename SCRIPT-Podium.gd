class_name Podium
extends Node2D

@onready var top_1: Label = $"Top 3/VBoxContainer/Top_1"
@onready var top_2: Label = $"Top 3/VBoxContainer/Top_2"
@onready var top_3: Label = $"Top 3/VBoxContainer/Top_3"

var Linha_de_Desenho_1: PackedVector2Array
var Linha_de_Desenho_2: PackedVector2Array = [Vector2(0,0), Vector2(1,1)]
var Linha_de_Desenho_3: PackedVector2Array = [Vector2(0,0), Vector2(1,1)]

#var coords_mouth: Array 
var Podium_Rewards: Dictionary = {} # key: "Carro #1", value: reward
var Podium_Replays: Dictionary = {} # key: "Carro #1", value: PackedVector2Array

@onready var media: Label = $"Top 3/Media"
	

	
	
func _draw() -> void:
	
	# Preencher as linhas com "nada" da erro
	if Linha_de_Desenho_3.size() > 2:
		draw_polyline(Linha_de_Desenho_3, top_3.get("theme_override_colors/font_color"), 3.0, true)
	if Linha_de_Desenho_2.size() > 2:
		draw_polyline(Linha_de_Desenho_2, top_2.get("theme_override_colors/font_color"), 3.0, true)
	if Linha_de_Desenho_1.size() > 2:
		draw_polyline(Linha_de_Desenho_1, top_1.get("theme_override_colors/font_color"), 3.0, true)
	
func Dado_Recebido(Car_Ref: Car, Car_Reward: float):
	
	# Add the new score
	var key :String = "Carro #" + str(Car_Ref.Car_Number)
	Podium_Rewards[key] = Car_Reward
	Podium_Replays[key] = Car_Ref.Replay_Buffer
	
	#Temp_Linha_de_Desenho = Car_Ref.Replay_Buffer
	#queue_redraw()
	#print(Temp_Linha_de_Desenho)
	
	update_labels()
	update_linhas()
	queue_redraw()
	
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
		
	#var formated_average: float = get_top3_average()
	media.text = "Média: %.2f" % get_top3_average()
	
	
func update_linhas() -> void:
	
	var entries := get_sorted_entries()

	# Reset
	Linha_de_Desenho_1 = []
	Linha_de_Desenho_2 = []
	Linha_de_Desenho_3 = []
	
	if entries.size() > 0:
		Linha_de_Desenho_1 = Podium_Replays[entries[0][0]]
	if entries.size() > 1:
		Linha_de_Desenho_2 = Podium_Replays[entries[1][0]]
	if entries.size() > 2:
		Linha_de_Desenho_3 = Podium_Replays[entries[2][0]]
	
	
	
func get_sorted_entries() -> Array:
	var entries := []

	for key in Podium_Rewards.keys():
		entries.append([key, Podium_Rewards[key]])

	entries.sort_custom(func(a, b):
		return a[1] > b[1]
	)

	return entries
		
		
		
func get_top3_average() -> float:
	
	var entries := get_sorted_entries()

	if entries.size() == 0:
		return 0.0
	if entries.size() == 1:
		return entries[0][1]
	if entries.size() == 2:
		return (entries[0][1] + entries[1][1]) / 2.0

	# entries.size() >= 3
	return (entries[0][1] + entries[1][1] + entries[2][1]) / 3.0
