class_name ChatPanel
extends PanelContainer
## Room / race chat: message list + input. Messages live in Net.chat_log, so the room view and the
## game screen show the same conversation. Plain Labels only (no BBCode), max 200 characters.

var _list: VBoxContainer
var _scroll: ScrollContainer
var _input: LineEdit


func _init(height := 220.0) -> void:
	custom_minimum_size = Vector2(0, height)
	add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, 12, 1, 12))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	v.add_child(UI.label("CHAT", 12, UI.INK_MUTED, UI.font_sans_bold))
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	_scroll.add_child(_list)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	_input = LineEdit.new()
	_input.placeholder_text = "Say something…"
	_input.max_length = 200
	_input.keep_editing_on_text_submit = true   # Enter sends and you keep typing
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.text_submitted.connect(func(_t): _send())
	_input.gui_input.connect(func(e):
		if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
			_input.release_focus()
			_input.accept_event())
	row.add_child(_input)
	row.add_child(UI.button("Send", "", _send))


func _ready() -> void:
	for e in Net.chat_log:
		_add(e)
	if Net.chat_log.is_empty():
		var hint := UI.label("Messages appear here.", 13, UI.INK_FAINT)
		hint.name = "Hint"
		_list.add_child(hint)
	Net.chat_received.connect(_add)
	_to_bottom.call_deferred()


func _send() -> void:
	Net.send_chat(_input.text)
	_input.text = ""
	_input.grab_focus.call_deferred()   # also after clicking Send


func _add(e: Dictionary) -> void:
	var hint := _list.get_node_or_null("Hint")
	if hint:
		hint.queue_free()
	if e.get("sys", false):
		var s := UI.label(str(e.text), 13, UI.INK_FAINT)
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(s)
	else:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		box.add_child(UI.label(str(e.name), 12, UI.ACCENT if e.mine else UI.GOLD, UI.font_sans_bold))
		var t := UI.label(str(e.text), 15, UI.INK)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(60, 0)
		box.add_child(t)
		_list.add_child(box)
	_to_bottom.call_deferred()


func _to_bottom() -> void:
	await get_tree().process_frame
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
