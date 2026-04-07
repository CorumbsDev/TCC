extends Control

func _on_fase1_pressed():
	get_tree().change_scene_to_file("res://Inventory/fases/binary_phase.tscn")

func _on_fase3_pressed():
	get_tree().change_scene_to_file("res://Inventory/fases/conversion_phase.tscn")

func _on_glossary_pressed():
	get_tree().change_scene_to_file("res://Inventory/fases/glossary_screen.tscn")

func _on_fase2_pressed():
	get_tree().change_scene_to_file("res://Inventory/fases/phase2.tscn")

func _on_fase2_classic_pressed():
	get_tree().change_scene_to_file("res://Inventory/fases/backpack_phase.tscn")

func _on_inventario_livre_pressed():
	get_tree().change_scene_to_file("res://Inventory/fases/inventory_menu.tscn")
