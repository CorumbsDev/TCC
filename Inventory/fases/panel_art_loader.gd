class_name PanelArtLoader
extends RefCounted

const PATH_BACKPACK := "res://Inventory/Art/UI/panel_backpack.png"
const PATH_WORKBENCH := "res://Inventory/Art/UI/bancada.png"
const PATH_BACKGROUND := "res://Inventory/Art/UI/backgorund.png"
const PATH_MENU_BACKGROUND := "res://Inventory/Art/UI/backgorund_tela_inicial.jpeg"


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
	sb.content_margin_left = 16
	sb.content_margin_top = 12
	sb.content_margin_right = 16
	sb.content_margin_bottom = 14
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
		# PanelZoneHeader.install(vbox, _zone_for_panel(panel)) # Removed per user request
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
	var res = load(path)
	if res is Texture2D:
		return res
	return null


static func apply_button_style(btn: Button) -> void:
	if btn == null: return
	var tex = _load_if_exists("res://Inventory/Art/UI/botao_1.png")
	if tex == null: return
	
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 6
	sb.texture_margin_top = 6
	sb.texture_margin_right = 6
	sb.texture_margin_bottom = 6
	
	var sb_hover = sb.duplicate()
	sb_hover.modulate_color = Color(1.1, 1.1, 1.1)
	
	var sb_pressed = sb.duplicate()
	sb_pressed.modulate_color = Color(0.9, 0.9, 0.9)
	
	var sb_disabled = sb.duplicate()
	sb_disabled.modulate_color = Color(0.5, 0.5, 0.5, 0.8)
	
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.72, 0.72, 0.72, 0.9))
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 1)


static func skin_all_buttons(root: Node) -> void:
	if root is Button and not root is OptionButton:
		apply_button_style(root)
	
	for i in range(root.get_child_count()):
		skin_all_buttons(root.get_child(i))

static func apply_background(root: Node, custom_path: String = "") -> void:
	if not root is Control:
		return
	var path_to_load = custom_path if custom_path != "" else PATH_BACKGROUND
	var tex = _load_if_exists(path_to_load)
	if not tex:
		return
	var existing_bg = root.get_node_or_null("Background")
	if existing_bg is ColorRect:
		existing_bg.color = Color(0, 0, 0, 0)
	elif existing_bg is Panel:
		var empty_sb = StyleBoxEmpty.new()
		existing_bg.add_theme_stylebox_override("panel", empty_sb)

	if root.has_node("DynamicBackgroundArt"):
		return
		
	var bg = TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.name = "DynamicBackgroundArt"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	root.add_child(bg)
	root.move_child(bg, 0)
