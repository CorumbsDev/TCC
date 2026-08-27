class_name BinaryConfigPanel
extends RefCounted

var ui: Dictionary

func _init(ui_elements: Dictionary) -> void:
	ui = ui_elements

func show_data(step: PhaseSequenceStep) -> void:
	var bc: BinaryPhaseConfig = step.config_binario
	if not bc:
		bc = ConfigGenerator.generate_binary_config()
		step.config_binario = bc
	ui.spin_bin_left.value = bc.fixed_left_bit
	ui.spin_bin_right.value = bc.fixed_right_bit

func apply_to_step(step: PhaseSequenceStep) -> void:
	var bc: BinaryPhaseConfig = step.config_binario
	if not bc:
		bc = ConfigGenerator.generate_binary_config()
		step.config_binario = bc
	bc.fixed_left_bit = int(ui.spin_bin_left.value)
	bc.fixed_right_bit = int(ui.spin_bin_right.value)

func get_visibility_rules() -> Dictionary:
	return {
		"grid_mochila": false,
		"hbox_mochila": false,
		"sep_mochila": false,
		"hbox_valores": false,
		"grid_vals": false,
		"sep_valores": false,
		"lbl_csv": true,
		"line_edit_csv": false,
		"lbl_rnd_pool": false,
		"spin_rnd_pool": false,
		"sep_tools": false,
		"lbl_tools": false,
		"check_float": false,
		"check_double": false,
		"check_short": false,
		"check_fp8": false,
		"check_fp16": false,
		"check_fp_cust": false,
		"check_calc": false,
		"binary_panel": true,
		"lbl_csv_text": "Itens forçados (não usado em fase binária):",
		"line_edit_csv_placeholder": "",
		"lbl_rnd_pool_text": ""
	}
