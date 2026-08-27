class_name ExpressionEvaluator
extends RefCounted

static func validate_types(sequence: Array) -> Dictionary:
	var tipos_encontrados = []
	var valores_encontrados = []
	
	for i in range(sequence.size()):
		var token = sequence[i]
		if token in ["+", "-", "*", "/", "**", "//", "%", "==", "!=", ">", "<", ">=", "<=", "and", "or", "not"]:
			continue
		
		if token.begins_with('"') and token.ends_with('"'):
			tipos_encontrados.append("STRING")
			valores_encontrados.append(token)
		elif token.to_lower() == "true" or token.to_lower() == "false":
			tipos_encontrados.append("INT")
			valores_encontrados.append("1" if token.to_lower() == "true" else "0")
		elif "." in token and token.replace(".", "").replace("-", "").is_valid_float():
			tipos_encontrados.append("FLOAT")
			valores_encontrados.append(token)
		elif token.is_valid_int() or (token.begins_with("-") and token.substr(1).is_valid_int()):
			tipos_encontrados.append("INT")
			valores_encontrados.append(token)
		else:
			tipos_encontrados.append("UNKNOWN")
			valores_encontrados.append(token)
			
	var tipos_unicos = []
	for tipo in tipos_encontrados:
		if tipo not in tipos_unicos and tipo != "UNKNOWN":
			tipos_unicos.append(tipo)
			
	var valido = true
	var mensagem = ""
	
	if tipos_unicos.size() > 2:
		valido = false
		mensagem = "Muitos tipos diferentes na expressão"
	elif "STRING" in tipos_unicos and tipos_unicos.size() > 1:
		valido = true
		mensagem = "Aviso: Operação com string"
		
	return {
		"valido": valido,
		"mensagem": mensagem,
		"tipos": tipos_encontrados,
		"valores": valores_encontrados
	}

static func evaluate_with_type(expr: String) -> Dictionary:
	var regex = RegEx.new()
	regex.compile("([0-9\\.]+)\\+?to_float\\+?([0-9\\.]+)")
	expr = regex.sub(expr, "($1 * 1.0 + 0 * $2)", true)
	regex.compile("([0-9\\.]+)\\+?to_int\\+?([0-9\\.]+)")
	expr = regex.sub(expr, "(floor($1) + 0 * $2)", true)
	regex.compile("([0-9\\.]+)\\+?to_short\\+?([0-9\\.]+)")
	expr = regex.sub(expr, "(floor($1) + 0 * $2)", true)
	
	expr = expr.replace(" ", "")
	
	if expr.begins_with('"') and expr.ends_with('"'):
		var str_valor = expr.substr(1, expr.length() - 2)
		return {"resultado": str_valor, "tipo": "STRING"}
		
	if expr.to_lower() == "true": return {"resultado": 1, "tipo": "INT"}
	if expr.to_lower() == "false": return {"resultado": 0, "tipo": "INT"}
	
	var expression = Expression.new()
	var error = expression.parse(expr, [])
	if error == OK:
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
				
			if "to_short" in expr.to_lower():
				tipo_resultado = "SHORT_INT"
				
			return {"resultado": resultado, "tipo": tipo_resultado}
			
	return {"resultado": 0.0, "tipo": "FLOAT"}
