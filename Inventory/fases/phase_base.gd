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
var converter_slot = null
var double_slot = null

var item_held = null
var current_slot = null
var can_place := false


func _ready():
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
		hint_label.text = "Solte o orbe aqui para convertê-lo para Double (4 slots, Rosa)."
		_update_next_button_state()
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
		converter_slot.state = converter_slot.States.FREE
		converter_slot.item_stored = null
	elif slot == double_slot:
		double_slot.state = double_slot.States.FREE
		double_slot.item_stored = null
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


func _pedagogy_extra_when_full() -> String:
	return ""


func is_phase_success() -> bool:
	# Padrão: permitir avanço. Subclasses (ex: mochila) podem sobrescrever.
	return true
