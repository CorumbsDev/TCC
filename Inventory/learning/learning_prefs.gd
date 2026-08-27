extends Node
## Preferências em memória (tutorial visto, etc.)

var _seen_tutorials: Dictionary = {}

func has_seen_tutorial(key: String) -> bool:
	if key.is_empty():
		return true
	return _seen_tutorials.has(key)

func mark_tutorial_seen(key: String) -> void:
	if key.is_empty():
		return
	_seen_tutorials[key] = true
