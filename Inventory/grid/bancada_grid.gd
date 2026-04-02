class_name BancadaGrid
extends GridContainer

signal slot_entered(slot)
signal slot_exited(slot)
signal item_changed(slot)

@export var number_of_slots: int = 10
@export var grid_columns: int = 5
@export var initial_items: Array[String] = []

@onready var grid_container = self  # se for o próprio GridContainer

var slots_array: Array = []

func _ready():
	if grid_columns < 1:
		grid_columns = 1
	columns = grid_columns
	_create_slots()
	_fill_initial_items()

func _create_slots():
	for i in range(number_of_slots):
		var slot = preload("res://Inventory/slots/slot.tscn").instantiate()
		slot.slot_ID = 100 + i
		add_child(slot)
		slots_array.append(slot)
		slot.slot_entered.connect(_on_slot_entered)
		slot.slot_exited.connect(_on_slot_exited)
		slot.item_changed.connect(_on_slot_item_changed)

func clear_initial_items():
	initial_items = []

func _fill_initial_items():
	for i in range(min(initial_items.size(), number_of_slots)):
		var item_id = initial_items[i]
		if item_id.is_empty():
			continue
		var slot = slots_array[i]
		var item = preload("res://Inventory/Items/Item.tscn").instantiate()
		item.load_item(item_id)
		add_child(item)
		item.global_position = slot.global_position + Vector2(25, 25)
		item.grid_anchor = slot
		slot.state = slot.States.TAKEN
		slot.item_stored = item
		slot.set_item(item)

func remove_item(slot):
	if slot.item_stored:
		slot.state = slot.States.FREE
		slot.item_stored = null
		slot.set_item(null)

func clear_all_items():
	for slot in slots_array:
		if slot.item_stored:
			var item = slot.item_stored
			if item.get_parent() == self:
				remove_child(item)
			item.queue_free()
			slot.state = slot.States.FREE
			slot.item_stored = null
			slot.set_item(null)
	initial_items = []

func _on_slot_entered(slot): slot_entered.emit(slot)
func _on_slot_exited(slot): slot_exited.emit(slot)
func _on_slot_item_changed(slot): item_changed.emit(slot)
