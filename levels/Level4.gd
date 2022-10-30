extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func startgame():
	if get_tree().is_network_server():
		for play in get_parent().get_node("Players").get_children():
			play.rset("player_type", "launch")
			#play.rset("doingsomething", true)
			play.rset("nomove", true)
