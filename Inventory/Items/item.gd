extends Node2D

@onready var IconRect_path = $Icon

var item_ID : String
var value : int =0
var operator : String = ""
var selected = false
var item_grids := [Vector2(0,0)]
var grid_anchor = null

func _ready():
	pass

func _process(delta):
	if selected:
		global_position = lerp(global_position, get_global_mouse_position(), 25 * delta)

func load_item(a_ItemID: String) -> void:
	item_ID = a_ItemID
	var data = DataHandler.item_data[item_ID]

	if data.has("Operator") and str(data["Operator"]) != "":
		operator = str(data["Operator"])
		value = 0
	elif data.has("Value") and int(data["Value"]) != 0:
		value = int(data["Value"])
		operator = ""


	# Ícone
	var Icon_path = "res://Inventory/Sprites/" + item_ID + ".png"
	IconRect_path.texture = load(Icon_path)




func _snap_to(destination):
	var tween = get_tree().create_tween()
	#separate cases to avoid snapping errors
	if int(rotation_degrees) % 180 == 0:
		destination += IconRect_path.size/2
	else:
		var temp_xy_switch = Vector2(IconRect_path.size.y,IconRect_path.size.x)
		destination += temp_xy_switch/2
	tween.tween_property(self, "global_position", destination, 0.15).set_trans(Tween.TRANS_SINE)
	selected = false
