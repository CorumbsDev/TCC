extends Control

func _ready():
	PanelArtLoader.skin_all_buttons(self)
	PanelArtLoader.apply_background(self, PanelArtLoader.PATH_MENU_BACKGROUND)

func _on_comecar_pressed():
	var fm = SequenceFileManager.new()
	var seqs = fm.load_all_sequences()
	
	var seq_name = "Sequencia_Base.tres"
	if not seqs.has(seq_name) and not seqs.is_empty():
		seq_name = seqs.keys()[0]
		
	if seqs.has(seq_name):
		var seq_list = seqs[seq_name] as PhaseSequenceList
		var steps = seq_list.to_runtime_array()
		if not steps.is_empty():
			PhaseRunner.begin_with_steps(steps)
		else:
			print("Sequencia vazia")
	else:
		print("Nenhuma sequencia encontrada")

func _on_gerador_pressed():
	get_tree().change_scene_to_file("res://Inventory/fases/sequence_editor.tscn")
