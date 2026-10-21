extends Control
## Multiplayer (1v1 race): open rooms list, Create room dialog (variant, difficulty, optional password),
## password prompt for locked rooms, and the room view (players + Start for the host).

var col: VBoxContainer
var list_box: VBoxContainer
var dialog: Control
var _refresh_clock := 0.0
var _joining := false
var _picker_close := Callable()   # closes the open Mode list (a click elsewhere in the dialog)


func setup(_params: Dictionary) -> void:
	var parts := UI.page(900, 44)
	add_child(parts[0])
	col = parts[1]
	Net.rooms_listed.connect(_on_rooms)
	Net.room_entered.connect(_on_room_entered)
	Net.opponent_joined.connect(func(_n): _rebuild())
	Net.opponent_left.connect(func():
		UI.toast("Your opponent left the room." if Net.is_host else "The host left, so the room was closed.")
		_rebuild())
	Net.recheck_steam()
	_rebuild()


func on_leave() -> void:
	pass   # staying in a room while browsing is fine; the room view's Leave button leaves it


func _process(delta: float) -> void:
	if Net.in_room or dialog != null:
		return
	_refresh_clock -= delta
	if _refresh_clock <= 0.0:
		_refresh_clock = 4.0
		Net.refresh_rooms()


func _clear() -> void:
	for c in col.get_children():
		c.queue_free()
	list_box = null


func _rebuild() -> void:
	_clear()
	col.add_child(UI.heading("Multiplayer", 46))
	var sub := UI.label("1v1 race: the same puzzle for both players, side by side. First to finish wins.", 17, UI.INK_MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)
	var notice := _steam_notice()
	if notice != null:
		col.add_child(notice)
	if not Net.available():
		var again := UI.button("Check again", "PrimaryButton", _recheck)
		again.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		col.add_child(again)
		return
	if OS.is_debug_build() and not Net.in_room:
		var tm := CheckButton.new()
		tm.text = "Test mode: play two game windows on this PC (editor builds only)"
		tm.focus_mode = Control.FOCUS_NONE
		tm.button_pressed = Net.test_mode()
		tm.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		tm.toggled.connect(func(on):
			Net.set_test_mode(on)
			_rebuild.call_deferred())
		col.add_child(tm)
	if Net.in_room:
		_build_room()
	else:
		_build_list()


func _card_text(title: String, body: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 22))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(UI.label(title, 20, UI.INK, UI.font_sans_bold))
	var l := UI.label(body, 15, UI.INK_MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	p.add_child(v)
	return p


## Explains why Steam isn't used (if it isn't). Steam is checked again on Refresh.
func _steam_notice() -> Control:
	var title := ""
	var body := ""
	match Net.steam_state():
		"ok":
			return null
		"test":
			title = "Test mode is on"
			body = "Rooms are only visible to other game windows on this PC, even though Steam is running."
		"no_plugin":
			if SteamManager.client_running():
				title = "Steam is running, but this build can't use it yet"
			else:
				title = "Steam support isn't installed in this build"
			body = "The GodotSteam plugin is missing from addons/. Install it from Godot's AssetLib tab (search \"GodotSteam GDExtension\"), then reload the project."
		"not_running":
			title = "Steam isn't running"
			body = "Start Steam and sign in, then press Refresh."
		_:
			title = "Steam is running, but the game couldn't connect to it"
			body = "Make sure you're signed in, then press Refresh. (Steam error %d)" % SteamManager.last_status
	if Net.backend == "local" and not Net.test_mode():
		body += "
Test mode for now: rooms are only visible to other game windows on this PC."
	var p := _card_text(title, body)
	p.add_theme_stylebox_override("panel", UI.box(UI.GOLD_SOFT, Color(UI.GOLD, 0.5), UI.RADIUS, 1, 18))
	for l in p.get_child(0).get_children():
		l.add_theme_color_override("font_color", UI.GOLD_TEXT)
	return p


## Refresh: pick up Steam if it was started since, then reload the room list.
func _recheck() -> void:
	var before := Net.backend
	Net.recheck_steam()
	if Net.backend != before:
		UI.toast("Connected to Steam." if Net.backend == "steam" else "Steam still isn't available.")
		_rebuild()
		return
	_refresh_clock = 4.0
	Net.refresh_rooms()
	if Net.backend != "steam":
		_rebuild()


static func _variant_text(v: String) -> String:
	return "Random variant" if v == "random" else Variants.display_name(v)


# ------------------------------------------------------------------ rooms list

func _build_list() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var t := UI.label("Open rooms", 24, UI.INK, UI.font_serif)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	row.add_child(UI.button("Refresh", "", _recheck))
	row.add_child(UI.button("Create room", "PrimaryButton", _open_create))
	col.add_child(row)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 10)
	col.add_child(list_box)
	list_box.add_child(UI.label("Looking for rooms…", 15, UI.INK_MUTED))
	_refresh_clock = 0.0


func _on_rooms(rooms: Array) -> void:
	if list_box == null or not is_instance_valid(list_box):
		return
	for c in list_box.get_children():
		c.queue_free()
	if rooms.is_empty():
		list_box.add_child(_card_text("No open rooms right now", "Create one and wait for an opponent, or refresh in a moment."))
		return
	for r in rooms:
		list_box.add_child(_room_row(r))


func _room_row(r: Dictionary) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 16))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var icon := VariantIcon.new(str(r.variant) if r.variant != "random" else "classic", 34)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icon)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	v.add_child(UI.label(str(r.name), 18, UI.INK, UI.font_sans_bold))
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 8)
	info.add_child(UI.label(_variant_text(str(r.variant)), 15, UI.INK_MUTED))
	info.add_child(UI.tag(str(r.difficulty).to_upper(), UI.ACCENT, UI.ACCENT_SOFT))
	if r.locked:
		info.add_child(UI.tag("PASSWORD", UI.GOLD_TEXT, UI.GOLD_SOFT))
	v.add_child(info)
	h.add_child(v)
	if r.get("mine", false):
		info.add_child(UI.tag("YOUR ROOM", UI.INK_MUTED, UI.PAPER_WARM))
	var join := UI.button("Join", "PrimaryButton", func(): _join(r))
	if r.get("mine", false):
		join.disabled = true
		join.tooltip_text = "This room belongs to your own Steam account (another game window). Steam allows one account per PC."
	join.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(join)
	return p


func _join(r: Dictionary) -> void:
	if r.locked:
		_open_password(r)
	else:
		_do_join(r, "")


func _do_join(r: Dictionary, pw: String) -> void:
	_close_dialog()
	_joining = true
	UI.toast("Joining %s…" % str(r.name))
	Net.join_room(r, pw)


func _on_room_entered(ok: bool, error: String) -> void:
	_joining = false
	if not ok:
		UI.toast(error)
	_rebuild()


# ------------------------------------------------------------------ room view

func _build_room() -> void:
	var r := Net.room
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 24))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UI.label(str(r.name), 26, UI.INK, UI.font_serif))
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 8)
	info.add_child(UI.label(_variant_text(str(r.variant)), 16, UI.INK_MUTED))
	info.add_child(UI.tag(str(r.difficulty).to_upper(), UI.ACCENT, UI.ACCENT_SOFT))
	if r.get("locked", false):
		info.add_child(UI.tag("PASSWORD", UI.GOLD_TEXT, UI.GOLD_SOFT))
	v.add_child(info)
	if Net.opponent != "" and Net.score.me + Net.score.opp > 0:
		v.add_child(UI.label("Score   You %d – %d %s" % [Net.score.me, Net.score.opp, Net.opponent], 16, UI.INK, UI.font_sans_bold))
	v.add_child(HSeparator.new())
	var me := Net.my_name() + "  (you)"
	var host_name := me if Net.is_host else Net.opponent
	var guest_name := (Net.opponent if Net.opponent != "" else "Waiting for an opponent…") if Net.is_host else me
	for pl in [["HOST", host_name], ["OPPONENT" if Net.is_host else "GUEST", guest_name]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var k := UI.label(pl[0], 12, UI.INK_FAINT, UI.font_sans_bold)
		k.custom_minimum_size = Vector2(90, 0)
		row.add_child(k)
		row.add_child(UI.label(pl[1], 17, UI.INK))
		v.add_child(row)
	v.add_child(HSeparator.new())
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	if Net.is_host:
		var start := UI.button("Start match", "PrimaryButton", func(): Net.start_match())
		start.disabled = Net.opponent == ""
		actions.add_child(start)
		var hint := UI.label("" if Net.opponent != "" else "Others see this room in their list and can join.", 14, UI.INK_MUTED)
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		actions.add_child(hint)
	else:
		var wait := UI.label("Waiting for the host to start the match…", 15, UI.INK_MUTED)
		wait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		actions.add_child(wait)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(sp)
	actions.add_child(UI.button("Leave room", "", func():
		Net.leave()
		_rebuild()))
	v.add_child(actions)
	col.add_child(p)
	col.add_child(ChatPanel.new(260))
	var rules := UI.label("Vanilla rules: no hints, no checks, no mistake limit. Rule conflicts still show if they're on in Settings. Leaving during a match forfeits it.", 14, UI.INK_MUTED)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(rules)


# ------------------------------------------------------------------ dialogs

func _close_dialog() -> void:
	if dialog and is_instance_valid(dialog):
		dialog.queue_free()
	dialog = null
	_picker_close = Callable()


## Dimmed full-screen layer with a centred card; click outside or Esc closes it.
func _dialog(title: String) -> VBoxContainer:
	_close_dialog()
	dialog = ColorRect.new()
	(dialog as ColorRect).color = Color(0, 0, 0, 0.4)
	dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_close_dialog())
	add_child(dialog)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 28))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.custom_minimum_size = Vector2(460, 0)
	p.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and _picker_close.is_valid():
			_picker_close.call())
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(UI.heading(title, 30))
	return v


func _field(v: VBoxContainer, label: String) -> void:
	v.add_child(UI.label(label.to_upper(), 12, UI.INK_MUTED, UI.font_sans_bold))


func _open_create() -> void:
	var v := _dialog("Create room")
	_field(v, "Room name")
	var room_name := LineEdit.new()
	room_name.placeholder_text = "%s's room" % Net.my_name()
	room_name.max_length = 32
	room_name.text = str(GameState.settings.get("mp_room_name", ""))
	v.add_child(room_name)
	_field(v, "Mode")
	var picked := [str(GameState.settings.get("mp_variant", "classic"))]
	v.add_child(_variant_picker(picked))

	_field(v, "Difficulty")
	var diff_row := GridContainer.new()   # 6 levels: two rows of three
	diff_row.columns = 3
	diff_row.add_theme_constant_override("h_separation", 8)
	diff_row.add_theme_constant_override("v_separation", 8)
	var chosen := [str(GameState.settings.get("mp_difficulty", "medium"))]
	var chips := {}
	for d in GameState.DIFFICULTIES:
		var b := UI.button(d.capitalize(), "ChipButton")
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.button_pressed = d == chosen[0]
		chips[d] = b
		diff_row.add_child(b)
	for d in chips:
		chips[d].pressed.connect(func():
			chosen[0] = d
			for k in chips: chips[k].button_pressed = k == d)
	v.add_child(diff_row)

	var lock := CheckButton.new()
	lock.text = "Password protected"
	lock.focus_mode = Control.FOCUS_NONE
	v.add_child(lock)
	var pw := LineEdit.new()
	pw.placeholder_text = "Password"
	pw.secret = true
	pw.max_length = 32
	pw.visible = false
	v.add_child(pw)
	lock.toggled.connect(func(on):
		pw.visible = on
		if on: pw.grab_focus())

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	row.add_child(UI.button("Cancel", "", _close_dialog))
	row.add_child(UI.button("Create", "PrimaryButton", func():
		if lock.button_pressed and pw.text.strip_edges() == "":
			UI.toast("Enter a password or turn off password protection.")
			return
		var vid: String = picked[0]
		GameState.settings.mp_variant = vid
		GameState.settings.mp_difficulty = chosen[0]
		GameState.settings.mp_room_name = room_name.text.strip_edges()
		GameState.save_settings()
		_close_dialog()
		Net.create_room({"name": room_name.text, "variant": vid, "difficulty": chosen[0],
			"password": pw.text.strip_edges() if lock.button_pressed else ""})))
	v.add_child(row)


## Searchable drop-down: the field shows the chosen variant; click it (or start typing) to open the list,
## type to filter, Enter takes the first match, click an item to pick it. picked[0] = "random" or an id.
func _variant_picker(picked: Array) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var field := LineEdit.new()
	field.placeholder_text = "Search variants…"
	field.right_icon = null
	box.add_child(field)
	var arrow := UI.label("▾", 16, UI.INK_MUTED)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	arrow.offset_left = -34
	arrow.offset_right = -16
	field.add_child(arrow)
	var list := ItemList.new()
	list.custom_minimum_size = Vector2(0, 230)
	list.focus_mode = Control.FOCUS_NONE
	list.visible = false
	box.add_child(list)
	var ids: Array = Variants.CORE.duplicate()
	ids.sort_custom(func(a, b): return Variants.display_name(a) < Variants.display_name(b))
	ids.push_front("random")
	var fill := func(filter: String):
		list.clear()
		var f := filter.strip_edges().to_lower()
		for id in ids:
			var nm := _variant_text(id)
			if f != "" and not nm.to_lower().contains(f):
				continue
			list.add_item(nm)
			list.set_item_metadata(list.item_count - 1, id)
			if id == picked[0]:
				list.select(list.item_count - 1)
		if list.item_count == 0:
			list.add_item("No variant matches \"%s\"" % filter.strip_edges(), null, false)
	var open := func():
		if list.visible:
			return
		list.visible = true
		arrow.text = "▴"
		field.text = ""
		field.placeholder_text = "Search variants…  (now: %s)" % _variant_text(picked[0])
		fill.call("")
	var close := func():
		list.visible = false
		arrow.text = "▾"
		field.text = _variant_text(picked[0])
		field.placeholder_text = "Search variants…"
	var choose := func(i: int):
		if i < 0 or i >= list.item_count or list.get_item_metadata(i) == null:
			return
		picked[0] = str(list.get_item_metadata(i))
		close.call()
		field.release_focus()
	var opened_at := [-1]   # frame the list opened (the same click that focuses shouldn't close it)
	field.focus_entered.connect(func():
		open.call()
		opened_at[0] = Engine.get_process_frames())
	field.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if not list.visible:
				open.call()
			elif field.text == "" and Engine.get_process_frames() - opened_at[0] > 1:
				close.call()
				field.release_focus.call_deferred())
	field.text_changed.connect(func(t):
		open.call()
		fill.call(t))
	field.text_submitted.connect(func(_t): choose.call(0))
	list.item_clicked.connect(func(i, _pos, mb):
		if mb == MOUSE_BUTTON_LEFT:
			choose.call(i))
	# Not on focus loss: scrolling the list with the wheel takes focus from the field.
	_picker_close = func():
		if is_instance_valid(list) and list.visible:
			close.call()
	close.call()
	return box


func _open_password(r: Dictionary) -> void:
	var v := _dialog("Password needed")
	var l := UI.label("%s is password protected." % str(r.name), 15, UI.INK_MUTED)
	v.add_child(l)
	var pw := LineEdit.new()
	pw.placeholder_text = "Password"
	pw.secret = true
	pw.max_length = 32
	v.add_child(pw)
	pw.text_submitted.connect(func(_t): _do_join(r, pw.text.strip_edges()))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	row.add_child(UI.button("Cancel", "", _close_dialog))
	row.add_child(UI.button("Join", "PrimaryButton", func(): _do_join(r, pw.text.strip_edges())))
	v.add_child(row)
	pw.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if dialog and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_dialog()
		get_viewport().set_input_as_handled()
