extends Control
## Fase 3: sequência de desafios decimal -> binário (MSB à esquerda).

@export var num_bits: int = 3
@export var challenge_decimals: Array[int] = [5, 3, 6]
@export var advance_delay_seconds: float = 2.4

@onready var slot_scene = preload("res://Inventory/slots/slot.tscn")
@onready var item_scene = preload("res://Inventory/Items/Item.tscn")
@onready var left_grid = $HBox/LeftPanel/MarginContainer/VBox/GridContainer
@onready var targets_row = $HBox/RightPanel/MarginContainer/VBox/TargetsRow
@onready var goal_label = $HBox/RightPanel/MarginContainer/VBox/GoalLabel
@onready var progress_label = $HBox/RightPanel/MarginContainer/VBox/ProgressLabel
@onready var result_label = $HBox/RightPanel/MarginContainer/VBox/ResultLabel
@onready var explanation_label = $HBox/RightPanel/MarginContainer/VBox/ExplanationLabel
@onready var btn_voltar = $TopBar/BtnVoltar
@onready var btn_help = $TopBar/BtnHelp
@onready var bits_info_label: Label = $TopBar/BitsInfoLabel

var left_slots: Array = []
var target_slots: Array = []
var item_held = null
var current_slot = null
var can_place = false
var challenge_idx := 0
var suppress_check := false
var is_advancing := false
var _configured_num_bits := 0


func _ready():
	btn_voltar.pressed.connect(_on_voltar_pressed)
	btn_help.pressed.connect(_on_help_pressed)
	if challenge_decimals.is_empty():
		challenge_decimals = [5, 3, 6]
	_normalize_challenges()
	_configured_num_bits = num_bits
	_autoadjust_num_bits_for_challenges()
	if num_bits < 1:
		num_bits = 1
	if advance_delay_seconds < 0.3:
		advance_delay_seconds = 0.3
	challenge_idx = 0
	for i in range(6):
		var s = slot_scene.instantiate()
		s.slot_ID = i
		left_grid.add_child(s)
		left_slots.append(s)
		s.slot_entered.connect(_on_slot_entered)
		s.slot_exited.connect(_on_slot_exited)
		_spawn_bit_at_slot(i, i % 2)
	for j in range(num_bits):
		var ts = slot_scene.instantiate()
		ts.slot_ID = 100 + j
		ts.state = ts.States.FREE
		targets_row.add_child(ts)
		target_slots.append(ts)
		ts.slot_entered.connect(_on_slot_entered)
		ts.slot_exited.connect(_on_slot_exited)
		ts.item_changed.connect(_on_target_changed)
	_update_bits_info_label()
	_refresh_challenge_ui()
	call_deferred("_try_show_intro")


func _try_show_intro() -> void:
	var k := TutorialTexts.KEY_PHASE_CONVERSION
	TutorialOverlay.open(self, k, TutorialTexts.title_for(k), TutorialTexts.body_for(k), false)


func _on_help_pressed() -> void:
	var k := TutorialTexts.KEY_PHASE_CONVERSION
	TutorialOverlay.open(self, k, TutorialTexts.title_for(k), TutorialTexts.body_for(k), false)


func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Inventory/fases/main_menu.tscn")


func _spawn_bit_at_slot(slot_idx: int, bit_value: int) -> void:
	var slot = left_slots[slot_idx]
	if slot.item_stored != null:
		return
	var item = item_scene.instantiate()
	slot.add_child(item)
	item.position = Vector2(25, 25)
	var id = "item_binary_1" if bit_value == 1 else "item_binary_0"
	item.load_item(id)
	item.grid_anchor = slot
	slot.state = slot.States.TAKEN
	slot.item_stored = item
	slot.set_item(item)


func _on_slot_entered(s):
	current_slot = s
	if not item_held:
		return
	if s in target_slots:
		var is_bit = item_held.get("data_type") != null and item_held.data_type == item_held.DataType.BINARY
		if is_bit and item_held.value_binary.length() == 1:
			can_place = true
		else:
			can_place = false
	elif s in left_slots:
		can_place = false
		if s.item_stored == null:
			can_place = true


func _on_slot_exited(_s):
	current_slot = null
	can_place = false


func _on_target_changed(_slot):
	if suppress_check:
		return
	_check_solution()


func _check_solution() -> void:
	if is_advancing:
		return
	var target := _current_target_decimal()
	for t in target_slots:
		if t.item_stored == null:
			result_label.text = "Desafio %d/%d: preencha os %d bits (esquerda = MSB)." % [challenge_idx + 1, _challenge_count(), num_bits]
			explanation_label.text = ""
			return
	var bin_str := ""
	for t in target_slots:
		bin_str += _bit_char_from_item(t.item_stored)
	var val := _binary_string_to_int(bin_str)
	var expected := _decimal_to_binary_bits(target, num_bits)
	result_label.text = "Seu binário: %s = %d (decimal). Objetivo: representar %d." % [bin_str, val, target]
	var expansion := _binary_expansion_explanation(bin_str, val)
	if bin_str == expected:
		explanation_label.text = expansion + " [correto]"
		if challenge_idx < _challenge_count() - 1:
			is_advancing = true
			var next_idx := challenge_idx + 1
			result_label.text = "Acertou! Próximo desafio: %d em %d bits..." % [_effective_challenges()[next_idx], num_bits]
			await get_tree().create_timer(advance_delay_seconds).timeout
			challenge_idx = next_idx
			_clear_target_slots_to_pool()
			_refill_pool_if_empty()
			_refresh_challenge_ui()
			is_advancing = false
		else:
			result_label.text = "Parabéns! Você concluiu os %d desafios da fase 3." % _challenge_count()
			explanation_label.text = "Última resposta correta: " + expansion
	else:
		explanation_label.text = expansion + "\nEsperado em %d bits: %s. Dica: decomponha %d em soma de potências de 2." % [num_bits, expected, target]


func _current_target_decimal() -> int:
	var list := _effective_challenges()
	if challenge_idx < 0 or challenge_idx >= list.size():
		return list[0]
	return list[challenge_idx]


func _effective_challenges() -> Array[int]:
	if challenge_decimals == null or challenge_decimals.is_empty():
		return [5, 3, 6]
	return challenge_decimals


func _normalize_challenges() -> void:
	# Garante inteiros nao-negativos para evitar casos invalidos.
	var normalized: Array[int] = []
	for v in challenge_decimals:
		normalized.append(max(0, int(v)))
	challenge_decimals = normalized


func _autoadjust_num_bits_for_challenges() -> void:
	# Se existir valor que nao cabe em num_bits, aumenta automaticamente.
	var max_value := 0
	for v in _effective_challenges():
		if v > max_value:
			max_value = v
	var required_bits := 1
	while (1 << required_bits) - 1 < max_value:
		required_bits += 1
	if num_bits < required_bits:
		num_bits = required_bits


func _update_bits_info_label() -> void:
	if not bits_info_label:
		return
	if num_bits > _configured_num_bits:
		bits_info_label.text = "Bits configurados: %d -> ajustado automaticamente para %d" % [_configured_num_bits, num_bits]
	else:
		bits_info_label.text = "Bits usados: %d" % num_bits


func _challenge_count() -> int:
	return _effective_challenges().size()


func _refresh_challenge_ui() -> void:
	var target := _current_target_decimal()
	progress_label.text = "Desafio %d de %d" % [challenge_idx + 1, _challenge_count()]
	goal_label.text = "Objetivo: representar o decimal %d usando exatamente %d bits." % [target, num_bits]
	result_label.text = "Preencha os %d bits (esquerda = MSB)." % num_bits
	explanation_label.text = ""


func _clear_target_slots_to_pool() -> void:
	suppress_check = true
	for slot in target_slots:
		var item = slot.item_stored
		slot.item_stored = null
		slot.state = slot.States.FREE
		slot.set_item(null)
		if item != null:
			_return_item_to_pool(item)
	suppress_check = false


func _return_item_to_pool(item: Node2D) -> void:
	for slot in left_slots:
		if slot.item_stored == null:
			if item.get_parent():
				item.get_parent().remove_child(item)
			slot.add_child(item)
			item.position = Vector2(25, 25)
			item.grid_anchor = slot
			item.selected = false
			slot.item_stored = item
			slot.state = slot.States.TAKEN
			slot.set_item(item)
			return
	if item.get_parent():
		item.get_parent().remove_child(item)
	item.queue_free()


func _bit_char_from_item(item: Node) -> String:
	if item.get("data_type") != null and item.data_type == item.DataType.BINARY and item.value_binary.length() == 1:
		return item.value_binary
	return "0"


func _decimal_to_binary_bits(value: int, bit_count: int) -> String:
	var out := ""
	for i in range(bit_count - 1, -1, -1):
		out += str((value >> i) & 1)
	return out


func _binary_expansion_explanation(full_binary: String, decimal: int) -> String:
	var n := full_binary.length()
	var parts: PackedStringArray = PackedStringArray()
	for i in range(n):
		var bit := full_binary[i]
		var power: int = n - 1 - i
		parts.append("%s×2^%d" % [bit, power])
	var joined := ""
	for i in range(parts.size()):
		if i > 0:
			joined += " + "
		joined += parts[i]
	return "Expansão posicional: " + joined + " = %d. " % decimal


func _binary_string_to_int(bin_str: String) -> int:
	var r := 0
	for i in range(bin_str.length()):
		r = r * 2 + int(bin_str[i])
	return r


func _refill_pool_if_empty() -> void:
	for i in range(left_slots.size()):
		if left_slots[i].item_stored == null:
			_spawn_bit_at_slot(i, i % 2)


@warning_ignore("unused_parameter")
func _process(_delta):
	if item_held:
		if Input.is_action_just_pressed("select_item"):
			_try_place_item()
	else:
		if Input.is_action_just_pressed("select_item"):
			_try_pick_item()


func _try_pick_item() -> void:
	if current_slot == null or current_slot.item_stored == null:
		return
	item_held = current_slot.item_stored
	item_held.selected = true
	item_held.get_parent().remove_child(item_held)
	add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	current_slot.item_stored = null
	current_slot.state = current_slot.States.FREE
	current_slot.set_item(null)
	if current_slot in target_slots:
		_check_solution()


func _try_place_item() -> void:
	if not can_place or current_slot == null:
		return
	var placing = item_held
	placing.get_parent().remove_child(placing)
	if current_slot in left_slots:
		current_slot.add_child(placing)
		placing.position = Vector2(25, 25)
	else:
		current_slot.add_child(placing)
		placing.position = Vector2(25, 25)
	placing._snap_to(current_slot.global_position + Vector2(25, 25))
	placing.grid_anchor = current_slot
	placing.selected = false
	current_slot.item_stored = placing
	current_slot.state = current_slot.States.TAKEN
	current_slot.set_item(placing)
	item_held = null
	can_place = false
	_refill_pool_if_empty()
