extends "res://phaseBase.gd"

@export var initial_backpack_string: String = "1_i, 2.5_f, 3.33_D"

func _ready():
	# Chama o _ready da base (conecta botões, etc.)
	super()
	
	# Limpa os containers (remove qualquer coisa que possa ter sido colocada na base)
	_clear_container(backpack_container)
	_clear_container(bancada_container)
	
	# Instancia os grids personalizados (use os nomes reais dos arquivos)
	var backpack_grid_instance = preload("res://Inventory/backpack/BackpackGrid.tscn").instantiate()
	var bancada_grid_instance = preload("res://Inventory/grid/BancadaGrid.tscn").instantiate()
	
	# Adiciona como filhos dos containers
	backpack_container.add_child(backpack_grid_instance)
	bancada_container.add_child(bancada_grid_instance)
	
	var backpack = backpack_grid_instance
	var bancada = bancada_grid_instance
	
	# Remove qualquer item criado pelos grids no _ready
	backpack.clear_all_items()
	bancada.clear_all_items()
	
	# Conecta sinais
	setup_grids(backpack, bancada)
	
	# Aguarda layout dos slots antes de criar itens
	call_deferred("_initialize_game", backpack, bancada)

func _initialize_game(backpack, bancada):
	# Agora os grids estão prontos (layout já calculado)
	backpack.clear_all_items()
	bancada.clear_all_items()
	
	_create_backpack_items_from_string(initial_backpack_string, backpack)
	var used = backpack.total_bytes_used()
	var free = backpack.capacity_bytes - used
	if free > 0:
		_generate_bancada_items(bancada, free)
	else:
		_generate_bancada_items(bancada, 0)  # opcional: gera alguns itens mesmo com mochila cheia
	
	_update_bytes_label()
	_update_hint()

func _clear_container(container):
	for child in container.get_children():
		child.queue_free()

func _create_backpack_items_from_string(str_data: String, backpack):
	var entries = str_data.split(",", false)
	var slots = backpack.slots_array
	var slot_index = 0
	
	for entry in entries:
		entry = entry.strip_edges()
		if entry.is_empty():
			continue
		
		var parts = entry.split("_")
		if parts.size() != 2:
			push_warning("Entrada inválida: %s" % entry)
			continue
		
		var value_str = parts[0]
		var type_str = parts[1].to_lower()
		
		var item = preload("res://Inventory/Items/Item.tscn").instantiate()
		
		match type_str:
			"i":
				item.set_value_directly(int(value_str))
			"f":
				item.set_value_by_type(float(value_str), item.DataType.FLOAT)
			"D", "d":
				item.set_value_by_type(float(value_str), item.DataType.DOUBLE)
			_:
				push_warning("Tipo desconhecido: %s para %s" % [type_str, entry])
				item.queue_free()
				continue
		
		# Encontra slot livre
		var placed = false
		for i in range(slot_index, slots.size()):
			var slot = slots[i]
			if backpack.can_place_item(item, slot):
				backpack.place_item(item, slot)
				slot_index = i + 1
				placed = true
				break
		if not placed:
			push_warning("Não foi possível colocar o item %s na mochila" % entry)
			item.queue_free()

func _generate_bancada_items(bancada, min_bytes: int):
	var tipos = [
		{"type": "i", "size": 1},
		{"type": "f", "size": 4},
		{"type": "D", "size": 2}
	]
	
	var total_bytes = 0
	var items_created = 0
	var max_items = bancada.number_of_slots
	
	while total_bytes < min_bytes and items_created < max_items:
		var tipo_info = tipos[randi() % tipos.size()]
		var tipo = tipo_info["type"]
		var size = tipo_info["size"]
		
		var valor
		match tipo:
			"i":
				valor = randi() % 100
			"f", "D":
				valor = randf_range(0.0, 100.0)
		
		var item = preload("res://Inventory/Items/Item.tscn").instantiate()
		if tipo == "i":
			item.set_value_directly(valor)
		else:
			item.set_value_by_type(valor, item.DataType.FLOAT if tipo == "f" else item.DataType.DOUBLE)
		
		var placed = false
		for slot in bancada.slots_array:
			if slot.item_stored == null:
				slot.state = slot.States.TAKEN
				slot.item_stored = item
				slot.set_item(item)
				bancada.add_child(item)
				item.global_position = slot.global_position + Vector2(25, 25)
				item.grid_anchor = slot
				placed = true
				break
		if not placed:
			item.queue_free()
			break
		
		total_bytes += size
		items_created += 1
	
	print("Bancada gerada com %d itens (total de bytes: %d)" % [items_created, total_bytes])

func _on_spawn_pressed():
	if item_held != null:
		return
	var item = preload("res://Inventory/Items/Item.tscn").instantiate()
	add_child(item)
	item.set_value_directly(randi() % 10)
	item.selected = true
	item_held = item
	_update_bytes_label()
