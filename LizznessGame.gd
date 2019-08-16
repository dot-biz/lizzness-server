extends Node

export var MAX_PLAYERS: int = 18
export var MIN_PLAYERS: int = 5
signal READY_TO_START

const PLAYER_COLORS = [Color.blue, Color.black, Color.red, Color.darkgreen, Color.darkorange, Color.blueviolet]

var players = []
var room_code: int

enum {STATE_LOBBY, STATE_PLAYING, STATE_DISSOLVING}
enum {GAME_DAY_MORNING, GAME_DAY_WORKDAY, GAME_DAY_AFTERNOON, GAME_DAY_MIDNIGHT}
enum CLIENT_ROLE {GUEST, ADMIN, HOST}
var game_state: int
var day_number: int
var day_state: int

var human_win_count: int

func _ready():
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnect")

func initialize(client_id: int, room_code: int):
	players.append({
		'id': client_id,
		'nick': str(client_id),
		'role': CLIENT_ROLE.HOST,
		'color': Color.black
	})
	self.room_code = room_code
	self.game_state = STATE_LOBBY

func attempt_add(client_id: int):
	for player in players:
		if client_id == player['id']:
			print('Player %s is already in room %s. Not re-adding.' % [str(client_id), str(room_code)])
			return {
				'success': true,
				'reason': 0000,
				'player': player
			}
	print('Attempting to add player %s to room %s.' % [str(client_id), str(room_code)])
	if len(players) < MAX_PLAYERS:
		var player_struct = addPlayer(client_id)
		return {
			'success': true,
			'reason': 0000,
			'player': player_struct
		}
	else:
		return {
			'success': false,
			'reason': 1501
		}

func addPlayer(client_id: int):
	print('Player %s joined room %s' % [str(client_id), str(room_code)])
	var player_dict = {
		'id': client_id,
		'nick': str(client_id),
		'role': CLIENT_ROLE.GUEST,
		'color': PLAYER_COLORS[randi() % len(PLAYER_COLORS)]
	}
	
	players.append(player_dict)
	
	var player_obj = get_node('/root/clients/%s' % str(client_id))
	
	synchronize_player_list()
	
	return player_dict

func synchronize_player_list():
	print('Checking if screen/admin both exist.')
	var admin_exists = false
	var screen_exists = false
	for player in players:
		if player['role'] == CLIENT_ROLE.ADMIN:
			admin_exists = true
		if player['role'] == CLIENT_ROLE.HOST:
			screen_exists = true
	
	if not screen_exists:
		print('\t> Screen disconnected! Dissolving room!')
		do_room_dissolve({
			'reason': 9000,
			'human': 'The player who started the game has disconnected!'
		})
		return
	else:
		print('\t> Screen still connected.')
	
	if not admin_exists:
		if len(players) == 1:
			print('\t> No admin exists, but no players have connected yet.')
		else:
			print('\t> No admin exists! Promoting first player!')
			for player in players:
				if player['role'] != CLIENT_ROLE.HOST:
					print('\t> Promoting player %s.' % str(player['id']))
					player['role'] = CLIENT_ROLE.ADMIN
					break
	
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

remote func change_nick(new_nick):
	if not validate_nick(new_nick):
		return
	var requesting_player_id = get_tree().get_rpc_sender_id()
	var change = false
	for player in players:
		if player['id'] == requesting_player_id:
			player['nick'] = new_nick
			change = true
	
	if change:
		synchronize_player_list()

func validate_nick(nick):
	return len(nick) >= 1 and len(nick) <= 8

remote func start_game():
	if game_state != STATE_LOBBY:
		return
	var requesting_player_id = get_tree().get_rpc_sender_id()
	for player in players:
		if player['id'] == requesting_player_id and player['role'] == CLIENT_ROLE.ADMIN and len(players) >= MIN_PLAYERS and len(players) <= MAX_PLAYERS:
			_do_game_start()

func _do_game_start():
	game_state = STATE_PLAYING
	day_number = 0
	day_state = GAME_DAY_MORNING
	
	for player in players:
		rpc_id(player['id'], 'game_state_change', game_state, day_number, day_state)

func do_room_dissolve(reason):
	game_state = STATE_DISSOLVING
	for player in players:
		get_node('/root/clients/%s' % player['id']).kick(reason)
	get_node('/root/games').finish_dissolve(self)