extends Node2D

@onready var value_label: Label = $ColorRect/value_label
@onready var cylinder_visual: Node2D = $CylinderVisual

# Enum para identificar o tipo de dado do orb
enum DataType {INT, FLOAT, STRING, OPERATOR, DOUBLE, BINARY, SHORT_INT, FP8, FP16, RAW}

var item_ID : String
var data_type: DataType = DataType.INT  # Tipo padrão é INT
var value : int = 0
var value_float : float = 0.0
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

var _preview_active: bool = false
var _preview_original_type: int = -1
var _preview_original_value_float: float = 0.0
var _preview_original_value: int = 0
var _preview_original_value_str: String = ""
var _preview_original_op: String = ""

## Tamanho visual de um slot na grade (deve bater com slot.gd).
const SLOT_PX := 64
const ORB_SLOT_MARGIN := 12

# Signal para notificar quando o mouse entra/sai
signal mouse_entered_item(item)
signal mouse_exited_item(item)

func _ready():
	setup_mouse_detection()

func setup_mouse_detection():
	pass

func _process(delta):
	if selected:
		global_position = lerp(global_position, get_global_mouse_position(), 25 * delta)
	
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
		var min_x = 0.0
		var min_y = 0.0
		var max_x = 0.0
		var max_y = 0.0
		if item_grids.size() > 0:
			for g in item_grids:
				if g.x < min_x: min_x = g.x
				if g.x > max_x: max_x = g.x
				if g.y < min_y: min_y = g.y
				if g.y > max_y: max_y = g.y
		return Rect2(Vector2(-half + min_x * SLOT_PX, -half + min_y * SLOT_PX), Vector2((max_x - min_x + 1.0) * SLOT_PX, (max_y - min_y + 1.0) * SLOT_PX))
	var icon: TextureRect = get_node_or_null("Icon") as TextureRect
	if icon and icon.size.x > 1.0:
		return Rect2(icon.position, icon.size)
	if value_label:
		return Rect2(value_label.position, value_label.size)
	return Rect2(Vector2(-half, -half), Vector2(SLOT_PX, SLOT_PX))

func get_item_info() -> Dictionary:
	return ItemData.get_item_info(self)

func load_item(a_ItemID: String) -> void:
	# Não usar get_node("/root/...") aqui: o item ainda pode estar fora da árvore.
	ItemData.load_item(self, a_ItemID, DataHandler)
	update_label_display()

func set_value_directly(new_value: int):
	value = new_value
	value_float = float(new_value)
	value_string = ""
	operator = ""
	data_type = DataType.INT
	item_ID = "item_number_" + str(new_value)
	update_label_display()

func set_value_by_type(new_value, tipo: DataType):
	ItemData.set_value_by_type(self, new_value, tipo)
	update_label_display()

func show_typing_preview(target_type: DataType, preview_value: float, has_warning: bool) -> void:
	if not _preview_active:
		_preview_original_type = data_type
		_preview_original_value = value
		_preview_original_value_float = value_float
		_preview_original_value_str = value_string
		_preview_original_op = operator
		_preview_active = true
	
	ItemData.set_value_by_type(self, preview_value, target_type)
	update_label_display()
	
	if has_warning:
		modulate = Color(1.0, 0.4, 0.4, 0.9)
	else:
		modulate = Color(0.6, 1.0, 0.6, 0.9)

func hide_typing_preview() -> void:
	if not _preview_active:
		return
	_preview_active = false
	var restore_val: Variant
	if _preview_original_type in [DataType.FLOAT, DataType.DOUBLE, DataType.FP8, DataType.FP16, DataType.RAW]:
		restore_val = _preview_original_value_float
	else:
		restore_val = _preview_original_value
	ItemData.set_value_by_type(self, restore_val, _preview_original_type)
	if _preview_original_type == DataType.STRING:
		ItemData.set_value_by_type(self, _preview_original_value_str, _preview_original_type)
	elif _preview_original_type == DataType.OPERATOR:
		ItemData.set_value_by_type(self, _preview_original_op, _preview_original_type)
	update_label_display()
	modulate = Color(1, 1, 1, 1)

func get_value_as_string() -> String:
	return OrbValueFormat.full_value_string(self)

func set_operator_directly(new_operator: String):
	operator = new_operator
	data_type = DataType.OPERATOR
	value = 0
	value_float = 0.0
	value_string = ""
	item_ID = "item_operator_" + new_operator
	update_label_display()

func update_label_display():
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

	if cylinder_visual == null:
		cylinder_visual = get_node_or_null("CylinderVisual") as Node2D

	var color_rect = value_label.get_parent() if value_label.get_parent() is ColorRect else null
	var icon = get_node_or_null("Icon") as TextureRect

	ItemVisuals.update_label_display(self, value_label, icon, cylinder_visual, color_rect)
	call_deferred("_ensure_centered_in_slot_parent")

func operator_display_label() -> String:
	return ItemVisuals.operator_display_label(self)

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

func shrink_orb_for_tool_slot() -> void:
	if cylinder_visual == null:
		cylinder_visual = get_node_or_null("CylinderVisual") as Node2D
	var color_rect = value_label.get_parent() if value_label else null
	ItemVisuals.shrink_orb_for_tool_slot(self, value_label, cylinder_visual, color_rect)

func restore_orb_layout() -> void:
	update_label_display()

func position_in_slot(slot: TextureRect) -> Vector2:
	if slot == null:
		return Vector2.ZERO
	var anchor: TextureRect = slot
	if grid_anchor is TextureRect:
		anchor = grid_anchor
	var side: float = maxf(anchor.size.x, SLOT_PX)
	var center: Vector2 = Vector2(side, side) * 0.5
	var span_x := 0
	for g in item_grids:
		span_x = maxi(span_x, int(g.x))
	if span_x >= 1:
		return center + Vector2(SLOT_PX * float(span_x) * 0.5, 0)
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
	if grid_anchor != null and grid_anchor is TextureRect:
		snap_to_slot(grid_anchor)
		return
	selected = false

func int_to_binary(val: int, bits: int) -> String:
	return ItemData.int_to_binary(val, bits)

func binary_to_int(bin_str: String) -> int:
	return ItemData.binary_to_int(bin_str)

func get_size_bytes() -> int:
	return ItemData.get_size_bytes(self)

func get_binary_explanation(bin_str: String) -> String:
	return ItemData.get_binary_explanation(bin_str)
