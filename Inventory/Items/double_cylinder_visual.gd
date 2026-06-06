class_name DoubleCylinderVisual
extends Control
## Cilindro horizontal (2 slots) — representação visual do tipo DOUBLE.

const RIM := Color(1.0, 0.28, 0.82, 1.0)
const RIM_GLOW := Color(1.0, 0.45, 0.9, 0.55)
const BODY := Color(0.42, 0.06, 0.32, 1.0)
const BODY_DARK := Color(0.28, 0.03, 0.22, 1.0)
const CAP := Color(0.58, 0.14, 0.46, 1.0)
const CAP_HI := Color(0.72, 0.22, 0.58, 1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 0


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 8.0 or h < 8.0:
		return
	var cap_h := clampf(h * 0.26, 5.0, h * 0.38)
	var rx := w * 0.5
	var top_c := Vector2(rx, cap_h * 0.52)
	var bot_c := Vector2(rx, h - cap_h * 0.52)
	var cap_rx := maxf(rx - 3.0, 4.0)
	var cap_ry := maxf(cap_h * 0.48, 3.0)

	# Corpo do cilindro
	var body_top := top_c.y + cap_ry * 0.35
	var body_bot := bot_c.y - cap_ry * 0.35
	draw_rect(Rect2(0, body_top, w, body_bot - body_top), BODY)
	# Sombra lateral
	draw_rect(Rect2(w * 0.78, body_top, w * 0.22, body_bot - body_top), BODY_DARK)
	# Destaque lateral
	draw_rect(Rect2(0, body_top, maxf(w * 0.08, 2.0), body_bot - body_top), CAP_HI.lightened(0.08))

	# Tampa inferior (elipse escura)
	_draw_filled_ellipse(bot_c, Vector2(cap_rx, cap_ry * 0.9), BODY_DARK)
	_draw_ellipse_outline(bot_c, Vector2(cap_rx, cap_ry * 0.9), RIM.darkened(0.15), 1.5)

	# Tampa superior (elipse clara + aro neon)
	_draw_filled_ellipse(top_c, Vector2(cap_rx, cap_ry), CAP)
	_draw_filled_ellipse(top_c, Vector2(cap_rx * 0.72, cap_ry * 0.55), CAP_HI.lightened(0.12))
	_draw_ellipse_outline(top_c, Vector2(cap_rx + 1.5, cap_ry + 1.0), RIM_GLOW, 3.0)
	_draw_ellipse_outline(top_c, Vector2(cap_rx, cap_ry), RIM, 2.0)


func _draw_filled_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	draw_colored_polygon(_ellipse_points(center, radius), color)


func _draw_ellipse_outline(center: Vector2, radius: Vector2, color: Color, width: float) -> void:
	var pts := _ellipse_points(center, radius)
	pts.append(pts[0])
	draw_polyline(pts, color, width, true)


func _ellipse_points(center: Vector2, radius: Vector2, steps: int = 36) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(steps)
	for i in range(steps):
		var a := TAU * float(i) / float(steps)
		pts[i] = center + Vector2(cos(a) * radius.x, sin(a) * radius.y)
	return pts
