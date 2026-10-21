extends Node
## 1v1 race multiplayer: room list, create / join (optional password) and a small message channel
## between the two players of a room. The host decides who finished first.
##
## Backends:
##   "steam"  Steam lobbies (GodotSteam). A room is a public 2-player lobby tagged lw=1; messages are
##            lobby chat messages, relayed by Steam, so nobody needs to open ports.
##   "local"  Debug builds only, when Steam isn't running: rooms on this PC, for testing with two game
##            windows. Rooms are files in user://mp_local/ and the players talk over UDP on 127.0.0.1.
##
## Messages are small JSON dictionaries with a type "t":
##   hello {name, pw}   guest -> host when joining (pw = hash of the password, "" if none)
##   welcome {name} / deny {reason}   host -> guest
##   start {v, d, id}   host -> guest: race this pack puzzle (both go to the game screen)
##   prog {cells}       81 chars, "1" = cell filled (the opponent sees which cells, never the digits)
##   done {time}        guest -> host: guest solved it
##   result {winner, host_time, guest_time}   host -> guest ("host" / "guest")
##   grid {values, bad} at the end of a race: the whole grid (the opponent's fog of war lifts)
##   chat {text}        chat message (max 200 characters)
##   again              "I want to play again"; when both sent it, the host starts a new race
##   ping / bye         keep-alive (local backend) / leaving

signal rooms_listed(rooms: Array)                 # [{id, name, variant, difficulty, locked}]
signal room_entered(ok: bool, error: String)      # after creating (host) or joining + password check (guest)
signal opponent_joined(name: String)
signal opponent_left
signal again_changed                              # play-again state changed (mine or the opponent's)
signal score_changed
signal room_closed                                 # guest: the host left, so we were taken out of the room
signal message(msg: Dictionary)                   # start / prog / done / result / grid
signal chat_received(entry: Dictionary)           # {mine, name, text} or {sys: true, text}

const VERSION := "1"
const LOCAL_DIR := "user://mp_local/"

var backend := ""      # "steam" | "local" | "" (multiplayer unavailable)
var in_room := false
var is_host := false
var room := {}         # {id, name, variant, difficulty, locked}
var opponent := ""     # opponent's name, "" while nobody has joined
var match_params := {} # last "start" message
var chat_log: Array = [] # this room's chat (room view and race share it)
var score := {"me": 0, "opp": 0}   # races won in this room against the current opponent
var again_me := false
var again_opp := false
var _password := ""    # host only
var _pending_pw := ""  # guest only, until the host answers
var _join_timeout := 0.0

# steam
var steam: Object = null
var lobby_id := 0
var my_id := 0
var opp_id := 0

# local
var _udp: PacketPeerUDP = null
var _port := 0
var _beat := 0.0
var _last_heard := 0.0
var _peer_known := false
var _peer_addr := ""
var _steam_hooked := false


func _ready() -> void:
	_pick_backend()


## Uses Steam when it's connected; otherwise the local test backend (debug builds) or nothing.
## Called again by the Multiplayer screen (open / Refresh) so starting Steam later is picked up.
func _pick_backend() -> void:
	if in_room or _join_timeout > 0.0:
		return
	if test_mode():
		backend = "local"
		return
	if SteamManager.try_init():
		backend = "steam"
		_hook_steam()
	elif OS.is_debug_build():
		backend = "local"
	else:
		backend = ""


## Plain-language Steam state for the Multiplayer screen.
## "ok" | "no_plugin" (build has no GodotSteam) | "not_running" | "failed"
func steam_state() -> String:
	if test_mode():
		return "test"
	if backend == "steam":
		return "ok"
	if not SteamManager.plugin_installed():
		return "no_plugin"
	if SteamManager.last_status == 2 or not SteamManager.client_running():
		return "not_running"
	return "failed"


## Debug builds only: play two game windows on this PC even while Steam is running
## (Steam allows one account per PC, so two windows on one account can't play each other).
func test_mode() -> bool:
	return OS.is_debug_build() and bool(GameState.settings.get("mp_test_mode", false))


func set_test_mode(on: bool) -> void:
	if in_room or _join_timeout > 0.0:
		return
	GameState.settings.mp_test_mode = on
	GameState.save_settings()
	backend = ""
	_pick_backend()


func recheck_steam() -> void:
	_pick_backend()


func _hook_steam() -> void:
	if _steam_hooked:
		return
	_steam_hooked = true
	steam = SteamManager.steam
	my_id = int(steam.call("getSteamID"))
	# Optional args: signal signatures differ slightly between GodotSteam versions.
	steam.connect("lobby_created", func(a = null, b = null): _steam_created(a, b))
	steam.connect("lobby_match_list", func(a = null): _steam_list(a))
	steam.connect("lobby_joined", func(a = null, _b = null, _c = null, d = null): _steam_joined(a, d))
	steam.connect("lobby_message", func(a = null, b = null, c = null, _d = null): _steam_message(a, b, c))
	steam.connect("lobby_chat_update", func(a = null, b = null, _c = null, d = null): _steam_chat_update(a, b, d))


## Quitting (Quit button, closing the window): leave the room so the opponent wins straight away
## instead of waiting for a time-out.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		if in_room or _join_timeout > 0.0:
			leave()


func available() -> bool:
	return backend != ""


func my_name() -> String:
	if backend == "steam":
		return SteamManager.persona_name()
	return "Player %d" % (OS.get_process_id() % 1000)


func _hash_pw(room_id, pw: String) -> String:
	return "" if pw == "" else ("%s:%s" % [str(room_id), pw]).sha256_text()


# ------------------------------------------------------------------ public API

func refresh_rooms() -> void:
	match backend:
		"steam":
			steam.call("addRequestLobbyListStringFilter", "lw", "1", 0)
			steam.call("addRequestLobbyListStringFilter", "ver", VERSION, 0)
			steam.call("addRequestLobbyListStringFilter", "state", "open", 0)
			steam.call("addRequestLobbyListDistanceFilter", 3)   # worldwide
			steam.call("requestLobbyList")
		"local":
			rooms_listed.emit(_local_rooms())
		_:
			rooms_listed.emit([])


## settings: {name ("" = "<player>'s room"), variant ("random" or an id), difficulty, password ("" = open room)}
func create_room(settings: Dictionary) -> void:
	leave()
	is_host = true
	_password = str(settings.get("password", ""))
	var room_name := str(settings.get("name", "")).strip_edges().left(32)
	if room_name == "":
		room_name = "%s's room" % my_name()
	room = {"id": 0, "name": room_name, "variant": str(settings.variant),
		"difficulty": str(settings.difficulty), "locked": _password != ""}
	match backend:
		"steam":
			steam.call("createLobby", 2, 2)   # public, 2 players
		"local":
			_udp = PacketPeerUDP.new()
			for i in 20:
				_port = 47900 + randi() % 400
				if _udp.bind(_port, "127.0.0.1") == OK:
					break
			room.id = _port
			in_room = true
			_peer_known = false
			_local_write_room()
			room_entered.emit(true, "")
		_:
			room_entered.emit(false, "Multiplayer needs Steam.")


func join_room(r: Dictionary, password := "") -> void:
	if r.get("mine", false):
		room_entered.emit(false, "That's your own room (same Steam account). Steam allows one account per PC: test with a friend, or use Test mode.")
		return
	leave()
	is_host = false
	room = r.duplicate()
	_pending_pw = _hash_pw(r.id, password)
	_join_timeout = 10.0
	match backend:
		"steam":
			steam.call("joinLobby", int(r.id))
		"local":
			_udp = PacketPeerUDP.new()
			_udp.bind(0, "127.0.0.1")
			_udp.set_dest_address("127.0.0.1", int(r.id))
			_peer_known = true
			_last_heard = Time.get_ticks_msec() / 1000.0
			_send_raw({"t": "hello", "name": my_name(), "pw": _pending_pw})


func leave() -> void:
	if in_room or _join_timeout > 0.0:
		_send_raw({"t": "bye"})
	match backend:
		"steam":
			if lobby_id != 0:
				steam.call("leaveLobby", lobby_id)
		"local":
			if is_host and _port != 0:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(LOCAL_DIR + "%d.json" % _port))
			if _udp:
				_udp.close()
	_udp = null
	_port = 0
	lobby_id = 0
	opp_id = 0
	in_room = false
	opponent = ""
	_join_timeout = 0.0
	match_params = {}
	chat_log.clear()
	score = {"me": 0, "opp": 0}
	again_me = false
	again_opp = false


## Host only: pick the puzzle and start the race for both players.
func start_match() -> void:
	if not is_host or opponent == "":
		return
	var v: String = room.variant
	if v == "random":
		v = Variants.CORE.pick_random()
	var d: String = room.difficulty
	var pool := GameState.pack_puzzles(v, d)
	if pool.is_empty():
		UI.toast("No puzzles for this variant.")
		return
	var pz: Dictionary = pool.pick_random()
	var msg := {"t": "start", "v": v, "d": d, "id": str(pz.get("id", ""))}
	send(msg)
	_begin(msg)


func send(msg: Dictionary) -> void:
	_send_raw(msg)


## After a race: count it for the room's score.
func record_result(won: bool) -> void:
	score[("me" if won else "opp")] += 1
	score_changed.emit()


func _reset_room_state() -> void:
	score = {"me": 0, "opp": 0}
	again_me = false
	again_opp = false
	score_changed.emit()
	again_changed.emit()


## "Play again": when both players asked, the host starts the next race.
func want_again() -> void:
	if again_me or not in_room or opponent == "":
		return
	again_me = true
	_send_raw({"t": "again"})
	again_changed.emit()
	_check_again()


func _check_again() -> void:
	if is_host and again_me and again_opp:
		start_match()


func send_chat(text: String) -> void:
	text = text.strip_edges().left(200)
	if text == "" or not in_room:
		return
	_send_raw({"t": "chat", "text": text})
	_chat({"mine": true, "name": my_name(), "text": text})


func _chat(entry: Dictionary) -> void:
	chat_log.append(entry)
	if chat_log.size() > 200:
		chat_log.pop_front()
	chat_received.emit(entry)


# ------------------------------------------------------------------ messages

func _send_raw(msg: Dictionary) -> void:
	var text := JSON.stringify(msg)
	match backend:
		"steam":
			if lobby_id != 0:
				steam.call("sendLobbyChatMsg", lobby_id, text)
		"local":
			if _udp and _peer_known:
				_udp.put_packet(text.to_utf8_buffer())


func _handle(msg: Dictionary, sender := 0) -> void:
	match str(msg.get("t", "")):
		"hello":
			if not is_host:
				return
			if opponent != "":
				_send_raw({"t": "deny", "reason": "The room is full."})
				return
			if room.locked and str(msg.get("pw", "")) != _hash_pw(room.id, _password):
				_send_raw({"t": "deny", "reason": "Wrong password."})
				return
			opponent = str(msg.get("name", "Opponent"))
			opp_id = sender
			_send_raw({"t": "welcome", "name": my_name()})
			_set_open(false)
			_chat({"sys": true, "text": "%s joined the room." % opponent})
			_reset_room_state()
			opponent_joined.emit(opponent)
		"welcome":
			if is_host or in_room:
				return
			opponent = str(msg.get("name", "Host"))
			in_room = true
			chat_log.clear()
			_reset_room_state()
			_chat({"sys": true, "text": "You joined %s." % str(room.get("name", "the room"))})
			_join_timeout = 0.0
			room_entered.emit(true, "")
		"deny":
			if is_host or in_room:
				return
			var reason := str(msg.get("reason", "Couldn't join."))
			_join_timeout = 0.0
			leave()
			room_entered.emit(false, reason)
		"bye":
			_on_opponent_gone()
		"ping":
			pass
		"chat":
			if in_room:
				Audio.play("chat")
				_chat({"mine": false, "name": opponent if opponent != "" else "Opponent",
					"text": str(msg.get("text", "")).strip_edges().left(200)})
		"start":
			if not is_host:
				_begin(msg)
		"again":
			if in_room and not again_opp:
				again_opp = true
				again_changed.emit()
				_check_again()
		_:
			message.emit(msg)


func _begin(msg: Dictionary) -> void:
	match_params = msg
	again_me = false
	again_opp = false
	GameState.go("game", {"versus": msg})


func _on_opponent_gone() -> void:
	if opponent == "" and not (not is_host and _join_timeout > 0.0):
		return
	if is_host:
		_chat({"sys": true, "text": "%s left the room." % opponent})
		_reset_room_state()
		opponent = ""
		opp_id = 0
		_peer_known = false
		_set_open(true)
		opponent_left.emit()
	else:
		var was_in := in_room
		leave()   # the host's room goes with the host
		if was_in:
			opponent_left.emit()
			room_closed.emit()
		else:
			room_entered.emit(false, "The room was closed.")


## Host: list the room again (nobody in it) or hide it (opponent joined).
func _set_open(open: bool) -> void:
	match backend:
		"steam":
			if lobby_id != 0:
				steam.call("setLobbyData", lobby_id, "state", "open" if open else "full")
				steam.call("setLobbyJoinable", lobby_id, open)
		"local":
			_local_write_room()


func _process(delta: float) -> void:
	if _join_timeout > 0.0 and not in_room:
		_join_timeout -= delta
		if _join_timeout <= 0.0:
			leave()
			room_entered.emit(false, "No answer from the room.")
	if backend != "local" or _udp == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	while _udp != null and _udp.get_available_packet_count() > 0:
		var pkt := _udp.get_packet()
		var from := "%s:%d" % [_udp.get_packet_ip(), _udp.get_packet_port()]
		if is_host:
			if opponent == "":   # answer whoever is knocking until someone is let in
				_udp.set_dest_address(_udp.get_packet_ip(), _udp.get_packet_port())
				_peer_known = true
				_peer_addr = from
			elif from != _peer_addr:
				continue   # a third window trying a full room
		_last_heard = now
		var data = JSON.parse_string(pkt.get_string_from_utf8())
		if data is Dictionary:
			_handle(data)
	if _udp == null:
		return   # a message made us leave the room
	if now - _beat > 1.0:
		_beat = now
		if is_host:
			_local_write_room()
		if _peer_known:
			_send_raw({"t": "ping"})
	if _peer_known and (in_room or _join_timeout > 0.0) and (opponent != "" or not is_host) and now - _last_heard > 5.0:
		_on_opponent_gone()


# ------------------------------------------------------------------ local backend (testing on one PC)

func _local_write_room() -> void:
	if _port == 0:
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOCAL_DIR))
	var f := FileAccess.open(LOCAL_DIR + "%d.json" % _port, FileAccess.WRITE)
	if f:
		var r := room.duplicate()
		r.beat = Time.get_unix_time_from_system()
		r.full = opponent != ""
		f.store_string(JSON.stringify(r))


func _local_rooms() -> Array:
	var out: Array = []
	var dir := DirAccess.open(LOCAL_DIR)
	if dir == null:
		return out
	var now := Time.get_unix_time_from_system()
	for fn in dir.get_files():
		var data = JSON.parse_string(FileAccess.get_file_as_string(LOCAL_DIR + fn))
		if not (data is Dictionary):
			continue
		if now - float(data.get("beat", 0)) > 4.0:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(LOCAL_DIR + fn))
			continue
		if bool(data.get("full", false)) or int(data.get("id", 0)) == _port:
			continue
		out.append({"id": int(data.id), "name": str(data.name), "variant": str(data.variant),
			"difficulty": str(data.difficulty), "locked": bool(data.locked)})
	return out


# ------------------------------------------------------------------ steam backend

func _steam_created(result, id) -> void:
	if int(result) != 1:
		is_host = false
		room_entered.emit(false, "Steam couldn't create the room (error %s)." % str(result))
		return
	lobby_id = int(id)
	room.id = lobby_id
	in_room = true
	for kv in [["lw", "1"], ["ver", VERSION], ["name", room.name], ["variant", room.variant],
			["difficulty", room.difficulty], ["locked", "1" if room.locked else "0"], ["state", "open"]]:
		steam.call("setLobbyData", lobby_id, kv[0], kv[1])
	room_entered.emit(true, "")


func _steam_list(lobbies) -> void:
	var out: Array = []
	for id in (lobbies if lobbies is Array else []):
		var lid := int(id)
		if lid == lobby_id or int(steam.call("getNumLobbyMembers", lid)) >= 2:
			continue
		out.append({"id": lid, "mine": int(steam.call("getLobbyOwner", lid)) == my_id,
			"name": str(steam.call("getLobbyData", lid, "name")),
			"variant": str(steam.call("getLobbyData", lid, "variant")),
			"difficulty": str(steam.call("getLobbyData", lid, "difficulty")),
			"locked": str(steam.call("getLobbyData", lid, "locked")) == "1"})
	rooms_listed.emit(out)


func _steam_joined(id, response) -> void:
	if is_host:
		return   # the creator also gets this
	if int(response) != 1:
		_join_timeout = 0.0
		room_entered.emit(false, "Couldn't join the room (it may be full or closed).")
		return
	lobby_id = int(id)
	opp_id = int(steam.call("getLobbyOwner", lobby_id))
	_send_raw({"t": "hello", "name": my_name(), "pw": _pending_pw})


func _steam_message(id, user, text) -> void:
	if int(id) != lobby_id or int(user) == my_id:
		return
	var data = JSON.parse_string(str(text))
	if data is Dictionary:
		_handle(data, int(user))


func _steam_chat_update(id, changed, state) -> void:
	if int(id) != lobby_id or int(changed) == my_id:
		return
	if int(state) & (2 | 4 | 8 | 16):   # left / disconnected / kicked / banned
		if (is_host and int(changed) == opp_id) or (not is_host and int(changed) == opp_id):
			_on_opponent_gone()
