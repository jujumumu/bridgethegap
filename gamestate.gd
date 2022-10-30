extends Node


const DEFAULT_PORT = 4910


const MAX_PEERS = 2
var peer = null


var player_name = ""

var pastroles = ["none", "none", "none"]
var playercolors = {}
var players = {}
var players_ready = []
var current_level = 0
var mainworld
var playerorder = []
var level4finish = []

signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)
 

func _player_connected(id):
	rpc_id(id, "register_player", player_name)


func _player_disconnected(id):
	if has_node("/root/World"): 
		emit_signal("game_error", "Player " + players[id] + " disconnected")
		end_game()
	else:
		unregister_player(id)



func _connected_ok():	
	# We just connected to a server
	emit_signal("connection_succeeded")



func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()
 
func disconnect_game():
	get_tree().network_peer = null
	end_game()


func _connected_fail():
	get_tree().set_network_peer(null) 
	emit_signal("connection_failed")



remote func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	print(id)
	players[id] = new_player_name
	emit_signal("player_list_changed")


func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")


remote func pre_start_game(spawn_points, order):
	
	var world = load("res://world.tscn").instance()
	get_tree().get_root().add_child(world)
	mainworld = get_tree().get_root().get_node("World")
	
	get_tree().get_root().get_node("Lobby").hide()

	var player_scene = load("res://Player.tscn")

	for thing in spawn_points:
		var player = player_scene.instance()
		
		var p_id = thing.id
		player.set_name(str(p_id)) 
		player.set_network_master(p_id)
		player.set_color(thing.color)
		playercolors[p_id] = thing.color

		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name.
			player.set_player_name(player_name)
		else:
			# Otherwise set name from peer.
			#player.set_player_name(players[p_id])
			pass

		world.get_node("Players").add_child(player)

	next_level(order, ["none", "none", "none"])
	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	


remote func post_start_game():
	get_tree().set_pause(false) 


remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()


func host_game(new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(peer)


func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)


func get_player_list():
	return players.values()


func get_player_name():
	return player_name


func begin_game():
	assert(get_tree().is_network_server())
	
	var spawn_locations = [Vector2(100,100), Vector2(200,100), Vector2(300,100)]
	var playercolors = ["blue", "green", "yellow"]
	
	
	
	var positions = Vector2(100,100)
	
	for id in players:
		playerorder.append(id)
	playerorder.append(1)
	
	var spawn_points = []
	for i in range(0,3):
		spawn_points.append({"id":playerorder[i], "position":spawn_locations[i], "color":playercolors[i]})
	

	pre_start_game(spawn_points, playerorder)
	rpc("pre_start_game", spawn_points, playerorder)

	


func end_game():
	current_level = 0
	if has_node("/root/World"):
		# End it
		get_node("/root/World").queue_free()

	emit_signal("game_ended")
	players.clear()

func go_next_level():
	var roles = []
	if current_level >= 5:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var val = rng.randi()%3
		if val == 0:
			roles.append("minimize")
			if rng.randi()%2 == 0:
				roles.append("launch")
				roles.append("pull")
			else:
				roles.append("pull")
				roles.append("launch")
		elif val == 1:
			roles.append("launch")
			if rng.randi()%2 == 0:
				roles.append("minimize")
				roles.append("pull")
			else:
				roles.append("pull")
				roles.append("minimize")
		elif val == 2:
			roles.append("pull")
			if rng.randi()%2 == 0:
				roles.append("launch")
				roles.append("minimize")
			else:
				roles.append("minimize")
				roles.append("launch")
	else:
		roles =  ["none", "none", "none"]
	rpc("next_level", playerorder, roles)

remotesync func next_level(order, roles, dontadd = false):
	if roles[0] == "none" or current_level == 9:
		mainworld.get_node("Roles").visible = false
	else:
		mainworld.get_node("Roles").visible = true
		for i in range(0,3):
			mainworld.get_node("Roles").get_node(playercolors[order[i]]).text = roles[i]
			
			
		
	
	pastroles = roles
	if current_level != 0:
		if get_viewport().has_node("World/Level" + str(current_level)):
			var thisshit = get_viewport().get_node("World/Level" + str(current_level))
			thisshit.queue_free()
			thisshit.name = "bruhbruhbruhbruh"
	
	current_level = current_level + 1
	if dontadd:
		current_level = current_level - 1
	
	if current_level <= 9:
		
		var playerspawns = ["none",
		[Vector2(70,878), Vector2(150,878), Vector2(220,878)],
		[Vector2(41,938), Vector2(41,808), Vector2(41,678)],
		[Vector2(70,878), Vector2(150,878), Vector2(220,878)],
		[Vector2(631,887), Vector2(631+360,887), Vector2(631+720,887)],
		[Vector2(305,638), Vector2(905,638), Vector2(1505-60,638)],
		[Vector2(41,938), Vector2(41,808), Vector2(41,678)],
		[Vector2(70,878), Vector2(150,878), Vector2(220,878)],
		[Vector2(70,878), Vector2(150,878), Vector2(220,878)],
		[Vector2(70,878), Vector2(150,878), Vector2(220,878)],
		]
		for i in range(0,3):
			mainworld.get_node("Players").get_node(str(order[i])).togglecollision(true)
			mainworld.get_node("Players").get_node(str(order[i])).position = playerspawns[current_level][i]
			mainworld.get_node("Players").get_node(str(order[i])).velocity = Vector2(0,0)
			mainworld.get_node("Players").get_node(str(order[i])).player_type = roles[i]
			mainworld.get_node("Players").get_node(str(order[i])).minimize = false
			mainworld.get_node("Players").get_node(str(order[i])).doingsomething = false
			mainworld.get_node("Players").get_node(str(order[i])).WALK_MAX_SPEED = 200
			mainworld.get_node("Players").get_node(str(order[i])).JUMP_SPEED = 350
			mainworld.get_node("Players").get_node(str(order[i])).scale = Vector2(1,1)
			mainworld.get_node("Players").get_node(str(order[i])).nomove = false
			mainworld.get_node("Players").get_node(str(order[i])).pulled = false
			mainworld.get_node("Players").get_node(str(order[i])).pulledfirst = false
		var levelscene = load("res://levels/Level" + str(current_level)+".tscn")
		
		var leveel = levelscene.instance()
		mainworld.add_child(leveel)
		if leveel.has_method("startgame"):
			leveel.startgame()
		
	else:
		mainworld.get_node("Players").queue_free()
		var win = load("res://win.tscn")
		mainworld.add_child(win.instance())
	

remote func finishlevel4(id):
	if not id in level4finish:
		level4finish.append(id)
	if level4finish.size() == 3:
		level4finish.clear()
		go_next_level()
	
func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
