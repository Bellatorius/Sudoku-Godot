extends Node
## Dev helper: renders each screen to user://shots/*.png  (run with a display; not part of the game)

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	await _wait(20)
	await _shot("01_home")
	GameState.go("variant", {"id": "killer"})
	await _wait(20)
	await _shot("02_variant_killer")
	for v in Variants.CORE:
		var d: Dictionary = GameState.pack_puzzles(v, "medium")[0]
		GameState.go("game", {"slot": "shot:" + v, "pack": d})
		await _wait(15)
		var gs = main.current
		var s: Session = gs.session
		# play a few moves so digits, notes and selection show
		var empties: Array = []
		for c in 81:
			if s.values[c] == 0: empties.append(c)
		s.input_digit([empties[0]], s.puzzle.solution[empties[0]], "normal")
		for dd in range(1, 10):
			s.input_digit([empties[1]], dd, "corner")
			s.input_digit([empties[2]], dd, "center")
		s.input_digit([empties[3]], 3, "corner"); s.input_digit([empties[3]], 8, "corner")
		s.input_digit([empties[5], empties[6], empties[7]], 4, "color")
		s.input_digit([empties[7], empties[8]], 7, "color")
		s.input_digit([20, 21, 29], 2, "color")
		gs._set_mode("color")
		gs.board.selected = [empties[0]]
		gs.board.queue_redraw()
		await _wait(5)
		await _shot("03_game_" + v)
		GameState.clear_game("shot:" + v)
	# daily (threaded generation)
	GameState.go("game", {"daily": GameState.today()})
	await _wait(3)
	await _shot("07_generating")
	var dg = main.current
	var n := 0
	while dg.session == null and n < 2000:
		await _wait(1); n += 1
	print("daily generated after frames: ", n)
	dg.session.hint(-1)
	dg.session.hint(-1)
	await _wait(5)
	await _shot("08_daily")
	# leave + resume
	GameState.go("home")
	await _wait(5)
	print("daily saved: ", GameState.has_game("daily:" + GameState.today()))
	GameState.go("game", {"daily": GameState.today()})
	await _wait(5)
	print("resumed hints: ", main.current.session.hints_used)
	GameState.go("home")
	await _wait(10)
	await _shot("01_home_after")
	GameState.go("stats")
	await _wait(15)
	await _shot("04_stats")
	GameState.go("settings")
	await _wait(15)
	await _shot("05_settings")
	# solve flow
	GameState.go("game", {"slot": "shot:win", "pack": GameState.pack_puzzles("classic", "easy")[0]})
	await _wait(10)
	var g2 = main.current
	var s2: Session = g2.session
	var last := -1
	for c in 81:
		if s2.values[c] == 0:
			last = c
	for c in 81:
		if s2.values[c] == 0 and c != last:
			s2.values[c] = s2.puzzle.solution[c]
	s2.input_digit([last], s2.puzzle.solution[last], "normal")
	await _wait(120)
	await _shot("06_solved")
	get_tree().quit()

func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % name)
	print("shot ", name)
