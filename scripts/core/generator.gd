class_name Generator
extends RefCounted
## Builds unique-solution puzzles for every core variant from a seed.
## Deterministic for a given (variant, difficulty, seed) — used for daily puzzles.

# Target number of givens. 0 = remove as many as possible while staying unique.
# Levels: beginner, easy, medium, hard, expert, master. Expert and master keep minimal givens like hard,
# use fewer variant clues (CLUE_TIER) and only accept puzzles whose solver effort (grade()) reaches GRADE.
const TARGETS := {
	"classic":  {"beginner": 46, "easy": 38, "medium": 30, "hard": 0, "expert": 0, "master": 0},
	"diagonal": {"beginner": 42, "easy": 34, "medium": 27, "hard": 0, "expert": 0, "master": 0},
	"jigsaw":   {"beginner": 44, "easy": 36, "medium": 29, "hard": 0, "expert": 0, "master": 0},
	"killer":   {"beginner": 30, "easy": 22, "medium": 10, "hard": 0, "expert": 0, "master": 0},
	"thermo":   {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"arrow":    {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"kropki":   {"beginner": 32, "easy": 24, "medium": 14, "hard": 0, "expert": 0, "master": 0},
	"xv":       {"beginner": 34, "easy": 26, "medium": 16, "hard": 0, "expert": 0, "master": 0},
	"non_consecutive": {"beginner": 36, "easy": 28, "medium": 18, "hard": 0, "expert": 0, "master": 0},
	"king":     {"beginner": 40, "easy": 32, "medium": 24, "hard": 0, "expert": 0, "master": 0},
	"knight":   {"beginner": 40, "easy": 32, "medium": 24, "hard": 0, "expert": 0, "master": 0},
	"even_odd": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"german_whispers": {"beginner": 38, "easy": 30, "medium": 20, "hard": 0, "expert": 0, "master": 0},
	"renban":   {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"sandwich": {"beginner": 34, "easy": 26, "medium": 16, "hard": 0, "expert": 0, "master": 0},
	"skyscraper": {"beginner": 32, "easy": 24, "medium": 14, "hard": 0, "expert": 0, "master": 0},
	"xsum":     {"beginner": 34, "easy": 26, "medium": 16, "hard": 0, "expert": 0, "master": 0},
	"ascending": {"beginner": 38, "easy": 30, "medium": 22, "hard": 20, "expert": 20, "master": 20},
	"running":  {"beginner": 38, "easy": 30, "medium": 22, "hard": 20, "expert": 20, "master": 20},
	"little_killer": {"beginner": 34, "easy": 26, "medium": 18, "hard": 0, "expert": 0, "master": 0},
	"palindrome": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"between":  {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"lockout":  {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"consecutive": {"beginner": 32, "easy": 24, "medium": 14, "hard": 0, "expert": 0, "master": 0},
	"greater_than": {"beginner": 34, "easy": 26, "medium": 16, "hard": 0, "expert": 0, "master": 0},
	"dutch_whispers": {"beginner": 38, "easy": 30, "medium": 20, "hard": 0, "expert": 0, "master": 0},
	"slow_thermo": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"quadruple": {"beginner": 36, "easy": 28, "medium": 20, "hard": 0, "expert": 0, "master": 0},
	"universal": {"beginner": 40, "easy": 32, "medium": 26, "hard": 0, "expert": 0, "master": 0},
	"windoku":  {"beginner": 40, "easy": 32, "medium": 26, "hard": 0, "expert": 0, "master": 0},
	"twisted":  {"beginner": 36, "easy": 28, "medium": 18, "hard": 0, "expert": 0, "master": 0},
	"bishop":   {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"axia":     {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"couples":  {"beginner": 36, "easy": 28, "medium": 20, "hard": 0, "expert": 0, "master": 0},
	"dutch_flatmates": {"beginner": 40, "easy": 32, "medium": 26, "hard": 0, "expert": 0, "master": 0},
	"friendly": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"index":    {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"pulse":    {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"reflection": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"slingshot": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"vertex":   {"beginner": 36, "easy": 28, "medium": 20, "hard": 0, "expert": 0, "master": 0},
	"zipper":   {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
}
const LEVELS := ["beginner", "easy", "medium", "hard", "expert", "master"]
## How many lines / cages / dots / outside clues a level gets: beginner like easy, expert and master like medium
## (fewer clues than hard, which makes the minimal-givens puzzle need deeper reasoning).
const CLUE_TIER := {"beginner": "easy", "easy": "easy", "medium": "medium", "hard": "hard", "expert": "medium", "master": "medium"}
## Minimum grade() per variant for expert / master: the median and top-quarter grade of that variant's Hard pack.
const GRADE := {
	"classic": [2.86, 7.39],
	"killer": [40.39, 55.28],
	"thermo": [26.72, 58.23],
	"arrow": [52.15, 71.68],
	"jigsaw": [65.65, 79.56],
	"diagonal": [39.16, 66.32],
	"kropki": [5.14, 16.23],
	"xv": [32.0, 51.86],
	"non_consecutive": [50.88, 62.88],
	"king": [44.6, 60.9],
	"knight": [65.88, 81.52],
	"even_odd": [5.66, 17.02],
	"german_whispers": [48.71, 65.4],
	"renban": [47.68, 71.65],
	"sandwich": [63.25, 79.97],
	"skyscraper": [58.81, 71.88],
	"little_killer": [53.22, 68.72],
	"palindrome": [39.21, 58.49],
	"between": [55.76, 77.48],
	"consecutive": [30.88, 51.04],
	"greater_than": [51.19, 74.76],
	"dutch_whispers": [47.6, 70.35],
	"slow_thermo": [55.35, 72.15],
	"quadruple": [21.46, 48.73],
	"universal": [5.84, 14.84],
	"windoku": [46.63, 65.05],
	"xsum": [54.66, 69.42],
	"zipper": [55.13, 71.03],
	"lockout": [55.74, 75.82],
	"twisted": [57.13, 70.19],
	"bishop": [37.02, 68.55],
	"ascending": [25.55, 29.77],
	"axia": [32.25, 53.42],
	"couples": [10.01, 35.61],
	"dutch_flatmates": [36.29, 64.37],
	"friendly": [4.23, 10.05],
	"index": [15.02, 36.61],
	"pulse": [15.48, 32.66],
	"reflection": [33.77, 64.06],
	"running": [29.18, 55.52],
	"slingshot": [53.86, 76.75],
	"vertex": [53.29, 74.65],
}
## Expert / master: how many graded candidates make() tries before settling for the toughest one.
const GRADE_TRIES := 40
const NODE_LIMIT := 6000
## Smaller uniqueness budget where every search node is expensive (whole-row clue checks).
const REDUCE_NODES := {"ascending": 2000}
## Search budget for building the full solution grid, and how many tries make() gets.
## Non-consecutive solutions are hard to find by random search and the time is heavy-tailed,
## so it gets many short tries instead of a few long ones.
const SOLVE_NODES := {"non_consecutive": 40000, "twisted": 40000}
const ATTEMPTS := {"non_consecutive": 40, "twisted": 40}

var rng := RandomNumberGenerator.new()
var _budget := 0


static func make(variant: String, difficulty: String, seed_value: int) -> Puzzle:
	var g := Generator.new()
	g.rng.seed = seed_value
	var need := 0.0
	if difficulty == "expert" or difficulty == "master":
		need = float(GRADE.get(variant, [0.0, 0.0])[0 if difficulty == "expert" else 1])
	var best: Puzzle = null
	var best_grade := -1.0
	for t in (GRADE_TRIES if need > 0.0 else 1):
		var pz: Puzzle = null
		for attempt in int(ATTEMPTS.get(variant, 8)):
			pz = g._attempt(variant, difficulty)
			if pz:
				break
		if pz == null:
			continue
		var gr := grade(pz) if need > 0.0 else 0.0
		if gr > best_grade:
			best = pz
			best_grade = gr
		if gr >= need:
			break
	if best:
		best.id = "%s-%s-%d" % [variant, difficulty.substr(0, 2), seed_value]
	return best


## Solver effort to prove the puzzle has one solution, per empty cell: about 1 when plain deduction
## finishes it, higher when the solver has to try things out. Used to sort expert / master puzzles.
static func grade(pz: Puzzle) -> float:
	var s := Solver.new(pz)
	s.count_solutions(pz.givens, 2, 0)
	return float(s.last_nodes()) / float(pz.givens.count(0) + 1)


func _attempt(variant: String, difficulty: String) -> Puzzle:
	var pz := Puzzle.new()
	pz.variant = variant
	pz.difficulty = difficulty
	pz.diagonals = variant == "diagonal"
	if variant == "jigsaw":
		pz.regions = _jigsaw_regions()
	var empty := PackedInt32Array()
	empty.resize(81)
	pz.twist_gen = variant == "twisted"
	var sol := Solver.new(pz).solve(empty, rng, int(SOLVE_NODES.get(variant, 20000)))
	pz.twist_gen = false
	if sol.size() != 81:
		return null
	pz.solution = sol
	var tier: String = CLUE_TIER.get(difficulty, difficulty)   # how many variant clues this level gets
	var e := tier == "easy"
	var m := tier == "medium"

	match variant:
		"killer": _make_cages(pz)
		"thermo": _make_thermos(pz, {"easy": 6, "medium": 7, "hard": 9}[tier])
		"arrow": _make_arrows(pz, {"easy": 6, "medium": 7, "hard": 9}[tier])
		"kropki": _make_edges(pz, true)
		"xv": _make_edges(pz, false)
		"even_odd": _make_parity(pz, {"easy": 24, "medium": 18, "hard": 14}[tier])
		"german_whispers": _make_lines(pz, "gw", {"easy": 6, "medium": 7, "hard": 9}[tier])
		"renban": _make_lines(pz, "rb", {"easy": 6, "medium": 7, "hard": 9}[tier])
		"sandwich": _make_outer(pz, "sw", ["L", "T"], 10 if e else (12 if m else 14))
		"skyscraper": _make_outer(pz, "sk", ["L", "R", "T", "B"], 12 if e else (14 if m else 18))
		"xsum": _make_outer(pz, "xs", ["L", "R", "T", "B"], 12 if e else (14 if m else 18))
		"ascending": _make_outer(pz, "as", ["L", "T"], 12 if e else (14 if m else 18))
		"running": _make_outer(pz, "rn", ["L", "T"], 12 if e else (14 if m else 18))
		"little_killer": _make_little_killer(pz, 8 if e else (10 if m else 12))
		"palindrome": _make_path_lines(pz, "pal", 5 if e else (6 if m else 8))
		"zipper": _make_path_lines(pz, "zp", 5 if e else (6 if m else 8))
		"between": _make_path_lines(pz, "bt", 6 if e else (7 if m else 9))
		"lockout": _make_path_lines(pz, "lo", 6 if e else (7 if m else 9))
		"dutch_whispers": _make_path_lines(pz, "dw", 6 if e else (7 if m else 9))
		"slow_thermo": _make_path_lines(pz, "st", 6 if e else (7 if m else 9))
		"bishop": _make_path_lines(pz, "bi", 6 if e else (7 if m else 9))
		"reflection": _make_reflection(pz, 3 if e else (4 if m else 5))
		"consecutive": _make_consecutive(pz)
		"greater_than": _make_relations(pz, true, 50 if e else (60 if m else 80))
		"couples": _make_relations(pz, false, 40 if e else (50 if m else 60))
		"quadruple": _make_quads(pz, 10 if e else (12 if m else 16))
		"twisted": _make_twists(pz)
		"axia", "friendly", "index", "pulse": _make_marks(pz, variant, 8 if e else (10 if m else 12))
		"slingshot": _make_slings(pz, 5 if e else (6 if m else 8))
		"vertex": _make_vertices(pz, 8 if e else (10 if m else 12))
	if variant == "pulse" and pz.marks.size() < 2:
		return null

	pz.givens = sol.duplicate()
	_reduce(pz, TARGETS.get(variant, TARGETS.classic)[difficulty], int(REDUCE_NODES.get(variant, NODE_LIMIT)))
	return pz


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]; a[i] = a[j]; a[j] = t


func _reduce(pz: Puzzle, target: int, nodes := NODE_LIMIT) -> void:
	var solver := Solver.new(pz)
	var cells: Array = []
	for i in 41:  # symmetric pairs (i, 80 - i)
		cells.append(i)
	_shuffle(cells)
	var count := 81
	for c in cells:
		if target > 0 and count <= target:
			break
		var o: int = 80 - c
		var sc := pz.givens[c]
		var so := pz.givens[o]
		pz.givens[c] = 0
		pz.givens[o] = 0
		if solver.count_solutions(pz.givens, 2, nodes) == 1:
			count -= 1 if c == o else 2
		else:
			pz.givens[c] = sc
			pz.givens[o] = so


# --------------------------------------------------------------- jigsaw

func _jigsaw_regions() -> PackedInt32Array:
	var reg := Puzzle.standard_regions()
	var swaps := 0
	var tries := 0
	while swaps < 120 and tries < 6000:
		tries += 1
		var a := rng.randi_range(0, 80)
		var nbs := _orth(a)
		var b: int = nbs[rng.randi_range(0, nbs.size() - 1)]
		var ra := reg[a]
		var rb := reg[b]
		if ra == rb:
			continue
		# a moves into rb; pick some cell x of rb adjacent to ra (not b) to move into ra
		var cand: Array = []
		for x in 81:
			if reg[x] == rb and x != b:
				for y in _orth(x):
					if reg[y] == ra and y != a:
						cand.append(x)
						break
		if cand.is_empty():
			continue
		var x: int = cand[rng.randi_range(0, cand.size() - 1)]
		reg[a] = rb
		reg[x] = ra
		if _connected(reg, ra) and _connected(reg, rb):
			swaps += 1
		else:
			reg[a] = ra
			reg[x] = rb
	return reg


func _orth(i: int) -> Array:
	var r := i / 9
	var c := i % 9
	var out: Array = []
	if r > 0: out.append(i - 9)
	if r < 8: out.append(i + 9)
	if c > 0: out.append(i - 1)
	if c < 8: out.append(i + 1)
	return out


func _connected(reg: PackedInt32Array, id: int) -> bool:
	var start := -1
	var total := 0
	for i in 81:
		if reg[i] == id:
			total += 1
			if start < 0: start = i
	if start < 0: return false
	var seen := {start: true}
	var stack := [start]
	while not stack.is_empty():
		var c: int = stack.pop_back()
		for n in _orth(c):
			if reg[n] == id and not seen.has(n):
				seen[n] = true
				stack.append(n)
	return seen.size() == total


# --------------------------------------------------------------- killer

func _make_cages(pz: Puzzle) -> void:
	var owner := PackedInt32Array()
	owner.resize(81)
	owner.fill(-1)
	var order: Array = range(81)
	_shuffle(order)
	var cages: Array = []
	var sizes := [2, 2, 3, 3, 3, 4, 4, 5]
	for start in order:
		if owner[start] >= 0:
			continue
		var cells: Array = [start]
		var digits := {pz.solution[start]: true}
		owner[start] = cages.size()
		var want: int = sizes[rng.randi_range(0, sizes.size() - 1)]
		while cells.size() < want:
			var opts: Array = []
			for c in cells:
				for n in _orth(c):
					if owner[n] == -1 and not digits.has(pz.solution[n]) and not opts.has(n):
						opts.append(n)
			if opts.is_empty():
				break
			var pick: int = opts[rng.randi_range(0, opts.size() - 1)]
			cells.append(pick)
			digits[pz.solution[pick]] = true
			owner[pick] = cages.size()
		cages.append(cells)
	# Merge singleton cages into a neighbour where possible.
	for ci in cages.size():
		var cells: Array = cages[ci]
		if cells.size() != 1:
			continue
		var c: int = cells[0]
		for n in _orth(c):
			var other: int = owner[n]
			if other == ci or cages[other].size() >= 5:
				continue
			var clash := false
			for oc in cages[other]:
				if pz.solution[oc] == pz.solution[c]:
					clash = true
			if not clash:
				cages[other].append(c)
				owner[c] = other
				cages[ci] = []
				break
	for cells in cages:
		if cells.is_empty():
			continue
		var s := 0
		for c in cells:
			s += pz.solution[c]
		cells.sort()
		pz.cages.append({"cells": cells, "sum": s})


# --------------------------------------------------------------- lines

func _nbrs8(i: int) -> Array:
	var r := i / 9
	var c := i % 9
	var out: Array = []
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if dr == 0 and dc == 0: continue
			var rr: int = r + dr
			var cc: int = c + dc
			if rr >= 0 and rr < 9 and cc >= 0 and cc < 9:
				out.append(rr * 9 + cc)
	return out


func _seg_key(a: int, b: int) -> String:
	return "%d-%d" % [mini(a, b), maxi(a, b)]


## A diagonal step a->b is blocked if it would cross an existing diagonal segment.
func _crosses(a: int, b: int, segs: Dictionary) -> bool:
	var ra := a / 9
	var ca := a % 9
	var rb := b / 9
	var cb := b % 9
	if ra == rb or ca == cb:
		return false
	return segs.has(_seg_key(ra * 9 + cb, rb * 9 + ca))


## True if the diagonal step a->b would cross step c->d.
func _cross_pair(a: int, b: int, c: int, d: int) -> bool:
	if a / 9 == b / 9 or a % 9 == b % 9:
		return false
	var x := (a / 9) * 9 + b % 9
	var y := (b / 9) * 9 + a % 9
	return (c == x and d == y) or (c == y and d == x)


## True if the line a->b->c turns back on itself (sharper than a right angle).
func _sharp(a: int, b: int, c: int) -> bool:
	return (b / 9 - a / 9) * (c / 9 - b / 9) + (b % 9 - a % 9) * (c % 9 - b % 9) < 0


## True if the diagonal step a->b would cross a step of the line itself.
func _crosses_path(a: int, b: int, path: Array) -> bool:
	for i in path.size() - 1:
		if _cross_pair(a, b, path[i], path[i + 1]):
			return true
	return false


func _add_segs(path: Array, segs: Dictionary) -> void:
	for i in path.size() - 1:
		segs[_seg_key(path[i], path[i + 1])] = true


func _make_thermos(pz: Puzzle, n: int) -> void:
	var used := {}
	var segs := {}
	var tries := 0
	while pz.thermos.size() < n and tries < 400:
		tries += 1
		var start := rng.randi_range(0, 80)
		if used.has(start) or pz.solution[start] > 5:
			continue
		var path: Array = [start]
		var want := rng.randi_range(3, 6)
		while path.size() < want:
			var cur: int = path[-1]
			var opts: Array = []
			for nb in _nbrs8(cur):
				if used.has(nb) or path.has(nb) or pz.solution[nb] <= pz.solution[cur]:
					continue
				if _crosses(cur, nb, segs):
					continue
				opts.append(nb)
			if opts.is_empty():
				break
			# Prefer small steps so thermos can grow longer.
			opts.sort_custom(func(x, y): return pz.solution[x] < pz.solution[y])
			var k := mini(opts.size(), 2)
			path.append(opts[rng.randi_range(0, k - 1)])
		if path.size() < 3:
			continue
		for c in path:
			used[c] = true
		_add_segs(path, segs)
		pz.thermos.append(path)


func _make_arrows(pz: Puzzle, n: int) -> void:
	var used := {}
	var segs := {}
	var tries := 0
	while pz.arrows.size() < n and tries < 400:
		tries += 1
		var circle := rng.randi_range(0, 80)
		var total: int = pz.solution[circle]
		if used.has(circle) or total < 3:
			continue
		var paths: Array = []
		_arrow_dfs(pz, [circle], 0, total, used, segs, paths)
		if paths.is_empty():
			continue
		var path: Array = paths[rng.randi_range(0, paths.size() - 1)]
		for c in path:
			used[c] = true
		_add_segs(path, segs)
		pz.arrows.append({"circle": path[0], "line": path.slice(1)})


func _arrow_dfs(pz: Puzzle, path: Array, s: int, total: int, used: Dictionary, segs: Dictionary, out: Array) -> void:
	if out.size() > 12:
		return
	var L := path.size() - 1
	if s == total and L >= 2:
		out.append(path.duplicate())
		return
	if L >= 4 or s >= total:
		return
	var cur: int = path[-1]
	var nbs := _nbrs8(cur)
	_shuffle(nbs)
	for nb in nbs:
		if used.has(nb) or path.has(nb) or _crosses(cur, nb, segs):
			continue
		var v: int = pz.solution[nb]
		if s + v > total:
			continue
		path.append(nb)
		_arrow_dfs(pz, path, s + v, total, used, segs, out)
		path.pop_back()


# --------------------------------------------------------------- dots / XV

func _make_edges(pz: Puzzle, kropki: bool) -> void:
	pz.negative = true
	for i in 81:
		for n in [i + 1, i + 9]:
			if n > 80 or (n == i + 1 and i % 9 == 8):
				continue
			var a: int = pz.solution[i]
			var b: int = pz.solution[n]
			var t := ""
			if kropki:
				var white := absi(a - b) == 1
				var black := a == 2 * b or b == 2 * a
				if white and black:
					t = "w" if rng.randf() < 0.5 else "b"
				elif white:
					t = "w"
				elif black:
					t = "b"
			else:
				if a + b == 10: t = "x"
				elif a + b == 5: t = "v"
			if t != "":
				pz.edges[Puzzle.edge_key(i, n)] = t


# --------------------------------------------------------------- even-odd

func _make_parity(pz: Puzzle, n: int) -> void:
	var cells: Array = range(81)
	_shuffle(cells)
	for i in mini(n, 81):
		var c: int = cells[i]
		pz.parity[c] = "e" if pz.solution[c] % 2 == 0 else "o"


# --------------------------------------------------------------- whispers / renban lines

func _make_lines(pz: Puzzle, t: String, n: int) -> void:
	var used := {}
	var segs := {}
	var tries := 0
	while pz.lines.size() < n and tries < 600:
		tries += 1
		var start := rng.randi_range(0, 80)
		if used.has(start):
			continue
		var path: Array = []
		if t == "gw":
			path = _whisper_path(pz, start, rng.randi_range(3, 7), used, segs)
		else:
			path = _renban_path(pz, start, rng.randi_range(3, 5), used, segs)
		if path.size() < 3:
			continue
		for c in path:
			used[c] = true
		_add_segs(path, segs)
		pz.lines.append({"t": t, "cells": path})


func _whisper_path(pz: Puzzle, start: int, want: int, used: Dictionary, segs: Dictionary) -> Array:
	if pz.solution[start] == 5:
		return []
	var path: Array = [start]
	while path.size() < want:
		var cur: int = path[-1]
		var opts: Array = []
		for nb in _nbrs8(cur):
			if used.has(nb) or path.has(nb) or _crosses(cur, nb, segs):
				continue
			if absi(pz.solution[nb] - pz.solution[cur]) >= 5:
				opts.append(nb)
		if opts.is_empty():
			break
		path.append(opts[rng.randi_range(0, opts.size() - 1)])
	return path


func _renban_path(pz: Puzzle, start: int, want: int, used: Dictionary, segs: Dictionary) -> Array:
	var out: Array = []
	_renban_dfs(pz, [start], want, used, segs, out)
	return out


func _renban_dfs(pz: Puzzle, path: Array, want: int, used: Dictionary, segs: Dictionary, out: Array) -> void:
	if not out.is_empty():
		return
	var lo := 10
	var hi := 0
	for c in path:
		lo = mini(lo, pz.solution[c])
		hi = maxi(hi, pz.solution[c])
	if hi - lo > want - 1:
		return
	if path.size() == want:
		out.append_array(path)
		return
	var cur: int = path[-1]
	var nbs := _nbrs8(cur)
	_shuffle(nbs)
	for nb in nbs:
		if used.has(nb) or path.has(nb) or _crosses(cur, nb, segs):
			continue
		var dup := false
		for c in path:
			if pz.solution[c] == pz.solution[nb]:
				dup = true
		if dup:
			continue
		path.append(nb)
		_renban_dfs(pz, path, want, used, segs, out)
		path.pop_back()
		if not out.is_empty():
			return


# --------------------------------------------------------------- outside clues

func _make_outer(pz: Puzzle, t: String, sides: Array, n: int) -> void:
	var slots: Array = []
	for sd in sides:
		for i in 9:
			slots.append([sd, i])
	_shuffle(slots)
	for k in mini(n, slots.size()):
		var sd: String = slots[k][0]
		var i: int = slots[k][1]
		var a := PackedInt32Array()
		for c in Solver.outer_cells(sd, i):
			a.append(pz.solution[c])
		pz.outer.append({"t": t, "s": sd, "i": i, "v": Solver.outer_value(t, a)})


## Little (unique) killer: diagonal sums from a clue just outside the grid; digits on a sum differ.
func _make_little_killer(pz: Puzzle, n: int) -> void:
	var cands: Array = []
	var seen := {}
	var spots: Array = []
	for k in 9:
		spots.append_array([[-1, k], [9, k], [k, -1], [k, 9]])
	for o in spots:
		for dir in [[1, 1], [1, -1], [-1, 1], [-1, -1]]:
			var cells: Array = []
			var r: int = o[0] + dir[0]
			var c: int = o[1] + dir[1]
			while r >= 0 and r <= 8 and c >= 0 and c <= 8:
				cells.append(r * 9 + c)
				r += dir[0]
				c += dir[1]
			if cells.size() < 2 or cells.size() > 7:
				continue
			var digits := {}
			var total := 0
			for cc in cells:
				digits[pz.solution[cc]] = true
				total += pz.solution[cc]
			if digits.size() != cells.size():
				continue
			var key := str(cells.min()) + ":" + str(cells.max())
			if seen.has(key):
				continue
			seen[key] = true
			cands.append({"cells": cells, "sum": total, "o": o, "dir": dir})
	_shuffle(cands)
	var used := {}
	for cd in cands:
		if pz.sums.size() >= n:
			break
		var ok := str(cd.o)
		if used.has(ok):
			continue
		used[ok] = true
		pz.sums.append(cd)


# --------------------------------------------------------------- more line clues

## Depth-first search for a line of `want` cells from `start`: ok(path) must hold for every prefix
## and done(path) for the full line. diag = bishop steps only (crossing allowed, no overlap).
func _path_dfs(start: int, want: int, used: Dictionary, segs: Dictionary, ok: Callable, done: Callable, diag := false) -> Array:
	var out: Array = []
	_budget = 300
	_pdfs([start], want, used, segs, ok, done, diag, out)
	return out


func _pdfs(path: Array, want: int, used: Dictionary, segs: Dictionary, ok: Callable, done: Callable, diag: bool, out: Array) -> void:
	_budget -= 1
	if _budget < 0 or not ok.call(path):
		return
	if path.size() == want:
		if done.call(path):
			out.append_array(path)
		return
	var cur: int = path[-1]
	var nbs := _nbrs8(cur)
	_shuffle(nbs)
	for nb in nbs:
		if used.has(nb) or path.has(nb):
			continue
		if diag:
			if nb / 9 == cur / 9 or nb % 9 == cur % 9:
				continue
		elif _crosses(cur, nb, segs) or _crosses_path(cur, nb, path):
			continue
		if path.size() >= 2 and _sharp(path[-2], cur, nb):
			continue
		path.append(nb)
		_pdfs(path, want, used, segs, ok, done, diag, out)
		path.pop_back()
		if not out.is_empty() or _budget < 0:
			return


## Grows a line outwards from a centre cell; pair_ok(x, y) decides which digit pairs may sit at
## matching distances from the centre (palindrome: equal, zipper: sum to the centre digit).
func _centre_path(pz: Puzzle, start: int, pairs: int, used: Dictionary, segs: Dictionary, pair_ok: Callable) -> Array:
	var path: Array = [start]
	for k in pairs:
		var a: int = path[0]
		var b: int = path[-1]
		var opts: Array = []
		for na in _nbrs8(a):
			if used.has(na) or path.has(na) or _crosses(a, na, segs) or _crosses_path(a, na, path):
				continue
			for nb in _nbrs8(b):
				if nb == na or used.has(nb) or path.has(nb) or _crosses(b, nb, segs) or _crosses_path(b, nb, path):
					continue
				if _cross_pair(a, na, b, nb):
					continue
				if path.size() >= 2 and (_sharp(path[1], a, na) or _sharp(path[-2], b, nb)):
					continue
				if pair_ok.call(pz.solution[na], pz.solution[nb]):
					opts.append([na, nb])
		if opts.is_empty():
			break
		var pick: Array = opts[rng.randi_range(0, opts.size() - 1)]
		path.push_front(pick[0])
		path.append(pick[1])
	return path


func _make_path_lines(pz: Puzzle, t: String, n: int) -> void:
	var sol := pz.solution
	var used := {}
	var segs := {}
	var tries := 0
	var any := func(_pp: Array) -> bool: return true
	var bi_ok := func(pp: Array) -> bool:
		for i in pp.size() - 1:
			if sol[pp[i]] == sol[pp[-1]]:
				return false
		return true
	# Between: everything after the first circle sits on one side of it, inner digits between the ends
	var bt_ok := func(pp: Array) -> bool:
		if pp.size() < 2:
			return true
		if sol[pp[1]] == sol[pp[0]]:
			return false
		return (sol[pp[-1]] > sol[pp[0]]) == (sol[pp[1]] > sol[pp[0]])
	var bt_done := func(pp: Array) -> bool:
		var lo := mini(sol[pp[0]], sol[pp[-1]])
		var hi := maxi(sol[pp[0]], sol[pp[-1]])
		for i in range(1, pp.size() - 1):
			if sol[pp[i]] <= lo or sol[pp[i]] >= hi:
				return false
		return true
	# Lockout: ends differ by 4+, inner digits outside their range
	var lo_ok := func(pp: Array) -> bool: return pp.size() < 2 or sol[pp[-1]] != sol[pp[0]]
	var lo_done := func(pp: Array) -> bool:
		if absi(sol[pp[0]] - sol[pp[-1]]) < 4:
			return false
		var lo := mini(sol[pp[0]], sol[pp[-1]])
		var hi := maxi(sol[pp[0]], sol[pp[-1]])
		for i in range(1, pp.size() - 1):
			if sol[pp[i]] >= lo and sol[pp[i]] <= hi:
				return false
		return true
	while pz.lines.size() < n and tries < 800:
		tries += 1
		var start := rng.randi_range(0, 80)
		if used.has(start):
			continue
		var path: Array = []
		match t:
			"pal":
				path = _centre_path(pz, start, rng.randi_range(2, 4), used, segs,
					func(x: int, y: int) -> bool: return x == y)
			"zp":
				var cv: int = sol[start]
				if cv < 3:
					continue
				path = _centre_path(pz, start, rng.randi_range(1, 3), used, segs,
					func(x: int, y: int) -> bool: return x + y == cv)
			"dw":
				path = _path_dfs(start, rng.randi_range(3, 7), used, segs,
					func(pp: Array) -> bool: return pp.size() < 2 or absi(sol[pp[-1]] - sol[pp[-2]]) >= 4, any)
			"st":
				path = _path_dfs(start, rng.randi_range(3, 6), used, segs,
					func(pp: Array) -> bool: return pp.size() < 2 or sol[pp[-1]] >= sol[pp[-2]], any)
			"bi":
				path = _path_dfs(start, rng.randi_range(4, 8), used, segs, bi_ok, any, true)
			"bt":
				path = _path_dfs(start, rng.randi_range(3, 6), used, segs, bt_ok, bt_done)
			"lo":
				path = _path_dfs(start, rng.randi_range(3, 6), used, segs, lo_ok, lo_done)
		if path.size() < 3:
			continue
		for c in path:
			used[c] = true
		if t != "bi":
			_add_segs(path, segs)
		pz.lines.append({"t": t, "cells": path})


## Reflection: groups of two lines that read the same digits from their starting symbol.
func _make_reflection(pz: Puzzle, groups: int) -> void:
	var sol := pz.solution
	var used := {}
	var segs := {}
	var g := 0
	var tries := 0
	while g < groups and tries < 600:
		tries += 1
		var s1 := rng.randi_range(0, 80)
		var s2 := rng.randi_range(0, 80)
		if s1 == s2 or used.has(s1) or used.has(s2) or sol[s1] != sol[s2]:
			continue
		var p1: Array = [s1]
		var p2: Array = [s2]
		var want := rng.randi_range(3, 5)
		while p1.size() < want:
			var a: int = p1[-1]
			var b: int = p2[-1]
			var opts: Array = []
			for na in _nbrs8(a):
				if used.has(na) or p1.has(na) or p2.has(na) or _crosses(a, na, segs):
					continue
				if _crosses_path(a, na, p1) or _crosses_path(a, na, p2):
					continue
				for nb in _nbrs8(b):
					if nb == na or used.has(nb) or p1.has(nb) or p2.has(nb) or _crosses(b, nb, segs):
						continue
					if _crosses_path(b, nb, p1) or _crosses_path(b, nb, p2) or _cross_pair(a, na, b, nb):
						continue
					if sol[na] == sol[nb]:
						opts.append([na, nb])
			if opts.is_empty():
				break
			var pick: Array = opts[rng.randi_range(0, opts.size() - 1)]
			p1.append(pick[0])
			p2.append(pick[1])
		if p1.size() < 3:
			continue
		# sometimes one line runs on past the shorter one
		if rng.randf() < 0.4:
			var a: int = p1[-1]
			for na in _nbrs8(a):
				if not used.has(na) and not p1.has(na) and not p2.has(na) and not _crosses(a, na, segs) 						and not _crosses_path(a, na, p1) and not _crosses_path(a, na, p2):
					p1.append(na)
					break
		for c in p1 + p2:
			used[c] = true
		_add_segs(p1, segs)
		_add_segs(p2, segs)
		pz.lines.append({"t": "rf", "g": g, "cells": p1})
		pz.lines.append({"t": "rf", "g": g, "cells": p2})
		g += 1


# --------------------------------------------------------------- edge relations

func _edge_pairs() -> Array:
	var out: Array = []
	for i in 81:
		if i % 9 < 8: out.append([i, i + 1])
		if i < 72: out.append([i, i + 9])
	return out


func _make_consecutive(pz: Puzzle) -> void:
	pz.negative = true
	for pr in _edge_pairs():
		if absi(pz.solution[pr[0]] - pz.solution[pr[1]]) == 1:
			pz.edges[Puzzle.edge_key(pr[0], pr[1])] = "c"


## Greater-than signs (">" = the lower-index cell is bigger) or Couples parity tildes.
func _make_relations(pz: Puzzle, greater: bool, n: int) -> void:
	var pairs := _edge_pairs()
	_shuffle(pairs)
	for k in mini(n, pairs.size()):
		var a: int = pz.solution[pairs[k][0]]
		var b: int = pz.solution[pairs[k][1]]
		var t := (">" if a > b else "<") if greater else ("s" if a % 2 == b % 2 else "d")
		pz.edges[Puzzle.edge_key(pairs[k][0], pairs[k][1])] = t


func _make_quads(pz: Puzzle, n: int) -> void:
	var tops: Array = []
	for r in 8:
		for c in 8:
			tops.append(r * 9 + c)
	_shuffle(tops)
	for k in mini(n, tops.size()):
		var t: int = tops[k]
		var ds: Array = [pz.solution[t], pz.solution[t + 1], pz.solution[t + 9], pz.solution[t + 10]]
		_shuffle(ds)
		var pick := ds.slice(0, rng.randi_range(2, 4))
		pick.sort()
		pz.quads.append({"c": t, "d": pick})


func _make_twists(pz: Puzzle) -> void:
	var sol := pz.solution
	for r in 8:
		for c in 8:
			var t := r * 9 + c
			if absi(sol[t] - sol[t + 10]) == 1 and absi(sol[t + 1] - sol[t + 9]) == 1:
				pz.twists.append(t)


# --------------------------------------------------------------- cell marks

func _make_marks(pz: Puzzle, variant: String, n: int) -> void:
	var sol := pz.solution
	var cand: Array = []
	for m in 81:
		var d: int = sol[m]
		var r := m / 9
		var c := m % 9
		var code := ""
		match variant:
			"axia":
				code = "ax"
				for dir in [[1, 1], [1, -1], [-1, 1], [-1, -1]]:
					var rr: int = r + dir[0]
					var c2: int = c + dir[1]
					while rr >= 0 and rr <= 8 and c2 >= 0 and c2 <= 8:
						if sol[rr * 9 + c2] == d:
							code = ""
						rr += dir[0]
						c2 += dir[1]
			"friendly":
				if d == r + 1 or d == c + 1 or d == (r / 3) * 3 + c / 3 + 1:
					code = "fr"
			"pulse":
				code = "pu"
				for nb in _orth(m):
					if not Solver.edge_rel(Solver.Edge.PULSE, d, sol[nb]):
						code = ""
			"index":
				var h: bool = sol[r * 9 + d - 1] == c + 1
				var v: bool = sol[(d - 1) * 9 + c] == r + 1
				if h and v: code = "ihv"
				elif h: code = "ih"
				elif v: code = "iv"
		if code != "":
			cand.append([m, code])
	_shuffle(cand)
	for cd in cand:
		if pz.marks.size() >= n:
			break
		if variant == "pulse":
			var clash := false
			for nb in _orth(cd[0]):
				if pz.marks.has(nb): clash = true
			if clash:
				continue
		pz.marks[cd[0]] = cd[1]


## Slingshot: source s next to arrow cell a; the arrow bends 90 degrees into dir.
func _make_slings(pz: Puzzle, n: int) -> void:
	var sol := pz.solution
	var cand: Array = []
	for a in 81:
		for s in _orth(a):
			var dr: int = a / 9 - s / 9
			var dc: int = a % 9 - s % 9
			for dir in [[dc, dr], [-dc, -dr]]:
				var tr: int = a / 9 + dir[0] * sol[a]
				var tc: int = a % 9 + dir[1] * sol[a]
				if tr >= 0 and tr <= 8 and tc >= 0 and tc <= 8 and sol[tr * 9 + tc] == sol[s]:
					cand.append({"s": s, "a": a, "dir": dir})
	_shuffle(cand)
	var used := {}
	for cd in cand:
		if pz.slings.size() >= n:
			break
		if used.has(cd.a) or used.has(cd.s):
			continue
		used[cd.a] = true
		used[cd.s] = true
		pz.slings.append(cd)


## Vertex: a tip cell with two arm cells around it (not in a straight line through the tip).
func _make_vertices(pz: Puzzle, n: int) -> void:
	var sol := pz.solution
	var cand: Array = []
	for t in 81:
		var nb := _nbrs8(t)
		for i in nb.size():
			for j in range(i + 1, nb.size()):
				var a: int = nb[i]
				var b: int = nb[j]
				if a - t == t - b:
					continue
				if Solver.vertex_rel(sol[t], sol[a], sol[b]):
					cand.append({"tip": t, "a": a, "b": b})
	_shuffle(cand)
	var used := {}
	var segs := {}
	for cd in cand:
		if pz.vertices.size() >= n:
			break
		if used.has(cd.tip) or used.has(cd.a) or used.has(cd.b):
			continue
		if _crosses(cd.tip, cd.a, segs) or _crosses(cd.tip, cd.b, segs):
			continue
		for c in [cd.tip, cd.a, cd.b]:
			used[c] = true
		_add_segs([cd.a, cd.tip, cd.b], segs)
		pz.vertices.append(cd)
