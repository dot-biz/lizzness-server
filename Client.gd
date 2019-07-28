extends Node

signal CREATE_ROOM
signal DISCONNECTED
signal JOIN_ROOM

var id: int
var nickname: String

func initialize(id: int):
	self.id = id
	self.nickname = str(id)

remote func create_room(game_name: String):
	emit_signal('CREATE_ROOM', get_tree().get_rpc_sender_id(), game_name)

remote func join_room(room_code: int):
	emit_signal('JOIN_ROOM', get_tree().get_rpc_sender_id(), room_code)

func confirm_create(response):
	rpc_id(id, 'create_game_response', response)
	if response['success']:
		emit_signal('JOIN_ROOM', get_tree().get_rpc_sender_id(), response['room_code'])

func confirm_join(response):
	rpc_id(id, 'join_game_response', response)
	if response['success']:
		get_node('/root/games/%s' % str(response['room_code'])).synchronize_player_list()

func pre_delete():
	emit_signal('DISCONNECTED', id)

func kick(reason):
	rpc_id(id, 'server_force_disconnect', reason)
	get_node('/root/Server').client_disconnected(id)