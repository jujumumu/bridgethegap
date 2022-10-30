extends StaticBody2D


export var wallname = ""



func _on_Area2D_body_entered(body):
	get_node("AnimatedSprite").frame = 1
	get_node("CollisionShape2D").disabled = true
	get_node("Area2D").monitorable = false
	get_node("Area2D").monitoring = false
	
	get_parent().get_node(wallname).move()

