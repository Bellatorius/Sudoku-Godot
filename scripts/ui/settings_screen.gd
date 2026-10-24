extends Control
## Settings in tabs: Gameplay (highlighting, notes, timer), Display (dark mode, fullscreen, FPS cap,
## V-Sync), Sound.


## Tab shown last; kept while the game runs (dark mode rebuilds the screen, the tab stays).
static var _tab := "gameplay"
const TABS := [["gameplay", "Gameplay"], ["display", "Display"], ["sound", "Sound"]]


func setup(_params: Dictionary) -> void:
	var parts := UI.page(720, 44)
	add_child(parts[0])
	var col: VBoxContainer = parts[1]
	col.add_child(UI.heading("Settings", 46))

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	col.add_child(bar)
	var pages := {}
	var tab_btns := {}
	for t in TABS:
		var b := UI.button(t[1], "ChipButton")
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.add_child(b)
		tab_btns[t[0]] = b
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", 14)
		pages[t[0]] = page
	var show := func(key: String):
		_tab = key
		for k in pages:
			pages[k].visible = k == key
			tab_btns[k].button_pressed = k == key
	for k in tab_btns:
		tab_btns[k].pressed.connect(func(): show.call(k))

	# --- Gameplay
	var gv := _panel(pages.gameplay)
	for item in [
		["highlight_conflicts", "Highlight rule conflicts", "Show broken rules in red as you play."],
		["highlight_same", "Highlight matching digits", "Tint every cell with the selected digit."],
		["highlight_peers", "Highlight row, column and box", "Shade the cells that see the selected cell."],
		["color_notes", "Colour pencil marks", "Blue = still possible, red = already placed in the same row, column, box or cage."],
		["auto_clear_notes", "Auto-remove pencil marks", "Placing a digit clears it from notes in the same row, column, region and cage."],
		["show_timer", "Show timer", "The timer still runs for best times when hidden."],
	]:
		gv.add_child(_toggle(item[0], item[1], item[2]))

	# --- Display
	var dv := _panel(pages.display)
	dv.add_child(_toggle("dark_mode", "Dark mode", "Dark paper and light ink, easier on the eyes at night."))
	dv.add_child(_toggle("fullscreen", "Fullscreen", "Also toggled with F11."))
	dv.add_child(_toggle("line_intro", "Draw-in animation", "When a puzzle opens, its lines, thermometers and arrows draw themselves in."))
	dv.add_child(HSeparator.new())
	dv.add_child(_fps_cap())
	dv.add_child(HSeparator.new())
	dv.add_child(_toggle("vsync", "V-Sync", "Matches your monitor's refresh rate and stops screen tearing. While it's on, the FPS cap can't go above your monitor's refresh rate."))

	# --- Sound
	var sv := _panel(pages.sound)
	var music_desc := "A cappella vocal music. Press M anywhere to mute or unmute."
	if not Audio.has_music():
		music_desc = "No music tracks installed yet (audio/music/)."
	sv.add_child(_toggle("music_on", "Music", music_desc))
	sv.add_child(_slider("music_volume", "Music volume"))
	sv.add_child(HSeparator.new())
	sv.add_child(_toggle("sfx_on", "Sound effects", "Arabic frame drum: a bright stroke for a valid digit, a dull double hit when a digit breaks a rule."))
	sv.add_child(_slider("sfx_volume", "Effects volume", "correct"))

	for k in pages:
		col.add_child(pages[k])
	col.add_child(UI.label("Sudoku Variants v%s" % ProjectSettings.get_setting("application/config/version"), 13, UI.INK_FAINT))
	var credits := UI.label("Classic Master puzzles (17 givens): from Gordon Royle's collection of 17-clue Sudoku (University of Western Australia), completed by the Enjoy Sudoku Players Forum; ratings by Denis Berthier.", 12, UI.INK_FAINT)
	credits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(credits)
	show.call(_tab if pages.has(_tab) else "gameplay")


## A rounded card inside a tab page; returns its content column.
func _panel(page: VBoxContainer) -> VBoxContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 22))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	box.add_child(v)
	page.add_child(box)
	return v


## Frames-per-second limit: a slider from 30 up to 240, or up to the monitor's refresh rate while
## V-Sync is on (V-Sync never lets the game run faster than the monitor anyway).
func _fps_cap() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	var t := UI.label("FPS cap", 17, UI.INK, UI.font_sans_medium)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var val := UI.label("", 17, UI.ACCENT, UI.font_sans_bold)
	head.add_child(val)
	v.add_child(head)
	var d := UI.label("Limit how many frames per second the game draws. Lower saves power and keeps laptops cooler; a puzzle game looks the same at 60.", 14, UI.INK_MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(300, 0)
	v.add_child(d)
	var s := HSlider.new()
	s.min_value = 30
	s.step = 1
	s.focus_mode = Control.FOCUS_NONE
	v.add_child(s)
	var ends := HBoxContainer.new()
	var lo := UI.label("30", 13, UI.INK_FAINT)
	lo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ends.add_child(lo)
	var hi := UI.label("", 13, UI.INK_FAINT)
	ends.add_child(hi)
	v.add_child(ends)
	var note := UI.label("", 13, UI.INK_MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(300, 0)
	v.add_child(note)
	var setting := [false]   # true while the code moves the slider (not the player)
	var sync := func():   # range follows V-Sync: 240, or the monitor's refresh rate
		var top := GameState.fps_max()
		setting[0] = true
		s.max_value = top
		s.value = GameState.fps_limit()
		setting[0] = false
		hi.text = str(top)
		val.text = "%d FPS" % int(s.value)
		note.visible = top < 240
		note.text = "V-Sync is on, so the cap goes up to your monitor's %d Hz. Turn V-Sync off to go up to 240." % top
	s.value_changed.connect(func(x: float):
		val.text = "%d FPS" % int(x)
		if not setting[0]:
			Engine.max_fps = int(x))   # live; saved when released
	var save := func():
		if int(GameState.settings.get("fps_cap", 240)) != int(s.value):
			GameState.settings.fps_cap = int(s.value)
			GameState.save_settings()
	s.drag_ended.connect(func(_changed): save.call())
	s.gui_input.connect(func(e):   # a plain click on the track (no drag) also counts
		if e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			save.call())
	GameState.settings_changed.connect(sync)   # V-Sync switched
	v.tree_exiting.connect(func(): GameState.settings_changed.disconnect(sync))
	sync.call()
	return v


func _slider(key: String, title: String, preview := "") -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := UI.label(title, 15, UI.INK_MUTED)
	l.custom_minimum_size = Vector2(150, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(GameState.settings.get(key, 0.5))
	s.focus_mode = Control.FOCUS_NONE
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(v: float):
		GameState.settings[key] = v
		GameState.save_settings())
	if preview != "":
		s.drag_ended.connect(func(_c): Audio.play(preview))
	h.add_child(s)
	return h


func _toggle(key: String, title: String, desc: String) -> Control:
	var h := HBoxContainer.new()
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	v.add_child(UI.label(title, 17, UI.INK, UI.font_sans_medium))
	var d := UI.label(desc, 14, UI.INK_MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(300, 0)
	v.add_child(d)
	h.add_child(v)
	var cb := CheckButton.new()
	cb.focus_mode = Control.FOCUS_NONE
	cb.button_pressed = bool(GameState.settings.get(key, false))
	cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cb.toggled.connect(func(on: bool):
		GameState.settings[key] = on
		GameState.save_settings())
	h.add_child(cb)
	return h

