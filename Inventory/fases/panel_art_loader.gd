class_name PanelArtLoader
extends RefCounted

const PATH_BACKPACK := "res://Inventory/Art/UI/panel_backpack.png"
const PATH_WORKBENCH := "res://Inventory/Art/UI/panel_workbench.png"


static func gray_panel_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.19, 0.19, 0.21, 1)
	sb.border_color = Color(0.30, 0.30, 0.34, 1)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_top = 10
	sb.content_margin_right = 10
	sb.content_margin_bottom = 10
	return sb


static func apply_panel_style(panel: Panel) -> void:
	apply_phase_panel(panel)


static func apply_phase_panel(panel: Control) -> void:
	if panel == null:
		return
	var tex: Texture2D = null
	var name_l := panel.name.to_lower()
	if name_l.contains("backpack") or name_l.contains("left"):
		tex = _load_if_exists(PATH_BACKPACK)
	elif name_l.contains("bancada") or name_l.contains("right"):
		tex = _load_if_exists(PATH_WORKBENCH)
	if tex != null:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		sb.texture_margin_left = 16
		sb.texture_margin_top = 16
		sb.texture_margin_right = 16
		sb.texture_margin_bottom = 16
		panel.add_theme_stylebox_override("panel", sb)
	else:
		panel.add_theme_stylebox_override("panel", gray_panel_stylebox())


static func _load_if_exists(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
