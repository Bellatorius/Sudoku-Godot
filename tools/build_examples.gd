extends SceneTree
## Writes res://puzzles/examples.json: one easy puzzle per variant for the rules' solved example
## (so the example opens instantly, even for variants whose packs aren't built yet).
##   godot --headless -s tools/build_examples.gd

func _init() -> void:
	var out := {}
	for v in Variants.CORE:
		var pz: Puzzle = null
		var path := "res://puzzles/%s.json" % v
		if FileAccess.file_exists(path):
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			for d in data.get("puzzles", []):
				if d.get("difficulty", "") == "easy":
					pz = Puzzle.from_dict(d)
					break
		if pz == null:
			pz = Generator.make(v, "easy", 7)
		pz.id = "example-" + v
		out[v] = pz.to_dict()
		print(v)
	var lines := PackedStringArray()
	for v in out:
		lines.append('"%s": %s' % [v, JSON.stringify(out[v], "", false)])
	var f := FileAccess.open("res://puzzles/examples.json", FileAccess.WRITE)
	f.store_string("{\n%s\n}\n" % ",\n".join(lines))
	quit()
