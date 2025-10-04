import re
import os
import json
import sys

def processar_expressao(expressao):
    """Processa uma expressão matemática simples"""
    try:
        # Remove espaços e padroniza operadores
        expressao = expressao.replace(" ", "").replace("×", "*").replace("÷", "/")
        
        # Avaliação segura
        resultado = eval(expressao)
        return float(resultado)
    except Exception as e:
        print(f"Erro ao processar expressão '{expressao}': {e}")
        return None

def gerar_codigo(expressao, resultado):
    """Gera código Python para a expressão"""
    try:
        codigo = f"""
# Código gerado automaticamente
# Expressão: {expressao}

def calcular():
    return {expressao}

resultado = calcular()
print("=== RESULTADO ===")
print(f"Expressão: {expressao}")
print(f"Resultado: {{resultado}}")

if __name__ == "__main__":
    calcular()
"""
        return codigo.strip()
    except Exception as e:
        return f"# Erro ao gerar código: {str(e)}"

def main():
    if len(sys.argv) >= 3:
        arquivo_expressao = sys.argv[1]
        arquivo_resultado = sys.argv[2]
        
        try:
            # Lê a expressão do arquivo
            with open(arquivo_expressao, 'r', encoding='utf-8') as f:
                expressao = f.read().strip()
            
            print(f"Processando expressão: {expressao}")
            
            # Processa a expressão
            resultado = processar_expressao(expressao)
            
            # Gera o código
            codigo_gerado = gerar_codigo(expressao, resultado)
            
            # Prepara os dados do resultado
            dados = {
                "expressao": expressao,
                "resultado": resultado if resultado is not None else 0.0,
                "codigo": codigo_gerado,
                "sucesso": resultado is not None
            }
            
            # Salva o resultado
            with open(arquivo_resultado, 'w', encoding='utf-8') as f:
                json.dump(dados, f, indent=2, ensure_ascii=False)
            
            print(f"Resultado salvo: {expressao} = {resultado}")
                
        except Exception as e:
            print(f"Erro: {e}")
            # Salva um resultado de erro
            dados_erro = {
                "expressao": expressao if 'expressao' in locals() else "Desconhecida",
                "resultado": 0.0,
                "codigo": f"Erro: {str(e)}",
                "sucesso": False
            }
            with open(arquivo_resultado, 'w', encoding='utf-8') as f:
                json.dump(dados_erro, f, indent=2, ensure_ascii=False)
    else:
        print("=== GERADOR DE CÓDIGO PYTHON ===")
        print("Uso: python Controlador.py <arquivo_expressao> <arquivo_resultado>")
        
        # Modo de teste interativo
        expressao_teste = "5+5"
        resultado_teste = processar_expressao(expressao_teste)
        codigo_teste = gerar_codigo(expressao_teste, resultado_teste)
        
        print(f"\nTeste com '{expressao_teste}':")
        print(f"Resultado: {resultado_teste}")
        print(f"Código:\n{codigo_teste}")

if __name__ == "__main__":
    main()