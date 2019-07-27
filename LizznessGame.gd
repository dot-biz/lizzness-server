extends Node

export var MAX_PLAYERS: int = 8

var players = []
var room_code: int

func _ready():
	pass

func initialize(client_id: int, room_code: int):
	players.append({
		'id': client_id,
		'admin': true
	})
	self.room_code = room_code

func attempt_add(client_id: int):
	return len(players) < MAX_PLAYERS