class_name OrbHoverBar
extends PanelContainer

const IDLE_TEXT := "Passe o mouse em um orbe para ver tipo e valor."

var _label: Label = null
var _hover_item: Node = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 58)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_apply_style()
	_label = _find_label()
	set_idle_text()


func wire_orb(item: Node) -> void:
	if item == null or not is_instance_valid(item):
		return
	if not item.has_signal("mouse_entered_item"):
		return
	if not item.mouse_entered_item.is_connected(_on_orb_entered):
		item.mouse_entered_item.connect(_on_orb_entered)
	if not item.mouse_exited_item.is_connected(_on_orb_exited):
		item.mouse_exited_item.connect(_on_orb_exited)


func wire_slot_items(slots: Array) -> void:
	for slot in slots:
		if slot == null:
			continue
		if "item_stored" in slot and slot.item_stored != null:
			wire_orb(slot.item_stored)
		if "items_stored" in slot:
			for it in slot.items_stored:
				wire_orb(it)


func show_info(item: Node) -> void:
	if _label == null:
		_label = _find_label()
	if _label == null or item == null:
		return
	var lines: PackedStringArray = OrbValueFormat.detail_lines(item)
	var line1 := lines[0] if lines.size() > 0 else "Orbe"
	var line2 := ""
	if lines.size() > 2:
		line2 = lines[1] + "  ·  " + lines[2]
	elif lines.size() > 1:
		line2 = lines[1]
	_label.text = line1 + ("\n" + line2 if not line2.is_empty() else "")


func set_idle_text() -> void:
	if _label == null:
		_label = _find_label()
	if _label:
		_label.text = IDLE_TEXT


func _on_orb_entered(item: Node) -> void:
	if _hover_item == item:
		return
	_hover_item = item
	show_info(item)


func _on_orb_exited(item: Node) -> void:
	if _hover_item != item:
		return
	_hover_item = null
	set_idle_text()


func _find_label() -> Label:
	var direct := get_node_or_null("MarginContainer/OrbHoverLabel")
	if direct is Label:
		return direct
	direct = get_node_or_null("OrbHoverLabel")
	if direct is Label:
		return direct
	for child in get_children():
		if child is MarginContainer:
			for sub in child.get_children():
				if sub is Label:
					return sub
		elif child is Label:
			return child
	return null


func _apply_style() -> void:
	apply_info_panel(self)


static func info_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.11, 0.16, 0.92)
	sb.border_color = Color(0.35, 0.55, 0.7, 0.45)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func apply_info_panel(panel: Control) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", info_stylebox())


static func apply_info_label(label: Label, font_size: int = 13) -> void:
	if label == null:
		return
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.94))
	label.add_theme_font_size_override("font_size", font_size)


static func apply_info_richtext(rt: RichTextLabel, font_size: int = 14) -> void:
	if rt == null:
		return
	rt.add_theme_color_override("default_color", Color(0.82, 0.88, 0.94))
	rt.add_theme_font_size_override("normal_font_size", font_size)


static func make_in(parent: Control, before: Node = null) -> OrbHoverBar:
	var bar := OrbHoverBar.new()
	bar.name = "OrbHoverBar"
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl := Label.new()
	lbl.name = "OrbHoverLabel"
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_info_label(lbl)
	margin.add_child(lbl)
	bar.add_child(margin)
	if before != null and before.get_parent() == parent:
		var idx := before.get_index()
		parent.add_child(bar)
		parent.move_child(bar, idx)
	else:
		parent.add_child(bar)
	return bar
