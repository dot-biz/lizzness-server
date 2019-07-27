extends Node

var server: WebSocketServer
var clients: Node

func _ready():
	
	clients = Node.new()
	clients.setName("clients")
	get_tree().get_root().call_deferred("add_child", clients)
	
	server = WebSocketServer.new()
	server.listen(12926, PoolStringArray(), true)
	get_tree().set_network_peer(server)
	get_tree().connect("network_peer_connected", self, "client_connected")
	get_tree().connect("network_peer_disconnected", self, "client_disconnected")

func client_connected(id: int):
	var client = load("res://Client.tscn").instance()
	client.initialize(id)
	clients.add_child(client)

func client_disconnected(id: int):
	get_node("root/clients/%s" % str(id)).queue_free()

func _process(delta: float):
	if server.is_listening():
		server.poll()
