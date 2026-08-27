class_name ItemVisuals
extends RefCounted

const SLOT_PX := 64
const ORB_SLOT_MARGIN := 12

static func update_label_display(item, value_label: Label, icon: TextureRect, cylinder_visual: Control, color_rect: ColorRect) -> void:
	if not value_label:
		return
	
	value_label.visible = true
	
	if color_rect:
		if item.data_type == item.DataType.RAW:
			color_rect.color = Color(0.5, 0.5, 0.5, 1)
		else:
			color_rect.color = Color(0.24, 0.17, 0.08, 1)
		color_rect.z_index = -1
	
	match item.data_type:
		item.DataType.OPERATOR:
			value_label.add_theme_color_override("font_color", Color(1, 0.85, 0.35, 1))
			value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.DataType.INT:
			value_label.add_theme_color_override("font_color", Color.BLUE)
		item.DataType.FLOAT:
			value_label.add_theme_color_override("font_color", Color.RED)
		item.DataType.STRING:
			value_label.add_theme_color_override("font_color", Color.YELLOW)
		item.DataType.DOUBLE:
			value_label.add_theme_color_override("font_color", Color.MAGENTA)
		item.DataType.BINARY:
			value_label.add_theme_color_override("font_color", Color.LIME)
		item.DataType.SHORT_INT:
			value_label.add_theme_color_override("font_color", Color.CYAN)
		item.DataType.FP8:
			value_label.add_theme_color_override("font_color", Color.VIOLET)
		item.DataType.FP16:
			value_label.add_theme_color_override("font_color", Color.GOLD)
		item.DataType.RAW:
			value_label.add_theme_color_override("font_color", Color.WHITE)
		_:
			value_label.add_theme_color_override("font_color", Color.BLACK)
			
	if item.data_type == item.DataType.OPERATOR:
		value_label.text = operator_display_label(item)
	elif item.data_type == item.DataType.BINARY:
		value_label.text = item.value_binary
	else:
		value_label.text = OrbValueFormat.compact_label_string(item)
		
	var dims := _compute_orb_dimensions(item, value_label.text)
	var has_orb_art := false
	_resize_visual(item, color_rect, dims, value_label)
	has_orb_art = _apply_orb_sprite(item, dims, icon, cylinder_visual, color_rect, value_label)
	_apply_label_fit(item, value_label)
	
	if has_orb_art and value_label:
		value_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		
	if OrbValueFormat.should_compact(item):
		value_label.tooltip_text = "Valor exato: " + OrbValueFormat.full_value_string(item)
	else:
		value_label.tooltip_text = ""
		
	if item.data_type == item.DataType.OPERATOR:
		value_label.tooltip_text = "Operador: " + item.operator
		
	value_label.queue_redraw()

static func operator_display_label(item) -> String:
	match item.operator:
		"+": return "+"
		"++": return "++"
		"to_int": return "int"
		"to_float": return "flt"
		"to_short": return "sh"
	if item.operator.begins_with("to_") and item.operator.length() > 3:
		return item.operator.substr(3)
	if item.operator.length() <= 5:
		return item.operator
	return item.operator.substr(0, 5)

static func shrink_orb_for_tool_slot(item, value_label: Label, cylinder_visual: Control, color_rect: ColorRect) -> void:
	if item.data_type != item.DataType.DOUBLE:
		return
	var dims := Vector2(SLOT_PX - ORB_SLOT_MARGIN * 2.0, SLOT_PX - ORB_SLOT_MARGIN * 2.0)
	if color_rect:
		_resize_visual(item, color_rect, dims, value_label)
		_apply_double_cylinder(item, dims, null, cylinder_visual, color_rect, value_label)
		_apply_label_fit(item, value_label)

static func _compute_orb_dimensions(item, text: String) -> Vector2:
	if item.data_type == item.DataType.DOUBLE:
		return _double_capsule_size()
	var char_count := maxi(text.length(), 1)
	var base_scale := _base_type_slot_scale(item)
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

static func _base_type_slot_scale(item) -> float:
	match item.data_type:
		item.DataType.FP8:
			return 0.25
		item.DataType.SHORT_INT, item.DataType.FP16:
			return 0.5
		item.DataType.DOUBLE:
			return 2.0
		_:
			return 1.0

static func _apply_orb_sprite(item, dims: Vector2, icon: TextureRect, cylinder_visual: Control, color_rect: ColorRect, value_label: Label) -> bool:
	if dims == Vector2.ZERO:
		dims = _compute_orb_dimensions(item, value_label.text if value_label else "")
	if item.data_type == item.DataType.DOUBLE:
		return _apply_double_cylinder(item, dims, icon, cylinder_visual, color_rect, value_label)
	if icon == null:
		return false
	if cylinder_visual:
		cylinder_visual.visible = false
	icon.visible = true
	var path := ""
	match item.data_type:
		item.DataType.INT:
			path = "res://Inventory/Art/Orbs/orb_int.png"
		item.DataType.FLOAT:
			path = "res://Inventory/Art/Orbs/orb_float.png"
		item.DataType.BINARY:
			path = "res://Inventory/Art/Orbs/orb_binary.png"
		item.DataType.OPERATOR:
			path = "res://Inventory/Art/Orbs/orb_operator.png"
		item.DataType.RAW:
			path = "res://Inventory/Art/Orbs/orb_raw.png"
		item.DataType.SHORT_INT:
			path = "res://Inventory/Art/Orbs/orb_int.png"
		item.DataType.FP8, item.DataType.FP16:
			path = "res://Inventory/Art/Orbs/orb_float.png"
	var tex: Texture2D = null
	if not path.is_empty() and ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	elif item.data_type == item.DataType.BINARY and ResourceLoader.exists("res://Inventory/Sprites/Item_binary.png"):
		tex = load("res://Inventory/Sprites/Item_binary.png") as Texture2D
	icon.texture = tex
	_fit_visual_rect(item, icon, dims, value_label)
	
	if color_rect:
		if tex:
			color_rect.color = Color(0, 0, 0, 0)
		elif item.data_type == item.DataType.RAW:
			color_rect.color = Color(0.5, 0.5, 0.5, 1)
		else:
			color_rect.color = Color(0.24, 0.17, 0.08, 1)
	return tex != null

static func _apply_double_cylinder(item, dims: Vector2, icon: TextureRect, cylinder_visual: Control, color_rect: ColorRect, value_label: Label) -> bool:
	if icon:
		icon.visible = false
		icon.texture = null
	if cylinder_visual == null:
		return false
	cylinder_visual.visible = true
	_fit_visual_rect(item, cylinder_visual, dims, value_label)
	cylinder_visual.queue_redraw()
	if color_rect:
		color_rect.color = Color(0, 0, 0, 0)
	if value_label:
		value_label.z_index = 2
		value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	return true

static func _double_capsule_size() -> Vector2:
	var width := SLOT_PX * 2.0 - ORB_SLOT_MARGIN
	var height := SLOT_PX - ORB_SLOT_MARGIN * 2.0
	return Vector2(width, height)

static func _fit_visual_rect(item, node: Control, dims: Vector2, value_label: Label) -> void:
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
	if value_label and item.data_type != item.DataType.DOUBLE:
		value_label.z_index = 1
		value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))

static func _orb_label_fit_size(value_label: Label) -> Vector2:
	var cr = value_label.get_parent() if value_label else null
	if cr is ColorRect and cr.size.x > 1.0:
		return cr.size
	var fallback := SLOT_PX - ORB_SLOT_MARGIN * 2.0
	return Vector2(fallback, fallback)

static func _orb_font_size(text: String, width: float, height: float) -> int:
	var char_count := maxi(text.length(), 1)
	var short_side := minf(width, height)
	var base: int = 15 if short_side < 34.0 else (17 if short_side < 46.0 else 18)
	if char_count <= 3:
		return base
	var by_width := int(width * 0.9 / (char_count * 0.5))
	var by_height := int(height * 0.72)
	return clampi(mini(by_width, by_height), 10, base)

static func _apply_label_fit(item, value_label: Label) -> void:
	if not value_label:
		return
	var dims := _orb_label_fit_size(value_label)
	var fs: int
	if item.data_type == item.DataType.OPERATOR:
		fs = 22 if item.operator.length() <= 2 else 13
		fs = mini(fs, _orb_font_size(value_label.text, dims.x, dims.y))
	else:
		fs = _orb_font_size(value_label.text, dims.x, dims.y)
	value_label.add_theme_font_size_override("font_size", fs)
	var outline: int = 2 if fs <= 12 else 3
	value_label.add_theme_constant_override("outline_size", outline)

static func _resize_visual(_item, color_rect, dims: Vector2, value_label: Label) -> void:
	var width := dims.x
	var height := dims.y
	if color_rect and color_rect is ColorRect:
		color_rect.position = Vector2(-width * 0.5, -height * 0.5)
		color_rect.size = Vector2(width, height)

	if value_label:
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
