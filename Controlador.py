import re
import json
import sys
import math

# Quando o Godot chama com arquivo de entrada/saída, não poluir o console.
_QUIET = len(sys.argv) >= 3


def _log(*args) -> None:
	if not _QUIET:
		print(*args, file=sys.stderr)


def detectar_tipo_python(valor):
    """Detecta o tipo Python do valor e retorna como string do jogo."""
    tipo_python = type(valor).__name__
    tipo_map = {
        'int': 'INT',
        'float': 'FLOAT',
        'bool': 'INT',
        'str': 'STRING'
    }
    return tipo_map.get(tipo_python, 'FLOAT')


def _preprocessar_incrementos(expressao: str) -> str:
    """Converte ++/-- do jogo para (x+1)/(x-1) antes do eval."""
    expressao = re.sub(r'(\d+(?:\.\d+)?)\+\+', r'(\1+1)', expressao)
    expressao = re.sub(r'(\d+(?:\.\d+)?)--', r'(\1-1)', expressao)
    expressao = re.sub(r'\+\+(\d+(?:\.\d+)?)', r'(\1+1)', expressao)
    expressao = re.sub(r'--(\d+(?:\.\d+)?)', r'(\1-1)', expressao)
    # 5++3 (tokens colados) → (5+1)+3
    expressao = re.sub(r'\)(\d)', r')+\1', expressao)
    return expressao


def processar_expressao(expressao):
    """Processa uma expressão e retorna resultado com tipo."""
    try:
        expressao_proc = expressao
        # Conversores tokenizados pelo inventário (ex: 5+to_float+0)
        expressao_proc = re.sub(
            r'([0-9\.]+)\+?to_float\+?([0-9\.]*)',
            r'(float(\1)+0*\2)',
            expressao_proc,
            flags=re.IGNORECASE
        )
        expressao_proc = re.sub(
            r'([0-9\.]+)\+?to_int\+?([0-9\.]*)',
            r'(int(\1)+0*\2)',
            expressao_proc,
            flags=re.IGNORECASE
        )
        expressao_proc = re.sub(
            r'([0-9\.]+)\+?to_short\+?([0-9\.]*)',
            r'(int(\1)+0*\2)',
            expressao_proc,
            flags=re.IGNORECASE
        )
        expressao_proc = re.sub(r'to_float\(([^\)]+)\)', r'float(\1)', expressao_proc, flags=re.IGNORECASE)
        expressao_proc = re.sub(r'to_int\(([^\)]+)\)', r'int(\1)', expressao_proc, flags=re.IGNORECASE)
        expressao_proc = re.sub(r'to_short\(([^\)]+)\)', r'int(\1)', expressao_proc, flags=re.IGNORECASE)

        expressao_limpa = expressao_proc.replace(" ", "").replace("×", "*").replace("÷", "/")
        expressao_limpa = _preprocessar_incrementos(expressao_limpa)

        safe_dict = {
            'math': math,
            'sin': math.sin,
            'cos': math.cos,
            'tan': math.tan,
            'log': math.log,
            'sqrt': math.sqrt,
            'float': float,
            'int': int,
        }
        resultado = eval(expressao_limpa, {"__builtins__": {}}, safe_dict)

        tipo_resultado = detectar_tipo_python(resultado)
        if 'to_short' in expressao.lower():
            tipo_resultado = 'SHORT_INT'

        valor_resultado = resultado
        if tipo_resultado == 'INT' and isinstance(resultado, bool):
            valor_resultado = 1 if resultado else 0
        elif tipo_resultado in ('INT', 'SHORT_INT'):
            valor_resultado = int(resultado)
        elif tipo_resultado == 'FLOAT':
            valor_resultado = float(resultado)
        elif tipo_resultado == 'STRING':
            valor_resultado = str(resultado)

        return {
            'valor': valor_resultado,
            'tipo': tipo_resultado,
            'sucesso': True,
            'expressao_eval': expressao_limpa,
        }
    except Exception as e:
        _log(f"Erro ao processar expressão '{expressao}': {e}")
        return {
            'valor': None,
            'tipo': 'FLOAT',
            'sucesso': False,
            'erro': str(e)
        }


def gerar_codigo(expressao, resultado_info):
    """Gera código Python legível para a expressão."""
    try:
        tipo = resultado_info.get('tipo', 'FLOAT')
        expr_eval = resultado_info.get('expressao_eval', expressao)
        return f'''# Código gerado automaticamente
# Expressão (jogo): {expressao}
# Expressão (Python): {expr_eval}
# Tipo do resultado: {tipo}

def calcular():
    return {expr_eval}

resultado = calcular()
print("=== RESULTADO ===")
print(f"Expressão: {expressao}")
print(f"Tipo: {tipo}")
print(f"Resultado: {{resultado}}")
print(f"Tipo Python: {{type(resultado).__name__}}")

if __name__ == "__main__":
    calcular()'''.strip()
    except Exception as e:
        return f"# Erro ao gerar código: {str(e)}"


def main():
    if len(sys.argv) >= 3:
        arquivo_expressao = sys.argv[1]
        arquivo_resultado = sys.argv[2]
        try:
            with open(arquivo_expressao, 'r', encoding='utf-8') as f:
                expressao = f.read().strip()

            _log(f"Processando expressão: {expressao}")
            resultado_info = processar_expressao(expressao)
            codigo_gerado = gerar_codigo(expressao, resultado_info)

            dados = {
                "expressao": expressao,
                "resultado": resultado_info.get('valor', 0.0),
                "tipo": resultado_info.get('tipo', 'FLOAT'),
                "codigo": codigo_gerado,
                "sucesso": resultado_info.get('sucesso', False)
            }
            if not resultado_info.get('sucesso', False):
                dados["erro"] = resultado_info.get('erro', 'Erro desconhecido')
                dados["resultado"] = 0.0

            with open(arquivo_resultado, 'w', encoding='utf-8') as f:
                json.dump(dados, f, indent=2, ensure_ascii=False)

            _log(
                f"Resultado salvo: {expressao} = {resultado_info.get('valor')} "
                f"(tipo: {resultado_info.get('tipo')})"
            )
        except Exception as e:
            _log(f"Erro: {e}")
            dados_erro = {
                "expressao": expressao if 'expressao' in locals() else "Desconhecida",
                "resultado": 0.0,
                "tipo": "FLOAT",
                "codigo": f"Erro: {str(e)}",
                "sucesso": False,
                "erro": str(e)
            }
            with open(arquivo_resultado, 'w', encoding='utf-8') as f:
                json.dump(dados_erro, f, indent=2, ensure_ascii=False)
    else:
        print("=== CONTROLADOR DE EXPRESSÕES (Code Orbs) ===")
        print("Uso: python Controlador.py <arquivo_expressao> <arquivo_resultado>")
        for expr in ["5+5", "5++3", "++5", "0b1010", "5++ + 3"]:
            info = processar_expressao(expr)
            print(f"  {expr} -> {info}")


if __name__ == "__main__":
    main()
