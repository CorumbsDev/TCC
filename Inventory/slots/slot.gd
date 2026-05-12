extends TextureRect

signal slot_entered(slot)
signal slot_exited(slot)

@onready var filter = $StatusFilter

var slot_ID
var is_hovering:=false
enum States {DEFAULT, TAKEN, FREE, PARTIAL}
var state = States.DEFAULT
var items_stored = []
var item_stored:
	get:
		if items_stored.size() > 0:
			return items_stored[0]
		return null
	set(value):
		if value == null:
			items_stored.clear()
		else:
			items_stored = [value]
signal item_changed(slot)

func _ready():
	custom_minimum_size = Vector2(64, 64)
	size = Vector2(64, 64)
	expand_mode = 1 # TextureRect.EXPAND_IGNORE_SIZE
	add_to_group("slot")


func set_item(item):
	self.item_stored = item
	emit_signal("item_changed", self)

func add_item(item):
	if not items_stored.has(item):
		items_stored.append(item)
	emit_signal("item_changed", self)

func remove_item(item):
	if items_stored.has(item):
		items_stored.erase(item)
	emit_signal("item_changed", self)

func clear_items():
	items_stored.clear()
	emit_signal("item_changed", self)

func get_used_bytes() -> int:
	var total = 0
	for item in items_stored:
		if item and item.has_method("get_size_bytes"):
			total += item.get_size_bytes()
	return total

func set_color(a_state = States.DEFAULT) -> void :
	match a_state:
		States.DEFAULT:
			filter.color = Color(Color.WHITE, 0.0)
		States.TAKEN:
			filter.color = Color(Color.RED, 0.2)
		States.PARTIAL:
			filter.color = Color(Color.YELLOW, 0.2)
		States.FREE:
			filter.color = Color(Color.GREEN, 0.2)

func _process(_delta):
	if get_global_rect().has_point(get_global_mouse_position()):
		if not is_hovering:
			is_hovering = true
			emit_signal("slot_entered",self)
	else:
		if is_hovering:
			is_hovering = false
			emit_signal("slot_exited",self)
