class_name PhaseSequenceStep
extends Resource

enum Kind { MOCHILA, BINARIO, TYPE_BOX, RAW_MOCHILA }

## Tipo de fase na sequência.
@export var kind: Kind = Kind.MOCHILA
## Preencher quando kind == MOCHILA (pode ficar null para usar defaults da mochila).
@export var config_mochila: PhaseConfig
## Preencher quando kind == BINARIO (pode ficar null para padrão 1 _ 0).
@export var config_binario: BinaryPhaseConfig
## Preencher quando kind == TYPE_BOX
@export var config_type_box: TypeBoxPhaseConfig
## Preencher quando kind == RAW_MOCHILA (mochila + orbes RAW para tipar).
@export var config_raw_mochila: RawKnapsackPhaseConfig
