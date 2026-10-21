extends Control
## "Sudoku Variants — 40+ Logic Puzzle Types": hero, search, daily banner and variant card grid.

var grid: GridContainer
var search: LineEdit
var cards: Array = []
var only_playable := false
var _chip_all: Button
var _chip_play: Button
var empty_label: Label


func setup(_params: Dictionary) -> void:
	var parts := UI.page(1120, 44)
	var scroll: ScrollContainer = parts[0]
	var col: VBoxContainer = parts[1]
	add_child(scroll)

	var title := UI.heading("Sudoku Variants — 40+ Logic Puzzle Types", 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	var sub := UI.label("Play every Sudoku variant — Thermo, Killer, Arrow, Jigsaw, Kropki, XV and more. Rules, tips and endless puzzles for each.", 18, UI.INK_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)
	col.add_child(UI.spacer(6))

	var sc := CenterContainer.new()
	search = LineEdit.new()
	search.placeholder_text = "Search variants..."
	search.custom_minimum_size = Vector2(480, 0)
	search.clear_button_enabled = true
	search.text_changed.connect(func(_t): _filter())
	sc.add_child(search)
	col.add_child(sc)
	col.add_child(UI.spacer(8))

	col.add_child(_daily_banner())
	col.add_child(_random_card())
	col.add_child(UI.spacer(4))

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	_chip_all = UI.button("All 42", "ChipButton", func(): _set_mode(false))
	_chip_play = UI.button("Playable now (%d)" % Variants.CORE.size(), "ChipButton", func(): _set_mode(true))
	_chip_all.toggle_mode = true
	_chip_play.toggle_mode = true
	chips.add_child(_chip_all)
	chips.add_child(_chip_play)
	col.add_child(chips)

	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	col.add_child(grid)
	empty_label = UI.label("No variants match your search.", 16, UI.INK_MUTED)
	empty_label.visible = false
	col.add_child(empty_label)

	# Playable variants first, then the rest alphabetically (site order).
	var ordered: Array = []
	for id in Variants.CORE:
		ordered.append(Variants.get_info(id))
	for v in Variants.LIST:
		if not Variants.is_playable(v.id):
			ordered.append(v)
	for v in ordered:
		var card := _make_card(v)
		cards.append(card)
		grid.add_child(card)

	resized.connect(_on_resized)
	_on_resized()
	_set_mode(false)


func _on_resized() -> void:
	if grid:
		grid.columns = 3 if size.x >= 1180 else 2


func _set_mode(playable: bool) -> void:
	only_playable = playable
	_chip_all.button_pressed = not playable
	_chip_play.button_pressed = playable
	_filter()


func _filter() -> void:
	var q := search.text.strip_edges().to_lower()
	var shown := 0
	for card in cards:
		var v: Dictionary = card.get_meta("info")
		var hit: bool = q == "" or v.name.to_lower().contains(q) or v.short.to_lower().contains(q)
		if only_playable and not Variants.is_playable(v.id):
			hit = false
		card.visible = hit
		if hit: shown += 1
	empty_label.visible = shown == 0


func _daily_banner() -> Control:
	var info := GameState.daily_info()
	var done := GameState.daily_done()
	var p := PanelContainer.new()
	var sb := UI.box(UI.GOLD_SOFT, Color(UI.GOLD, 0.45), UI.RADIUS, 1, 0)
	sb.content_margin_left = 24; sb.content_margin_right = 24
	sb.content_margin_top = 18; sb.content_margin_bottom = 18
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	p.add_child(h)
	var icon := VariantIcon.new(info.variant, 40)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icon)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(UI.label("Daily Puzzle", 13, UI.GOLD_TEXT, UI.font_sans_bold))
	top.add_child(UI.label(GameState.today(), 13, UI.INK_MUTED))
	v.add_child(top)
	v.add_child(UI.label("Today's challenge: %s" % Variants.display_name(info.variant), 22, UI.INK, UI.font_serif))
	var streak := GameState.current_streak()
	var line := "Current streak: %d day%s" % [streak, "" if streak == 1 else "s"]
	if done:
		line = "Solved today ✓  ·  " + line
	v.add_child(UI.label(line, 14, UI.INK_MUTED))
	h.add_child(v)
	var cal := UI.button("Calendar", "", func(): GameState.go("daily"))
	cal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cal)
	var btn := UI.button("Solved ✓" if done else "Play daily", "PrimaryButton", func(): GameState.go("game", {"daily": info.date}))
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.disabled = done
	h.add_child(btn)
	return p


func _make_card(v: Dictionary) -> Control:
	var playable := Variants.is_playable(v.id)
	var card := PanelContainer.new()
	card.set_meta("info", v)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 98)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if playable else Control.CURSOR_ARROW
	var normal := UI.card_box(false)
	var hover := UI.card_box(true)
	card.add_theme_stylebox_override("panel", normal)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(h)
	var icon := VariantIcon.new(v.id, 30)
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if not playable:
		icon.color = UI.INK_MUTED
	h.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_l := UI.label(v.name, 18, UI.INK if playable else UI.INK_MUTED, UI.font_sans_bold)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_l)
	if playable:
		var solved := GameState.variant_solved_count(v.id)
		if solved > 0:
			top.add_child(UI.tag("%d solved" % solved, UI.SUCCESS, Color(UI.SUCCESS, 0.12)))
		else:
			top.add_child(UI.tag("Play", UI.ACCENT, UI.ACCENT_SOFT))
	else:
		top.add_child(UI.tag("Coming soon", UI.INK_MUTED, UI.PAPER_WARM))
	col.add_child(top)
	var desc := UI.label(v.short, 14, UI.INK_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.max_lines_visible = 2
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.custom_minimum_size = Vector2(120, 46)
	col.add_child(desc)
	for c in [name_l, desc]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.mouse_entered.connect(func(): if playable: card.add_theme_stylebox_override("panel", hover))
	card.mouse_exited.connect(func(): card.add_theme_stylebox_override("panel", normal))
	card.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if playable:
				GameState.go("variant", {"id": v.id})
			else:
				UI.toast("%s is coming soon — it's on the roadmap!" % v.name))
	return card


## "Random puzzle": a random variant at the selected difficulty (see _add_random_buttons).
func _random_card() -> Control:
	var p := PanelContainer.new()
	var sb := UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 0)
	sb.content_margin_left = 24; sb.content_margin_right = 24
	sb.content_margin_top = 16; sb.content_margin_bottom = 16
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	v.add_child(UI.label("Random puzzle", 22, UI.INK, UI.font_serif))
	v.add_child(UI.label("Pick a difficulty, then press it again to play a random variant.", 14, UI.INK_MUTED))
	h.add_child(v)
	_add_random_buttons(h, 92)
	return p


## Easy / Medium / Hard buttons for the random puzzle. The first click selects a difficulty: its
## text is replaced by a tick (and it's remembered in settings.random_difficulty), meaning
## "press again". Clicking the ticked button starts a random puzzle at that difficulty.
func _add_random_buttons(box: BoxContainer, min_w := 96) -> void:
	var buttons := {}
	var refresh := func():
		var sel := str(GameState.settings.get("random_difficulty", "medium"))
		for d in buttons:
			var b: Button = buttons[d]
			var on: bool = d == sel
			b.text = "" if on else String(d).capitalize()
			b.theme_type_variation = "PrimaryButton" if on else ""
			b.tooltip_text = ("%s selected. Click again to play a random %s puzzle." % [String(d).capitalize(), d]) if on else "Select %s" % d
			b.get_node("Tick").visible = on
	for d in GameState.DIFFICULTIES:
		var b := UI.button(String(d).capitalize(), "")
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.custom_minimum_size = Vector2(min_w, 40)
		var tick := Control.new()
		tick.name = "Tick"
		tick.set_anchors_preset(Control.PRESET_FULL_RECT)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.draw.connect(func():
			var c := tick.size / 2.0
			# same line weight as the other icons in the UI (about 2 px)
			var s := minf(tick.size.y * 0.22, 8.0)
			var col: Color = b.get_theme_color("font_color")
			tick.draw_polyline(PackedVector2Array([c + Vector2(-s, 0.05 * s), c + Vector2(-0.3 * s, 0.75 * s), c + Vector2(s, -0.75 * s)]),
				col, 2.2, true))
		b.add_child(tick)
		b.pressed.connect(func():
			if str(GameState.settings.get("random_difficulty", "medium")) == d:
				GameState.go("game", GameState.random_game_params(d))
			else:
				GameState.settings.random_difficulty = d
				GameState.save_settings()
				refresh.call())
		buttons[d] = b
		box.add_child(b)
	refresh.call()
