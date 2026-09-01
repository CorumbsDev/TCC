class_name SequenceFileManager
extends RefCounted

const SEQUENCES_DIR = "user://sequences"
## Mesma sequência usada pelo botão Começar no menu (cópia no editor fica em user://sequences/).
const BUNDLED_PEDAGOGICAL_SEQUENCE := "res://Inventory/fases/scenarios/sequencia_base.tres"
var sequences: Dictionary = {}

func _init() -> void:
	_ensure_dir()

func _ensure_dir() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("sequences"):
		dir.make_dir("sequences")

func load_all_sequences() -> Dictionary:
	sequences.clear()
	var dir = DirAccess.open(SEQUENCES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res = ResourceLoader.load(SEQUENCES_DIR + "/" + file_name)
				if res is PhaseSequenceList:
					sequences[file_name] = res
			file_name = dir.get_next()
			
	if sequences.is_empty():
		_create_base_sequence("Sequencia_Base.tres")
		
	return sequences

func _create_base_sequence(file_name: String) -> PhaseSequenceList:
	# Preferir a sequência pedagógica embutida no projeto.
	var bundled := load(BUNDLED_PEDAGOGICAL_SEQUENCE) as PhaseSequenceList
	if bundled != null and not bundled.steps.is_empty():
		ResourceSaver.save(bundled, SEQUENCES_DIR + "/" + file_name)
		sequences[file_name] = bundled
		return bundled

	var seq = PhaseSequenceList.new()

	var step1 = PhaseSequenceStep.new()
	step1.kind = PhaseSequenceStep.Kind.MOCHILA
	step1.config_mochila = ConfigGenerator.generate_knapsack_config(8, 8, 10, 4, 1, 10, "", 6, false)
	seq.steps.append(step1)

	var step2 = PhaseSequenceStep.new()
	step2.kind = PhaseSequenceStep.Kind.TYPE_BOX
	step2.config_type_box = ConfigGenerator.generate_type_box_config(12, ["7", "3.14", "1"])
	step2.config_type_box.expected_solution_types = PackedStringArray(["int", "float", "int"])
	seq.steps.append(step2)

	ResourceSaver.save(seq, SEQUENCES_DIR + "/" + file_name)
	sequences[file_name] = seq
	return seq

func create_new_sequence(file_name: String) -> PhaseSequenceList:
	var seq = PhaseSequenceList.new()
	var step = PhaseSequenceStep.new()
	step.kind = PhaseSequenceStep.Kind.MOCHILA
	step.config_mochila = ConfigGenerator.generate_knapsack_config()
	seq.steps.append(step)
	
	ResourceSaver.save(seq, SEQUENCES_DIR + "/" + file_name)
	sequences[file_name] = seq
	return seq

func save_sequence(file_name: String, seq: PhaseSequenceList) -> bool:
	if not sequences.has(file_name):
		return false
	var path := SEQUENCES_DIR + "/" + file_name
	var err := ResourceSaver.save(seq, path)
	if err != OK:
		push_error("Erro ao salvar sequência %s: %s" % [file_name, error_string(err)])
		return false
	sequences[file_name] = seq
	return true

func delete_sequence(file_name: String) -> void:
	var path = SEQUENCES_DIR + "/" + file_name
	if DirAccess.dir_exists_absolute(SEQUENCES_DIR) and FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	sequences.erase(file_name)

func rename_sequence(old_file: String, new_file: String) -> bool:
	if not sequences.has(old_file) or sequences.has(new_file):
		return false
	var seq = sequences[old_file]
	sequences.erase(old_file)
	sequences[new_file] = seq
	var err = DirAccess.rename_absolute(SEQUENCES_DIR + "/" + old_file, SEQUENCES_DIR + "/" + new_file)
	return err == OK
