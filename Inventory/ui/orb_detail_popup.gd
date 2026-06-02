class_name OrbDetailPopup
extends PanelContainer

var _body: RichTextLabel
var _pinned_item: Node = null


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.09, 0.14, 0.94)
	sb.border_color = Color(0.36, 0.78, 0.91, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("panel", sb)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.custom_minimum_size = Vector2(240, 0)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)


func show_for_item(item: Node, near_global: Vector2, pin: bool = false) -> void:
	if item == null or not is_instance_valid(item):
		hide_popup()
		return
	_pinned_item = item if pin else null
	_body.text = OrbValueFormat.detail_bbcode(item)
	visible = true
	call_deferred("_place_at", near_global)


func _place_at(near_global: Vector2) -> void:
	if not visible:
		return
	var popup_size := size
	var vp := get_viewport().get_visible_rect().size
	var pos := near_global + Vector2(14, 14)
	if pos.x + popup_size.x > vp.x - 8:
		pos.x = vp.x - popup_size.x - 8
	if pos.y + popup_size.y > vp.y - 8:
		pos.y = near_global.y - popup_size.y - 10
	global_position = pos


func hide_popup(unpin: bool = true) -> void:
	if _pinned_item != null and not unpin:
		return
	_pinned_item = null
	visible = false


func is_pinned_to(item: Node) -> bool:
	return _pinned_item == item and visible


static func ensure_on(node: Node) -> OrbDetailPopup:
	var existing: Node = node.get_node_or_null("OrbDetailPopup")
	if existing is OrbDetailPopup:
		return existing
	var popup := OrbDetailPopup.new()
	popup.name = "OrbDetailPopup"
	node.add_child(popup)
	return popup
