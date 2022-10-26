extends Control

onready var IpAddr := $Control/IpAddr
var player = load("res://Player.tscn")

var current_spawn_location_instance_number = 1
var current_player_for_spawn_location_number = null

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")


func _player_connected(id) -> void:
	# Called on both clients and server when a peer connects.
	print("Player " + str(id) + " has connected")
	instance_player(id)

func _player_disconnected(id) -> void:
	print("Player " + str(id) + " has disconnected")
	if Persistent_nodes.has_node(str(id)):	
		Persistent_nodes.get_node(str(id)).queue_free()

func _connected_to_server() -> void:
	# Only called on clients, not server.
	yield(get_tree().create_timer(0.1), "timeout")
	instance_player(get_tree().get_network_unique_id())

func _on_CreateServer_pressed():
	Network.create_server()
	$Control.hide()
	instance_player(get_tree().get_network_unique_id())


func _on_JoinServer_pressed():
	Network.ip_address = IpAddr.text
	$Control.hide()
	$Control/CreateServer.hide()
	Network.join_server()

func _on_StartGame_pressed():
	self.rpc("switch_to_game")

sync func switch_to_game() -> void:
	# warning-ignore:RETURN_VALUE_DISCARDED
	get_tree().change_scene("res://World.tscn")

func instance_player(id) -> void:
	var player_instance = Global.instance_node(player, 
		Persistent_nodes
	)
	
	player_instance.name = str(id)
	player_instance.set_network_master(id)
	if current_spawn_location_instance_number > 6:
		current_spawn_location_instance_number = 1
	else:
		current_spawn_location_instance_number += 1
