extends Node

const DEFAULT_PORT = 28960
const MAX_CLIENTS = 6

var server = null
var client = null

var ip_address = ""
var client_connected_to_server = false

onready var client_connection_timeout_timer = Timer.new()

func _ready() -> void:
	add_child(client_connection_timeout_timer)
	client_connection_timeout_timer.wait_time = 10
	client_connection_timeout_timer.one_shot = true
	client_connection_timeout_timer.connect("timeout", self, "_client_connection_timeout")
	
	# set IP for hosting by OS type
	if OS.get_name() == "Windows":
		ip_address = IP.get_local_addresses()[3]
	elif OS.get_name() == "Android":
		ip_address = IP.get_local_addresses()[0]
	else:
		ip_address = IP.get_local_addresses()[3]
	
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and not ip.ends_with(".1"):
			ip_address = ip
	
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().connect("connection_failed", self, "_connection_failed")

func create_server() -> void:
	server = NetworkedMultiplayerENet.new()
	server.create_server(DEFAULT_PORT, MAX_CLIENTS)
	get_tree().set_network_peer(server)
	

func join_server() -> void:
	client = NetworkedMultiplayerENet.new()
	client.create_client(ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(client)
	client_connection_timeout_timer.start()



func _connected_to_server() -> void:
	print("Successfully connected to the server")
	client_connected_to_server = true

func _server_disconnected() -> void:
	# Server kicked us; show error and abort.
	print("Disconnected from the server")

func _client_connection_timeout():
	if client_connected_to_server == false:
		print("Client has been timed out")
		reset_network_connection()

func _connection_failed():
	# Could not even connect to server; abort.
	reset_network_connection()

func reset_network_connection() -> void:
	if get_tree().has_network_peer():
		get_tree().network_peer = null
