extends Node2D

@onready var value_label: Label = $ColorRect/value_label

# Enum para identificar o tipo de dado do orb
enum DataType {INT, FLOAT, BOOLEAN, STRING, OPERATOR}

var item_ID : String
var data_type: DataType = DataType.INT  # Tipo padrão é INT
var value : int = 0
var value_float : float = 0.0
var value_bool : bool = false
var value_string : String = ""
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
		DataType.FLOAT:
			value_float = float(new_value)
			value = int(value_float)
			value_bool = false
			value_string = ""
		DataType.BOOLEAN:
			value_bool = bool(new_value)
			value = 1 if value_bool else 0
			value_float = 1.0 if value_bool else 0.0
			value_string = ""
		DataType.STRING:
			value_string = str(new_value)
			value = 0
			value_float = 0.0
			value_bool = false
		DataType.OPERATOR:
			operator = str(new_value)
			value = 0
			value_float = 0.0
			value_bool = false
			value_string = ""
	
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
	
	# Configura o texto baseado no tipo
	if data_type == DataType.OPERATOR:
		value_label.text = operator
		value_label.add_theme_color_override("font_color", Color.RED)
		value_label.add_theme_font_size_override("font_size", 24)
	elif data_type == DataType.INT:
		value_label.text = str(value)
		value_label.add_theme_color_override("font_color", Color.BLUE)
		value_label.add_theme_font_size_override("font_size", 20)
	elif data_type == DataType.FLOAT:
		value_label.text = str(value_float)
		value_label.add_theme_color_override("font_color", Color.CYAN)
		value_label.add_theme_font_size_override("font_size", 20)
	elif data_type == DataType.BOOLEAN:
		value_label.text = "true" if value_bool else "false"
		value_label.add_theme_color_override("font_color", Color.GREEN)
		value_label.add_theme_font_size_override("font_size", 20)
	elif data_type == DataType.STRING:
		value_label.text = '"' + value_string + '"'
		value_label.add_theme_color_override("font_color", Color.YELLOW)
		value_label.add_theme_font_size_override("font_size", 18)
	else:
		value_label.text = str(value)
		value_label.add_theme_color_override("font_color", Color.BLACK) 
		value_label.add_theme_font_size_override("font_size", 20)
	
	# Força o redesenho
	value_label.queue_redraw()

func _snap_to(destination):
	var tween = get_tree().create_tween()
	# Ajuste para usar o tamanho da Label
	if value_label:
		destination += value_label.size / 2
	tween.tween_property(self, "global_position", destination, 0.15).set_trans(Tween.TRANS_SINE)
	selected = false
