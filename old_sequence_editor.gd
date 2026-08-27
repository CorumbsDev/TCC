extends Control

const SEQUENCES_DIR = "user://sequences"

@onready var tree: Tree = $Panel/VBoxContainer/HSplitContainer/LeftPanel/Tree
@onready var empty_label: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/EmptyLabel
@onready var sequence_editor_ui: VBoxContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/SequenceEditor
@onready var phase_editor_ui: VBoxContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor

# Sequence UI
@onready var file_name_edit: LineEdit = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/SequenceEditor/HBoxContainer/FileNameEdit

# Phase UI
@onready var option_type: OptionButton = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/PhaseTypeHBox/OptionType
@onready var spin_cap: SpinBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/SpinCap
@onready var spin_slots_m: SpinBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/SpinSlotsM
@onready var spin_slots_p: SpinBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/SpinSlotsP
@onready var spin_cols: SpinBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/SpinCols
@onready var spin_min: SpinBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer2/SpinMin
@onready var spin_max: SpinBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer2/SpinMax
@onready var line_edit_csv: LineEdit = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/LineEditCSV
@onready var spin_rnd_pool: SpinBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/SpinRndPool
@onready var check_float: CheckBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckFloat
@onready var check_double: CheckBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckDouble
@onready var check_short: CheckBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckShort
@onready var check_bool: CheckBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckBool
@onready var check_fp8: CheckBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckFP8
@onready var check_fp16: CheckBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckFP16
@onready var check_fp_cust: CheckBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckFPCust
@onready var check_calc: CheckBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckCalc
@onready var lbl_csv: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/LblCSV
@onready var lbl_rnd_pool: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/LblRndPool
@onready var lbl_cap: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/LblCap
@onready var lbl_slots_m: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/LblSlotsM
@onready var lbl_slots_p: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/LblSlotsP
@onready var lbl_cols: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/LblCols
@onready var grid_mochila: GridContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer
@onready var hbox_mochila: HBoxContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/HBoxMochila
@onready var hbox_valores: HBoxContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/HBoxValores
@onready var grid_vals: GridContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer2
@onready var binary_panel: VBoxContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/BinaryPanel
@onready var spin_bin_left: SpinBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/BinaryPanel/GridBinary/SpinBinLeft
@onready var spin_bin_right: SpinBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/BinaryPanel/GridBinary/SpinBinRight
@onready var status_label: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/StatusLabel
@onready var sep_mochila: HSeparator = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/Sep1
@onready var sep_valores: HSeparator = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/Sep2
@onready var sep_tools: HSeparator = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/Sep3
@onready var lbl_tools: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/LabelFerramentas

var _sequences: Dictionary = {} # filename -> PhaseSequenceList
var _root: TreeItem
var _selected_item: TreeItem
var _is_updating_ui: bool = false # impede chamadas de signals durante update UI
var _active_phase_step: PhaseSequenceStep = null
var _active_phase_parent_file: String = ""
var _last_rnd_pool_size: int = -1

func _ready() -> void:
	_ensure_dir()
	tree.columns = 1
	_root = tree.create_item()
	if line_edit_csv and not line_edit_csv.focus_exited.is_connected(_on_csv_focus_exited):
		line_edit_csv.focus_exited.connect(_on_csv_focus_exited)
	_load_all_sequences()
	_show_empty()


func _ensure_dir() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("sequences"):
		dir.make_dir("sequences")


func _load_all_sequences() -> void:
	# Limpa ├írvore
	for c in _root.get_children():
		c.free()
	_sequences.clear()
	
	var dir = DirAccess.open(SEQUENCES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res = ResourceLoader.load(SEQUENCES_DIR + "/" + file_name)
				if res is PhaseSequenceList:
					_sequences[file_name] = res
					_add_sequence_to_tree(file_name, res)
			file_name = dir.get_next()
	
	# Se estiver vazio, cria uma padr├úo
	if _sequences.is_empty():
		_create_new_sequence("Nova_Sequencia.tres")


func _add_sequence_to_tree(file_name: String, seq_list: PhaseSequenceList) -> TreeItem:
	var seq_item = tree.create_item(_root)
	seq_item.set_text(0, "­ƒôü " + file_name.replace(".tres", ""))
	seq_item.set_metadata(0, {"type": "sequence", "file": file_name, "data": seq_list})
	seq_item.set_collapsed(false)
	
	var i = 1
	for step in seq_list.steps:
		_add_phase_to_tree(seq_item, step, i)
		i += 1
		
	return seq_item


func _add_phase_to_tree(parent: TreeItem, step: PhaseSequenceStep, index: int) -> TreeItem:
	var phase_item = tree.create_item(parent)
	phase_item.set_text(0, "­ƒôä Fase %d (%s)" % [index, _kind_label(step.kind)])
	phase_item.set_metadata(0, {"type": "phase", "step": step, "parent_file": parent.get_metadata(0).file})
	return phase_item


func _create_new_sequence(file_name: String) -> void:
	var seq = PhaseSequenceList.new()
	var step = PhaseSequenceStep.new()
	step.kind = PhaseSequenceStep.Kind.MOCHILA
	step.config_mochila = ConfigGenerator.generate_knapsack_config()
	seq.steps.append(step)
	
	ResourceSaver.save(seq, SEQUENCES_DIR + "/" + file_name)
	_sequences[file_name] = seq
	var item = _add_sequence_to_tree(file_name, seq)
	item.select(0)


func _on_tree_item_selected() -> void:
	_flush_active_phase_editor()
	_selected_item = tree.get_selected()
	if not _selected_item:
		_show_empty()
		return
		
	var meta = _selected_item.get_metadata(0)
	if not meta:
		return
		
	_is_updating_ui = true
	
	if meta.type == "sequence":
		_active_phase_step = null
		_active_phase_parent_file = ""
		_show_sequence_editor(meta.file)
	elif meta.type == "phase":
		_active_phase_parent_file = meta.parent_file
		_active_phase_step = meta.step
		_show_phase_editor(meta.step)
		
	_is_updating_ui = false


func _show_empty() -> void:
	_active_phase_step = null
	_active_phase_parent_file = ""
	empty_label.visible = true
	sequence_editor_ui.visible = false
	phase_editor_ui.visible = false


func _show_sequence_editor(file_name: String) -> void:
	empty_label.visible = false
	sequence_editor_ui.visible = true
	phase_editor_ui.visible = false
	file_name_edit.text = file_name.replace(".tres", "")


func _show_phase_editor(step: PhaseSequenceStep) -> void:
	empty_label.visible = false
	sequence_editor_ui.visible = false
	phase_editor_ui.visible = true
	
	option_type.selected = step.kind
	_update_phase_editor_visibility(step)
	
	if step.kind == PhaseSequenceStep.Kind.MOCHILA:
		var cfg = step.config_mochila
		if not cfg:
			cfg = PhaseConfig.new()
			step.config_mochila = cfg
			
		spin_cap.value = cfg.capacity_bytes
		spin_slots_m.value = cfg.backpack_slot_count
		spin_slots_p.value = cfg.pool_slot_count
		spin_cols.value = cfg.pool_grid_columns
		spin_min.value = cfg.spawn_int_min
		spin_max.value = cfg.spawn_int_max
		line_edit_csv.text = cfg.initial_backpack_csv
		spin_rnd_pool.value = cfg.random_pool.size()
		check_float.button_pressed = cfg.use_converter
		check_double.button_pressed = cfg.allow_double
		check_short.button_pressed = cfg.allow_short
		check_bool.button_pressed = cfg.allow_bool
		check_fp8.button_pressed = cfg.allow_fp8
		check_fp16.button_pressed = cfg.allow_fp16
		check_fp_cust.button_pressed = cfg.allow_fp_customization
		check_calc.button_pressed = cfg.allow_calc
	elif step.kind == PhaseSequenceStep.Kind.TYPE_BOX:
		var cfg = step.config_type_box
		if not cfg:
			cfg = TypeBoxPhaseConfig.new()
			step.config_type_box = cfg
			
		spin_cap.value = cfg.capacity_bytes
		spin_slots_m.value = cfg.box_slot_count
		line_edit_csv.text = ",".join(cfg.initial_raw_values)
		spin_rnd_pool.value = 1 if cfg.randomize_values else 0
		check_float.button_pressed = cfg.allow_float
		check_double.button_pressed = cfg.allow_double
		check_short.button_pressed = cfg.allow_short
		check_bool.button_pressed = cfg.allow_bool
		check_fp8.button_pressed = cfg.allow_fp8
		check_fp16.button_pressed = cfg.allow_fp16
		check_calc.button_pressed = false
		check_fp_cust.button_pressed = false
		_last_rnd_pool_size = -1
	elif step.kind == PhaseSequenceStep.Kind.RAW_MOCHILA:
		var cfg: RawKnapsackPhaseConfig = step.config_raw_mochila
		if not cfg:
			cfg = ConfigGenerator.generate_raw_knapsack_config()
			step.config_raw_mochila = cfg
		spin_cap.value = cfg.capacity_bytes
		spin_slots_m.value = cfg.backpack_slot_count
		spin_slots_p.value = cfg.pool_slot_count
		spin_cols.value = cfg.pool_grid_columns
		line_edit_csv.text = ",".join(cfg.initial_raw_values)
		spin_rnd_pool.value = 1 if cfg.randomize_values else 0
		check_float.button_pressed = cfg.allow_float
		check_double.button_pressed = cfg.allow_double
		check_short.button_pressed = cfg.allow_short
		check_bool.button_pressed = cfg.allow_bool
		check_fp8.button_pressed = cfg.allow_fp8
		check_fp16.button_pressed = cfg.allow_fp16
		check_calc.button_pressed = false
		check_fp_cust.button_pressed = false
		_last_rnd_pool_size = -1
	elif step.kind == PhaseSequenceStep.Kind.BINARIO:
		var bc: BinaryPhaseConfig = step.config_binario
		if not bc:
			bc = ConfigGenerator.generate_binary_config()
			step.config_binario = bc
		spin_bin_left.value = bc.fixed_left_bit
		spin_bin_right.value = bc.fixed_right_bit
		_last_rnd_pool_size = -1
	if step.kind == PhaseSequenceStep.Kind.MOCHILA:
		_last_rnd_pool_size = int(spin_rnd_pool.value)


func _kind_label(kind: PhaseSequenceStep.Kind) -> String:
	match kind:
		PhaseSequenceStep.Kind.BINARIO: return "Bin├írio"
		PhaseSequenceStep.Kind.TYPE_BOX: return "Tipagem"
		PhaseSequenceStep.Kind.RAW_MOCHILA: return "Mochila+RAW"
		_: return "Mochila"


func _update_phase_editor_visibility(step: PhaseSequenceStep) -> void:
	var is_mochila := step.kind == PhaseSequenceStep.Kind.MOCHILA
	var is_typebox := step.kind == PhaseSequenceStep.Kind.TYPE_BOX
	var is_raw := step.kind == PhaseSequenceStep.Kind.RAW_MOCHILA
	var is_bin := step.kind == PhaseSequenceStep.Kind.BINARIO
	var show_mochila := is_mochila or is_typebox or is_raw
	var show_pool := is_mochila or is_raw
	var show_tools := is_mochila or is_typebox or is_raw
	grid_mochila.visible = show_mochila
	hbox_mochila.visible = show_mochila
	sep_mochila.visible = show_mochila
	hbox_valores.visible = is_mochila or is_typebox or is_raw
	grid_vals.visible = is_mochila
	sep_valores.visible = is_mochila or is_typebox or is_raw
	lbl_csv.visible = is_mochila or is_typebox or is_raw
	line_edit_csv.visible = is_mochila or is_typebox or is_raw
	lbl_rnd_pool.visible = show_pool or is_typebox or is_raw
	spin_rnd_pool.visible = show_pool or is_typebox or is_raw
	sep_tools.visible = show_tools
	lbl_tools.visible = show_tools
	check_float.visible = show_tools
	check_double.visible = show_tools
	check_short.visible = show_tools
	check_bool.visible = show_tools
	check_fp8.visible = show_tools
	check_fp16.visible = show_tools
	check_fp_cust.visible = is_mochila
	check_calc.visible = is_mochila
	binary_panel.visible = is_bin
	if is_mochila:
		lbl_csv.text = "Itens iniciais na mochila (ex: 1_i, 2_i, 3.14_f):"
		line_edit_csv.placeholder_text = "1_i, 2_i, 3.14_f"
		lbl_rnd_pool.text = "Qtd Tipos Aleat├│rios Extra:"
	elif is_typebox:
		lbl_csv.text = "Valores brutos iniciais (ex: 1.5, 2.0, 3):"
		line_edit_csv.placeholder_text = "1.5, 2.0, 3"
		lbl_rnd_pool.text = "Valores aleat├│rios (1=sim, 0=n├úo):"
	elif is_raw:
		lbl_csv.text = "Valores RAW no pool (ex: 7, 3.14, 42):"
		line_edit_csv.placeholder_text = "7, 3.14, 42"
		lbl_rnd_pool.text = "Valores aleat├│rios (1=sim, 0=n├úo):"
	else:
		lbl_csv.text = "Itens for├ºados (n├úo usado em fase bin├íria):"


func _flush_active_phase_editor() -> void:
	if _active_phase_step == null or _active_phase_parent_file == "":
		return
	_apply_ui_to_step(_active_phase_step)
	_save_sequence(_active_phase_parent_file)
	_set_status("Salvo: " + _active_phase_parent_file)


func _apply_ui_to_step(step: PhaseSequenceStep) -> void:
	if step == null:
		return
	match step.kind:
		PhaseSequenceStep.Kind.MOCHILA:
			var cfg: PhaseConfig = step.config_mochila
			if not cfg:
				cfg = PhaseConfig.new()
				step.config_mochila = cfg
			cfg.capacity_bytes = int(spin_cap.value)
			cfg.backpack_slot_count = int(spin_slots_m.value)
			cfg.pool_slot_count = int(spin_slots_p.value)
			cfg.pool_grid_columns = int(spin_cols.value)
			cfg.spawn_int_min = int(spin_min.value)
			cfg.spawn_int_max = int(spin_max.value)
			cfg.initial_backpack_csv = line_edit_csv.text.strip_edges()
			var pool_size := int(spin_rnd_pool.value)
			if pool_size != _last_rnd_pool_size:
				if pool_size > 0:
					cfg.random_pool = ConfigGenerator._random_int_items(pool_size)
				else:
					cfg.random_pool.clear()
				_last_rnd_pool_size = pool_size
			cfg.use_converter = check_float.button_pressed
			cfg.allow_double = check_double.button_pressed
			cfg.allow_short = check_short.button_pressed
			cfg.allow_bool = check_bool.button_pressed
			cfg.allow_fp8 = check_fp8.button_pressed
			cfg.allow_fp16 = check_fp16.button_pressed
			cfg.allow_fp_customization = check_fp_cust.button_pressed
			cfg.allow_calc = check_calc.button_pressed
		PhaseSequenceStep.Kind.TYPE_BOX:
			var cfg: TypeBoxPhaseConfig = step.config_type_box
			if not cfg:
				cfg = ConfigGenerator.generate_type_box_config()
				step.config_type_box = cfg
			cfg.capacity_bytes = int(spin_cap.value)
			cfg.box_slot_count = int(spin_slots_m.value)
			var vals: PackedStringArray = PackedStringArray()
			for p in line_edit_csv.text.split(",", false):
				var s := p.strip_edges()
				if not s.is_empty():
					vals.append(s)
			cfg.initial_raw_values = vals
			cfg.randomize_values = (int(spin_rnd_pool.value) > 0)
			cfg.allow_float = check_float.button_pressed
			cfg.allow_double = check_double.button_pressed
			cfg.allow_short = check_short.button_pressed
			cfg.allow_bool = check_bool.button_pressed
			cfg.allow_fp8 = check_fp8.button_pressed
			cfg.allow_fp16 = check_fp16.button_pressed
		PhaseSequenceStep.Kind.RAW_MOCHILA:
			var cfg: RawKnapsackPhaseConfig = step.config_raw_mochila
			if not cfg:
				cfg = ConfigGenerator.generate_raw_knapsack_config()
				step.config_raw_mochila = cfg
			cfg.capacity_bytes = int(spin_cap.value)
			cfg.backpack_slot_count = int(spin_slots_m.value)
			cfg.pool_slot_count = int(spin_slots_p.value)
			cfg.pool_grid_columns = int(spin_cols.value)
			var raw_vals: PackedStringArray = PackedStringArray()
			for p in line_edit_csv.text.split(",", false):
				var s := p.strip_edges()
				if not s.is_empty():
					raw_vals.append(s)
			cfg.initial_raw_values = raw_vals
			cfg.randomize_values = (int(spin_rnd_pool.value) > 0)
			cfg.allow_float = check_float.button_pressed
			cfg.allow_double = check_double.button_pressed
			cfg.allow_short = check_short.button_pressed
			cfg.allow_bool = check_bool.button_pressed
			cfg.allow_fp8 = check_fp8.button_pressed
			cfg.allow_fp16 = check_fp16.button_pressed
		PhaseSequenceStep.Kind.BINARIO:
			var bc: BinaryPhaseConfig = step.config_binario
			if not bc:
				bc = ConfigGenerator.generate_binary_config()
				step.config_binario = bc
			bc.fixed_left_bit = int(spin_bin_left.value)
			bc.fixed_right_bit = int(spin_bin_right.value)


func _set_status(msg: String) -> void:
	if status_label:
		status_label.text = msg


func _on_binary_param_changed(_value: float) -> void:
	if _is_updating_ui:
		return
	_apply_ui_to_step(_active_phase_step)
	if _active_phase_parent_file != "":
		_save_sequence(_active_phase_parent_file)


func _on_btn_nova_seq_pressed() -> void:
	var base_name = "Nova_Sequencia"
	var i = 1
	var file_name = base_name + ".tres"
	while _sequences.has(file_name):
		file_name = base_name + "_" + str(i) + ".tres"
		i += 1
	_create_new_sequence(file_name)


func _on_btn_nova_fase_pressed() -> void:
	var sel = tree.get_selected()
	if not sel: return
	
	var seq_item = sel if sel.get_metadata(0).type == "sequence" else sel.get_parent()
	var meta = seq_item.get_metadata(0)
	var seq_list: PhaseSequenceList = meta.data
	
	var new_step = PhaseSequenceStep.new()
	new_step.kind = PhaseSequenceStep.Kind.MOCHILA
	new_step.config_mochila = ConfigGenerator.generate_knapsack_config()
	seq_list.steps.append(new_step)
	
	_add_phase_to_tree(seq_item, new_step, seq_list.steps.size())
	_save_sequence(meta.file)


func _on_btn_delete_pressed() -> void:
	var sel = tree.get_selected()
	if not sel: return
	
	var meta = sel.get_metadata(0)
	if meta.type == "sequence":
		var file = meta.file
		var path = SEQUENCES_DIR + "/" + file
		DirAccess.remove_absolute(path)
		_sequences.erase(file)
		sel.free()
		_show_empty()
	elif meta.type == "phase":
		var seq_item = sel.get_parent()
		var seq_meta = seq_item.get_metadata(0)
		var seq_list: PhaseSequenceList = seq_meta.data
		seq_list.steps.erase(meta.step)
		sel.free()
		
		# Renumerar labels
		var i = 1
		for c in seq_item.get_children():
			var step = c.get_metadata(0).step
			c.set_text(0, "­ƒôä Fase %d (%s)" % [i, _kind_label(step.kind)])
			i += 1
			
		_save_sequence(seq_meta.file)
		_show_empty()


func _on_btn_salvar_tudo_pressed() -> void:
	_flush_active_phase_editor()
	if not _selected_item:
		return
	var seq_item = _selected_item if _selected_item.get_metadata(0).type == "sequence" else _selected_item.get_parent()
	_save_sequence(seq_item.get_metadata(0).file)
	_set_status("Sequ├¬ncia salva: " + seq_item.get_metadata(0).file)
	print("Sequ├¬ncia salva com sucesso!")


func _save_sequence(file_name: String) -> void:
	if not _sequences.has(file_name):
		return
	var seq: PhaseSequenceList = _sequences[file_name]
	var path := SEQUENCES_DIR + "/" + file_name
	var err := ResourceSaver.save(seq, path)
	if err != OK:
		push_error("Erro ao salvar sequ├¬ncia %s: %s" % [file_name, error_string(err)])
		_set_status("Erro ao salvar (veja Output).")
		return
	# Garante que o disco tem a mesma refer├¬ncia editada na mem├│ria
	_sequences[file_name] = seq
	# Mant├®m refer├¬ncia da ├írvore alinhada ao recurso salvo
	for child in _root.get_children():
		var meta = child.get_metadata(0)
		if meta and meta.get("file") == file_name:
			meta.data = seq
			child.set_metadata(0, meta)


func _on_csv_focus_exited() -> void:
	if _is_updating_ui or _active_phase_step == null:
		return
	_apply_ui_to_step(_active_phase_step)
	if _active_phase_parent_file != "":
		_save_sequence(_active_phase_parent_file)


func _on_file_name_changed(new_text: String) -> void:
	_flush_active_phase_editor()
	if _is_updating_ui:
		return
	var sel = tree.get_selected()
	if not sel or sel.get_metadata(0).type != "sequence": return
	
	var old_file = sel.get_metadata(0).file
	var new_file = new_text.strip_edges()
	if new_file == "" or not new_file.is_valid_filename(): return
	if not new_file.ends_with(".tres"): new_file += ".tres"
	
	if old_file == new_file: return
	if _sequences.has(new_file): return # Nome j├í existe
	
	# Renomeia
	var seq = _sequences[old_file]
	_sequences.erase(old_file)
	_sequences[new_file] = seq
	
	DirAccess.rename_absolute(SEQUENCES_DIR + "/" + old_file, SEQUENCES_DIR + "/" + new_file)
	
	sel.set_text(0, "­ƒôü " + new_text)
	var meta = sel.get_metadata(0)
	meta.file = new_file
	sel.set_metadata(0, meta)
	
	# Atualiza filhos
	for c in sel.get_children():
		var child_meta = c.get_metadata(0)
		child_meta.parent_file = new_file
		c.set_metadata(0, child_meta)


func _on_phase_type_selected(index: int) -> void:
	if _is_updating_ui: return
	var sel = tree.get_selected()
	if not sel or sel.get_metadata(0).type != "phase": return
	
	var step: PhaseSequenceStep = sel.get_metadata(0).step
	step.kind = index as PhaseSequenceStep.Kind
	if step.kind == PhaseSequenceStep.Kind.MOCHILA and not step.config_mochila:
		step.config_mochila = ConfigGenerator.generate_knapsack_config()
	elif step.kind == PhaseSequenceStep.Kind.BINARIO and not step.config_binario:
		step.config_binario = ConfigGenerator.generate_binary_config()
	elif step.kind == PhaseSequenceStep.Kind.TYPE_BOX and not step.config_type_box:
		step.config_type_box = ConfigGenerator.generate_type_box_config()
	elif step.kind == PhaseSequenceStep.Kind.RAW_MOCHILA and not step.config_raw_mochila:
		step.config_raw_mochila = ConfigGenerator.generate_raw_knapsack_config()
		
	var idx = sel.get_index() + 1
	sel.set_text(0, "­ƒôä Fase %d (%s)" % [idx, _kind_label(step.kind)])
	
	var parent_file = sel.get_metadata(0).parent_file
	_save_sequence(parent_file)
	
	_active_phase_parent_file = parent_file
	_active_phase_step = step
	_is_updating_ui = true
	_show_phase_editor(step)
	_is_updating_ui = false


func _on_param_changed(_value: float) -> void:
	if _is_updating_ui or _active_phase_step == null:
		return
	_apply_ui_to_step(_active_phase_step)
	if _active_phase_parent_file != "":
		_save_sequence(_active_phase_parent_file)


func _on_text_param_changed(_new_text: String) -> void:
	if _is_updating_ui or _active_phase_step == null:
		return
	_apply_ui_to_step(_active_phase_step)
	if _active_phase_parent_file != "":
		_save_sequence(_active_phase_parent_file)


func _on_bool_param_changed(_toggled: bool) -> void:
	if _is_updating_ui or _active_phase_step == null:
		return
	_apply_ui_to_step(_active_phase_step)
	if _active_phase_parent_file != "":
		_save_sequence(_active_phase_parent_file)

func _show_dialog(title: String, text: String) -> void:
	var dlg = AcceptDialog.new()
	dlg.title = title
	dlg.dialog_text = text
	add_child(dlg)
	dlg.popup_centered()

func _on_help_geral_pressed() -> void:
	_show_dialog("Explorador de Sequ├¬ncias", "Uma 'Sequ├¬ncia' ├® um conjunto de fases na ordem. Voc├¬ pode criar m├║ltiplas sequ├¬ncias e cada uma ├® salva como um arquivo no seu computador.")

func _on_help_mochila_pressed() -> void:
	_show_dialog("Mochila e Bancada", "- Capacidade: Quantos bytes a mochila suporta.\n- Slots: Quantos quadrados vis├¡veis existem para soltar itens.\n- Bancada (Pool): A ├írea onde os itens ficam dispon├¡veis para escolha.")

func _on_help_valores_pressed() -> void:
	_show_dialog("Valores e Tipos", "- Int M├¡n/M├íx: faixa de ints aleat├│rios.\n- Itens iniciais: 1_i, 3.14_f, 2.5_d, 1_b (v├¡rgulas entre itens).\n- Exportar/Importar CSV usa | entre itens na coluna de itens (ex: 1_i|2_i|3_i).\n- Tipos aleat├│rios extra: quantidade de IDs sortidos na bancada.")

func _on_btn_export_csv_pressed() -> void:
	var sel = tree.get_selected()
	if not sel: return
	var seq_item = sel if sel.get_metadata(0).type == "sequence" else sel.get_parent()
	var seq_list: PhaseSequenceList = seq_item.get_metadata(0).data
	
	var csv_str = "KIND,CAPACITY,SLOTS_M,SLOTS_P,COLS,MIN,MAX,CSV_ITEMS,RND_POOL,FLOAT,DOUBLE,SHORT,BOOL,FP8,FP16,CALC,FP_CUST,FP8_E,FP8_M,FP16_E,FP16_M\n"
	for step in seq_list.steps:
		if step.kind == PhaseSequenceStep.Kind.MOCHILA:
			var c = step.config_mochila
			if not c: c = PhaseConfig.new()
			var items_field := SequenceCsvCodec.items_field_from_backpack_csv(c.initial_backpack_csv)
			csv_str += "M,%d,%d,%d,%d,%d,%d,%s,%d,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d,%d,%d\n" % [
				c.capacity_bytes, c.backpack_slot_count, c.pool_slot_count, c.pool_grid_columns,
				c.spawn_int_min, c.spawn_int_max,
				SequenceCsvCodec.escape_field(items_field), c.random_pool.size(),
				str(c.use_converter), str(c.allow_double), str(c.allow_short), str(c.allow_bool),
				str(c.allow_fp8), str(c.allow_fp16), str(c.allow_calc), str(c.allow_fp_customization),
				c.fp8_exp_bits, c.fp8_mant_bits, c.fp16_exp_bits, c.fp16_mant_bits
			]
		elif step.kind == PhaseSequenceStep.Kind.TYPE_BOX:
			var c = step.config_type_box
			if not c: c = TypeBoxPhaseConfig.new()
			var raw_field := SequenceCsvCodec.ITEMS_SEP.join(c.initial_raw_values)
			csv_str += "T,%d,%d,0,0,0,0,%s,%d,%s,%s,%s,%s,%s,%s,false,false,%d,%d,%d,%d\n" % [
				c.capacity_bytes, c.box_slot_count,
				SequenceCsvCodec.escape_field(raw_field),
				1 if c.randomize_values else 0,
				str(c.allow_float), str(c.allow_double), str(c.allow_short), str(c.allow_bool),
				str(c.allow_fp8), str(c.allow_fp16),
				c.fp8_exp_bits, c.fp8_mant_bits, c.fp16_exp_bits, c.fp16_mant_bits
			]
		elif step.kind == PhaseSequenceStep.Kind.RAW_MOCHILA:
			var c: RawKnapsackPhaseConfig = step.config_raw_mochila
			if not c:
				c = RawKnapsackPhaseConfig.new()
			var raw_field2 := SequenceCsvCodec.ITEMS_SEP.join(c.initial_raw_values)
			csv_str += "R,%d,%d,%d,%d,0,0,%s,%d,%s,%s,%s,%s,%s,%s,false,false,%d,%d,%d,%d\n" % [
				c.capacity_bytes, c.backpack_slot_count, c.pool_slot_count, c.pool_grid_columns,
				SequenceCsvCodec.escape_field(raw_field2),
				1 if c.randomize_values else 0,
				str(c.allow_float), str(c.allow_double), str(c.allow_short), str(c.allow_bool),
				str(c.allow_fp8), str(c.allow_fp16),
				c.fp8_exp_bits, c.fp8_mant_bits, c.fp16_exp_bits, c.fp16_mant_bits
			]
		else:
			var bc: BinaryPhaseConfig = step.config_binario
			if not bc:
				bc = ConfigGenerator.generate_binary_config()
			csv_str += "B,%d,%d,0,0,0,0,,0,false,false,false,false,false,false,false,false,4,3,5,10\n" % [
				bc.fixed_left_bit, bc.fixed_right_bit
			]
			
	DisplayServer.clipboard_set(csv_str)
	_show_dialog("Exportar CSV", "Sequ├¬ncia exportada para a ├írea de transfer├¬ncia (Ctrl+C) com sucesso!")

func _on_btn_import_csv_pressed() -> void:
	var csv_str = DisplayServer.clipboard_get().strip_edges()
	if csv_str == "" or not csv_str.begins_with("KIND,"):
		_show_dialog("Erro de Importa├º├úo", "Nenhum CSV v├ílido encontrado na ├írea de transfer├¬ncia.")
		return
		
	var lines = csv_str.split("\n")
	var seq_list = PhaseSequenceList.new()
	
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line == "":
			continue
		var parts: PackedStringArray = SequenceCsvCodec.parse_csv_line(line)
		if parts.size() < 8:
			continue
		
		var step = PhaseSequenceStep.new()
		if parts[0] == "M":
			step.kind = PhaseSequenceStep.Kind.MOCHILA
			var c = PhaseConfig.new()
			c.capacity_bytes = int(parts[1])
			c.backpack_slot_count = int(parts[2])
			c.pool_slot_count = int(parts[3])
			c.pool_grid_columns = int(parts[4])
			c.spawn_int_min = int(parts[5])
			c.spawn_int_max = int(parts[6])
			c.initial_backpack_csv = SequenceCsvCodec.backpack_csv_from_items_field(parts[7])
			var rp_size = int(parts[8])
			if rp_size > 0:
				c.random_pool = ConfigGenerator._random_int_items(rp_size)
			if parts.size() > 9:
				c.use_converter = (parts[9] == "true")
			if parts.size() > 10:
				c.allow_double = (parts[10] == "true")
			if parts.size() > 11:
				c.allow_short = (parts[11] == "true")
			if parts.size() > 12:
				c.allow_bool = (parts[12] == "true")
			if parts.size() > 13:
				c.allow_fp8 = (parts[13] == "true")
			if parts.size() > 14:
				c.allow_fp16 = (parts[14] == "true")
			if parts.size() > 15:
				c.allow_calc = (parts[15] == "true")
			if parts.size() >= 21:
				c.allow_fp_customization = (parts[16] == "true")
				c.fp8_exp_bits = int(parts[17])
				c.fp8_mant_bits = int(parts[18])
				c.fp16_exp_bits = int(parts[19])
				c.fp16_mant_bits = int(parts[20])
			step.config_mochila = c
		elif parts[0] == "R":
			step.kind = PhaseSequenceStep.Kind.RAW_MOCHILA
			var rc := RawKnapsackPhaseConfig.new()
			rc.capacity_bytes = int(parts[1])
			rc.backpack_slot_count = int(parts[2])
			rc.pool_slot_count = int(parts[3])
			rc.pool_grid_columns = int(parts[4])
			var raw_vals2: PackedStringArray = PackedStringArray()
			var raw_field_r := SequenceCsvCodec.backpack_csv_from_items_field(parts[7])
			for p in raw_field_r.split(",", false):
				var s2 := p.strip_edges()
				if not s2.is_empty():
					raw_vals2.append(s2)
			rc.initial_raw_values = raw_vals2
			rc.randomize_values = (int(parts[8]) > 0)
			if parts.size() > 9:
				rc.allow_float = (parts[9] == "true")
			if parts.size() > 10:
				rc.allow_double = (parts[10] == "true")
			if parts.size() > 11:
				rc.allow_short = (parts[11] == "true")
			if parts.size() > 12:
				rc.allow_bool = (parts[12] == "true")
			if parts.size() > 13:
				rc.allow_fp8 = (parts[13] == "true")
			if parts.size() > 14:
				rc.allow_fp16 = (parts[14] == "true")
			if parts.size() >= 21:
				rc.fp8_exp_bits = int(parts[17])
				rc.fp8_mant_bits = int(parts[18])
				rc.fp16_exp_bits = int(parts[19])
				rc.fp16_mant_bits = int(parts[20])
			step.config_raw_mochila = rc
		elif parts[0] == "T":
			step.kind = PhaseSequenceStep.Kind.TYPE_BOX
			var c = TypeBoxPhaseConfig.new()
			c.capacity_bytes = int(parts[1])
			c.box_slot_count = int(parts[2])
			var vals: PackedStringArray = PackedStringArray()
			var raw_field := SequenceCsvCodec.backpack_csv_from_items_field(parts[7])
			for p in raw_field.split(",", false):
				var s := p.strip_edges()
				if not s.is_empty():
					vals.append(s)
			c.initial_raw_values = vals
			c.randomize_values = (int(parts[8]) > 0)
			if parts.size() > 9:
				c.allow_float = (parts[9] == "true")
			if parts.size() > 10:
				c.allow_double = (parts[10] == "true")
			if parts.size() > 11:
				c.allow_short = (parts[11] == "true")
			if parts.size() > 12:
				c.allow_bool = (parts[12] == "true")
			if parts.size() > 13:
				c.allow_fp8 = (parts[13] == "true")
			if parts.size() > 14:
				c.allow_fp16 = (parts[14] == "true")
			if parts.size() >= 21:
				c.fp8_exp_bits = int(parts[17])
				c.fp8_mant_bits = int(parts[18])
				c.fp16_exp_bits = int(parts[19])
				c.fp16_mant_bits = int(parts[20])
			step.config_type_box = c
		else:
			step.kind = PhaseSequenceStep.Kind.BINARIO
			var bc := BinaryPhaseConfig.new()
			bc.fixed_left_bit = int(parts[1]) if parts.size() > 1 else 1
			bc.fixed_right_bit = int(parts[2]) if parts.size() > 2 else 0
			step.config_binario = bc
		
		seq_list.steps.append(step)
	
	var base_name = "Seq_Importada"
	var idx = 1
	var file_name = base_name + ".tres"
	while _sequences.has(file_name):
		file_name = base_name + "_" + str(idx) + ".tres"
		idx += 1
		
	ResourceSaver.save(seq_list, SEQUENCES_DIR + "/" + file_name)
	_sequences[file_name] = seq_list
	var item = _add_sequence_to_tree(file_name, seq_list)
	item.select(0)
	_show_dialog("Sucesso", "Sequ├¬ncia importada com sucesso!")


func _on_btn_jogar_pressed() -> void:
	_flush_active_phase_editor()
	var sel = tree.get_selected()
	if not sel:
		return
	var seq_item = sel if sel.get_metadata(0).type == "sequence" else sel.get_parent()
	var file_name: String = seq_item.get_metadata(0).file
	var seq_list: PhaseSequenceList = _sequences.get(file_name, seq_item.get_metadata(0).data)
	
	var steps = seq_list.to_runtime_array()
	if steps.is_empty():
		return
	
	_save_sequence(file_name)
	
	PhaseRunner.begin_with_steps(steps)


func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Inventory/fases/main_menu.tscn")
