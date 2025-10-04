extends Control

@onready var slot_scene = preload("res://Inventory/slot.tscn")
@onready var grid_container = $Background/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var item_scene = preload("res://Inventory/Items/Item.tscn")
@onready var scroll_container = $Background/MarginContainer/VBoxContainer/ScrollContainer
@onready var col_count = grid_container.columns
@onready var controlador_externo = $ControladorExterno

var grid_array := []
var item_held = null
var current_slot = null
var can_place := false
var icon_anchor : Vector2

# Variáveis para controlar as expressões e itens consumidos
var ultimos_slots_expressao = []  # Armazena os slots usados na última expressão
var ultima_expressao = ""         # Armazena a última expressão processada

func _ready():
	if controlador_externo and controlador_externo.has_signal("expressao_processada"):
		controlador_externo.expressao_processada.connect(_on_expressao_processada)
		print("Controlador externo conectado")
	else:
		print("Controlador externo não encontrado, usando fallback")
	
	for i in range(64):
		create_slot()

func _on_expressao_processada(resultado: float, codigo: String):
	print("=== EXPRESSÃO PROCESSADA ===")
	print("Resultado: ", resultado)
	print("Código: ", codigo)
	
	# Consome os itens usados na expressão ANTES de criar o novo item
	consumir_itens_expressao()
	
	# Cria o item de resultado
	create_result_item(resultado)

func create_slot():
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	grid_container.add_child(new_slot)
	grid_array.push_back(new_slot)

	new_slot.slot_entered.connect(_on_slot_mouse_entered)
	new_slot.slot_exited.connect(_on_slot_mouse_exited)
	new_slot.item_changed.connect(_on_item_changed)

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

func _on_slot_mouse_entered(a_Slot):
	icon_anchor = Vector2(10000, 100000)
	current_slot = a_Slot
	if item_held:
		check_slot_availability(current_slot)
		set_grids.call_deferred(current_slot)

func _on_slot_mouse_exited(a_Slot):
	clear_grid()
	if not grid_container.get_global_rect().has_point(get_global_mouse_position()):
		current_slot = null

func create_item_on_hand_randomly():
	if item_held == null:
		var new_item = item_scene.instantiate()
		add_child(new_item)
		
		var random_item = ""
		match randi_range(1, 5):
			1: random_item = "item_number_7"
			2: random_item = "item_operator_plus"
			3: random_item = "item_operator_increment"
			4: random_item = "item_number_7"
			5: random_item = "item_number_5"
		
		if new_item.has_method("load_item"):
			new_item.load_item(random_item)
		else:
			print("Item não tem método load_item")
		
		new_item.selected = true
		item_held = new_item

func _on_button_spawn_pressed():
	create_item_on_hand_randomly()

func check_slot_availability(a_Slot):
	if not item_held:
		can_place = false
		return
	
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
	if not item_held:
		return
	
	for grid in item_held.item_grids:
		var grid_to_check = a_Slot.slot_ID + grid[0] + grid[1] * col_count
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			continue
		var line_switch_check = a_Slot.slot_ID % col_count + grid[0]
		if line_switch_check < 0 or line_switch_check >= col_count:
			continue
		
		if can_place:
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.FREE)
			if grid[1] < icon_anchor.x: icon_anchor.x = grid[1]
			if grid[0] < icon_anchor.y: icon_anchor.y = grid[0]
		else:
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.TAKEN)

func clear_grid():
	for slot in grid_array:
		slot.set_color(slot.States.DEFAULT)

func place_item():
	if not can_place or not current_slot: 
		return
	
	item_held.get_parent().remove_child(item_held)
	grid_container.add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	
	var calculated_grid_id = current_slot.slot_ID + int(icon_anchor.x) * col_count + int(icon_anchor.y)
	item_held._snap_to(grid_array[calculated_grid_id].global_position)
	item_held.grid_anchor = current_slot
	
	for grid in item_held.item_grids:
		var grid_to_check = current_slot.slot_ID + grid[0] + grid[1] * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.TAKEN 
		grid_array[grid_to_check].item_stored = item_held
		grid_array[grid_to_check].set_item(item_held)
	
	item_held = null
	clear_grid()

func pick_item():
	if not current_slot or not current_slot.item_stored: 
		return
	
	item_held = current_slot.item_stored
	item_held.selected = true
	
	item_held.get_parent().remove_child(item_held)
	add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	
	for grid in item_held.item_grids:
		var grid_to_check = item_held.grid_anchor.slot_ID + grid[0] + grid[1] * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.FREE 
		grid_array[grid_to_check].item_stored = null
	
	check_slot_availability(current_slot)
	set_grids.call_deferred(current_slot)

func _on_add_slot_pressed():
	create_slot()

func check_combinations():
	# Verifica combinações horizontais
	for linha in range(8):
		var sequence = []
		var slots_na_sequencia = []  # Armazena os slots usados na sequência
		for coluna in range(8):
			var index = linha * 8 + coluna
			if index < grid_array.size():
				var slot = grid_array[index]
				if slot.item_stored != null:
					var item = slot.item_stored
					if item.get("operator") != null and item.operator != "":
						sequence.append(item.operator)
						slots_na_sequencia.append(slot)
					elif item.get("value") != null and item.value != 0:
						sequence.append(str(item.value))
						slots_na_sequencia.append(slot)
				else:
					if sequence.size() >= 3:
						# Armazena os slots usados antes de processar
						ultimos_slots_expressao = slots_na_sequencia.duplicate()
						_process_sequence(sequence)
					sequence.clear()
					slots_na_sequencia.clear()
		
		if sequence.size() >= 3:
			# Armazena os slots usados antes de processar
			ultimos_slots_expressao = slots_na_sequencia.duplicate()
			_process_sequence(sequence)
	
	# Verifica combinações verticais
	for coluna in range(8):
		var sequence = []
		var slots_na_sequencia = []  # Armazena os slots usados na sequência
		for linha in range(8):
			var index = linha * 8 + coluna
			if index < grid_array.size():
				var slot = grid_array[index]
				if slot.item_stored != null:
					var item = slot.item_stored
					if item.get("operator") != null and item.operator != "":
						sequence.append(item.operator)
						slots_na_sequencia.append(slot)
					elif item.get("value") != null and item.value != 0:
						sequence.append(str(item.value))
						slots_na_sequencia.append(slot)
				else:
					if sequence.size() >= 3:
						# Armazena os slots usados antes de processar
						ultimos_slots_expressao = slots_na_sequencia.duplicate()
						_process_sequence(sequence)
					sequence.clear()
					slots_na_sequencia.clear()
		
		if sequence.size() >= 3:
			# Armazena os slots usados antes de processar
			ultimos_slots_expressao = slots_na_sequencia.duplicate()
			_process_sequence(sequence)

func _process_sequence(seq: Array):
	if seq.size() >= 3:
		var expr = "".join(seq)
		ultima_expressao = expr  # Armazena a expressão
		print("Expressão formada:", expr)
		
		# Tenta usar o controlador externo primeiro
		if controlador_externo and controlador_externo.has_method("processar_expressao_assincrona"):
			controlador_externo.processar_expressao_assincrona(expr)
		else:
			# Fallback: avalia localmente
			var resultado = avaliar_expressao(expr)
			print("Resultado (fallback):", resultado)
			
			# Consome os itens e cria o resultado
			consumir_itens_expressao()
			create_result_item(resultado)

func avaliar_expressao(expr: String) -> float:
	expr = expr.replace(" ", "")
	var expression = Expression.new()
	var error = expression.parse(expr, [])
	if error == OK:
		var result = expression.execute([], null, true)
		if not expression.has_execute_failed():
			return float(result)
	return 0.0

func create_result_item(resultado: float):
	if item_held == null:
		var new_item = item_scene.instantiate()
		add_child(new_item)
		
		# Converte o resultado para inteiro
		var valor_inteiro = int(resultado)
		valor_inteiro = clamp(valor_inteiro, 0, 999)
		
		# Usa o método para definir o valor diretamente
		if new_item.has_method("set_value_directly"):
			new_item.set_value_directly(valor_inteiro)
		else:
			# Fallback para o método antigo
			var item_type = "item_number_" + str(valor_inteiro)
			if new_item.has_method("load_item"):
				new_item.load_item(item_type)
		
		new_item.selected = true
		item_held = new_item
		print("Item de resultado criado com valor: ", valor_inteiro)

func consumir_itens_expressao():
	"""Remove os itens usados na expressão do grid"""
	print("Consumindo ", ultimos_slots_expressao.size(), " itens da expressão")
	
	for slot in ultimos_slots_expressao:
		if slot.item_stored != null:
			var item = slot.item_stored
			
			# Remove o item do slot
			slot.item_stored = null
			
			# Se o item está atualmente segurado, solta ele
			if item == item_held:
				item_held = null
			
			# Remove o item da cena
			item.queue_free()
			
			# Atualiza o estado do slot
			slot.state = slot.States.FREE
			slot.set_color(slot.States.DEFAULT)
			slot.set_item(null)  # Dispara o sinal de mudança
	
	# Limpa a lista de slots usados
	ultimos_slots_expressao.clear()

# Função para debug - mostra os slots que serão consumidos
func debug_slots_expressao():
	print("Slots marcados para consumo:")
	for slot in ultimos_slots_expressao:
		print(" - Slot ", slot.slot_ID)
