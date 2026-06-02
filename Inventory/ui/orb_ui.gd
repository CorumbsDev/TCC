extends Node

## Autoload: popup de valor exato para qualquer cena com orbes.

var _popup: OrbDetailPopup = null
var _host: Node = null


func _ready() -> void:
	pass


func _get_popup() -> OrbDetailPopup:
	if _popup != null and is_instance_valid(_popup):
		return _popup
	var root := get_tree().current_scene
	if root == null:
		return null
	_host = root
	_popup = OrbDetailPopup.ensure_on(root)
	return _popup


func show_detail(item: Node, global_pos: Vector2, pin: bool = false) -> void:
	var p := _get_popup()
	if p:
		p.show_for_item(item, global_pos, pin)


func hide_detail(force: bool = false) -> void:
	if _popup and is_instance_valid(_popup):
		_popup.hide_popup(force)
