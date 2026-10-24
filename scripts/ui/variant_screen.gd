extends Control
## Variant detail: rules, solving tip, example board, and difficulty selection.

var vid := "classic"


func setup(params: Dictionary) -> void:
	vid = params.get("id", "classic")
	var info := Variants.get_info(vid)
	var parts := UI.page(1120, 28)
	add_child(parts[0])
	var col: VBoxContainer = parts[1]

	var back := UI.button("←  All variants", "NavButton", func(): GameState.go("home"))
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(back)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 40)
	col.add_child(h)

	# Left column — text + difficulty rows
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	left.add_theme_constant_override("separation", 14)
	h.add_child(left)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	var icon := VariantIcon.new(vid, 40)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(icon)
	title_row.add_child(UI.heading(info.get("name", vid), 46))
	left.add_child(title_row)

	var rules := UI.label(info.get("rules", info.get("short", "")), 17, UI.INK)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.custom_minimum_size = Vector2(300, 0)
	left.add_child(rules)

	if info.has("tip"):
		var tip := PanelContainer.new()
		var sb := UI.box(UI.ACCENT_SOFT, Color(0, 0, 0, 0), 12, 0, 16)
		tip.add_theme_stylebox_override("panel", sb)
		var tv := VBoxContainer.new()
		tv.add_child(UI.label("SOLVING TIP", 12, UI.ACCENT, UI.font_sans_bold))
		var tl := UI.label(info.tip, 15, UI.INK)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.custom_minimum_size = Vector2(280, 0)
		tv.add_child(tl)
		tip.add_child(tv)
		left.add_child(tip)

	left.add_child(UI.spacer(4))
	left.add_child(UI.label("Choose a difficulty", 24, UI.INK, UI.font_serif))
	for d in GameState.DIFFICULTIES:
		left.add_child(_difficulty_row(d))

	# Right column — example board
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	h.add_child(right)
	var ehead := HBoxContainer.new()
	var el := UI.label("EXAMPLE", 12, UI.INK_FAINT, UI.font_sans_bold)
	el.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	el.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ehead.add_child(el)
	var sol_btn := UI.button("Show solution", "")
	sol_btn.add_theme_font_size_override("font_size", 13)
	ehead.add_child(sol_btn)
	right.add_child(ehead)
	var board := Board.new()
	board.interactive = false
	board.align_top = true
	board.custom_minimum_size = Vector2(440, 440)
	right.add_child(board)
	var example := GameState.pack_puzzles(vid, "easy")
	var pz: Puzzle
	if not example.is_empty():
		pz = Puzzle.from_dict(example[0])
	else:
		pz = Generator.make(vid, "easy", 7)
	if pz:
		var es := Session.new(pz)
		board.set_session(es)
		sol_btn.pressed.connect(func():
			var show := sol_btn.text == "Show solution"
			for c in pz.cell_count():
				if not es.is_given(c):
					es.values[c] = pz.solution[c] if show else 0
			sol_btn.text = "Hide solution" if show else "Show solution"
			board.queue_redraw())
	else:
		sol_btn.visible = false


func _difficulty_row(d: String) -> Control:
	var slot := "%s:%s" % [vid, d]
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 16))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var dot := Control.new()
	dot.custom_minimum_size = Vector2(12 * GameState.DIFFICULTIES.size(), 22)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var level: int = GameState.DIFFICULTIES.find(d) + 1
	var locked := not GameState.level_unlocked(vid, d)
	if locked:
		p.modulate.a = 0.75
	dot.draw.connect(func():
		for i in GameState.DIFFICULTIES.size():
			dot.draw_circle(Vector2(6 + i * 12, 11), 4.5, (UI.INK_FAINT if locked else UI.ACCENT) if i < level else UI.LINE_STRONG, true, -1.0, true))
	h.add_child(dot)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	v.add_child(UI.label(d.capitalize(), 18, UI.INK_MUTED if locked else UI.INK, UI.font_sans_bold))
	var best := float(GameState.variant_stats(vid).best.get(d, 0.0))
	var prog := GameState.pack_progress(vid, d)
	var meta := []
	meta.append("Best %s" % UI.format_time(best) if best > 0 else "No best time yet")
	if prog.y > 0:
		meta.append("%d/%d solved" % [prog.x, prog.y])
	if locked:
		meta = [GameState.unlock_hint(vid, d)]
	v.add_child(UI.label("  ·  ".join(meta), 14, UI.INK_MUTED))
	h.add_child(v)
	if locked and not GameState.has_game(slot):
		h.add_child(_lock_icon())
		return p

	if GameState.has_game(slot):
		var cont := UI.button("Continue", "PrimaryButton", func(): GameState.go("game", {"slot": slot}))
		cont.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(cont)
	var gen := UI.button("New puzzle", "" if GameState.has_game(slot) else "PrimaryButton",
		func(): GameState.go("game", GameState.new_game_params(vid, d)))
	gen.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(gen)
	return p


## Padlock drawn in the UI's line style.
static func _lock_icon() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(40, 40)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.tooltip_text = "Locked"
	c.draw.connect(func():
		var m := c.size / 2.0
		var col := UI.INK_FAINT
		c.draw_rect(Rect2(m + Vector2(-9, -2), Vector2(18, 13)), col, false, 2.0, true)
		c.draw_arc(m + Vector2(0, -2), 6.0, PI, TAU, 16, col, 2.0, true)
		c.draw_line(m + Vector2(-6, -2), m + Vector2(-6, -3), col, 2.0)
		c.draw_line(m + Vector2(6, -2), m + Vector2(6, -3), col, 2.0)
		c.draw_circle(m + Vector2(0, 4.5), 1.8, col))
	return c
