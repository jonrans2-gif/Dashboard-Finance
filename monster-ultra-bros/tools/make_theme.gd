extends Node
## Bakes the UI theme built by scripts/autoload/ui_theme.gd into
## res://assets/ui/theme.tres (the project-wide GUI theme). Run with:
##   godot --headless --path . res://tools/make_theme.tscn

func _ready() -> void:
	var err := ResourceSaver.save(UITheme._build(), "res://assets/ui/theme.tres")
	print("theme saved: ", err == OK)
	get_tree().quit()
