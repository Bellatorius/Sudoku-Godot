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
	"region_sum": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"entropic": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"modular": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"parity_lines": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"nabner": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"ten_lines": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"double_arrow": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"pill_arrow": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"fortress": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"min_max": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"clone": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"frame": {"beginner": 36, "easy": 28, "medium": 18, "hard": 0, "expert": 0, "master": 0},
	"numbered_rooms": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"rossini": {"beginner": 34, "easy": 26, "medium": 16, "hard": 0, "expert": 0, "master": 0},
	"battlefield": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"sum_product_dots": {"beginner": 36, "easy": 28, "medium": 18, "hard": 0, "expert": 0, "master": 0},
	"anti_diagonal": {"beginner": 40, "easy": 32, "medium": 26, "hard": 0, "expert": 0, "master": 0},
	"center_dot": {"beginner": 40, "easy": 34, "medium": 27, "hard": 0, "expert": 0, "master": 0},
	"asterisk": {"beginner": 40, "easy": 34, "medium": 27, "hard": 0, "expert": 0, "master": 0},
	"girandola": {"beginner": 40, "easy": 34, "medium": 27, "hard": 0, "expert": 0, "master": 0},
	"argyle": {"beginner": 40, "easy": 34, "medium": 27, "hard": 0, "expert": 0, "master": 0},
	"queen": {"beginner": 40, "easy": 34, "medium": 27, "hard": 0, "expert": 0, "master": 0},
	"miracle": {"beginner": 30, "easy": 20, "medium": 12, "hard": 0, "expert": 0, "master": 0},
	"magic_square": {"beginner": 40, "easy": 32, "medium": 26, "hard": 0, "expert": 0, "master": 0},
	"toroidal": {"beginner": 44, "easy": 36, "medium": 29, "hard": 0, "expert": 0, "master": 0},
	"ratio_dots": {"beginner": 36, "easy": 28, "medium": 18, "hard": 0, "expert": 0, "master": 0},
	"difference_dots": {"beginner": 36, "easy": 28, "medium": 18, "hard": 0, "expert": 0, "master": 0},
	"product_lines": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"difference_lines": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"ratio_lines": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"prime_composite": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"parity_regions": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"missing_digit": {"beginner": 38, "easy": 30, "medium": 24, "hard": 0, "expert": 0, "master": 0},
	"forbidden_digit": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"divisibility": {"beginner": 38, "easy": 30, "medium": 22, "hard": 0, "expert": 0, "master": 0},
	"kenken": {"beginner": 34, "easy": 22, "medium": 12, "hard": 0, "expert": 0, "master": 0},
	"alphabet": {"beginner": 46, "easy": 38, "medium": 30, "hard": 0, "expert": 0, "master": 0},
	"wordoku": {"beginner": 46, "easy": 38, "medium": 30, "hard": 0, "expert": 0, "master": 0},
	"symbol": {"beginner": 46, "easy": 38, "medium": 30, "hard": 0, "expert": 0, "master": 0},
	"color": {"beginner": 46, "easy": 38, "medium": 30, "hard": 0, "expert": 0, "master": 0},
	"roman": {"beginner": 46, "easy": 38, "medium": 30, "hard": 0, "expert": 0, "master": 0},
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
## Expert: as few given digits as possible. 0 = an empty grid (the clues alone solve it); 2 = variants whose
## rules stay true when digits are swapped (d -> 10-d …), so a digit or two must break the tie. The generator adds
## more clues (hard amounts × EXPERT_BOOSTS) until the goal is met, else keeps the try with the fewest digits.
const EXPERT_GOAL := {
	# measured: these reach 0-8 digits in under ~2 minutes a puzzle. The slow outside-clue and many line
	# variants (Sandwich, Skyscraper, Ascending, Ten Lines, Frame, Region Sum, …) keep the graded Expert.
	"kropki": 0, "xv": 0, "sum_product_dots": 0, "quadruple": 0, "numbered_rooms": 0, "greater_than": 0, "xsum": 0,
	"killer": 0, "arrow": 0, "pill_arrow": 0, "zipper": 0, "thermo": 0, "slow_thermo": 0,
	"consecutive": 2, "twisted": 2, "german_whispers": 2, "renban": 2, "reflection": 2, "miracle": 2,
	"ratio_dots": 0, "product_lines": 0, "ratio_lines": 0, "kenken": 0, "difference_dots": 2, "difference_lines": 2,
}
## Wordoku: 9-letter words with no repeated letter (the letters stand for the digits 1-9).
const WORDS := ["AUTHORIZE", "COMPUTERS", "ABDUCTING", "BACKFIRED", "BLUDGEONS", "CHAMPIONS", "DUPLICATE",
	"EDUCATION", "FORMULATE", "PATHOGENS", "MOUSETRAP", "HYDRAULIC", "COUNTRIES"]
const EXPERT_BOOSTS := [1.0, 1.6, 2.4, 3.5]
## Line variants built as pictures (Shapes): the picture is laid down first and the digits are solved to fit it.
## Value = line type ("th" = thermometers).
const PICTURE := {"thermo": "th", "slow_thermo": "st", "german_whispers": "gw", "dutch_whispers": "dw", "renban": "rb",
	"between": "bt", "lockout": "lo", "zipper": "zp", "region_sum": "rs", "entropic": "en",
	"modular": "mo", "parity_lines": "pa", "nabner": "nb", "ten_lines": "tn", "double_arrow": "da"}
## (Palindrome, product, difference and ratio lines keep random lines: their rules almost never fit a drawing.)
## Longest / shortest line per type (longer picture paths are cut into pieces that meet end to end).
const PIC_MAX := {"nb": 4, "da": 6, "zp": 5, "lo": 5, "bt": 7, "th": 5, "st": 5, "rs": 6, "gw": 6, "dw": 7}
const PIC_MIN := {"zp": 3, "bt": 3, "lo": 3, "da": 3}
const PIC_NODES := 15000
const PIC_NODES_GEN := 5000   # generated designs give up sooner (most misfits fail fast or never)
## Share of picture puzzles drawn from the hand-drawn library (the rest are generated designs).
const PIC_HAND := {9: 0.6, 6: 0.3}
## Pack builds set this to the puzzle's number in its pack (tools/build_packs.gd): pictures are then
## dealt in a shuffled cycle per variant + level, so none comes back before all the others were used.
static var pic_plan := -1
const EXPERT_NODES := 40000
## Expert / master: how many graded candidates make() tries before settling for the toughest one.
const GRADE_TRIES := 40
const NODE_LIMIT := 6000
## Smaller uniqueness budget where every search node is expensive (whole-row clue checks).
const REDUCE_NODES := {"ascending": 2000}
## Search budget for building the full solution grid, and how many tries make() gets.
## Non-consecutive solutions are hard to find by random search and the time is heavy-tailed,
## so it gets many short tries instead of a few long ones.
const SOLVE_NODES := {"non_consecutive": 40000, "twisted": 40000, "miracle": 40000, "anti_diagonal": 40000, "magic_square": 300000}
const ATTEMPTS := {"non_consecutive": 40, "twisted": 40, "miracle": 60, "anti_diagonal": 40, "toroidal": 40}
## Magic Square: the 3 rows, 3 columns and 2 diagonals of the centre box sum to 15.
const MAGIC_LINES := [[30, 31, 32], [39, 40, 41], [48, 49, 50], [30, 39, 48], [31, 40, 49], [32, 41, 50],
	[30, 40, 50], [32, 40, 48]]

var rng := RandomNumberGenerator.new()
var _n := 9      # grid size of the puzzle being built (6 for Mini)
var _nc := 81    # its cell count
var _budget := 0
var _wrap := false   # toroidal: neighbours wrap around the edges while building regions
var _boost := 1.0    # expert: clue counts are multiplied by this


static func make(variant: String, difficulty: String, seed_value: int) -> Puzzle:
	var g := Generator.new()
	g.rng.seed = seed_value
	var need := 0.0
	var rule := variant.trim_prefix("mini_")
	if (difficulty == "expert" and not EXPERT_GOAL.has(rule)) or difficulty == "master":
		need = float(grade_bar(variant)[0 if difficulty == "expert" else 1])
	var best: Puzzle = null
	var best_grade := -1.0
	for t in (GRADE_TRIES if need > 0.0 else 1):
		var pz: Puzzle = null
		for attempt in int(ATTEMPTS.get(rule, 8)):
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
		if difficulty == "master":
			g._minimize(best, int(REDUCE_NODES.get(rule, NODE_LIMIT)))
	return best


## Master: minimal givens. The symmetric pass in _reduce leaves pairs where only one cell is needed, so
## givens are also taken out one at a time (best of MINIMIZE_ORDERS random orders): afterwards no single
## given can be removed without losing the unique solution.
const MINIMIZE_ORDERS := 3

func _minimize(pz: Puzzle, nodes: int) -> void:
	var solver := Solver.new(pz)
	var best := pz.givens
	for k in MINIMIZE_ORDERS:
		var g := pz.givens.duplicate()
		var cells: Array = []
		for c in g.size():
			if g[c] != 0:
				cells.append(c)
		_shuffle(cells)
		for c in cells:
			var keep := g[c]
			g[c] = 0
			if solver.count_solutions(g, 2, nodes) != 1:
				g[c] = keep
		if g.count(0) > best.count(0):
			best = g
	pz.givens = best


static var _grades_file = null   # extra bars measured later (res://puzzles/grades.json, variant -> [expert, master])


## Expert / master minimum grade for a variant: GRADE, or puzzles/grades.json for newer variants.
static func grade_bar(variant: String) -> Array:
	if _grades_file == null:
		_grades_file = {}
		if FileAccess.file_exists("res://puzzles/grades.json"):
			var data = JSON.parse_string(FileAccess.get_file_as_string("res://puzzles/grades.json"))
			if data is Dictionary:
				_grades_file = data
	if _grades_file.has(variant):   # measured later (newer variants, and the picture versions of line variants)
		return _grades_file[variant]
	return GRADE.get(variant, [0.0, 0.0])


## Solver effort to prove the puzzle has one solution, per empty cell: about 1 when plain deduction
## finishes it, higher when the solver has to try things out. Used to sort expert / master puzzles.
static func grade(pz: Puzzle) -> float:
	var s := Solver.new(pz)
	s.count_solutions(pz.givens, 2, 0)
	return float(s.last_nodes()) / float(pz.givens.count(0) + 1)


## Given digits for a level: TARGETS, scaled to the cell count for Mini (6x6) variants.
static func target(variant: String, difficulty: String) -> int:
	var rule := variant.trim_prefix("mini_")
	var t: int = TARGETS.get(rule, TARGETS.classic)[difficulty]
	return t if rule == variant else int(round(t * 36.0 / 81.0))


func _attempt(id: String, difficulty: String) -> Puzzle:
	var pz := Puzzle.new()
	pz.variant = id
	var variant := pz.rule   # the rules (Mini puzzles use the 9x9 variant's rules on 6x6)
	_n = pz.size
	_nc = _n * _n
	pz.difficulty = difficulty
	pz.diagonals = variant == "diagonal"
	if variant == "jigsaw":
		pz.regions = _jigsaw_regions()
	elif variant == "toroidal":
		_wrap = true
		pz.regions = _jigsaw_regions()
		_wrap = false
	elif variant == "magic_square":
		for ln in MAGIC_LINES:
			pz.sums.append({"cells": ln.duplicate(), "sum": 15, "o": [], "dir": []})
	var empty := PackedInt32Array()
	empty.resize(_nc)
	if variant == "magic_square":   # start from one of the 8 magic squares (rotations / mirrors of one)
		var sq := [[2, 7, 6], [9, 5, 1], [4, 3, 8]]
		var turn := rng.randi_range(0, 3)
		var flip := rng.randf() < 0.5
		for r in 3:
			for c in 3:
				var rr := r
				var cc := c
				for k in turn:
					var t := rr; rr = cc; cc = 2 - t
				if flip:
					cc = 2 - cc
				empty[(3 + rr) * _n + 3 + cc] = sq[r][c]
	if PICTURE.has(variant):
		return _attempt_picture(pz, id, variant, difficulty, empty)
	pz.twist_gen = variant == "twisted"
	var sol := Solver.new(pz).solve(empty, rng, int(SOLVE_NODES.get(variant, 20000)))
	pz.twist_gen = false
	if sol.size() != _nc:
		return null
	pz.solution = sol
	var tier: String = CLUE_TIER.get(difficulty, difficulty)   # how many variant clues this level gets
	if difficulty == "expert" and EXPERT_GOAL.has(variant):
		return _attempt_fewest(pz, variant)

	_make_clues(pz, variant, tier)
	if variant == "pulse" and pz.marks.size() < 2:
		return null

	pz.givens = sol.duplicate()
	_reduce(pz, target(id, difficulty), int(REDUCE_NODES.get(variant, NODE_LIMIT)))
	return pz


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]; a[i] = a[j]; a[j] = t


func _reduce(pz: Puzzle, target: int, nodes := NODE_LIMIT) -> void:
	var solver := Solver.new(pz)
	var cells: Array = []
	var nc := pz.cell_count()
	for i in (nc + 1) / 2:  # symmetric pairs (i, nc - 1 - i)
		cells.append(i)
	_shuffle(cells)
	var count := nc
	for c in cells:
		if target > 0 and count <= target:
			break
		var o: int = nc - 1 - c
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
	var reg := Puzzle.standard_regions(_n)
	var swaps := 0
	var tries := 0
	while swaps < 120 and tries < 6000:
		tries += 1
		var a := rng.randi_range(0, _nc - 1)
		var nbs := _orth(a)
		var b: int = nbs[rng.randi_range(0, nbs.size() - 1)]
		var ra := reg[a]
		var rb := reg[b]
		if ra == rb:
			continue
		# a moves into rb; pick some cell x of rb adjacent to ra (not b) to move into ra
		var cand: Array = []
		for x in _nc:
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
	var r := i / _n
	var c := i % _n
	var out: Array = []
	if _wrap:   # toroidal: the board wraps around
		return [((r + 8) % _n) * _n + c, ((r + 1) % _n) * _n + c, r * _n + (c + 8) % _n, r * _n + (c + 1) % _n]
	if r > 0: out.append(i - _n)
	if r < _n - 1: out.append(i + _n)
	if c > 0: out.append(i - 1)
	if c < _n - 1: out.append(i + 1)
	return out


func _connected(reg: PackedInt32Array, id: int) -> bool:
	var start := -1
	var total := 0
	for i in _nc:
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

func _make_cages(pz: Puzzle, ops := false) -> void:
	var owner := PackedInt32Array()
	owner.resize(_nc)
	owner.fill(-1)
	var order: Array = range(_nc)
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
		if not ops:
			pz.cages.append({"cells": cells, "sum": s})
			continue
		# Mathdoku: + or × for any cage, − or ÷ for two cells
		var a: int = pz.solution[cells[0]]
		var b: int = pz.solution[cells[-1]]
		var choices: Array = ["+", "*"]
		if cells.size() == 2:
			choices += ["-", "-"]
			if maxi(a, b) % mini(a, b) == 0: choices += ["/", "/"]
		var op: String = choices[rng.randi_range(0, choices.size() - 1)]
		var val := s
		if op == "*":
			val = 1
			for c in cells: val *= pz.solution[c]
		elif op == "-": val = absi(a - b)
		elif op == "/": val = maxi(a, b) / mini(a, b)
		pz.cages.append({"cells": cells, "sum": val, "op": op})


# --------------------------------------------------------------- lines

func _nbrs8(i: int) -> Array:
	var r := i / _n
	var c := i % _n
	var out: Array = []
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if dr == 0 and dc == 0: continue
			var rr: int = r + dr
			var cc: int = c + dc
			if rr >= 0 and rr < _n and cc >= 0 and cc < _n:
				out.append(rr * _n + cc)
	return out


func _seg_key(a: int, b: int) -> String:
	return "%d-%d" % [mini(a, b), maxi(a, b)]


## A diagonal step a->b is blocked if it would cross an existing diagonal segment.
func _crosses(a: int, b: int, segs: Dictionary) -> bool:
	var ra := a / _n
	var ca := a % _n
	var rb := b / _n
	var cb := b % _n
	if ra == rb or ca == cb:
		return false
	return segs.has(_seg_key(ra * _n + cb, rb * _n + ca))


## True if the diagonal step a->b would cross step c->d.
func _cross_pair(a: int, b: int, c: int, d: int) -> bool:
	if a / _n == b / _n or a % _n == b % _n:
		return false
	var x := (a / _n) * _n + b % _n
	var y := (b / _n) * _n + a % _n
	return (c == x and d == y) or (c == y and d == x)


## True if the line a->b->c turns back on itself (sharper than a right angle).
func _sharp(a: int, b: int, c: int) -> bool:
	return (b / _n - a / _n) * (c / _n - b / _n) + (b % _n - a % _n) * (c % _n - b % _n) < 0


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
	n = _scaled(n)
	var used := {}
	var segs := {}
	var tries := 0
	while pz.thermos.size() < n and tries < 400:
		tries += 1
		var start := rng.randi_range(0, _nc - 1)
		if used.has(start) or pz.solution[start] > _n - 4:
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
	n = _scaled(n)
	var used := {}
	var segs := {}
	var tries := 0
	while pz.arrows.size() < n and tries < 400:
		tries += 1
		var circle := rng.randi_range(0, _nc - 1)
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
	for i in _nc:
		for n in [i + 1, i + _n]:
			if n >= _nc or (n == i + 1 and i % _n == _n - 1):
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
				if a + b == 10: t = "x"   # (Mini: only 4 + 6)
				elif a + b == 5: t = "v"
			if t != "":
				pz.edges[Puzzle.edge_key(i, n)] = t


# --------------------------------------------------------------- even-odd

func _make_parity(pz: Puzzle, n: int) -> void:
	n = _scaled(n)
	var cells: Array = range(_nc)
	_shuffle(cells)
	for i in mini(n, _nc):
		var c: int = cells[i]
		pz.parity[c] = "e" if pz.solution[c] % 2 == 0 else "o"


# --------------------------------------------------------------- whispers / renban lines

func _make_lines(pz: Puzzle, t: String, n: int) -> void:
	n = _scaled(n)
	var used := {}
	var segs := {}
	var tries := 0
	while pz.lines.size() < n and tries < 600:
		tries += 1
		var start := rng.randi_range(0, _nc - 1)
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
	n = _scaled(n)
	var slots: Array = []
	for sd in sides:
		for i in _n:
			slots.append([sd, i])
	_shuffle(slots)
	for k in mini(n, slots.size()):
		var sd: String = slots[k][0]
		var i: int = slots[k][1]
		var a := PackedInt32Array()
		for c in Solver.outer_cells(sd, i, _n):
			a.append(pz.solution[c])
		var v := Solver.outer_value(t, a)
		if t == "md":   # Missing Digit: a digit that isn't among the first three cells
			var opts: Array = range(1, 10).filter(func(x): return x != a[0] and x != a[1] and x != a[2])
			v = opts[rng.randi_range(0, opts.size() - 1)]
		pz.outer.append({"t": t, "s": sd, "i": i, "v": v})


## Little (unique) killer: diagonal sums from a clue just outside the grid; digits on a sum differ.
func _make_little_killer(pz: Puzzle, n: int) -> void:
	n = _scaled(n)
	var cands: Array = []
	var seen := {}
	var spots: Array = []
	for k in _n:
		spots.append_array([[-1, k], [_n, k], [k, -1], [k, _n]])
	for o in spots:
		for dir in [[1, 1], [1, -1], [-1, 1], [-1, -1]]:
			var cells: Array = []
			var r: int = o[0] + dir[0]
			var c: int = o[1] + dir[1]
			while r >= 0 and r < _n and c >= 0 and c < _n:
				cells.append(r * _n + c)
				r += dir[0]
				c += dir[1]
			if cells.size() < 2 or cells.size() > _n - 2:
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
			if nb / _n == cur / _n or nb % _n == cur % _n:
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
	n = _scaled(n)
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
	var en_ok := func(pp: Array) -> bool:   # entropic / modular: the last three cells all differ
		if pp.size() < 2: return true
		var g := func(x: int) -> int: return (x - 1) / (_n / 3) if t == "en" else x % 3
		for i in range(maxi(0, pp.size() - 3), pp.size() - 1):
			if g.call(sol[pp[i]]) == g.call(sol[pp[-1]]): return false
		return true
	var pa_ok := func(pp: Array) -> bool: return pp.size() < 2 or sol[pp[-1]] % 2 != sol[pp[-2]] % 2
	var nb_ok := func(pp: Array) -> bool:
		for i in pp.size() - 1:
			if absi(sol[pp[i]] - sol[pp[-1]]) <= 1: return false
		return true
	var ten_run := func(pp: Array) -> int:   # running sum of the open piece, -1 if a piece overshoots 10
		var r := 0
		for c in pp:
			r += sol[c]
			if r == 10: r = 0
			elif r > 10: return -1
		return r
	var tn_ok := func(pp: Array) -> bool: return ten_run.call(pp) >= 0
	var tn_done := func(pp: Array) -> bool: return ten_run.call(pp) == 0
	var da_ok := func(pp: Array) -> bool:
		var inner := 0
		for i in range(1, pp.size()): inner += sol[pp[i]]
		return inner - sol[pp[-1]] <= 17
	var da_done := func(pp: Array) -> bool:
		var inner := 0
		for i in range(1, pp.size() - 1): inner += sol[pp[i]]
		return sol[pp[0]] + sol[pp[-1]] == inner
	var pr_done := func(pp: Array) -> bool:   # 2+ box pieces, all with the same product
		var prods: Array = []
		for j in pp.size():
			if j == 0 or pz.regions[pp[j]] != pz.regions[pp[j - 1]]:
				prods.append(1)
			prods[-1] *= sol[pp[j]]
		if prods.size() < 2: return false
		for x in prods:
			if x != prods[0]: return false
		return true
	var df_ok := func(pp: Array) -> bool:   # every step the same (non-zero) difference
		if pp.size() < 2: return true
		var g := absi(sol[pp[1]] - sol[pp[0]])
		return g > 0 and absi(sol[pp[-1]] - sol[pp[-2]]) == g
	var rt_ok := func(pp: Array) -> bool:   # every step a 2:1 ratio
		if pp.size() < 2: return true
		var x: int = sol[pp[-1]]; var y: int = sol[pp[-2]]
		return x == y * 2 or y == x * 2
	var rs_done := func(pp: Array) -> bool:   # 2+ box segments, all with the same sum
		var sums: Array = []
		for j in pp.size():
			if j == 0 or pz.regions[pp[j]] != pz.regions[pp[j - 1]]:
				sums.append(0)
			sums[-1] += sol[pp[j]]
		if sums.size() < 2: return false
		for x in sums:
			if x != sums[0]: return false
		return true
	while pz.lines.size() < n and tries < 800:
		tries += 1
		var start := rng.randi_range(0, _nc - 1)
		if used.has(start):
			continue
		var path: Array = []
		match t:
			"en", "mo":
				path = _path_dfs(start, rng.randi_range(4, 7), used, segs, en_ok, any)
			"pa":
				path = _path_dfs(start, rng.randi_range(4, 7), used, segs, pa_ok, any)
			"nb":
				path = _path_dfs(start, rng.randi_range(3, 5), used, segs, nb_ok, any)
			"tn":
				path = _path_dfs(start, rng.randi_range(3, 7), used, segs, tn_ok, tn_done)
			"da":
				path = _path_dfs(start, rng.randi_range(3, 5), used, segs, da_ok, da_done)
			"rs":
				path = _path_dfs(start, rng.randi_range(4, 7), used, segs, any, rs_done)
			"pr":
				path = _path_dfs(start, rng.randi_range(3, 6), used, segs, any, pr_done)
			"df":
				path = _path_dfs(start, rng.randi_range(3, 6), used, segs, df_ok, any)
			"rt":
				path = _path_dfs(start, 3, used, segs, rt_ok, any)
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
	groups = _scaled(groups)
	var sol := pz.solution
	var used := {}
	var segs := {}
	var g := 0
	var tries := 0
	while g < groups and tries < 600:
		tries += 1
		var s1 := rng.randi_range(0, _nc - 1)
		var s2 := rng.randi_range(0, _nc - 1)
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
	for i in _nc:
		if i % _n < _n - 1: out.append([i, i + 1])
		if i < _nc - _n: out.append([i, i + _n])
	return out


func _make_consecutive(pz: Puzzle) -> void:
	pz.negative = true
	for pr in _edge_pairs():
		if absi(pz.solution[pr[0]] - pz.solution[pr[1]]) == 1:
			pz.edges[Puzzle.edge_key(pr[0], pr[1])] = "c"


## Greater-than signs (">" = the lower-index cell is bigger) or Couples parity tildes.
func _make_relations(pz: Puzzle, greater: bool, n: int) -> void:
	n = _scaled(n)
	var pairs := _edge_pairs()
	_shuffle(pairs)
	for k in mini(n, pairs.size()):
		var a: int = pz.solution[pairs[k][0]]
		var b: int = pz.solution[pairs[k][1]]
		var t := (">" if a > b else "<") if greater else ("s" if a % 2 == b % 2 else "d")
		pz.edges[Puzzle.edge_key(pairs[k][0], pairs[k][1])] = t


func _make_quads(pz: Puzzle, n: int) -> void:
	n = _scaled(n)
	var tops: Array = []
	for r in _n - 1:
		for c in _n - 1:
			tops.append(r * _n + c)
	_shuffle(tops)
	for k in mini(n, tops.size()):
		var t: int = tops[k]
		var ds: Array = [pz.solution[t], pz.solution[t + 1], pz.solution[t + _n], pz.solution[t + _n + 1]]
		_shuffle(ds)
		var pick := ds.slice(0, rng.randi_range(2, 4))
		pick.sort()
		pz.quads.append({"c": t, "d": pick})


func _make_twists(pz: Puzzle) -> void:
	var sol := pz.solution
	for r in 8:
		for c in 8:
			var t := r * _n + c
			if absi(sol[t] - sol[t + 10]) == 1 and absi(sol[t + 1] - sol[t + 9]) == 1:
				pz.twists.append(t)


# --------------------------------------------------------------- cell marks

func _make_marks(pz: Puzzle, variant: String, n: int) -> void:
	n = _scaled(n)
	var sol := pz.solution
	var cand: Array = []
	for m in _nc:
		var d: int = sol[m]
		var r := m / _n
		var c := m % _n
		var code := ""
		match variant:
			"axia":
				code = "ax"
				for dir in [[1, 1], [1, -1], [-1, 1], [-1, -1]]:
					var rr: int = r + dir[0]
					var c2: int = c + dir[1]
					while rr >= 0 and rr <= 8 and c2 >= 0 and c2 <= 8:
						if sol[rr * _n + c2] == d:
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
			"prime_composite":
				if d in [2, 3, 5, 7]: code = "pm"
				elif d in [4, 6, 8, 9]: code = "cm"
			"forbidden_digit":
				var x := rng.randi_range(1, 8)
				code = "x%d" % (x if x < d else x + 1)   # any digit except the right one
			"divisibility":
				var opts: Array = []
				for q in [2, 3, 4]:
					if d % q == 0: opts.append("d%d" % q)
				if not opts.is_empty(): code = opts[rng.randi_range(0, opts.size() - 1)]
			"index":
				var h: bool = sol[r * _n + d - 1] == c + 1
				var v: bool = sol[(d - 1) * _n + c] == r + 1
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
	n = _scaled(n)
	var sol := pz.solution
	var cand: Array = []
	for a in _nc:
		for s in _orth(a):
			var dr: int = a / _n - s / _n
			var dc: int = a % _n - s % _n
			for dir in [[dc, dr], [-dc, -dr]]:
				var tr: int = a / _n + dir[0] * sol[a]
				var tc: int = a % _n + dir[1] * sol[a]
				if tr >= 0 and tr <= 8 and tc >= 0 and tc <= 8 and sol[tr * _n + tc] == sol[s]:
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
	n = _scaled(n)
	var sol := pz.solution
	var cand: Array = []
	for t in _nc:
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



# --------------------------------------------------------------- newer clue types

## Pill Arrow: two orthogonal cells read as a 2-digit number, then an arrow whose digits sum to it.
func _make_pills(pz: Puzzle, n: int) -> void:
	n = _scaled(n)
	var sol := pz.solution
	var used := {}
	var segs := {}
	var tries := 0
	while pz.lines.size() < n and tries < 800:
		tries += 1
		var a := rng.randi_range(0, _nc - 1)
		var nbs := _orth(a)
		var b: int = nbs[rng.randi_range(0, nbs.size() - 1)]
		if used.has(a) or used.has(b):
			continue
		var target: int = sol[a] * 10 + sol[b]
		if target > 40:
			continue
		var paths: Array = []
		_arrow_dfs(pz, [b], 0, target, used.merged({a: true}), segs, paths)
		paths = paths.filter(func(pp): return pp.size() <= 7)
		if paths.is_empty():
			continue
		var path: Array = paths[rng.randi_range(0, paths.size() - 1)]
		var cells: Array = [a] + path
		for c in cells:
			used[c] = true
		_add_segs(path, segs)
		pz.lines.append({"t": "pl", "cells": cells})


## Fortress: grey cells bigger than each orthogonal neighbour that isn't grey.
func _make_fortress(pz: Puzzle, n: int) -> void:
	n = _scaled(n)
	var sol := pz.solution
	var order: Array = range(_nc)
	_shuffle(order)
	var grey := {}
	for c in order:
		if grey.size() >= n:
			break
		var ok := true
		for nb in _orth(c):
			if not grey.has(nb) and sol[nb] >= sol[c]:
				ok = false
		# a grey neighbour that relied on this cell being white must still be bigger than it
		if ok:
			grey[c] = true
			pz.marks[c] = "fo"


## Minimum / Maximum: cells smaller / bigger than all orthogonal neighbours.
func _make_minmax(pz: Puzzle, n: int) -> void:
	n = _scaled(n)
	var sol := pz.solution
	var cand: Array = []
	for c in _nc:
		var lo := true
		var hi := true
		for nb in _orth(c):
			if sol[nb] < sol[c]: lo = false
			if sol[nb] > sol[c]: hi = false
		if lo: cand.append([c, "mn"])
		if hi: cand.append([c, "mx"])
	_shuffle(cand)
	for cd in cand:
		if pz.marks.size() >= n:
			break
		var clash := false
		for nb in _orth(cd[0]):
			if pz.marks.has(nb): clash = true
		if not clash:
			pz.marks[cd[0]] = cd[1]


## Clone: pairs of same-shaped areas (2-5 cells) whose digits match cell by cell.
func _make_clones(pz: Puzzle, n: int) -> void:
	n = _scaled(n)
	var sol := pz.solution
	var used := {}
	var tries := 0
	while pz.clones.size() < n and tries < 3000:
		tries += 1
		var a := rng.randi_range(0, _nc - 1)
		var dr := rng.randi_range(-8, 8)
		var dc := rng.randi_range(-8, 8)
		if dr == 0 and dc == 0:
			continue
		var shape: Array = []   # grow a shape from a while the shifted cells keep matching
		var frontier: Array = [a]
		var want := rng.randi_range(2, 5)
		while shape.size() < want and not frontier.is_empty():
			var c: int = frontier.pop_at(rng.randi_range(0, frontier.size() - 1))
			if shape.has(c) or used.has(c):
				continue
			var r: int = c / _n + dr
			var k: int = c % _n + dc
			if r < 0 or r > 8 or k < 0 or k > 8:
				continue
			var t: int = r * _n + k
			if used.has(t) or sol[t] != sol[c] or shape.has(t):
				continue
			shape.append(c)
			for nb in _orth(c):
				frontier.append(nb)
		if shape.size() < 2:
			continue
		var b: Array = shape.map(func(c): return (c / _n + dr) * _n + c % _n + dc)
		var overlap := false
		for c in b:
			if shape.has(c): overlap = true
		if overlap:
			continue
		for c in shape + b:
			used[c] = true
		pz.clones.append({"a": shape, "b": b})


## Sum & product dots: a number on the edge between two cells, "+N" (sum) or "*N" (product).
func _make_value_dots(pz: Puzzle, n: int) -> void:
	n = _scaled(n)
	var pairs := _edge_pairs()
	_shuffle(pairs)
	for k in mini(n, pairs.size()):
		var a: int = pz.solution[pairs[k][0]]
		var b: int = pz.solution[pairs[k][1]]
		var t := ("+%d" % (a + b)) if rng.randf() < 0.5 else ("*%d" % (a * b))
		pz.edges[Puzzle.edge_key(pairs[k][0], pairs[k][1])] = t


## Lines, cages, dots, outside numbers … for a level's clue tier (scaled by _boost for expert).
func _make_clues(pz: Puzzle, variant: String, tier: String) -> void:
	var e := tier == "easy"
	var m := tier == "medium"
	match variant:
		"killer": _make_cages(pz)
		"kenken": _make_cages(pz, true)
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
		"region_sum": _make_path_lines(pz, "rs", 5 if e else (6 if m else 8))
		"entropic": _make_path_lines(pz, "en", 5 if e else (6 if m else 8))
		"modular": _make_path_lines(pz, "mo", 5 if e else (6 if m else 8))
		"parity_lines": _make_path_lines(pz, "pa", 6 if e else (7 if m else 9))
		"nabner": _make_path_lines(pz, "nb", 6 if e else (7 if m else 9))
		"ten_lines": _make_path_lines(pz, "tn", 6 if e else (7 if m else 9))
		"double_arrow": _make_path_lines(pz, "da", 6 if e else (7 if m else 9))
		"pill_arrow": _make_pills(pz, 5 if e else (6 if m else 8))
		"fortress": _make_fortress(pz, 10 if e else (12 if m else 16))
		"min_max": _make_minmax(pz, 8 if e else (10 if m else 14))
		"clone": _make_clones(pz, 3 if e else (4 if m else 5))
		"frame": _make_outer(pz, "fs", ["L", "R", "T", "B"], 14 if e else (18 if m else 24))
		"numbered_rooms": _make_outer(pz, "nr", ["L", "R", "T", "B"], 12 if e else (14 if m else 18))
		"rossini": _make_outer(pz, "ro", ["L", "R", "T", "B"], 36)   # every side: no arrow means "neither"
		"battlefield": _make_outer(pz, "bf", ["L", "T"], 12 if e else (14 if m else 18))
		"sum_product_dots": _make_value_dots(pz, 24 if e else (30 if m else 40))
		"ratio_dots": _make_ratio_dots(pz, 24 if e else (30 if m else 40))
		"difference_dots": _make_diff_dots(pz, 24 if e else (30 if m else 40))
		"product_lines": _make_path_lines(pz, "pr", 5 if e else (6 if m else 8))
		"difference_lines": _make_path_lines(pz, "df", 6 if e else (7 if m else 9))
		"ratio_lines": _make_path_lines(pz, "rt", 6 if e else (8 if m else 10))
		"prime_composite": _make_marks(pz, variant, 14 if e else (18 if m else 24))
		"forbidden_digit": _make_marks(pz, variant, 20 if e else (28 if m else 36))
		"divisibility": _make_marks(pz, variant, 14 if e else (18 if m else 24))
		"parity_regions": _make_areas(pz, 6 if e else (8 if m else 10))
		"missing_digit": _make_outer(pz, "md", ["L", "R", "T", "B"], 16 if e else (22 if m else 30))
		"wordoku": pz.word = WORDS[rng.randi_range(0, WORDS.size() - 1)]



## Expert with the fewest given digits: more and more clues on the same solution until the clues
## (almost) solve the grid alone; keeps the try with the fewest digits.
## Picture puzzle: a named drawing (Shapes.PICTURES_*) or a symmetric design becomes the lines, then the
## solver finds digits that fit; the givens are removed as usual.
func _attempt_picture(pz: Puzzle, id: String, variant: String, difficulty: String, empty: PackedInt32Array) -> Puzzle:
	var t: String = PICTURE[variant]
	var library := picture_library(t, _n)
	var hand: float = PIC_HAND.get(_n, 0.6)
	var plan := _planned_picture(library, id, difficulty, hand)   # pack builds: this slot's picture, or [null]
	var want_gen := (not plan.is_empty() and plan[0] == null) if pic_plan >= 0 else rng.randf() >= hand
	if library.is_empty():
		want_gen = true
	var gen_fails := 0
	for tries in 12:
		var title := ""
		var paths: Array = []
		var is_gen := false
		if not plan.is_empty() and plan[0] != null and tries < 5:   # 5 goes at the planned picture
			title = plan[0][0]
			paths = Shapes.transform(Shapes.parse(plan[0][1], _n), plan[1], _n)
		elif (want_gen and gen_fails < 3) or library.is_empty():
			# a generated design; strict rules (whispers, lockout …) rarely fit one, so after 3 misses
			# a hand-drawn picture that is known to fit takes its place
			var pr: Array = Shapes.procedural(rng, _n)
			title = pr[0]
			paths = pr[1]
			is_gen = true
			if Shapes.has_cross(paths, _n):   # no + or X shapes in the pictures
				gen_fails += 1
				continue
		else:
			var pic: Array = library[rng.randi_range(0, library.size() - 1)]
			title = pic[0]
			paths = Shapes.transform(Shapes.parse(pic[1], _n), 1 if rng.randf() < 0.5 else 0, _n)   # mirror only: pictures stay upright
		var lines := _picture_lines(pz, paths, t)
		if lines.size() < 3:
			continue
		pz.thermos = []
		pz.lines = []
		for cells in lines:
			if t == "th":
				pz.thermos.append(cells)
			else:
				pz.lines.append({"t": t, "cells": cells})
		var sol := Solver.new(pz).solve(empty, rng, PIC_NODES_GEN if is_gen else PIC_NODES)
		if sol.size() != _nc:
			if is_gen:
				gen_fails += 1
			continue
		pz.solution = sol
		pz.title = title
		pz.givens = sol.duplicate()
		if difficulty == "expert" and EXPERT_GOAL.has(variant):
			_reduce(pz, 0, EXPERT_NODES)   # the picture alone should (nearly) solve it
		else:
			_reduce(pz, target(id, difficulty), int(REDUCE_NODES.get(variant, NODE_LIMIT)))
		return pz
	return null


## Pack plan (pic_plan >= 0): [picture, mirror] for this slot, [null] for a generated design, [] = no plan.
## Out of every 10 slots the first round(10 * hand) are pictures; pictures go through a shuffled order of the
## library (reshuffled each cycle, never the same one twice in a row), mirrored on every other cycle.
func _planned_picture(library: Array, id: String, difficulty: String, hand: float) -> Array:
	if pic_plan < 0 or library.is_empty():
		return []
	var per10 := int(round(10.0 * hand))
	if pic_plan % 10 >= per10:
		return [null]
	var h := (pic_plan / 10) * per10 + pic_plan % 10   # number of this picture slot
	var cycle := h / library.size()
	var order := _pic_order(library.size(), id, difficulty, cycle)
	return [library[order[h % library.size()]], cycle % 2]


static func _pic_order(n: int, id: String, difficulty: String, cycle: int) -> Array:
	var order: Array = range(n)
	var r := RandomNumberGenerator.new()
	r.seed = absi(hash("%s:%s:%d" % [id, difficulty, cycle]))
	for i in range(n - 1, 0, -1):
		var j := r.randi_range(0, i)
		var t = order[i]; order[i] = order[j]; order[j] = t
	if cycle > 0 and n > 1 and order[0] == _pic_order(n, id, difficulty, cycle - 1)[-1]:
		var t = order[0]; order[0] = order[1]; order[1] = t
	return order


static var _pic_table = null   # res://puzzles/pictures.json: grid size -> line type -> picture names that fit


## The hand-drawn pictures that suit line type t on an n x n grid (tools/build_picture_table.gd measured
## which ones the rule can satisfy); all of them if the table is missing.
static func picture_library(t: String, n: int) -> Array:
	var lib: Array = Shapes.PICTURES_9 if n == 9 else Shapes.PICTURES_6
	if _pic_table == null:
		_pic_table = {}
		if FileAccess.file_exists("res://puzzles/pictures.json"):
			var data = JSON.parse_string(FileAccess.get_file_as_string("res://puzzles/pictures.json"))
			if data is Dictionary:
				_pic_table = data
	var ok: Array = _pic_table.get(str(n), {}).get(t, [])
	if ok.is_empty() and not _pic_table.has(str(n)):
		return lib
	return lib.filter(func(pic): return ok.has(pic[0]))


## Cuts the picture's paths to the line type's length limits (pieces meet end to end), turns some around
## and drops lines a rule can't use (region sum / product lines must cross a box border).
func _picture_lines(pz: Puzzle, paths: Array, t: String) -> Array:
	var mx: int = mini(int(PIC_MAX.get(t, _n)), _n if t in ["th", "rb"] else 99)
	if _n == 6:
		mx = mini(mx, {"nb": 3, "da": 5}.get(t, 6))
	var mn: int = PIC_MIN.get(t, 2)
	var out: Array = []
	for p in paths:
		var path: Array = p.duplicate()
		var flip := rng.randi_range(0, 1)
		var pieces := 1
		while (path.size() - 1) / float(pieces) > mx - 1:
			pieces += 1
		var step := float(path.size() - 1) / pieces
		for k in pieces:
			var a := int(round(k * step))
			var b := int(round((k + 1) * step))
			var cells: Array = path.slice(a, b + 1)
			if (k + flip) % 2 == 1:
				cells.reverse()   # pieces alternate direction: a cut line never chains into one long thermometer
			if t == "zp" and cells.size() % 2 == 0:
				cells.pop_back()   # a zipper needs a middle cell
			if cells.size() < mn:
				continue
			if t in ["rs", "pr"]:
				var boxes := {}
				for c in cells: boxes[pz.regions[c]] = true
				if boxes.size() < 2:
					continue
			out.append(cells)
	return out


func _attempt_fewest(pz: Puzzle, variant: String) -> Puzzle:
	var goal: int = EXPERT_GOAL[variant]   # (the rule, also for Mini)
	var best: Puzzle = null
	var keep_sums: Array = pz.sums.duplicate(true)   # magic-square lines are part of the setup, not clues
	for boost in EXPERT_BOOSTS:
		_clear_clues(pz)
		pz.sums = keep_sums.duplicate(true)
		_boost = boost
		_make_clues(pz, variant, "hard")
		_boost = 1.0
		if variant == "pulse" and pz.marks.size() < 2:
			continue
		pz.givens = pz.solution.duplicate()
		_reduce(pz, 0, maxi(EXPERT_NODES, int(REDUCE_NODES.get(variant, 0))))
		if best == null or pz.given_count() < best.given_count():
			best = Puzzle.from_dict(pz.to_dict())
		if pz.given_count() <= goal:
			break
	return best


func _clear_clues(pz: Puzzle) -> void:
	pz.cages = []
	pz.thermos = []
	pz.arrows = []
	pz.edges = {}
	pz.negative = false
	pz.parity = {}
	pz.lines = []
	pz.outer = []
	pz.sums = []
	pz.twists = []
	pz.quads = []
	pz.marks = {}
	pz.vertices = []
	pz.slings = []
	pz.clones = []
	pz.areas = []


func _scaled(n: int) -> int:
	return int(ceil(n * _boost * _nc / 81.0))   # Mini grids get fewer clues for their 36 cells



## Ratio dots: "/N" where one cell is N times the other.
func _make_ratio_dots(pz: Puzzle, n: int) -> void:
	n = _scaled(n)
	var pairs := _edge_pairs()
	_shuffle(pairs)
	for pr in pairs:
		if pz.edges.size() >= n:
			break
		var a: int = pz.solution[pr[0]]
		var b: int = pz.solution[pr[1]]
		if maxi(a, b) % mini(a, b) == 0:
			pz.edges[Puzzle.edge_key(pr[0], pr[1])] = "/%d" % (maxi(a, b) / mini(a, b))


## Difference dots: "-N", the two cells differ by N.
func _make_diff_dots(pz: Puzzle, n: int) -> void:
	n = _scaled(n)
	var pairs := _edge_pairs()
	_shuffle(pairs)
	for k in mini(n, pairs.size()):
		pz.edges[Puzzle.edge_key(pairs[k][0], pairs[k][1])] = "-%d" % absi(pz.solution[pairs[k][0]] - pz.solution[pairs[k][1]])


## Even-Odd Regions: connected areas (3-6 cells) whose digits are all even or all odd.
func _make_areas(pz: Puzzle, n: int) -> void:
	n = _scaled(n)
	var sol := pz.solution
	var used := {}
	var tries := 0
	while pz.areas.size() < n and tries < 2000:
		tries += 1
		var start := rng.randi_range(0, _nc - 1)
		if used.has(start):
			continue
		var par: int = sol[start] % 2
		var cells: Array = [start]
		var want := rng.randi_range(3, 6)
		var frontier: Array = _orth(start)
		while cells.size() < want and not frontier.is_empty():
			var c: int = frontier.pop_at(rng.randi_range(0, frontier.size() - 1))
			if used.has(c) or cells.has(c) or sol[c] % 2 != par:
				continue
			cells.append(c)
			frontier += _orth(c)
		if cells.size() < 3:
			continue
		for c in cells:
			used[c] = true
		cells.sort()
		pz.areas.append({"cells": cells, "t": "e" if par == 0 else "o"})
