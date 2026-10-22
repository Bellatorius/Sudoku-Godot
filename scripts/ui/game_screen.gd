extends Control
## Play screen: board, number pad, note modes, undo/redo, hints, timer, pause, autosave, win dialog.

var session: Session
var board: Board
var slot := ""
var daily_date := ""
var mode := "normal"
var _shown_mode := ""
var paused := false
var _dirty := false
var _save_clock := 0.0
var _thread: Thread
var _gen_params := {}
## Dev cheats, only in debug builds (running from the editor), never in exported release builds:
##   ← ← → ← ↑          fill and finish the puzzle
##   → → ←               fill every cell but one
const CHEAT := [KEY_LEFT, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_UP]
const CHEAT_ALL_BUT_ONE := [KEY_RIGHT, KEY_RIGHT, KEY_LEFT]
var _cheat_keys: Array = []
var _cheat_time := 0

var title_l: Label
var diff_tag_holder: HBoxContainer
var timer_l: Label
var mistakes_l: Label
var pause_btn: Button
var mode_btns := {}
var pad_btns: Array = []
var pad_counts: Array = []      # small "how many left" labels on the pad keys
var undo_btn: Button
var redo_btn: Button
var hint_btn: Button
var check_btn: Button
var _lost := false        # mistake limit reached
var _win_next: Button      # main button on the win card (Space / Enter presses it)
var help_layer: Control
var rules_l: Label
var overlay: Control
var overlay_box: VBoxContainer
var board_holder: Control
var left_col: VBoxContainer
var restart_btn: Button
var rules_head: HBoxContainer
var cheat_l: Label
var main_row: HBoxContainer

# Multiplayer race (params.versus = Net's "start" message)
const OPP_W := 250
var versus := {}
var _countdown := 0.0
var _match_over := false
var _opp_cells := ""         # 81 chars, "1" = opponent filled that cell
var _sent_cells := ""
var _opp_bad := ""           # 81 chars, "1" = that opponent cell breaks a rule (shown red through the fog)
var _opp_values := ""        # 81 digits, sent when the race ends: the fog lifts
var opp_note: Label
var score_l: Label
var after_box: VBoxContainer   # after the race: Play again / Main menu (stays while the loser keeps solving)
var again_status: Label
var _again_btns: Array = []
var _finishing := false        # the loser chose to keep solving after the race
var opp_board: Control
var opp_pct: Label


func setup(params: Dictionary) -> void:
	if params.has("versus"):
		_setup_versus(params.versus)
		return
	_build()
	if params.has("daily"):
		daily_date = params.daily
		slot = "daily:" + daily_date
		if GameState.has_game(slot):
			_start(Session.from_dict(GameState.load_game(slot)))
		else:
			var info := GameState.daily_info(daily_date)
			if info.has("puzzle"):
				_start(Session.new(Puzzle.from_dict(info.puzzle)))
			else:
				_generate({"variant": info.variant, "difficulty": info.difficulty, "seed": info.seed})
		return
	slot = params.get("slot", "")
	if params.has("pack"):
		_start(Session.new(Puzzle.from_dict(params.pack)))
	elif params.has("generate"):
		_generate(params.generate)
	elif GameState.has_game(slot):
		_start(Session.from_dict(GameState.load_game(slot)))
	else:
		GameState.go("home")


func on_leave() -> void:
	if not versus.is_empty() and not _match_over:
		Net.leave()   # leaving a race forfeits it
	_save()
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


# ------------------------------------------------------------------ layout

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28 if side != "top" else 18)
	add_child(margin)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 40)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(h)
	main_row = h

	# --- left: header + board (sized to fit the available height)
	left_col = VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 12)
	h.add_child(left_col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.custom_minimum_size = Vector2(0, 48)
	left_col.add_child(head)
	head.add_child(UI.button("←", "NavButton", _go_back))
	title_l = UI.heading("", 32)
	head.add_child(title_l)
	diff_tag_holder = HBoxContainer.new()
	diff_tag_holder.add_theme_constant_override("separation", 6)
	diff_tag_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(diff_tag_holder)
	if OS.is_debug_build():
		cheat_l = UI.label("← ← → ← ↑  solve      → → ←  fill all but one", 13, UI.INK_MUTED)
		cheat_l.tooltip_text = "Dev cheats (only in test builds run from Godot)."
		cheat_l.mouse_filter = Control.MOUSE_FILTER_PASS
		cheat_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(cheat_l)

	board_holder = Control.new()
	left_col.add_child(board_holder)
	board = Board.new()
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_holder.add_child(board)

	overlay = ColorRect.new()
	(overlay as ColorRect).color = Color(UI.PAPER, 0.94)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	board_holder.add_child(overlay)
	var oc := CenterContainer.new()
	oc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(oc)
	overlay_box = VBoxContainer.new()
	overlay_box.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay_box.add_theme_constant_override("separation", 14)
	oc.add_child(overlay_box)

	# --- right: controls
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(330, 0)
	right.add_theme_constant_override("separation", 12)
	h.add_child(right)

	var trow := HBoxContainer.new()
	trow.custom_minimum_size = Vector2(0, 48)
	timer_l = UI.label("0:00", 30, UI.INK, UI.font_sans_medium)
	timer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trow.add_child(timer_l)
	mistakes_l = UI.label("", 16, UI.INK_MUTED, UI.font_sans_medium)
	mistakes_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trow.add_child(mistakes_l)
	trow.add_child(UI.spacer(0, 14))
	pause_btn = UI.button("Pause", "", _toggle_pause)
	pause_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trow.add_child(pause_btn)
	var help := UI.button("?", "")
	help.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	help.tooltip_text = "Keyboard & mouse shortcuts"
	help.pressed.connect(_toggle_help)
	trow.add_child(help)
	right.add_child(trow)

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 6)
	for m in [["normal", "Normal"], ["corner", "Corner"], ["center", "Centre"], ["color", "Colour"]]:
		var b := UI.button(m[1], "ChipButton")
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var key: String = m[0]
		b.pressed.connect(func(): _set_mode(key))
		mode_btns[key] = b
		modes.add_child(b)
	right.add_child(modes)

	var pad := GridContainer.new()
	pad.columns = 3
	pad.add_theme_constant_override("h_separation", 8)
	pad.add_theme_constant_override("v_separation", 8)
	for d in range(1, 10):
		var b := UI.button(str(d), "PadButton")
		b.custom_minimum_size = Vector2(104, 62)
		var dd := d
		b.pressed.connect(func(): _digit(dd, _effective_mode()))
		var cnt := UI.label("", 13, UI.INK_MUTED, UI.font_sans_medium)
		cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.anchor_left = 1.0
		cnt.anchor_right = 1.0
		cnt.offset_left = -34
		cnt.offset_right = -9
		cnt.offset_top = 5
		cnt.offset_bottom = 23
		b.add_child(cnt)
		pad.add_child(b)
		pad_btns.append(b)
		pad_counts.append(cnt)
	right.add_child(pad)

	var actions := GridContainer.new()
	actions.columns = 3
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	undo_btn = UI.button("Undo", "", func(): if session: session.undo())
	redo_btn = UI.button("Redo", "", func(): if session: session.redo())
	hint_btn = UI.button("Hint", "", _hint)
	check_btn = UI.button("Check", "", _check)
	restart_btn = UI.button("Restart", "", _restart)
	var acts := [undo_btn, redo_btn,
		UI.button("Erase", "", func(): if session and not paused: session.erase(board.selected, _effective_mode())),
		hint_btn,
		check_btn,
		restart_btn]
	for b in acts:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(b)
	right.add_child(actions)

	var rules_box := PanelContainer.new()
	rules_box.add_theme_stylebox_override("panel", UI.box(UI.PAPER_WARM, Color(0, 0, 0, 0), 12, 0, 14))
	var rv := VBoxContainer.new()
	var rhead := HBoxContainer.new()
	var rt := UI.label("RULES", 12, UI.INK_MUTED, UI.font_sans_bold)
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rhead.add_child(rt)
	rules_head = rhead   # the example "i" (tooltip) is added once the variant is known
	rv.add_child(rhead)
	rules_l = UI.label("", 14, UI.INK)
	rules_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_l.custom_minimum_size = Vector2(300, 0)
	rv.add_child(rules_l)
	rules_box.add_child(rv)
	right.add_child(rules_box)


	_set_mode("normal")
	resized.connect(_fit_board)
	_fit_board.call_deferred()


func _fit_board() -> void:
	var avail_h := size.y - 18 - 28 - 48 - 12
	var avail_w := size.x - 56 - 330 - 40
	if not versus.is_empty():
		avail_w -= OPP_W + 40
	var s := floorf(maxf(280.0, minf(avail_h, avail_w)))
	board_holder.custom_minimum_size = Vector2(s, s)


func _set_mode(m: String) -> void:
	mode = m
	_show_mode(_effective_mode())


## Holding Shift / Ctrl / Ctrl+Shift temporarily switches to corner / centre / colour.
func _effective_mode() -> String:
	var shift := Input.is_key_pressed(KEY_SHIFT)
	var ctrl := Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)
	if shift and ctrl: return "color"
	if shift: return "corner"
	if ctrl: return "center"
	return mode


func _show_mode(m: String) -> void:
	if m == _shown_mode:
		return
	_shown_mode = m
	for k in mode_btns:
		mode_btns[k].button_pressed = k == m
	_refresh_pad()


func _refresh_pad() -> void:
	var m := _shown_mode
	var n := session.puzzle.size if session else 9
	for d in range(1, 10):
		var b: Button = pad_btns[d - 1]
		var cnt: Label = pad_counts[d - 1]
		b.visible = d <= n or m == "color"   # Mini: pad 1-6 (the colour palette keeps all 9)
		cnt.visible = session != null and m != "color"
		if cnt.visible:
			cnt.text = str(maxi(0, n - session.digit_count(d)))
		var colour_digits := session != null and session.puzzle.variant == "color"   # Color Sudoku: the digits are colours
		b.text = str(d) if session == null else Board.glyph_for(session.puzzle, d)
		if colour_digits and m != "color":
			b.text = ""
		if m == "color" or colour_digits:
			var sb := UI.box(UI.CELL_COLORS[d], Color(UI.INK, 0.25), 12, 1)
			var sbh := UI.box(UI.CELL_COLORS[d].lightened(0.2), UI.INK, 12, 2)
			b.add_theme_stylebox_override("normal", sb)
			b.add_theme_stylebox_override("hover", sbh)
			b.add_theme_stylebox_override("pressed", sbh)
			b.add_theme_color_override("font_color", Color(UI.INK, 0.55))
			b.add_theme_font_size_override("font_size", 16)
			b.disabled = colour_digits and m == "normal" and session.digit_count(d) >= 9
		else:
			for k in ["normal", "hover", "pressed"]:
				b.remove_theme_stylebox_override(k)
			b.remove_theme_color_override("font_color")
			var long := b.text.length() >= 3   # Roman numerals
			b.add_theme_font_size_override("font_size", (26 if m == "normal" else 18) - (8 if long else 0))
			b.disabled = session != null and m == "normal" and session.digit_count(d) >= n


# ------------------------------------------------------------------ lifecycle

func _generate(g: Dictionary) -> void:
	_gen_params = g
	_show_overlay("loading")
	title_l.text = Variants.display_name(g.variant)
	_thread = Thread.new()
	_thread.start(Generator.make.bind(String(g.variant), String(g.difficulty), int(g.seed)))


func _start(s: Session) -> void:
	session = s
	session.auto_clear_notes = GameState.settings.auto_clear_notes
	board.set_session(session)
	session.changed.connect(_on_changed)
	title_l.text = Variants.display_name(session.puzzle.variant)
	for c in diff_tag_holder.get_children():
		c.queue_free()
	if daily_date != "":
		diff_tag_holder.add_child(UI.tag("DAILY · " + daily_date, UI.GOLD_TEXT, UI.GOLD_SOFT))
	else:   # dailies are always hard and aren't labelled with a difficulty
		diff_tag_holder.add_child(UI.tag(session.puzzle.difficulty.to_upper(), UI.ACCENT, UI.ACCENT_SOFT))
	var info := Variants.get_info(session.puzzle.variant)
	rules_l.text = info.get("rules", info.get("short", ""))
	for c in rules_head.get_children():
		if c is ExampleHint:
			c.queue_free()
	var hint := ExampleHint.new()
	hint.pressed.connect(_toggle_example)
	rules_head.add_child(hint)
	timer_l.visible = GameState.settings.show_timer
	_hide_overlay()
	if not versus.is_empty():
		_start_versus()
		return
	if slot == "" and daily_date == "":
		slot = "%s:%s" % [session.puzzle.variant, session.puzzle.difficulty]
	_dirty = true
	_save()
	_on_changed()
	if session.is_lost():
		_on_lost.call_deferred()


func _process(delta: float) -> void:
	if _thread and _thread.is_started() and not _thread.is_alive():
		var pz: Puzzle = _thread.wait_to_finish()
		_thread = null
		if pz == null:
			UI.toast("Couldn't generate a puzzle — please try again.")
			GameState.go("variant", {"id": _gen_params.get("variant", "classic")})
			return
		_start(Session.new(pz))
		return
	_show_mode(_effective_mode())
	if _countdown > 0.0:
		var before := ceili(_countdown)
		_countdown -= delta
		if _countdown <= 0.0:
			_hide_overlay()
			var f := get_viewport().gui_get_focus_owner()   # race starts: keys go to the board
			if f:
				f.release_focus()
		elif ceili(_countdown) != before:
			_show_countdown()
		return
	if session and not paused and not session.solved and (not _match_over or _finishing):
		session.elapsed += delta
		timer_l.text = UI.format_time(session.elapsed)
		_save_clock += delta
		if _save_clock > 5.0:
			_save_clock = 0.0
			_dirty = true
			_save()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and session and not session.solved and not paused:
		_toggle_pause()


func _save() -> void:
	if session == null or not _dirty or slot == "":
		return
	_dirty = false
	if session.solved:
		GameState.clear_game(slot)
	else:
		GameState.store_game(slot, session.to_dict())


func _on_changed() -> void:
	_dirty = true
	if not versus.is_empty():
		_send_progress()
	undo_btn.disabled = not session.can_undo()
	redo_btn.disabled = not session.can_redo()
	_refresh_hint()
	_refresh_check()
	_refresh_mistakes()
	_refresh_pad()
	if session.solved and not versus.is_empty():
		_versus_solved()
	elif session.solved and not overlay.visible:
		_on_solved()


func _go_back() -> void:
	if not versus.is_empty():
		GameState.go("multiplayer")   # on_leave forfeits if the race is still on
		return
	_save()
	if daily_date != "":
		GameState.go("daily", {"date": daily_date})
	elif session:
		GameState.go("variant", {"id": session.puzzle.variant})
	else:
		GameState.go("variant", {"id": _gen_params.get("variant", "classic")})


# ------------------------------------------------------------------ actions

func _digit(d: int, m: String) -> void:
	if session == null or paused or board.selected.is_empty():
		return
	if d > session.puzzle.size and m != "color":   # Mini: digits 1-6 only (all 9 colours)
		return
	var before := session.values.duplicate()
	session.input_digit(board.selected, d, m)
	if m != "normal" or session.solved:
		return
	# Frame drum feedback: "wrong" only when a newly placed digit breaks a rule.
	var placed := board.selected.filter(func(c): return session.values[c] == d and before[c] != d)
	if placed.is_empty():
		return
	if not versus.is_empty():   # race: no mistake counting, sound only for rule breaks
		Audio.play("wrong" if placed.any(func(c): return session.conflicts[c]) else "correct")
		return
	_count_mistakes(placed)


## Counts the newly placed digits that are mistakes (rule depends on difficulty) and loses the
## puzzle at the limit. Also plays the frame-drum feedback.
func _count_mistakes(placed: Array) -> void:
	var bad := placed.filter(func(c): return session.counts_as_mistake(c)).size()
	if bad > 0:
		session.mistakes += bad
		_dirty = true
		_refresh_mistakes()
	Audio.play("wrong" if bad > 0 else "correct")
	if session.is_lost():
		_on_lost()


func _hint() -> void:
	if session == null or paused or not versus.is_empty(): return
	if session.hints_left() <= 0:
		var none_h := int(Session.HINT_LIMITS.get(session.puzzle.difficulty, 0)) == 0
		UI.toast(("Daily puzzles have no hints." if daily_date != "" else "%s puzzles have no hints." % session.puzzle.difficulty.capitalize()) if none_h else "No hints left for this puzzle.")
		return
	var target: int = board.selected[-1] if board.selected.size() == 1 else -1
	if target >= 0 and session.values[target] == session.puzzle.solution[target]:
		target = -1
	var c := session.hint(target)
	if c >= 0:
		board.selected = [c]
		board.queue_redraw()


func _check() -> void:
	if session == null or paused or not versus.is_empty(): return
	if session.checks_left() <= 0:
		var none_c := int(Session.CHECK_LIMITS.get(session.puzzle.difficulty, 0)) == 0
		UI.toast(("Daily puzzles have no checks." if daily_date != "" else "%s puzzles have no checks." % session.puzzle.difficulty.capitalize()) if none_c else "No checks left for this puzzle.")
		return
	# Nothing of the player's own to check yet (givens and hinted digits don't count): don't use one up.
	var placed := 0
	for c in session.values.size():
		if session.values[c] != 0 and not session.is_given(c) and not session.hinted[c]:
			placed += 1
	if placed == 0:
		UI.toast("You can't check yet: you haven't placed any digits. Check compares your digits with the solution.")
		return
	session.checks_used += 1
	_dirty = true
	_refresh_check()
	var wrong := session.wrong_cells()
	if wrong.is_empty():
		UI.toast("Looking good — no mistakes so far.")
	else:
		board.flash(wrong)
		UI.toast("%d cell%s don't match the solution." % [wrong.size(), "" if wrong.size() == 1 else "s"])


func _restart() -> void:
	if session == null or paused or not versus.is_empty(): return
	session.restart()
	UI.toast("Puzzle restarted and the timer reset.")


func _toggle_pause() -> void:
	if session == null or session.solved or _lost or not versus.is_empty(): return
	paused = not paused
	pause_btn.text = "Resume" if paused else "Pause"
	if paused:
		_show_overlay("paused")
	else:
		_hide_overlay()


# ------------------------------------------------------------------ overlays

func _clear_overlay() -> void:
	for c in overlay_box.get_children():
		c.queue_free()


func _show_overlay(kind: String) -> void:
	_clear_overlay()
	overlay.visible = true
	match kind:
		"loading":
			overlay_box.add_child(UI.heading("Generating puzzle…", 30))
			var l := UI.label("Building a grid with exactly one solution.", 15, UI.INK_MUTED)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			overlay_box.add_child(l)
		"paused":
			overlay_box.add_child(UI.heading("Paused", 40))
			var b := UI.button("Resume", "PrimaryButton", _toggle_pause)
			b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			overlay_box.add_child(b)


func _hide_overlay() -> void:
	overlay.visible = false
	_clear_overlay()


func _on_solved() -> void:
	board.celebrate()
	Audio.play("solved")
	var res := GameState.record_solve(session.puzzle, session.elapsed, session.hints_used, daily_date, session.mistakes)
	_dirty = true
	_save()
	await get_tree().create_timer(1.3).timeout
	if not is_inside_tree():
		return
	_clear_overlay()
	overlay.visible = true
	(overlay as ColorRect).color = Color(UI.PAPER, 0.88)
	var card := PanelContainer.new()
	var sb := UI.box(UI.SURFACE, UI.LINE_STRONG, 18, 1, 32)
	sb.shadow_color = Color(0, 0, 0, 0.08); sb.shadow_size = 24; sb.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)
	var t := UI.heading("Solved!", 46)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var lines := [Variants.display_name(session.puzzle.variant) if daily_date != "" else "%s · %s" % [Variants.display_name(session.puzzle.variant), session.puzzle.difficulty.capitalize()],
		"Time  %s%s" % [UI.format_time(session.elapsed), "   — new best!" if res.new_best else ""],
		"Hints used  %d" % session.hints_used]
	if daily_date != "":
		lines.append("Daily streak  %d" % res.streak)
	for s in lines:
		var l := UI.label(s, 17, UI.INK_MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	v.add_child(UI.spacer(6))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var pz := session.puzzle
	if daily_date != "":
		var dd := daily_date
		row.add_child(UI.button("Daily calendar", "PrimaryButton", func(): GameState.go("daily", {"date": dd})))
	else:
		row.add_child(UI.button("Next puzzle", "PrimaryButton", func():
			GameState.go("game", GameState.new_game_params(pz.variant, pz.difficulty))))
	v.add_child(row)
	# Keyboard on the win card (not shown on it, but listed in the ? panel):
	# Space / Enter = the main (next) button, Esc = home.
	for b in row.get_children():
		if b is Button and b.theme_type_variation == "PrimaryButton":
			_win_next = b
	overlay_box.add_child(card)


# ------------------------------------------------------------------ help panel (opened by the ? button)

const HELP_LINES := [
	["1–9 or number pad", "enter a digit"],
	["Hold Shift", "corner marks"],
	["Hold Ctrl", "centre marks"],
	["Hold Ctrl + Shift", "colours"],
	["Space / Tab", "next mode"],
	["Z  X  C  V", "normal / corner / centre / colour"],
	["Arrows or WASD", "move (Shift = extend the selection)"],
	["Backspace / Delete", "erase"],
	["Ctrl+Z / Ctrl+Y", "undo / redo"],
	["H", "hint (Beginner 20, Easy 10, Medium 3, Hard and up none)"],
	["Mistakes", "Beginner no limit, Easy 14, Medium 7, Hard 3, Expert 2, Master 1"],
	["P", "pause"],
	["Esc", "close this panel / clear the selection / go back"],
	["Double-click a digit", "select every cell with that digit"],
	["Ctrl/Shift + click, or drag", "select several cells"],
	["M", "mute / unmute music"],
	["Mouse 4 / 5", "back / forward"],
	["After solving: Space / Enter", "next puzzle (Journey: next level)"],
	["After solving: Esc", "home"],
]


var example_layer: Control


## A solved example of this variant (a different puzzle), over the screen; Close, a click outside or Esc closes it.
func _toggle_example() -> void:
	if example_layer and is_instance_valid(example_layer):
		example_layer.queue_free()
		example_layer = null
		return
	var variant: String = session.puzzle.variant if session else str(_gen_params.get("variant", "classic"))
	var es := Board.solved_example(variant, session.puzzle.id if session else "")
	if es == null:
		UI.toast("No example available.")
		return
	example_layer = ColorRect.new()
	(example_layer as ColorRect).color = Color(0, 0, 0, 0.45)
	example_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	example_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	example_layer.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_toggle_example())
	add_child(example_layer)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	example_layer.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 24))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var head := HBoxContainer.new()
	var t := UI.heading("Example: " + Variants.display_name(variant), 26)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UI.button("Close", "", _toggle_example))
	v.add_child(head)
	var side := clampf(size.y - 300.0, 300.0, 500.0)
	# the main idea, shown on the example's own digits; Next steps through a few of them
	var ideas := ExampleExplain.explain(es.puzzle)
	var idea_row := HBoxContainer.new()
	idea_row.add_theme_constant_override("separation", 10)
	var cap := UI.label("", 17, UI.INK, UI.font_sans_medium)
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.custom_minimum_size = Vector2(side - 120.0, 48)
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	idea_row.add_child(cap)
	var next := UI.button("Next ›", "PrimaryButton")
	next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	next.visible = ideas.size() > 1
	idea_row.add_child(next)
	v.add_child(idea_row)
	var b := Board.new()
	b.interactive = false
	b.custom_minimum_size = Vector2(side, side)
	v.add_child(b)
	b.set_session(es)
	var count := UI.label("", 13, UI.INK_FAINT)
	v.add_child(count)
	var at := [0]
	var show_idea := func():
		var it: Dictionary = ideas[at[0]]
		cap.text = it.text
		b.emphasis = it.cells
		b.queue_redraw()
		count.text = "Idea %d of %d  ·  the highlighted cells show it  ·  blue digits were solved" % [at[0] + 1, ideas.size()]
	next.pressed.connect(func():
		at[0] = (at[0] + 1) % ideas.size()
		show_idea.call())
	if ideas.is_empty():
		cap.text = "A solved puzzle of this variant."
	else:
		show_idea.call()


func _toggle_help() -> void:
	if help_layer and is_instance_valid(help_layer):
		help_layer.queue_free()
		help_layer = null
		return
	help_layer = ColorRect.new()
	(help_layer as ColorRect).color = Color(0, 0, 0, 0.35)
	help_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	help_layer.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_toggle_help())
	add_child(help_layer)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help_layer.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 26))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	var head := HBoxContainer.new()
	var t := UI.heading("Keyboard & mouse", 28)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UI.button("Close", "", _toggle_help))
	v.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 8)
	for row in HELP_LINES:
		grid.add_child(UI.label(row[0], 15, UI.INK, UI.font_sans_bold))
		grid.add_child(UI.label(row[1], 15, UI.INK_MUTED))
	v.add_child(grid)


## Check button text/state from the checks left for this puzzle's difficulty.
func _refresh_check() -> void:
	if check_btn == null or session == null:
		return
	var limit := int(Session.CHECK_LIMITS.get(session.puzzle.difficulty, 0))
	var left := session.checks_left()
	if limit == 0:
		check_btn.text = "No checks"
	else:
		check_btn.text = "Check (%d)" % left
	check_btn.disabled = left <= 0


## Hint button text/state from the hints left for this puzzle's difficulty.
func _refresh_hint() -> void:
	if hint_btn == null or session == null:
		return
	var left := session.hints_left()
	if Session.HINT_LIMITS.get(session.puzzle.difficulty, 0) == 0:
		hint_btn.text = "No hints"
	else:
		hint_btn.text = "Hint (%d)" % left
	hint_btn.disabled = left <= 0

## Mistake limit reached: stop the puzzle and offer Try again / a way out.
func _on_lost() -> void:
	if _lost:
		return
	_lost = true
	paused = true
	Audio.play("wrong")
	_dirty = true
	_save()
	_clear_overlay()
	overlay.visible = true
	(overlay as ColorRect).color = Color(UI.PAPER, 0.9)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 32))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	var t := UI.heading("Puzzle lost", 42)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var what := "rule breaks" if session.puzzle.difficulty in Session.RULE_BREAK_LEVELS else "wrong digits"
	var l := UI.label("You made %d mistakes (%s), the limit for %s puzzles." % [session.mistakes, what, "daily" if daily_date != "" else session.puzzle.difficulty], 16, UI.INK_MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	v.add_child(UI.spacer(6))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var pz := session.puzzle
	if daily_date != "":
		var dd := daily_date
		row.add_child(UI.button("Daily calendar", "", func(): GameState.go("daily", {"date": dd})))
	elif _is_road():
		row.add_child(UI.button("Back to road", "", func(): GameState.go("journey", {"variant": pz.variant})))
	else:
		row.add_child(UI.button("New puzzle", "", func():
			GameState.go("game", GameState.new_game_params(pz.variant, pz.difficulty))))
	var again := UI.button("Try again", "PrimaryButton", _try_again)
	row.add_child(again)
	_win_next = again
	v.add_child(row)
	var keys_l := UI.label("Space / Enter: try again    ·    Esc: home", 13, UI.INK_FAINT)
	keys_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(keys_l)
	overlay_box.add_child(card)


func _try_again() -> void:
	_lost = false
	paused = false
	_win_next = null
	session.retry()
	_hide_overlay()
	(overlay as ColorRect).color = Color(UI.PAPER, 0.94)
	_dirty = true
	_save()
	UI.toast("Same puzzle, fresh start. Good luck!")


func _refresh_mistakes() -> void:
	if mistakes_l == null or session == null:
		return
	var limit := session.mistake_limit()
	if limit <= 0:   # beginner: no limit
		mistakes_l.text = "Mistakes %d" % session.mistakes
		mistakes_l.add_theme_color_override("font_color", UI.INK_MUTED)
		return
	mistakes_l.text = "Mistakes %d/%d" % [session.mistakes, limit]
	mistakes_l.add_theme_color_override("font_color", UI.DANGER if session.mistakes >= limit - 1 and session.mistakes > 0 else UI.INK_MUTED)


func _is_road() -> bool:
	return false


# ------------------------------------------------------------------ keyboard

## Tracks the last arrow presses (within 3 s of each other); true when the cheat sequence completes.
func _cheat(code: int) -> bool:
	if not code in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		_cheat_keys.clear()
		return false
	var now := Time.get_ticks_msec()
	if now - _cheat_time > 3000:
		_cheat_keys.clear()
	_cheat_time = now
	_cheat_keys.append(code)
	if _cheat_keys.size() > CHEAT.size():
		_cheat_keys.pop_front()
	if paused or session.solved:
		return false
	if _cheat_keys == CHEAT:
		_cheat_keys.clear()
		session.autofill()
		return true
	if _cheat_keys.slice(-CHEAT_ALL_BUT_ONE.size()) == CHEAT_ALL_BUT_ONE:
		_cheat_keys.clear()
		var c := session.autofill_all_but_one()
		if c >= 0:
			board.selected = [c]
			board.queue_redraw()
		return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if session == null or not (event is InputEventKey) or not event.pressed:
		return
	var k: InputEventKey = event
	if _countdown > 0.0:
		return
	if session.solved or _lost or (_match_over and not _finishing):
		if _win_next and not k.echo:
			if k.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
				get_viewport().set_input_as_handled()
				_win_next.pressed.emit()
			elif k.keycode == KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				GameState.go("multiplayer" if not versus.is_empty() else "home")
		return
	var code := k.keycode
	# (only real arrow keys count — Shift + number pad 4/6/8 also report as arrows on Windows)
	if OS.is_debug_build() and not k.echo and k.physical_keycode == code and _cheat(code):
		get_viewport().set_input_as_handled()
		return
	var digit := -1
	if code >= KEY_1 and code <= KEY_9:
		digit = code - KEY_0
	elif code >= KEY_KP_1 and code <= KEY_KP_9:
		digit = code - KEY_KP_0
	var phys := k.physical_keycode
	if phys >= KEY_1 and phys <= KEY_9:
		digit = phys - KEY_0  # shifted digits / non-US layouts
	elif phys >= KEY_KP_1 and phys <= KEY_KP_9:
		digit = phys - KEY_KP_0  # Shift+numpad reports End/Down/… on Windows
	if digit > 0:
		var m := mode
		var ctrl := k.ctrl_pressed or k.meta_pressed
		# Windows quirk: with Num Lock on, Shift + number pad sends a fake Shift release and turns the
		# key into End/Down/PgDn/… — so a number-pad key that arrives as a navigation key means Shift.
		var shift := k.shift_pressed or (phys >= KEY_KP_1 and phys <= KEY_KP_9 and not (code >= KEY_KP_1 and code <= KEY_KP_9))
		if shift and ctrl: m = "color"
		elif shift: m = "corner"
		elif ctrl: m = "center"
		_digit(digit, m)
	elif code in [KEY_BACKSPACE, KEY_DELETE, KEY_0, KEY_KP_0, KEY_PERIOD] or phys == KEY_KP_0:
		if not paused: session.erase(board.selected, _effective_mode())
	elif code == KEY_Z and (k.ctrl_pressed or k.meta_pressed):
		if k.shift_pressed: session.redo()
		else: session.undo()
	elif code == KEY_Y and (k.ctrl_pressed or k.meta_pressed):
		session.redo()
	elif code == KEY_SPACE or code == KEY_TAB:
		var order := ["normal", "corner", "center", "color"]
		_set_mode(order[(order.find(mode) + 1) % order.size()])
	elif code == KEY_Z: _set_mode("normal")
	elif code == KEY_X: _set_mode("corner")
	elif code == KEY_C and not (k.ctrl_pressed or k.meta_pressed): _set_mode("center")
	elif code == KEY_V and not (k.ctrl_pressed or k.meta_pressed): _set_mode("color")
	elif code == KEY_H: _hint()
	elif code == KEY_P: _toggle_pause()
	elif code == KEY_ESCAPE:
		if example_layer and is_instance_valid(example_layer):
			_toggle_example()
			get_viewport().set_input_as_handled()
			return
		if help_layer and is_instance_valid(help_layer):
			_toggle_help()
			get_viewport().set_input_as_handled()
			return
		if paused: _toggle_pause()
		elif not board.selected.is_empty():
			board.selected = []
			board.queue_redraw()
		elif not versus.is_empty():
			UI.toast("Esc doesn't leave a race. Use the ← button (you'll forfeit).")
		else:
			return   # nothing to close here: Main takes Esc as "go back a screen"
	elif code == KEY_UP or code == KEY_W: board.move_cursor(0, -1, k.shift_pressed)
	elif code == KEY_DOWN or code == KEY_S: board.move_cursor(0, 1, k.shift_pressed)
	elif code == KEY_LEFT or code == KEY_A: board.move_cursor(-1, 0, k.shift_pressed)
	elif code == KEY_RIGHT or code == KEY_D: board.move_cursor(1, 0, k.shift_pressed)
	else:
		return
	get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ multiplayer race

func _setup_versus(msg: Dictionary) -> void:
	versus = msg
	var pz: Puzzle = null
	for d in GameState.pack_puzzles(str(msg.v), str(msg.d)):
		if str(d.get("id", "")) == str(msg.id):
			pz = Puzzle.from_dict(d)
			break
	_build()
	_build_opponent()
	for b in [hint_btn, check_btn, restart_btn, pause_btn, mistakes_l]:
		b.visible = false
	if cheat_l:
		cheat_l.visible = false   # keeps the header narrow enough for the opponent column (cheats still work)
	board.versus = true
	if pz == null:
		UI.toast("This puzzle isn't in your puzzle packs. Both players need the same game version.")
		Net.leave()
		GameState.go.call_deferred("multiplayer")
		return
	_start(Session.new(pz))


func _build_opponent() -> void:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(OPP_W, 0)
	v.add_theme_constant_override("separation", 10)
	main_row.add_child(v)
	var head := Control.new()
	head.custom_minimum_size = Vector2(0, 48)
	v.add_child(head)
	score_l = UI.label("", 15, UI.INK, UI.font_sans_bold)
	v.add_child(score_l)
	_refresh_score()
	Net.score_changed.connect(_refresh_score)
	v.add_child(UI.label("OPPONENT", 12, UI.INK_MUTED, UI.font_sans_bold))
	var name_l := UI.label(Net.opponent if Net.opponent != "" else "Opponent", 20, UI.INK, UI.font_sans_bold)
	name_l.clip_text = true
	v.add_child(name_l)
	opp_board = Control.new()
	opp_board.custom_minimum_size = Vector2(OPP_W, OPP_W)
	opp_board.draw.connect(_draw_opponent)
	v.add_child(opp_board)
	opp_pct = UI.label("0% filled", 16, UI.INK_MUTED, UI.font_sans_medium)
	v.add_child(opp_pct)
	opp_note = UI.label("You see which cells your opponent has filled (red = breaks a rule), not their digits. The puzzle's own digits are shown.", 13, UI.INK_FAINT)
	opp_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(opp_note)
	after_box = VBoxContainer.new()
	after_box.add_theme_constant_override("separation", 6)
	after_box.visible = false
	v.add_child(after_box)
	var arow := HBoxContainer.new()
	arow.add_theme_constant_override("separation", 6)
	after_box.add_child(arow)
	var ab := UI.button("Play again", "PrimaryButton", _play_again)
	ab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arow.add_child(ab)
	_again_btns.append(ab)
	arow.add_child(UI.button("Main menu", "", _main_menu))
	again_status = UI.label("", 13, UI.INK_MUTED)
	again_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	after_box.add_child(again_status)
	Net.again_changed.connect(_refresh_again)
	var chat := ChatPanel.new(150)
	chat.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(chat)
	Net.message.connect(_on_net_message)
	Net.opponent_left.connect(_on_opponent_left)


func _draw_opponent() -> void:
	if session == null:
		return
	var n := session.puzzle.size
	var nc := n * n
	var c := floorf(float(OPP_W) / n)
	var r := Rect2(Vector2.ZERO, Vector2(c * n, c * n))
	opp_board.draw_rect(r, UI.SURFACE)
	var revealed := _opp_values.length() == nc
	var fs := int(c * 0.6)
	for i in nc:
		var cr := Rect2(Vector2(i % n, i / n) * c, Vector2(c, c))
		var bad := _opp_bad.length() == nc and _opp_bad[i] == "1"
		if session.is_given(i):
			opp_board.draw_rect(cr, Color(UI.INK, 0.10))
		elif bad:
			opp_board.draw_rect(cr.grow(-2), Color(UI.DANGER, 0.75 if not revealed else 0.3))
		elif _opp_cells.length() == nc and _opp_cells[i] == "1" and not revealed:
			opp_board.draw_rect(cr.grow(-2), Color(UI.ACCENT, 0.55))
		# the puzzle's own digits are known to both players, so they're never hidden
		var digit := str(session.puzzle.givens[i]) if session.is_given(i) else (_opp_values[i] if revealed else "0")
		if digit != "0":
			digit = Board.glyph_for(session.puzzle, int(digit))
			var col := UI.INK if session.is_given(i) else (UI.DANGER if bad else UI.ACCENT)
			var f: Font = UI.font_sans_medium
			var sz := f.get_string_size(digit, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			opp_board.draw_string(f, cr.get_center() + Vector2(-sz.x / 2.0, (f.get_ascent(fs) - f.get_descent(fs)) / 2.0),
				digit, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	for i in range(1, n):
		opp_board.draw_line(Vector2(i * c, 0), Vector2(i * c, r.size.y), Color(UI.INK, 0.15), 1.0)
		opp_board.draw_line(Vector2(0, i * c), Vector2(r.size.x, i * c), Color(UI.INK, 0.15), 1.0)
	var regions := session.puzzle.regions
	for i in nc:
		var cr := Rect2(Vector2(i % n, i / n) * c, Vector2(c, c))
		if i % n < n - 1 and regions[i] != regions[i + 1]:
			opp_board.draw_line(Vector2(cr.end.x, cr.position.y), Vector2(cr.end.x, cr.end.y), UI.INK, 2.0)
		if i / n < n - 1 and regions[i] != regions[i + n]:
			opp_board.draw_line(Vector2(cr.position.x, cr.end.y), Vector2(cr.end.x, cr.end.y), UI.INK, 2.0)
	opp_board.draw_rect(r, UI.INK, false, 2.0)


func _start_versus() -> void:
	slot = ""
	for c in diff_tag_holder.get_children():
		c.queue_free()
	diff_tag_holder.add_child(UI.tag("1V1 RACE", UI.GOLD_TEXT, UI.GOLD_SOFT))
	diff_tag_holder.add_child(UI.tag(session.puzzle.difficulty.to_upper(), UI.ACCENT, UI.ACCENT_SOFT))
	_on_changed()
	_countdown = 3.0
	_show_countdown()


func _show_countdown() -> void:
	_clear_overlay()
	overlay.visible = true
	(overlay as ColorRect).color = UI.PAPER   # the board stays hidden: nobody gets a head start
	var n := UI.heading(str(ceili(_countdown)), 120)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_box.add_child(n)
	var l := UI.label("Get ready: first to finish wins", 18, UI.INK_MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_box.add_child(l)
	Audio.play("correct")


func _filled_cells() -> String:
	var out := ""
	for i in session.values.size():
		out += "1" if session.values[i] != 0 and not session.is_given(i) else "0"
	return out


func _send_progress() -> void:
	if _match_over or session == null:
		return
	var cells := _filled_cells()
	var bad := _bad_cells()
	if cells + bad == _sent_cells:
		return
	_sent_cells = cells + bad
	Net.send({"t": "prog", "cells": cells, "bad": bad})


## "1" for every cell of mine that breaks a rule (the same red cells I see).
func _bad_cells() -> String:
	var out := ""
	for i in session.values.size():
		out += "1" if session.values[i] != 0 and not session.is_given(i) and session.conflicts[i] else "0"
	return out


## Race over: send my whole grid so the opponent's fog lifts.
func _send_reveal() -> void:
	var vals := ""
	for i in session.values.size():
		vals += str(session.values[i])
	Net.send({"t": "grid", "values": vals, "bad": _bad_cells()})


func _on_net_message(msg: Dictionary) -> void:
	match str(msg.get("t", "")):
		"grid":
			_opp_values = str(msg.get("values", ""))
			_opp_bad = str(msg.get("bad", ""))
			opp_note.text = "Their final grid (red = breaks a rule)."
			opp_board.queue_redraw()
		"prog":
			_opp_cells = str(msg.get("cells", ""))
			_opp_bad = str(msg.get("bad", ""))
			if session:
				var empty := 0
				var filled := 0
				for i in session.values.size():
					if not session.is_given(i):
						empty += 1
						if _opp_cells.length() == session.values.size() and _opp_cells[i] == "1":
							filled += 1
				opp_pct.text = "%d%% filled" % (100 * filled / maxi(1, empty))
			opp_board.queue_redraw()
		"done":   # host: the guest finished first
			if Net.is_host and not _match_over:
				var gt := float(msg.get("time", 0.0))
				Net.send({"t": "result", "winner": "guest", "host_time": -1.0, "guest_time": gt})
				_show_result(false, -1.0, gt)
		"result":
			if not Net.is_host:
				var mine := float(msg.get("guest_time", -1.0))
				if mine < 0.0 and session.solved:
					mine = session.elapsed
				_show_result(str(msg.get("winner", "")) == "guest", mine, float(msg.get("host_time", -1.0)))


## The host decides the winner (whoever's "finished" reaches the host first); the guest reports and waits.
func _versus_solved() -> void:
	if _match_over:
		if _finishing:
			_finishing = false
			board.celebrate()
			Audio.play("solved")
			UI.toast("Puzzle finished in %s." % UI.format_time(session.elapsed))
		return
	board.celebrate()
	Audio.play("solved")
	_send_progress()
	if Net.is_host:
		Net.send({"t": "result", "winner": "host", "host_time": session.elapsed, "guest_time": -1.0})
		_show_result(true, session.elapsed, -1.0)
	else:
		Net.send({"t": "done", "time": session.elapsed})
		_clear_overlay()
		overlay.visible = true
		(overlay as ColorRect).color = Color(UI.PAPER, 0.88)
		var t := UI.heading("Finished!", 44)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		overlay_box.add_child(t)
		var l := UI.label("Waiting for the result…", 17, UI.INK_MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		overlay_box.add_child(l)


func _on_opponent_left() -> void:
	if _match_over:
		if Net.is_host:
			UI.toast("Your opponent left the room.")
			_refresh_again()
		else:   # kicked: the room closed with the host
			UI.toast("The host left, so the room was closed.")
			GameState.go("multiplayer")
		return
	var note := "Your opponent left the match."
	_show_result(true, session.elapsed if session and session.solved else -1.0, -1.0, note)


## my_time / opp_time in seconds, < 0 if that player didn't finish.
func _show_result(won: bool, my_time: float, opp_time: float, note := "") -> void:
	if _match_over:
		return
	_match_over = true
	_send_reveal()
	if Net.in_room:
		Net.record_result(won)
		after_box.visible = true
		opp_note.visible = false   # room for the Play again buttons (the grid is revealed anyway)
		_refresh_again()
	var mp: Dictionary = GameState.stats.get("multiplayer", {"wins": 0, "losses": 0})
	var key := "wins" if won else "losses"
	mp[key] = int(mp.get(key, 0)) + 1
	GameState.stats.multiplayer = mp
	GameState.save_stats()
	SteamManager.on_versus(won, mp)
	if not session.solved:
		Audio.play("solved" if won else "wrong")
	await get_tree().create_timer(1.0 if session.solved else 0.2).timeout
	if not is_inside_tree():
		return
	_clear_overlay()
	overlay.visible = true
	(overlay as ColorRect).color = Color(UI.PAPER, 0.88)
	var card := PanelContainer.new()
	var sb := UI.box(UI.SURFACE, UI.LINE_STRONG, 18, 1, 32)
	sb.shadow_color = Color(0, 0, 0, 0.08); sb.shadow_size = 24; sb.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	var t := UI.heading("You win!" if won else "You lost", 46)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var lines: Array = []
	if note != "":
		lines.append(note)
	elif not won:
		lines.append("%s finished first." % (Net.opponent if Net.opponent != "" else "Your opponent"))
	lines.append("%s · %s" % [Variants.display_name(session.puzzle.variant), session.puzzle.difficulty.capitalize()])
	lines.append("Your time  " + (UI.format_time(my_time) if my_time >= 0.0 else "didn't finish"))
	if opp_time >= 0.0:
		lines.append("Opponent  " + UI.format_time(opp_time))
	for s in lines:
		var l := UI.label(s, 17, UI.INK_MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	if Net.in_room and Net.opponent != "":
		var sc := UI.label("Score   You %d – %d %s" % [Net.score.me, Net.score.opp, Net.opponent], 17, UI.INK, UI.font_sans_bold)
		sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(sc)
	v.add_child(UI.spacer(6))
	if not won and not session.solved and Net.in_room:
		var keep := UI.button("Keep solving", "", _keep_solving)
		keep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		keep.tooltip_text = "Finish the puzzle at your own pace. The result doesn't change."
		v.add_child(keep)
	if Net.in_room and Net.opponent != "":
		var again := UI.button("Play again", "PrimaryButton", _play_again)
		row.add_child(again)
		_again_btns.append(again)
		_win_next = again
	else:
		row.add_child(UI.button("Multiplayer", "", func(): GameState.go("multiplayer")))
	row.add_child(UI.button("Main menu", "", _main_menu))
	v.add_child(row)
	var st := UI.label("", 14, UI.INK_FAINT)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.name = "AgainStatus"
	v.add_child(st)
	overlay_box.add_child(card)
	_refresh_again()



# ------------------------------------------------------------------ after the race

func _refresh_score() -> void:
	if score_l:
		score_l.text = "Score   You %d – %d" % [Net.score.me, Net.score.opp]
		score_l.visible = Net.score.me + Net.score.opp > 0


## Status of "Play again" for both players, on the result card and under the opponent's grid.
func _refresh_again() -> void:
	var opp := Net.opponent if Net.opponent != "" else "Your opponent"
	var text := ""
	if not Net.in_room or Net.opponent == "":
		text = "Your opponent has left."
	elif Net.again_me and Net.again_opp:
		text = "Starting…"
	elif Net.again_me:
		text = "Waiting for %s to press Play again…" % opp
	elif Net.again_opp:
		text = "%s wants to play again." % opp
	if again_status:
		again_status.text = text
	var st := overlay_box.find_child("AgainStatus", true, false) if overlay_box else null
	if st:
		st.text = text
	for b in _again_btns:
		if is_instance_valid(b):
			b.disabled = Net.again_me or not Net.in_room or Net.opponent == ""
			b.text = "Waiting…" if Net.again_me else "Play again"


func _play_again() -> void:
	Net.want_again()


func _main_menu() -> void:
	Net.leave()
	GameState.go("home")


## The loser closes the result card and finishes the puzzle; the race result stays the same.
func _keep_solving() -> void:
	_finishing = true
	_win_next = null
	_hide_overlay()
	UI.toast("Finish at your own pace. Play again and Main menu are under your opponent's grid.")
