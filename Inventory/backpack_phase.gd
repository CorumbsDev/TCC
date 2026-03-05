extends Control
## Fase 2: Mochila com limite em bytes.
## Inventário com capacidade em bytes; cada item tem tamanho (ex: int = 1 byte).
## Objetivo: preencher o último byte livre (ex: colocar um int).

@onready var slot_scene = preload("res://Inventory/slot.tscn")
@onready var item_scene = preload("res://Inventory/Items/Item.tscn")
@onready var grid_container = $HBox/BackpackPanel/MarginContainer/VBox/ScrollContainer/GridContainer
@onready var scroll_container = $HBox/BackpackPanel/MarginContainer/VBox/ScrollContainer
@onready var bytes_label = $HBox/BackpackPanel/MarginContainer/VBox/BytesLabel
@onready var hint_label = $HBox/BackpackPanel/MarginContainer/VBox/HintLabel
@onready var btn_spawn = $HBox/BackpackPanel/MarginContainer/VBox/Header/BtnSpawn
@onready var btn_voltar = $TopBar/BtnVoltar

const CAPACITY_BYTES := 8
const COL_COUNT := 4

var grid_array := []
var item_held = null
var current_slot = null
var can_place := false
var icon_anchor: Vector2

func _ready():
	btn_voltar.pressed.connect(_on_voltar_pressed)
	btn_spawn.pressed.connect(_on_spawn_pressed)
	for i in range(8):
		var s = slot_scene.instantiate()
		s.slot_ID = i
		grid_container.add_child(s)
		grid_array.push_back(s)
		s.slot_entered.connect(_on_slot_entered)
		s.slot_exited.connect(_on_slot_exited)
		s.item_changed.connect(_on_slot_item_changed)
	# Preenche 7 bytes com ints (1 byte cada) → sobra 1 byte
	for i in range(7):
		var item = item_scene.instantiate()
		grid_container.add_child(item)
		item.load_item("item_number_%d" % (i + 1))
		var slot = grid_array[i]
		item.global_position = slot.global_position + Vector2(25, 25)
		item.grid_anchor = slot
		slot.state = slot.States.TAKEN
		slot.item_stored = item
		slot.set_item(item)
	_update_bytes_label()

func _on_voltar_pressed():
	get_tree().change_scene_to_file("res://Inventory/main_menu.tscn")

func _on_spawn_pressed():
	if item_held != null:
		return
	# Alterna entre int (1 byte) e double (2 bytes) para o jogador aprender a escolher o int
	var ids = ["item_number_0", "item_double_3.14159", "item_number_5", "item_double_2.71828"]
	var id = ids[randi() % ids.size()]
	var item = item_scene.instantiate()
	add_child(item)
	item.load_item(id)
	item.selected = true
	item_held = item
	_update_bytes_label()

func _on_slot_entered(slot):
	current_slot = slot
	if not item_held:
		return
	var used = _total_bytes_used()
	var need = item_held.get_size_bytes() if item_held.has_method("get_size_bytes") else 1
	if used + need > CAPACITY_BYTES:
		can_place = false
		hint_label.text = "Não cabe! Este item usa %d byte(s). Falta(m) %d byte(s)." % [need, CAPACITY_BYTES - used]
		return
	# Verifica se os slots necessários (1 ou 2 para double) estão livres
	can_place = _can_place_on_slot(slot)
	if not can_place:
		hint_label.text = "Slots ocupados ou não há espaço contíguo."

func _can_place_on_slot(slot) -> bool:
	if not item_held or not item_held.get("item_grids"):
		return slot.state == slot.States.FREE
	for grid in item_held.item_grids:
		var idx = slot.slot_ID + int(grid.x) + int(grid.y) * COL_COUNT
		if idx < 0 or idx >= grid_array.size():
			return false
		var line_switch = slot.slot_ID % COL_COUNT + int(grid.x)
		if line_switch < 0 or line_switch >= COL_COUNT:
			return false
		if grid_array[idx].state == grid_array[idx].States.TAKEN:
			return false
	return true

func _on_slot_exited(_slot):
	current_slot = null
	can_place = false
	_update_hint()

func _on_slot_item_changed(_slot):
	_update_bytes_label()
	_update_hint()

func _total_bytes_used() -> int:
	var total = 0
	for slot in grid_array:
		if slot.item_stored != null and slot.item_stored.has_method("get_size_bytes"):
			total += slot.item_stored.get_size_bytes()
	return total

func _update_bytes_label():
	var used = _total_bytes_used()
	bytes_label.text = "Mochila: %d / %d bytes" % [used, CAPACITY_BYTES]
	if used >= CAPACITY_BYTES:
		bytes_label.text += " — Cheia!"

func _update_hint():
	var used = _total_bytes_used()
	var free = CAPACITY_BYTES - used
	if free <= 0:
		hint_label.text = "Mochila cheia! Objetivo concluído."
	elif free == 1:
		hint_label.text = "Falta 1 byte. Coloque um INT (1 byte) no slot vazio!"
	else:
		hint_label.text = "Faltam %d bytes. Itens: INT = 1 byte, DOUBLE = 2 bytes." % free

@warning_ignore("unused_parameter")
func _process(delta):
	if item_held:
		if Input.is_action_just_pressed("select_item"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				_place_item()
	else:
		if Input.is_action_just_pressed("select_item"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				_pick_item()

func _place_item():
	if not can_place or current_slot == null:
		return
	var placing = item_held
	placing.get_parent().remove_child(placing)
	grid_container.add_child(placing)
	placing.global_position = get_global_mouse_position()
	placing._snap_to(current_slot.global_position + Vector2(25, 25))
	placing.grid_anchor = current_slot
	placing.selected = false
	icon_anchor = Vector2(0, 0)
	for grid in placing.item_grids:
		var idx = current_slot.slot_ID + int(grid.x) + int(grid.y) * COL_COUNT
		if idx >= 0 and idx < grid_array.size():
			grid_array[idx].state = grid_array[idx].States.TAKEN
			grid_array[idx].item_stored = placing
			grid_array[idx].set_item(placing)
	item_held = null
	can_place = false
	_update_bytes_label()
	_update_hint()

func _pick_item():
	if current_slot == null or current_slot.item_stored == null:
		return
	item_held = current_slot.item_stored
	item_held.selected = true
	item_held.get_parent().remove_child(item_held)
	add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	for grid in item_held.item_grids:
		var idx = item_held.grid_anchor.slot_ID + int(grid.x) + int(grid.y) * COL_COUNT
		if idx >= 0 and idx < grid_array.size():
			grid_array[idx].state = grid_array[idx].States.FREE
			grid_array[idx].item_stored = null
			grid_array[idx].set_item(null)
	_update_bytes_label()
	_update_hint()
