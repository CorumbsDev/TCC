extends Node2D

@onready var value_label: Label = $ColorRect/value_label

# Enum para identificar o tipo de dado do orb
enum DataType {INT, FLOAT, BOOLEAN, STRING, OPERATOR, DOUBLE, BINARY, SHORT_INT, FP8, FP16, RAW}

var item_ID : String
var data_type: DataType = DataType.INT  # Tipo padrão é INT
var value : int = 0
var value_float : float = 0.0
var value_bool : bool = false
var value_string : String = ""
var value_double : float = 0.0  # Precisão dupla (ocupa 2 slots)
var value_short : int = 0
var value_binary : String = "00000000"  # Representação binária em string
var binary_bits : int = 8  # Quantidade de bits para o tipo BINARY
var operator : String = ""
var selected = false
var item_grids := [Vector2(0,0)]
var grid_anchor = null
var is_hovered = false  # Nova variável para rastrear hover

var fp_exp_bits: int = -1
var fp_mant_bits: int = -1

## Tamanho visual de um slot na grade (deve bater com slot.gd).
const SLOT_PX := 64
const ORB_SLOT_MARGIN := 12

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
	if selected:
		if is_hovered:
			is_hovered = false
			mouse_exited_item.emit(self)
		return
	var mouse_pos := get_global_mouse_position()
	var item_rect := get_item_rect()
	if item_rect.has_point(to_local(mouse_pos)):
		if not is_hovered:
			is_hovered = true
			mouse_entered_item.emit(self)
	else:
		if is_hovered:
			is_hovered = false
			mouse_exited_item.emit(self)

func get_item_rect() -> Rect2:
	"""Retorna o retângulo do item para detecção de hover / clique."""
	var half: float = SLOT_PX * 0.5
	if grid_anchor != null or not selected:
		return Rect2(Vector2(-half, -half), Vector2(SLOT_PX, SLOT_PX))
	var icon: TextureRect = get_node_or_null("Icon") as TextureRect
	if icon and icon.size.x > 1.0:
		return Rect2(icon.position, icon.size)
	if value_label:
		return Rect2(value_label.position, value_label.size)
	return Rect2(Vector2(-half, -half), Vector2(SLOT_PX, SLOT_PX))

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
			DataType.RAW:
				info.id = "item_raw_" + str(value_float)
			_:
				info.id = "item_unknown"
	else:
		info.id = item_ID
	
	var full_val: String = OrbValueFormat.full_value_string(self)
	match data_type:
		DataType.INT:
			info.tipo = "INT (Inteiro)"
			info.valor = full_val
			info.detalhes = "Número inteiro: " + full_val
		DataType.FLOAT:
			info.tipo = "FLOAT (Decimal)"
			info.valor = full_val
			info.detalhes = "Número decimal: " + full_val
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
			info.valor = full_val
			info.detalhes = "Valor double: " + full_val + "\nOcupa 2 slots"
		DataType.BINARY:
			var decimal_val = binary_to_int(value_binary)
			var explicacao = get_binary_explanation(value_binary)
			info.tipo = "BINARY (Binário)"
			info.valor = value_binary
			info.detalhes = "Binário: " + value_binary + "\nDecimal: " + str(decimal_val) + "\nBits: " + str(binary_bits) + "\nOcupa " + str(binary_bits) + " slots\n\nComo o binário funciona:\n" + explicacao
		DataType.FP8:
			info.tipo = "FP8 (Float 8-bit)"
			info.valor = full_val
			info.detalhes = "Ponto flutuante 8-bit: " + full_val + "\nOcupa 0.25 slots"
		DataType.FP16:
			info.tipo = "FP16 (Float 16-bit)"
			info.valor = full_val
			info.detalhes = "Ponto flutuante 16-bit: " + full_val + "\nOcupa 0.5 slots"
		DataType.RAW:
			info.tipo = "RAW (Valor Puro)"
			info.valor = full_val
			info.detalhes = "Valor sem tipo definido: " + full_val + "\nArraste para uma caixa de tipagem."
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
				item_grids = [Vector2(0,0)]
			"SHORT_INT", "SHORT":
				data_type = DataType.SHORT_INT
				value_short = int(data.get("Value", 0))
				value = value_short
				value_float = float(value_short)
				value_bool = false
				value_string = ""
				item_grids = [Vector2(0,0)]
			"FP8":
				data_type = DataType.FP8
				value_float = float(data.get("Value", 0.0))
				value = int(value_float)
				value_bool = false
				value_string = ""
				item_grids = [Vector2(0,0)]
			"FP16":
				data_type = DataType.FP16
				value_float = float(data.get("Value", 0.0))
				value = int(value_float)
				value_bool = false
				value_string = ""
				item_grids = [Vector2(0,0)]
			"RAW":
				data_type = DataType.RAW
				value_float = float(data.get("Value", 0.0))
				value = int(value_float)
				value_bool = false
				value_string = ""
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
		DataType.SHORT_INT:
			value_short = int(new_value)
			value = value_short
			value_float = float(value_short)
			value_bool = false
			value_string = ""
			item_grids = [Vector2(0,0)]
		DataType.FP8:
			value_float = float(new_value)
			value = int(value_float)
			value_bool = false
			value_string = ""
			item_grids = [Vector2(0,0)]
		DataType.FP16:
			value_float = float(new_value)
			value = int(value_float)
			value_bool = false
			value_string = ""
			item_grids = [Vector2(0,0)]
		DataType.RAW:
			value_float = float(new_value)
			value = int(value_float)
			value_bool = false
			value_string = ""
			item_grids = [Vector2(0,0)]
	
	update_label_display()

func get_value_as_string() -> String:
	"""Valor completo (console / lógica), não a versão compacta do rótulo."""
	return OrbValueFormat.full_value_string(self)

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
	# Garante que a Label existe (caminho correto na cena: ColorRect/value_label)
	if not value_label:
		value_label = get_node_or_null("ColorRect/value_label")
	if not value_label:
		value_label = get_node_or_null("ValueLabel")
	if not value_label:
		var cr = get_node_or_null("ColorRect")
		if cr:
			value_label = cr.get_node_or_null("value_label")
	if not value_label:
		push_error("Nenhuma Label encontrada no item!")
		return
	
	# Garante que a Label está visível
	value_label.visible = true
	
	# Referência ao ColorRect pai da label
	var color_rect = value_label.get_parent() if value_label.get_parent() is ColorRect else null
	
	if color_rect:
		if data_type == DataType.RAW:
			color_rect.color = Color(0.5, 0.5, 0.5, 1)
		else:
			color_rect.color = Color(0.24, 0.17, 0.08, 1)
		color_rect.z_index = -1
	
	var slot_scale := 1.0
	match data_type:
		DataType.OPERATOR:
			value_label.add_theme_color_override("font_color", Color(1, 0.85, 0.35, 1))
			var op_fs: int = 22 if operator.length() <= 2 else 13
			value_label.add_theme_font_size_override("font_size", op_fs)
			value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		DataType.INT:
			value_label.add_theme_color_override("font_color", Color.BLUE)
			value_label.add_theme_font_size_override("font_size", 20)
		DataType.FLOAT:
			value_label.add_theme_color_override("font_color", Color.RED)
			value_label.add_theme_font_size_override("font_size", 20)
		DataType.BOOLEAN:
			value_label.add_theme_color_override("font_color", Color.GREEN)
			value_label.add_theme_font_size_override("font_size", 12)
			slot_scale = 0.25
		DataType.STRING:
			value_label.add_theme_color_override("font_color", Color.YELLOW)
			value_label.add_theme_font_size_override("font_size", 18)
		DataType.DOUBLE:
			value_label.add_theme_color_override("font_color", Color.MAGENTA)
			value_label.add_theme_font_size_override("font_size", 16)
			slot_scale = 2.0
		DataType.BINARY:
			value_label.add_theme_color_override("font_color", Color.LIME)
			value_label.add_theme_font_size_override("font_size", 14)
		DataType.SHORT_INT:
			value_label.add_theme_color_override("font_color", Color.CYAN)
			value_label.add_theme_font_size_override("font_size", 18)
			slot_scale = 0.5
		DataType.FP8:
			value_label.add_theme_color_override("font_color", Color.VIOLET)
			value_label.add_theme_font_size_override("font_size", 14)
			slot_scale = 0.25
		DataType.FP16:
			value_label.add_theme_color_override("font_color", Color.GOLD)
			value_label.add_theme_font_size_override("font_size", 16)
			slot_scale = 0.5
		DataType.RAW:
			value_label.add_theme_color_override("font_color", Color.WHITE)
			value_label.add_theme_font_size_override("font_size", 20)
		_:
			value_label.add_theme_color_override("font_color", Color.BLACK)
			value_label.add_theme_font_size_override("font_size", 20)
	if data_type == DataType.OPERATOR:
		value_label.text = operator_display_label()
	elif data_type == DataType.BINARY:
		value_label.text = value_binary
	else:
		value_label.text = OrbValueFormat.compact_label_string(self)
	var has_orb_art := false
	_resize_visual(color_rect, slot_scale)
	has_orb_art = _apply_orb_sprite(slot_scale)
	if has_orb_art and value_label:
		value_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		value_label.add_theme_constant_override("outline_size", 4)
	if OrbValueFormat.should_compact(self):
		value_label.tooltip_text = "Valor exato: " + OrbValueFormat.full_value_string(self)
	else:
		value_label.tooltip_text = ""
	if data_type == DataType.OPERATOR:
		value_label.tooltip_text = "Operador: " + operator
	value_label.queue_redraw()
	call_deferred("_ensure_centered_in_slot_parent")


func operator_display_label() -> String:
	match operator:
		"+": return "+"
		"++": return "++"
		"to_int": return "int"
		"to_float": return "flt"
		"to_short": return "sh"
		"to_boolean", "to_bool": return "bool"
	if operator.begins_with("to_") and operator.length() > 3:
		return operator.substr(3)
	if operator.length() <= 5:
		return operator
	return operator.substr(0, 5)


func _ensure_centered_in_slot_parent() -> void:
	var p := get_parent()
	if p is TextureRect and p.is_in_group("slot"):
		position = position_in_slot(p)


func _slot_item_count(slot: TextureRect) -> int:
	var n := 0
	for it in slot.items_stored:
		if it != null:
			n += 1
	return n

func _apply_orb_sprite(slot_count: float = 1.0) -> bool:
	var icon: TextureRect = get_node_or_null("Icon") as TextureRect
	if icon == null:
		return false
	var path := ""
	match data_type:
		DataType.INT:
			path = "res://Inventory/Art/Orbs/orb_int.png"
		DataType.FLOAT:
			path = "res://Inventory/Art/Orbs/orb_float.png"
		DataType.DOUBLE:
			path = "res://Inventory/Art/Orbs/orb_double.png"
		DataType.BOOLEAN:
			path = "res://Inventory/Art/Orbs/orb_bool.png"
		DataType.BINARY:
			path = "res://Inventory/Art/Orbs/orb_binary.png"
		DataType.OPERATOR:
			path = "res://Inventory/Art/Orbs/orb_operator.png"
		DataType.RAW:
			path = "res://Inventory/Art/Orbs/orb_raw.png"
		DataType.SHORT_INT, DataType.FP8, DataType.FP16:
			path = "res://Inventory/Art/Orbs/orb_float.png"
	var tex: Texture2D = null
	if not path.is_empty() and ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	elif data_type == DataType.BINARY and ResourceLoader.exists("res://Inventory/Sprites/Item_binary.png"):
		tex = load("res://Inventory/Sprites/Item_binary.png") as Texture2D
	icon.texture = tex
	_fit_icon_rect(icon, slot_count)
	var color_rect = value_label.get_parent() if value_label and value_label.get_parent() is ColorRect else null
	if color_rect:
		if tex:
			color_rect.color = Color(0, 0, 0, 0)
		elif data_type == DataType.RAW:
			color_rect.color = Color(0.5, 0.5, 0.5, 1)
		else:
			color_rect.color = Color(0.24, 0.17, 0.08, 1)
	return tex != null


func _fit_icon_rect(icon: TextureRect, slot_count: float) -> void:
	var w_slots: float = maxf(slot_count, 0.25)
	var side: float = SLOT_PX * w_slots - ORB_SLOT_MARGIN * 2.0
	side = clampf(side, 18.0, SLOT_PX * 4.0)
	var half: float = side * 0.5
	icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	icon.offset_left = -half
	icon.offset_top = -half
	icon.offset_right = half
	icon.offset_bottom = half
	icon.custom_minimum_size = Vector2(side, side)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.z_index = 0
	if value_label:
		value_label.z_index = 1
		value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		value_label.add_theme_constant_override("outline_size", 3)


func _resize_visual(color_rect, slot_count: float) -> void:
	var side: float = clampf(SLOT_PX * maxf(slot_count, 0.25) - ORB_SLOT_MARGIN * 2.0, 18.0, SLOT_PX * 4.0)
	var half: float = side * 0.5

	if data_type == DataType.BOOLEAN or data_type == DataType.FP8:
		side = SLOT_PX * 0.5 - 4.0
		half = side * 0.5
	elif data_type == DataType.SHORT_INT or data_type == DataType.FP16:
		side = SLOT_PX * 0.5 - 4.0
		half = side * 0.5
	elif data_type == DataType.OPERATOR:
		side = SLOT_PX - ORB_SLOT_MARGIN * 2.0
		half = side * 0.5

	if color_rect and color_rect is ColorRect:
		color_rect.position = Vector2(-half, -half)
		color_rect.size = Vector2(side, side)

	if value_label:
		# Label usa anchors full-rect no ColorRect; só ajusta fonte (evita warning de layout).
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var fs: int = 14 if side < 36.0 else (16 if side < 52.0 else 20)
		value_label.add_theme_font_size_override("font_size", fs)

## Posição local para centralizar o orbe dentro do slot (pai = slot TextureRect).
func position_in_slot(slot: TextureRect) -> Vector2:
	if slot == null:
		return Vector2.ZERO
	var side: float = maxf(slot.size.x, SLOT_PX)
	var center: Vector2 = Vector2(side, side) * 0.5
	# RAW, operador ou item único: sempre centralizado no slot.
	if data_type == DataType.OPERATOR or data_type == DataType.RAW or _slot_item_count(slot) <= 1:
		return center
	var item_bytes: int = get_size_bytes() if has_method("get_size_bytes") else 4
	if item_bytes >= 4:
		return center
	var current_grid: Array = [null, null, null, null]
	var my_pos: int = 0
	for it in slot.items_stored:
		var sz: int = it.get_size_bytes() if it.has_method("get_size_bytes") else 4
		var pos_found: int = 0
		if sz >= 4:
			current_grid[0] = it
			current_grid[1] = it
			current_grid[2] = it
			current_grid[3] = it
			pos_found = 0
		elif sz == 2:
			if current_grid[0] == null and current_grid[1] == null:
				current_grid[0] = it
				current_grid[1] = it
				pos_found = 0
			elif current_grid[2] == null and current_grid[3] == null:
				current_grid[2] = it
				current_grid[3] = it
				pos_found = 2
		elif sz <= 1:
			for i in range(4):
				if current_grid[i] == null:
					current_grid[i] = it
					pos_found = i
					break
		if it == self:
			my_pos = pos_found
			break
	var quarter: float = slot.size.x * 0.25
	var offset := Vector2.ZERO
	if item_bytes <= 1:
		match my_pos:
			0: offset = Vector2(-quarter, -quarter)
			1: offset = Vector2(-quarter, quarter)
			2: offset = Vector2(quarter, -quarter)
			3: offset = Vector2(quarter, quarter)
	elif item_bytes == 2:
		offset = Vector2(-quarter, 0) if my_pos == 0 else Vector2(quarter, 0)
	return center + offset


func snap_to_slot(slot: TextureRect) -> void:
	if slot == null:
		return
	if get_parent() != slot:
		var p := get_parent()
		if p:
			p.remove_child(self)
		slot.add_child(self)
	selected = false
	var target: Vector2 = position_in_slot(slot)
	var tween := create_tween()
	tween.tween_property(self, "position", target, 0.12).set_trans(Tween.TRANS_SINE)


func _snap_to(_destination_global: Vector2) -> void:
	# Legado: inventário livre chama com global do slot; preferir snap_to_slot.
	if grid_anchor != null and grid_anchor is TextureRect:
		snap_to_slot(grid_anchor)
		return
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
		@warning_ignore("integer_division")
		temp = temp / 2
	return result

func binary_to_int(bin_str: String) -> int:
	"""Converte uma string binária para inteiro"""
	var result = 0
	for i in range(bin_str.length()):
		result = result * 2 + int(bin_str[i])
	return result

func get_size_bytes() -> int:
	"""Retorna o tamanho em bytes do item (para Fase 2 - Mochila)."""
	match data_type:
		DataType.DOUBLE:
			return 8
		DataType.FLOAT:
			return 4
		DataType.INT:
			return 4
		DataType.SHORT_INT:
			return 2
		DataType.FP16:
			return 2
		DataType.BOOLEAN:
			return 1
		DataType.FP8:
			return 1
		DataType.RAW:
			return 0
		DataType.BINARY:
			if item_ID != null and item_ID != "" and DataHandler:
				return DataHandler.get_item_bytes(item_ID)
			return int(ceil(float(binary_bits) / 8.0))
		_:
			if item_ID != null and item_ID != "" and DataHandler:
				return DataHandler.get_item_bytes(item_ID)
			return 4

func get_binary_explanation(bin_str: String) -> String:
	"""Gera texto explicando a conversão binário → decimal (ex: 10₂ = 1·2¹ + 0·2⁰ = 2)"""
	if bin_str.is_empty():
		return "-"
	var n = bin_str.length()
	var termos: PackedStringArray = []
	for i in range(n):
		var dig = bin_str[i]
		var pos = n - 1 - i
		var exp_str = "2⁰" if pos == 0 else ("2¹" if pos == 1 else "2²" if pos == 2 else "2³" if pos == 3 else "2^" + str(pos))
		termos.append(dig + "·" + exp_str)
	var formula = " + ".join(termos)
	var decimal_val = binary_to_int(bin_str)
	return bin_str + "₂ = " + formula + " = " + str(decimal_val)
