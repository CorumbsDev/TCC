class_name PanelArtLoader
extends RefCounted

const PATH_BACKPACK := "res://Inventory/Art/UI/panel_backpack.png"
const PATH_WORKBENCH := "res://Inventory/Art/UI/panel_workbench.png"


static func gray_panel_stylebox() -> StyleBoxFlat:
	return _flat_style(
		Color(0.19, 0.19, 0.21, 1),
		Color(0.30, 0.30, 0.34, 1),
		Color(0, 0, 0, 0),
		0
	)


static func backpack_panel_stylebox() -> StyleBoxFlat:
	return _flat_style(
		Color(0.10, 0.13, 0.19, 1),
		Color(0.32, 0.58, 0.92, 0.9),
		Color(0.18, 0.42, 0.78, 0.22),
		5
	)


static func workbench_panel_stylebox() -> StyleBoxFlat:
	return _flat_style(
		Color(0.14, 0.11, 0.09, 1),
		Color(0.92, 0.58, 0.22, 0.88),
		Color(0.75, 0.38, 0.08, 0.18),
		4
	)


static func challenge_panel_stylebox() -> StyleBoxFlat:
	return _flat_style(
		Color(0.09, 0.11, 0.16, 1),
		Color(0.42, 0.55, 0.88, 0.85),
		Color(0.25, 0.35, 0.7, 0.2),
		4
	)


static func _flat_style(bg: Color, border: Color, shadow: Color, shadow_sz: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_top = 10
	sb.content_margin_right = 12
	sb.content_margin_bottom = 10
	sb.shadow_color = shadow
	sb.shadow_size = shadow_sz
	sb.shadow_offset = Vector2(0, 2)
	return sb


static func apply_panel_style(panel: Panel) -> void:
	apply_phase_panel(panel)


static func apply_zone_chrome(panel: Control) -> void:
	apply_phase_panel(panel)
	panel.clip_contents = true
	var vbox := _find_content_vbox(panel)
	if vbox:
		PanelZoneHeader.install(vbox, _zone_for_panel(panel))
		vbox.add_theme_constant_override("separation", 8)


static func apply_phase_panel(panel: Control) -> void:
	if panel == null:
		return
	var name_l := panel.name.to_lower()
	var tex: Texture2D = null
	if name_l.contains("backpack"):
		tex = _load_if_exists(PATH_BACKPACK)
	elif name_l.contains("bancada"):
		tex = _load_if_exists(PATH_WORKBENCH)
	elif name_l.contains("left"):
		tex = _load_if_exists(PATH_WORKBENCH)
	elif name_l.contains("right"):
		tex = _load_if_exists(PATH_BACKPACK)
	if tex != null:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		sb.texture_margin_left = 16
		sb.texture_margin_top = 16
		sb.texture_margin_right = 16
		sb.texture_margin_bottom = 16
		panel.add_theme_stylebox_override("panel", sb)
	else:
		panel.add_theme_stylebox_override("panel", _fallback_style_for(name_l))


static func _fallback_style_for(name_l: String) -> StyleBoxFlat:
	if name_l.contains("backpack"):
		return backpack_panel_stylebox()
	if name_l.contains("bancada") or name_l.contains("left"):
		return workbench_panel_stylebox()
	if name_l.contains("right"):
		return challenge_panel_stylebox()
	return gray_panel_stylebox()


static func _zone_for_panel(panel: Control) -> String:
	var name_l := panel.name.to_lower()
	if name_l.contains("backpack"):
		return "backpack"
	if name_l.contains("bancada"):
		return "workbench"
	if name_l.contains("left"):
		return "bits_pool"
	if name_l.contains("right"):
		return "challenge"
	return "workbench"


static func _find_content_vbox(panel: Control) -> VBoxContainer:
	for child in panel.get_children():
		if child is MarginContainer:
			for sub in child.get_children():
				if sub is VBoxContainer:
					return sub as VBoxContainer
		if child is VBoxContainer:
			return child as VBoxContainer
	return null


static func _load_if_exists(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
