class_name PanelZoneHeader
extends HBoxContainer
## Cabeçalho gamificado (ícone + título) para mochila, bancada e fases binárias.

const ICON_SIZE := 28


static func install(parent: VBoxContainer, zone: String) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if parent.get_node_or_null("ZoneHeader"):
		return
	var header := PanelZoneHeader.new()
	header.name = "ZoneHeader"
	header._build(zone)
	parent.add_child(header)
	parent.move_child(header, 0)


func _build(zone: String) -> void:
	add_theme_constant_override("separation", 10)
	custom_minimum_size.y = 36
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon := _Icon.new()
	icon.zone = zone
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	add_child(icon)
	var title := Label.new()
	title.text = _title_for(zone)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", _accent_for(zone))
	add_child(title)


static func _title_for(zone: String) -> String:
	match zone:
		"backpack":
			return "Mochila — memória"
		"workbench":
			return "Bancada — pool"
		"bits_pool":
			return "Pool de bits"
		"challenge":
			return "Área do desafio"
		_:
			return "Zona"


static func _accent_for(zone: String) -> Color:
	match zone:
		"backpack":
			return Color(0.55, 0.78, 1.0, 1)
		"workbench":
			return Color(1.0, 0.72, 0.38, 1)
		"bits_pool":
			return Color(0.65, 0.9, 0.75, 1)
		"challenge":
			return Color(0.75, 0.82, 1.0, 1)
		_:
			return Color(0.85, 0.88, 0.92, 1)


class _Icon extends Control:
	var zone := "backpack"

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := minf(size.x, size.y)
		if s < 8.0:
			return
		match zone:
			"backpack":
				_draw_backpack(s)
			"workbench":
				_draw_workbench(s)
			"bits_pool":
				_draw_bits(s)
			"challenge":
				_draw_target(s)
			_:
				_draw_workbench(s)

	func _draw_backpack(side: float) -> void:
		var body := Rect2(side * 0.18, side * 0.28, side * 0.64, side * 0.58)
		draw_rect(body, Color(0.22, 0.38, 0.62, 1))
		draw_rect(body, Color(0.45, 0.72, 1.0, 0.95), false, 2.0)
		var flap := Rect2(side * 0.22, side * 0.18, side * 0.56, side * 0.16)
		draw_rect(flap, Color(0.28, 0.48, 0.78, 1))
		draw_arc(Vector2(side * 0.5, side * 0.16), side * 0.12, PI, 0.0, 16, Color(0.5, 0.75, 1.0, 1), 2.0)
		draw_rect(Rect2(side * 0.44, side * 0.48, side * 0.12, side * 0.14), Color(0.15, 0.22, 0.35, 1))

	func _draw_workbench(side: float) -> void:
		var top := Rect2(side * 0.08, side * 0.22, side * 0.84, side * 0.18)
		draw_rect(top, Color(0.45, 0.32, 0.18, 1))
		draw_rect(top, Color(1.0, 0.68, 0.28, 0.95), false, 2.0)
		draw_rect(Rect2(side * 0.14, side * 0.40, side * 0.1, side * 0.42), Color(0.35, 0.25, 0.15, 1))
		draw_rect(Rect2(side * 0.76, side * 0.40, side * 0.1, side * 0.42), Color(0.35, 0.25, 0.15, 1))
		draw_circle(Vector2(side * 0.72, side * 0.3), side * 0.05, Color(1.0, 0.82, 0.35, 0.9))

	func _draw_bits(side: float) -> void:
		for i in 3:
			var cx := side * (0.25 + float(i) * 0.25)
			var bit_on := i % 2 == 1
			var fill := Color(0.55, 0.95, 0.72, 0.95) if bit_on else Color(0.18, 0.42, 0.32, 1)
			draw_circle(Vector2(cx, side * 0.5), side * 0.14, fill)
			draw_circle(Vector2(cx, side * 0.5), side * 0.14, Color(0.55, 0.95, 0.72, 0.9), false, 2.0)

	func _draw_target(side: float) -> void:
		draw_arc(Vector2(side * 0.5, side * 0.5), side * 0.34, 0, TAU, 24, Color(0.45, 0.58, 0.95, 0.85), 2.0)
		draw_arc(Vector2(side * 0.5, side * 0.5), side * 0.22, 0, TAU, 20, Color(0.55, 0.68, 1.0, 0.75), 2.0)
		draw_line(Vector2(side * 0.5, side * 0.12), Vector2(side * 0.5, side * 0.88), Color(0.7, 0.8, 1.0, 0.5), 1.5)
		draw_line(Vector2(side * 0.12, side * 0.5), Vector2(side * 0.88, side * 0.5), Color(0.7, 0.8, 1.0, 0.5), 1.5)
