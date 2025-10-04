import re
import os
import json
import sys
import math

class ProcessadorExpressoes:
	def __init__(self):
		self.operadores_suportados = {
			'+', '-', '*', '/', '**', '//', '%',
			'&', '|', '^', '~', '<<', '>>',
			'++', '--', 'sin', 'cos', 'tan', 'log', 'sqrt'
		}
	
	def tokenizar_expressao(self, expressao):
		"""Tokeniza a expressão incluindo operadores especiais e funções"""
		# Padrão para números, operadores, funções e variáveis
		pattern = r'''
			\d+\.?\d*|           # Números (inteiros e decimais)
			[a-zA-Z_][a-zA-Z0-9_]*|  # Funções e variáveis
			\*\*|//|<<|>>|       # Operadores multi-caractere
			[+\-*/%&|^~()]|      # Operadores e parênteses
			\+\+|--              # Incremento/decremento
		'''
		tokens = re.findall(pattern, expressao, re.VERBOSE)
		return [token for token in tokens if token.strip()]
	
	def preprocessar_expressao(self, tokens):
		"""Pré-processa tokens para lidar com operadores especiais"""
		novos_tokens = []
		i = 0
		
		while i < len(tokens):
			token = tokens[i]
			
			# Handle incremento/decremento
			if token == '++':
				if i > 0 and tokens[i-1].replace('.', '').isdigit():
					# Pós-incremento: x++ → (x + 1)
					num = novos_tokens.pop()
					novos_tokens.extend(['(', num, '+', '1', ')'])
				elif i + 1 < len(tokens) and tokens[i+1].replace('.', '').isdigit():
					# Pré-incremento: ++x → (x + 1)
					novos_tokens.extend(['(', tokens[i+1], '+', '1', ')'])
					i += 1
				else:
					novos_tokens.append(token)
			
			elif token == '--':
				if i > 0 and tokens[i-1].replace('.', '').isdigit():
					# Pós-decremento: x-- → (x - 1)
					num = novos_tokens.pop()
					novos_tokens.extend(['(', num, '-', '1', ')'])
				elif i + 1 < len(tokens) and tokens[i+1].replace('.', '').isdigit():
					# Pré-decremento: --x → (x - 1)
					novos_tokens.extend(['(', tokens[i+1], '-', '1', ')'])
					i += 1
				else:
					novos_tokens.append(token)
			
			# Handle funções matemáticas
			elif token in ['sin', 'cos', 'tan', 'log', 'sqrt']:
				if i + 2 < len(tokens) and tokens[i+1] == '(':
					# Encontra o parêntese de fechamento correspondente
					j = i + 2
					paren_count = 1
					while j < len(tokens) and paren_count > 0:
						if tokens[j] == '(':
							paren_count += 1
						elif tokens[j] == ')':
							paren_count -= 1
						j += 1
					
					# Processa o conteúdo dos parênteses
					conteudo = tokens[i+2:j-1]
					conteudo_processado = self.preprocessar_expressao(conteudo)
					expressao_interna = ''.join(conteudo_processado)
					
					# Converte para chamada de função Python
					if token == 'sin':
						novos_tokens.append(f'math.sin({expressao_interna})')
					elif token == 'cos':
						novos_tokens.append(f'math.cos({expressao_interna})')
					elif token == 'tan':
						novos_tokens.append(f'math.tan({expressao_interna})')
					elif token == 'log':
						novos_tokens.append(f'math.log({expressao_interna})')
					elif token == 'sqrt':
						novos_tokens.append(f'math.sqrt({expressao_interna})')
					
					i = j
				else:
					novos_tokens.append(token)
			
			# Handle operadores bit a bit
			elif token in ['&', '|', '^', '~', '<<', '>>']:
				novos_tokens.append(token)
			
			else:
				novos_tokens.append(token)
			
			i += 1
		
		return novos_tokens
	
	def processar_expressao(self, expressao):
		"""Processa uma expressão matemática complexa"""
		try:
			# Remove espaços e padroniza operadores
			expressao = expressao.replace(" ", "").replace("×", "*").replace("÷", "/")
			
			# Tokeniza e pré-processa
			tokens = self.tokenizar_expressao(expressao)
			tokens_processados = self.preprocessar_expressao(tokens)
			expressao_final = ''.join(tokens_processados)
			
			print(f"Expressão original: {expressao}")
			print(f"Expressão processada: {expressao_final}")
			
			# Ambiente seguro para eval
			safe_dict = {
				'math': math,
				'sin': math.sin,
				'cos': math.cos,
				'tan': math.tan,
				'log': math.log,
				'sqrt': math.sqrt,
				'__builtins__': {}
			}
			
			# Avalia a expressão
			resultado = eval(expressao_final, safe_dict)
			return float(resultado)
			
		except Exception as e:
			print(f"Erro ao processar expressão '{expressao}': {e}")
			return None

def gerar_codigo(expressao, resultado):
	"""Gera código Python para a expressão computacional"""
	try:
		processador = ProcessadorExpressoes()
		tokens = processador.tokenizar_expressao(expressao.replace(" ", ""))
		tokens_processados = processador.preprocessar_expressao(tokens)
		expressao_final = ''.join(tokens_processados)
		
		codigo = f"""
# CÓDIGO GERADO - EXPRESSÃO COMPUTACIONAL
# Expressão original: {expressao}
# Expressão processada: {expressao_final}

import math

# Variáveis e operações
{expressao_final}

print("=== EXPRESSÃO COMPUTACIONAL ===")
print(f"Original: {expressao}")
print(f"Processada: {expressao_final}")
print(f"Resultado: {{resultado}}")

# Resultado final
resultado = {expressao_final}
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
			processador = ProcessadorExpressoes()
			resultado = processador.processar_expressao(expressao)
			
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
			dados_erro = {
				"expressao": expressao if 'expressao' in locals() else "Desconhecida",
				"resultado": 0.0,
				"codigo": f"Erro: {str(e)}",
				"sucesso": False
			}
			with open(arquivo_resultado, 'w', encoding='utf-8') as f:
				json.dump(dados_erro, f, indent=2, ensure_ascii=False)
	else:
		print("=== PROCESSADOR DE EXPRESSÕES COMPUTACIONAIS ===")
		print("Uso: python Controlador.py <arquivo_expressao> <arquivo_resultado>")
		
		# Modo de teste interativo
		processador = ProcessadorExpressoes()
		testes = [
			"5++ + 3",           # Pós-incremento
			"++5 * 2",           # Pré-incremento  
			"10 >> 1",           # Shift right
			"5 & 3",             # AND bit a bit
			"5 | 2",             # OR bit a bit
			"sin(0)",            # Função seno
			"sqrt(16)",          # Raiz quadrada
			"5 + 3 * 2",         # Precedência
			"(5 + 3) * 2"        # Parênteses
		]
		
		for expressao_teste in testes:
			resultado_teste = processador.processar_expressao(expressao_teste)
			codigo_teste = gerar_codigo(expressao_teste, resultado_teste)
			
			print(f"\n{'='*50}")
			print(f"Teste: '{expressao_teste}'")
			print(f"Resultado: {resultado_teste}")
			print(f"Código:\n{codigo_teste}")

if __name__ == "__main__":
	main()
