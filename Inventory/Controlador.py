from py4godot.methods import private
from py4godot.signals import signal, SignalArg
from py4godot.classes import gdclass
from py4godot.classes.core import Vector3
from py4godot.classes.Control import Control
import re
import sys

# Função independente para avaliar expressões
def avaliar_expressao(expr: str) -> float:
	# Remove possíveis espaços em branco
	expr = expr.strip()
	# Verifica se a expressão contém apenas caracteres permitidos
	if not re.match(r'^[0-9\+\-\*\/\.\(\) ]+$', expr):
		return 0
	try:
		# Avalia a expressão
		return eval(expr)
	except Exception:
		return 0

@gdclass
class Controlador(Control):

	def _ready(self) -> None:
		# Exemplo de uso
		resultado = avaliar_expressao("7+7")
		print("Resultado:", resultado)  # Deve mostrar 14

if __name__ == "__main__":
	if len(sys.argv) > 1:
		expr = sys.argv[1]
		resultado = avaliar_expressao(expr)
		print(resultado)  # importante: o GDScript lê a saí