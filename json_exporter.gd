extends Node

var Base_Path: String = "user://points.json"


func Export_Car_States(Car_Instance: Car) -> void:
	
	
	var Temporary_File: FileAccess = FileAccess.open(Base_Path, FileAccess.WRITE)
	
	
	Temporary_File.store_string(JSON.stringify(Car_Instance.Input_List))
	
	Temporary_File.close()
	
	
	print("Saved to ", Base_Path)
