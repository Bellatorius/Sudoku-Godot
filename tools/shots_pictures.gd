extends Node
## Dev helper: picture puzzles mid draw-in and with a highlighted line → user://shots/pic_*.png

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	for v in ["thermo", "german_whispers", "renban", "between", "mini_region_sum"]:
		var pz := Generator.make(v, "medium", 31)
		GameState.go("game", {"slot": "shot:" + v, "pack": pz.to_dict()})
		await _wait(22)
		await _shot("pic_intro_" + v)
		await _wait(150)
		var gs = main.current
		var b = gs.board
		var cells: Array = pz.thermos[0] if not pz.thermos.is_empty() else pz.lines[0].cells
		b._hover = cells[1]
		b.queue_redraw()
		await _wait(3)
		await _shot("pic_hover_" + v)
		GameState.clear_game("shot:" + v)
	get_tree().quit()


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % name)
	print("shot ", name)
