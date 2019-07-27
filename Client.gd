extends Node

signal CREATE_ROOM
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
	rpc_id(id, 'join_game_response', response)

func confirm_join(response):
	rpc_id(id, 'join_game_response', response)