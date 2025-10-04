extends Node
class_name ControladorExterno

signal expressao_processada(resultado: float, codigo: String)

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
		var resultado = avaliar_expressao_rapida(expressao)
		expressao_processada.emit(resultado, "Erro ao salvar: " + expressao)
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
		var resultado = avaliar_expressao_rapida(expressao)
		expressao_processada.emit(resultado, "Erro Python: " + expressao)

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
			var codigo = dados.get("codigo", "")
			var sucesso = dados.get("sucesso", false)
			
			print("Expressão processada: ", dados.get("expressao", ""))
			print("Resultado: ", resultado)
			print("Sucesso: ", sucesso)
			
			if sucesso:
				expressao_processada.emit(float(resultado), codigo)
			else:
				# Se não foi bem-sucedido, usa fallback
				var resultado_fallback = avaliar_expressao_rapida(ultima_expressao)
				expressao_processada.emit(resultado_fallback, "Fallback: " + ultima_expressao)
		else:
			print("Erro ao analisar JSON: ", erro)
			# Fallback
			var resultado = avaliar_expressao_rapida(ultima_expressao)
			expressao_processada.emit(resultado, "Erro JSON: " + ultima_expressao)
	else:
		print("Arquivo de resultado não encontrado: ", arquivo_resultado)
		# Fallback
		var resultado = avaliar_expressao_rapida(ultima_expressao)
		expressao_processada.emit(resultado, "Arquivo não encontrado: " + ultima_expressao)

func avaliar_expressao_rapida(expressao: String) -> float:
	# Avaliação simples em GDScript
	expressao = expressao.replace("×", "*").replace("÷", "/").replace(" ", "")
	
	var expression = Expression.new()
	var erro = expression.parse(expressao, [])
	
	if erro == OK:
		var resultado = expression.execute([], null, true)
		if not expression.has_execute_failed():
			return float(resultado)
	
	return 0.0
