extends Enemy
## Empty Can: a dented, discarded can that patrols back and forth.


func _ready() -> void:
	setup("empty_can", Vector2(10, 16), "walk")
	speed = 30.0
