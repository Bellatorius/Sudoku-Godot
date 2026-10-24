extends SceneTree
## Makes the given digits go down level by level (beginner > easy > medium > hard > expert > master, by the
## pack average) and makes every master puzzle minimal: no single given can be removed while the solution
## stays unique (best of several removal orders; a true minimum would need an exhaustive search).
##
##   pool <variant> <keep>   hard + expert + master become `keep` puzzles each: the first 3*keep of each level
##                           are trimmed, sorted by their minimal given count, and dealt fewest -> master,
##                           next -> expert (half of the removable givens taken out), rest -> hard (as built,
##                           trimmed below the medium average if needed). Digits from the solution are added
##                           back where a level would otherwise not stay above the next one.
##   trim <variant>          keeps every puzzle; only the master puzzles are trimmed to minimal.
##   report <variant>...     average givens per level and whether the order holds.
##   Optional, after the variant: <orders> <nodes> for slow solvers (e.g. pool sandwich 20 1 6000).
##
##   godot --headless --path . -s tools/level_order.gd -- pool killer 20

const LEVELS := ["beginner", "easy", "medium", "hard", "expert", "master"]
static var ORDERS := 3        # removal orders tried for master puzzles; the fewest givens wins
static var NODES := 20000     # uniqueness budget per check; an aborted check keeps the given


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	match args[0] if args.size() > 0 else "":
		"pool":
			if args.size() >= 5:
				ORDERS = int(args[3]); NODES = int(args[4])
			_pool(args[1], int(args[2]))
		"trim":
			if args.size() >= 4:
				ORDERS = int(args[2]); NODES = int(args[3])
			_trim(args[1])
		"report":
			for v in args.slice(1):
				print(_report(v, _load(v)))
	quit()


func _load(v: String) -> Array:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://puzzles/%s.json" % v))
	return data.get("puzzles", []) if data is Dictionary else []


func _save(v: String, list: Array) -> void:
	var lines := PackedStringArray()
	for p in list:
		lines.append(JSON.stringify(p, "", false))
	var f := FileAccess.open("res://puzzles/%s.json" % v, FileAccess.WRITE)
	f.store_string('{"variant": "%s", "version": 1, "puzzles": [\n%s\n]}\n' % [v, ",\n".join(lines)])


static func _count(givens: String) -> int:
	var n := 0
	for ch in givens:
		if ch != "0":
			n += 1
	return n


static func _avg(list: Array, level: String) -> float:
	var s := 0.0
	var n := 0
	for p in list:
		if p.get("difficulty", "") == level:
			s += _count(str(p.givens))
			n += 1
	return s / n if n > 0 else -1.0


## "variant: b 37.6 > e 29.7 > … OK" (or the levels that break the order)
static func _report(v: String, list: Array) -> String:
	var parts := PackedStringArray()
	var bad := PackedStringArray()
	var prev := -1.0
	var prev_l := ""
	for l in LEVELS:
		var a := _avg(list, l)
		if a < 0:
			continue
		parts.append("%s %.1f" % [l.left(2), a])
		if prev >= 0 and not a < prev:
			bad.append("%s>=%s" % [l, prev_l])
		prev = a
		prev_l = l
	return "ORDER %s: %s  %s" % [v, " ".join(parts), "OK" if bad.is_empty() else "BAD " + ",".join(bad)]


## Removes givens one at a time in a seeded random order while the solution stays unique.
## Returns the cells it removed, in order (so some can be put back).
static func _strip(pz: Puzzle, solver: Solver, g: PackedInt32Array, seed_value: int) -> Array:
	var cells: Array = []
	for c in g.size():
		if g[c] != 0:
			cells.append(c)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = cells[i]; cells[i] = cells[j]; cells[j] = t
	var removed: Array = []
	for c in cells:
		var keep := g[c]
		g[c] = 0
		if solver.count_solutions(g, 2, NODES) == 1:
			removed.append(c)
		else:
			g[c] = keep
	return removed


static func _to_str(g: PackedInt32Array) -> String:
	var s := ""
	for x in g:
		s += str(x)
	return s


## Master: the fewest givens over ORDERS removal orders.
static func _minimal(p: Dictionary) -> String:
	var pz := Puzzle.from_dict(p)
	var solver := Solver.new(pz)
	var best := str(p.givens)
	for k in ORDERS:
		var g := pz.givens.duplicate()
		_strip(pz, solver, g, hash(str(p.id)) + k)
		var s := _to_str(g)
		if _count(s) < _count(best):
			best = s
	return best


## Puts back digits from the solution (cells with no given, in a fixed order) until the puzzle has `n` givens.
static func _add_back(p: Dictionary, n: int) -> void:
	var g := str(p.givens)
	var sol := str(p.solution)
	var cells: Array = []
	for c in g.length():
		if g[c] == "0":
			cells.append(c)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(p.id) + "+")
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = cells[i]; cells[i] = cells[j]; cells[j] = t
	var i := 0
	while _count(g) < n and i < cells.size():
		var c: int = cells[i]
		g = g.left(c) + sol[c] + g.substr(c + 1)
		i += 1
	p.givens = g


## Lifts a level's average above `floor_avg` by putting digits back, one puzzle at a time.
static func _lift(list: Array, floor_avg: float) -> void:
	var guard := 0
	while not list.is_empty() and _avg_of(list) <= floor_avg and guard < 2000:
		var p: Dictionary = list[guard % list.size()]
		_add_back(p, _count(str(p.givens)) + 1)
		guard += 1


static func _avg_of(list: Array) -> float:
	var s := 0.0
	for p in list:
		s += _count(str(p.givens))
	return s / maxi(1, list.size())


func _pool(v: String, keep: int) -> void:
	var all := _load(v)
	var others: Array = all.filter(func(p): return not p.difficulty in ["hard", "expert", "master"])
	var cand: Array = []
	for l in ["master", "expert", "hard"]:
		cand += all.filter(func(p): return p.difficulty == l).slice(0, 3 * keep)
	# trim every candidate once (one order) to learn its minimal given count
	var info: Array = []   # [minimal count, level rank, puzzle, removed cells]
	var rank := {"master": 0, "expert": 1, "hard": 2}
	for p in cand:
		var pz := Puzzle.from_dict(p)
		var g := pz.givens.duplicate()
		var removed := _strip(pz, Solver.new(pz), g, hash(str(p.id)))
		info.append([_count(str(p.givens)) - removed.size(), rank[p.difficulty], p, removed])
	info.sort_custom(func(a, b): return a[0] < b[0] if a[0] != b[0] else a[1] < b[1])
	var out := {"master": [], "expert": [], "hard": []}
	for i in mini(info.size(), 3 * keep):
		var level: String = "master" if i < keep else ("expert" if i < 2 * keep else "hard")
		var p: Dictionary = info[i][2].duplicate(true)
		var removed: Array = info[i][3]
		if level == "master":
			p.givens = _minimal(p)
		elif level == "expert":
			# take out half of the removable givens: between hard (as built) and master (minimal)
			var pz := Puzzle.from_dict(p)
			var g := pz.givens.duplicate()
			for c in removed.slice(0, (removed.size() + 1) / 2):
				g[c] = 0
			p.givens = _to_str(g)
		if p.difficulty != level:
			p.id = "pack-%s-%s-p%03d" % [v, level, out[level].size() + 1]
		p.difficulty = level
		out[level].append(p)
	# hard below medium: take out removable givens until under the medium average
	var med := _avg(others, "medium")
	if med >= 0 and _avg_of(out.hard) >= med:
		for i in out.hard.size():
			var p: Dictionary = out.hard[i]
			var pz := Puzzle.from_dict(p)
			var g := pz.givens.duplicate()
			var removed := _strip(pz, Solver.new(pz), g, hash(str(p.id)))
			var cap := int(floor(med)) - 1
			var cur := _count(str(p.givens))
			var take := clampi(cur - cap, 0, removed.size())
			var g2 := pz.givens.duplicate()
			for c in removed.slice(0, take):
				g2[c] = 0
			p.givens = _to_str(g2)
	# strictly descending: put digits back where a level isn't above the next one
	_lift(out.expert, _avg_of(out.master))
	_lift(out.hard, _avg_of(out.expert))
	# every step kept a proven-unique state; this re-check only catches a bug (2 = a second solution found)
	for p in out.hard + out.expert + out.master:
		var pz := Puzzle.from_dict(p)
		if Solver.new(pz).count_solutions(pz.givens, 2, NODES * 10) == 2:
			push_error("not unique after trimming: " + str(p.id))
			return
	var list: Array = others + out.hard + out.expert + out.master
	_save(v, list)
	print(_report(v, list))


func _trim(v: String) -> void:
	var all := _load(v)
	var t0 := Time.get_ticks_msec()
	for p in all:
		if p.difficulty == "master":
			p.givens = _minimal(p)
	_save(v, all)
	print(_report(v, all), "  (%ds)" % ((Time.get_ticks_msec() - t0) / 1000))
