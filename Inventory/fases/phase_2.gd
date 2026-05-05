extends "res://Inventory/fases/phase_base.gd"

const GRID_SCENE := preload("res://Inventory/InventoryGrid.tscn")
const ITEM_SCENE := preload("res://Inventory/Items/Item.tscn")

@export var config: PhaseConfig


func _ready():
	super()
	var injected: PhaseConfig = PhaseRunner.take_backpack_config_if_any()
	var cfg := injected if injected != null else config
	if cfg == null:
		cfg = PhaseConfig.new()
		cfg.initial_backpack_csv = "1_i, 2_i, 3_i"
		cfg.pool_slot_count = 12
		cfg.random_pool = PackedStringArray()
	config = cfg
	config.apply_constraints()
	_clear_container(backpack_container)
	_clear_container(pool_container)
	var backpack: InventoryGrid = GRID_SCENE.instantiate()
	var pool: InventoryGrid = GRID_SCENE.instantiate()
	_apply_challenge_exports(backpack)
	_apply_pool_exports(pool)
	backpack_container.add_child(backpack)
	pool_container.add_child(pool)
	backpack.clear_all_items()
	pool.clear_all_items()
	setup_grids(backpack, pool)
	call_deferred("_initialize_game", backpack, pool)


func _update_phase_title() -> void:
	if phase_title:
		phase_title.text = "Mochila | Cap: %d | Slots: %d | Pool: %d | Valores: %d-%d" % [
			config.capacity_bytes,
			config.backpack_slot_count,
			config.pool_slot_count,
			config.spawn_int_min,
			config.spawn_int_max
		]


func _apply_challenge_exports(grid: InventoryGrid):
	grid.capacity_bytes = config.capacity_bytes
	grid.grid_columns = config.grid_columns
	grid.number_of_slots = config.backpack_slot_count
	grid.initial_items = []


func _apply_pool_exports(grid: InventoryGrid):
	grid.capacity_bytes = 999999
	grid.grid_columns = config.pool_grid_columns
	grid.number_of_slots = config.pool_slot_count
	grid.initial_items = []


func _initialize_game(backpack: InventoryGrid, pool: InventoryGrid):
	backpack.clear_all_items()
	pool.clear_all_items()
	for entry in config.get_backpack_entry_list():
		_place_parsed_item_in_challenge(backpack, entry)
	for entry in config.initial_pool_items:
		if str(entry).strip_edges().is_empty():
			continue
		var item := _make_item_from_entry(str(entry))
		if item == null:
			continue
		if not pool.try_place_item_automatically(item):
			item.queue_free()
			push_warning("Pool: sem espaço para item inicial: %s" % entry)
	var min_extra := config.min_bytes_random_pool
	if min_extra <= 0:
		min_extra = max(0, backpack.capacity_bytes - backpack.total_bytes_used())
	_generate_extra_pool_items(pool, min_extra)
	_update_bytes_label()
	_update_hint()


func _clear_container(container: Node):
	for child in container.get_children():
		child.queue_free()


func _make_item_from_entry(entry: String) -> Node2D:
	var e := entry.strip_edges()
	if e.is_empty():
		return null
	if DataHandler and DataHandler.item_data.has(e):
		var by_id: Node2D = ITEM_SCENE.instantiate()
		by_id.load_item(e)
		# Nesta fase, o objetivo é trabalhar apenas com INT (1 byte cada).
		if by_id.data_type != by_id.DataType.INT:
			by_id.queue_free()
			push_warning("Nesta fase, use apenas IDs de INT. Entrada: %s" % e)
			return null
		return by_id
	if e.begins_with("item_"):
		if DataHandler and DataHandler.item_data.has(e):
			var by_id2: Node2D = ITEM_SCENE.instantiate()
			by_id2.load_item(e)
			if by_id2.data_type != by_id2.DataType.INT:
				by_id2.queue_free()
				push_warning("Nesta fase, use apenas IDs de INT. Entrada: %s" % e)
				return null
			return by_id2
		push_warning("ID não cadastrado no DataHandler: %s" % e)
		return null
	var parts := e.split("_")
	if parts.size() < 2:
		push_warning("Entrada inválida: %s" % e)
		return null
	var type_str := parts[parts.size() - 1].to_lower()
	if type_str != "i":
		push_warning("Nesta fase, use apenas INT no formato X_i (ex: 3_i). Entrada inválida: %s" % e)
		return null
	var value_str := parts[0]
	for pi in range(1, parts.size() - 1):
		value_str += "_" + parts[pi]
	var shorthand: Node2D = ITEM_SCENE.instantiate()
	var raw := int(value_str)
	shorthand.set_value_directly(config.clamp_int_value(raw))
	return shorthand


func _place_parsed_item_in_challenge(backpack: InventoryGrid, entry: String):
	var item := _make_item_from_entry(entry)
	if item == null:
		return
	var placed := false
	for slot in backpack.slots_array:
		if backpack.can_place_item(item, slot):
			backpack.place_item(item, slot)
			placed = true
			break
	if not placed:
		item.queue_free()
		push_warning("Mochila: não coube %s" % entry)


func _generate_extra_pool_items(pool: InventoryGrid, min_extra_bytes: int):
	var total := 0
	var guard := 0
	while total < min_extra_bytes and guard < pool.number_of_slots * 4:
		guard += 1
		var item: Node2D = ITEM_SCENE.instantiate()
		if config.random_pool.size() > 0:
			var id := str(config.random_pool[randi() % config.random_pool.size()])
			if not DataHandler or not DataHandler.item_data.has(id):
				item.queue_free()
				continue
			item.load_item(id)
		else:
			# Nesta versão, o pool é composto apenas por INT (1 byte).
			item.set_value_directly(randi_range(config.spawn_int_min, config.spawn_int_max))
		var sz: int = item.get_size_bytes() if item.has_method("get_size_bytes") else 1
		if not pool.try_place_item_automatically(item):
			item.queue_free()
			break
		total += sz


func _tutorial_intro_id() -> String:
	return TutorialTexts.KEY_PHASE_BACKPACK


func _pedagogy_extra_when_full() -> String:
	if not backpack_grid:
		return ""
	var seen := {}
	var parts: PackedStringArray = PackedStringArray()
	var total := 0
	for slot in backpack_grid.slots_array:
		var it = slot.item_stored
		if it == null or seen.has(it):
			continue
		seen[it] = true
		var b: int = it.get_size_bytes() if it.has_method("get_size_bytes") else 1
		total += b
		parts.append("%s → %d byte(s)" % [_item_pedagogy_label(it), b])
	if parts.is_empty():
		return ""
	var joined := ""
	for i in range(parts.size()):
		if i > 0:
			joined += ", "
		joined += parts[i]
	return "Por que fecha? Cada item conta uma vez pelo seu tamanho em bytes: " + joined + ". Total = %d bytes." % total


func _item_pedagogy_label(it: Node) -> String:
	if it.has_method("get_item_info"):
		var info: Dictionary = it.get_item_info()
		var v = str(info.get("valor", "?"))
		var t = str(info.get("tipo", ""))
		return v + " (" + t + ")"
	if it.has_method("get_value_as_string"):
		return it.get_value_as_string()
	return str(it)


func _on_spawn_pressed():
	if item_held != null:
		return
	var item: Node2D = ITEM_SCENE.instantiate()
	add_child(item)
	if config.random_pool.size() > 0:
		var id := str(config.random_pool[randi() % config.random_pool.size()])
		if DataHandler and DataHandler.item_data.has(id):
			item.load_item(id)
			if item.data_type != item.DataType.INT:
				item.set_value_directly(randi_range(config.spawn_int_min, config.spawn_int_max))
		else:
			item.set_value_directly(randi_range(config.spawn_int_min, config.spawn_int_max))
	else:
		item.set_value_directly(randi_range(config.spawn_int_min, config.spawn_int_max))
	item.selected = true
	item_held = item
	_update_bytes_label()


func is_phase_success() -> bool:
	# Considera concluída quando os bytes usados na mochila atingem ou ultrapassam a capacidade
	if not backpack_grid:
		return false
	return backpack_grid.total_bytes_used() >= backpack_grid.capacity_bytes
