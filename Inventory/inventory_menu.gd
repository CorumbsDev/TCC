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

func _on_expressao_processada(resultado: Variant, tipo_resultado: String, codigo: String):
	print("=== EXPRESSÃO PROCESSADA ===")
	print("Resultado: ", resultado)
	print("Tipo: ", tipo_resultado)
	print("Código: ", codigo)
	
	# Consome os itens usados na expressão ANTES de criar o novo item
	consumir_itens_expressao()
	
	# Cria o item de resultado com o tipo correto
	create_result_item_typed(resultado, tipo_resultado)

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
					# Verifica se é operador
					if item.get("data_type") != null and item.data_type == item.DataType.OPERATOR:
						if item.operator != "":
							sequence.append(item.operator)
							slots_na_sequencia.append(slot)
					# Verifica se é um valor (qualquer tipo)
					elif item.get("data_type") != null:
						# Usa o método get_value_as_string() para obter o valor formatado
						if item.has_method("get_value_as_string"):
							sequence.append(item.get_value_as_string())
						else:
							# Fallback para compatibilidade
							match item.data_type:
								item.DataType.INT:
									sequence.append(str(item.value))
								item.DataType.FLOAT:
									sequence.append(str(item.value_float))
								item.DataType.BOOLEAN:
									sequence.append("true" if item.value_bool else "false")
								item.DataType.STRING:
									sequence.append('"' + item.value_string + '"')
						slots_na_sequencia.append(slot)
					# Fallback para itens antigos (compatibilidade)
					elif item.get("operator") != null and item.operator != "":
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
					# Verifica se é operador
					if item.get("data_type") != null and item.data_type == item.DataType.OPERATOR:
						if item.operator != "":
							sequence.append(item.operator)
							slots_na_sequencia.append(slot)
					# Verifica se é um valor (qualquer tipo)
					elif item.get("data_type") != null:
						# Usa o método get_value_as_string() para obter o valor formatado
						if item.has_method("get_value_as_string"):
							sequence.append(item.get_value_as_string())
						else:
							# Fallback para compatibilidade
							match item.data_type:
								item.DataType.INT:
									sequence.append(str(item.value))
								item.DataType.FLOAT:
									sequence.append(str(item.value_float))
								item.DataType.BOOLEAN:
									sequence.append("true" if item.value_bool else "false")
								item.DataType.STRING:
									sequence.append('"' + item.value_string + '"')
						slots_na_sequencia.append(slot)
					# Fallback para itens antigos (compatibilidade)
					elif item.get("operator") != null and item.operator != "":
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

func validar_tipos_expressao(sequence: Array) -> Dictionary:
	"""Valida se os tipos na expressão são compatíveis"""
	var tipos_encontrados = []
	var valores_encontrados = []
	
	# Analisa a sequência para identificar tipos
	for i in range(sequence.size()):
		var token = sequence[i]
		
		# Verifica se é operador
		if token in ["+", "-", "*", "/", "**", "//", "%", "==", "!=", ">", "<", ">=", "<=", "and", "or", "not"]:
			continue
		
		# Detecta tipo do valor
		if token.begins_with('"') and token.ends_with('"'):
			tipos_encontrados.append("STRING")
			valores_encontrados.append(token)
		elif token.to_lower() == "true" or token.to_lower() == "false":
			tipos_encontrados.append("BOOLEAN")
			valores_encontrados.append(token)
		elif "." in token and token.replace(".", "").replace("-", "").is_valid_float():
			tipos_encontrados.append("FLOAT")
			valores_encontrados.append(token)
		elif token.is_valid_int() or (token.begins_with("-") and token.substr(1).is_valid_int()):
			tipos_encontrados.append("INT")
			valores_encontrados.append(token)
		else:
			tipos_encontrados.append("UNKNOWN")
			valores_encontrados.append(token)
	
	# Verifica compatibilidade básica
	var tipos_unicos = []
	for tipo in tipos_encontrados:
		if tipo not in tipos_unicos and tipo != "UNKNOWN":
			tipos_unicos.append(tipo)
	
	var valido = true
	var mensagem = ""
	
	# Regras de validação
	if tipos_unicos.size() > 2:
		valido = false
		mensagem = "Muitos tipos diferentes na expressão"
	elif "STRING" in tipos_unicos and tipos_unicos.size() > 1:
		# String só pode ser concatenada com string ou multiplicada por int
		valido = true  # Python permite algumas operações
		mensagem = "Aviso: Operação com string"
	
	return {
		"valido": valido,
		"mensagem": mensagem,
		"tipos": tipos_encontrados,
		"valores": valores_encontrados
	}

func _process_sequence(seq: Array):
	if seq.size() >= 3:
		var expr = "".join(seq)
		ultima_expressao = expr
		print("Expressão formada:", expr)
		
		# Valida tipos (opcional - pode ser comentado se não quiser validação)
		var validacao = validar_tipos_expressao(seq)
		if not validacao.valido:
			print("AVISO: ", validacao.mensagem)
			# Continua mesmo assim - Python vai lidar com erros
		
		# Tenta usar o controlador externo primeiro
		if controlador_externo and controlador_externo.has_method("processar_expressao_assincrona"):
			controlador_externo.processar_expressao_assincrona(expr)
		else:
			# Fallback: avalia localmente
			var resultado_info = avaliar_expressao_com_tipo(expr)
			print("Resultado (fallback):", resultado_info.resultado, " Tipo:", resultado_info.tipo)
			
			# Consome os itens e cria o resultado
			consumir_itens_expressao()
			create_result_item_typed(resultado_info.resultado, resultado_info.tipo)

func avaliar_expressao_com_tipo(expr: String) -> Dictionary:
	"""Avalia expressão e retorna resultado com tipo"""
	expr = expr.replace(" ", "")
	
	# Detecta strings
	if expr.begins_with('"') and expr.ends_with('"'):
		var str_valor = expr.substr(1, expr.length() - 2)
		return {"resultado": str_valor, "tipo": "STRING"}
	
	# Detecta booleanos
	if expr.to_lower() == "true":
		return {"resultado": true, "tipo": "BOOLEAN"}
	if expr.to_lower() == "false":
		return {"resultado": false, "tipo": "BOOLEAN"}
	
	var expression = Expression.new()
	var error = expression.parse(expr, [])
	if error == OK:
		var resultado = expression.execute([], null, true)
		if not expression.has_execute_failed():
			var tipo_resultado = "FLOAT"
			if typeof(resultado) == TYPE_INT:
				tipo_resultado = "INT"
			elif typeof(resultado) == TYPE_FLOAT:
				tipo_resultado = "FLOAT"
			elif typeof(resultado) == TYPE_BOOL:
				tipo_resultado = "BOOLEAN"
			elif typeof(resultado) == TYPE_STRING:
				tipo_resultado = "STRING"
			
			return {"resultado": resultado, "tipo": tipo_resultado}
	
	return {"resultado": 0.0, "tipo": "FLOAT"}

func create_result_item(resultado: float):
	"""Método antigo mantido para compatibilidade - sempre cria INT"""
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

func create_result_item_typed(resultado: Variant, tipo_resultado: String):
	"""Cria um item de resultado com o tipo correto"""
	if item_held == null:
		var new_item = item_scene.instantiate()
		add_child(new_item)
		
		# Verifica se o item tem o método set_value_by_type
		if new_item.has_method("set_value_by_type"):
			# Mapeia o tipo string para o enum DataType
			var tipo_enum = new_item.DataType.INT  # Default
			
			match tipo_resultado:
				"INT":
					tipo_enum = new_item.DataType.INT
					var valor_int = int(resultado)
					valor_int = clamp(valor_int, -999, 999)  # Permite negativos
					new_item.set_value_by_type(valor_int, tipo_enum)
				"FLOAT":
					tipo_enum = new_item.DataType.FLOAT
					var valor_float = float(resultado)
					# Limita casas decimais para exibição
					valor_float = clamp(valor_float, -999.99, 999.99)
					new_item.set_value_by_type(valor_float, tipo_enum)
				"BOOLEAN":
					tipo_enum = new_item.DataType.BOOLEAN
					var valor_bool = bool(resultado)
					new_item.set_value_by_type(valor_bool, tipo_enum)
				"STRING":
					tipo_enum = new_item.DataType.STRING
					var valor_str = str(resultado)
					# Limita tamanho da string
					if valor_str.length() > 20:
						valor_str = valor_str.substr(0, 20) + "..."
					new_item.set_value_by_type(valor_str, tipo_enum)
				_:
					# Fallback: tenta converter para int
					tipo_enum = new_item.DataType.INT
					var valor_int = int(float(resultado))
					valor_int = clamp(valor_int, -999, 999)
					new_item.set_value_by_type(valor_int, tipo_enum)
		else:
			# Fallback: usa método antigo
			var valor_inteiro = int(float(resultado))
			valor_inteiro = clamp(valor_inteiro, 0, 999)
			if new_item.has_method("set_value_directly"):
				new_item.set_value_directly(valor_inteiro)
			else:
				var item_type = "item_number_" + str(valor_inteiro)
				if new_item.has_method("load_item"):
					new_item.load_item(item_type)
		
		new_item.selected = true
		item_held = new_item
		print("Item de resultado criado - Valor: ", resultado, " Tipo: ", tipo_resultado)

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
