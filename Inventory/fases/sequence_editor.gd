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
@onready var check_calc: CheckBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckCalc

var _sequences: Dictionary = {} # filename -> PhaseSequenceList
var _root: TreeItem
var _selected_item: TreeItem
var _is_updating_ui: bool = false # impede chamadas de signals durante update UI

func _ready() -> void:
	_ensure_dir()
	tree.columns = 1
	_root = tree.create_item()
	_load_all_sequences()
	_show_empty()


func _ensure_dir() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("sequences"):
		dir.make_dir("sequences")


func _load_all_sequences() -> void:
	# Limpa árvore
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
	
	# Se estiver vazio, cria uma padrão
	if _sequences.is_empty():
		_create_new_sequence("Nova_Sequencia.tres")


func _add_sequence_to_tree(file_name: String, seq_list: PhaseSequenceList) -> TreeItem:
	var seq_item = tree.create_item(_root)
	seq_item.set_text(0, "📁 " + file_name.replace(".tres", ""))
	seq_item.set_metadata(0, {"type": "sequence", "file": file_name, "data": seq_list})
	seq_item.set_collapsed(false)
	
	var i = 1
	for step in seq_list.steps:
		_add_phase_to_tree(seq_item, step, i)
		i += 1
		
	return seq_item


func _add_phase_to_tree(parent: TreeItem, step: PhaseSequenceStep, index: int) -> TreeItem:
	var phase_item = tree.create_item(parent)
	var type_str = "Mochila" if step.kind == PhaseSequenceStep.Kind.MOCHILA else "Binário"
	phase_item.set_text(0, "📄 Fase %d (%s)" % [index, type_str])
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
	_selected_item = tree.get_selected()
	if not _selected_item:
		_show_empty()
		return
		
	var meta = _selected_item.get_metadata(0)
	if not meta:
		return
		
	_is_updating_ui = true
	
	if meta.type == "sequence":
		_show_sequence_editor(meta.file)
	elif meta.type == "phase":
		_show_phase_editor(meta.step)
		
	_is_updating_ui = false


func _show_empty() -> void:
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
		check_calc.button_pressed = cfg.allow_calc
	else:
		# Para fase binária, vamos desabilitar ou ocultar coisas por enquanto, 
		# pois focamos na mochila, mas deixamos os defaults
		pass


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
			var type_str = "Mochila" if step.kind == PhaseSequenceStep.Kind.MOCHILA else "Binário"
			c.set_text(0, "📄 Fase %d (%s)" % [i, type_str])
			i += 1
			
		_save_sequence(seq_meta.file)
		_show_empty()


func _on_btn_salvar_tudo_pressed() -> void:
	if not _selected_item: return
	var seq_item = _selected_item if _selected_item.get_metadata(0).type == "sequence" else _selected_item.get_parent()
	_save_sequence(seq_item.get_metadata(0).file)
	print("Sequência salva com sucesso!")


func _save_sequence(file_name: String) -> void:
	if _sequences.has(file_name):
		ResourceSaver.save(_sequences[file_name], SEQUENCES_DIR + "/" + file_name)


func _on_file_name_changed(new_text: String) -> void:
	if _is_updating_ui: return
	var sel = tree.get_selected()
	if not sel or sel.get_metadata(0).type != "sequence": return
	
	var old_file = sel.get_metadata(0).file
	var new_file = new_text.strip_edges()
	if new_file == "" or not new_file.is_valid_filename(): return
	if not new_file.ends_with(".tres"): new_file += ".tres"
	
	if old_file == new_file: return
	if _sequences.has(new_file): return # Nome já existe
	
	# Renomeia
	var seq = _sequences[old_file]
	_sequences.erase(old_file)
	_sequences[new_file] = seq
	
	DirAccess.rename_absolute(SEQUENCES_DIR + "/" + old_file, SEQUENCES_DIR + "/" + new_file)
	
	sel.set_text(0, "📁 " + new_text)
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
		
	# Atualiza o texto da árvore
	var type_str = "Mochila" if step.kind == PhaseSequenceStep.Kind.MOCHILA else "Binário"
	var idx = sel.get_index() + 1
	sel.set_text(0, "📄 Fase %d (%s)" % [idx, type_str])
	
	var parent_file = sel.get_metadata(0).parent_file
	_save_sequence(parent_file)
	
	_is_updating_ui = true
	_show_phase_editor(step)
	_is_updating_ui = false


func _on_param_changed(value: float) -> void:
	if _is_updating_ui: return
	var sel = tree.get_selected()
	if not sel or sel.get_metadata(0).type != "phase": return
	var step: PhaseSequenceStep = sel.get_metadata(0).step
	if step.kind != PhaseSequenceStep.Kind.MOCHILA: return
	
	var cfg: PhaseConfig = step.config_mochila
	cfg.capacity_bytes = int(spin_cap.value)
	cfg.backpack_slot_count = int(spin_slots_m.value)
	cfg.pool_slot_count = int(spin_slots_p.value)
	cfg.pool_grid_columns = int(spin_cols.value)
	cfg.spawn_int_min = int(spin_min.value)
	cfg.spawn_int_max = int(spin_max.value)
	
	# Simula preenchimento aleatório de tipos com random_pool
	var pool_size = int(spin_rnd_pool.value)
	if pool_size > 0:
		cfg.random_pool = ConfigGenerator._random_int_items(pool_size)
	else:
		cfg.random_pool.clear()
		
	var parent_file = sel.get_metadata(0).parent_file
	_save_sequence(parent_file)


func _on_text_param_changed(new_text: String) -> void:
	if _is_updating_ui: return
	var sel = tree.get_selected()
	if not sel or sel.get_metadata(0).type != "phase": return
	var step: PhaseSequenceStep = sel.get_metadata(0).step
	if step.kind != PhaseSequenceStep.Kind.MOCHILA: return
	
	step.config_mochila.initial_backpack_csv = new_text
	var parent_file = sel.get_metadata(0).parent_file
	_save_sequence(parent_file)


func _on_bool_param_changed(_toggled: bool) -> void:
	if _is_updating_ui: return
	var sel = tree.get_selected()
	if not sel or sel.get_metadata(0).type != "phase": return
	var step: PhaseSequenceStep = sel.get_metadata(0).step
	if step.kind != PhaseSequenceStep.Kind.MOCHILA: return
	
	step.config_mochila.use_converter = check_float.button_pressed
	step.config_mochila.allow_double = check_double.button_pressed
	step.config_mochila.allow_short = check_short.button_pressed
	step.config_mochila.allow_bool = check_bool.button_pressed
	step.config_mochila.allow_calc = check_calc.button_pressed
	
	var parent_file = sel.get_metadata(0).parent_file
	_save_sequence(parent_file)

func _show_dialog(title: String, text: String) -> void:
	var dlg = AcceptDialog.new()
	dlg.title = title
	dlg.dialog_text = text
	add_child(dlg)
	dlg.popup_centered()

func _on_help_geral_pressed() -> void:
	_show_dialog("Explorador de Sequências", "Uma 'Sequência' é um conjunto de fases na ordem. Você pode criar múltiplas sequências e cada uma é salva como um arquivo no seu computador.")

func _on_help_mochila_pressed() -> void:
	_show_dialog("Mochila e Bancada", "- Capacidade: Quantos bytes a mochila suporta.\n- Slots: Quantos quadrados visíveis existem para soltar itens.\n- Bancada (Pool): A área onde os itens ficam disponíveis para escolha.")

func _on_help_valores_pressed() -> void:
	_show_dialog("Valores e Tipos", "- Int Mín/Máx: A faixa de valores aleatórios gerados para os tipos Inteiros.\n- Forçar Itens CSV: Defina exatamente o que deve aparecer. Formato: valor_tipo. Ex: 1_i (Int 1), 3.14_f (Float), 2.5_d (Double), 1_b (Bool).\n- Tipos Aleatórios Extra: Adiciona IDs aleatórios cadastrados no jogo à bancada.")

func _on_btn_export_csv_pressed() -> void:
	var sel = tree.get_selected()
	if not sel: return
	var seq_item = sel if sel.get_metadata(0).type == "sequence" else sel.get_parent()
	var seq_list: PhaseSequenceList = seq_item.get_metadata(0).data
	
	var csv_str = "KIND,CAPACITY,SLOTS_M,SLOTS_P,COLS,MIN,MAX,CSV_ITEMS,RND_POOL,FLOAT,DOUBLE,SHORT,BOOL,CALC\n"
	for step in seq_list.steps:
		if step.kind == PhaseSequenceStep.Kind.MOCHILA:
			var c = step.config_mochila
			if not c: c = PhaseConfig.new()
			csv_str += "M,%d,%d,%d,%d,%d,%d,%s,%d,%s,%s,%s,%s,%s\n" % [
				c.capacity_bytes, c.backpack_slot_count, c.pool_slot_count, c.pool_grid_columns,
				c.spawn_int_min, c.spawn_int_max, c.initial_backpack_csv, c.random_pool.size(),
				str(c.use_converter), str(c.allow_double), str(c.allow_short), str(c.allow_bool), str(c.allow_calc)
			]
		else:
			csv_str += "B,0,0,0,0,0,0,,0,false,false,false,false,false\n"
			
	DisplayServer.clipboard_set(csv_str)
	_show_dialog("Exportar CSV", "Sequência exportada para a área de transferência (Ctrl+C) com sucesso!")

func _on_btn_import_csv_pressed() -> void:
	var csv_str = DisplayServer.clipboard_get().strip_edges()
	if csv_str == "" or not csv_str.begins_with("KIND,"):
		_show_dialog("Erro de Importação", "Nenhum CSV válido encontrado na área de transferência.")
		return
		
	var lines = csv_str.split("\n")
	var seq_list = PhaseSequenceList.new()
	
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line == "": continue
		var parts = line.split(",")
		if parts.size() < 14: continue
		
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
			c.initial_backpack_csv = parts[7]
			var rp_size = int(parts[8])
			if rp_size > 0:
				c.random_pool = ConfigGenerator._random_int_items(rp_size)
			c.use_converter = (parts[9] == "true")
			c.allow_double = (parts[10] == "true")
			c.allow_short = (parts[11] == "true")
			c.allow_bool = (parts[12] == "true")
			c.allow_calc = (parts[13] == "true")
			step.config_mochila = c
		else:
			step.kind = PhaseSequenceStep.Kind.BINARIO
			step.config_binario = ConfigGenerator.generate_binary_config()
		
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
	_show_dialog("Sucesso", "Sequência importada com sucesso!")


func _on_btn_jogar_pressed() -> void:
	var sel = tree.get_selected()
	if not sel: return
	var seq_item = sel if sel.get_metadata(0).type == "sequence" else sel.get_parent()
	var seq_list: PhaseSequenceList = seq_item.get_metadata(0).data
	
	var steps = seq_list.to_runtime_array()
	if steps.is_empty(): return
	
	# Salva só pra garantir
	_save_sequence(seq_item.get_metadata(0).file)
	
	PhaseRunner.begin_with_steps(steps)


func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Inventory/fases/main_menu.tscn")
