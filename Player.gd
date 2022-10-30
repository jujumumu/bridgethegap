extends KinematicBody2D


const WALK_FORCE = 1000
var WALK_MAX_SPEED = 200
const STOP_FORCE = 1300
var JUMP_SPEED = 330

var GRAVITY = 600

var in_area = []
var pull_area = []

var playercolor

remotesync var player_pos = Vector2()
remotesync var player_velocity = Vector2()
remotesync var player_type = "none"
remotesync var doingsomething = false
remotesync var nomove = false
remotesync var pulled = false
var pulledfirst = false
var minimize = false
var pullerid

var previous_pos = Vector2(0,0)
var previous_velocity = Vector2(0,0)

var velocity = Vector2()



func set_color(col):
	playercolor = col
	get_node("AnimatedSprite").animation = col + "right"
	
func set_player_name(inname):
	pass

func _physics_process(delta):
	#print(gamestate.level4finish)
	
	if is_network_master():
		#print(velocity, pulledfirst, pull_area, is_network_master())
		if pulledfirst:
			
			if pull_area.size()!= 0:
				print("stopped")
				#stop
				pulledfirst = false
				rset("pulled", false)
				velocity = Vector2(0,0)
				get_parent().get_node(str(pullerid)).rpc_id(pullerid, "donepulling")
				get_node("pull").position = Vector2(0,0)
		if pulled:
			move_and_slide_with_snap(velocity, Vector2.DOWN, Vector2.UP, true)

			
			rset_unreliable("player_pos", position)
			rset_unreliable("player_velocity", velocity)
			pulledfirst = true
			return
		# Horizontal movement code. First, get the player's input.
		if not (doingsomething or nomove):
			var walk = WALK_FORCE * (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
			# Slow down the player if they're not trying to move.
			if abs(walk) < WALK_FORCE * 0.2:
				# The velocity, slowed down a bit, and then reassigned.
				velocity.x = move_toward(velocity.x, 0, STOP_FORCE * delta)
			else:
				velocity.x += walk * delta
			# Clamp to the maximum horizontal movement speed.
		velocity.x = clamp(velocity.x, -WALK_MAX_SPEED, WALK_MAX_SPEED)

		# Vertical movement code. Apply gravity.
		velocity.y += GRAVITY * delta
		
		# Move based on the velocity and snap to the ground.
		velocity = move_and_slide_with_snap(velocity, Vector2.DOWN, Vector2.UP, true)
		
		
		# Check for jumping. is_on_floor() must be called after movement code.
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = -JUMP_SPEED
		rset_unreliable("player_pos", position)
		rset_unreliable("player_velocity", velocity)
		
		
	else:
		if previous_pos != player_pos or previous_velocity != player_velocity:
			#print(player_velocity, player_pos)
			previous_pos = player_pos
			previous_velocity = player_velocity
			position = player_pos
			velocity = player_velocity
	
	if pulled:
		get_node("AnimatedSprite").frame = 0
		get_node("AnimatedSprite").playing = false
	
	if velocity.x > 0:
		get_node("AnimatedSprite").animation = playercolor + "right"
		get_node("AnimatedSprite").playing = true
	elif velocity.x < 0:
		get_node("AnimatedSprite").animation = playercolor + "left"
		get_node("AnimatedSprite").playing = true
	else:
		get_node("AnimatedSprite").frame = 0
		get_node("AnimatedSprite").playing = false
	
	
	
	

func _input(ev):
	if is_network_master() == false:
		return

	if ev is InputEventKey and ev.scancode == KEY_SPACE: #code
		if player_type == "minimize":
			if velocity == Vector2(0,0) and doingsomething == false:
				#print(get_tree().get_network_unique_id())
					doingsomething = true
					rpc("togglesize")
		if player_type == "launch":
			if velocity == Vector2(0,0):
				if nomove:
					#only in level 4 
					if not get_tree().is_network_server():
						gamestate.rpc_id(1,"finishlevel4", get_tree().get_network_unique_id())
					else:
						gamestate.finishlevel4(1)
				for body in in_area:
					if body.has_method("launch_off"):
						body.rpc("launch_off")
		if player_type == "pull":
			if velocity == Vector2(0,0) and doingsomething == false:
				print("PUSLADJSDJLAK")
				
					
				var closest = 10000
				var closestchild
				for c in gamestate.mainworld.get_node("Players").get_children():
					if c != self:
						if position.distance_to(c.position) < closest:
							closest = position.distance_to(c.position)
							closestchild = c
				doingsomething = true
				print(closestchild.get_network_master())
				closestchild.rpc_id(closestchild.get_network_master(), "getpulled", (position - closestchild.position).normalized())
				

remotesync func togglecollision(boo):
	set_collision_layer_bit(2,boo)
	set_collision_mask_bit(2,boo)

remotesync func togglesize():
	if minimize:
		minimize = false
		#grow big
		get_node("Tween").interpolate_property(self, "scale", Vector2(0.33,0.33), Vector2(1,1), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		get_node("Tween").start()
		WALK_MAX_SPEED = 200
		JUMP_SPEED = 350
	else:
		minimize = true
		get_node("Tween").interpolate_property(self, "scale", Vector2(1,1), Vector2(0.33,0.33), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		get_node("Tween").start()
		WALK_MAX_SPEED = 200/3.0
		JUMP_SPEED = 202.072594
		


func _on_Tween_tween_all_completed():
	doingsomething = false


remotesync func launch_off():
	velocity = Vector2(0,-500)

remote func getpulled(direction):
	print("GOT PULLED", direction)
	pullerid = get_tree().get_rpc_sender_id()
	pulled = true
	rset("pulled", true)
	velocity = direction * 600
	get_node("pull").position = get_node("pull").position + direction * 3
	
remote func donepulling():
	print("DONEPULLING")
	doingsomething = false
	if nomove:
		if not get_tree().is_network_server():
			gamestate.rpc_id(1,"finishlevel4", get_tree().get_network_unique_id())
		else:
			gamestate.finishlevel4(1)

func _on_head_body_entered(body):
	if is_network_master():
		if not body in in_area:
			in_area.append(body)


func _on_head_body_exited(body):
	if is_network_master():
		in_area.erase(body)


func _on_pull_body_entered(body):
	if is_network_master():
		if not body in pull_area:
			pull_area.append(body)


func _on_pull_body_exited(body):
	if is_network_master():
		pull_area.erase(body)



