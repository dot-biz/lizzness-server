extends Node

const GAME_NAMES = {
	'Lizzness': preload('res://LizznessGame.tscn')
}

func _ready():
	pass

func create_room(client_id: int, game_name: String):
	if not (game_name in GAME_NAMES):
		return {
			'success': false,
			'reason': 1000
		}
	
	var room_code = randi() % 10000
	
	var game = GAME_NAMES[game_name].instance()
	game.set_name(str(room_code))
	add_child(game)
	game.initialize(client_id, room_code)
	
	game.connect('READY_TO_START', self, '_ready_to_start')
	return {
		'success': true,
		'reason': 0000,
		'room_code': room_code
	}
	
func join_room(client_id: int, room_code: int):
	if not has_node(str(room_code)):
		return {
			'success': false,
			'reason': 1500
		}
	
	var room = get_node('/root/games/%s' % str(room_code))
	var add_attempt = room.attempt_add(client_id)
	if not add_attempt['success']:
		return add_attempt
	
	return {
		'success': true,
		'reason': 0000,
		'room_code': room_code,
		'player': add_attempt['player']
	}

func finish_dissolve(room):
	room.queue_free()