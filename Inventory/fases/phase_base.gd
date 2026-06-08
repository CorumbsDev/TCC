extends Control

const ItemRef = preload("res://Inventory/Items/item.gd")

@onready var btn_voltar = $TopBar/BtnVoltar
@onready var btn_help = get_node_or_null("TopBar/BtnHelp")
@onready var btn_proxima = get_node_or_null("TopBar/BtnProxima")
@onready var phase_title = get_node_or_null("TopBar/PhaseTitle")
@onready var btn_spawn = $TopBar/BtnSpawn
@onready var bytes_label = $HBox/BackpackPanel/MarginContainer/VBoxContainer/PhaseInfoBar/MarginContainer/VBoxContainer/BytesLabel
@onready var hint_label = $HBox/BackpackPanel/MarginContainer/VBoxContainer/PhaseInfoBar/MarginContainer/VBoxContainer/HintLabel

@onready var backpack_container = $HBox/BackpackPanel/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var pool_container = $HBox/BancadaPanel/MarginContainer/VBoxContainer/GridContainer

var backpack_grid: InventoryGrid = null
var pool_grid: InventoryGrid = null
var converter_slot: TextureRect = null
var converter_option_btn: OptionButton = null
var double_slot: TextureRect = null
var short_slot: TextureRect = null
var calc_slot_1: TextureRect = null
var calc_slot_2 = null
var calc_slot_result: TextureRect = null
var calc_op_btn = null
var inspect_slot: TextureRect = null

var item_held = null
var current_slot = null
var can_place := false
var inspector_modal = null
var _orb_hover_bar: OrbHoverBar = null
var _converter_syncing: bool = false


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
	if phase_title:
		phase_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
	call_deferred("_apply_panel_art")
	call_deferred("_wire_all_orbs")
	call_deferred("_anchor_orb_hover_above_pool")


func _get_phase_config():
	return null


func _apply_panel_art() -> void:
	var bp := get_node_or_null("HBox/BackpackPanel") as Control
	var bn := get_node_or_null("HBox/BancadaPanel") as Control
	if bp:
		PanelArtLoader.apply_zone_chrome(bp)
	if bn:
		PanelArtLoader.apply_zone_chrome(bn)
	_style_phase_labels()


func _style_phase_labels() -> void:
	var bar := get_node_or_null("HBox/BackpackPanel/MarginContainer/VBoxContainer/PhaseInfoBar")
	if bar is PhaseInfoBar:
		return
	if bytes_label:
		OrbHoverBar.apply_info_label(bytes_label)
	if hint_label:
		OrbHoverBar.apply_info_label(hint_label)


func _wire_all_orbs() -> void:
	for grid in [backpack_grid, pool_grid]:
		if grid == null:
			continue
		for slot in grid.slots_array:
			for it in slot.items_stored:
				_wire_orb(it)
			if not slot.item_changed.is_connected(_on_orb_slot_changed):
				slot.item_changed.connect(_on_orb_slot_changed)


func _on_orb_slot_changed(slot) -> void:
	for it in slot.items_stored:
		_wire_orb(it)


func _wire_orb(item: Node) -> void:
	var bar := _get_orb_hover_bar()
	if bar:
		bar.wire_orb(item)


func _get_orb_hover_bar() -> OrbHoverBar:
	if _orb_hover_bar != null and is_instance_valid(_orb_hover_bar):
		return _orb_hover_bar
	for path in [
		"HBox/BancadaPanel/MarginContainer/VBoxContainer/OrbHoverBar",
		"HBox/BancadaPanel/MarginContainer/VBoxContainer/OrbHoverPanel",
	]:
		var n := get_node_or_null(path)
		if n is OrbHoverBar:
			_orb_hover_bar = n
			return _orb_hover_bar
	return null


func _register_orb_hover_bar(bar: OrbHoverBar) -> void:
	_orb_hover_bar = bar


func _anchor_orb_hover_above_pool() -> void:
	var bar := _get_orb_hover_bar()
	if bar == null or pool_grid == null:
		return
	var parent := pool_grid.get_parent()
	if parent == null:
		return
	parent.move_child(bar, pool_grid.get_index())


func _open_orb_inspector(item: Node) -> void:
	var cfg = _get_phase_config()
	if cfg == null or item == null:
		return
	if not inspector_modal:
		inspector_modal = preload("res://Inventory/fases/inspector_modal.gd").new()
		add_child(inspector_modal)
	inspector_modal.open(cfg, item)


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
	dlg.popup_centered(Vector2(400, 120))


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
		_update_next_button_state()
	elif slot == calc_slot_result:
		can_place = false
	elif slot == calc_slot_1 or slot == calc_slot_2:
		can_place = slot.item_stored == null
		if can_place:
			_update_next_button_state()
	elif slot == inspect_slot:
		can_place = slot.item_stored == null
		if can_place:
			_update_next_button_state()
	elif backpack_grid and slot in backpack_grid.slots_array:
		can_place = backpack_grid.can_place_item(item_held, slot)
		var need = item_held.get_size_bytes() if item_held.has_method("get_size_bytes") else 1
		var used = backpack_grid.total_bytes_used()
		if can_place and used + need > backpack_grid.capacity_bytes:
			can_place = false
	elif pool_grid and slot in pool_grid.slots_array:
		can_place = pool_grid.can_place_item(item_held, slot)
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
	if not item_held or not is_instance_valid(item_held):
		return
		
	if current_slot == converter_slot:
		var placed := await _convert_item_with_dialog(item_held, true)
		if not placed:
			return
		item_held = null
		can_place = false
		_update_bytes_label()
		_update_hint()
		return
		
	if current_slot == calc_slot_1 or current_slot == calc_slot_2 or current_slot == inspect_slot:
		if current_slot == calc_slot_1 or current_slot == calc_slot_2:
			_clear_calc_result()
		_mount_item_on_calc_slot(current_slot, item_held)
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
	if slot == null or slot.item_stored == null:
		return
	item_held = slot.item_stored
	if not is_instance_valid(item_held):
		item_held = null
		return
	item_held.selected = true
	item_held.get_parent().remove_child(item_held)
	add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	if slot == converter_slot:
		if converter_slot:
			converter_slot.item_stored = null
		converter_slot.state = converter_slot.States.FREE
		if item_held.has_method("restore_orb_layout"):
			item_held.restore_orb_layout()
	elif slot == inspect_slot:
		inspect_slot.state = inspect_slot.States.FREE
		inspect_slot.item_stored = null
	elif slot == calc_slot_result:
		slot.state = slot.States.FREE
		slot.item_stored = null
		if item_held.has_method("restore_orb_layout"):
			item_held.restore_orb_layout()
	elif slot == calc_slot_1 or slot == calc_slot_2:
		slot.state = slot.States.FREE
		slot.item_stored = null
		_clear_calc_result()
		if item_held.has_method("restore_orb_layout"):
			item_held.restore_orb_layout()
	elif backpack_grid and slot in backpack_grid.slots_array:
		backpack_grid.remove_item(item_held)
	elif pool_grid and slot in pool_grid.slots_array:
		pool_grid.remove_item(item_held)
	_wire_orb(item_held)
	if converter_option_btn:
		_revert_converter_dropdown(item_held.data_type)
	_update_bytes_label()
	_update_hint()


func _update_bytes_label():
	if not backpack_grid:
		return
	var used = backpack_grid.total_bytes_used()
	var cap = backpack_grid.capacity_bytes
	bytes_label.text = "Mochila: %d / %d bytes" % [used, cap]
	_update_next_button_state()


func _update_hint() -> void:
	if not hint_label:
		return
	if is_phase_success():
		hint_label.text = "Objetivo concluído!"
		hint_label.visible = true
	else:
		hint_label.text = ""
		hint_label.visible = false
	_update_next_button_state()

func _clear_calc_result() -> void:
	if calc_slot_result == null or calc_slot_result.item_stored == null:
		return
	var old = calc_slot_result.item_stored
	calc_slot_result.item_stored = null
	calc_slot_result.state = calc_slot_result.States.FREE
	if is_instance_valid(old):
		old.queue_free()


func _mount_item_on_calc_slot(slot: TextureRect, item: Node) -> void:
	if item.get_parent() != slot:
		if item.get_parent():
			item.get_parent().remove_child(item)
		slot.add_child(item)
	if item.has_method("shrink_orb_for_tool_slot"):
		item.shrink_orb_for_tool_slot()
	if item.has_method("snap_to_slot"):
		item.snap_to_slot(slot)
	else:
		item.position = slot.size * 0.5
	item.grid_anchor = slot
	item.selected = false
	slot.item_stored = item
	slot.state = slot.States.TAKEN


func _check_calculator() -> void:
	if calc_slot_1 and calc_slot_2 and calc_op_btn and calc_slot_result:
		if calc_slot_1.item_stored != null and calc_slot_2.item_stored != null:
			var item1 = calc_slot_1.item_stored
			var item2 = calc_slot_2.item_stored
			
			var val1 = item1.value_float if item1.data_type in [item1.DataType.FLOAT, item1.DataType.DOUBLE] else float(item1.value)
			var val2 = item2.value_float if item2.data_type in [item2.DataType.FLOAT, item2.DataType.DOUBLE] else float(item2.value)
			
			var p1 = _get_type_priority(item1)
			var p2 = _get_type_priority(item2)
			var target_type = item1.data_type if p1 >= p2 else item2.data_type
			var target_type_str = _get_type_string(target_type)
			
			var result_val = 0.0
			if calc_op_btn.text == "+":
				result_val = val1 + val2
			else:
				result_val = val1 - val2
				
			var deg = _check_degradation(target_type_str, result_val)
			if deg.has_warning:
				var dlg = ConfirmationDialog.new()
				dlg.dialog_text = deg.message + "\n\nDeseja prosseguir com o cálculo?"
				dlg.title = "Aviso da Calculadora"
				dlg.ok_button_text = "Prosseguir"
				dlg.cancel_button_text = "Cancelar"
				add_child(dlg)
				dlg.popup_centered(Vector2(450, 150))
				var res = await _wait_for_dialog(dlg)
				dlg.queue_free()
				if not res:
					return
			
			item1.queue_free()
			item2.queue_free()
			calc_slot_1.item_stored = null
			calc_slot_1.state = calc_slot_1.States.FREE
			calc_slot_2.item_stored = null
			calc_slot_2.state = calc_slot_2.States.FREE
			
			_clear_calc_result()
			var new_item: Node2D = preload("res://Inventory/Items/Item.tscn").instantiate()
			var final_val = deg.degraded_value
			if target_type in [ItemRef.DataType.INT, ItemRef.DataType.SHORT_INT]:
				new_item.set_value_by_type(int(final_val), target_type)
			else:
				new_item.set_value_by_type(final_val, target_type)
			
			if target_type in [ItemRef.DataType.FP8, ItemRef.DataType.FP16]:
				if item1.data_type == target_type:
					new_item.fp_exp_bits = item1.fp_exp_bits
					new_item.fp_mant_bits = item1.fp_mant_bits
				elif item2.data_type == target_type:
					new_item.fp_exp_bits = item2.fp_exp_bits
					new_item.fp_mant_bits = item2.fp_mant_bits
			
			if new_item.has_method("update_label_display"):
				new_item.update_label_display()
			_mount_item_on_calc_slot(calc_slot_result, new_item)
			_wire_orb(new_item)
			new_item.scale = Vector2(0.2, 0.2)
			var tween = create_tween()
			tween.tween_property(new_item, "scale", Vector2(1.1, 1.1), 0.18)
			tween.tween_property(new_item, "scale", Vector2(1.0, 1.0), 0.1)

func _get_type_priority(item) -> int:
	if item == null:
		return 0
	return _priority_for_data_type(item.data_type)


func _priority_for_data_type(dt: int) -> int:
	if dt == ItemRef.DataType.DOUBLE: return 100
	if dt == ItemRef.DataType.FLOAT: return 90
	if dt == ItemRef.DataType.FP16: return 80
	if dt == ItemRef.DataType.FP8: return 70
	if dt == ItemRef.DataType.INT: return 60
	if dt == ItemRef.DataType.SHORT_INT: return 50
	return 0


func _get_type_string(dt: int) -> String:
	if dt == ItemRef.DataType.DOUBLE: return "Double"
	if dt == ItemRef.DataType.FLOAT: return "Float"
	if dt == ItemRef.DataType.FP16: return "FP16"
	if dt == ItemRef.DataType.FP8: return "FP8"
	if dt == ItemRef.DataType.INT: return "Int"
	if dt == ItemRef.DataType.SHORT_INT: return "Short"
	return "Float"


func _converter_target_item() -> Node:
	if converter_slot and converter_slot.item_stored:
		return converter_slot.item_stored
	if item_held and is_instance_valid(item_held):
		return item_held
	return null


func _value_for_conversion(item: Node) -> float:
	if item.data_type in [ItemRef.DataType.FLOAT, ItemRef.DataType.DOUBLE, ItemRef.DataType.FP8, ItemRef.DataType.FP16]:
		return item.value_float
	return float(item.value)


func _apply_fp_bits_from_config(item: Node, kind: String) -> void:
	var cfg = get("config")
	if cfg == null or item == null:
		return
	if kind == "fp8":
		item.fp_exp_bits = cfg.fp8_exp_bits
		item.fp_mant_bits = cfg.fp8_mant_bits
	elif kind == "fp16":
		item.fp_exp_bits = cfg.fp16_exp_bits
		item.fp_mant_bits = cfg.fp16_mant_bits


func _apply_target_type_to_item(item: Node, target_type_str: String, final_val: float) -> void:
	if item == null or not is_instance_valid(item):
		return
	match target_type_str:
		"Int":
			item.set_value_by_type(int(final_val), ItemRef.DataType.INT)
		"Float":
			item.set_value_by_type(final_val, ItemRef.DataType.FLOAT)
		"Double":
			item.set_value_by_type(final_val, ItemRef.DataType.DOUBLE)
		"Short":
			item.set_value_by_type(int(final_val), ItemRef.DataType.SHORT_INT)
		"FP8":
			item.set_value_by_type(final_val, ItemRef.DataType.FP8)
			_apply_fp_bits_from_config(item, "fp8")
		"FP16":
			item.set_value_by_type(final_val, ItemRef.DataType.FP16)
			_apply_fp_bits_from_config(item, "fp16")
	if item.has_method("update_label_display"):
		item.update_label_display()


func _revert_converter_dropdown(dt: int) -> void:
	if not converter_option_btn:
		return
	var revert_str := _get_type_string(dt)
	_converter_syncing = true
	for i in range(converter_option_btn.item_count):
		if converter_option_btn.get_item_text(i) == revert_str:
			converter_option_btn.select(i)
			break
	_converter_syncing = false


func _mount_item_on_converter(item: Node) -> void:
	if item == null or not is_instance_valid(item) or converter_slot == null:
		return
	var parent = item.get_parent()
	if parent != converter_slot:
		if parent:
			parent.remove_child(item)
		converter_slot.add_child(item)
	if item.has_method("snap_to_slot"):
		item.snap_to_slot(converter_slot)
	else:
		item.position = converter_slot.size * 0.5
	item.grid_anchor = converter_slot
	item.selected = false
	converter_slot.item_stored = item
	converter_slot.state = converter_slot.States.TAKEN


func _convert_item_with_dialog(item: Node, mount_on_converter: bool) -> bool:
	if item == null or not is_instance_valid(item):
		return false
	var target_type_str := converter_option_btn.get_item_text(converter_option_btn.selected) if converter_option_btn else "Float"
	var deg := _check_degradation(target_type_str, _value_for_conversion(item))
	if deg.has_warning:
		var dlg := ConfirmationDialog.new()
		dlg.dialog_text = deg.message + "\n\nDeseja converter assim mesmo?"
		dlg.title = "Aviso de Degradação"
		dlg.ok_button_text = "Prosseguir"
		dlg.cancel_button_text = "Cancelar"
		add_child(dlg)
		dlg.popup_centered(Vector2(450, 150))
		var res := await _wait_for_dialog(dlg)
		dlg.queue_free()
		if not res:
			return false
	if not is_instance_valid(item):
		return false
	_apply_target_type_to_item(item, target_type_str, deg.degraded_value)
	if mount_on_converter:
		_mount_item_on_converter(item)
	return true

func is_phase_success() -> bool:
	# Padrão: permitir avanço. Subclasses (ex: mochila) podem sobrescrever.
	return true

func _on_converter_type_changed(_index):
	if _converter_syncing:
		return
	var item := _converter_target_item()
	if item == null or not is_instance_valid(item):
		return
	var previous_dt: int = item.data_type
	var target_type_str := converter_option_btn.get_item_text(converter_option_btn.selected) if converter_option_btn else "Float"
	var deg := _check_degradation(target_type_str, _value_for_conversion(item))
	if deg.has_warning:
		var dlg := ConfirmationDialog.new()
		dlg.dialog_text = deg.message + "\n\nDeseja prosseguir mesmo assim?"
		dlg.title = "Aviso de Degradação de Dados"
		dlg.ok_button_text = "Prosseguir"
		dlg.cancel_button_text = "Cancelar"
		add_child(dlg)
		dlg.popup_centered(Vector2(450, 150))
		var res := await _wait_for_dialog(dlg)
		dlg.queue_free()
		if not res:
			_revert_converter_dropdown(previous_dt)
			return
	if not is_instance_valid(item):
		return
	_apply_target_type_to_item(item, target_type_str, deg.degraded_value)
	_update_bytes_label()
	_update_hint()

func _check_degradation(target_type_str: String, val_to_convert: float) -> Dictionary:
	var result = {"has_warning": false, "message": "", "degraded_value": val_to_convert}
	if target_type_str == "Int":
		var trunc_val = float(int(val_to_convert))
		if trunc_val != val_to_convert:
			result.has_warning = true
			result.message = "Perda de precisão: A parte decimal será descartada."
		
		if trunc_val < -2147483648:
			result.has_warning = true
			result.message = "Overflow: O valor excede os limites de um Inteiro de 32 bits (-2.1B a 2.1B)."
			trunc_val = -2147483648
		elif trunc_val > 2147483647:
			result.has_warning = true
			result.message = "Overflow: O valor excede os limites de um Inteiro de 32 bits (-2.1B a 2.1B)."
			trunc_val = 2147483647
		result.degraded_value = trunc_val
			
	elif target_type_str == "Short":
		var trunc_val = float(int(val_to_convert))
		if trunc_val != val_to_convert:
			result.has_warning = true
			result.message = "Perda de precisão: A parte decimal será descartada."
			
		if trunc_val < -32768:
			result.has_warning = true
			result.message = "Overflow: O valor excede os limites de um Short Inteiro de 16 bits (-32768 a 32767)."
			trunc_val = -32768
		elif trunc_val > 32767:
			result.has_warning = true
			result.message = "Overflow: O valor excede os limites de um Short Inteiro de 16 bits (-32768 a 32767)."
			trunc_val = 32767
		result.degraded_value = trunc_val
			
	elif target_type_str == "Float":
		if val_to_convert > 3.4028235e38:
			result.has_warning = true
			result.message = "Overflow: O valor excede a capacidade máxima de um Float de 32 bits e se tornará Infinito Positivo."
			result.degraded_value = INF
		elif val_to_convert < -3.4028235e38:
			result.has_warning = true
			result.message = "Overflow: O valor excede a capacidade máxima de um Float de 32 bits e se tornará Infinito Negativo."
			result.degraded_value = -INF
			
	elif target_type_str == "FP8":
		var config = get("config")
		var e_bits = 4
		var m_bits = 3
		if config != null and config.get("fp8_exp_bits") != null:
			e_bits = config.fp8_exp_bits
			m_bits = config.fp8_mant_bits
		
		var dict = _float_to_custom_fp_bits(val_to_convert, e_bits, m_bits)
		var back_to_float = _custom_fp_bits_to_float(dict.bits, e_bits, m_bits)
		if val_to_convert != back_to_float:
			result.has_warning = true
			result.message = "Perda de precisão: O formato FP8 (" + str(e_bits) + " exp, " + str(m_bits) + " mant) não possui precisão suficiente para o valor exato. Valor aproximado: " + str(back_to_float)
		result.degraded_value = back_to_float
		
	elif target_type_str == "FP16":
		var config = get("config")
		var e_bits = 5
		var m_bits = 10
		if config != null and config.get("fp16_exp_bits") != null:
			e_bits = config.fp16_exp_bits
			m_bits = config.fp16_mant_bits
		
		var dict = _float_to_custom_fp_bits(val_to_convert, e_bits, m_bits)
		var back_to_float = _custom_fp_bits_to_float(dict.bits, e_bits, m_bits)
		if val_to_convert != back_to_float:
			result.has_warning = true
			result.message = "Perda de precisão: O formato FP16 não possui precisão suficiente para manter o valor exato. Valor aproximado: " + str(back_to_float)
		result.degraded_value = back_to_float
		
	return result

func _wait_for_dialog(dlg: ConfirmationDialog) -> bool:
	var result = [false]
	var done = [false]
	dlg.confirmed.connect(func(): result[0] = true; done[0] = true)
	dlg.canceled.connect(func(): done[0] = true)
	dlg.close_requested.connect(func(): done[0] = true)
	
	while not done[0]:
		await get_tree().process_frame
		
	return result[0]

func _float_to_custom_fp_bits(val: float, exp_bits: int, mant_bits: int) -> Dictionary:
	var bytes = PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, val)
	var f_bits = bytes.decode_u32(0)
	var sign_bit = (f_bits >> 31) & 1
	var f_exp = (f_bits >> 23) & 0xFF
	var f_mant = f_bits & 0x7FFFFF
	var tgt_bias = (1 << (exp_bits - 1)) - 1
	var tgt_exp = 0
	var tgt_mant = 0
	if f_exp == 0xFF:
		tgt_exp = (1 << exp_bits) - 1
		tgt_mant = 1 if f_mant != 0 else 0
	elif f_exp == 0:
		tgt_exp = 0
		tgt_mant = 0
	else:
		var actual_exp = f_exp - 127
		tgt_exp = actual_exp + tgt_bias
		if tgt_exp >= (1 << exp_bits) - 1:
			tgt_exp = (1 << exp_bits) - 1
			tgt_mant = 0
		elif tgt_exp <= 0:
			tgt_exp = 0
			tgt_mant = 0
		else:
			if mant_bits <= 23:
				tgt_mant = f_mant >> (23 - mant_bits)
			else:
				tgt_mant = f_mant << (mant_bits - 23)
	var combined_bits = (sign_bit << (exp_bits + mant_bits)) | (tgt_exp << mant_bits) | tgt_mant
	return {"bits": combined_bits}

func _custom_fp_bits_to_float(bits: int, exp_bits: int, mant_bits: int) -> float:
	var sign_bit = (bits >> (exp_bits + mant_bits)) & 1
	var tgt_exp = (bits >> mant_bits) & ((1 << exp_bits) - 1)
	var tgt_mant = bits & ((1 << mant_bits) - 1)
	var tgt_bias = (1 << (exp_bits - 1)) - 1
	var f_exp = 0
	var f_mant = 0
	if tgt_exp == ((1 << exp_bits) - 1):
		f_exp = 0xFF
		f_mant = 1 if tgt_mant != 0 else 0
	elif tgt_exp == 0:
		f_exp = 0
		f_mant = 0
	else:
		var actual_exp = tgt_exp - tgt_bias
		f_exp = actual_exp + 127
		if f_exp <= 0:
			f_exp = 0
		elif f_exp >= 0xFF:
			f_exp = 0xFF
			f_mant = 0
		else:
			if mant_bits <= 23:
				f_mant = tgt_mant << (23 - mant_bits)
			else:
				f_mant = tgt_mant >> (mant_bits - 23)
	var f_bits = (sign_bit << 31) | (f_exp << 23) | f_mant
	var bytes = PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, f_bits)
	return bytes.decode_float(0)
