extends Node
## Dev helper: renders the Mini (6x6) screens to user://shots/mini_*.png (run with a display).

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	load("res://scripts/ui/home_screen.gd")._group = "mini"
	GameState.go("home")
	await _wait(20)
	await _shot("mini_home")
	for v in ["killer", "sandwich", "kenken", "thermo", "jigsaw", "kropki", "little_killer", "region_sum"]:
		var pz := Generator.make("mini_" + v, "medium", 5)
		GameState.go("game", {"slot": "shot:mini_" + v, "pack": pz.to_dict()})
		await _wait(15)
		var gs = main.current
		var s: Session = gs.session
		var empties: Array = []
		for c in s.values.size():
			if s.values[c] == 0: empties.append(c)
		s.input_digit([empties[0]], s.puzzle.solution[empties[0]], "normal")
		for dd in range(1, 7):
			s.input_digit([empties[1]], dd, "corner")
			s.input_digit([empties[2]], dd, "center")
		gs.board.selected = [empties[0]]
		gs.board.queue_redraw()
		await _wait(5)
		await _shot("mini_game_" + v)
		GameState.clear_game("shot:mini_" + v)
	GameState.go("variant", {"id": "mini_killer"})
	await _wait(20)
	await _shot("mini_variant_killer")
	get_tree().quit()


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % name)
	print("shot ", name)
