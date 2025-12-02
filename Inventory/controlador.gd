extends Node
class_name ControladorExterno

# Signal atualizado para incluir tipo do resultado
signal expressao_processada(resultado: Variant, tipo_resultado: String, codigo: String)

var ultima_expressao: String = ""
var arquivo_resultado: String = "user://resultado.json"

func _ready():
	print("Controlador Externo carregado")

func processar_expressao_assincrona(expressao: String):
	ultima_expressao = expressao
	
	# Salva a expressão em um arquivo temporário
	var arquivo_expressao = "user://temp_expr_%s.txt" % Time.get_unix_time_from_system()
	
	if not salvar_expressao(expressao, arquivo_expressao):
		# Fallback se não conseguir salvar
		var resultado_info = avaliar_expressao_rapida(expressao)
		expressao_processada.emit(resultado_info.resultado, resultado_info.tipo, "Erro ao salvar: " + expressao)
		return
	
	# Executa o Python
	var script_path = ProjectSettings.globalize_path("res://Controlador.py")
	var expressao_path = ProjectSettings.globalize_path(arquivo_expressao)
	var resultado_path = ProjectSettings.globalize_path(arquivo_resultado)
	
	var args = [script_path, expressao_path, resultado_path]
	var output = []
	
	print("Executando Python...")
	
	# Tenta com 'python' primeiro, depois com 'py' como fallback
	var exit_code = OS.execute("python", args, output, true)
	
	if exit_code != 0:
		print("Tentando com 'py'...")
		exit_code = OS.execute("py", args, output, true)
	
	print("Saída do Python: ", output)
	print("Código de saída: ", exit_code)
	
	if exit_code == 0:
		# Pequeno delay para garantir que o arquivo foi escrito
		await get_tree().create_timer(0.2).timeout
		ler_resultado_json()
	else:
		print("Erro na execução do Python")
		# Fallback para avaliação rápida
		var resultado_info = avaliar_expressao_rapida(ultima_expressao)
		expressao_processada.emit(resultado_info.resultado, resultado_info.tipo, "Erro Python: " + ultima_expressao)

func salvar_expressao(expressao: String, caminho: String) -> bool:
	var dir = DirAccess.open("user://")
	if dir:
		var arquivo = FileAccess.open(caminho, FileAccess.WRITE)
		if arquivo:
			arquivo.store_string(expressao)
			arquivo.close()
			print("Expressão salva: ", caminho)
			return true
		else:
			print("Erro ao salvar expressão em: ", caminho)
			return false
	else:
		print("Não foi possível abrir o diretório user://")
		return false

func ler_resultado_json():
	var arquivo = FileAccess.open(arquivo_resultado, FileAccess.READ)
	if arquivo:
		var conteudo = arquivo.get_as_text()
		arquivo.close()
		
		print("Conteúdo do arquivo JSON: ", conteudo)
		
		var json_resultado = JSON.new()
		var erro = json_resultado.parse(conteudo)
		
		if erro == OK:
			var dados = json_resultado.data
			var resultado = dados.get("resultado", 0.0)
			var tipo = dados.get("tipo", "FLOAT")
			var codigo = dados.get("codigo", "")
			var sucesso = dados.get("sucesso", false)
			
			print("Expressão processada: ", dados.get("expressao", ""))
			print("Resultado: ", resultado)
			print("Tipo: ", tipo)
			print("Sucesso: ", sucesso)
			
			if sucesso:
				# Converte o resultado para o tipo correto
				var resultado_convertido = converter_resultado_para_tipo(resultado, tipo)
				expressao_processada.emit(resultado_convertido, tipo, codigo)
			else:
				# Se não foi bem-sucedido, usa fallback
				var resultado_info = avaliar_expressao_rapida(ultima_expressao)
				expressao_processada.emit(resultado_info.resultado, resultado_info.tipo, "Fallback: " + ultima_expressao)
		else:
			print("Erro ao analisar JSON: ", erro)
			# Fallback
			var resultado_info = avaliar_expressao_rapida(ultima_expressao)
			expressao_processada.emit(resultado_info.resultado, resultado_info.tipo, "Erro JSON: " + ultima_expressao)
	else:
		print("Arquivo de resultado não encontrado: ", arquivo_resultado)
		# Fallback
		var resultado_info = avaliar_expressao_rapida(ultima_expressao)
		expressao_processada.emit(resultado_info.resultado, resultado_info.tipo, "Arquivo não encontrado: " + ultima_expressao)

func converter_resultado_para_tipo(valor: Variant, tipo: String) -> Variant:
	"""Converte o valor para o tipo correto"""
	match tipo:
		"INT":
			return int(valor)
		"FLOAT":
			return float(valor)
		"BOOLEAN":
			if typeof(valor) == TYPE_BOOL:
				return bool(valor)
			elif typeof(valor) == TYPE_INT or typeof(valor) == TYPE_FLOAT:
				return bool(valor)
			else:
				return bool(valor)
		"STRING":
			return str(valor)
		_:
			return float(valor)

func avaliar_expressao_rapida(expressao: String) -> Dictionary:
	"""Avaliação simples em GDScript com detecção de tipo"""
	expressao = expressao.replace("×", "*").replace("÷", "/").replace(" ", "")
	
	# Tenta detectar strings
	if expressao.begins_with('"') and expressao.ends_with('"'):
		var str_valor = expressao.substr(1, expressao.length() - 2)
		return {"resultado": str_valor, "tipo": "STRING"}
	
	# Tenta detectar booleanos
	if expressao.to_lower() == "true":
		return {"resultado": true, "tipo": "BOOLEAN"}
	if expressao.to_lower() == "false":
		return {"resultado": false, "tipo": "BOOLEAN"}
	
	# Tenta avaliar como expressão matemática
	var expression = Expression.new()
	var erro = expression.parse(expressao, [])
	
	if erro == OK:
		var resultado = expression.execute([], null, true)
		if not expression.has_execute_failed():
			# Detecta o tipo do resultado
			var tipo_resultado = "FLOAT"
			if typeof(resultado) == TYPE_INT:
				tipo_resultado = "INT"
			elif typeof(resultado) == TYPE_FLOAT:
				tipo_resultado = "FLOAT"
			elif typeof(resultado) == TYPE_BOOL:
				tipo_resultado = "BOOLEAN"
			elif typeof(resultado) == TYPE_STRING:
				tipo_resultado = "STRING"
			
			return {"resultado": resultado, "tipo": tipo_resultado}
	
	return {"resultado": 0.0, "tipo": "FLOAT"}
