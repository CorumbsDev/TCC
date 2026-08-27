class_name RawKnapsackPhaseConfig
extends Resource

## Mochila: capacidade e grade do desafio.
@export var capacity_bytes: int = 8
@export var grid_columns: int = 4
@export var backpack_slot_count: int = 8
@export var pool_slot_count: int = 10
@export var pool_grid_columns: int = 5

## Valores sem tipo no pool (ex: "42", "3.14", "0.5").
@export var initial_raw_values: PackedStringArray = PackedStringArray(["7", "3.14", "42"])
@export var randomize_values: bool = false

## Tipos que o aluno pode escolher nas estações de tipagem.
@export var allow_int: bool = true
@export var allow_short: bool = false
@export var allow_float: bool = true
@export var allow_double: bool = false
@export var allow_fp8: bool = false
@export var allow_fp16: bool = false

@export var fp8_exp_bits: int = 4
@export var fp8_mant_bits: int = 3
@export var fp16_exp_bits: int = 5
@export var fp16_mant_bits: int = 10

## Limite de movimentos para ganhar a 2ª estrela. 0 significa que não é exigido.
@export var star2_max_moves: int = 0
## Solução ideal (CSV de atalhos) para ganhar a 3ª estrela. Vazio significa que não é exigido.
@export var star3_best_solution_csv: String = ""

func apply_constraints() -> void:
	capacity_bytes = clampi(capacity_bytes, 1, 4096)
	grid_columns = clampi(grid_columns, 1, 64)
	backpack_slot_count = clampi(backpack_slot_count, 1, 512)
	pool_slot_count = clampi(pool_slot_count, 1, 512)
	pool_grid_columns = clampi(pool_grid_columns, 1, 64)
