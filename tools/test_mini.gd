extends SceneTree
## Dev check: builds Mini (6x6) puzzles for the given rules and levels and reports time / uniqueness.
##   godot --headless -s tools/test_mini.gd -- killer thermo …   (no rules = all of Variants.MINI)

func _init() -> void:
	var rules: Array = OS.get_cmdline_user_args()
	if rules.is_empty():
		rules = Variants.MINI
	for r in rules:
		var line := "%-16s" % r
		for d in ["easy", "medium", "hard"]:
			var t0 := Time.get_ticks_msec()
			var ok := 0
			var givens := 0
			for k in 3:
				var pz := Generator.make("mini_" + r, d, 1000 + k)
				if pz and Solver.new(pz).count_solutions(pz.givens, 2, 0) == 1:
					ok += 1
					givens += pz.given_count()
			line += "  %s %d/3 g%.0f %.1fs" % [d.substr(0, 1), ok, givens / maxf(ok, 1), (Time.get_ticks_msec() - t0) / 3000.0]
		print(line)
	quit()
