class_name TutorialOverlay
extends CanvasLayer
## Painel modal de tutorial/onboarding.

signal closed()

@onready var title_label: Label = $CenterContainer/Panel/Margin/VBox/TitleLabel
@onready var body_label: RichTextLabel = $CenterContainer/Panel/Margin/VBox/RichTextLabel
@onready var btn_ok: Button = $CenterContainer/Panel/Margin/VBox/BtnOk

var _pref_key: String = ""
var _mark_on_close: bool = false


func _ready():
	btn_ok.pressed.connect(_on_ok)
	visible = false


func present(pref_key: String, title: String, bbcode_body: String, mark_on_close: bool) -> void:
	_pref_key = pref_key
	_mark_on_close = mark_on_close
	title_label.text = title
	body_label.text = bbcode_body
	visible = true


func _on_ok() -> void:
	if _mark_on_close and not _pref_key.is_empty():
		LearningPrefs.mark_tutorial_seen(_pref_key)
	visible = false
	closed.emit()


static func open(parent: Node, pref_key: String, title: String, bbcode_body: String, mark_on_close: bool) -> void:
	var inst = preload("res://Inventory/ui/tutorial_overlay.tscn").instantiate()
	parent.get_tree().root.add_child(inst)
	inst.call_deferred("present", pref_key, title, bbcode_body, mark_on_close)
