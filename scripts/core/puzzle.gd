class_name Puzzle
extends RefCounted
## A 9x9 puzzle definition. Cells are indexed 0..80 (row * 9 + col).
##
## JSON format (used by puzzle packs in res://puzzles/*.json):
## {
##   "id": "thermo-e-001", "variant": "thermo", "difficulty": "easy",
##   "givens":   "0030...",   81 chars, 0 = empty
##   "solution": "4836...",   81 chars (optional for hand-made puzzles: solved on load)
##   "regions":  "0001112...", 81 chars, region id per cell (optional; default 3x3 boxes)
##   "diagonals": true,
##   "cages":   [{"cells": [0, 1, 9], "sum": 14}],
##   "thermos": [[10, 11, 12]],            bulb first
##   "arrows":  [{"circle": 40, "line": [41, 42]}],
##   "edges":   {"3,4": "w", "12,21": "b", "5,6": "x", "30,31": "v"},
##   "negative": true,                      all possible dots / X / V are shown
##   "parity":  {"12": "e", "40": "o"},      Even-Odd: e = even (square), o = odd (circle)
##   "lines":   [{"t": "gw", "cells": [3, 4, 13]}]   line clues, in order along the line:
##              gw German Whispers (neighbours differ >= 5), dw Dutch Whispers (>= 4), rb Renban,
##              pal Palindrome, bt Between (ends = circles), lo Lockout (ends = squares),
##              st Slow Thermo (bulb first), bi Bishop (no repeats), rf Reflection (+ "g": group id;
##              lines of one group carry the same digits from their start)
##   edges also: "c" Consecutive (with negative), ">"/"<" Greater-than (lower-index cell > / < other),
##              "s" same parity, "d" different parity (Couples)
##   "outer":   [{"t": "sw", "s": "L", "i": 3, "v": 12}]  clues outside the grid: sw Sandwich, sk Skyscraper,
##              as Ascending Sequences, rn Running Cells; s = side L/R (rows) or T/B (columns), i = row/col
##   "sums":    [{"cells": [...], "sum": 23, "o": [-1, 2], "dir": [1, 1]}]  Little Killer diagonals
##              (o = the outside cell the clue sits in, dir = arrow direction)
##   "twists":  [10, 33]   Twisted Consecutive: top-left cell of each 2x2 whose corner has a hollow square
##   "quads":   [{"c": 10, "d": [1, 4]}]   Quadruple: circle at the corner below-right of cell c
##   "marks":   {"12": "ax"}  cell marks: ax Axia, fr Friendly, pu Pulse, ih / iv / ihv Index Lookup
##   "vertices":[{"tip": 40, "a": 30, "b": 32}]   Vertex: tip = sum or difference of the arm digits
##   "slings":  [{"s": 39, "a": 40, "dir": [0, 1]}] Slingshot: digit N in cell a means the digit of s
##              repeats N cells beyond a in direction dir
## }
## Rules without clues (Non-consecutive, Anti-King, Anti-Knight) come from the variant id alone.

var id := ""
var variant := "classic"
var difficulty := "medium"
var givens := PackedInt32Array()
var solution := PackedInt32Array()
var regions := PackedInt32Array()
var diagonals := false
var cages: Array = []      # [{cells: Array[int], sum: int}]
var thermos: Array = []    # [Array[int]]
var arrows: Array = []     # [{circle: int, line: Array[int]}]
var edges: Dictionary = {} # "a,b" (a < b) -> "w" | "b" | "x" | "v"
var negative := false
var parity: Dictionary = {}  # cell -> "e" | "o"
var lines: Array = []        # [{t: String, cells: Array[int], g?: int}]
var outer: Array = []        # [{t, s, i, v}]
var sums: Array = []         # [{cells, sum, o, dir}]
var twists: Array = []       # [top-left cell]
var quads: Array = []        # [{c, d: Array[int]}]
var marks: Dictionary = {}   # cell -> "ax" | "fr" | "pu" | "ih" | "iv" | "ihv"
var vertices: Array = []     # [{tip, a, b}]
var slings: Array = []       # [{s, a, dir}]
var twist_gen := false       # generator only: build a solution whose 2x2 diagonals agree (Twisted)


func _init() -> void:
	givens.resize(81)
	solution.resize(81)
	regions = standard_regions()


static func standard_regions() -> PackedInt32Array:
	var r := PackedInt32Array()
	r.resize(81)
	for i in 81:
		r[i] = (i / 27) * 3 + (i % 9) / 3
	return r


static func edge_key(a: int, b: int) -> String:
	return "%d,%d" % [mini(a, b), maxi(a, b)]


func uses_boxes() -> bool:
	return variant != "jigsaw"


func given_count() -> int:
	var n := 0
	for v in givens:
		if v > 0:
			n += 1
	return n


static func _str_to_arr(s: String) -> PackedInt32Array:
	var a := PackedInt32Array()
	a.resize(81)
	for i in mini(81, s.length()):
		var ch := s[i]
		a[i] = 0 if (ch == "." or ch == "0") else int(ch)
	return a


static func _arr_to_str(a: PackedInt32Array) -> String:
	var s := ""
	for v in a:
		s += str(v)
	return s


func to_dict() -> Dictionary:
	var d := {
		"id": id, "variant": variant, "difficulty": difficulty,
		"givens": _arr_to_str(givens), "solution": _arr_to_str(solution),
	}
	if variant == "jigsaw":
		d.regions = _arr_to_str(regions)
	if diagonals:
		d.diagonals = true
	if not cages.is_empty():
		d.cages = cages
	if not thermos.is_empty():
		d.thermos = thermos
	if not arrows.is_empty():
		d.arrows = arrows
	if not edges.is_empty():
		d.edges = edges
		d.negative = negative
	if not parity.is_empty():
		var pd := {}
		for k in parity:
			pd[str(k)] = parity[k]
		d.parity = pd
	if not lines.is_empty():
		d.lines = lines
	for key in ["outer", "sums", "twists", "quads", "vertices", "slings"]:
		var arr: Array = get(key)
		if not arr.is_empty():
			d[key] = arr
	if not marks.is_empty():
		var md := {}
		for k in marks:
			md[str(k)] = marks[k]
		d.marks = md
	return d


static func from_dict(d: Dictionary) -> Puzzle:
	var p := Puzzle.new()
	p.id = str(d.get("id", ""))
	p.variant = str(d.get("variant", "classic"))
	p.difficulty = str(d.get("difficulty", "medium"))
	p.givens = _str_to_arr(str(d.get("givens", "")))
	p.solution = _str_to_arr(str(d.get("solution", "")))
	if d.has("regions"):
		p.regions = _str_to_arr(str(d.regions))
	p.diagonals = bool(d.get("diagonals", p.variant == "diagonal"))
	for c in d.get("cages", []):
		p.cages.append({"cells": _ints(c.cells), "sum": int(c.sum)})
	for t in d.get("thermos", []):
		p.thermos.append(_ints(t))
	for a in d.get("arrows", []):
		p.arrows.append({"circle": int(a.circle), "line": _ints(a.line)})
	var e: Dictionary = d.get("edges", {})
	for k in e:
		var parts := str(k).split(",")
		p.edges[edge_key(int(parts[0]), int(parts[1]))] = str(e[k])
	p.negative = bool(d.get("negative", false))
	var pd: Dictionary = d.get("parity", {})
	for k in pd:
		p.parity[int(k)] = str(pd[k])
	for ln in d.get("lines", []):
		var l2 := {"t": str(ln.t), "cells": _ints(ln.cells)}
		if ln.has("g"):
			l2.g = int(ln.g)
		p.lines.append(l2)
	for o in d.get("outer", []):
		p.outer.append({"t": str(o.t), "s": str(o.s), "i": int(o.i), "v": int(o.v)})
	for sm in d.get("sums", []):
		p.sums.append({"cells": _ints(sm.cells), "sum": int(sm.sum), "o": _ints(sm.o), "dir": _ints(sm.dir)})
	p.twists = _ints(d.get("twists", []))
	for q in d.get("quads", []):
		p.quads.append({"c": int(q.c), "d": _ints(q.d)})
	var md: Dictionary = d.get("marks", {})
	for k in md:
		p.marks[int(k)] = str(md[k])
	for v in d.get("vertices", []):
		p.vertices.append({"tip": int(v.tip), "a": int(v.a), "b": int(v.b)})
	for sl in d.get("slings", []):
		p.slings.append({"s": int(sl.s), "a": int(sl.a), "dir": _ints(sl.dir)})
	# Hand-made puzzles may omit the solution — solve it now.
	if p.solution.count(0) > 0:
		var sol := Solver.new(p).solve(p.givens)
		if sol.size() == 81:
			p.solution = sol
	return p


static func _ints(a) -> Array:
	var out: Array = []
	for v in a:
		out.append(int(v))
	return out
