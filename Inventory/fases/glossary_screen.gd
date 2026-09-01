extends Control

@onready var rich: RichTextLabel = $Panel/Margin/VBox/RichTextLabel
@onready var btn_voltar: Button = $Panel/Margin/VBox/BtnVoltar


func _ready():
	# Mesma ordem/arte do criador: fundo + Panel por cima (tonalidade escurecida).
	PanelArtLoader.apply_background(self)
	PanelArtLoader.skin_all_buttons(self)
	OrbHoverBar.apply_info_richtext(rich, 16)
	btn_voltar.pressed.connect(_on_voltar)
	_load_glossary()


func _load_glossary() -> void:
	var path := "res://Inventory/Data/glossary.json"
	if not FileAccess.file_exists(path):
		rich.text = "Arquivo glossary.json não encontrado."
		return
	var txt := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		rich.text = "JSON inválido."
		return
	var termos: Array = data.get("termos", [])
	var blocks: PackedStringArray = PackedStringArray()
	for e in termos:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var termo := str(e.get("termo", ""))
		var def := str(e.get("definicao", ""))
		blocks.append("[b]" + termo + "[/b]\n" + def)
	var out := ""
	for i in range(blocks.size()):
		if i > 0:
			out += "\n\n"
		out += blocks[i]
	rich.text = ReadableBbcode.for_ui(out)


func _on_voltar() -> void:
	get_tree().change_scene_to_file("res://Inventory/fases/main_menu.tscn")
