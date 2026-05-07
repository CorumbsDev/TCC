extends Node

const ITEM_JSON_PATH := "res://Inventory/Data/Item_data.json"
const _ConfigGeneratorScript = preload("res://Inventory/fases/config_generator.gd")

var item_data: Dictionary = {}

func _ready():
	randomize()
	_init_item_data()
	_merge_item_definitions_from_json(ITEM_JSON_PATH)
	_ConfigGeneratorScript.init_with_data_handler(self)


func _init_item_data():
	item_data = {
		"item_number_1": {"Value": 1, "DataType": "INT", "Bytes": 1},
		"item_number_2": {"Value": 2, "DataType": "INT", "Bytes": 1},
		"item_number_3": {"Value": 3, "DataType": "INT", "Bytes": 1},
		"item_number_5": {"Value": 5, "DataType": "INT", "Bytes": 1},
		"item_number_7": {"Value": 7, "DataType": "INT", "Bytes": 1},
		"item_number_10": {"Value": 10, "DataType": "INT", "Bytes": 1},
		"item_operator_plus": {"Operator": "+"},
		"item_operator_increment": {"Operator": "++"},
		"item_double_3.14159": {"Value": 3.14159, "DataType": "FLOAT", "Bytes": 8},
		"item_binary_10": {"Value": 10, "DataType": "BINARY", "Bits": 4, "Bytes": 1},
		"item_binary_42": {"Value": 42, "DataType": "BINARY", "Bits": 6, "Bytes": 1},
		"item_binary_0": {"Value": 0, "DataType": "BINARY", "Bits": 1, "Bytes": 1},
		"item_binary_1": {"Value": 1, "DataType": "BINARY", "Bits": 1, "Bytes": 1},
		"item_operator_to_float": {"Operator": "to_float"},
		"item_operator_to_int": {"Operator": "to_int"}
	}


func _merge_item_definitions_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var raw := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for item_id in parsed:
		item_data[str(item_id)] = _json_row_to_item_entry(parsed[item_id])


func _json_row_to_item_entry(row: Variant) -> Dictionary:
	if typeof(row) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = row
	var op := str(d.get("Operator", "")).strip_edges()
	if op != "":
		return {"Operator": op}
	var out = {}
	out["DataType"] = str(d.get("DataType", "INT")).to_upper()
	out["Value"] = d.get("Value", 0)
	if d.has("Bytes"):
		out["Bytes"] = int(d["Bytes"])
	if d.has("Bits"):
		out["Bits"] = int(d["Bits"])
	return out


func get_item_bytes(item_id: String) -> int:
	if not item_data.has(item_id):
		return 1
	var data = item_data[item_id]
	if data.has("Bytes"):
		return int(data["Bytes"])
	if data.has("Bits"):
		return int(ceil(float(data["Bits"]) / 8.0))
	return 1


# Generator methods
func generate_knapsack_config(capacity: int = 8, backpack_slots: int = 8, pool_slots: int = 10, grid_cols: int = 4, int_min: int = 1, int_max: int = 10, initial_csv: String = "1_i,2_i", random_pool_size: int = 4, use_converter: bool = false) -> PhaseConfig:
	return ConfigGenerator.generate_knapsack_config(capacity, backpack_slots, pool_slots, grid_cols, int_min, int_max, initial_csv, random_pool_size, use_converter)

func generate_sequence(num_phases: int, mix_types: bool = true, base_params: Dictionary = {}) -> Array:
	return ConfigGenerator.generate_sequence(num_phases, mix_types, base_params)

func generate_binary_config(left_bit: int = 1, right_bit: int = 0) -> BinaryPhaseConfig:
	return ConfigGenerator.generate_binary_config(left_bit, right_bit)
