extends SceneTree
## Measures the expert / master grade bars for variants that aren't in Generator.GRADE yet, from their
## Hard puzzles (pack, or puzzles/_parts/<v>_hard.json while building), and writes res://puzzles/grades.json.
##   godot --headless -s tools/build_grades.gd -- <variant> <variant> …

func _init() -> void:
	var out := {}
	if FileAccess.file_exists("res://puzzles/grades.json"):
		out = JSON.parse_string(FileAccess.get_file_as_string("res://puzzles/grades.json"))
	for v in OS.get_cmdline_user_args():
		var hard: Array = []
		var part := "res://puzzles/_parts/%s_hard.json" % v
		if FileAccess.file_exists(part):
			hard = JSON.parse_string(FileAccess.get_file_as_string(part))
		elif FileAccess.file_exists("res://puzzles/%s.json" % v):
			var data = JSON.parse_string(FileAccess.get_file_as_string("res://puzzles/%s.json" % v))
			hard = data.puzzles.filter(func(p): return p.difficulty == "hard")
		if hard.is_empty():
			print(v, ": no hard puzzles")
			continue
		var scores: Array = []
		for k in mini(60, hard.size()):
			scores.append(Generator.grade(Puzzle.from_dict(hard[k * hard.size() / mini(60, hard.size())])))
		scores.sort()
		out[v] = [snappedf(scores[scores.size() / 2], 0.01), snappedf(scores[scores.size() * 3 / 4], 0.01)]
		print(v, ": ", out[v])
	var f := FileAccess.open("res://puzzles/grades.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t"))
	quit()
