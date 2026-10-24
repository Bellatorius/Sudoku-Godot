extends Control
## "Sudoku Variants — 60+ Logic Puzzle Types": hero, search, daily banner and variant card grid.

var grids: Array = []            # one card grid per group
var sections := {}               # group id -> VBoxContainer (heading + grid)
var search: LineEdit
var cards: Array = []
## Group shown on the home page ("all" or a Variants.CATEGORIES id); kept while the game runs.
static var _group := "all"
var _chips := {}
var empty_label: Label


func setup(_params: Dictionary) -> void:
	var parts := UI.page(1120, 44)
	var scroll: ScrollContainer = parts[0]
	var col: VBoxContainer = parts[1]
	add_child(scroll)

	var title := UI.heading("One grid. Endless rules.", 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	var sub := UI.label("Play every Sudoku variant — Thermo, Killer, Arrow, Jigsaw, Kropki, XV and more. Rules, tips and endless puzzles for each.", 18, UI.INK_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)
	col.add_child(UI.spacer(6))

	col.add_child(UI.spacer(8))

	col.add_child(_daily_banner())
	col.add_child(_random_card())
	col.add_child(UI.spacer(4))

	# Group filter chips (wrap onto a second line when narrow) with the search box beside them
	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 12)
	col.add_child(filter_row)
	var chips := HFlowContainer.new()
	chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	var all_groups: Array = [["all", "All", []]] + Variants.CATEGORIES
	for g in all_groups:
		var n: int = Variants.all_list().size() if g[0] == "all" else g[2].size()
		var b := UI.button("%s %d" % [g[1], n], "ChipButton")
		b.toggle_mode = true
		var key: String = g[0]
		b.pressed.connect(func(): _set_group(key))
		_chips[key] = b
		chips.add_child(b)
	filter_row.add_child(chips)
	search = LineEdit.new()
	search.placeholder_text = "Search variants..."
	search.custom_minimum_size = Vector2(240, 0)
	search.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	search.clear_button_enabled = true
	search.text_changed.connect(func(_t): _filter())
	filter_row.add_child(search)

	# One section per group: heading + its cards (in "All" every group is shown under its heading)
	for g in Variants.CATEGORIES:
		var sec := VBoxContainer.new()
		sec.add_theme_constant_override("separation", 10)
		var head := UI.label(g[1], 24, UI.INK, UI.font_serif)
		head.name = "Head"
		sec.add_child(head)
		var gr := GridContainer.new()
		gr.columns = 2
		gr.add_theme_constant_override("h_separation", 14)
		gr.add_theme_constant_override("v_separation", 14)
		sec.add_child(gr)
		grids.append(gr)
		for id in g[2]:
			var card := _make_card(Variants.get_info(id))
			cards.append(card)
			gr.add_child(card)
		sections[g[0]] = sec
		col.add_child(sec)
	empty_label = UI.label("No variants match your search.", 16, UI.INK_MUTED)
	empty_label.visible = false
	col.add_child(empty_label)

	resized.connect(_on_resized)
	_on_resized()
	_set_group(_group if _chips.has(_group) else "all")


func _on_resized() -> void:
	for gr in grids:
		gr.columns = 3 if size.x >= 1180 else 2


func _set_group(key: String) -> void:
	_group = key
	for k in _chips:
		_chips[k].button_pressed = k == key
	_filter()


func _filter() -> void:
	var q := search.text.strip_edges().to_lower()
	# Search looks in every group; if the selected group has none of the matches, show them all with a note
	# (so a typo or the wrong filter never leaves an empty page without saying why).
	var in_group := 0
	var anywhere := 0
	for card in cards:
		var v: Dictionary = card.get_meta("info")
		if _matches(v, q):
			anywhere += 1
			if _group == "all" or Variants.category(v.id) == _group:
				in_group += 1
	var widen := q != "" and in_group == 0 and anywhere > 0
	var shown := 0
	for card in cards:
		var v: Dictionary = card.get_meta("info")
		var hit := _matches(v, q) and (widen or _group == "all" or Variants.category(v.id) == _group)
		card.visible = hit
		if hit: shown += 1
	for k in sections:   # hide groups with nothing to show; the heading only matters when several groups show
		var sec: VBoxContainer = sections[k]
		var any := false
		for c in sec.get_child(1).get_children():
			if c.visible: any = true
		sec.visible = any
		sec.get_node("Head").visible = _group == "all" or widen
	if widen:
		var gname := ""
		for g in Variants.CATEGORIES:
			if g[0] == _group: gname = g[1]
		empty_label.text = "Nothing in %s matches \"%s\". Showing matches from all groups:" % [gname, search.text.strip_edges()]
	else:
		empty_label.text = "No variants match \"%s\"." % search.text.strip_edges()
	empty_label.visible = widen or shown == 0
	if widen:   # the note goes above the results
		empty_label.get_parent().move_child(empty_label, sections.values()[0].get_index())
	else:
		empty_label.get_parent().move_child(empty_label, -1)


## Forgiving search: every typed word must match a word of the name (or appear in the description).
## A word matches when it is contained, typed with letters left out ("termo" -> thermo), or one or two
## letters off ("kiler", "sandwhich").
static func _matches(v: Dictionary, q: String) -> bool:
	if q == "":
		return true
	var nm: String = str(v.name).to_lower()
	if nm.contains(q) or str(v.short).to_lower().contains(q):
		return true
	var words := nm.replace("-", " ").replace("(", " ").replace(")", " ").split(" ", false)
	for qw in q.split(" ", false):
		var ok := false
		for w in words:
			if w.contains(qw) or (qw.length() >= 3 and _subsequence(qw, w)) or 					(qw.length() >= 4 and _edits(qw, w) <= (1 if qw.length() < 6 else 2)):
				ok = true
				break
		if not ok:
			return false
	return true


static func _subsequence(a: String, b: String) -> bool:
	var i := 0
	for ch in b:
		if i < a.length() and a[i] == ch:
			i += 1
	return i == a.length()


## Edit distance (insert / delete / change one letter).
static func _edits(a: String, b: String) -> int:
	var prev: Array = range(b.length() + 1)
	for i in a.length():
		var cur: Array = [i + 1]
		for j in b.length():
			cur.append(mini(mini(prev[j + 1] + 1, cur[j] + 1), prev[j] + (0 if a[i] == b[j] else 1)))
		prev = cur
	return prev[b.length()]


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
	var sub := UI.label("Pick a difficulty, then press it again to play a random variant.", 14, UI.INK_MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(180, 0)
	v.add_child(sub)
	h.add_child(v)
	_add_random_buttons(h, 78)
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
			# selected: an outlined box with the level's name sitting in its top border, and the tick inside
			var sb := UI.box(UI.SURFACE, UI.ACCENT if on else UI.LINE_STRONG, 10, 2 if on else 1)
			sb.content_margin_left = 12; sb.content_margin_right = 12
			sb.content_margin_top = 8; sb.content_margin_bottom = 8
			var sbh := sb.duplicate()
			sbh.border_color = UI.ACCENT if on else UI.INK
			for k in ["normal", "focus"]:
				b.add_theme_stylebox_override(k, sb)
			for k in ["hover", "pressed", "hover_pressed"]:
				b.add_theme_stylebox_override(k, sbh)
			b.tooltip_text = ("%s selected. Click again to play a random %s puzzle." % [String(d).capitalize(), d]) if on else "Select %s" % d
			b.get_node("Tick").visible = on
			b.get_node("Legend").visible = on
	for d in GameState.DIFFICULTIES:
		var b := UI.button(String(d).capitalize(), "")
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.custom_minimum_size = Vector2(min_w, 40)
		b.add_theme_font_size_override("font_size", 14)
		var tick := Control.new()
		tick.name = "Tick"
		tick.set_anchors_preset(Control.PRESET_FULL_RECT)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.draw.connect(func():
			var c := tick.size / 2.0
			# same line weight as the other icons in the UI (about 2 px)
			var s := minf(tick.size.y * 0.22, 8.0)
			var col: Color = UI.ACCENT
			tick.draw_polyline(PackedVector2Array([c + Vector2(-s, 0.05 * s), c + Vector2(-0.3 * s, 0.75 * s), c + Vector2(s, -0.75 * s)]),
				col, 2.2, true))
		b.add_child(tick)
		var legend := Label.new()   # the level name in the top border (shown when selected)
		legend.name = "Legend"
		legend.text = " %s " % String(d).capitalize()
		legend.add_theme_font_size_override("font_size", 11)
		legend.add_theme_color_override("font_color", UI.ACCENT)
		legend.add_theme_stylebox_override("normal", UI.box(UI.SURFACE, Color(0, 0, 0, 0), 0, 0))
		legend.position = Vector2(8, -9)
		legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(legend)
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
