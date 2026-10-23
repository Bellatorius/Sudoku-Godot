extends Node
## Dev helper: nav bar + home title in light / dark and at the narrowest window -> user://shots/nav_*.png

func _ready() -> void:
	var was_dark: bool = UI.dark
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	for dark in [false, true]:
		UI.set_dark(dark)
		await _wait(20)
		await _shot("nav_home_" + ("dark" if dark else "light"))
	UI.set_dark(false)
	# the tab pill must not move between screens with and without the Continue chip
	var xs := []
	for scr in ["home", "game", "stats"]:
		if scr == "game":
			var d: Dictionary = GameState.pack_puzzles("classic", "easy")[0]
			GameState.go("game", {"slot": "shot:nav", "pack": d})
		else:
			GameState.go(scr)
		await _wait(10)
		xs.append([scr, main._nav_pill.global_position.x, main.continue_btn.visible])
	GameState.clear_game("shot:nav")
	print("PILL_X ", xs)
	GameState.go("stats")
	await _wait(10)
	await _shot("nav_stats_light")
	get_window().size = Vector2i(960, 640)
	await _wait(20)
	await _shot("nav_narrow")
	UI.set_dark(was_dark)
	get_tree().quit()


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % name)
