class_name PanelArtLoader
extends RefCounted

const PATH_BACKPACK := "res://Inventory/Art/UI/panel_backpack.png"
const PATH_WORKBENCH := "res://Inventory/Art/UI/panel_workbench.png"


static func apply_panel_style(panel: Panel) -> void:
	if panel == null:
		return
	var tex: Texture2D = null
	if panel.name.to_lower().contains("backpack"):
		tex = _load_if_exists(PATH_BACKPACK)
	elif panel.name.to_lower().contains("bancada"):
		tex = _load_if_exists(PATH_WORKBENCH)
	if tex == null:
		return
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 24
	sb.texture_margin_top = 24
	sb.texture_margin_right = 24
	sb.texture_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", sb)


static func _load_if_exists(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
