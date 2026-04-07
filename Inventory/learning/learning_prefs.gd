extends Node
## Preferências locais (tutorial visto, etc.) em user://

const CFG_PATH := "user://learning_prefs.cfg"


func has_seen_tutorial(key: String) -> bool:
	if key.is_empty():
		return true
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return false
	return bool(cfg.get_value("tutorials", key, false))


func mark_tutorial_seen(key: String) -> void:
	if key.is_empty():
		return
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)
	cfg.set_value("tutorials", key, true)
	cfg.save(CFG_PATH)
