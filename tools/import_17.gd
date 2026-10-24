extends SceneTree
## Replaces the Classic master pack with 17-given puzzles (17 is the proven minimum for classic Sudoku).
## Source: Gordon Royle's list of 49,158 17-clue puzzles (University of Western Australia), completed by
## the Enjoy Sudoku Players Forum; file and Sudoku Explainer ratings from github.com/denis-berthier/Sudoku-classif
## (Royle-49158-17c/puzzles.txt + SER.txt). Credited in Settings → About.
##
## Input: a text file of "<SER rating> <81 digits, 0 = empty>" lines (the hardest ones, picked beforehand).
##   godot --headless --path . -s tools/import_17.gd -- <file> [count]
## Each puzzle is solved and checked for a unique solution with our own solver before it goes in.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var count := int(args[1]) if args.size() > 1 else 500
	var lines := FileAccess.get_file_as_string(args[0]).split("\n", false)
	var out: Array = []
	for line in lines:
		if out.size() >= count:
			break
		var parts := line.strip_edges().split(" ", false)
		var d := {"id": "", "variant": "classic", "difficulty": "master", "givens": parts[1], "solution": ""}
		var pz := Puzzle.from_dict(d)
		var solver := Solver.new(pz)
		if solver.count_solutions(pz.givens, 2, 0) != 1:
			push_error("not unique: " + parts[1])
			continue
		d.solution = Puzzle._arr_to_str(solver.solve(pz.givens))
		d.id = "pack-classic-master-r17-%03d" % (out.size() + 1)
		out.append(d)
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://puzzles/classic.json"))
	var list: Array = data.puzzles.filter(func(p): return p.difficulty != "master")
	list += out
	var rows := PackedStringArray()
	for p in list:
		rows.append(JSON.stringify(p, "", false))
	var f := FileAccess.open("res://puzzles/classic.json", FileAccess.WRITE)
	f.store_string('{"variant": "classic", "version": 1, "puzzles": [\n%s\n]}\n' % ",\n".join(rows))
	print("IMPORT classic master: %d puzzles with 17 givens" % out.size())
	quit()
