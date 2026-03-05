# DataHandler.gd
extends Node

# Tamanho em bytes por tipo (para Fase 2 - Mochila): INT=1, DOUBLE=2, BINARY=ceil(bits/8), etc.
var item_data = {
	# ===== NÚMEROS INTEIROS (INT) =====
	"item_number_0": {"Value": 0, "DataType": "INT", "Bytes": 1},
	"item_number_1": {"Value": 1, "DataType": "INT", "Bytes": 1},
	"item_number_2": {"Value": 2, "DataType": "INT", "Bytes": 1},
	"item_number_3": {"Value": 3, "DataType": "INT", "Bytes": 1},
	"item_number_4": {"Value": 4, "DataType": "INT", "Bytes": 1},
	"item_number_5": {"Value": 5, "DataType": "INT", "Bytes": 1},
	"item_number_6": {"Value": 6, "DataType": "INT", "Bytes": 1},
	"item_number_7": {"Value": 7, "DataType": "INT", "Bytes": 1},
	"item_number_8": {"Value": 8, "DataType": "INT", "Bytes": 1},
	"item_number_9": {"Value": 9, "DataType": "INT", "Bytes": 1},
	
	# ===== NÚMEROS DECIMAIS (FLOAT) =====
	"item_float_0.5": {"Value": 0.5, "DataType": "FLOAT", "Bytes": 1},
	"item_float_1.5": {"Value": 1.5, "DataType": "FLOAT", "Bytes": 1},
	"item_float_2.5": {"Value": 2.5, "DataType": "FLOAT", "Bytes": 1},
	"item_float_3.14": {"Value": 3.14, "DataType": "FLOAT", "Bytes": 1},
	"item_float_10.0": {"Value": 10.0, "DataType": "FLOAT", "Bytes": 1},
	"item_float_0.1": {"Value": 0.1, "DataType": "FLOAT", "Bytes": 1},
	
	# ===== VALORES BOOLEANOS =====
	"item_bool_true": {"Value": true, "DataType": "BOOLEAN", "Bytes": 1},
	"item_bool_false": {"Value": false, "DataType": "BOOLEAN", "Bytes": 1},
	
	# ===== STRINGS =====
	"item_string_hello": {"Value": "hello", "DataType": "STRING", "Bytes": 1},
	"item_string_world": {"Value": "world", "DataType": "STRING", "Bytes": 1},
	"item_string_test": {"Value": "test", "DataType": "STRING", "Bytes": 1},
	"item_string_empty": {"Value": "", "DataType": "STRING", "Bytes": 1},
	
	# ===== OPERADORES =====
	"item_operator_plus": {"Operator": "+"},
	"item_operator_minus": {"Operator": "-"},
	"item_operator_multiply": {"Operator": "*"},
	"item_operator_divide": {"Operator": "/"},
	"item_operator_power": {"Operator": "**"},
	"item_operator_increment": {"Operator": "++"},
	"item_operator_decrement": {"Operator": "--"},
	"item_operator_and": {"Operator": "&"},
	"item_operator_or": {"Operator": "|"},
	"item_operator_shiftleft": {"Operator": "<<"},
	"item_operator_shiftright": {"Operator": ">>"},
	"item_function_sin": {"Operator": "sin"},
	"item_function_cos": {"Operator": "cos"},
	"item_function_sqrt": {"Operator": "sqrt"},
	
	# ===== DOUBLE (Precisão Dupla - ocupa 2 slots = 2 bytes) =====
	"item_double_3.14159": {"Value": 3.14159265, "DataType": "DOUBLE", "Bytes": 2},
	"item_double_2.71828": {"Value": 2.71828182, "DataType": "DOUBLE", "Bytes": 2},
	"item_double_1.41421": {"Value": 1.41421356, "DataType": "DOUBLE", "Bytes": 2},
	
	# ===== BINARY (Binário - tamanho em bytes = ceil(bits/8)) =====
	"item_binary_0": {"Value": 0, "DataType": "BINARY", "Bits": 1, "Bytes": 1},
	"item_binary_1": {"Value": 1, "DataType": "BINARY", "Bits": 1, "Bytes": 1},
	"item_binary_10": {"Value": 2, "DataType": "BINARY", "Bits": 2, "Bytes": 1},
	"item_binary_11": {"Value": 3, "DataType": "BINARY", "Bits": 2, "Bytes": 1},
	"item_binary_5": {"Value": 5, "DataType": "BINARY", "Bits": 3, "Bytes": 1},
	"item_binary_1010": {"Value": 10, "DataType": "BINARY", "Bits": 4, "Bytes": 1},
	"item_binary_42": {"Value": 42, "DataType": "BINARY", "Bits": 6, "Bytes": 1},
	"item_binary_255": {"Value": 255, "DataType": "BINARY", "Bits": 8, "Bytes": 1}
}

func get_item_bytes(item_id: String) -> int:
	"""Retorna o tamanho em bytes do item (para Fase 2 - Mochila)."""
	if not item_data.has(item_id):
		return 1
	var data = item_data[item_id]
	if data.has("Bytes"):
		return int(data["Bytes"])
	if data.has("Bits"):
		return int(ceil(float(data["Bits"]) / 8.0))
	if data.has("DataType"):
		match str(data["DataType"]).to_upper():
			"DOUBLE":
				return 2
	return 1
