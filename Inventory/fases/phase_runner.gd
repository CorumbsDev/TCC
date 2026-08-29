extends Node

const PATH_PHASE2 := "res://Inventory/fases/phase2.tscn"
const PATH_BINARY := "res://Inventory/fases/binary_phase.tscn"
const PATH_TYPE_BOX := "res://Inventory/fases/type_box_phase.tscn"
const PATH_RAW_MOCHILA := "res://Inventory/fases/raw_knapsack_phase.tscn"
const PATH_MENU := "res://Inventory/fases/main_menu.tscn"

signal phase_advance_blocked(reason: String)

var _steps: Array = []
var _idx: int = -1
var _active: bool = false
var _pending_backpack: PhaseConfig = null
var _pending_binary: BinaryPhaseConfig = null
var _pending_type_box: TypeBoxPhaseConfig = null
var _pending_raw_mochila: RawKnapsackPhaseConfig = null
var _pending_tutorial_text: String = ""
var _has_pending_tutorial: bool = false


func is_sequence_active() -> bool:
	return _active


func should_show_next_button() -> bool:
	return _active


func begin_with_steps(steps: Array) -> void:
	abort_sequence()
	if steps.is_empty():
		push_warning("PhaseRunner: sequência vazia.")
		return
	for s in steps:
		if not (s is PhaseSequenceStep):
			push_warning("PhaseRunner: entrada ignorada (não é PhaseSequenceStep).")
			continue
		_steps.append(s)
	if _steps.is_empty():
		return
	_active = true
	_idx = 0
	_go_step(_idx)


func advance_from_phase() -> void:
	if not _active:
		return
	# Verifica se a fase atual permite avanço (subclasses podem implementar is_phase_success)
	var current_scene = get_tree().get_current_scene()
	if current_scene and current_scene.has_method("is_phase_success"):
		var ok: bool = current_scene.is_phase_success()
		if not ok:
			# Emite signal em vez de apenas push_warning para UI feedback
			phase_advance_blocked.emit("Objetivo não concluído. Complete a fase antes de avançar.")
			return
	# Avança índice e muda para a próxima fase
	_idx += 1
	if _idx >= _steps.size():
		_finish_sequence_to_menu()
		return
	_go_step(_idx)


func take_backpack_config_if_any() -> PhaseConfig:
	var c := _pending_backpack
	_pending_backpack = null
	return c


func take_binary_config_if_any() -> BinaryPhaseConfig:
	var c := _pending_binary
	_pending_binary = null
	return c

func take_type_box_config_if_any() -> TypeBoxPhaseConfig:
	var c := _pending_type_box
	_pending_type_box = null
	return c


func take_raw_knapsack_config_if_any() -> RawKnapsackPhaseConfig:
	var c := _pending_raw_mochila
	_pending_raw_mochila = null
	return c


func has_custom_tutorial() -> bool:
	return _has_pending_tutorial

func take_tutorial_text_if_any() -> String:
	var t := _pending_tutorial_text
	_pending_tutorial_text = ""
	_has_pending_tutorial = false
	return t


func abort_sequence() -> void:
	_active = false
	_steps.clear()
	_idx = -1
	_pending_backpack = null
	_pending_binary = null
	_pending_type_box = null
	_pending_raw_mochila = null
	_pending_tutorial_text = ""
	_has_pending_tutorial = false


func _go_step(i: int) -> void:
	if i < 0 or i >= _steps.size():
		return
	var step: PhaseSequenceStep = _steps[i]
	_pending_tutorial_text = step.custom_tutorial_text
	_has_pending_tutorial = true
	match step.kind:
		PhaseSequenceStep.Kind.MOCHILA:
			var cfg: PhaseConfig = step.config_mochila if step.config_mochila else PhaseConfig.new()
			_pending_backpack = cfg.duplicate(true)
			get_tree().change_scene_to_file(PATH_PHASE2)
		PhaseSequenceStep.Kind.BINARIO:
			var bc: BinaryPhaseConfig = step.config_binario if step.config_binario else BinaryPhaseConfig.new()
			_pending_binary = bc.duplicate(true)
			get_tree().change_scene_to_file(PATH_BINARY)
		PhaseSequenceStep.Kind.TYPE_BOX:
			var tbc: TypeBoxPhaseConfig = step.config_type_box if step.config_type_box else TypeBoxPhaseConfig.new()
			_pending_type_box = tbc.duplicate(true)
			get_tree().change_scene_to_file(PATH_TYPE_BOX)
		PhaseSequenceStep.Kind.RAW_MOCHILA:
			var rkc: RawKnapsackPhaseConfig = step.config_raw_mochila if step.config_raw_mochila else RawKnapsackPhaseConfig.new()
			_pending_raw_mochila = rkc.duplicate(true)
			get_tree().change_scene_to_file(PATH_RAW_MOCHILA)


func _finish_sequence_to_menu() -> void:
	abort_sequence()
	get_tree().change_scene_to_file(PATH_MENU)
