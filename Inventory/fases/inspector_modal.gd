extends AcceptDialog

var insp_rt_label: RichTextLabel = null
var insp_config_panel: VBoxContainer = null
var spin_fp8_exp: SpinBox = null
var spin_fp8_mant: SpinBox = null
var spin_fp16_exp: SpinBox = null
var spin_fp16_mant: SpinBox = null

var config = null
var current_item: Node = null

func _init():
	title = "Inspecionador de Orbes"
	var vbox = VBoxContainer.new()
	
	insp_rt_label = RichTextLabel.new()
	insp_rt_label.bbcode_enabled = true
	insp_rt_label.custom_minimum_size = Vector2(450, 200)
	vbox.add_child(insp_rt_label)
	
	insp_config_panel = VBoxContainer.new()
	var lbl_cfg = Label.new()
	lbl_cfg.text = "Configuração do Formato (Soma fixa p/ Sign=1):"
	insp_config_panel.add_child(lbl_cfg)
	
	var grid = GridContainer.new()
	grid.columns = 4
	insp_config_panel.add_child(grid)
	
	var lbl_fp8_exp = Label.new()
	lbl_fp8_exp.text = "FP8 Exp:"
	grid.add_child(lbl_fp8_exp)
	spin_fp8_exp = SpinBox.new()
	spin_fp8_exp.min_value = 1
	spin_fp8_exp.max_value = 6
	spin_fp8_exp.value_changed.connect(_on_insp_cfg_changed.bind("fp8"))
	grid.add_child(spin_fp8_exp)
	
	var lbl_fp8_mant = Label.new()
	lbl_fp8_mant.text = "FP8 Mant:"
	grid.add_child(lbl_fp8_mant)
	spin_fp8_mant = SpinBox.new()
	spin_fp8_mant.editable = false
	grid.add_child(spin_fp8_mant)
	
	var lbl_fp16_exp = Label.new()
	lbl_fp16_exp.text = "FP16 Exp:"
	grid.add_child(lbl_fp16_exp)
	spin_fp16_exp = SpinBox.new()
	spin_fp16_exp.min_value = 1
	spin_fp16_exp.max_value = 14
	spin_fp16_exp.value_changed.connect(_on_insp_cfg_changed.bind("fp16"))
	grid.add_child(spin_fp16_exp)
	
	var lbl_fp16_mant = Label.new()
	lbl_fp16_mant.text = "FP16 Mant:"
	grid.add_child(lbl_fp16_mant)
	spin_fp16_mant = SpinBox.new()
	spin_fp16_mant.editable = false
	grid.add_child(spin_fp16_mant)
	
	vbox.add_child(insp_config_panel)
	add_child(vbox)

func open(p_config, p_item):
	config = p_config
	current_item = p_item
	
	# Usa o formato específico do item se ele já o salvou. Caso contrário, pega do config da fase
	var fp8_e = current_item.fp_exp_bits if current_item.data_type == current_item.DataType.FP8 and current_item.fp_exp_bits != -1 else config.fp8_exp_bits
	var fp16_e = current_item.fp_exp_bits if current_item.data_type == current_item.DataType.FP16 and current_item.fp_exp_bits != -1 else config.fp16_exp_bits
	
	spin_fp8_exp.set_value_no_signal(fp8_e)
	spin_fp8_mant.set_value_no_signal(7 - fp8_e)
	spin_fp16_exp.set_value_no_signal(fp16_e)
	spin_fp16_mant.set_value_no_signal(15 - fp16_e)
	
	insp_config_panel.visible = config.allow_fp_customization and current_item.data_type in [current_item.DataType.FP8, current_item.DataType.FP16]
	
	_update_inspector_text()
	popup_centered(Vector2(500, 350))

func _on_insp_cfg_changed(_val: float, type: String):
	if type == "fp8" and current_item.data_type == current_item.DataType.FP8:
		var new_exp_bits = int(spin_fp8_exp.value)
		var new_mant_bits = 7 - new_exp_bits
		spin_fp8_mant.set_value_no_signal(new_mant_bits)
		
		# Recupera bits brutos usando o formato antigo
		var old_exp = current_item.fp_exp_bits if current_item.fp_exp_bits != -1 else config.fp8_exp_bits
		var old_mant = current_item.fp_mant_bits if current_item.fp_mant_bits != -1 else config.fp8_mant_bits
		var dict = _float_to_custom_fp_bits(current_item.value_float, old_exp, old_mant)
		var raw_bits = dict.bits
		
		# Atualiza o formato interno do orbe
		current_item.fp_exp_bits = new_exp_bits
		current_item.fp_mant_bits = new_mant_bits
		
		# Converte os bits brutos de volta para float sob a nova codificação
		var new_float = _custom_fp_bits_to_float(raw_bits, new_exp_bits, new_mant_bits)
		if current_item.has_method("set_value_by_type"):
			current_item.set_value_by_type(new_float, current_item.data_type)
		else:
			current_item.value_float = new_float
			if current_item.has_method("update_label_display"):
				current_item.update_label_display()
			
	elif type == "fp16" and current_item.data_type == current_item.DataType.FP16:
		var new_exp_bits = int(spin_fp16_exp.value)
		var new_mant_bits = 15 - new_exp_bits
		spin_fp16_mant.set_value_no_signal(new_mant_bits)
		
		var old_exp = current_item.fp_exp_bits if current_item.fp_exp_bits != -1 else config.fp16_exp_bits
		var old_mant = current_item.fp_mant_bits if current_item.fp_mant_bits != -1 else config.fp16_mant_bits
		var dict = _float_to_custom_fp_bits(current_item.value_float, old_exp, old_mant)
		var raw_bits = dict.bits
		
		current_item.fp_exp_bits = new_exp_bits
		current_item.fp_mant_bits = new_mant_bits
		
		var new_float = _custom_fp_bits_to_float(raw_bits, new_exp_bits, new_mant_bits)
		if current_item.has_method("set_value_by_type"):
			current_item.set_value_by_type(new_float, current_item.data_type)
		else:
			current_item.value_float = new_float
			if current_item.has_method("update_label_display"):
				current_item.update_label_display()
	
	_update_inspector_text()

func _update_inspector_text():
	if not current_item: return
	var item = current_item
	
	var text = "[b]Tipo:[/b] " + item.get_item_info()["tipo"] + "\n[b]Valor Atual:[/b] " + str(item.value_float if item.data_type in [item.DataType.FLOAT, item.DataType.DOUBLE, item.DataType.FP8, item.DataType.FP16] else item.value) + "\n\n"
	
	if item.data_type == item.DataType.INT or item.data_type == item.DataType.SHORT_INT or item.data_type == item.DataType.BINARY:
		var bits = 32 if item.data_type == item.DataType.INT else (16 if item.data_type == item.DataType.SHORT_INT else item.binary_bits)
		var bin_str = _int_to_bin_str(item.value, bits)
		text += "[b]Binário:[/b]\n" + _format_bytes(bin_str)
	elif item.data_type == item.DataType.FLOAT:
		var dict = _float_to_custom_fp_bits(item.value_float, 8, 23)
		text += _format_fp_text(dict, 8, 23)
	elif item.data_type == item.DataType.DOUBLE:
		var dict = _double_to_fp_bits(item.value_float)
		text += _format_fp_text(dict, 11, 52)
	elif item.data_type == item.DataType.FP8:
		var e_bits = item.fp_exp_bits if item.fp_exp_bits != -1 else config.fp8_exp_bits
		var m_bits = item.fp_mant_bits if item.fp_mant_bits != -1 else config.fp8_mant_bits
		var dict = _float_to_custom_fp_bits(item.value_float, e_bits, m_bits)
		text += _format_fp_text(dict, e_bits, m_bits)
	elif item.data_type == item.DataType.FP16:
		var e_bits = item.fp_exp_bits if item.fp_exp_bits != -1 else config.fp16_exp_bits
		var m_bits = item.fp_mant_bits if item.fp_mant_bits != -1 else config.fp16_mant_bits
		var dict = _float_to_custom_fp_bits(item.value_float, e_bits, m_bits)
		text += _format_fp_text(dict, e_bits, m_bits)
	else:
		text += "Não possui representação binária detalhada."
		
	insp_rt_label.text = text

func _format_bytes(bin_str: String) -> String:
	var out = ""
	for i in range(bin_str.length()):
		if i > 0 and i % 8 == 0:
			out += " "
		out += bin_str[i]
	return out

func _int_to_bin_str(val: int, bits: int) -> String:
	var s = ""
	for i in range(bits - 1, -1, -1):
		s += "1" if (val & (1 << i)) != 0 else "0"
	return s

func _float_to_custom_fp_bits(val: float, exp_bits: int, mant_bits: int) -> Dictionary:
	var bytes = PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, val)
	var f_bits = bytes.decode_u32(0)
	
	var sign = (f_bits >> 31) & 1
	var f_exp = (f_bits >> 23) & 0xFF
	var f_mant = f_bits & 0x7FFFFF
	
	var tgt_bias = (1 << (exp_bits - 1)) - 1
	var tgt_exp = 0
	var tgt_mant = 0
	
	if f_exp == 0xFF:
		tgt_exp = (1 << exp_bits) - 1
		tgt_mant = 1 if f_mant != 0 else 0
	elif f_exp == 0:
		tgt_exp = 0
		tgt_mant = 0
	else:
		var actual_exp = f_exp - 127
		tgt_exp = actual_exp + tgt_bias
		if tgt_exp >= (1 << exp_bits) - 1:
			tgt_exp = (1 << exp_bits) - 1
			tgt_mant = 0
		elif tgt_exp <= 0:
			tgt_exp = 0
			tgt_mant = 0
		else:
			if mant_bits <= 23:
				tgt_mant = f_mant >> (23 - mant_bits)
			else:
				tgt_mant = f_mant << (mant_bits - 23)
			
	var combined_bits = (sign << (exp_bits + mant_bits)) | (tgt_exp << mant_bits) | tgt_mant
	return {"sign": sign, "exp": tgt_exp, "mant": tgt_mant, "bits": combined_bits}

func _custom_fp_bits_to_float(bits: int, exp_bits: int, mant_bits: int) -> float:
	var sign = (bits >> (exp_bits + mant_bits)) & 1
	var tgt_exp = (bits >> mant_bits) & ((1 << exp_bits) - 1)
	var tgt_mant = bits & ((1 << mant_bits) - 1)
	
	var tgt_bias = (1 << (exp_bits - 1)) - 1
	
	var f_exp = 0
	var f_mant = 0
	
	if tgt_exp == ((1 << exp_bits) - 1): # Inf / NaN
		f_exp = 0xFF
		f_mant = 1 if tgt_mant != 0 else 0
	elif tgt_exp == 0: # Zero / Subnormal
		f_exp = 0
		f_mant = 0
	else:
		var actual_exp = tgt_exp - tgt_bias
		f_exp = actual_exp + 127
		if f_exp <= 0:
			f_exp = 0
		elif f_exp >= 0xFF:
			f_exp = 0xFF
			f_mant = 0
		else:
			if mant_bits <= 23:
				f_mant = tgt_mant << (23 - mant_bits)
			else:
				f_mant = tgt_mant >> (mant_bits - 23)
	
	var f_bits = (sign << 31) | (f_exp << 23) | f_mant
	var bytes = PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, f_bits)
	return bytes.decode_float(0)

func _double_to_fp_bits(val: float) -> Dictionary:
	var bytes = PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, val)
	var f_bits = bytes.decode_u64(0)
	var sign = (f_bits >> 63) & 1
	var f_exp = (f_bits >> 52) & 0x7FF
	var f_mant = f_bits & 0xFFFFFFFFFFFFF
	return {"sign": sign, "exp": f_exp, "mant": f_mant}

func _format_fp_text(dict: Dictionary, exp_bits: int, mant_bits: int) -> String:
	var s_str = "1" if dict.sign != 0 else "0"
	var e_str = ""
	for i in range(exp_bits - 1, -1, -1):
		e_str += "1" if (dict.exp & (1 << i)) != 0 else "0"
	var m_str = ""
	for i in range(mant_bits - 1, -1, -1):
		m_str += "1" if (dict.mant & (1 << i)) != 0 else "0"
		
	var bits_array = []
	bits_array.append({"bit": s_str, "color": "red"})
	for b in e_str: bits_array.append({"bit": b, "color": "green"})
	for b in m_str: bits_array.append({"bit": b, "color": "blue"})
	
	var bin_formatted = ""
	for i in range(bits_array.size()):
		if i > 0 and i % 8 == 0:
			bin_formatted += " "
		bin_formatted += "[color=" + bits_array[i].color + "]" + bits_array[i].bit + "[/color]"
	
	var out = "[b]Codificação Ponto Flutuante:[/b]\n"
	out += "[color=red]Sinal (1)[/color] | [color=green]Expoente (" + str(exp_bits) + ")[/color] | [color=blue]Mantissa (" + str(mant_bits) + ")[/color]\n"
	out += bin_formatted + "\n\n"
	
	var actual_exp = dict.exp - ((1 << (exp_bits - 1)) - 1)
	out += "Viés (Bias): " + str((1 << (exp_bits - 1)) - 1) + "\n"
	out += "Expoente Real: " + str(actual_exp)
	
	return out
