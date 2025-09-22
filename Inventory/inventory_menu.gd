extends Control

@onready var slot_scene = preload("res://Inventory/slot.tscn")
@onready var grid_container = $Background/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var item_scene = preload("res://Inventory/Items/Item.tscn")
@onready var scroll_container = $Background/MarginContainer/VBoxContainer/ScrollContainer
@onready var col_count = grid_container.columns #save column number
@onready var slots # todos os slots filhos

var grid_array := []
var item_held = null
var current_slot = null
var can_place := false
var icon_anchor : Vector2

func _ready():
	for i in range(64):
		create_slot()

func _on_item_changed(slot):
	print("Item mudou no slot:", slot.slot_ID)
	check_combinations()

func _process(delta):
	if item_held:
		if Input.is_action_just_pressed("select_item"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				place_item()
	else:
		if Input.is_action_just_pressed("select_item"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				pick_item()

func create_slot():
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	grid_container.add_child(new_slot)
	grid_array.push_back(new_slot)

	# sinais já existentes
	new_slot.slot_entered.connect(_on_slot_mouse_entered)
	new_slot.slot_exited.connect(_on_slot_mouse_exited)

	# novo: conecta mudança de item
	new_slot.item_changed.connect(_on_item_changed)

func _on_slot_mouse_entered(a_Slot):
	icon_anchor = Vector2(10000,100000)
	current_slot = a_Slot
	if item_held:
		check_slot_availability(current_slot)
		set_grids.call_deferred(current_slot)

func _on_slot_mouse_exited(a_Slot):
	clear_grid()
	
	if not grid_container.get_global_rect().has_point(get_global_mouse_position()):
		current_slot = null

func create_item_on_hand(item_size: String):
	if item_held == null:
		var new_item = item_scene.instantiate()
		add_child(new_item)
		
		new_item.load_item(item_size)
		
		new_item.selected = true
		item_held = new_item

func create_item_on_hand_randomly():
	if item_held == null:
		var new_item = item_scene.instantiate()
		add_child(new_item)
		
		var random_item = ""
		
		match randi_range(1,5):
			1:
				random_item = "item_number_7"
			2:
				random_item = "item_operator_plus"
			3:
				random_item = "item_operator_plus"
			4:
				random_item = "item_number_7"
			5:
				random_item = "item_number_5"
		
		new_item.load_item(random_item)
		
		new_item.selected = true
		item_held = new_item

func _on_button_spawn_pressed():
	create_item_on_hand_randomly()

func check_slot_availability(a_Slot):
	
	for grid in item_held.item_grids:
		var grid_to_check = a_Slot.slot_ID + grid[0] + grid[1] * col_count
		var line_switch_check = a_Slot.slot_ID % col_count + grid[0]
		if line_switch_check < 0 or line_switch_check >= col_count:
			can_place = false
			return
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			can_place = false
			return
		if grid_array[grid_to_check].state == grid_array[grid_to_check].States.TAKEN:
			can_place = false
			return
		
	can_place = true

func set_grids(a_Slot):
	for grid in item_held.item_grids:
		var grid_to_check = a_Slot.slot_ID + grid[0] + grid[1] * col_count
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			continue
		#make sure the check don't wrap around boarders
		var line_switch_check = a_Slot.slot_ID % col_count + grid[0]
		if line_switch_check <0 or line_switch_check >= col_count:
			continue
		
		if can_place:
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.FREE)
			#save anchor for snapping
			if grid[1] < icon_anchor.x: icon_anchor.x = grid[1]
			if grid[0] < icon_anchor.y: icon_anchor.y = grid[0]
				
		else:
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.TAKEN)

func clear_grid():
	for grid in grid_array:
		grid.set_color(grid.States.DEFAULT)

func place_item():
	if not can_place or not current_slot: 
		return #put indication of placement failed, sound or visual here
		
	#for changing scene tree
	item_held.get_parent().remove_child(item_held)
	
	grid_container.add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	
	var calculated_grid_id = current_slot.slot_ID + icon_anchor.x * col_count + icon_anchor.y
	item_held._snap_to(grid_array[calculated_grid_id].global_position)
	#print(calculated_grid_id)
	item_held.grid_anchor = current_slot
	for grid in item_held.item_grids:
		var grid_to_check = current_slot.slot_ID + grid[0] + grid[1] * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.TAKEN 
		grid_array[grid_to_check].item_stored = item_held
		grid_array[grid_to_check].set_item(item_held) # dispara o sinal
	
	#put item into a data storage here
	
	item_held = null
	clear_grid()
	
func pick_item():
	if not current_slot or not current_slot.item_stored: 
		return
	item_held = current_slot.item_stored
	item_held.selected = true
	
	#move node in the scene tree
	item_held.get_parent().remove_child(item_held)
	add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	
	for grid in item_held.item_grids:
		var grid_to_check = item_held.grid_anchor.slot_ID + grid[0] + grid[1] * col_count # use grid anchor instead of current slot to prevent bug
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.FREE 
		grid_array[grid_to_check].item_stored = null
	
	check_slot_availability(current_slot)
	set_grids.call_deferred(current_slot)

func _on_add_slot_pressed():
	create_slot()

func use_item(item):
	if item.value != null:
		print("Número:", item.value)
	elif item.operator != null:
		print("Operador:", item.operator)

func check_combinations():
	# Verifica combinações horizontais
	for linha in range(8):  # 8 linhas (64 slots / 8 colunas)
		var sequence = []
		for coluna in range(8):  # 8 colunas
			var index = linha * 8 + coluna
			if index < grid_array.size():
				var slot = grid_array[index]
				if slot.item_stored != null:
					var item = slot.item_stored
					if item.operator != "":
						sequence.append(item.operator)
					elif item.value != 0:
						sequence.append(str(item.value))
				else:
					if sequence.size() >= 3:
						_process_sequence(sequence)
					sequence.clear()
		
		if sequence.size() >= 3:
			_process_sequence(sequence)

func _process_sequence(seq : Array):
	if seq.size() >= 3:
		var expr = "".join(seq)
		print("Expressão formada:", expr)
		
		# Avalia a expressão diretamente no GDScript
		var resultado = avaliar_expressao(expr)
		print("Resultado:", resultado)
		
		# Aqui você pode adicionar lógica para criar um novo item com o resultado
		# create_result_item(resultado)

func avaliar_expressao(expr: String) -> float:
	# Remove espaços em branco
	expr = expr.replace(" ", "")
	
	# Verifica se a expressão é válida
	if not expr.is_valid_float() and not ("+" in expr or "-" in expr or "*" in expr or "/" in expr):
		return 0.0
	
	# Usa a classe Expression do Godot para avaliar a expressão
	var expression = Expression.new()
	var error = expression.parse(expr, [])
	if error != OK:
		print("Erro ao analisar expressão: ", expression.get_error_text())
		return 0.0
	
	var result = expression.execute([], null, true)
	if expression.has_execute_failed():
		print("Erro ao executar expressão: ", expression.get_error_text())
		return 0.0
	
	return float(result)

func _on_slot_item_changed(slot: Variant) -> void:
	print("Item mudou no slot:", slot.slot_ID)
	check_combinations()
