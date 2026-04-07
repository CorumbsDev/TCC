class_name InventoryGrid
extends Panel

signal slot_entered(slot)
signal slot_exited(slot)
signal item_changed(slot)

@export var capacity_bytes: int = 8
@export var number_of_slots: int = 8
@export var grid_columns: int = 4
@export var initial_items: Array[String] = ["item_number_5", "item_number_7", "item_operator_plus"]
@onready var grid_container = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer

var slots_array: Array = []


func _ready():
	if not grid_container:
		push_error("InventoryGrid: GridContainer inválido!")
		return
	grid_container.columns = grid_columns
	_create_slots()
	_fill_initial_items()


func _create_slots():
	for i in range(number_of_slots):
		var slot = preload("res://Inventory/slots/slot.tscn").instantiate()
		slot.slot_ID = i
		slot.state = slot.States.FREE
		grid_container.add_child(slot)
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
		grid_container.add_child(item)
		for offset in item.item_grids:
			var idx = slot.slot_ID + int(offset.x) + int(offset.y) * grid_columns
			if idx >= 0 and idx < slots_array.size():
				var target_slot = slots_array[idx]
				target_slot.state = target_slot.States.TAKEN
				target_slot.item_stored = item
				target_slot.set_item(item)
		call_deferred("_position_item", item, slot)


func _position_item(item, slot):
	await get_tree().process_frame
	if is_instance_valid(item) and is_instance_valid(slot):
		item.global_position = slot.global_position + Vector2(25, 25)


func total_bytes_used() -> int:
	var total = 0
	var counted := {}
	for slot in slots_array:
		var it = slot.item_stored
		if it and it.has_method("get_size_bytes") and not counted.has(it):
			counted[it] = true
			total += it.get_size_bytes()
	return total


func can_place_item(item, slot) -> bool:
	if not item or not slot:
		return false
	for offset in item.item_grids:
		var idx = slot.slot_ID + int(offset.x) + int(offset.y) * grid_columns
		if idx < 0 or idx >= slots_array.size():
			return false
		if slots_array[idx].state != slots_array[idx].States.FREE:
			return false
	return true


func find_first_free_anchor_for(item) -> Variant:
	for slot in slots_array:
		if can_place_item(item, slot):
			return slot
	return null


func try_place_item_automatically(item: Node) -> bool:
	var slot = find_first_free_anchor_for(item)
	if slot == null:
		return false
	place_item(item, slot)
	return true


func place_item(item, slot):
	if not grid_container:
		push_error("InventoryGrid: grid_container is null")
		return
	remove_item(item)
	for offset in item.item_grids:
		var idx = slot.slot_ID + int(offset.x) + int(offset.y) * grid_columns
		if idx < 0 or idx >= slots_array.size():
			continue
		var target_slot = slots_array[idx]
		target_slot.state = target_slot.States.TAKEN
		target_slot.item_stored = item
		target_slot.set_item(item)
	item.grid_anchor = slot
	var parent = item.get_parent()
	if parent != grid_container:
		if parent:
			parent.remove_child(item)
		grid_container.add_child(item)
	_position_item(item, slot)


func remove_item(item):
	for slot in slots_array:
		if slot.item_stored == item:
			slot.state = slot.States.FREE
			slot.item_stored = null
			slot.set_item(null)


func clear_all_items():
	if not grid_container:
		push_error("InventoryGrid: grid_container is null.")
		return
	for slot in slots_array:
		if slot.item_stored:
			var item = slot.item_stored
			if item.get_parent() == grid_container:
				grid_container.remove_child(item)
			item.queue_free()
			slot.state = slot.States.FREE
			slot.item_stored = null
			slot.set_item(null)
	initial_items = []


func remove_item_single_slot(slot):
	# Compatível com código antigo que liberava um slot do pool
	if slot.item_stored:
		var it = slot.item_stored
		remove_item(it)


func _on_slot_entered(slot):
	slot_entered.emit(slot)


func _on_slot_exited(slot):
	slot_exited.emit(slot)


func _on_slot_item_changed(slot):
	item_changed.emit(slot)
