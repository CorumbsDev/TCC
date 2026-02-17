extends Node2D

@onready var value_label: Label = $ColorRect/value_label

# Enum para identificar o tipo de dado do orb
enum DataType {INT, FLOAT, BOOLEAN, STRING, OPERATOR, DOUBLE, BINARY}

var item_ID : String
var data_type: DataType = DataType.INT  # Tipo padrão é INT
var value : int = 0
var value_float : float = 0.0
var value_bool : bool = false
var value_string : String = ""
var value_double : float = 0.0  # Precisão dupla (ocupa 2 slots)
var value_binary : String = "00000000"  # Representação binária em string
var binary_bits : int = 8  # Quantidade de bits para o tipo BINARY
var operator : String = ""
var selected = false
var item_grids := [Vector2(0,0)]
var grid_anchor = null
var is_hovered = false  # Nova variável para rastrear hover

# Signal para notificar quando o mouse entra/sai
signal mouse_entered_item(item)
signal mouse_exited_item(item)

func _ready():
	# Adiciona área de detecção de mouse se não existir
	setup_mouse_detection()

func setup_mouse_detection():
	# Verifica se já existe uma Area2D ou similar
	# Se não, vamos usar o método de detecção no _process
	pass

func _process(delta):
	if selected:
		global_position = lerp(global_position, get_global_mouse_position(), 25 * delta)
	
	# Detecta se o mouse está sobre o item
	check_mouse_hover()

func check_mouse_hover():
	# Verifica se o mouse está sobre o item
	var mouse_pos = get_global_mouse_position()
	var item_rect = get_item_rect()
	
	if item_rect.has_point(to_local(mouse_pos)):
		if not is_hovered:
			is_hovered = true
			mouse_entered_item.emit(self)
	else:
		if is_hovered:
			is_hovered = false
			mouse_exited_item.emit(self)

func get_item_rect() -> Rect2:
	"""Retorna o retângulo do item para detecção de hover"""
	if value_label:
		var label_size = value_label.size
		var label_pos = value_label.global_position - global_position
		return Rect2(label_pos, label_size)
	else:
		# Fallback: retângulo padrão
		return Rect2(Vector2(-20, -20), Vector2(40, 40))

func get_item_info() -> Dictionary:
	"""Retorna um dicionário com todas as informações do item"""
	var info = {
		"tipo": "",
		"valor": "",
		"id": "",
		"detalhes": ""
	}
	
	# Garante que o ID sempre tenha um valor
	if item_ID == null or item_ID == "":
		# Gera um ID baseado no tipo e valor
		match data_type:
			DataType.INT:
				info.id = "item_number_" + str(value)
			DataType.FLOAT:
				info.id = "item_float_" + str(value_float)
			DataType.BOOLEAN:
				info.id = "item_bool_" + ("true" if value_bool else "false")
			DataType.STRING:
				info.id = "item_string_" + str(value_string.hash())
			DataType.OPERATOR:
				info.id = "item_operator_" + operator
			DataType.DOUBLE:
				info.id = "item_double_" + str(value_double)
			DataType.BINARY:
				info.id = "item_binary_" + str(value)
			_:
				info.id = "item_unknown"
	else:
		info.id = item_ID
	
	match data_type:
		DataType.INT:
			info.tipo = "INT (Inteiro)"
			info.valor = str(value)
			info.detalhes = "Número inteiro: " + str(value)
		DataType.FLOAT:
			info.tipo = "FLOAT (Decimal)"
			info.valor = str(value_float)
			info.detalhes = "Número decimal: " + str(value_float)
		DataType.BOOLEAN:
			info.tipo = "BOOLEAN (Booleano)"
			info.valor = "true" if value_bool else "false"
			info.detalhes = "Valor booleano: " + ("Verdadeiro" if value_bool else "Falso")
		DataType.STRING:
			info.tipo = "STRING (Texto)"
			info.valor = '"' + value_string + '"'
			info.detalhes = "Texto: " + value_string
		DataType.OPERATOR:
			info.tipo = "OPERATOR (Operador)"
			info.valor = operator
			info.detalhes = "Operador: " + operator
		DataType.DOUBLE:
			info.tipo = "DOUBLE (Precisão Dupla)"
			info.valor = str(value_double)
			info.detalhes = "Valor double: " + str(value_double) + "\nOcupa 2 slots"
		DataType.BINARY:
			var decimal_val = binary_to_int(value_binary)
			info.tipo = "BINARY (Binário)"
			info.valor = value_binary
			info.detalhes = "Binário: " + value_binary + "\nDecimal: " + str(decimal_val) + "\nBits: " + str(binary_bits) + "\nOcupa " + str(binary_bits) + " slots"
		_:
			info.tipo = "DESCONHECIDO"
			info.valor = str(value)
			info.detalhes = "Tipo não identificado"
	
	return info

func load_item(a_ItemID: String) -> void:
	item_ID = a_ItemID
	var data = DataHandler.item_data[item_ID]

	# Verifica se é um operador
	if data.has("Operator") and str(data["Operator"]) != "":
		operator = str(data["Operator"])
		data_type = DataType.OPERATOR
		value = 0
		value_float = 0.0
		value_bool = false
		value_string = ""
	# Verifica o tipo de dado
	elif data.has("DataType"):
		var tipo = str(data["DataType"]).to_upper()
		match tipo:
			"FLOAT":
				data_type = DataType.FLOAT
				value_float = float(data.get("Value", 0.0))
				value = 0
				value_bool = false
				value_string = ""
			"BOOLEAN", "BOOL":
				data_type = DataType.BOOLEAN
				value_bool = bool(data.get("Value", false))
				value = 0
				value_float = 0.0
				value_string = ""
			"STRING", "STR":
				data_type = DataType.STRING
				value_string = str(data.get("Value", ""))
				value = 0
				value_float = 0.0
				value_bool = false
			"DOUBLE":
				data_type = DataType.DOUBLE
				value_double = float(data.get("Value", 0.0))
				value = int(value_double)
				value_float = value_double
				value_bool = false
				value_string = ""
				# DOUBLE ocupa 2 slots horizontais
				item_grids = [Vector2(0,0), Vector2(1,0)]
			"BINARY", "BIN":
				data_type = DataType.BINARY
				binary_bits = int(data.get("Bits", 8))
				value = int(data.get("Value", 0))
				value_binary = int_to_binary(value, binary_bits)
				value_float = float(value)
				value_bool = false
				value_string = ""
				# BINARY ocupa 1 slot (antes era N slots)
				item_grids = [Vector2(0,0)]
			_:
				# Padrão: INT
				data_type = DataType.INT
				value = int(data.get("Value", 0))
				value_float = 0.0
				value_bool = false
				value_string = ""
	else:
		# Fallback: assume que é um número inteiro (compatibilidade)
		data_type = DataType.INT
		value = int(data.get("Value", 0))
		value_float = 0.0
		value_bool = false
		value_string = ""
		operator = ""

	update_label_display()

func set_value_directly(new_value: int):
	"""Define o valor diretamente (para resultados de expressões) - mantém compatibilidade"""
	value = new_value
	value_float = float(new_value)
	value_bool = false
	value_string = ""
	operator = ""
	data_type = DataType.INT
	item_ID = "item_number_" + str(new_value)
	update_label_display()

func set_value_by_type(new_value, tipo: DataType):
	"""Define o valor baseado no tipo de dado"""
	data_type = tipo
	operator = ""
	
	match tipo:
		DataType.INT:
			value = int(new_value)
			value_float = float(new_value)
			value_bool = false
			value_string = ""
			item_grids = [Vector2(0,0)]
		DataType.FLOAT:
			value_float = float(new_value)
			value = int(value_float)
			value_bool = false
			value_string = ""
			item_grids = [Vector2(0,0)]
		DataType.BOOLEAN:
			value_bool = bool(new_value)
			value = 1 if value_bool else 0
			value_float = 1.0 if value_bool else 0.0
			value_string = ""
			item_grids = [Vector2(0,0)]
		DataType.STRING:
			value_string = str(new_value)
			value = 0
			value_float = 0.0
			value_bool = false
			item_grids = [Vector2(0,0)]
		DataType.OPERATOR:
			operator = str(new_value)
			value = 0
			value_float = 0.0
			value_bool = false
			value_string = ""
			item_grids = [Vector2(0,0)]
		DataType.DOUBLE:
			value_double = float(new_value)
			value = int(value_double)
			value_float = value_double
			value_bool = false
			value_string = ""
			# DOUBLE ocupa 2 slots horizontais
			item_grids = [Vector2(0,0), Vector2(1,0)]
		DataType.BINARY:
			value = int(new_value)
			value_binary = int_to_binary(value, binary_bits)
			value_float = float(value)
			value_bool = false
			value_string = ""
			# BINARY ocupa 1 slot (antes era N slots)
			item_grids = [Vector2(0,0)]
	
	update_label_display()

func get_value_as_string() -> String:
	"""Retorna o valor como string baseado no tipo"""
	match data_type:
		DataType.INT:
			return str(value)
		DataType.FLOAT:
			return str(value_float)
		DataType.BOOLEAN:
			return "true" if value_bool else "false"
		DataType.STRING:
			return value_string
		DataType.OPERATOR:
			return operator
		DataType.DOUBLE:
			return str(value_double)
		DataType.BINARY:
			return str(binary_to_int(value_binary))
		_:
			return str(value)

func set_operator_directly(new_operator: String):
	"""Define o operador diretamente"""
	operator = new_operator
	data_type = DataType.OPERATOR
	value = 0
	value_float = 0.0
	value_bool = false
	value_string = ""
	item_ID = "item_operator_" + new_operator
	update_label_display()

func update_label_display():
	# Aguarda a Label estar pronta se necessário
	if not value_label:
		# Tenta encontrar a Label se não foi atribuída automaticamente
		value_label = get_node_or_null("ValueLabel")
		if not value_label:
			# Procura por qualquer Label na cena
			var labels = get_children().filter(func(child): return child is Label)
			if labels.size() > 0:
				value_label = labels[0]
			else:
				push_error("Nenhuma Label encontrada no item!")
				return
	
	# Garante que a Label está visível
	value_label.visible = true
	
	# Referência ao ColorRect pai da label
	var color_rect = value_label.get_parent() if value_label.get_parent() is ColorRect else null
	
	# Configura o texto baseado no tipo
	if data_type == DataType.OPERATOR:
		value_label.text = operator
		value_label.add_theme_color_override("font_color", Color.RED)
		value_label.add_theme_font_size_override("font_size", 24)
		_resize_visual(color_rect, 1)
	elif data_type == DataType.INT:
		value_label.text = str(value)
		value_label.add_theme_color_override("font_color", Color.BLUE)
		value_label.add_theme_font_size_override("font_size", 20)
		_resize_visual(color_rect, 1)
	elif data_type == DataType.FLOAT:
		value_label.text = str(value_float)
		value_label.add_theme_color_override("font_color", Color.CYAN)
		value_label.add_theme_font_size_override("font_size", 20)
		_resize_visual(color_rect, 1)
	elif data_type == DataType.BOOLEAN:
		value_label.text = "true" if value_bool else "false"
		value_label.add_theme_color_override("font_color", Color.GREEN)
		value_label.add_theme_font_size_override("font_size", 20)
		_resize_visual(color_rect, 1)
	elif data_type == DataType.STRING:
		value_label.text = '"' + value_string + '"'
		value_label.add_theme_color_override("font_color", Color.YELLOW)
		value_label.add_theme_font_size_override("font_size", 18)
		_resize_visual(color_rect, 1)
	elif data_type == DataType.DOUBLE:
		# DOUBLE: mostra valor com precisão, ocupa 2 slots
		value_label.text = str(value_double)
		value_label.add_theme_color_override("font_color", Color.MAGENTA)
		value_label.add_theme_font_size_override("font_size", 16)
		_resize_visual(color_rect, 2)
	elif data_type == DataType.BINARY:
		# BINARY: mostra valor bit a bit (ex: "1010") em 1 slot
		value_label.text = value_binary
		value_label.add_theme_color_override("font_color", Color.LIME)
		value_label.add_theme_font_size_override("font_size", 14)
		_resize_visual(color_rect, 1) # Sempre 1 slot
		
		# Tenta carregar sprite específico se existir
		var icon = get_node_or_null("Icon")
		if icon:
			var binary_texture = load("res://Inventory/Sprites/Item_binary.png")
			if binary_texture:
				icon.texture = binary_texture
	else:
		value_label.text = str(value)
		value_label.add_theme_color_override("font_color", Color.BLACK) 
		value_label.add_theme_font_size_override("font_size", 20)
		_resize_visual(color_rect, 1)
	
	# Força o redesenho
	value_label.queue_redraw()

func _resize_visual(color_rect, slot_count: int):
	"""Redimensiona o ColorRect e a Label para cobrir múltiplos slots"""
	var slot_size = 50  # Tamanho de cada slot em pixels
	var total_width = slot_count * slot_size
	
	if color_rect and color_rect is ColorRect:
		# Mantém margem de 5px em cada lado (slot = 50px, visual = 40px por slot)
		color_rect.offset_left = -19
		color_rect.offset_right = total_width - 19 - 10
		color_rect.offset_top = -20
		color_rect.offset_bottom = 20
	
	if value_label:
		# Label preenche o ColorRect
		value_label.offset_left = 0
		value_label.offset_right = total_width - 10
		value_label.custom_minimum_size.x = total_width - 10

func _snap_to(destination):
	var tween = get_tree().create_tween()
	# Offset fixo baseado no centro de 1 slot (50x50)
	# Não usa value_label.size pois itens multi-slot teriam offset errado
	destination += Vector2(20, 10)
	tween.tween_property(self, "global_position", destination, 0.15).set_trans(Tween.TRANS_SINE)
	selected = false

# ===== Funções auxiliares para BINARY =====

func int_to_binary(val: int, bits: int) -> String:
	"""Converte um inteiro para string binária com N bits"""
	if val < 0:
		val = 0
	var result = ""
	var temp = val
	for i in range(bits):
		result = str(temp % 2) + result
		temp = temp / 2
	return result

func binary_to_int(bin_str: String) -> int:
	"""Converte uma string binária para inteiro"""
	var result = 0
	for i in range(bin_str.length()):
		result = result * 2 + int(bin_str[i])
	return result
