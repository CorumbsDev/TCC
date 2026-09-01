class_name ConversionPhaseConfig
extends Resource

## Quantidade de bits do alvo (MSB à esquerda). Ajustado automaticamente se algum desafio não couber.
@export_range(1, 16) var num_bits: int = 3
## Decimais a converter, em ordem (ex: 5, 3, 6).
@export var challenge_decimals: Array[int] = [5, 3, 6]
## Delay entre desafios corretos (segundos).
@export var advance_delay_seconds: float = 2.4


func apply_constraints() -> void:
	num_bits = clampi(num_bits, 1, 16)
	advance_delay_seconds = maxf(advance_delay_seconds, 0.3)
	if challenge_decimals == null or challenge_decimals.is_empty():
		challenge_decimals = [5, 3, 6]
	else:
		var normalized: Array[int] = []
		for v in challenge_decimals:
			normalized.append(maxi(0, int(v)))
		challenge_decimals = normalized


func challenges_csv() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for v in challenge_decimals:
		parts.append(str(int(v)))
	return ", ".join(parts)


func set_challenges_from_csv(text: String) -> void:
	var out: Array[int] = []
	for p in text.split(",", false):
		var s := p.strip_edges()
		if s.is_empty():
			continue
		if s.is_valid_int():
			out.append(maxi(0, int(s)))
	challenge_decimals = out if not out.is_empty() else [5, 3, 6]
