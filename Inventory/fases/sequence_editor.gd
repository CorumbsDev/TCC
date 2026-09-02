extends Control

@onready var tree: Tree = $Panel/VBoxContainer/HSplitContainer/LeftPanel/Tree
@onready var empty_label: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/EmptyLabel
@onready var sequence_editor_ui: VBoxContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/SequenceEditor
@onready var phase_editor_ui: VBoxContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor

# Sequence UI
@onready var file_name_edit: LineEdit = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/SequenceEditor/HBoxContainer/FileNameEdit

# Phase UI Containers and Controls
@onready var option_type: OptionButton = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/PhaseTypeHBox/OptionType
@onready var tutorial_text_edit: TextEdit = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/TutorialTextVBox/TutorialTextEdit
@onready var grid_mochila: GridContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer
@onready var hbox_mochila: HBoxContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/HBoxMochila
@onready var hbox_valores: HBoxContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/HBoxValores
@onready var grid_vals: GridContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer2
@onready var binary_panel: VBoxContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/BinaryPanel
@onready var status_label: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/StatusLabel
@onready var sep_mochila: HSeparator = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/Sep1
@onready var sep_valores: HSeparator = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/Sep2
@onready var sep_tools: HSeparator = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/Sep3
@onready var lbl_tools: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/LabelFerramentas
@onready var lbl_csv: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/LblCSV
@onready var line_edit_csv: LineEdit = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/LineEditCSV
@onready var lbl_rnd_pool: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/LblRndPool
@onready var spin_rnd_pool: SpinBox = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/SpinRndPool
@onready var sep_star: HSeparator = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/SepStar
@onready var lbl_star: Label = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/LabelStarHeader
@onready var star_grid: GridContainer = $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/StarGrid

# For passing to panels
@onready var ui_elements = {
	"spin_cap": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/SpinCap,
	"spin_slots_m": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/SpinSlotsM,
	"spin_slots_p": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/SpinSlotsP,
	"spin_cols": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer/SpinCols,
	"spin_min": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer2/SpinMin,
	"spin_max": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/GridContainer2/SpinMax,
	"line_edit_csv": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/LineEditCSV,
	"spin_rnd_pool": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/SpinRndPool,
	"check_float": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckFloat,
	"check_double": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckDouble,
	"check_short": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckShort,
	"check_fp8": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckFP8,
	"check_fp16": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckFP16,
	"check_fp_cust": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckFPCust,
	"check_calc": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/CheckCalc,
	"spin_bin_left": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/BinaryPanel/GridBinary/SpinBinLeft,
	"spin_bin_right": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/BinaryPanel/GridBinary/SpinBinRight,
	"spin_star2_moves": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/StarGrid/SpinStar2Moves,
	"line_edit_star3_solution": $Panel/VBoxContainer/HSplitContainer/RightPanel/VBoxContainer/PhaseEditor/StarGrid/LineEditStar3Solution
}

var file_manager: SequenceFileManager
var panels: Dictionary = {}

var _root: TreeItem
var _selected_item: TreeItem
var _is_updating_ui: bool = false
var _active_phase_step: PhaseSequenceStep = null
var _active_phase_parent_file: String = ""
var _last_rnd_pool_size: int = -1

func _ready() -> void:
	file_manager = SequenceFileManager.new()
	panels[PhaseSequenceStep.Kind.MOCHILA] = MochilaConfigPanel.new(ui_elements)
	panels[PhaseSequenceStep.Kind.TYPE_BOX] = TypeboxConfigPanel.new(ui_elements)
	panels[PhaseSequenceStep.Kind.RAW_MOCHILA] = RawConfigPanel.new(ui_elements)
	panels[PhaseSequenceStep.Kind.BINARIO] = BinaryConfigPanel.new(ui_elements)
	panels[PhaseSequenceStep.Kind.CONVERSAO] = ConversionConfigPanel.new(ui_elements)
	
	tree.columns = 1
	_root = tree.create_item()
	if line_edit_csv and not line_edit_csv.focus_exited.is_connected(_on_csv_focus_exited):
		line_edit_csv.focus_exited.connect(_on_csv_focus_exited)
	
	if tutorial_text_edit and not tutorial_text_edit.text_changed.is_connected(_on_tutorial_text_changed):
		tutorial_text_edit.text_changed.connect(_on_tutorial_text_changed)
	
	_configure_phase_type_options()
	
	_load_all_sequences()
	_show_empty()
	
	PanelArtLoader.skin_all_buttons(self)
	PanelArtLoader.apply_background(self)
	
	# Apply 20% zoom out to the main container
	var main_vbox = $Panel/VBoxContainer
	main_vbox.scale = Vector2(0.8, 0.8)
	main_vbox.pivot_offset = main_vbox.size / 2.0
	main_vbox.resized.connect(func(): main_vbox.pivot_offset = main_vbox.size / 2.0)

func _configure_phase_type_options() -> void:
	option_type.clear()
	option_type.add_item("Mochila (Knapsack)", PhaseSequenceStep.Kind.MOCHILA)
	if PhaseSequenceStep.binary_phases_enabled():
		option_type.add_item("Binário", PhaseSequenceStep.Kind.BINARIO)
	option_type.add_item("Caixas de Tipagem", PhaseSequenceStep.Kind.TYPE_BOX)
	option_type.add_item("Mochila + Tipagem (RAW)", PhaseSequenceStep.Kind.RAW_MOCHILA)
	if PhaseSequenceStep.conversion_phases_enabled():
		option_type.add_item("Conversão Decimal → Binário", PhaseSequenceStep.Kind.CONVERSAO)


func _load_all_sequences() -> void:
	for c in _root.get_children():
		c.free()
	
	var sequences = file_manager.load_all_sequences()
	for file_name in sequences:
		_add_sequence_to_tree(file_name, sequences[file_name])

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
	phase_item.set_text(0, "📄 Fase %d (%s)" % [index, _kind_label(step.kind)])
	phase_item.set_metadata(0, {"type": "phase", "step": step, "parent_file": parent.get_metadata(0).file})
	return phase_item

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
	var kind_idx := option_type.get_item_index(step.kind)
	if kind_idx >= 0:
		option_type.selected = kind_idx
	elif step.kind == PhaseSequenceStep.Kind.BINARIO:
		_set_status("Fase Binário desabilitada no jogo. Escolha outro tipo acima.")
	elif step.kind == PhaseSequenceStep.Kind.CONVERSAO:
		_set_status("Fase Conversão desabilitada no jogo. Escolha outro tipo acima.")
	else:
		option_type.selected = 0
	if tutorial_text_edit.text != step.custom_tutorial_text:
		tutorial_text_edit.text = step.custom_tutorial_text
	
	if panels.has(step.kind):
		var panel = panels[step.kind]
		panel.show_data(step)
		_apply_visibility_rules(panel.get_visibility_rules())
	
	if step.kind == PhaseSequenceStep.Kind.MOCHILA:
		_last_rnd_pool_size = int(ui_elements.spin_rnd_pool.value)
	else:
		_last_rnd_pool_size = -1

func _apply_visibility_rules(rules: Dictionary) -> void:
	grid_mochila.visible = rules.get("grid_mochila", true)
	hbox_mochila.visible = rules.get("hbox_mochila", true)
	sep_mochila.visible = rules.get("sep_mochila", true)
	hbox_valores.visible = rules.get("hbox_valores", true)
	grid_vals.visible = rules.get("grid_vals", true)
	sep_valores.visible = rules.get("sep_valores", true)
	lbl_csv.visible = rules.get("lbl_csv", true)
	line_edit_csv.visible = rules.get("line_edit_csv", true)
	lbl_rnd_pool.visible = rules.get("lbl_rnd_pool", true)
	spin_rnd_pool.visible = rules.get("spin_rnd_pool", true)
	sep_tools.visible = rules.get("sep_tools", true)
	lbl_tools.visible = rules.get("lbl_tools", true)
	ui_elements.check_float.visible = rules.get("check_float", true)
	ui_elements.check_double.visible = rules.get("check_double", true)
	ui_elements.check_short.visible = rules.get("check_short", true)
	ui_elements.check_fp8.visible = rules.get("check_fp8", true)
	ui_elements.check_fp16.visible = rules.get("check_fp16", true)
	ui_elements.check_fp_cust.visible = rules.get("check_fp_cust", true)
	ui_elements.check_calc.visible = rules.get("check_calc", true)
	binary_panel.visible = rules.get("binary_panel", false)
	
	var sg = rules.get("star_grid", false)
	sep_star.visible = sg
	lbl_star.visible = sg
	star_grid.visible = sg
	
	lbl_csv.text = rules.get("lbl_csv_text", "")
	line_edit_csv.placeholder_text = rules.get("line_edit_csv_placeholder", "")
	lbl_rnd_pool.text = rules.get("lbl_rnd_pool_text", "")

func _kind_label(kind: PhaseSequenceStep.Kind) -> String:
	match kind:
		PhaseSequenceStep.Kind.BINARIO: return "Binário"
		PhaseSequenceStep.Kind.TYPE_BOX: return "Tipagem"
		PhaseSequenceStep.Kind.RAW_MOCHILA: return "Mochila+RAW"
		PhaseSequenceStep.Kind.CONVERSAO: return "Conversão"
		_: return "Mochila"

func _flush_active_phase_editor() -> void:
	if _active_phase_step == null or _active_phase_parent_file == "":
		return
	_apply_ui_to_step(_active_phase_step)
	file_manager.save_sequence(_active_phase_parent_file, file_manager.sequences[_active_phase_parent_file])
	_set_status("Salvo: " + _active_phase_parent_file)

func _apply_ui_to_step(step: PhaseSequenceStep) -> void:
	if step == null: return
	step.custom_tutorial_text = tutorial_text_edit.text
	if panels.has(step.kind):
		var panel = panels[step.kind]
		if step.kind == PhaseSequenceStep.Kind.MOCHILA:
			_last_rnd_pool_size = panel.apply_to_step(step, _last_rnd_pool_size)
		else:
			panel.apply_to_step(step)

func _set_status(msg: String) -> void:
	if status_label: status_label.text = msg

func _on_btn_nova_seq_pressed() -> void:
	var base_name = "Nova_Sequencia"
	var i = 1
	var file_name = base_name + ".tres"
	while file_manager.sequences.has(file_name):
		file_name = base_name + "_" + str(i) + ".tres"
		i += 1
	var seq = file_manager.create_new_sequence(file_name)
	var item = _add_sequence_to_tree(file_name, seq)
	item.select(0)

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
	file_manager.save_sequence(meta.file, seq_list)

func _on_btn_delete_pressed() -> void:
	var sel = tree.get_selected()
	if not sel: return
	
	var meta = sel.get_metadata(0)
	if meta.type == "sequence":
		var file = meta.file
		file_manager.delete_sequence(file)
		sel.free()
		_show_empty()
	elif meta.type == "phase":
		var seq_item = sel.get_parent()
		var seq_meta = seq_item.get_metadata(0)
		var seq_list: PhaseSequenceList = seq_meta.data
		seq_list.steps.erase(meta.step)
		sel.free()
		
		var i = 1
		for c in seq_item.get_children():
			var step = c.get_metadata(0).step
			c.set_text(0, "📄 Fase %d (%s)" % [i, _kind_label(step.kind)])
			i += 1
			
		file_manager.save_sequence(seq_meta.file, seq_list)
		_show_empty()

func _on_btn_move_up_pressed() -> void:
	if not _selected_item: return
	var meta = _selected_item.get_metadata(0)
	if not meta or meta.type != "phase": return
	
	var parent_file = meta.parent_file
	var step = meta.step
	var seq_list = file_manager.sequences[parent_file] as PhaseSequenceList
	
	var idx = seq_list.steps.find(step)
	if idx > 0:
		seq_list.steps.remove_at(idx)
		seq_list.steps.insert(idx - 1, step)
		file_manager.save_sequence(parent_file, seq_list)
		_load_all_sequences()
		_reselect_item(parent_file, step)

func _on_btn_move_down_pressed() -> void:
	if not _selected_item: return
	var meta = _selected_item.get_metadata(0)
	if not meta or meta.type != "phase": return
	
	var parent_file = meta.parent_file
	var step = meta.step
	var seq_list = file_manager.sequences[parent_file] as PhaseSequenceList
	
	var idx = seq_list.steps.find(step)
	if idx >= 0 and idx < seq_list.steps.size() - 1:
		seq_list.steps.remove_at(idx)
		seq_list.steps.insert(idx + 1, step)
		file_manager.save_sequence(parent_file, seq_list)
		_load_all_sequences()
		_reselect_item(parent_file, step)

func _reselect_item(parent_file: String, step: PhaseSequenceStep) -> void:
	for c in _root.get_children():
		var m = c.get_metadata(0)
		if m and m.type == "sequence" and m.file == parent_file:
			for p in c.get_children():
				var pm = p.get_metadata(0)
				if pm and pm.type == "phase" and pm.step == step:
					p.select(0)
					return

func _on_btn_salvar_tudo_pressed() -> void:
	_flush_active_phase_editor()
	if not _selected_item: return
	var seq_item = _selected_item if _selected_item.get_metadata(0).type == "sequence" else _selected_item.get_parent()
	file_manager.save_sequence(seq_item.get_metadata(0).file, seq_item.get_metadata(0).data)
	_set_status("Sequência salva: " + seq_item.get_metadata(0).file)

func _on_file_name_changed(new_text: String) -> void:
	_flush_active_phase_editor()
	if _is_updating_ui: return
	var sel = tree.get_selected()
	if not sel or sel.get_metadata(0).type != "sequence": return
	
	var old_file = sel.get_metadata(0).file
	var new_file = new_text.strip_edges()
	if new_file == "" or not new_file.is_valid_filename(): return
	if not new_file.ends_with(".tres"): new_file += ".tres"
	
	if old_file == new_file: return
	
	if file_manager.rename_sequence(old_file, new_file):
		sel.set_text(0, "📁 " + new_text)
		var meta = sel.get_metadata(0)
		meta.file = new_file
		sel.set_metadata(0, meta)
		
		for c in sel.get_children():
			var child_meta = c.get_metadata(0)
			child_meta.parent_file = new_file
			c.set_metadata(0, child_meta)

func _on_phase_type_selected(index: int) -> void:
	if _is_updating_ui: return
	var sel = tree.get_selected()
	if not sel or sel.get_metadata(0).type != "phase": return
	
	var step: PhaseSequenceStep = sel.get_metadata(0).step
	step.kind = option_type.get_item_id(index) as PhaseSequenceStep.Kind
	if step.kind == PhaseSequenceStep.Kind.MOCHILA and not step.config_mochila:
		step.config_mochila = ConfigGenerator.generate_knapsack_config()
	elif step.kind == PhaseSequenceStep.Kind.BINARIO and not step.config_binario:
		step.config_binario = ConfigGenerator.generate_binary_config()
	elif step.kind == PhaseSequenceStep.Kind.TYPE_BOX and not step.config_type_box:
		step.config_type_box = ConfigGenerator.generate_type_box_config()
	elif step.kind == PhaseSequenceStep.Kind.RAW_MOCHILA and not step.config_raw_mochila:
		step.config_raw_mochila = ConfigGenerator.generate_raw_knapsack_config()
	elif step.kind == PhaseSequenceStep.Kind.CONVERSAO and not step.config_conversao:
		step.config_conversao = ConfigGenerator.generate_conversion_config()
		
	var idx = sel.get_index() + 1
	sel.set_text(0, "📄 Fase %d (%s)" % [idx, _kind_label(step.kind)])
	
	var parent_file = sel.get_metadata(0).parent_file
	file_manager.save_sequence(parent_file, file_manager.sequences[parent_file])
	
	_active_phase_parent_file = parent_file
	_active_phase_step = step
	_is_updating_ui = true
	_show_phase_editor(step)
	_is_updating_ui = false

func _on_param_changed(_value: float) -> void:
	_trigger_ui_save()

func _on_text_param_changed(_new_text: String) -> void:
	_trigger_ui_save()

func _on_tutorial_text_changed() -> void:
	_trigger_ui_save()

func _on_bool_param_changed(_toggled: bool) -> void:
	_trigger_ui_save()

func _on_binary_param_changed(_value: float) -> void:
	_trigger_ui_save()

func _on_csv_focus_exited() -> void:
	_trigger_ui_save()

func _trigger_ui_save() -> void:
	if _is_updating_ui or _active_phase_step == null: return
	_apply_ui_to_step(_active_phase_step)
	if _active_phase_parent_file != "":
		file_manager.save_sequence(_active_phase_parent_file, file_manager.sequences[_active_phase_parent_file])
	_show_phase_editor(_active_phase_step)

func _show_dialog(title: String, text: String) -> void:
	# AcceptDialog como filho do editor ficava limitado ao painel esquerdo (~250px) e cortava o texto.
	TutorialOverlay.open(self, "seq_editor_help", title, text, false)

func _on_help_geral_pressed() -> void:
	_show_dialog("Explorador de Sequências", "Uma 'Sequência' é um conjunto de fases na ordem. Você pode criar múltiplas sequências e cada uma é salva como um arquivo no seu computador.")

func _on_help_mochila_pressed() -> void:
	_show_dialog("Mochila e Bancada", "- Capacidade: Quantos bytes a mochila suporta.\n- Slots: Quantos quadrados visíveis existem para soltar itens.\n- Bancada (Pool): A área onde os itens ficam disponíveis para escolha.")

func _on_help_valores_pressed() -> void:
	_show_dialog("Valores e Tipos", "- Int Mín/Máx: faixa de ints aleatórios.\n- Itens iniciais: 1_i, 3.14_f, 2.5_d (vírgulas entre itens).\n- Exportar/Importar CSV usa | entre itens na coluna de itens (ex: 1_i|2_i|3_i).\n- Tipos aleatórios extra: quantidade de IDs sortidos na bancada.")

func _on_btn_jogar_pressed() -> void:
	_flush_active_phase_editor()
	var sel = tree.get_selected()
	if not sel:
		return
	var seq_item = sel if sel.get_metadata(0).type == "sequence" else sel.get_parent()
	var file_name: String = seq_item.get_metadata(0).file
	var seq_list: PhaseSequenceList = file_manager.sequences.get(file_name, seq_item.get_metadata(0).data)
	
	var steps = seq_list.to_runtime_array()
	if steps.is_empty():
		return
	
	file_manager.save_sequence(file_name, seq_list)
	PhaseRunner.begin_with_steps(steps)

func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Inventory/fases/main_menu.tscn")


func _on_btn_export_csv_pressed() -> void:
	_flush_active_phase_editor()
	var sel = tree.get_selected()
	if not sel:
		_show_dialog("Exportar CSV", "Selecione uma sequência (ou uma fase dela) para exportar.")
		return
	var seq_item = sel if sel.get_metadata(0).type == "sequence" else sel.get_parent()
	if seq_item == null:
		return
	var seq_list: PhaseSequenceList = seq_item.get_metadata(0).data
	var csv_str = "KIND,CAPACITY,SLOTS_M,SLOTS_P,COLS,MIN,MAX,CSV_ITEMS,RND_POOL,FLOAT,DOUBLE,SHORT,BOOL,FP8,FP16,CALC,FP_CUST,FP8_E,FP8_M,FP16_E,FP16_M\n"
	for step in seq_list.steps:
		if step.kind == PhaseSequenceStep.Kind.MOCHILA:
			var c = step.config_mochila
			if not c:
				c = PhaseConfig.new()
			var items_field := SequenceCsvCodec.items_field_from_backpack_csv(c.initial_backpack_csv)
			csv_str += "M,%d,%d,%d,%d,%d,%d,%s,%d,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d,%d,%d\n" % [
				c.capacity_bytes, c.backpack_slot_count, c.pool_slot_count, c.pool_grid_columns,
				c.spawn_int_min, c.spawn_int_max,
				SequenceCsvCodec.escape_field(items_field), c.random_pool.size(),
				str(c.use_converter), str(c.allow_double), str(c.allow_short), "false",
				str(c.allow_fp8), str(c.allow_fp16), str(c.allow_calc), str(c.allow_fp_customization),
				c.fp8_exp_bits, c.fp8_mant_bits, c.fp16_exp_bits, c.fp16_mant_bits
			]
		elif step.kind == PhaseSequenceStep.Kind.TYPE_BOX:
			var tc = step.config_type_box
			if not tc:
				tc = TypeBoxPhaseConfig.new()
			var raw_field := SequenceCsvCodec.ITEMS_SEP.join(tc.initial_raw_values)
			csv_str += "T,%d,%d,0,0,0,0,%s,%d,%s,%s,%s,%s,%s,%s,false,false,%d,%d,%d,%d\n" % [
				tc.capacity_bytes, tc.box_slot_count,
				SequenceCsvCodec.escape_field(raw_field),
				1 if tc.randomize_values else 0,
				str(tc.allow_float), str(tc.allow_double), str(tc.allow_short), "false",
				str(tc.allow_fp8), str(tc.allow_fp16),
				tc.fp8_exp_bits, tc.fp8_mant_bits, tc.fp16_exp_bits, tc.fp16_mant_bits
			]
		elif step.kind == PhaseSequenceStep.Kind.RAW_MOCHILA:
			var rc: RawKnapsackPhaseConfig = step.config_raw_mochila
			if not rc:
				rc = RawKnapsackPhaseConfig.new()
			var raw_field2 := SequenceCsvCodec.ITEMS_SEP.join(rc.initial_raw_values)
			csv_str += "R,%d,%d,%d,%d,0,0,%s,%d,%s,%s,%s,%s,%s,%s,false,false,%d,%d,%d,%d\n" % [
				rc.capacity_bytes, rc.backpack_slot_count, rc.pool_slot_count, rc.pool_grid_columns,
				SequenceCsvCodec.escape_field(raw_field2),
				1 if rc.randomize_values else 0,
				str(rc.allow_float), str(rc.allow_double), str(rc.allow_short), "false",
				str(rc.allow_fp8), str(rc.allow_fp16),
				rc.fp8_exp_bits, rc.fp8_mant_bits, rc.fp16_exp_bits, rc.fp16_mant_bits
			]
		elif step.kind == PhaseSequenceStep.Kind.CONVERSAO and PhaseSequenceStep.conversion_phases_enabled():
			var cc: ConversionPhaseConfig = step.config_conversao
			if not cc:
				cc = ConfigGenerator.generate_conversion_config()
			var chal_parts: PackedStringArray = PackedStringArray()
			for v in cc.challenge_decimals:
				chal_parts.append(str(int(v)))
			var chal := SequenceCsvCodec.ITEMS_SEP.join(chal_parts)
			csv_str += "C,%d,%d,0,0,0,0,%s,0,false,false,false,false,false,false,false,false,4,3,5,10\n" % [
				cc.num_bits, int(cc.advance_delay_seconds * 10.0),
				SequenceCsvCodec.escape_field(chal)
			]
		elif step.kind == PhaseSequenceStep.Kind.BINARIO and PhaseSequenceStep.binary_phases_enabled():
			var bc: BinaryPhaseConfig = step.config_binario
			if not bc:
				bc = ConfigGenerator.generate_binary_config()
			csv_str += "B,%d,%d,0,0,0,0,,0,false,false,false,false,false,false,false,false,4,3,5,10\n" % [
				bc.fixed_left_bit, bc.fixed_right_bit
			]
	DisplayServer.clipboard_set(csv_str)
	_show_dialog("Exportar CSV", "Sequência copiada para a área de transferência.\nCole com Ctrl+V onde quiser.")


func _on_btn_import_csv_pressed() -> void:
	var csv_str = DisplayServer.clipboard_get().strip_edges()
	if csv_str == "" or not csv_str.begins_with("KIND,"):
		_show_dialog("Erro de Importação", "Nenhum CSV válido encontrado na área de transferência.\nExporte antes ou cole um CSV que comece com KIND,")
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
			var rp_size = int(parts[8]) if parts.size() > 8 else 0
			if rp_size > 0:
				c.random_pool = ConfigGenerator._random_int_items(rp_size)
			if parts.size() > 9:
				c.use_converter = (parts[9] == "true")
			if parts.size() > 10:
				c.allow_double = (parts[10] == "true")
			if parts.size() > 11:
				c.allow_short = (parts[11] == "true")
			# parts[12] = BOOL legado (ignorado)
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
			rc.randomize_values = (int(parts[8]) > 0) if parts.size() > 8 else false
			if parts.size() > 9:
				rc.allow_float = (parts[9] == "true")
			if parts.size() > 10:
				rc.allow_double = (parts[10] == "true")
			if parts.size() > 11:
				rc.allow_short = (parts[11] == "true")
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
			var tbc = TypeBoxPhaseConfig.new()
			tbc.capacity_bytes = int(parts[1])
			tbc.box_slot_count = int(parts[2])
			var vals: PackedStringArray = PackedStringArray()
			var raw_field := SequenceCsvCodec.backpack_csv_from_items_field(parts[7])
			for p in raw_field.split(",", false):
				var s := p.strip_edges()
				if not s.is_empty():
					vals.append(s)
			tbc.initial_raw_values = vals
			tbc.randomize_values = (int(parts[8]) > 0) if parts.size() > 8 else false
			if parts.size() > 9:
				tbc.allow_float = (parts[9] == "true")
			if parts.size() > 10:
				tbc.allow_double = (parts[10] == "true")
			if parts.size() > 11:
				tbc.allow_short = (parts[11] == "true")
			if parts.size() > 13:
				tbc.allow_fp8 = (parts[13] == "true")
			if parts.size() > 14:
				tbc.allow_fp16 = (parts[14] == "true")
			if parts.size() >= 21:
				tbc.fp8_exp_bits = int(parts[17])
				tbc.fp8_mant_bits = int(parts[18])
				tbc.fp16_exp_bits = int(parts[19])
				tbc.fp16_mant_bits = int(parts[20])
			step.config_type_box = tbc
		elif parts[0] == "C":
			if not PhaseSequenceStep.conversion_phases_enabled():
				continue
			step.kind = PhaseSequenceStep.Kind.CONVERSAO
			var cc := ConversionPhaseConfig.new()
			cc.num_bits = int(parts[1]) if parts.size() > 1 else 3
			cc.advance_delay_seconds = maxf(0.3, float(int(parts[2])) / 10.0) if parts.size() > 2 else 2.4
			var chal_field := SequenceCsvCodec.backpack_csv_from_items_field(parts[7])
			cc.set_challenges_from_csv(chal_field)
			cc.apply_constraints()
			step.config_conversao = cc
		elif parts[0] == "B":
			if not PhaseSequenceStep.binary_phases_enabled():
				continue
			step.kind = PhaseSequenceStep.Kind.BINARIO
			var bc := BinaryPhaseConfig.new()
			bc.fixed_left_bit = int(parts[1]) if parts.size() > 1 else 1
			bc.fixed_right_bit = int(parts[2]) if parts.size() > 2 else 0
			step.config_binario = bc
		else:
			continue
		seq_list.steps.append(step)
	if seq_list.steps.is_empty():
		_show_dialog("Erro de Importação", "CSV sem fases válidas.")
		return
	var base_name = "Seq_Importada"
	var idx = 1
	var file_name = base_name + ".tres"
	while file_manager.sequences.has(file_name):
		file_name = base_name + "_" + str(idx) + ".tres"
		idx += 1
	file_manager.sequences[file_name] = seq_list
	file_manager.save_sequence(file_name, seq_list)
	var item = _add_sequence_to_tree(file_name, seq_list)
	item.select(0)
	_show_dialog("Sucesso", "Sequência importada: " + file_name)
