extends Control

# Referências para a UI (serão acessadas pelas filhas)
@onready var btn_voltar = $TopBar/BtnVoltar
@onready var btn_spawn = $HBox/BackpackPanel/MarginContainer/VBoxContainer/Header/BtnSpawn
@onready var bytes_label = $HBox/BackpackPanel/MarginContainer/VBoxContainer/BytesLabel
@onready var hint_label = $HBox/BackpackPanel/MarginContainer/VBoxContainer/HintLabel

# Referências para os containers onde os grids serão instanciados
@onready var backpack_container = $HBox/BackpackPanel/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var bancada_container = $HBox/BancadaPanel/MarginContainer/VBoxContainer/GridContainer

# Referências para os grids (serão preenchidos pelas filhas)
var backpack_grid: BackpackGrid = null
var bancada_grid: BancadaGrid = null

# Variáveis de estado do arrasto
var item_held = null
var current_slot = null
var can_place := false

func _ready():
	btn_voltar.pressed.connect(_on_voltar_pressed)
	if btn_spawn:
		btn_spawn.pressed.connect(_on_spawn_pressed)
	
	# As filhas devem chamar setup_grids() após instanciar os grids

func setup_grids(backpack: BackpackGrid, bancada: BancadaGrid):
	backpack_grid = backpack
	bancada_grid = bancada
	
	# Conecta sinais dos grids
	backpack_grid.slot_entered.connect(_on_slot_entered)
	backpack_grid.slot_exited.connect(_on_slot_exited)
	backpack_grid.item_changed.connect(_on_slot_item_changed)
	
	bancada_grid.slot_entered.connect(_on_slot_entered)
	bancada_grid.slot_exited.connect(_on_slot_exited)
	bancada_grid.item_changed.connect(_on_slot_item_changed)
	
	# Atualiza UI inicial
	_update_bytes_label()
	_update_hint()

func _on_voltar_pressed():
	get_tree().change_scene_to_file("res://Inventory/fases/main_menu.tscn")

func _on_spawn_pressed():
	# Pode ser sobrescrito pelas filhas
	pass

func _on_slot_entered(slot):
	current_slot = slot
	if not item_held:
		return
	
	# Verifica se o slot pertence à mochila ou à bancada
	if slot in backpack_grid.slots_array:
		can_place = backpack_grid.can_place_item(item_held, slot)
		if not can_place:
			var used = backpack_grid.total_bytes_used()
			var need = item_held.get_size_bytes()
			hint_label.text = "Não cabe! Este item usa %d byte(s). Falta(m) %d byte(s)." % [need, backpack_grid.capacity_bytes - used]
	elif slot in bancada_grid.slots_array and slot.item_stored == null:
		can_place = true
	else:
		can_place = false

func _on_slot_exited(_slot):
	current_slot = null
	can_place = false
	_update_hint()

func _on_slot_item_changed(_slot):
	_update_bytes_label()
	_update_hint()

func _process(delta):
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
	
	if current_slot in backpack_grid.slots_array:
		backpack_grid.place_item(item_held, current_slot)
	else:  # bancada
		var old_parent = item_held.get_parent()
		if old_parent:
			old_parent.remove_child(item_held)
			
		current_slot.add_child(item_held)
		item_held.position = Vector2(25, 25)
		item_held._snap_to(current_slot.global_position + Vector2(25, 25))
		current_slot.state = current_slot.States.TAKEN
		current_slot.item_stored = item_held
		current_slot.set_item(item_held)
	
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
	
	if slot in backpack_grid.slots_array:
		backpack_grid.remove_item(item_held)  # remove o item do grid
	else:
		bancada_grid.remove_item(slot)
	
	_update_bytes_label()
	_update_hint()

func _update_bytes_label():
	if not backpack_grid:
		return
	var used = backpack_grid.total_bytes_used()
	var cap = backpack_grid.capacity_bytes
	bytes_label.text = "Mochila: %d / %d bytes" % [used, cap]
	if used >= cap:
		bytes_label.text += " — Cheia!"

func _update_hint():
	if not backpack_grid:
		return
	var used = backpack_grid.total_bytes_used()
	var cap = backpack_grid.capacity_bytes
	var free = cap - used
	if free <= 0:
		hint_label.text = "Mochila cheia! Objetivo concluído."
	elif free == 1:
		hint_label.text = "Falta 1 byte. Coloque um INT (1 byte) no slot vazio!"
	else:
		hint_label.text = "Faltam %d bytes. Use números inteiros (1 byte cada)." % free
