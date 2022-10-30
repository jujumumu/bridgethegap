extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.


func _ready():
	if not get_tree().is_network_server():
		get_node("Node2D/Reset").visible = false


func _on_Reset_pressed():
	gamestate.rpc("next_level", gamestate.playerorder, gamestate.pastroles, true)


func _on_skip_pressed():
	gamestate.go_next_level()
