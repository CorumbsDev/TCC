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
	# Remove placeholders velhos e inúteis para não criar Grids duplos (que esmagam o conteúdo)
	var bp_scroll = backpack_container.get_parent()
	var bp_vbox = bp_scroll.get_parent()
	bp_vbox.remove_child(bp_scroll)
	bp_scroll.queue_free()
	
	var pl_vbox = pool_container.get_parent()
	pl_vbox.remove_child(pool_container)
	pool_container.queue_free()
	
	var backpack: InventoryGrid = GRID_SCENE.instantiate()
	var pool: InventoryGrid = GRID_SCENE.instantiate()
	_apply_challenge_exports(backpack)
	_apply_pool_exports(pool)
	
	bp_vbox.add_child(backpack)
	pl_vbox.add_child(pool)
	
	# Atualiza referências e limpa tamanhos travados
	backpack_container = backpack
	pool_container = pool
	
	backpack.custom_minimum_size = Vector2(0, 0)
	backpack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	backpack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool.custom_minimum_size = Vector2(0, 0)
	pool.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pool.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
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
	
	if config.use_converter and converter_slot == null:
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		var lbl = Label.new()
		lbl.text = "Int ↔ Float"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(lbl)
		
		var center = CenterContainer.new()
		center.custom_minimum_size = Vector2(64, 64)
		vbox.add_child(center)
		
		converter_slot = preload("res://Inventory/slots/slot.tscn").instantiate()
		converter_slot.slot_ID = 999
		center.add_child(converter_slot)
		
		converter_slot.slot_entered.connect(_on_slot_entered)
		converter_slot.slot_exited.connect(_on_slot_exited)
		
		# --- Double Slot Panel ---
		var d_panel = PanelContainer.new()
		var d_vbox = VBoxContainer.new()
		d_panel.add_child(d_vbox)
		
		var d_lbl = Label.new()
		d_lbl.text = "Para Double\n(4 slots)"
		d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d_lbl.add_theme_font_size_override("font_size", 14)
		d_vbox.add_child(d_lbl)
		
		var d_center = CenterContainer.new()
		d_center.custom_minimum_size = Vector2(64, 64)
		d_vbox.add_child(d_center)
		
		double_slot = preload("res://Inventory/slots/slot.tscn").instantiate()
		double_slot.slot_ID = 998
		d_center.add_child(double_slot)
		
		double_slot.slot_entered.connect(_on_slot_entered)
		double_slot.slot_exited.connect(_on_slot_exited)
		
		# --- Short Slot Panel ---
		var s_panel = PanelContainer.new()
		var s_vbox = VBoxContainer.new()
		s_panel.add_child(s_vbox)
		
		var s_lbl = Label.new()
		s_lbl.text = "Para Short\n(0.5 slot)"
		s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_lbl.add_theme_font_size_override("font_size", 14)
		s_vbox.add_child(s_lbl)
		
		var s_center = CenterContainer.new()
		s_center.custom_minimum_size = Vector2(64, 64)
		s_vbox.add_child(s_center)
		
		short_slot = preload("res://Inventory/slots/slot.tscn").instantiate()
		short_slot.slot_ID = 997
		s_center.add_child(short_slot)
		
		short_slot.slot_entered.connect(_on_slot_entered)
		short_slot.slot_exited.connect(_on_slot_exited)
		
		# --- Boolean Slot Panel ---
		var b_panel = PanelContainer.new()
		var b_vbox = VBoxContainer.new()
		b_panel.add_child(b_vbox)
		
		var b_lbl = Label.new()
		b_lbl.text = "Para Bool\n(0.25 slot)"
		b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b_lbl.add_theme_font_size_override("font_size", 14)
		b_vbox.add_child(b_lbl)
		
		var b_center = CenterContainer.new()
		b_center.custom_minimum_size = Vector2(64, 64)
		b_vbox.add_child(b_center)
		
		boolean_slot = preload("res://Inventory/slots/slot.tscn").instantiate()
		boolean_slot.slot_ID = 996
		b_center.add_child(boolean_slot)
		
		boolean_slot.slot_entered.connect(_on_slot_entered)
		boolean_slot.slot_exited.connect(_on_slot_exited)
		
		var pool_vbox = pool_container.get_parent()
		if pool_vbox:
			var tools_container = pool_vbox.get_node_or_null("ConvertersContainer")
			var tools_hbox = null
			if not tools_container:
				tools_container = VBoxContainer.new()
				tools_container.name = "ConvertersContainer"
				
				var toggle_btn = Button.new()
				toggle_btn.text = "▼ Conversores"
				
				tools_hbox = HFlowContainer.new()
				tools_hbox.name = "ConvertersHBox"
				tools_hbox.alignment = FlowContainer.ALIGNMENT_CENTER
				tools_hbox.add_theme_constant_override("h_separation", 15)
				tools_hbox.add_theme_constant_override("v_separation", 15)
				
				toggle_btn.pressed.connect(func():
					tools_hbox.visible = not tools_hbox.visible
					toggle_btn.text = "▼ Conversores" if tools_hbox.visible else "▶ Conversores"
				)
				
				tools_container.add_child(toggle_btn)
				tools_container.add_child(tools_hbox)
				
				pool_vbox.add_child(tools_container)
				# Mover o container para ficar imediatamente acima da grid de orbes
				pool_vbox.move_child(tools_container, pool_container.get_index())
			else:
				tools_hbox = tools_container.get_node("ConvertersHBox")
				
			tools_hbox.add_child(panel)
			tools_hbox.add_child(d_panel)
			tools_hbox.add_child(s_panel)
			tools_hbox.add_child(b_panel)
		else:
			add_child(panel)
			add_child(d_panel)
			add_child(s_panel)
			add_child(b_panel)
			
	if config.use_converter:
		_create_calculator_ui()

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


func _create_calculator_ui():
	var pool_vbox = pool_container.get_parent()
	if not pool_vbox:
		return
		
	# Previne criação duplicada se já existir
	if pool_vbox.has_node("BottomToolsContainer"):
		return
		
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "Calculadora"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)
	
	var c1 = CenterContainer.new()
	c1.custom_minimum_size = Vector2(64, 64)
	calc_slot_1 = preload("res://Inventory/slots/slot.tscn").instantiate()
	calc_slot_1.slot_ID = 901
	c1.add_child(calc_slot_1)
	hbox.add_child(c1)
	
	calc_op_btn = Button.new()
	calc_op_btn.text = "+"
	calc_op_btn.custom_minimum_size = Vector2(40, 40)
	calc_op_btn.add_theme_font_size_override("font_size", 24)
	calc_op_btn.pressed.connect(func():
		calc_op_btn.text = "-" if calc_op_btn.text == "+" else "+"
	)
	hbox.add_child(calc_op_btn)
	
	var c2 = CenterContainer.new()
	c2.custom_minimum_size = Vector2(64, 64)
	calc_slot_2 = preload("res://Inventory/slots/slot.tscn").instantiate()
	calc_slot_2.slot_ID = 902
	c2.add_child(calc_slot_2)
	hbox.add_child(c2)
	
	calc_slot_1.slot_entered.connect(_on_slot_entered)
	calc_slot_1.slot_exited.connect(_on_slot_exited)
	calc_slot_2.slot_entered.connect(_on_slot_entered)
	calc_slot_2.slot_exited.connect(_on_slot_exited)
	
	var tools_container = VBoxContainer.new()
	tools_container.name = "BottomToolsContainer"
	
	var toggle_btn = Button.new()
	toggle_btn.text = "▲ Ferramentas"
	toggle_btn.custom_minimum_size = Vector2(150, 35) # Força o botão a ter tamanho visível
	
	var tools_hbox = HFlowContainer.new()
	tools_hbox.name = "BottomToolsHBox"
	tools_hbox.alignment = FlowContainer.ALIGNMENT_CENTER
	tools_hbox.add_theme_constant_override("h_separation", 15)
	tools_hbox.add_theme_constant_override("v_separation", 15)
	tools_hbox.visible = false
	
	toggle_btn.pressed.connect(func():
		tools_hbox.visible = not tools_hbox.visible
		toggle_btn.text = "▼ Ferramentas" if tools_hbox.visible else "▲ Ferramentas"
	)
	
	tools_container.add_child(tools_hbox)
	tools_container.add_child(toggle_btn)
	
	pool_vbox.add_child(tools_container)
	# Força a ficar logo abaixo do pool de itens
	pool_vbox.move_child(tools_container, pool_container.get_index() + 1)
	
	var container_para_adicionar = tools_hbox
	
	container_para_adicionar.add_child(panel)
	
	var insp_panel = PanelContainer.new()
	var insp_vbox = VBoxContainer.new()
	insp_panel.add_child(insp_vbox)
	
	var insp_lbl = Label.new()
	insp_lbl.text = "Inspecionar"
	insp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	insp_lbl.add_theme_font_size_override("font_size", 14)
	insp_vbox.add_child(insp_lbl)
	
	var insp_c = CenterContainer.new()
	insp_c.custom_minimum_size = Vector2(64, 64)
	insp_vbox.add_child(insp_c)
	
	inspect_slot = preload("res://Inventory/slots/slot.tscn").instantiate()
	inspect_slot.slot_ID = 903
	insp_c.add_child(inspect_slot)
	
	inspect_slot.slot_entered.connect(_on_slot_entered)
	inspect_slot.slot_exited.connect(_on_slot_exited)
	
	container_para_adicionar.add_child(insp_panel)


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
