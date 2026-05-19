extends "res://Inventory/fases/phase_base.gd"

const ItemRef = preload("res://Inventory/Items/item.gd")

var config: TypeBoxPhaseConfig

var type_boxes: Dictionary = {} # { DataType : { container: HBoxContainer, slots: Array, used_bytes: int } }
var global_capacity: int = 8

var pending_raw_values: int = 0
var all_slots: Array = []

@onready var boxes_vbox = VBoxContainer.new()

func _ready():
	super._ready()
	
	# Pega o config do PhaseRunner
	if PhaseRunner.has_method("take_type_box_config_if_any"):
		config = PhaseRunner.take_type_box_config_if_any()
		
	if not config:
		config = TypeBoxPhaseConfig.new()
		config.initial_raw_values = PackedStringArray(["250", "3.14", "1"])
		config.capacity_bytes = 8
		config.box_slot_count = 5
		config.randomize_values = false
		config.allow_int = true
		config.allow_float = true
		config.allow_short = true
		
	global_capacity = config.capacity_bytes
	
	# Limpa a área da mochila para colocar nossas caixas
	for child in backpack_container.get_parent().get_children():
		if child == backpack_container:
			child.queue_free()
			
	all_slots.clear()
	
	boxes_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boxes_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$HBox/BackpackPanel/MarginContainer/VBoxContainer/ScrollContainer.add_child(boxes_vbox)
	
	_create_boxes()
	_populate_pool()
	_update_bytes_label()
	_update_hint()

func _process(delta):
	# Detect mouse hover manually
	var new_current = null
	var mouse_pos = get_global_mouse_position()
	for slot in all_slots:
		if slot.get_global_rect().has_point(mouse_pos):
			new_current = slot
			break
			
	if current_slot != new_current:
		if current_slot:
			_on_box_slot_exited(current_slot)
		if new_current:
			if new_current.has_meta("is_type_box"):
				_on_box_slot_entered(new_current)
			elif new_current.has_meta("is_pool"):
				_on_pool_slot_entered(new_current)

	if item_held:
		item_held.global_position = lerp(item_held.global_position, get_global_mouse_position(), 25 * delta)
		if Input.is_action_just_pressed("select_item"):
			if current_slot and can_place:
				_place_item()
	else:
		if Input.is_action_just_pressed("select_item"):
			if current_slot and current_slot.has_meta("item_stored") and current_slot.get_meta("item_stored") != null:
				_pick_item()

func _update_phase_title() -> void:
	if phase_title:
		phase_title.text = "Fase: Caixas de Tipagem"

func _tutorial_intro_id() -> String:
	return "type_box_phase_intro"

func _create_boxes():
	var types = []
	if config.allow_int: types.append({"type": ItemRef.DataType.INT, "name": "Int", "color": Color.BLUE})
	if config.allow_short: types.append({"type": ItemRef.DataType.SHORT_INT, "name": "Short", "color": Color.CYAN})
	if config.allow_float: types.append({"type": ItemRef.DataType.FLOAT, "name": "Float", "color": Color.RED})
	if config.allow_double: types.append({"type": ItemRef.DataType.DOUBLE, "name": "Double", "color": Color.MAGENTA})
	if config.allow_fp8: types.append({"type": ItemRef.DataType.FP8, "name": "FP8", "color": Color.VIOLET})
	if config.allow_fp16: types.append({"type": ItemRef.DataType.FP16, "name": "FP16", "color": Color.GOLD})
	if config.allow_bool: types.append({"type": ItemRef.DataType.BOOLEAN, "name": "Boolean", "color": Color.GREEN})
	
	for t in types:
		var box_container = HBoxContainer.new()
		
		var title = Label.new()
		title.text = "Caixa " + t.name
		title.add_theme_color_override("font_color", t.color)
		title.custom_minimum_size = Vector2(120, 0)
		box_container.add_child(title)
		
		var slot_container = HBoxContainer.new()
		box_container.add_child(slot_container)
		
		# Criar slots base para cada caixa usando a configuração
		var slots = []
		for i in range(config.box_slot_count):
			var slot = ColorRect.new()
			slot.custom_minimum_size = Vector2(50, 50)
			slot.color = Color(0.15, 0.15, 0.15, 0.8) # Fundo escuro simples
			
			# Usamos meta para identificar a caixa e o tipo
			slot.set_meta("is_type_box", true)
			slot.set_meta("box_type", t.type)
			slot.set_meta("box_name", t.name)
			slot.set_meta("item_stored", null)
			
			slot_container.add_child(slot)
			slots.append(slot)
			all_slots.append(slot)
			
		type_boxes[t.type] = {
			"container": box_container,
			"slots": slots,
			"used_bytes": 0,
			"type_name": t.name
		}
		
		boxes_vbox.add_child(box_container)

func _populate_pool():
	# Criamos um InventoryGrid dinâmico para o Pool se não existir, ou usamos o base
	var pool_grid_node = pool_container
	# Limpar itens do pool
	for child in pool_grid_node.get_children():
		child.queue_free()
		
	pending_raw_values = 0
	
	var values_to_spawn = []
	if config.randomize_values:
		# Gera 4 valores desafiadores aleatórios
		for r in range(4):
			var case_type = randi() % 4
			match case_type:
				0: values_to_spawn.append("%.4f" % randf_range(-1.0, 1.0)) # Exige float ou double (muita precisão)
				1: values_to_spawn.append(str(randi_range(33000, 50000))) # Estoura short_int, exige int
				2: values_to_spawn.append(str(randi_range(0, 1))) # Ideal para boolean
				3: values_to_spawn.append("%.1f" % randf_range(100.0, 1000.0)) # Float comum
	else:
		values_to_spawn = config.initial_raw_values
	
	for raw_val_str in values_to_spawn:
		var slot = ColorRect.new()
		slot.custom_minimum_size = Vector2(50, 50)
		slot.color = Color(0.15, 0.15, 0.15, 0.8)
		slot.set_meta("is_pool", true)
		slot.set_meta("item_stored", null)
		
		var item = preload("res://Inventory/Items/Item.tscn").instantiate()
		item.data_type = ItemRef.DataType.RAW
		item.value_float = float(raw_val_str)
		item.update_label_display()
		
		slot.add_child(item)
		item.position = Vector2(25, 25) # center
		slot.set_meta("item_stored", item)
		
		pool_grid_node.add_child(slot)
		all_slots.append(slot)
		pending_raw_values += 1

func _on_box_slot_entered(slot):
	current_slot = slot
	if item_held and item_held.data_type == ItemRef.DataType.RAW:
		can_place = true
		hint_label.text = "Solte o valor aqui para converter para " + slot.get_meta("box_name") + "."
	else:
		can_place = false
		if item_held:
			hint_label.text = "Você só pode colocar valores RAW nestas caixas."

func _on_pool_slot_entered(slot):
	current_slot = slot
	if item_held:
		can_place = true
		hint_label.text = "Solte o valor de volta no pool."

func _on_box_slot_exited(slot):
	if current_slot == slot:
		current_slot = null
		can_place = false
		_update_hint()

func _place_item():
	if not can_place or not current_slot: return
	
	if current_slot.has_meta("is_type_box"):
		if current_slot.get_meta("item_stored") != null:
			hint_label.text = "Slot já ocupado!"
			return
			
		var target_type = current_slot.get_meta("box_type")
		var target_name = current_slot.get_meta("box_name")
		var val_to_convert = item_held.value_float
		
		# Verifica conversão
		var deg = _check_degradation(target_name, val_to_convert)
		if deg.has_warning:
			# FASE FALHA se houver degradação em caixa de tipagem
			var dlg = AcceptDialog.new()
			dlg.dialog_text = "FALHA NA CONVERSÃO!\n" + deg.message + "\n\nO valor " + str(val_to_convert) + " não é adequado para " + target_name + "."
			dlg.title = "Erro de Tipagem"
			add_child(dlg)
			dlg.popup_centered(Vector2(400, 150))
			await dlg.confirmed
			dlg.queue_free()
			
			# Retorna item pro pool (simplesmente resetar a posição para o mouse não basta, precisa de um slot do pool)
			# Para simplificar, deixa ele no mouse e não finaliza a colocação
			return
		
		var final_val = deg.degraded_value
		item_held.set_value_by_type(final_val, target_type)
		item_held.update_label_display()
		
		if item_held.get_parent() != current_slot:
			item_held.get_parent().remove_child(item_held)
			current_slot.add_child(item_held)
			
		item_held.position = Vector2(25, 25)
		current_slot.set_meta("item_stored", item_held)
		item_held.selected = false
		item_held = null
		can_place = false
		pending_raw_values -= 1
		
		_update_bytes_label()
		_update_hint()
		_update_next_button_state()
		
	elif current_slot.has_meta("is_pool"):
		if current_slot.get_meta("item_stored") != null:
			return
			
		if item_held.data_type != ItemRef.DataType.RAW:
			# Reverte para RAW se estava em uma caixa
			item_held.set_value_by_type(item_held.value_float, ItemRef.DataType.RAW)
			pending_raw_values += 1
			
		if item_held.get_parent() != current_slot:
			item_held.get_parent().remove_child(item_held)
			current_slot.add_child(item_held)
			
		item_held.position = Vector2(25, 25)
		current_slot.set_meta("item_stored", item_held)
		item_held.selected = false
		item_held = null
		can_place = false
		
		_update_bytes_label()
		_update_hint()
		_update_next_button_state()

func _pick_item():
	var slot = current_slot
	item_held = slot.get_meta("item_stored")
	if not item_held: return
	
	item_held.selected = true
	item_held.get_parent().remove_child(item_held)
	add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	
	slot.set_meta("item_stored", null)
	
	if slot.has_meta("is_type_box"):
		_update_bytes_label()
		_update_hint()
		_update_next_button_state()

func total_bytes_used() -> int:
	var total = 0
	for type_info in type_boxes.values():
		for slot in type_info.slots:
			var item = slot.get_meta("item_stored")
			if item:
				total += item.get_size_bytes()
	return total

func _update_bytes_label():
	var used = total_bytes_used()
	var cap = global_capacity
	if bytes_label:
		bytes_label.text = "Memória Global: %d / %d bytes" % [used, cap]
		if used > cap:
			bytes_label.text += " — OVERFLOW DE MEMÓRIA!"
			bytes_label.add_theme_color_override("font_color", Color.RED)
		else:
			bytes_label.add_theme_color_override("font_color", Color.WHITE)

func _update_hint():
	if not hint_label: return
	var used = total_bytes_used()
	var cap = global_capacity
	
	if used > cap:
		hint_label.text = "Limite de memória excedido! Tente tipos mais leves."
	elif pending_raw_values > 0:
		hint_label.text = "Aloque todos os valores do pool nas caixas."
	else:
		hint_label.text = "Todos os valores alocados e dentro da memória! Pronto para avançar."

func is_phase_success() -> bool:
	var used = total_bytes_used()
	if used > global_capacity: return false
	if pending_raw_values > 0: return false
	return true
