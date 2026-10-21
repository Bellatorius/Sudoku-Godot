extends Control
## Daily Challenge: month calendar of past dailies (play the ones you missed), today's puzzle,
## and the Steam leaderboard for the selected day.

const WEEKDAYS := ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

var month_year := 0      # shown month
var month := 0
var selected := ""       # selected date
var month_label: Label
var prev_btn: Button
var next_btn: Button
var grid: GridContainer
var detail: VBoxContainer
var board_box: VBoxContainer
var friends := false


func setup(params: Dictionary) -> void:
	selected = str(params.get("date", GameState.today()))
	var parts := selected.split("-")
	month_year = int(parts[0])
	month = int(parts[1])

	var page := UI.page(1060, 44)
	add_child(page[0])
	var col: VBoxContainer = page[1]
	col.add_child(UI.heading("Daily Challenge", 46))
	var streak := GameState.current_streak()
	# a new day starts at 00:00 UTC for everyone: show when that is on this PC's clock
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))
	var reset := "%02d:%02d" % [posmod(bias, 1440) / 60, posmod(bias, 60)]
	var sub := UI.label("A new puzzle every day from all %d variants, the same for every player, always a tough one: no hints or checks, 3 mistakes allowed. The next one starts at %s your time. Missed a day? Play it from the calendar.  ·  Streak: %d day%s" % [Variants.CORE.size(), reset, streak, "" if streak == 1 else "s"], 16, UI.INK_MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(300, 0)
	col.add_child(sub)
	col.add_child(UI.spacer(6))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	col.add_child(h)

	# --- calendar card
	var cal := PanelContainer.new()
	cal.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 22))
	h.add_child(cal)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 12)
	cal.add_child(cv)
	var head := HBoxContainer.new()
	prev_btn = UI.button("‹", "NavButton", func(): _shift_month(-1))
	prev_btn.add_theme_font_size_override("font_size", 26)
	head.add_child(prev_btn)
	month_label = UI.label("", 22, UI.INK, UI.font_serif)
	month_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	month_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(month_label)
	next_btn = UI.button("›", "NavButton", func(): _shift_month(1))
	next_btn.add_theme_font_size_override("font_size", 26)
	head.add_child(next_btn)
	cv.add_child(head)
	grid = GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	cv.add_child(grid)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 16)
	for item in [[UI.GOLD, "Solved"], [UI.ACCENT, "In progress"], [UI.LINE_STRONG, "Not played"]]:
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var c: Color = item[0]
		dot.draw.connect(func(): dot.draw_circle(Vector2(5, 5), 5, c, true, -1.0, true))
		legend.add_child(dot)
		legend.add_child(UI.label(item[1], 13, UI.INK_MUTED))
	cv.add_child(legend)

	# --- right: details + leaderboard
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	h.add_child(right)
	var dcard := PanelContainer.new()
	dcard.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 22))
	detail = VBoxContainer.new()
	detail.add_theme_constant_override("separation", 8)
	dcard.add_child(detail)
	right.add_child(dcard)
	var lcard := PanelContainer.new()
	lcard.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 22))
	board_box = VBoxContainer.new()
	board_box.add_theme_constant_override("separation", 8)
	lcard.add_child(board_box)
	right.add_child(lcard)

	SteamManager.daily_leaderboard_loaded.connect(_on_leaderboard)
	_build_month()
	_select(selected)


# ------------------------------------------------------------------ calendar

func _shift_month(n: int) -> void:
	month += n
	if month < 1:
		month = 12
		month_year -= 1
	elif month > 12:
		month = 1
		month_year += 1
	_build_month()


func _build_month() -> void:
	for c in grid.get_children():
		c.queue_free()
	var first := "%04d-%02d-01" % [month_year, month]
	month_label.text = "%s %d" % [["January", "February", "March", "April", "May", "June", "July", "August",
		"September", "October", "November", "December"][month - 1], month_year]
	var today := GameState.today()
	prev_btn.disabled = first <= GameState.DAILY_FIRST_DATE
	next_btn.disabled = first >= today.substr(0, 8) + "01"
	for w in WEEKDAYS:
		var l := UI.label(w, 12, UI.INK_FAINT, UI.font_sans_bold)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(52, 0)
		grid.add_child(l)
	for i in GameState.weekday(first):
		grid.add_child(UI.spacer(0, 52))
	var date := first
	while date.substr(0, 7) == first.substr(0, 7):
		grid.add_child(_day_button(date, today))
		date = GameState.add_days(date, 1)


func _day_button(date: String, today: String) -> Button:
	var b := UI.button(str(int(date.substr(8, 2))), "")
	b.custom_minimum_size = Vector2(52, 52)
	var playable := date <= today and date >= GameState.DAILY_FIRST_DATE
	var done := GameState.daily_done(date)
	var started := GameState.has_game("daily:" + date)
	var bg := UI.SURFACE
	var border := UI.LINE
	var fg := UI.INK
	if done:
		bg = UI.GOLD_SOFT; border = Color(UI.GOLD, 0.55); fg = UI.GOLD_TEXT
	elif started:
		bg = UI.ACCENT_SOFT; border = UI.ACCENT; fg = UI.ACCENT
	if date == selected:
		border = UI.INK
	var sb := UI.box(bg, border, 12, 2 if (date == selected or date == today) else 1)
	var sbh := UI.box(bg, UI.ACCENT, 12, 2)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.add_theme_stylebox_override("disabled", UI.box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12, 0))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, fg)
	b.add_theme_color_override("font_disabled_color", UI.INK_FAINT)
	if date == today:
		b.add_theme_font_override("font", UI.font_sans_bold)
	b.disabled = not playable
	var dinfo := GameState.daily_info(date)
	b.tooltip_text = "%s · %s%s" % [date, Variants.display_name(dinfo.variant), "  ✓ " + UI.format_time(GameState.daily_time(date)) if done and GameState.daily_time(date) > 0 else ""]
	b.pressed.connect(func(): _select(date))
	return b


# ------------------------------------------------------------------ details

func _select(date: String) -> void:
	selected = date
	if date.substr(0, 7) == "%04d-%02d" % [month_year, month]:
		_build_month()
	for c in detail.get_children():
		c.queue_free()
	var info := GameState.daily_info(date)
	var today := GameState.today()
	var is_today := date == today
	detail.add_child(UI.label(("TODAY  ·  " if is_today else "") + date, 12, UI.GOLD_TEXT, UI.font_sans_bold))
	detail.add_child(UI.label(Variants.display_name(info.variant), 26, UI.INK, UI.font_serif))
	var status := "Not played yet."
	var btn_text := "Play"
	var can_play := date <= today
	if GameState.daily_done(date):
		var t := GameState.daily_time(date)
		status = "Solved%s." % ((" in " + UI.format_time(t)) if t > 0 else "")
		can_play = false
	elif GameState.has_game("daily:" + date):
		var st: Dictionary = GameState.load_game("daily:" + date)
		status = "In progress · %s" % UI.format_time(float(st.get("elapsed", 0.0)))
		btn_text = "Continue"
	if not is_today and not GameState.daily_done(date):
		status += "  Past days don't count toward your streak."
	var sl := UI.label(status, 15, UI.INK_MUTED)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sl.custom_minimum_size = Vector2(240, 0)
	detail.add_child(sl)
	if can_play:
		var b := UI.button(btn_text, "PrimaryButton", func(): GameState.go("game", {"daily": date}))
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		detail.add_child(b)
	_load_leaderboard()


# ------------------------------------------------------------------ leaderboard

func _load_leaderboard() -> void:
	for c in board_box.get_children():
		c.queue_free()
	var top := HBoxContainer.new()
	var t := UI.label("Leaderboard", 20, UI.INK, UI.font_serif)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	for f in [false, true]:
		var chip := UI.button("Friends" if f else "Global", "ChipButton", func():
			friends = f
			_load_leaderboard())
		chip.toggle_mode = true
		chip.button_pressed = friends == f
		top.add_child(chip)
	board_box.add_child(top)
	board_box.add_child(UI.label("Loading…", 14, UI.INK_MUTED))
	SteamManager.request_daily_leaderboard(selected, friends)


func _on_leaderboard(date: String, f: bool, entries: Array, error: String) -> void:
	if date != selected or f != friends or not is_inside_tree():
		return
	var kids := board_box.get_children()
	if kids.size() > 1:
		kids[-1].queue_free()
	if error == "offline":
		var l := UI.label("Leaderboards appear when the game runs through Steam. Your own times are saved either way.", 14, UI.INK_MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(240, 0)
		board_box.add_child(l)
		return
	if entries.is_empty():
		board_box.add_child(UI.label("No times yet. Be the first!", 14, UI.INK_MUTED))
		return
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 18)
	g.add_theme_constant_override("v_separation", 6)
	for e in entries:
		var col: Color = UI.ACCENT if e.is_me else UI.INK
		var font: Font = UI.font_sans_bold if e.is_me else UI.font_sans
		g.add_child(UI.label("#%d" % e.rank, 15, UI.INK_MUTED, font))
		var n := UI.label(e.name, 15, col, font)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		g.add_child(n)
		g.add_child(UI.label(UI.format_time(e.seconds), 15, col, font))
	board_box.add_child(g)
