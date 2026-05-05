class_name PhaseConfig
extends Resource

## Capacidade em bytes da mochila do desafio (lado esquerdo).
@export var capacity_bytes: int = 8
@export var grid_columns: int = 4
## Quantidade de slots visíveis na mochila (grade do desafio).
@export var backpack_slot_count: int = 8
## Slots na bancada / pool de itens.
@export var pool_slot_count: int = 10
@export var pool_grid_columns: int = 5
## Intervalo inclusivo para INT aleatório (spawn e preenchimento sem random_pool).
@export var spawn_int_min: int = 0
@export var spawn_int_max: int = 99
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


## Garante limites válidos (capacidade, slots e faixa de valores INT).
func apply_constraints() -> void:
	capacity_bytes = clampi(capacity_bytes, 1, 4096)
	grid_columns = clampi(grid_columns, 1, 64)
	backpack_slot_count = clampi(backpack_slot_count, 1, 512)
	pool_slot_count = clampi(pool_slot_count, 1, 512)
	pool_grid_columns = clampi(pool_grid_columns, 1, 64)
	min_bytes_random_pool = clampi(min_bytes_random_pool, 0, 8192)
	spawn_int_min = clampi(spawn_int_min, -999999, 999999)
	spawn_int_max = clampi(spawn_int_max, -999999, 999999)
	if spawn_int_min > spawn_int_max:
		var t := spawn_int_min
		spawn_int_min = spawn_int_max
		spawn_int_max = t


func clamp_int_value(v: int) -> int:
	return clampi(v, spawn_int_min, spawn_int_max)


func get_backpack_entry_list() -> PackedStringArray:
	if initial_backpack_csv.strip_edges() != "":
		var out: PackedStringArray = PackedStringArray()
		for part in initial_backpack_csv.split(",", false):
			var s = part.strip_edges()
			if not s.is_empty():
				out.append(s)
		return out
	return initial_backpack_items
