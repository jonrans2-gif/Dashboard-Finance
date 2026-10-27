extends Control
## Small yes/no dialog.

var text := "ARE YOU SURE?"
var on_yes := Callable()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UITheme.dim_background(self, 0.7)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-100, -40)
	panel.custom_minimum_size = Vector2(200, 80)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	v.add_child(UITheme.label(text, 10))
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 8)
	var no := UITheme.button("NO", queue_free, 70)
	h.add_child(no)
	h.add_child(UITheme.button("YES", func():
		if on_yes.is_valid():
			on_yes.call()
		queue_free(), 70))
	v.add_child(h)
	no.grab_focus.call_deferred()


func back() -> void:
	queue_free()
