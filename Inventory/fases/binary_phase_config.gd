class_name BinaryPhaseConfig
extends Resource

## Bits fixos ao redor do espaço central (orb que o jogador preenche).
@export_range(0, 1) var fixed_left_bit: int = 1
@export_range(0, 1) var fixed_right_bit: int = 0


func apply_constraints() -> void:
	fixed_left_bit = clampi(fixed_left_bit, 0, 1)
	fixed_right_bit = clampi(fixed_right_bit, 0, 1)


func left_digit_string() -> String:
	return str(fixed_left_bit)


func right_digit_string() -> String:
	return str(fixed_right_bit)
