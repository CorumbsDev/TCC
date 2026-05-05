extends Control
## Fase 1: Completar binário.
## Esquerda: inventário com 0 e 1. Direita: binário incompleto (ex: 1 _ 0).
## Jogador arrasta 0 ou 1 para o espaço vazio; não há penalidade por errar.

@export var config: BinaryPhaseConfig

@onready var slot_scene = preload("res://Inventory/slots/slot.tscn")
@onready var item_scene = preload("res://Inventory/Items/Item.tscn")
@onready var left_grid = $HBox/LeftPanel/MarginContainer/VBox/GridContainer
@onready var target_slot = $HBox/RightPanel/MarginContainer/VBox/BinaryRow/TargetSlot
@onready var result_label = $HBox/RightPanel/MarginContainer/VBox/ResultLabel
@onready var explanation_label = $HBox/RightPanel/MarginContainer/VBox/ExplanationLabel
@onready var binary_display = $HBox/RightPanel/MarginContainer/VBox/BinaryDisplay
@onready var btn_voltar = $TopBar/BtnVoltar
@onready var btn_help = $TopBar/BtnHelp
@onready var btn_proxima = $TopBar/BtnProxima
@onready var title_label = $TopBar/Title
@onready var left_digit_label = $HBox/RightPanel/MarginContainer/VBox/BinaryRow/LeftDigit
@onready var right_digit_label = $HBox/RightPanel/MarginContainer/VBox/BinaryRow/RightDigit

var left_slots := []
var item_held = null
var current_slot = null
var can_place = false
var icon_anchor: Vector2
var BINARY_LEFT := "1"
var BINARY_RIGHT := "0"


func _resolve_binary_config() -> BinaryPhaseConfig:
	var injected := PhaseRunner.take_binary_config_if_any()
	if injected != null:
		return injected
	if config != null:
		return config
	return BinaryPhaseConfig.new()


func _ready():
	var cfg := _resolve_binary_config()
	cfg.apply_constraints()
	BINARY_LEFT = cfg.left_digit_string()
	BINARY_RIGHT = cfg.right_digit_string()
	if title_label:
		title_label.text = "Fase binário: %s _ %s" % [BINARY_LEFT, BINARY_RIGHT]
	if left_digit_label:
		left_digit_label.text = BINARY_LEFT
	if right_digit_label:
		right_digit_label.text = BINARY_RIGHT
	btn_voltar.pressed.connect(_on_voltar_pressed)
	btn_help.pressed.connect(_on_help_pressed)
	btn_proxima.visible = PhaseRunner.should_show_next_button()
	btn_proxima.pressed.connect(_on_proxima_pressed)
	# Cria 2 slots à esquerda (inventário de bits)
	for i in range(2):
		var s = slot_scene.instantiate()
		s.slot_ID = i
		left_grid.add_child(s)
		left_slots.append(s)
		s.slot_entered.connect(_on_slot_entered)
		s.slot_exited.connect(_on_slot_exited)
	# Coloca bit 0 no primeiro slot e bit 1 no segundo
	_spawn_bit_at_slot(0, 0)   # bit 0
	_spawn_bit_at_slot(1, 1)   # bit 1
	# Slot alvo (meio): quando recebe item, mostra resultado
	target_slot.slot_entered.connect(_on_slot_entered)
	target_slot.slot_exited.connect(_on_slot_exited)
	target_slot.item_changed.connect(_on_target_item_changed)
	_update_binary_display(null)
	call_deferred("_try_show_intro")


func _try_show_intro() -> void:
	var k := TutorialTexts.KEY_PHASE_BINARY
	TutorialOverlay.open(self, k, TutorialTexts.title_for(k), TutorialTexts.body_for(k), false)


func _on_help_pressed() -> void:
	var k := TutorialTexts.KEY_PHASE_BINARY
	TutorialOverlay.open(self, k, TutorialTexts.title_for(k), TutorialTexts.body_for(k), false)

func _spawn_bit_at_slot(slot_idx: int, bit_value: int):
	var slot = left_slots[slot_idx]
	if slot.item_stored != null:
		return
	var item = item_scene.instantiate()
	slot.add_child(item)
	item.position = Vector2(25, 25)
	var id = "item_binary_1" if bit_value == 1 else "item_binary_0"
	item.call_deferred("load_item", id)
	item.grid_anchor = slot
	slot.state = slot.States.TAKEN
	slot.item_stored = item
	slot.set_item(item)

func _on_voltar_pressed():
	PhaseRunner.abort_sequence()
	get_tree().change_scene_to_file("res://Inventory/fases/main_menu.tscn")


func _on_proxima_pressed():
	PhaseRunner.advance_from_phase()

func _on_slot_entered(s):
	current_slot = s
	if item_held and s == target_slot:
		# Só aceita bit (0 ou 1) no slot alvo
		var is_bit = item_held.get("data_type") != null and item_held.data_type == item_held.DataType.BINARY
		if is_bit and item_held.value_binary.length() == 1:
			can_place = true
		else:
			can_place = false
	elif item_held and s in left_slots:
		can_place = false  # não colocar de volta em slot já ocupado por outro; permitir soltar no vazio
		if s.item_stored == null:
			can_place = true

func _on_slot_exited(_s):
	current_slot = null
	can_place = false

func _on_target_item_changed(slot):
	if slot != target_slot:
		return
	if slot.item_stored == null:
		result_label.text = "Depois de soltar o orb, veja abaixo a conversão de binário para decimal."
		explanation_label.text = ""
		_update_binary_display(null)
		return
	var item = slot.item_stored
	var bit_str = item.value_binary if item.value_binary.length() == 1 else str(item.value)
	var full_binary = BINARY_LEFT + bit_str + BINARY_RIGHT
	var decimal = _binary_string_to_int(full_binary)
	result_label.text = "Binário: %s = %d (decimal)" % [full_binary, decimal]
	explanation_label.text = _binary_expansion_explanation(full_binary, decimal)
	_update_binary_display(bit_str)
	_refill_bits_if_empty()


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
	return "Expansão posicional: " + joined + " = %d." % decimal

func _binary_string_to_int(bin_str: String) -> int:
	var r = 0
	for i in range(bin_str.length()):
		r = r * 2 + int(bin_str[i])
	return r

func _update_binary_display(middle_bit: Variant):
	if middle_bit == null:
		binary_display.text = BINARY_LEFT + " _ " + BINARY_RIGHT
	else:
		binary_display.text = BINARY_LEFT + " " + str(middle_bit) + " " + BINARY_RIGHT

func _refill_bits_if_empty():
	for i in range(left_slots.size()):
		if left_slots[i].item_stored == null:
			_spawn_bit_at_slot(i, i)

@warning_ignore("unused_parameter")
func _process(delta):
	if item_held:
		if Input.is_action_just_pressed("select_item"):
			_try_place_item()
	else:
		if Input.is_action_just_pressed("select_item"):
			_try_pick_item()

func _try_pick_item():
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

func _try_place_item():
	if not can_place or current_slot == null:
		return
	var placing = item_held
	placing.get_parent().remove_child(placing)
	if current_slot in left_slots:
		current_slot.add_child(placing)
		placing.position = Vector2(25, 25)
	else:
		target_slot.add_child(placing)
		placing.position = Vector2(25, 25)
	placing._snap_to(current_slot.global_position + Vector2(25, 25))
	placing.grid_anchor = current_slot
	placing.selected = false
	current_slot.item_stored = placing
	current_slot.state = current_slot.States.TAKEN
	current_slot.set_item(placing)
	item_held = null
	can_place = false
	if current_slot == target_slot:
		_update_binary_display(placing.value_binary if placing.value_binary.length() == 1 else str(placing.value))
