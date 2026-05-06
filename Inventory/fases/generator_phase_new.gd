extends Control

# Nodes da UI
@onready var radio_easy = $MainVBox/DifficultyPanel/DifficultyVBox/DifficultyHBox/RadioEasy
@onready var radio_medium = $MainVBox/DifficultyPanel/DifficultyVBox/DifficultyHBox/RadioMedium
@onready var radio_hard = $MainVBox/DifficultyPanel/DifficultyVBox/DifficultyHBox/RadioHard
@onready var num_phases_spinbox = $MainVBox/ConfigPanel/ConfigVBox/NumPhasesSpinBox
@onready var binary_checkbox = $MainVBox/ConfigPanel/ConfigVBox/BinaryCheckBox
@onready var phases_list = $MainVBox/PreviewPanel/PreviewVBox/ScrollContainer/PhasesList
@onready var btn_jogar = $MainVBox/BottomRow/BtnJogar
@onready var config_vbox = $MainVBox/ConfigPanel/ConfigVBox

var converter_checkbox: CheckBox
var _pending_steps: Array = []
var _current_difficulty: String = "easy"

# Presets de dificuldade
var _presets = {
	"easy": {
		"capacity": 50,
		"backpack_slots": 6,
		"pool_slots": 15,
		"int_min": 1,
		"int_max": 10,
		"label": "Fácil"
	},
	"medium": {
		"capacity": 100,
		"backpack_slots": 8,
		"pool_slots": 20,
		"int_min": 5,
		"int_max": 50,
		"label": "Médio"
	},
	"hard": {
		"capacity": 200,
		"backpack_slots": 10,
		"pool_slots": 25,
		"int_min": 20,
		"int_max": 100,
		"label": "Difícil"
	}
}


func _ready():
	# Signals já estão conectados na cena
	converter_checkbox = CheckBox.new()
	converter_checkbox.text = "Permitir Conversor de Orbes (Int <-> Float)"
	config_vbox.add_child(converter_checkbox)
	_update_preview()


func _on_difficulty_changed(_toggled: bool):
	if radio_easy.button_pressed:
		_current_difficulty = "easy"
	elif radio_medium.button_pressed:
		_current_difficulty = "medium"
	elif radio_hard.button_pressed:
		_current_difficulty = "hard"
	
	_update_preview()


func _on_num_phases_changed(_value: float):
	_update_preview()


func _on_binary_toggled(_toggled: bool):
	_update_preview()


func _update_preview():
	# Limpa a lista de fases
	for child in phases_list.get_children():
		child.queue_free()
	
	var num_phases = int(num_phases_spinbox.value)
	var use_binary = binary_checkbox.button_pressed
	var preset = _presets[_current_difficulty]
	
	# Gera preview das fases
	for i in range(num_phases):
		var phase_label = Label.new()
		
		if use_binary and (i % 2 == 0):
			# Fase binária
			phase_label.text = "Fase %d: BINÁRIO" % (i + 1)
		else:
			# Fase mochila
			phase_label.text = "Fase %d: MOCHILA (Cap: %d | Slots: %d | Pool: %d | Val: %d-%d)" % [
				i + 1,
				preset["capacity"],
				preset["backpack_slots"],
				preset["pool_slots"],
				preset["int_min"],
				preset["int_max"]
			]
		
		phases_list.add_child(phase_label)
	
	btn_jogar.disabled = false


func _on_jogar_pressed():
	var num_phases = int(num_phases_spinbox.value)
	var use_binary = binary_checkbox.button_pressed
	var preset = _presets[_current_difficulty]
	
	var base_params = {
		"capacity": preset["capacity"],
		"backpack_slots": preset["backpack_slots"],
		"pool_slots": preset["pool_slots"],
		"grid_cols": 4,
		"int_min": preset["int_min"],
		"int_max": preset["int_max"],
		"random_pool_size": 4,
		"use_converter": converter_checkbox.button_pressed if converter_checkbox else false
	}
	
	var dh = get_node("/root/DataHandler")
	_pending_steps = dh.generate_sequence(num_phases, use_binary, base_params)
	
	if not _pending_steps.is_empty():
		PhaseRunner.begin_with_steps(_pending_steps)


func _on_voltar_pressed():
	get_tree().change_scene_to_file("res://Inventory/fases/main_menu.tscn")
