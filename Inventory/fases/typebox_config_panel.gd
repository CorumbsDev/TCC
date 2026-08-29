class_name TypeboxConfigPanel
extends RefCounted

var ui: Dictionary

func _init(ui_elements: Dictionary) -> void:
	ui = ui_elements

func show_data(step: PhaseSequenceStep) -> void:
	var cfg = step.config_type_box
	if not cfg:
		cfg = TypeBoxPhaseConfig.new()
		step.config_type_box = cfg
		
	ui.spin_cap.value = cfg.capacity_bytes
	ui.spin_slots_m.value = cfg.box_slot_count
	var joined := ",".join(cfg.initial_raw_values)
	if ui.line_edit_csv.text != joined:
		ui.line_edit_csv.text = joined
	ui.spin_rnd_pool.value = 1 if cfg.randomize_values else 0
	ui.check_float.button_pressed = cfg.allow_float
	ui.check_double.button_pressed = cfg.allow_double
	ui.check_short.button_pressed = cfg.allow_short
	ui.check_fp8.button_pressed = cfg.allow_fp8
	ui.check_fp16.button_pressed = cfg.allow_fp16
	ui.check_calc.button_pressed = false
	ui.check_fp_cust.button_pressed = false
	ui.spin_star2_moves.value = cfg.star2_max_moves
	ui.line_edit_star3_solution.text = cfg.star3_best_solution_csv

func apply_to_step(step: PhaseSequenceStep) -> void:
	var cfg: TypeBoxPhaseConfig = step.config_type_box
	if not cfg:
		cfg = ConfigGenerator.generate_type_box_config()
		step.config_type_box = cfg
		
	cfg.capacity_bytes = int(ui.spin_cap.value)
	cfg.box_slot_count = int(ui.spin_slots_m.value)
	var vals: PackedStringArray = PackedStringArray()
	for p in ui.line_edit_csv.text.split(",", false):
		var p_str: String = p
		var s := p_str.strip_edges()
		if not s.is_empty():
			vals.append(s)
	cfg.initial_raw_values = vals
	cfg.randomize_values = (int(ui.spin_rnd_pool.value) > 0)
	cfg.allow_float = ui.check_float.button_pressed
	cfg.allow_double = ui.check_double.button_pressed
	cfg.allow_short = ui.check_short.button_pressed
	cfg.allow_fp8 = ui.check_fp8.button_pressed
	cfg.allow_fp16 = ui.check_fp16.button_pressed
	cfg.star2_max_moves = int(ui.spin_star2_moves.value)
	cfg.star3_best_solution_csv = ui.line_edit_star3_solution.text.strip_edges()

func get_visibility_rules() -> Dictionary:
	return {
		"grid_mochila": true,
		"hbox_mochila": true,
		"sep_mochila": true,
		"hbox_valores": true,
		"grid_vals": false,
		"sep_valores": true,
		"lbl_csv": true,
		"line_edit_csv": true,
		"lbl_rnd_pool": true,
		"spin_rnd_pool": true,
		"sep_tools": true,
		"lbl_tools": true,
		"check_float": true,
		"check_double": true,
		"check_short": true,
		"check_fp8": true,
		"check_fp16": true,
		"check_fp_cust": false,
		"check_calc": false,
		"star_grid": true,
		"binary_panel": false,
		"lbl_csv_text": "Valores brutos iniciais (ex: 1.5, 2.0, 3):",
		"line_edit_csv_placeholder": "1.5, 2.0, 3",
		"lbl_rnd_pool_text": "Valores aleatórios (1=sim, 0=não):"
	}
