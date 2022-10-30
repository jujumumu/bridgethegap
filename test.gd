extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Tween").interpolate_property(get_node("Sprite"), "scale", Vector2(1,1), Vector2(0.5,0.5), 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	get_node("Tween").start()
	print(get_node("Sprite").scale)
	

