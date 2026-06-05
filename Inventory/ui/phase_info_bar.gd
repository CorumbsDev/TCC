class_name PhaseInfoBar
extends PanelContainer
## Painel de instruções/feedback com o mesmo visual do OrbHoverBar.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_END
	OrbHoverBar.apply_info_panel(self)
	for label in _collect_labels():
		OrbHoverBar.apply_info_label(label)


func _collect_labels() -> Array[Label]:
	var out: Array[Label] = []
	_walk_labels(self, out)
	return out


func _walk_labels(node: Node, out: Array[Label]) -> void:
	for child in node.get_children():
		if child is Label:
			out.append(child)
		else:
			_walk_labels(child, out)
