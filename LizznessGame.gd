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
		'nick': str(client_id),
		'admin': true
	})
	self.room_code = room_code

func attempt_add(client_id: int):
	for player in players:
		if client_id == player['id']:
			print('Player %s is already in room %s. Not re-adding.' % [str(client_id), str(room_code)])
			return {
				'success': true,
				'reason': 0000
			}
	print('Attempting to add player %s to room %s.' % [str(client_id), str(room_code)])
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
	print('Player %s joined room %s' % [str(client_id), str(room_code)])
	players.append({
		'id': client_id,
		'nick': str(client_id),
		'admin': false
	})
	
	var player_obj = get_node('/root/clients/%s' % str(client_id))
	player_obj.connect('DISCONNECTED', self, '_on_player_disconnect')
	
	synchronize_player_list()

func synchronize_player_list():
	print('Notifying the following players: %s' % str(players))
	for player in players:
		print('\n\t> Notifying player %s.' % str(player['id']))
		rpc_id(int(player['id']), 'update_player_list', {
			'players': players
		})

func _on_player_disconnect(id):
	var new_player_list = []
	for player in players:
		if player['id'] != id:
			new_player_list.append(player)
	
	players = new_player_list
	synchronize_player_list()