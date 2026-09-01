extends Node
class_name ControladorExterno

# Signal atualizado para incluir tipo do resultado
signal expressao_processada(resultado: Variant, tipo_resultado: String, codigo: String)

var ultima_expressao: String = ""
var arquivo_resultado: String = "user://resultado.json"

func _ready():
	pass

func processar_expressao_assincrona(expressao: String):
	ultima_expressao = expressao

	var arquivo_expressao = "user://temp_expr_%s.txt" % Time.get_unix_time_from_system()

	if not salvar_expressao(expressao, arquivo_expressao):
		var resultado_info = avaliar_expressao_rapida(expressao)
		expressao_processada.emit(resultado_info.resultado, resultado_info.tipo, "Erro ao salvar: " + expressao)
		return

	var script_path = ProjectSettings.globalize_path("res://Controlador.py")
	var expressao_path = ProjectSettings.globalize_path(arquivo_expressao)
	var resultado_path = ProjectSettings.globalize_path(arquivo_resultado)

	var args = [script_path, expressao_path, resultado_path]
	var output = []

	var exit_code = OS.execute("python3", args, output, true)
	if exit_code != 0:
		exit_code = OS.execute("python", args, output, true)
	if exit_code != 0:
		exit_code = OS.execute("py", args, output, true)

	if exit_code == 0:
		await get_tree().create_timer(0.2).timeout
		ler_resultado_json()
	else:
		var resultado_info = avaliar_expressao_rapida(ultima_expressao)
		expressao_processada.emit(resultado_info.resultado, resultado_info.tipo, "Erro Python: " + ultima_expressao)

func salvar_expressao(expressao: String, caminho: String) -> bool:
	var dir = DirAccess.open("user://")
	if dir:
		var arquivo = FileAccess.open(caminho, FileAccess.WRITE)
		if arquivo:
			arquivo.store_string(expressao)
			arquivo.close()
			return true
		return false
	return false

func ler_resultado_json():
	var arquivo = FileAccess.open(arquivo_resultado, FileAccess.READ)
	if arquivo:
		var conteudo = arquivo.get_as_text()
		arquivo.close()

		var json_resultado = JSON.new()
		var erro = json_resultado.parse(conteudo)

		if erro == OK:
			var dados = json_resultado.data
			var resultado = dados.get("resultado", 0.0)
			var tipo = dados.get("tipo", "FLOAT")
			var codigo = dados.get("codigo", "")
			var sucesso = dados.get("sucesso", false)

			if sucesso:
				var resultado_convertido = converter_resultado_para_tipo(resultado, tipo)
				expressao_processada.emit(resultado_convertido, tipo, codigo)
			else:
				var resultado_info = avaliar_expressao_rapida(ultima_expressao)
				expressao_processada.emit(resultado_info.resultado, resultado_info.tipo, "Fallback: " + ultima_expressao)
		else:
			var resultado_info = avaliar_expressao_rapida(ultima_expressao)
			expressao_processada.emit(resultado_info.resultado, resultado_info.tipo, "Erro JSON: " + ultima_expressao)
	else:
		var resultado_info = avaliar_expressao_rapida(ultima_expressao)
		expressao_processada.emit(resultado_info.resultado, resultado_info.tipo, "Arquivo não encontrado: " + ultima_expressao)

func converter_resultado_para_tipo(valor: Variant, tipo: String) -> Variant:
	match tipo:
		"INT", "SHORT_INT":
			return int(valor)
		"FLOAT":
			return float(valor)
		"DOUBLE":
			return float(valor)
		"STRING":
			return str(valor)
		"BINARY":
			return int(valor)
		_:
			return float(valor)

func avaliar_expressao_rapida(expressao: String) -> Dictionary:
	var regex = RegEx.new()
	regex.compile("([0-9\\.]+)\\+?to_float\\+?([0-9\\.]*)")
	expressao = regex.sub(expressao, "($1 * 1.0 + 0 * $2)", true)
	regex.compile("([0-9\\.]+)\\+?to_int\\+?([0-9\\.]*)")
	expressao = regex.sub(expressao, "(floor($1) + 0 * $2)", true)
	regex.compile("([0-9\\.]+)\\+?to_short\\+?([0-9\\.]*)")
	expressao = regex.sub(expressao, "(floor($1) + 0 * $2)", true)

	expressao = expressao.replace("×", "*").replace("÷", "/").replace(" ", "")
	regex.compile("([0-9\\.]+)\\+\\+")
	expressao = regex.sub(expressao, "($1+1)", true)
	regex.compile("([0-9\\.]+)--")
	expressao = regex.sub(expressao, "($1-1)", true)
	regex.compile("\\+\\+([0-9\\.]+)")
	expressao = regex.sub(expressao, "($1+1)", true)
	regex.compile("--([0-9\\.]+)")
	expressao = regex.sub(expressao, "($1-1)", true)
	regex.compile("\\)([0-9])")
	expressao = regex.sub(expressao, ")+$1", true)

	if expressao.begins_with('"') and expressao.ends_with('"'):
		var str_valor = expressao.substr(1, expressao.length() - 2)
		return {"resultado": str_valor, "tipo": "STRING"}

	if expressao.to_lower() == "true":
		return {"resultado": 1, "tipo": "INT"}
	if expressao.to_lower() == "false":
		return {"resultado": 0, "tipo": "INT"}

	var expression = Expression.new()
	var erro = expression.parse(expressao, [])

	if erro == OK:
		var resultado = expression.execute([], null, true)
		if not expression.has_execute_failed():
			var tipo_resultado = "FLOAT"
			if typeof(resultado) == TYPE_INT:
				tipo_resultado = "INT"
			elif typeof(resultado) == TYPE_FLOAT:
				tipo_resultado = "FLOAT"
			elif typeof(resultado) == TYPE_BOOL:
				tipo_resultado = "INT"
				resultado = 1 if resultado else 0
			elif typeof(resultado) == TYPE_STRING:
				tipo_resultado = "STRING"

			if "to_short" in expressao.to_lower():
				tipo_resultado = "SHORT_INT"

			return {"resultado": resultado, "tipo": tipo_resultado}

	return {"resultado": 0.0, "tipo": "FLOAT"}
