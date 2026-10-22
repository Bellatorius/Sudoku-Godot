extends SceneTree
## Dev check: picture puzzles (Generator.PICTURE) per variant: success, time, givens, picture names.
##   godot --headless -s tools/test_pictures.gd -- thermo mini_renban …   (no args = all, 9x9 and Mini)

func _init() -> void:
	var ids: Array = OS.get_cmdline_user_args()
	if ids.is_empty():
		for v in Generator.PICTURE:
			ids.append(v)
			if v in Variants.MINI:
				ids.append("mini_" + v)
	for v in ids:
		var line := "%-22s" % v
		for d in ["easy", "hard"]:
			var t0 := Time.get_ticks_msec()
			var ok := 0
			var g := 0
			var names: Array = []
			for k in 3:
				var pz := Generator.make(v, d, 777 + k)
				if pz and Solver.new(pz).count_solutions(pz.givens, 2, 0) == 1:
					ok += 1
					g += pz.given_count()
					names.append(pz.title)
			line += "  %s %d/3 g%.0f %.1fs %s" % [d.substr(0, 1), ok, g / maxf(ok, 1), (Time.get_ticks_msec() - t0) / 3000.0, ",".join(PackedStringArray(names))]
		print(line)
	quit()
