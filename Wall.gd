extends Node2D

var count = 0


func move():
	get_node("Tween").interpolate_property(get_node("StaticBody2D"), "position", Vector2(0,0), Vector2(0,30), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	get_node("Tween").start()




func _on_Tween_tween_all_completed():
	count = count + 1
	get_node("StaticBody2D").get_node(str(count)).visible = false
	if count == 9:
		get_node("StaticBody2D/CollisionShape2D").disabled = true
		return;
	get_node("Tween").interpolate_property(get_node("StaticBody2D"), "position", Vector2(0,count*30), Vector2(0,30*count+30), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	get_node("Tween").start()
