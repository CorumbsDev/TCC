extends Node

var item_data = {}

func _ready():
	var file = FileAccess.open("res://Inventory/Data/Item_data.json", FileAccess.READ)
	if file:
		var data = file.get_as_text()
		item_data = JSON.parse_string(data)


#load the data file
func load_data(path : String) -> void:
	if not FileAccess.file_exists(path):
		print("Item Data file not found")
	var item_data_file = FileAccess.open(path, FileAccess.READ)
	item_data = JSON.parse_string(item_data_file.get_as_text())
	item_data_file.close()
	#print(item_data)	#check value
