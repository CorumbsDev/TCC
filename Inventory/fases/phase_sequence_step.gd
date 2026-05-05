class_name PhaseSequenceStep
extends Resource

enum Kind { MOCHILA, BINARIO }

## Tipo de fase na sequência.
@export var kind: Kind = Kind.MOCHILA
## Preencher quando kind == MOCHILA (pode ficar null para usar defaults da mochila).
@export var config_mochila: PhaseConfig
## Preencher quando kind == BINARIO (pode ficar null para padrão 1 _ 0).
@export var config_binario: BinaryPhaseConfig
