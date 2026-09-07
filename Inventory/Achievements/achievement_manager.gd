extends Node

signal achievement_unlocked(id: String)
signal achievement_progressed(id: String, current: int, max_val: int)

const SAVE_PATH = "user://achievements.json"

var _achievements = {
	"first_type_phase": {
		"name": "Tipador Iniciante",
		"desc": "Passou da sua primeira fase de tipagem.",
		"icon": "res://icon.svg",
		"max_progress": 1,
		"current_progress": 0,
		"unlocked": false
	},
	"int_master": {
		"name": "Mestre dos Inteiros",
		"desc": "Passou de 5 fases contendo itens INT.",
		"icon": "res://icon.svg",
		"max_progress": 5,
		"current_progress": 0,
		"unlocked": false
	},
	"binary_basics": {
		"name": "O Despertar do Binário",
		"desc": "Completou uma fase de representação binária.",
		"icon": "res://icon.svg",
		"max_progress": 1,
		"current_progress": 0,
		"unlocked": false
	},
	"conversion_expert": {
		"name": "Transmutador de Tipos",
		"desc": "Completou uma fase de conversão de tipos (Cast).",
		"icon": "res://icon.svg",
		"max_progress": 1,
		"current_progress": 0,
		"unlocked": false
	},
	"backpack_explorer": {
		"name": "Mochileiro da Memória",
		"desc": "Encheu a memória com itens em uma fase clássica.",
		"icon": "res://icon.svg",
		"max_progress": 1,
		"current_progress": 0,
		"unlocked": false
	},
	"float_master": {
		"name": "Mestre Flutuante",
		"desc": "Passou de 5 fases contendo itens FLOAT.",
		"icon": "res://icon.svg",
		"max_progress": 5,
		"current_progress": 0,
		"unlocked": false
	},
	"primitive_collector": {
		"name": "Colecionador de Primitivos",
		"desc": "Utilizou INT, FLOAT e DOUBLE em suas jornadas.",
		"icon": "res://icon.svg",
		"max_progress": 3,
		"current_progress": 0,
		"unlocked": false,
		"flags": []
	},
	"star_collector": {
		"name": "Mochila Perfeita",
		"desc": "Completou uma fase de mochila ou bruta com 3 estrelas (eficiência máxima).",
		"icon": "res://icon.svg",
		"max_progress": 1,
		"current_progress": 0,
		"unlocked": false
	}
}

func _ready() -> void:
	_load_data()

func get_all_achievements() -> Dictionary:
	return _achievements

func add_progress(id: String, amount: int = 1) -> void:
	if not _achievements.has(id):
		return
		
	var ach = _achievements[id]
	if ach["unlocked"]:
		return
		
	ach["current_progress"] += amount
	
	if ach["current_progress"] >= ach["max_progress"]:
		ach["current_progress"] = ach["max_progress"]
		_unlock_internal(id)
	else:
		achievement_progressed.emit(id, ach["current_progress"], ach["max_progress"])
		_save_data()

func add_unique_progress(id: String, flag: String) -> void:
	if not _achievements.has(id):
		return
	var ach = _achievements[id]
	if ach["unlocked"]:
		return
	if not ach.has("flags"):
		ach["flags"] = []
	if not flag in ach["flags"]:
		ach["flags"].append(flag)
		add_progress(id, 1)

func unlock(id: String) -> void:
	if not _achievements.has(id):
		return
		
	var ach = _achievements[id]
	if ach["unlocked"]:
		return
		
	ach["current_progress"] = ach["max_progress"]
	_unlock_internal(id)

func reset_achievements() -> void:
	for id in _achievements:
		_achievements[id]["current_progress"] = 0
		_achievements[id]["unlocked"] = false
		if _achievements[id].has("flags"):
			_achievements[id]["flags"].clear()
	_save_data()

func _unlock_internal(id: String) -> void:
	var ach = _achievements[id]
	ach["unlocked"] = true
	achievement_unlocked.emit(id)
	_save_data()

func _save_data() -> void:
	var save_dict = {}
	for id in _achievements:
		save_dict[id] = {
			"current_progress": _achievements[id]["current_progress"],
			"unlocked": _achievements[id]["unlocked"]
		}
		if _achievements[id].has("flags"):
			save_dict[id]["flags"] = _achievements[id]["flags"]
	
	var json_string = JSON.stringify(save_dict)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)

func _load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var parsed = JSON.parse_string(json_string)
		if typeof(parsed) == TYPE_DICTIONARY:
			for id in parsed:
				if _achievements.has(id):
					var data = parsed[id]
					if data.has("current_progress"):
						_achievements[id]["current_progress"] = data["current_progress"]
					if data.has("unlocked"):
						_achievements[id]["unlocked"] = data["unlocked"]
					if data.has("flags") and _achievements[id].has("flags"):
						_achievements[id]["flags"] = data["flags"]
