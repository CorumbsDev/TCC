extends Node2D

@onready var value_label: Label = $ColorRect/value_label

var item_ID : String
var value : int = 0
var operator : String = ""
var selected = false
var item_grids := [Vector2(0,0)]
var grid_anchor = null

func _ready():
	pass

func _process(delta):
	if selected:
		global_position = lerp(global_position, get_global_mouse_position(), 25 * delta)

func load_item(a_ItemID: String) -> void:
	item_ID = a_ItemID
	var data = DataHandler.item_data[item_ID]

	if data.has("Operator") and str(data["Operator"]) != "":
		operator = str(data["Operator"])
		value = 0
	elif data.has("Value") and int(data["Value"]) != 0:
		value = int(data["Value"])
		operator = ""

	update_label_display()

func set_value_directly(new_value: int):
	"""Define o valor diretamente (para resultados de expressões)"""
	value = new_value
	operator = ""
	item_ID = "item_number_" + str(new_value)
	update_label_display()

func set_operator_directly(new_operator: String):
	"""Define o operador diretamente"""
	operator = new_operator
	value = 0
	item_ID = "item_operator_" + new_operator
	update_label_display()

func update_label_display():
	# Aguarda a Label estar pronta se necessário
	if not value_label:
		# Tenta encontrar a Label se não foi atribuída automaticamente
		value_label = get_node_or_null("ValueLabel")
		if not value_label:
			# Procura por qualquer Label na cena
			var labels = get_children().filter(func(child): return child is Label)
			if labels.size() > 0:
				value_label = labels[0]
			else:
				push_error("Nenhuma Label encontrada no item!")
				return
	
	# Garante que a Label está visível
	value_label.visible = true
	
	# Configura o texto
	if operator != "":
		value_label.text = operator
		value_label.add_theme_color_override("font_color", Color.RED)
		value_label.add_theme_font_size_override("font_size", 24)
	else:
		value_label.text = str(value)
		value_label.add_theme_color_override("font_color", Color.BLACK) 
		value_label.add_theme_font_size_override("font_size", 20)
	
	# Força o redesenho
	value_label.queue_redraw()
func _snap_to(destination):
	var tween = get_tree().create_tween()
	# Ajuste para usar o tamanho da Label
	if value_label:
		destination += value_label.size / 2
	tween.tween_property(self, "global_position", destination, 0.15).set_trans(Tween.TRANS_SINE)
	selected = false
