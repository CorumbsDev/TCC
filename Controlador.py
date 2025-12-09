import re
import os
import json
import sys

def detectar_tipo_python(valor):
    """Detecta o tipo Python do valor e retorna como string"""
    tipo_python = type(valor).__name__
    
    # Mapeia tipos Python para tipos do jogo
    tipo_map = {
        'int': 'INT',
        'float': 'FLOAT',
        'bool': 'BOOLEAN',
        'str': 'STRING'
    }
    
    return tipo_map.get(tipo_python, 'FLOAT')  # Default para FLOAT

def processar_expressao(expressao):
    """Processa uma expressão e retorna resultado com tipo"""
    try:
        # Remove espaços e padroniza operadores
        expressao_limpa = expressao.replace(" ", "").replace("×", "*").replace("÷", "/")
        
        # Remove aspas das strings se necessário para eval
        # Mas preserva strings entre aspas
        expressao_para_eval = expressao_limpa
        
        # Avaliação segura
        resultado = eval(expressao_para_eval)
        
        # Detecta o tipo do resultado
        tipo_resultado = detectar_tipo_python(resultado)
        
        # Prepara o valor baseado no tipo
        valor_resultado = resultado
        
        # Converte para formato JSON-safe
        if tipo_resultado == 'BOOLEAN':
            valor_resultado = bool(resultado)
        elif tipo_resultado == 'INT':
            valor_resultado = int(resultado)
        elif tipo_resultado == 'FLOAT':
            valor_resultado = float(resultado)
        elif tipo_resultado == 'STRING':
            valor_resultado = str(resultado)
        
        return {
            'valor': valor_resultado,
            'tipo': tipo_resultado,
            'sucesso': True
        }
    except Exception as e:
        print(f"Erro ao processar expressão '{expressao}': {e}")
        return {
            'valor': None,
            'tipo': 'FLOAT',
            'sucesso': False,
            'erro': str(e)
        }

def gerar_codigo(expressao, resultado_info):
    """Gera código Python para a expressão"""
    try:
        tipo = resultado_info.get('tipo', 'FLOAT')
        valor = resultado_info.get('valor', 0.0)
        
        codigo = f"""
# Código gerado automaticamente
# Expressão: {expressao}
# Tipo do resultado: {tipo}

def calcular():
    return {expressao}

resultado = calcular()
print("=== RESULTADO ===")
print(f"Expressão: {expressao}")
print(f"Tipo: {tipo}")
print(f"Resultado: {{resultado}}")
print(f"Tipo Python: {{type(resultado).__name__}}")

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
            resultado_info = processar_expressao(expressao)
            
            # Gera o código
            codigo_gerado = gerar_codigo(expressao, resultado_info)
            
            # Prepara os dados do resultado
            dados = {
                "expressao": expressao,
                "resultado": resultado_info.get('valor', 0.0),
                "tipo": resultado_info.get('tipo', 'FLOAT'),
                "codigo": codigo_gerado,
                "sucesso": resultado_info.get('sucesso', False)
            }
            
            # Adiciona erro se houver
            if not resultado_info.get('sucesso', False):
                dados["erro"] = resultado_info.get('erro', 'Erro desconhecido')
            
            # Salva o resultado
            with open(arquivo_resultado, 'w', encoding='utf-8') as f:
                json.dump(dados, f, indent=2, ensure_ascii=False)
            
            print(f"Resultado salvo: {expressao} = {resultado_info.get('valor')} (tipo: {resultado_info.get('tipo')})")
                
        except Exception as e:
            print(f"Erro: {e}")
            # Salva um resultado de erro
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
        print("=== GERADOR DE CÓDIGO PYTHON ===")
        print("Uso: python Controlador.py <arquivo_expressao> <arquivo_resultado>")
        
        # Modo de teste interativo
        expressao_teste = "5+5"
        resultado_teste = processar_expressao(expressao_teste)
        codigo_teste = gerar_codigo(expressao_teste, resultado_teste)
        
        print(f"\nTeste com '{expressao_teste}':")
        print(f"Resultado: {resultado_teste.get('valor')}")
        print(f"Tipo: {resultado_teste.get('tipo')}")
        print(f"Código:\n{codigo_teste}")

if __name__ == "__main__":
    main()