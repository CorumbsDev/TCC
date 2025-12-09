# DataHandler.gd
extends Node

var item_data = {
	# ===== NÚMEROS INTEIROS (INT) =====
	"item_number_0": {"Value": 0, "DataType": "INT"},
	"item_number_1": {"Value": 1, "DataType": "INT"},
	"item_number_2": {"Value": 2, "DataType": "INT"},
	"item_number_3": {"Value": 3, "DataType": "INT"},
	"item_number_4": {"Value": 4, "DataType": "INT"},
	"item_number_5": {"Value": 5, "DataType": "INT"},
	"item_number_6": {"Value": 6, "DataType": "INT"},
	"item_number_7": {"Value": 7, "DataType": "INT"},
	"item_number_8": {"Value": 8, "DataType": "INT"},
	"item_number_9": {"Value": 9, "DataType": "INT"},
	
	# ===== NÚMEROS DECIMAIS (FLOAT) =====
	"item_float_0.5": {"Value": 0.5, "DataType": "FLOAT"},
	"item_float_1.5": {"Value": 1.5, "DataType": "FLOAT"},
	"item_float_2.5": {"Value": 2.5, "DataType": "FLOAT"},
	"item_float_3.14": {"Value": 3.14, "DataType": "FLOAT"},
	"item_float_10.0": {"Value": 10.0, "DataType": "FLOAT"},
	"item_float_0.1": {"Value": 0.1, "DataType": "FLOAT"},
	
	# ===== VALORES BOOLEANOS =====
	"item_bool_true": {"Value": true, "DataType": "BOOLEAN"},
	"item_bool_false": {"Value": false, "DataType": "BOOLEAN"},
	
	# ===== STRINGS =====
	"item_string_hello": {"Value": "hello", "DataType": "STRING"},
	"item_string_world": {"Value": "world", "DataType": "STRING"},
	"item_string_test": {"Value": "test", "DataType": "STRING"},
	"item_string_empty": {"Value": "", "DataType": "STRING"},
	
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
	"item_function_sqrt": {"Operator": "sqrt"}
}
