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
				target_slot.add_item(item)
				if target_slot.get_used_bytes() >= 4:
					target_slot.state = target_slot.States.TAKEN
				elif target_slot.get_used_bytes() > 0:
					target_slot.state = target_slot.States.PARTIAL
				target_slot.set_color(target_slot.state)
		call_deferred("_position_item", item, slot)


func _position_item(item, slot):
	await get_tree().process_frame
	if is_instance_valid(item) and is_instance_valid(slot):
		var base_pos = slot.global_position + Vector2(32, 32)
		
		var current_grid = [null, null, null, null]
		var my_pos = 0
		
		for it in slot.items_stored:
			var sz = it.get_size_bytes() if it.has_method("get_size_bytes") else 4
			var pos_found = 0
			if sz >= 4:
				current_grid[0] = it; current_grid[1] = it; current_grid[2] = it; current_grid[3] = it
				pos_found = 0
			elif sz == 2:
				if current_grid[0] == null and current_grid[1] == null:
					current_grid[0] = it; current_grid[1] = it
					pos_found = 0
				elif current_grid[2] == null and current_grid[3] == null:
					current_grid[2] = it; current_grid[3] = it
					pos_found = 2
			elif sz == 1:
				for i in range(4):
					if current_grid[i] == null:
						current_grid[i] = it
						pos_found = i
						break
			if it == item:
				my_pos = pos_found
				break
				
		var offset = Vector2(0, 0)
		var item_bytes = item.get_size_bytes() if item.has_method("get_size_bytes") else 4
		
		if item_bytes == 1:
			if my_pos == 0: offset = Vector2(-16, -16)
			elif my_pos == 1: offset = Vector2(-16, 16)
			elif my_pos == 2: offset = Vector2(16, -16)
			elif my_pos == 3: offset = Vector2(16, 16)
		elif item_bytes == 2:
			if my_pos == 0: offset = Vector2(-16, 0)
			else: offset = Vector2(16, 0)
			
		item.global_position = base_pos + offset


func total_bytes_used() -> int:
	var total = 0
	var counted := {}
	for slot in slots_array:
		for it in slot.items_stored:
			if it and it.has_method("get_size_bytes") and not counted.has(it):
				counted[it] = true
				total += it.get_size_bytes()
	return total


func can_place_item(item, slot) -> bool:
	if not item or not slot:
		return false
	var item_bytes = item.get_size_bytes() if item.has_method("get_size_bytes") else 4
	
	for offset in item.item_grids:
		var idx = slot.slot_ID + int(offset.x) + int(offset.y) * grid_columns
		if idx < 0 or idx >= slots_array.size():
			return false
		var target_slot = slots_array[idx]
		
		# Simulando o espaço de memória (4 blocos de 1 byte por slot)
		var current_grid = [null, null, null, null]
		for it in target_slot.items_stored:
			if it == item: continue
			var sz = it.get_size_bytes() if it.has_method("get_size_bytes") else 4
			if sz >= 4:
				current_grid[0] = it; current_grid[1] = it; current_grid[2] = it; current_grid[3] = it
			elif sz == 2:
				if current_grid[0] == null and current_grid[1] == null:
					current_grid[0] = it; current_grid[1] = it
				elif current_grid[2] == null and current_grid[3] == null:
					current_grid[2] = it; current_grid[3] = it
			elif sz == 1:
				for i in range(4):
					if current_grid[i] == null:
						current_grid[i] = it
						break
		
		var can_fit = false
		if item_bytes >= 4:
			can_fit = (current_grid[0] == null and current_grid[1] == null and current_grid[2] == null and current_grid[3] == null)
		elif item_bytes == 2:
			can_fit = (current_grid[0] == null and current_grid[1] == null) or (current_grid[2] == null and current_grid[3] == null)
		elif item_bytes == 1:
			can_fit = (current_grid[0] == null or current_grid[1] == null or current_grid[2] == null or current_grid[3] == null)
			
		if not can_fit:
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
		target_slot.add_item(item)
		if target_slot.get_used_bytes() >= 4:
			target_slot.state = target_slot.States.TAKEN
		elif target_slot.get_used_bytes() > 0:
			target_slot.state = target_slot.States.PARTIAL
		target_slot.set_color(target_slot.state)
	item.grid_anchor = slot
	var parent = item.get_parent()
	if parent != grid_container:
		if parent:
			parent.remove_child(item)
		grid_container.add_child(item)
	_position_item(item, slot)


func remove_item(item):
	for slot in slots_array:
		if slot.items_stored.has(item):
			slot.remove_item(item)
			if slot.get_used_bytes() == 0:
				slot.state = slot.States.FREE
			elif slot.get_used_bytes() < 4:
				slot.state = slot.States.PARTIAL
			slot.set_color(slot.state)


func clear_all_items():
	if not grid_container:
		push_error("InventoryGrid: grid_container is null.")
		return
	for slot in slots_array:
		for item in slot.items_stored.duplicate():
			if item.get_parent() == grid_container:
				grid_container.remove_child(item)
			item.queue_free()
		slot.clear_items()
		slot.state = slot.States.FREE
		slot.set_color(slot.state)
	initial_items = []


func remove_item_single_slot(slot):
	# Compatível com código antigo que liberava um slot do pool
	if slot.items_stored.size() > 0:
		var it = slot.items_stored[0]
		remove_item(it)


func _on_slot_entered(slot):
	slot_entered.emit(slot)


func _on_slot_exited(slot):
	slot_exited.emit(slot)


func _on_slot_item_changed(slot):
	item_changed.emit(slot)
