class_name PhaseConfig
extends Resource

## Capacidade em bytes da mochila do desafio (lado esquerdo).
@export var capacity_bytes: int = 8
@export var grid_columns: int = 4
@export var backpack_slot_count: int = 8
@export var pool_slot_count: int = 10
@export var pool_grid_columns: int = 5
## Itens iniciais na mochila. Atalhos: "42_i", "3.14_f", "2.5_D" ou IDs do DataHandler (ex: "item_number_5").
@export var initial_backpack_items: PackedStringArray = PackedStringArray()
## Se não vazio, substitui initial_backpack_items (valores separados por vírgula, mesmo formato dos atalhos).
@export var initial_backpack_csv: String = ""
## Itens fixos no pool antes do sorteio (IDs ou atalhos).
@export var initial_pool_items: PackedStringArray = PackedStringArray()
## Sorteia apenas IDs existentes em DataHandler.item_data (ex: "item_number_3").
@export var random_pool: PackedStringArray = PackedStringArray()
## Metas de bytes adicionados por itens sortidos no pool (após os fixos). Se 0, usa o espaço livre na mochila após montar o desafio.
@export var min_bytes_random_pool: int = 0


func get_backpack_entry_list() -> PackedStringArray:
	if initial_backpack_csv.strip_edges() != "":
		var out: PackedStringArray = PackedStringArray()
		for part in initial_backpack_csv.split(",", false):
			var s = part.strip_edges()
			if not s.is_empty():
				out.append(s)
		return out
	return initial_backpack_items
