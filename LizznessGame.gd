extends Node

export var MAX_PLAYERS: int = 8
export var MIN_PLAYERS: int = 5
signal READY_TO_START
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
	if len(players) < MAX_PLAYERS:
		addPlayer(client_id)
		return {
			'success': true,
			'reason': 0000
		}
	else:
		return {
			'success': false,
			'reason': 1501	
		}
	
func addPlayer(client_id: int):
	players.append({
		'id': client_id,
		'admin': false	
	})
	if len(players) >= 5:
		emit_signal("READY_TO_START", room_code)