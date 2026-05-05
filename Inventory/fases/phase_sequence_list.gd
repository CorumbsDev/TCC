class_name PhaseSequenceList
extends Resource

## Lista de passos (mochila ou binário). Edite no Inspector ou neste arquivo .tres — sem precisar alterar código.
@export var steps: Array[PhaseSequenceStep] = []


## Retorna a lista para o PhaseRunner (cada passo referencia sub-resources do .tres).
func to_runtime_array() -> Array:
	var out: Array = []
	for s in steps:
		if s is PhaseSequenceStep:
			out.append(s)
	return out
