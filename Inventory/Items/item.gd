extends Node2D

@onready var value_label: Label = $ColorRect/value_label
@onready var cylinder_visual: Control = $CylinderVisual

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
			info.detalhes = "Valor double: " + full_val + "\nOcupa 2 slots lado a lado (8 bytes)"
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
	
	match data_type:
		DataType.OPERATOR:
			value_label.add_theme_color_override("font_color", Color(1, 0.85, 0.35, 1))
			value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		DataType.INT:
			value_label.add_theme_color_override("font_color", Color.BLUE)
		DataType.FLOAT:
			value_label.add_theme_color_override("font_color", Color.RED)
		DataType.BOOLEAN:
			value_label.add_theme_color_override("font_color", Color.GREEN)
		DataType.STRING:
			value_label.add_theme_color_override("font_color", Color.YELLOW)
		DataType.DOUBLE:
			value_label.add_theme_color_override("font_color", Color.MAGENTA)
		DataType.BINARY:
			value_label.add_theme_color_override("font_color", Color.LIME)
		DataType.SHORT_INT:
			value_label.add_theme_color_override("font_color", Color.CYAN)
		DataType.FP8:
			value_label.add_theme_color_override("font_color", Color.VIOLET)
		DataType.FP16:
			value_label.add_theme_color_override("font_color", Color.GOLD)
		DataType.RAW:
			value_label.add_theme_color_override("font_color", Color.WHITE)
		_:
			value_label.add_theme_color_override("font_color", Color.BLACK)
	if data_type == DataType.OPERATOR:
		value_label.text = operator_display_label()
	elif data_type == DataType.BINARY:
		value_label.text = value_binary
	else:
		value_label.text = OrbValueFormat.compact_label_string(self)
	var dims := _compute_orb_dimensions(value_label.text)
	var has_orb_art := false
	_resize_visual(color_rect, dims)
	has_orb_art = _apply_orb_sprite(dims)
	_apply_label_fit()
	if has_orb_art and value_label:
		value_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
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

func _base_type_slot_scale() -> float:
	match data_type:
		DataType.BOOLEAN, DataType.FP8:
			return 0.25
		DataType.SHORT_INT, DataType.FP16:
			return 0.5
		DataType.DOUBLE:
			return 2.0
		_:
			return 1.0


func shrink_orb_for_tool_slot() -> void:
	if data_type != DataType.DOUBLE:
		return
	var dims := Vector2(SLOT_PX - ORB_SLOT_MARGIN * 2.0, SLOT_PX - ORB_SLOT_MARGIN * 2.0)
	var color_rect = value_label.get_parent() if value_label else null
	if color_rect:
		_resize_visual(color_rect, dims)
		_apply_double_cylinder(dims)
		_apply_label_fit()


func restore_orb_layout() -> void:
	update_label_display()


func _compute_orb_dimensions(text: String) -> Vector2:
	if data_type == DataType.DOUBLE:
		return _double_capsule_size()
	var char_count := maxi(text.length(), 1)
	var base_scale := _base_type_slot_scale()
	var max_side := SLOT_PX - ORB_SLOT_MARGIN * 2.0
	var max_w := SLOT_PX - 4.0
	var visual_scale := base_scale
	if char_count >= 7:
		visual_scale = 1.0
	elif char_count >= 5:
		visual_scale = maxf(base_scale, 0.75)
	elif char_count >= 4:
		visual_scale = maxf(base_scale, 0.55)
	var side := clampf(SLOT_PX * visual_scale - ORB_SLOT_MARGIN * 2.0, 22.0, max_side)
	if char_count >= 6:
		var width := clampf(char_count * 6.8 + 6.0, side, max_w)
		var height := clampf(side, 24.0, max_side)
		return Vector2(width, height)
	return Vector2(side, side)


func _apply_orb_sprite(dims: Vector2 = Vector2.ZERO) -> bool:
	if dims == Vector2.ZERO:
		dims = _compute_orb_dimensions(value_label.text if value_label else "")
	if data_type == DataType.DOUBLE:
		return _apply_double_cylinder(dims)
	var icon: TextureRect = get_node_or_null("Icon") as TextureRect
	if icon == null:
		return false
	if cylinder_visual:
		cylinder_visual.visible = false
	icon.visible = true
	var path := ""
	match data_type:
		DataType.INT:
			path = "res://Inventory/Art/Orbs/orb_int.png"
		DataType.FLOAT:
			path = "res://Inventory/Art/Orbs/orb_float.png"
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
	_fit_visual_rect(icon, dims)
	var color_rect = value_label.get_parent() if value_label and value_label.get_parent() is ColorRect else null
	if color_rect:
		if tex:
			color_rect.color = Color(0, 0, 0, 0)
		elif data_type == DataType.RAW:
			color_rect.color = Color(0.5, 0.5, 0.5, 1)
		else:
			color_rect.color = Color(0.24, 0.17, 0.08, 1)
	return tex != null


func _apply_double_cylinder(dims: Vector2) -> bool:
	var icon: TextureRect = get_node_or_null("Icon") as TextureRect
	if icon:
		icon.visible = false
		icon.texture = null
	if cylinder_visual == null:
		return false
	cylinder_visual.visible = true
	_fit_visual_rect(cylinder_visual, dims)
	cylinder_visual.queue_redraw()
	var color_rect = value_label.get_parent() if value_label and value_label.get_parent() is ColorRect else null
	if color_rect:
		color_rect.color = Color(0, 0, 0, 0)
	if value_label:
		value_label.z_index = 2
		value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	return true


func _double_capsule_size() -> Vector2:
	var width := SLOT_PX * 2.0 - ORB_SLOT_MARGIN
	var height := SLOT_PX - ORB_SLOT_MARGIN * 2.0
	return Vector2(width, height)


func _fit_visual_rect(node: Control, dims: Vector2) -> void:
	var width := clampf(dims.x, 18.0, SLOT_PX * 4.0)
	var height := clampf(dims.y, 18.0, SLOT_PX * 2.0)
	var half_w: float = width * 0.5
	var half_h: float = height * 0.5
	node.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	node.offset_left = -half_w
	node.offset_top = -half_h
	node.offset_right = half_w
	node.offset_bottom = half_h
	node.custom_minimum_size = Vector2(width, height)
	if node is TextureRect:
		var icon := node as TextureRect
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		var wide := width > height * 1.12
		icon.stretch_mode = TextureRect.STRETCH_SCALE if wide else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.z_index = 0
	if value_label and data_type != DataType.DOUBLE:
		value_label.z_index = 1
		value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))


func _orb_label_fit_size() -> Vector2:
	var cr = value_label.get_parent() if value_label else null
	if cr is ColorRect and cr.size.x > 1.0:
		return cr.size
	var fallback := SLOT_PX - ORB_SLOT_MARGIN * 2.0
	return Vector2(fallback, fallback)


func _orb_font_size(text: String, width: float, height: float) -> int:
	var char_count := maxi(text.length(), 1)
	var short_side := minf(width, height)
	var base: int = 15 if short_side < 34.0 else (17 if short_side < 46.0 else 18)
	if char_count <= 3:
		return base
	var by_width := int(width * 0.9 / (char_count * 0.5))
	var by_height := int(height * 0.72)
	return clampi(mini(by_width, by_height), 10, base)


func _apply_label_fit() -> void:
	if not value_label:
		return
	var dims := _orb_label_fit_size()
	var fs: int
	if data_type == DataType.OPERATOR:
		fs = 22 if operator.length() <= 2 else 13
		fs = mini(fs, _orb_font_size(value_label.text, dims.x, dims.y))
	else:
		fs = _orb_font_size(value_label.text, dims.x, dims.y)
	value_label.add_theme_font_size_override("font_size", fs)
	var outline: int = 2 if fs <= 12 else 3
	value_label.add_theme_constant_override("outline_size", outline)


func _resize_visual(color_rect, dims: Vector2) -> void:
	var width := dims.x
	var height := dims.y
	if color_rect and color_rect is ColorRect:
		color_rect.position = Vector2(-width * 0.5, -height * 0.5)
		color_rect.size = Vector2(width, height)

	if value_label:
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _double_spans_two_slots(anchor: TextureRect) -> bool:
	if anchor == null or item_grids.size() < 2:
		return false
	var spans_right := false
	for g in item_grids:
		if int(g.x) >= 1:
			spans_right = true
			break
	if not spans_right:
		return false
	var grid_parent := anchor.get_parent()
	if grid_parent == null:
		return false
	for sibling in grid_parent.get_children():
		if sibling == anchor or not (sibling is TextureRect):
			continue
		if int(sibling.slot_ID) == anchor.slot_ID + 1 and self in sibling.items_stored:
			return true
	return false


## Posição local para centralizar o orbe dentro do slot (pai = slot TextureRect).
func position_in_slot(slot: TextureRect) -> Vector2:
	if slot == null:
		return Vector2.ZERO
	var anchor: TextureRect = slot
	if grid_anchor is TextureRect:
		anchor = grid_anchor
	var side: float = maxf(anchor.size.x, SLOT_PX)
	var center: Vector2 = Vector2(side, side) * 0.5
	# DOUBLE na grade: cápsula centrada entre dois slots horizontais (8 bytes).
	if data_type == DataType.DOUBLE and _double_spans_two_slots(anchor):
		return center + Vector2(SLOT_PX * 0.5, 0)
	# RAW, operador ou item único: sempre centralizado no slot.
	if data_type == DataType.OPERATOR or data_type == DataType.RAW or _slot_item_count(anchor) <= 1:
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
