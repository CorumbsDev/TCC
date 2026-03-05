extends Control

func _on_fase1_pressed():
	get_tree().change_scene_to_file("res://Inventory/binary_phase.tscn")

func _on_fase2_pressed():
	get_tree().change_scene_to_file("res://Inventory/backpack_phase.tscn")

func _on_inventario_livre_pressed():
	get_tree().change_scene_to_file("res://Inventory/inventory_menu.tscn")
