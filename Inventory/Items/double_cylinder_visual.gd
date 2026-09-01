class_name DoubleCylinderVisual
extends Node2D
## Cilindro (2 slots) — representação visual do tipo DOUBLE.
## Node2D (não Control): desenha de forma confiável como filho do Item.

const RIM := Color(1.0, 0.28, 0.82, 1.0)
const RIM_GLOW := Color(1.0, 0.55, 0.95, 0.7)
const BODY := Color(0.42, 0.06, 0.32, 0.92)
const BODY_DARK := Color(0.28, 0.03, 0.22, 1.0)
const CAP := Color(0.72, 0.18, 0.55, 1.0)
const CAP_HI := Color(0.95, 0.4, 0.85, 1.0)

var draw_size: Vector2 = Vector2(116, 40)


func _ready() -> void:
	z_index = 0
	queue_redraw()


func set_draw_size(new_size: Vector2) -> void:
	draw_size = new_size
	queue_redraw()


func _draw() -> void:
	var w := draw_size.x
	var h := draw_size.y
	if w < 8.0 or h < 8.0:
		return
	# Origem no centro do Item (como os outros orbs).
	var origin := -draw_size * 0.5
	var cap_h := clampf(h * 0.28, 6.0, h * 0.4)
	var rx := w * 0.5
	var top_c := origin + Vector2(rx, cap_h * 0.55)
	var bot_c := origin + Vector2(rx, h - cap_h * 0.55)
	var cap_rx := maxf(rx - 4.0, 6.0)
	var cap_ry := maxf(cap_h * 0.5, 4.0)

	var body_top := top_c.y + cap_ry * 0.25
	var body_bot := bot_c.y - cap_ry * 0.25
	draw_rect(Rect2(origin.x, body_top, w, body_bot - body_top), BODY)
	draw_rect(Rect2(origin.x + w * 0.78, body_top, w * 0.22, body_bot - body_top), BODY_DARK)
	draw_rect(Rect2(origin.x, body_top, maxf(w * 0.08, 2.0), body_bot - body_top), CAP_HI.lightened(0.05))

	# Tampa inferior
	_draw_filled_ellipse(bot_c, Vector2(cap_rx, cap_ry * 0.9), BODY_DARK)
	_draw_ellipse_outline(bot_c, Vector2(cap_rx, cap_ry * 0.9), RIM.darkened(0.1), 2.0)

	# Tampa superior (anel neon — o “estilo” do double)
	_draw_filled_ellipse(top_c, Vector2(cap_rx, cap_ry), CAP)
	_draw_filled_ellipse(top_c, Vector2(cap_rx * 0.7, cap_ry * 0.5), CAP_HI.lightened(0.15))
	_draw_ellipse_outline(top_c, Vector2(cap_rx + 2.0, cap_ry + 1.5), RIM_GLOW, 4.0)
	_draw_ellipse_outline(top_c, Vector2(cap_rx, cap_ry), RIM, 2.5)
	# Aro inferior também com glow leve (parece o anel do conversor)
	_draw_ellipse_outline(bot_c, Vector2(cap_rx + 1.0, cap_ry * 0.9 + 1.0), RIM_GLOW.darkened(0.15), 2.5)


func _draw_filled_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	draw_colored_polygon(_ellipse_points(center, radius), color)


func _draw_ellipse_outline(center: Vector2, radius: Vector2, color: Color, width: float) -> void:
	var pts := _ellipse_points(center, radius)
	pts.append(pts[0])
	draw_polyline(pts, color, width, true)


func _ellipse_points(center: Vector2, radius: Vector2, steps: int = 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(steps)
	for i in range(steps):
		var a := TAU * float(i) / float(steps)
		pts[i] = center + Vector2(cos(a) * radius.x, sin(a) * radius.y)
	return pts
