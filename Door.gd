extends Node2D


var check
var in_area = []

# Called when the node enters the scene tree for the first time.
func _ready():
	check = get_tree().is_network_server()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Area2D_body_entered(body):
	if check:
		if not body in in_area:
			in_area.append(body)
			body.rpc("togglecollision", false)

		if in_area.size() == 3:
			gamestate.go_next_level()


func _on_Area2D_body_exited(body):
	if check:
		in_area.erase(body)
		body.rpc("togglecollision", true)


func _on_Timer_timeout():
	pass # Replace with function body.
