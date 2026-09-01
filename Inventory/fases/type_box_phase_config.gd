class_name TypeBoxPhaseConfig
extends Resource

## Capacidade total em bytes permitida para a fase (soma de todas as caixas).
@export var capacity_bytes: int = 8

## Valores puros iniciais que o jogador deve tipar. (ex: "250_raw", "3.14_raw").
@export var initial_raw_values: PackedStringArray = PackedStringArray()

## Se verdadeiro, gera valores aleatórios "interessantes" ignorando initial_raw_values.
@export var randomize_values: bool = false

## Quantidade de espaços (slots) visíveis em cada caixa de tipagem.
@export var box_slot_count: int = 5

## Caixas (tipos) permitidas na fase.
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

## Tipos esperados por valor RAW (paralelo a initial_raw_values). Ex.: int,float,int
## Vazio = só valida bytes totais.
@export var expected_solution_types: PackedStringArray = PackedStringArray()

func apply_constraints() -> void:
	capacity_bytes = clampi(capacity_bytes, 1, 4096)
	box_slot_count = clampi(box_slot_count, 1, 64)
