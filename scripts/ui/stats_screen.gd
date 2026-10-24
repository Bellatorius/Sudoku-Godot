extends Control
## Player statistics: totals, solves per level, the daily calendar, recent solves, the 1v1 record,
## per-variant best times (with a search like the home page; click a row for that variant's details)
## and achievements.

const Home := preload("res://scripts/ui/home_screen.gd")
const HEAT_WEEKS := 40
const HEAT_CELL := 15
const HEAT_GAP := 4
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
## Averages, perfect solves, losses, play time and recent solves only exist from this day on.
const TRACKED_FROM := "24 Oct 2026"

const TOP_ROWS := 20   # best-times rows shown before the table is expanded

var _rows := {}        # variant id -> the table cells of its row
var _order: Array = [] # variant ids, most played first
var _no_match: Label
var _expander: Control
var _expanded := false
var _query := ""
var _modal: Control


func setup(_params: Dictionary) -> void:
	var parts := UI.page(1000, 44)
	add_child(parts[0])
	var col: VBoxContainer = parts[1]
	col.add_child(UI.heading("Your Stats", 46))
	var st := GameState.stats

	col.add_child(_tiles(st))
	col.add_child(UI.label("Averages, perfect solves, losses and play time are counted from %s." % TRACKED_FROM, 13, UI.INK_FAINT))
	col.add_child(UI.spacer(10))
	col.add_child(_section("By level"))
	col.add_child(_levels(st))
	col.add_child(UI.spacer(10))
	col.add_child(_section("Daily puzzles"))
	col.add_child(_heatmap(st))
	col.add_child(UI.spacer(10))
	col.add_child(_section("Recent solves"))
	col.add_child(_recent(st))
	col.add_child(UI.spacer(10))
	col.add_child(_section("1v1 races"))
	col.add_child(_races(st))
	col.add_child(UI.spacer(10))
	col.add_child(_best_times())

	col.add_child(UI.spacer(10))
	col.add_child(_section("Achievements"))
	var note := UI.label("Unlocked through Steam when the game runs with Steam (GodotSteam).", 14, UI.INK_MUTED)
	col.add_child(note)
	var ag := GridContainer.new()
	ag.columns = 2
	ag.add_theme_constant_override("h_separation", 14)
	ag.add_theme_constant_override("v_separation", 10)
	for key in SteamManager.ACHIEVEMENTS:
		var text: String = SteamManager.ACHIEVEMENTS[key]
		var parts2 := text.split(" — ")
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", UI.box(UI.PAPER, UI.LINE_STRONG, 12, 1, 14))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.add_child(UI.label(parts2[0], 16, UI.INK, UI.font_sans_bold))
		v.add_child(UI.label(parts2[1] if parts2.size() > 1 else "", 14, UI.INK_MUTED))
		p.add_child(v)
		ag.add_child(p)
	col.add_child(ag)


func _input(event: InputEvent) -> void:
	if _modal and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_detail()
		get_viewport().set_input_as_handled()


func _section(text: String) -> Label:
	return UI.label(text, 24, UI.INK, UI.font_serif)


# ---------------------------------------------------------------- totals

func _tiles(st: Dictionary) -> Control:
	var played := 0
	var mastered := 0
	var most := ""
	var most_n := 0
	for id in Variants.CORE:
		var vs := GameState.variant_stats(id)
		if int(vs.solved) > 0:
			played += 1
		if vs.best.has("master"):
			mastered += 1
		if int(vs.solved) > most_n:
			most_n = int(vs.solved)
			most = id
	var lost := int(st.get("total_lost", 0))
	var solved := int(st.total_solved)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	for t in [["Puzzles solved", str(solved)],
			["Win rate", "%d%%" % roundi(100.0 * solved / (solved + lost)) if solved + lost > 0 else "—",
				"%d lost to the mistake limit" % lost],
			["Perfect solves", str(int(st.get("perfect", 0))), "no hints, no mistakes"],
			["Play time", _hours(float(st.get("play_time", 0.0)))],
			["Most played", Variants.display_name(most) if most != "" else "—", "%d solves" % most_n if most != "" else ""],
			["Daily streak", str(GameState.current_streak())],
			["Best streak", str(int(st.daily.best_streak))],
			["Variants played", "%d / %d" % [played, Variants.CORE.size()]],
			["Variants mastered", "%d / %d" % [mastered, Variants.CORE.size()], "solved on Master"],
			["Dailies solved", str(st.daily.done.size())]]:
		grid.add_child(_tile(t[0], t[1], t[2] if t.size() > 2 else ""))
	return grid


func _tile(title: String, value: String, sub := "") -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 18))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(UI.label(title.to_upper(), 12, UI.INK_FAINT, UI.font_sans_bold))
	var big := UI.label(value, 34 if value.length() <= 9 else 20, UI.INK, UI.font_serif)
	big.custom_minimum_size.y = 44
	big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	big.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(big)
	if sub != "":
		v.add_child(UI.label(sub, 12, UI.INK_MUTED))
	p.add_child(v)
	return p


static func _hours(seconds: float) -> String:
	var m := int(seconds) / 60
	if m < 60:
		return "%d m" % m
	return "%d h %d m" % [m / 60, m % 60]


# ---------------------------------------------------------------- by level

func _levels(st: Dictionary) -> Control:
	var perfect := {}
	var lost := {}
	for id in st.variants:
		var lv: Dictionary = st.variants[id].get("levels", {})
		for d in lv:
			perfect[d] = int(perfect.get(d, 0)) + int(lv[d].get("perfect", 0))
			lost[d] = int(lost.get(d, 0)) + int(lv[d].get("lost", 0))
	var solved: Dictionary = st.get("levels", {})
	var top := 1
	for d in GameState.DIFFICULTIES:
		top = maxi(top, int(solved.get(d, 0)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for d in GameState.DIFFICULTIES:
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 16))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		v.add_child(UI.label(String(d).to_upper(), 12, UI.INK_FAINT, UI.font_sans_bold))
		var n := int(solved.get(d, 0))
		v.add_child(UI.label(str(n), 30, UI.INK, UI.font_serif))
		var bar := Control.new()   # share of the most-solved level
		bar.custom_minimum_size = Vector2(0, 6)
		var frac := float(n) / top
		bar.draw.connect(func():
			bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(UI.INK, 0.08))
			bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * frac, bar.size.y)), UI.ACCENT))
		v.add_child(bar)
		v.add_child(UI.label("%d perfect · %d lost" % [int(perfect.get(d, 0)), int(lost.get(d, 0))], 12, UI.INK_MUTED))
		p.add_child(v)
		row.add_child(p)
	return row


# ---------------------------------------------------------------- daily calendar

## The last HEAT_WEEKS weeks, one column per week (Monday on top); a gold square = daily solved.
func _heatmap(st: Dictionary) -> Control:
	var done: Dictionary = st.daily.done
	var today := GameState.today()
	var t_today := Time.get_unix_time_from_datetime_string(today + "T12:00:00")
	var wd := int(Time.get_datetime_dict_from_unix_time(t_today).weekday)   # 0 = Sunday
	var monday := t_today - ((wd + 6) % 7) * 86400
	var start := monday - (HEAT_WEEKS - 1) * 7 * 86400
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 18))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	box.add_child(v)
	v.add_child(UI.label("%d dailies solved · current streak %d · best streak %d" % [done.size(),
		GameState.current_streak(), int(st.daily.best_streak)], 14, UI.INK_MUTED))
	var map := Control.new()
	var step := HEAT_CELL + HEAT_GAP
	map.custom_minimum_size = Vector2(HEAT_WEEKS * step + 34, 7 * step + 18)
	map.mouse_filter = Control.MOUSE_FILTER_STOP
	var cell_date := func(pos: Vector2) -> String:
		var c := int((pos.x - 34) / step)
		var r := int((pos.y - 18) / step)
		if pos.x < 34 or pos.y < 18 or c < 0 or c >= HEAT_WEEKS or r < 0 or r > 6:
			return ""
		return Time.get_date_string_from_unix_time(start + (c * 7 + r) * 86400)
	map.draw.connect(func():
		var font := UI.font_sans
		for r in [0, 2, 4]:
			map.draw_string(font, Vector2(0, 18 + r * step + HEAT_CELL - 3), ["Mon", "", "Wed", "", "Fri"][r], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.INK_FAINT)
		var last_month := -1
		var last_label := -9
		for c in HEAT_WEEKS:
			var mo := int(Time.get_datetime_dict_from_unix_time(start + c * 7 * 86400).month)
			if mo != last_month:
				if c - last_label >= 3:   # a month that starts right after the first column gets no label
					map.draw_string(font, Vector2(34 + c * step, 11), MONTHS[mo - 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.INK_FAINT)
					last_label = c
				last_month = mo
			for r in 7:
				var date := Time.get_date_string_from_unix_time(start + (c * 7 + r) * 86400)
				if date > today:
					continue
				var rect := Rect2(34 + c * step, 18 + r * step, HEAT_CELL, HEAT_CELL)
				map.draw_rect(rect, UI.GOLD if done.has(date) else Color(UI.INK, 0.08))
				if date == today:
					map.draw_rect(rect.grow(1.5), UI.ACCENT, false, 2.0))
	map.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseMotion:
			var date: String = cell_date.call(e.position)
			if date == "" or date > today:
				map.tooltip_text = ""
			elif done.has(date):
				map.tooltip_text = "%s · solved in %s" % [date, UI.format_time(float(done[date].get("time", 0.0)))]
			else:
				map.tooltip_text = "%s · not solved" % date)
	v.add_child(map)
	return box


# ---------------------------------------------------------------- recent solves

func _recent(st: Dictionary) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	box.add_child(v)
	var recent: Array = st.get("recent", [])
	if recent.is_empty():
		v.add_child(UI.label("Your last 10 solves show up here.", 15, UI.INK_MUTED))
		return box
	for r in recent:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var id := str(r.get("v", ""))
		row.add_child(VariantIcon.new(id, 22))
		var nm := UI.label(Variants.display_name(id), 16, UI.INK, UI.font_sans_medium)
		row.add_child(nm)
		row.add_child(UI.tag(str(r.get("d", "")).to_upper(), UI.ACCENT, UI.ACCENT_SOFT))
		if r.get("daily", false):
			row.add_child(UI.tag("DAILY", UI.GOLD_TEXT, UI.GOLD_SOFT))
		if r.get("best", false):
			row.add_child(UI.tag("NEW BEST", UI.GOLD_TEXT, UI.GOLD_SOFT))
		if r.get("perfect", false):
			row.add_child(UI.tag("PERFECT", UI.INK_MUTED, Color(UI.INK, 0.07)))
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(sp)
		row.add_child(UI.label(UI.format_time(float(r.get("t", 0.0))), 16, UI.INK, UI.font_sans_medium))
		var when := UI.label(_when(float(r.get("at", 0.0))), 14, UI.INK_FAINT)
		when.custom_minimum_size.x = 90
		when.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(when)
		v.add_child(row)
	return box


## "today", "yesterday" or "24 Oct" (local time).
static func _when(unix: float) -> String:
	if unix <= 0.0:
		return ""
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var day := Time.get_date_string_from_unix_time(int(unix) + bias)
	var now := int(Time.get_unix_time_from_system()) + bias
	if day == Time.get_date_string_from_unix_time(now):
		return "today"
	if day == Time.get_date_string_from_unix_time(now - 86400):
		return "yesterday"
	var p := day.split("-")
	return "%d %s" % [int(p[2]), MONTHS[int(p[1]) - 1]]


# ---------------------------------------------------------------- 1v1

func _races(st: Dictionary) -> Control:
	var mp: Dictionary = st.get("multiplayer", {})
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var bt := float(mp.get("best_time", 0.0))
	for t in [["Wins", str(int(mp.get("wins", 0)))], ["Losses", str(int(mp.get("losses", 0)))],
			["Win streak", "%d" % int(mp.get("streak", 0)), "best %d" % int(mp.get("best_streak", 0))],
			["Fastest win", UI.format_time(bt) if bt > 0.0 else "—"]]:
		row.add_child(_tile(t[0], t[1], t[2] if t.size() > 2 else ""))
	return row


# ---------------------------------------------------------------- best times + details

func _best_times() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	var head := HBoxContainer.new()
	var title := _section("Best times")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var search := LineEdit.new()
	search.placeholder_text = "Search variants..."
	search.custom_minimum_size = Vector2(240, 0)
	search.clear_button_enabled = true
	search.text_changed.connect(_filter)
	head.add_child(search)
	v.add_child(head)
	v.add_child(UI.label("Most played first. Click a variant for its details.", 13, UI.INK_FAINT))

	var table := PanelContainer.new()
	table.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 8))
	var grid := GridContainer.new()
	grid.columns = 2 + GameState.DIFFICULTIES.size()
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 14)
	m.add_child(grid)
	table.add_child(m)
	for h in ["Variant", "Solved"] + GameState.DIFFICULTIES.map(func(x): return String(x).capitalize()):
		var l := UI.label(h.to_upper(), 12, UI.INK_FAINT, UI.font_sans_bold)
		if h == "Variant":
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(l)
	_order = Variants.CORE.duplicate()
	var rank := {}
	for i in _order.size():
		rank[_order[i]] = i
	# most solved first; equal counts keep the catalogue order
	_order.sort_custom(func(a, b):
		var na := int(GameState.variant_stats(a).solved)
		var nb := int(GameState.variant_stats(b).solved)
		return na > nb if na != nb else rank[a] < rank[b])
	for id in _order:
		var vs := GameState.variant_stats(id)
		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 10)
		name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_row.mouse_filter = Control.MOUSE_FILTER_STOP
		name_row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		name_row.tooltip_text = "Details"
		name_row.add_child(VariantIcon.new(id, 22))
		var nm := UI.label(Variants.display_name(id), 16, UI.INK, UI.font_sans_medium)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_row.add_child(nm)
		name_row.mouse_entered.connect(func(): nm.add_theme_color_override("font_color", UI.ACCENT))
		name_row.mouse_exited.connect(func(): nm.add_theme_color_override("font_color", UI.INK))
		name_row.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_open_detail(id))
		var cells: Array = [name_row, UI.label(str(int(vs.solved)), 16)]
		for d in GameState.DIFFICULTIES:
			var b := float(vs.best.get(d, 0.0))
			cells.append(UI.label(UI.format_time(b) if b > 0 else "—", 16, UI.INK if b > 0 else UI.INK_FAINT))
		for c in cells:
			grid.add_child(c)
		_rows[id] = cells
	v.add_child(table)
	_no_match = UI.label("No variants match your search.", 15, UI.INK_MUTED)
	_no_match.visible = false
	v.add_child(_no_match)
	_expander = _build_expander()
	v.add_child(_expander)
	_refresh_rows()
	return v


## A line across the page with a round arrow button in the middle: shows / hides the rows after TOP_ROWS.
func _build_expander() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var line_l := ColorRect.new()
	line_l.color = UI.LINE_STRONG
	line_l.custom_minimum_size.y = 1
	line_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var line_r := line_l.duplicate()
	row.add_child(line_l)
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.custom_minimum_size = Vector2(44, 44)
	var n_ := UI.box(UI.SURFACE, UI.LINE_STRONG, 999, 1)
	var h_ := UI.box(UI.ACCENT_SOFT, UI.ACCENT, 999, 1)
	for st in ["normal", "focus"]:
		btn.add_theme_stylebox_override(st, n_)
	for st in ["hover", "pressed", "hover_pressed"]:
		btn.add_theme_stylebox_override(st, h_)
	btn.pressed.connect(func():
		_expanded = not _expanded
		_refresh_rows())
	var arrow := Control.new()
	arrow.set_anchors_preset(Control.PRESET_FULL_RECT)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.draw.connect(func():
		var c := arrow.size / 2.0
		var d := -1.0 if _expanded else 1.0   # down = expand, up = collapse
		var col := UI.ACCENT if btn.is_hovered() else UI.INK_MUTED
		arrow.draw_polyline(PackedVector2Array([c + Vector2(-7, -3.5 * d), c + Vector2(0, 3.5 * d), c + Vector2(7, -3.5 * d)]), col, 2.2, true))
	btn.add_child(arrow)
	btn.mouse_entered.connect(arrow.queue_redraw)
	btn.mouse_exited.connect(arrow.queue_redraw)
	btn.set_meta("arrow", arrow)
	row.add_child(btn)
	row.add_child(line_r)
	row.set_meta("btn", btn)
	return row


## Search on: every matching variant. Search off: the TOP_ROWS most played, or all of them when expanded.
func _refresh_rows() -> void:
	var any := false
	for i in _order.size():
		var id: String = _order[i]
		var hit: bool = Home._matches(Variants.get_info(id), _query) if _query != "" else (_expanded or i < TOP_ROWS)
		for c in _rows[id]:
			c.visible = hit
		any = any or hit
	_no_match.visible = not any
	_expander.visible = _query == "" and _order.size() > TOP_ROWS
	var btn: Button = _expander.get_meta("btn")
	btn.tooltip_text = "Show fewer" if _expanded else "Show all %d variants" % _order.size()
	(btn.get_meta("arrow") as Control).queue_redraw()


## The search looks through all variants (same forgiving match as the home page).
func _filter(text: String) -> void:
	_query = text.strip_edges().to_lower()
	_refresh_rows()


## One variant in detail: per level solved, best, average, perfect, lost and pack progress.
func _open_detail(id: String) -> void:
	_close_detail()
	var vs := GameState.variant_stats(id)
	var lv: Dictionary = vs.get("levels", {})
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_close_detail())
	add_child(dim)
	_modal = dim
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 26))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.add_child(VariantIcon.new(id, 34))
	var t := UI.heading(Variants.display_name(id), 32)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UI.button("Close", "", _close_detail))
	v.add_child(head)
	var last := float(vs.get("last_played", 0.0))
	v.add_child(UI.label("%d solved · %d perfect · %d lost%s" % [int(vs.solved), int(vs.get("perfect", 0)),
		int(vs.get("lost", 0)), (" · last played " + _when(last)) if last > 0.0 else ""], 15, UI.INK_MUTED))

	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 10)
	for h in ["Level", "Solved", "Best", "Average", "Perfect", "Lost", "Pack"]:
		grid.add_child(UI.label(h.to_upper(), 12, UI.INK_FAINT, UI.font_sans_bold))
	for d in GameState.DIFFICULTIES:
		var e: Dictionary = lv.get(d, {})
		var pack := GameState.pack_progress(id, d)
		var n := maxi(int(e.get("n", 0)), pack.x)   # pack solves also cover the time before tracking began
		var b := float(vs.best.get(d, 0.0))
		var avg := float(e.get("time", 0.0)) / int(e.get("n", 0)) if int(e.get("n", 0)) > 0 else 0.0
		grid.add_child(UI.label(String(d).capitalize(), 16, UI.INK, UI.font_sans_medium))
		for txt in [str(n), UI.format_time(b) if b > 0 else "—", UI.format_time(avg) if avg > 0 else "—",
				str(int(e.get("perfect", 0))), str(int(e.get("lost", 0))),
				"%d / %d" % [pack.x, pack.y] if pack.y > 0 else "—"]:
			grid.add_child(UI.label(txt, 16, UI.INK if txt != "—" and txt != "0" else UI.INK_FAINT))
	v.add_child(grid)
	v.add_child(UI.label("Pack = puzzles of the built-in pack you've solved; after that, new puzzles are generated.", 12, UI.INK_FAINT))


func _close_detail() -> void:
	if _modal:
		_modal.queue_free()
		_modal = null
