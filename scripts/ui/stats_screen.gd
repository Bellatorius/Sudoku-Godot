extends Control
## Player statistics: totals, daily streak and per-variant best times.


func setup(_params: Dictionary) -> void:
	var parts := UI.page(1000, 44)
	add_child(parts[0])
	var col: VBoxContainer = parts[1]
	col.add_child(UI.heading("Your Stats", 46))
	var st := GameState.stats

	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 14)
	var played := 0
	for id in Variants.CORE:
		if int(GameState.variant_stats(id).solved) > 0:
			played += 1
	for t in [["Puzzles solved", str(int(st.total_solved))],
			["Daily streak", str(GameState.current_streak())],
			["Best streak", str(int(st.daily.best_streak))],
			["Variants mastered", "%d / %d" % [played, Variants.CORE.size()]],
			["1v1 wins / losses", "%d / %d" % [int(st.get("multiplayer", {}).get("wins", 0)), int(st.get("multiplayer", {}).get("losses", 0))]]]:
		tiles.add_child(_tile(t[0], t[1]))
	col.add_child(tiles)
	col.add_child(UI.spacer(10))
	col.add_child(UI.label("Best times", 24, UI.INK, UI.font_serif))

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
	for id in Variants.CORE:
		var vs := GameState.variant_stats(id)
		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 10)
		name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_row.add_child(VariantIcon.new(id, 22))
		name_row.add_child(UI.label(Variants.display_name(id), 16, UI.INK, UI.font_sans_medium))
		grid.add_child(name_row)
		grid.add_child(UI.label(str(int(vs.solved)), 16))
		for d in GameState.DIFFICULTIES:
			var b := float(vs.best.get(d, 0.0))
			grid.add_child(UI.label(UI.format_time(b) if b > 0 else "—", 16, UI.INK if b > 0 else UI.INK_FAINT))
	col.add_child(table)

	col.add_child(UI.spacer(10))
	col.add_child(UI.label("Achievements", 24, UI.INK, UI.font_serif))
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


func _tile(title: String, value: String) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, UI.LINE_STRONG, UI.RADIUS, 1, 20))
	var v := VBoxContainer.new()
	v.add_child(UI.label(title.to_upper(), 12, UI.INK_FAINT, UI.font_sans_bold))
	v.add_child(UI.label(value, 36, UI.INK, UI.font_serif))
	p.add_child(v)
	return p
