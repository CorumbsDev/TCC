extends Control

@onready var btn_voltar = $TopBar/BtnVoltar
@onready var btn_help = get_node_or_null("TopBar/BtnHelp")
@onready var btn_proxima = get_node_or_null("TopBar/BtnProxima")
@onready var phase_title = get_node_or_null("TopBar/PhaseTitle")
@onready var btn_spawn = $HBox/BackpackPanel/MarginContainer/VBoxContainer/Header/BtnSpawn
@onready var bytes_label = $HBox/BackpackPanel/MarginContainer/VBoxContainer/BytesLabel
@onready var hint_label = $HBox/BackpackPanel/MarginContainer/VBoxContainer/HintLabel

@onready var backpack_container = $HBox/BackpackPanel/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var pool_container = $HBox/BancadaPanel/MarginContainer/VBoxContainer/GridContainer

var backpack_grid: InventoryGrid = null
var pool_grid: InventoryGrid = null
var converter_slot: TextureRect = null
var double_slot: TextureRect = null
var short_slot: TextureRect = null
var boolean_slot: TextureRect = null
var calc_slot_1: TextureRect = null
var calc_slot_2 = null
var calc_op_btn = null
var inspect_slot: TextureRect = null

var item_held = null
var current_slot = null
var can_place := false


func _ready():
	# Força a interface a não vazar da tela do jogo
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	btn_voltar.pressed.connect(_on_voltar_pressed)
	if btn_help:
		btn_help.pressed.connect(_on_help_pressed)
	if btn_proxima:
		btn_proxima.visible = PhaseRunner.should_show_next_button()
		btn_proxima.pressed.connect(_on_proxima_pressed)
		# Inicialmente atualizar estado (enabled/disabled) do botão Próxima
		call_deferred("_update_next_button_state")
	if btn_spawn:
		btn_spawn.pressed.connect(_on_spawn_pressed)
	# Conectar ao signal do PhaseRunner para feedback amigável
	PhaseRunner.phase_advance_blocked.connect(_on_phase_advance_blocked)
	call_deferred("_try_show_intro")
	call_deferred("_update_phase_title")


func _tutorial_intro_id() -> String:
	return ""


func _update_phase_title() -> void:
	"""Override this in subclasses to update the phase title with parameters"""
	if phase_title:
		phase_title.text = "Fase"


func _try_show_intro() -> void:
	var tid := _tutorial_intro_id()
	if tid.is_empty():
		return
	# Sempre mostra ao entrar na fase; o botão ? mantém reabertura manual.
	TutorialOverlay.open(self, tid, TutorialTexts.title_for(tid), TutorialTexts.body_for(tid), false)


func _on_help_pressed() -> void:
	var tid := _tutorial_intro_id()
	if tid.is_empty():
		return
	TutorialOverlay.open(self, tid, TutorialTexts.title_for(tid), TutorialTexts.body_for(tid), false)


func setup_grids(backpack: InventoryGrid, pool: InventoryGrid):
	backpack_grid = backpack
	pool_grid = pool
	backpack_grid.slot_entered.connect(_on_slot_entered)
	backpack_grid.slot_exited.connect(_on_slot_exited)
	backpack_grid.item_changed.connect(_on_slot_item_changed)
	pool_grid.slot_entered.connect(_on_slot_entered)
	pool_grid.slot_exited.connect(_on_slot_exited)
	pool_grid.item_changed.connect(_on_slot_item_changed)
	_update_bytes_label()
	_update_hint()


func _on_voltar_pressed():
	PhaseRunner.abort_sequence()
	get_tree().change_scene_to_file("res://Inventory/fases/main_menu.tscn")


func _on_proxima_pressed():
	# Verifica se a fase permite avanço; mostra modal amigável caso contrário
	if has_method("is_phase_success") and not is_phase_success():
		_show_not_ready_modal()
		return
	PhaseRunner.advance_from_phase()


func _on_phase_advance_blocked(reason: String):
	# Handler para o signal emitido pelo PhaseRunner quando avanço é bloqueado
	_show_not_ready_modal(reason)


func _show_not_ready_modal(custom_message: String = ""):
	# Cria e mostra um AcceptDialog temporário com mensagem clara
	var message := custom_message if custom_message != "" else "Você precisa completar o objetivo desta fase antes de avançar. Verifique as instruções e tente novamente."
	var dlg := AcceptDialog.new()
	dlg.dialog_text = message
	add_child(dlg)
	dlg.popup_centered_minsize(Vector2(400, 120))


func _update_next_button_state():
	if not btn_proxima:
		return
	# Se a cena atual implementa is_phase_success, usar seu retorno; caso contrário, permitir avanço
	if has_method("is_phase_success"):
		btn_proxima.disabled = not is_phase_success()
	else:
		btn_proxima.disabled = false


func _on_spawn_pressed():
	pass


func _on_slot_entered(slot):
	current_slot = slot
	if not item_held:
		return
	if slot == converter_slot:
		can_place = true
		hint_label.text = "Solte o orbe aqui para convertê-lo (Int ↔ Float)."
		_update_next_button_state()
	elif slot == double_slot:
		can_place = true
		hint_label.text = "Solte o orbe aqui para convertê-lo para Double (2 slots, Rosa)."
		_update_next_button_state()
	elif slot == short_slot:
		can_place = true
		hint_label.text = "Solte o orbe aqui para convertê-lo para Short Int (0.5 slot, Ciano)."
		_update_next_button_state()
	elif slot == boolean_slot:
		can_place = true
		hint_label.text = "Solte o orbe aqui para convertê-lo para Boolean (0.25 slot, Verde)."
		_update_next_button_state()
	elif slot == calc_slot_1 or slot == calc_slot_2:
		if slot.item_stored == null:
			can_place = true
			hint_label.text = "Solte o orbe na calculadora."
			_update_next_button_state()
		else:
			can_place = false
	elif slot == inspect_slot:
		if slot.item_stored == null:
			can_place = true
			hint_label.text = "Slot de inspeção."
			_update_next_button_state()
		else:
			can_place = false
	elif backpack_grid and slot in backpack_grid.slots_array:
		can_place = backpack_grid.can_place_item(item_held, slot)
		var need = item_held.get_size_bytes() if item_held.has_method("get_size_bytes") else 1
		var used = backpack_grid.total_bytes_used()
		if can_place and used + need > backpack_grid.capacity_bytes:
			can_place = false
			hint_label.text = "Não cabe! Este item usa %d byte(s). Falta(m) %d byte(s)." % [need, backpack_grid.capacity_bytes - used]
		elif not can_place:
			hint_label.text = "Slots ocupados ou não há espaço contíguo."
		else:
			_update_hint()
	elif pool_grid and slot in pool_grid.slots_array:
		can_place = pool_grid.can_place_item(item_held, slot)
		if not can_place:
			hint_label.text = "Pool: slots ocupados ou item não cabe nos slots livres."
		else:
			_update_hint()
	else:
		can_place = false


func _on_slot_exited(_slot):
	current_slot = null
	can_place = false
	_update_hint()


func _on_slot_item_changed(_slot):
	_update_bytes_label()
	_update_hint()


func _process(_delta):
	if item_held:
		item_held.global_position = get_global_mouse_position()
		if Input.is_action_just_pressed("select_item"):
			if current_slot and can_place:
				_place_item()
	else:
		if Input.is_action_just_pressed("select_item"):
			if current_slot and current_slot.item_stored:
				_pick_item()


func _place_item():
	if not can_place or not current_slot:
		return
		
	if current_slot == converter_slot:
		var atual_tipo = item_held.data_type
		if atual_tipo == item_held.DataType.INT:
			item_held.set_value_by_type(float(item_held.value), item_held.DataType.FLOAT)
		elif atual_tipo == item_held.DataType.FLOAT or atual_tipo == item_held.DataType.DOUBLE:
			item_held.set_value_by_type(int(item_held.value_float), item_held.DataType.INT)
		
		if item_held.has_method("update_label_display"):
			item_held.update_label_display()
		
		# Tira do pai antigo e coloca no current_slot se necessario
		if item_held.get_parent() != converter_slot:
			item_held.get_parent().remove_child(item_held)
			converter_slot.add_child(item_held)
		
		item_held.global_position = converter_slot.global_position + Vector2(25, 25)
		item_held.grid_anchor = converter_slot
		item_held.selected = false
		converter_slot.item_stored = item_held
		converter_slot.state = converter_slot.States.TAKEN
		item_held = null
		can_place = false
		_update_bytes_label()
		_update_hint()
		return
		
	if current_slot == double_slot:
		item_held.set_value_by_type(float(item_held.get_value_as_string()), item_held.DataType.DOUBLE)
		
		if item_held.has_method("update_label_display"):
			item_held.update_label_display()
		
		if item_held.get_parent() != double_slot:
			item_held.get_parent().remove_child(item_held)
			double_slot.add_child(item_held)
		
		item_held.global_position = double_slot.global_position + Vector2(25, 25)
		item_held.grid_anchor = double_slot
		item_held.selected = false
		double_slot.item_stored = item_held
		double_slot.state = double_slot.States.TAKEN
		item_held = null
		can_place = false
		_update_bytes_label()
		_update_hint()
		return
		
	if current_slot == short_slot:
		item_held.set_value_by_type(int(item_held.value), item_held.DataType.SHORT_INT)
		if item_held.has_method("update_label_display"):
			item_held.update_label_display()
		if item_held.get_parent() != short_slot:
			item_held.get_parent().remove_child(item_held)
			short_slot.add_child(item_held)
		item_held.global_position = short_slot.global_position + Vector2(25, 25)
		item_held.grid_anchor = short_slot
		item_held.selected = false
		short_slot.item_stored = item_held
		short_slot.state = short_slot.States.TAKEN
		item_held = null
		can_place = false
		_update_bytes_label()
		_update_hint()
		return
		
	if current_slot == boolean_slot:
		item_held.set_value_by_type(item_held.value != 0, item_held.DataType.BOOLEAN)
		if item_held.has_method("update_label_display"):
			item_held.update_label_display()
		if item_held.get_parent() != boolean_slot:
			item_held.get_parent().remove_child(item_held)
			boolean_slot.add_child(item_held)
		item_held.global_position = boolean_slot.global_position + Vector2(25, 25)
		item_held.grid_anchor = boolean_slot
		item_held.selected = false
		boolean_slot.item_stored = item_held
		boolean_slot.state = boolean_slot.States.TAKEN
		item_held = null
		can_place = false
		_update_bytes_label()
		_update_hint()
		return
		
	if current_slot == calc_slot_1 or current_slot == calc_slot_2 or current_slot == inspect_slot:
		if item_held.get_parent() != current_slot:
			item_held.get_parent().remove_child(item_held)
			current_slot.add_child(item_held)
		
		# Shrink DOUBLE visually while in calculator
		if item_held.data_type == item_held.DataType.DOUBLE:
			if item_held.has_method("_resize_visual"):
				var color_rect = item_held.get_node_or_null("ColorRect")
				if not color_rect:
					color_rect = item_held.get_node_or_null("ValueLabel").get_parent()
				if color_rect:
					item_held._resize_visual(color_rect, 1)
		
		item_held.global_position = current_slot.global_position + Vector2(25, 25)
		item_held.grid_anchor = current_slot
		item_held.selected = false
		current_slot.item_stored = item_held
		current_slot.state = current_slot.States.TAKEN
		item_held = null
		can_place = false
		
		_check_calculator()
		
		_update_bytes_label()
		_update_hint()
		return
		
	if current_slot in backpack_grid.slots_array:
		backpack_grid.place_item(item_held, current_slot)
	else:
		pool_grid.place_item(item_held, current_slot)
	item_held.selected = false
	item_held = null
	can_place = false
	_update_bytes_label()
	_update_hint()


func _pick_item():
	var slot = current_slot
	item_held = slot.item_stored
	item_held.selected = true
	item_held.get_parent().remove_child(item_held)
	add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	if slot == converter_slot:
		if converter_slot:
			converter_slot.item_stored = null
		if double_slot:
			double_slot.item_stored = null
		if short_slot:
			short_slot.item_stored = null
		if boolean_slot:
			boolean_slot.item_stored = null
		converter_slot.state = converter_slot.States.FREE
	elif slot == double_slot:
		double_slot.state = double_slot.States.FREE
		double_slot.item_stored = null
	elif slot == short_slot:
		short_slot.state = short_slot.States.FREE
		short_slot.item_stored = null
	elif slot == boolean_slot:
		boolean_slot.state = boolean_slot.States.FREE
		boolean_slot.item_stored = null
	elif slot == inspect_slot:
		inspect_slot.state = inspect_slot.States.FREE
		inspect_slot.item_stored = null
	elif slot == calc_slot_1 or slot == calc_slot_2:
		slot.state = slot.States.FREE
		slot.item_stored = null
		# Restore DOUBLE visual
		if item_held.data_type == item_held.DataType.DOUBLE:
			if item_held.has_method("_resize_visual"):
				var color_rect = item_held.get_node_or_null("ColorRect")
				if not color_rect:
					color_rect = item_held.get_node_or_null("ValueLabel").get_parent()
				if color_rect:
					item_held._resize_visual(color_rect, 2)
	elif backpack_grid and slot in backpack_grid.slots_array:
		backpack_grid.remove_item(item_held)
	elif pool_grid and slot in pool_grid.slots_array:
		pool_grid.remove_item(item_held)
	_update_bytes_label()
	_update_hint()


func _update_bytes_label():
	if not backpack_grid:
		return
	var used = backpack_grid.total_bytes_used()
	var cap = backpack_grid.capacity_bytes
	bytes_label.text = "Mochila (desafio): %d / %d bytes" % [used, cap]
	if used >= cap:
		bytes_label.text += " — Cheia!"
	# Atualiza estado do botão Próxima quando bytes mudam
	_update_next_button_state()


func _update_hint():
	if not backpack_grid:
		return
	var used = backpack_grid.total_bytes_used()
	var cap = backpack_grid.capacity_bytes
	var free = cap - used
	if free <= 0:
		hint_label.text = _hint_full_message()
	elif free == 1:
		hint_label.text = "Falta 1 byte. Clique em um INT do pool e arraste para o slot vazio da mochila."
	else:
		hint_label.text = "Faltam %d bytes. Use INTs do pool na mochila até fechar a capacidade." % free
	# Atualiza estado do botão Próxima quando hints mudam
	_update_next_button_state()


func _hint_full_message() -> String:
	var base := "Mochila cheia! Objetivo concluído."
	var extra := _pedagogy_extra_when_full()
	if extra.is_empty():
		return base
	return base + "\n\n" + extra

func _check_calculator():
	if double_slot != null and double_slot.item_stored != null:
		var item = double_slot.item_stored
		if item.data_type == item.DataType.INT or item.data_type == item.DataType.FLOAT:
			item.set_value_by_type(float(item.value), item.DataType.DOUBLE)
		double_slot.item_stored = null
		item_held = item
		item.grid_anchor = null
		
	if short_slot != null and short_slot.item_stored != null:
		var item = short_slot.item_stored
		item.set_value_by_type(int(item.value), item.DataType.SHORT_INT)
		short_slot.item_stored = null
		item_held = item
		item.grid_anchor = null
		
	if boolean_slot != null and boolean_slot.item_stored != null:
		var item = boolean_slot.item_stored
		var bool_val = item.value != 0
		item.set_value_by_type(bool_val, item.DataType.BOOLEAN)
		boolean_slot.item_stored = null
		item_held = item
		item.grid_anchor = null
		
	if calc_slot_1 and calc_slot_2 and calc_op_btn:
		if calc_slot_1.item_stored != null and calc_slot_2.item_stored != null:
			var item1 = calc_slot_1.item_stored
			var item2 = calc_slot_2.item_stored
			
			var val1 = item1.value_float if item1.data_type in [item1.DataType.FLOAT, item1.DataType.DOUBLE] else float(item1.value)
			var val2 = item2.value_float if item2.data_type in [item2.DataType.FLOAT, item2.DataType.DOUBLE] else float(item2.value)
			
			var is_float = (item1.data_type in [item1.DataType.FLOAT, item1.DataType.DOUBLE] or item2.data_type in [item2.DataType.FLOAT, item2.DataType.DOUBLE])
			var is_double = (item1.data_type == item1.DataType.DOUBLE or item2.data_type == item2.DataType.DOUBLE)
			
			var result_val = 0.0
			if calc_op_btn.text == "+":
				result_val = val1 + val2
			else:
				result_val = val1 - val2
			
			item1.queue_free()
			item2.queue_free()
			calc_slot_1.item_stored = null
			calc_slot_1.state = calc_slot_1.States.FREE
			calc_slot_2.item_stored = null
			calc_slot_2.state = calc_slot_2.States.FREE
			
			var new_item = preload("res://Inventory/Items/Item.tscn").instantiate()
			add_child(new_item)
			
			if is_double:
				new_item.set_value_by_type(result_val, new_item.DataType.DOUBLE)
			elif is_float:
				new_item.set_value_by_type(result_val, new_item.DataType.FLOAT)
			else:
				new_item.set_value_by_type(int(result_val), new_item.DataType.INT)
			
			if new_item.has_method("update_label_display"):
				new_item.update_label_display()
			
			new_item.selected = true
			item_held = new_item
			item_held.global_position = get_global_mouse_position()
			
			var tween = create_tween()
			new_item.scale = Vector2(0.2, 0.2)
			tween.tween_property(new_item, "scale", Vector2(1.2, 1.2), 0.2)
			tween.tween_property(new_item, "scale", Vector2(1.0, 1.0), 0.1)

func _pedagogy_extra_when_full() -> String:
	return ""


func is_phase_success() -> bool:
	# Padrão: permitir avanço. Subclasses (ex: mochila) podem sobrescrever.
	return true
