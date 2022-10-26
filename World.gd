extends Node2D

var current_spawn_location_instance_number = 1
var current_player_for_spawn_location_number = null

func _ready() -> void:
	# warning-ignore:RETURN_VALUE_DISCARDED
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	
	if get_tree().is_network_server():
		setup_players_positions()

func setup_players_positions() -> void:
	for player in Persistent_nodes.get_children():
		for spawn_location in $Spawning_nodes.get_children():
			if int(spawn_location.name) == current_spawn_location_instance_number and current_player_for_spawn_location_number != player:
				player.rpc("update_position", spawn_location.global_position)
				current_spawn_location_instance_number += 1
				current_player_for_spawn_location_number = player

func _player_disconnected(id) -> void:
	print("Player " + str(id) + " has disconnected")
	if Persistent_nodes.has_node(str(id)):
		Persistent_nodes.get_node(str(id)).queue_free()
