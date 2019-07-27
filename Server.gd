extends Node

signal CLIENT_CONNECTION_READY

var server: WebSocketServer
var clients: Node
var games: Node

const LISTEN_PORT = 12926

func _ready():
	
	clients = Node.new()
	clients.set_name("clients")
	get_tree().get_root().call_deferred("add_child", clients)
	
	games = preload('res://games.tscn').instance()
	games.set_name('games')
	get_tree().get_root().call_deferred('add_child', games)
	
	server = WebSocketServer.new()
	server.listen(LISTEN_PORT, PoolStringArray(), true)
	get_tree().set_network_peer(server)
	get_tree().connect("network_peer_connected", self, "client_connected")
	get_tree().connect("network_peer_disconnected", self, "client_disconnected")
	
	print('Listening on port %s.' % LISTEN_PORT)

func client_connected(id: int):
	print('Client %s connected!' % str(id))
	var client = load("res://Client.tscn").instance()
	client.initialize(id)
	client.set_name(str(id))
	clients.add_child(client)
	client.connect('CREATE_ROOM', self, '_on_client_create_room')
	client.connect('JOIN_ROOM', self, '_on_client_join_room')
	emit_signal('CLIENT_CONNECTION_READY', id)

func client_disconnected(id: int):
	print('Client %s disconnected!' % str(id))
	get_node("root/clients/%s" % str(id)).queue_free()

func _process(delta: float):
	if server.is_listening():
		server.poll()

func _on_client_create_room(client_id: int, game_name: String):
	var response = get_node('/root/games').create_room(client_id, game_name)
	get_node('/root/clients/%s' % str(client_id)).confirm_create(response)

func _on_client_join_room(client_id: int, room_code: int):
	var response = get_node('/root/games').join_room(client_id, room_code)
	get_node('/root/clients/%s' % str(client_id)).confirm_join(response)