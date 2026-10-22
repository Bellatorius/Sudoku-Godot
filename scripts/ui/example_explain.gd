class_name ExampleExplain
extends RefCounted
## Turns a solved example into short "this is the idea" notes for the example popup: each note has
## the cells to highlight and a sentence using the example's real digits.
##   explain(pz) -> [{cells: Array[int], text: String}, ...]   (variant idea first, up to ~6 notes)

static var _n := 9   # grid size of the example (6 for Mini)


static func explain(pz: Puzzle) -> Array:
	_n = pz.size
	var sol := pz.solution
	var out: Array = []
	var dg := func(cells: Array) -> Array: return cells.map(func(c): return sol[c])
	var j := func(cells: Array, sep: String) -> String: return sep.join(PackedStringArray(cells.map(func(c): return str(sol[c]))))
	var plus := func(cells: Array) -> String: return j.call(cells, " + ")
	var total := func(cells: Array) -> int:
		var s := 0
		for c in cells: s += sol[c]
		return s

	for cg in pz.cages.slice(0, 3):
		match str(cg.get("op", "+")):
			"*": out.append({"cells": cg.cells, "text": "This cage: %s = %d." % [j.call(cg.cells, " × "), cg.sum]})
			"-": out.append({"cells": cg.cells, "text": "This cage: %d − %d = %d." % [maxi(sol[cg.cells[0]], sol[cg.cells[1]]), mini(sol[cg.cells[0]], sol[cg.cells[1]]), cg.sum]})
			"/": out.append({"cells": cg.cells, "text": "This cage: %d ÷ %d = %d." % [maxi(sol[cg.cells[0]], sol[cg.cells[1]]), mini(sol[cg.cells[0]], sol[cg.cells[1]]), cg.sum]})
			_: out.append({"cells": cg.cells, "text": "This cage: %s = %d, with no digit repeated." % [plus.call(cg.cells), cg.sum]})
	for t in pz.thermos.slice(0, 3):
		out.append({"cells": t, "text": "From the bulb the digits rise: %s." % j.call(t, " < ")})
	for a in pz.arrows.slice(0, 3):
		out.append({"cells": [a.circle] + a.line, "text": "The circle %d equals the arrow's digits: %s." % [sol[a.circle], plus.call(a.line)]})

	var groups := {}
	for ln in pz.lines:
		var cells: Array = ln.cells
		match str(ln.t):
			"gw": out.append({"cells": cells, "text": "Neighbours on the green line differ by at least 5: %s." % j.call(cells, " · ")})
			"dw": out.append({"cells": cells, "text": "Neighbours on the orange line differ by at least 4: %s." % j.call(cells, " · ")})
			"rb":
				var d: Array = dg.call(cells); d.sort()
				out.append({"cells": cells, "text": "A set of consecutive digits in any order: %s (%d to %d)." % [j.call(cells, " "), d[0], d[-1]]})
			"pal": out.append({"cells": cells, "text": "Reads the same both ways: %s." % j.call(cells, " ")})
			"bt":
				var inner: Array = cells.slice(1, cells.size() - 1)
				out.append({"cells": cells, "text": "Inside digits %s lie between the circles %d and %d." % [j.call(inner, ", "), sol[cells[0]], sol[cells[-1]]]})
			"lo":
				var inner: Array = cells.slice(1, cells.size() - 1)
				out.append({"cells": cells, "text": "Ends %d and %d differ by 4 or more; inside digits %s stay outside that range." % [sol[cells[0]], sol[cells[-1]], j.call(inner, ", ")]})
			"st": out.append({"cells": cells, "text": "Never goes down from the bulb: %s." % j.call(cells, " ≤ ")})
			"bi": out.append({"cells": cells, "text": "No digit repeats on the bishop line: %s." % j.call(cells, " ")})
			"zp":
				var m: int = cells.size() / 2
				var parts: Array = []
				for k in range(1, m + 1):
					parts.append("%d + %d" % [sol[cells[m - k]], sol[cells[m + k]]])
				out.append({"cells": cells, "text": "The middle %d = %s." % [sol[cells[m]], " = ".join(PackedStringArray(parts))]})
			"rs":
				var pieces: Array = [[]]
				for i in cells.size():
					if i > 0 and pz.regions[cells[i]] != pz.regions[cells[i - 1]]:
						pieces.append([])
					pieces[-1].append(cells[i])
				out.append({"cells": cells, "text": "Every box piece sums to %d: %s." % [total.call(pieces[0]), " | ".join(PackedStringArray(pieces.map(func(p): return plus.call(p))))]})
			"en": out.append({"cells": cells, "text": "Any 3 in a row hold one low (%s), one middle (%s), one high (%s): %s." % ((["1-2", "3-4", "5-6"] if _n == 6 else ["1-3", "4-6", "7-9"]) + [j.call(cells, " ")])})
			"mo": out.append({"cells": cells, "text": "Any 3 in a row have different remainders ÷ 3: %s." % j.call(cells, " ")})
			"pa": out.append({"cells": cells, "text": "Odd and even alternate: %s." % j.call(cells, " ")})
			"nb": out.append({"cells": cells, "text": "No two are equal or consecutive: %s." % j.call(cells, " ")})
			"tn":
				var pieces: Array = []
				var run: Array = []
				var s := 0
				for c in cells:
					run.append(c); s += sol[c]
					if s == 10:
						pieces.append(plus.call(run)); run = []; s = 0
				out.append({"cells": cells, "text": "The line splits into pieces of 10: %s." % " | ".join(PackedStringArray(pieces))})
			"da":
				var inner: Array = cells.slice(1, cells.size() - 1)
				out.append({"cells": cells, "text": "The circles %d + %d = %s, the digits between them." % [sol[cells[0]], sol[cells[-1]], plus.call(inner)]})
			"pl":
				var arrow: Array = cells.slice(2)
				out.append({"cells": cells, "text": "The pill reads %d%d = %s along the arrow." % [sol[cells[0]], sol[cells[1]], plus.call(arrow)]})
			"pr":
				var pieces: Array = [[]]
				for i in cells.size():
					if i > 0 and pz.regions[cells[i]] != pz.regions[cells[i - 1]]:
						pieces.append([])
					pieces[-1].append(cells[i])
				out.append({"cells": cells, "text": "Every box piece has the same product: %s." % " | ".join(PackedStringArray(pieces.map(func(pc): return j.call(pc, " × "))))})
			"df": out.append({"cells": cells, "text": "Neighbours all differ by %d: %s." % [absi(sol[cells[1]] - sol[cells[0]]), j.call(cells, " ")]})
			"rt": out.append({"cells": cells, "text": "Every neighbour pair is 2:1: %s." % j.call(cells, " ")})
			"rf":
				var g := int(ln.get("g", 0))
				if not groups.has(g): groups[g] = []
				groups[g].append(cells)
	for g in groups:
		var ls: Array = groups[g]
		if ls.size() >= 2:
			out.append({"cells": ls[0] + ls[1], "text": "Lines with the same symbol read alike from it: %s and %s." % [j.call(ls[0], " "), j.call(ls[1], " ")]})

	for o in pz.outer.slice(0, 6):
		var cells := Array(Solver.outer_cells(o.s, o.i, _n))
		var a := PackedInt32Array(dg.call(cells))
		var where := ("row %d" % (o.i + 1)) if o.s in ["L", "R"] else ("column %d" % (o.i + 1))
		var side_name: String = {"L": "the left", "R": "the right", "T": "the top", "B": "the bottom"}[o.s]
		match str(o.t):
			"sw":
				var i1 := a.find(1); var i9 := a.find(_n)
				var mid: Array = cells.slice(mini(i1, i9) + 1, maxi(i1, i9))
				out.append({"cells": cells.slice(mini(i1, i9), maxi(i1, i9) + 1), "text": "In %s, between the 1 and the %d: %s = %d." % [where, _n, plus.call(mid) if not mid.is_empty() else "nothing", o.v]})
			"sk":
				var seen: Array = []
				var mx := 0
				for k in _n:
					if a[k] > mx: seen.append(cells[k]); mx = a[k]
				out.append({"cells": seen, "text": "From %s you see %d buildings in %s: %s (taller hide shorter)." % [side_name, o.v, where, j.call(seen, ", ")]})
			"xs":
				out.append({"cells": cells.slice(0, a[0]), "text": "The first digit is %d, so the first %d cells add up: %s = %d." % [a[0], a[0], plus.call(cells.slice(0, a[0])), o.v]})
			"fs":
				out.append({"cells": cells.slice(0, 3), "text": "The first three from %s: %s = %d." % [side_name, plus.call(cells.slice(0, 3)), o.v]})
			"nr":
				out.append({"cells": [cells[0], cells[a[0] - 1]], "text": "The first digit is %d, so the %s cell from %s holds the clue %d." % [a[0], _ordinal(a[0]), side_name, o.v]})
			"ro":
				var w: String = ["neither go up nor down", "go up", "go down"][[0, 1, -1].find(int(o.v))]
				out.append({"cells": cells.slice(0, 3), "text": "The first three from %s %s: %s." % [side_name, w, j.call(cells.slice(0, 3), " ")]})
			"as":
				out.append({"cells": cells, "text": "%s has %d ascending runs: %s." % [where.capitalize(), o.v, j.call(cells, " ")]})
			"rn":
				var run: Array = []
				for k in _n:
					if (k > 0 and absi(a[k] - a[k - 1]) == 1) or (k < _n - 1 and absi(a[k] - a[k + 1]) == 1):
						run.append(cells[k])
				out.append({"cells": run, "text": "%d cells of %s sit in a ±1 run: %s." % [o.v, where, j.call(run, ", ")]})
			"md":
				out.append({"cells": cells.slice(0, 3), "text": "The first three from %s are %s: no %d among them." % [side_name, j.call(cells.slice(0, 3), ", "), o.v]})
			"bf":
				var x := a[0]; var y := a[8]
				var lo := 9 - y if x + y > 9 else x
				var hi := x if x + y > 9 else 9 - y
				var part: Array = cells.slice(lo, hi)
				out.append({"cells": [cells[0], cells[8]] + part, "text": "Armies %d and %d %s: %s = %d." % [x, y, "overlap" if x + y > 9 else "leave a gap", plus.call(part) if not part.is_empty() else "nothing", o.v]})

	for sm in pz.sums.slice(0, 3):
		if sm.o.is_empty():
			out.append({"cells": sm.cells, "text": "This line of the magic square: %s = 15." % plus.call(sm.cells)})
		else:
			out.append({"cells": sm.cells, "text": "The arrow's diagonal: %s = %d, no repeats." % [plus.call(sm.cells), sm.sum]})

	var edge_count := 0
	for key in pz.edges:
		if edge_count >= 4:
			break
		var parts: PackedStringArray = key.split(",")
		var a := int(parts[0]); var b := int(parts[1])
		var x: int = sol[a]; var y: int = sol[b]
		var t: String = pz.edges[key]
		var text := ""
		match t:
			"w": text = "White dot: %d and %d are consecutive." % [x, y]
			"b": text = "Black dot: %d is double %d." % [maxi(x, y), mini(x, y)]
			"x": text = "X: %d + %d = 10." % [x, y]
			"v": text = "V: %d + %d = 5." % [x, y]
			"c": text = "Bar: %d and %d are consecutive." % [x, y]
			">", "<": text = "The sign points to the smaller digit: %d %s %d." % [x, t, y]
			"s": text = "Tilde: %d and %d have the same parity." % [x, y]
			"d": text = "Crossed tilde: %d and %d have different parity." % [x, y]
			_:
				if t.begins_with("+"): text = "+%s: %d + %d." % [t.substr(1), x, y]
				elif t.begins_with("/"): text = "1:%s dot: %d is %s times %d." % [t.substr(1), maxi(x, y), t.substr(1), mini(x, y)]
				elif t.begins_with("-"): text = "Difference %s: %d and %d." % [t.substr(1), x, y]
				elif t.begins_with("*"): text = "×%s: %d × %d." % [t.substr(1), x, y]
		if text != "":
			out.append({"cells": [a, b], "text": text})
			edge_count += 1
	if pz.negative and not pz.edges.is_empty():   # the missing marks say something too
		for a in _n * _n - 1:
			var b := a + 1
			if a % _n < _n - 1 and not pz.edges.has(Puzzle.edge_key(a, b)):
				var what: String = {"kropki": "not consecutive and not double", "xv": "don't sum to 5 or 10",
					"consecutive": "aren't consecutive"}.get(pz.rule, "")
				if what != "":
					out.append({"cells": [a, b], "text": "No mark between %d and %d: they %s." % [sol[a], sol[b], what]})
				break

	var par := 0
	for k in pz.parity:
		if par >= 2: break
		out.append({"cells": [int(k)], "text": ("Square: %d is even." if pz.parity[k] == "e" else "Circle: %d is odd.") % sol[int(k)]})
		par += 1

	var marks := 0
	for k in pz.marks:
		if marks >= 3: break
		var m := int(k)
		var r := m / _n; var c := m % _n
		var nb := _orth(m)
		match str(pz.marks[k]):
			"ax":
				var diag: Array = [m]
				for dv in [[1, 1], [1, -1], [-1, 1], [-1, -1]]:
					var rr: int = r + dv[0]; var cc: int = c + dv[1]
					while rr >= 0 and rr <= 8 and cc >= 0 and cc <= 8:
						diag.append(rr * 9 + cc); rr += dv[0]; cc += dv[1]
				out.append({"cells": diag, "text": "The %d doesn't appear again on its two diagonals." % sol[m]})
			"fr":
				var why := "its row number" if sol[m] == r + 1 else ("its column number" if sol[m] == c + 1 else "its box number")
				out.append({"cells": [m], "text": "The heart holds %d: %s." % [sol[m], why]})
			"pm": out.append({"cells": [m], "text": "P: %d is prime." % sol[m]})
			"cm": out.append({"cells": [m], "text": "C: %d is composite." % sol[m]})
			"d2", "d3", "d4": out.append({"cells": [m], "text": "÷%s: %d divides by %s." % [str(pz.marks[k])[1], sol[m], str(pz.marks[k])[1]]})
			_ when str(pz.marks[k]).begins_with("x"): out.append({"cells": [m], "text": "The crossed-out %s can't go here; the cell is %d." % [str(pz.marks[k])[1], sol[m]]})
			"pu": out.append({"cells": [m] + nb, "text": "Pulse %d: its neighbours %s are ±1, a divisor or a multiple." % [sol[m], j.call(nb, ", ")]})
			"fo": out.append({"cells": [m] + nb, "text": "The grey %d is bigger than its white neighbours." % sol[m]})
			"mn": out.append({"cells": [m] + nb, "text": "MIN %d is smaller than all its neighbours %s." % [sol[m], j.call(nb, ", ")]})
			"mx": out.append({"cells": [m] + nb, "text": "MAX %d is bigger than all its neighbours %s." % [sol[m], j.call(nb, ", ")]})
			"ih", "ihv" when sol[m] != c + 1: out.append({"cells": [m, r * 9 + sol[m] - 1], "text": "Arrow %d in column %d: column %d of this row holds %d." % [sol[m], c + 1, sol[m], c + 1]})
			"iv" when sol[m] != r + 1: out.append({"cells": [m, (sol[m] - 1) * 9 + c], "text": "Arrow %d in row %d: row %d of this column holds %d." % [sol[m], r + 1, sol[m], r + 1]})
		marks += 1

	for ar in pz.areas.slice(0, 2):
		out.append({"cells": ar.cells, "text": "%s area: %s, all %s." % ["Even" if ar.t == "e" else "Odd", j.call(ar.cells, " "), "even" if ar.t == "e" else "odd"]})
	for q in pz.quads.slice(0, 2):
		var t: int = q.c
		var four: Array = [t, t + 1, t + _n, t + _n + 1]
		out.append({"cells": four, "text": "Circle %s: those digits appear around it (%s)." % [" ".join(PackedStringArray(q.d.map(func(x): return str(x)))), j.call(four, " ")]})
	for t in pz.twists.slice(0, 2):
		out.append({"cells": [t, t + 1, t + 9, t + 10], "text": "Square: both diagonal pairs are consecutive (%d-%d and %d-%d)." % [sol[t], sol[t + 10], sol[t + 1], sol[t + 9]]})
	for vx in pz.vertices.slice(0, 2):
		var tip: int = sol[vx.tip]; var x: int = sol[vx.a]; var y: int = sol[vx.b]
		out.append({"cells": [vx.tip, vx.a, vx.b], "text": "Tip %d = %s." % [tip, ("%d + %d" % [x, y]) if tip == x + y else ("%d - %d" % [maxi(x, y), mini(x, y)])]})
	for sl in pz.slings.slice(0, 2):
		var n: int = sol[sl.a]
		var tgt: int = (sl.a / 9 + sl.dir[0] * n) * 9 + sl.a % 9 + sl.dir[1] * n
		out.append({"cells": [sl.s, sl.a, tgt], "text": "Arrow %d: the %d it comes from appears again %d cells further on." % [n, sol[sl.s], n]})
	for cl in pz.clones.slice(0, 2):
		out.append({"cells": cl.a + cl.b, "text": "Same shape, same digits: %s and %s." % [j.call(cl.a, " "), j.call(cl.b, " ")]})

	# rules without clues: show them on a cell of the example
	var mid_rc := _n / 2 - (1 if _n == 6 else 0)   # a cell near the middle (Mini: row/column 3)
	var centre := mid_rc * _n + mid_rc
	match pz.rule:
		"diagonal":
			var d: Array = range(0, _n * _n, _n + 1)
			out.append({"cells": d, "text": "The main diagonal holds 1 to %d once: %s." % [_n, j.call(d, " ")]})
		"king", "knight", "miracle", "non_consecutive":
			var near: Array = []
			if pz.rule != "non_consecutive":
				var moves: Array = [[-1, -1], [-1, 1], [1, -1], [1, 1]] if pz.rule != "knight" else []
				if pz.rule != "king":
					moves += [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]]
				for mv in moves:
					near.append((mid_rc + mv[0]) * _n + mid_rc + mv[1])
			var text := "None of these cells repeats the %d in the middle." % sol[centre]
			if pz.rule == "non_consecutive" or pz.rule == "miracle":
				near += _orth(centre)
				var sides: String = j.call(_orth(centre), ", ")
				var cons := _consecutive_of(sol[centre])
				if pz.rule == "miracle":
					text = "Around the %d: no repeat a king's or knight's move away, and its side neighbours %s aren't %s." % [sol[centre], sides, cons]
				else:
					text = "The %d's side neighbours %s are never %s." % [sol[centre], sides, cons]
			out.append({"cells": [centre] + near, "text": text})
		"windoku":
			var w: Array = []
			for k in 9: w.append((1 + k / 3) * 9 + 1 + k % 3)
			out.append({"cells": w, "text": "Each shaded window holds 1 to 9 once: %s." % j.call(w, " ")})
		"universal":
			var u: Array = []
			for b in 9: u.append(((b / 3) * 3) * 9 + (b % 3) * 3)
			out.append({"cells": u, "text": "The top-left cell of every box: %s, all different." % j.call(u, " ")})
		"center_dot", "asterisk", "girandola":
			var rg: Array = {"center_dot": [10, 13, 16, 37, 40, 43, 64, 67, 70], "asterisk": Solver.ASTERISK, "girandola": Solver.GIRANDOLA}[pz.variant]
			out.append({"cells": rg, "text": "The shaded cells hold 1 to 9 once: %s." % j.call(rg, " ")})
		"argyle":
			var ln: Array = Solver.ARGYLE[0]
			var cells: Array = []
			for k in ln[2]: cells.append(ln[0] + ln[1] * k)
			out.append({"cells": cells, "text": "No repeats on an argyle line: %s." % j.call(cells, " ")})
		"queen":
			var nines: Array = range(81).filter(func(c): return sol[c] == 9)
			out.append({"cells": nines, "text": "No two 9s share a diagonal (or a row, column, box)."})
		"anti_diagonal":
			var d: Array = range(0, 81, 10)
			var u := {}
			for c in d: u[sol[c]] = true
			out.append({"cells": d, "text": "The diagonal uses only 3 digits: %s." % ", ".join(PackedStringArray(u.keys().map(func(x): return str(x))))})
		"dutch_flatmates":
			for c in range(9, 72):
				if sol[c] == 5:
					var who: Array = [c]
					if sol[c - 9] == 1: who.append(c - 9)
					if sol[c + 9] == 9: who.append(c + 9)
					out.append({"cells": who, "text": "This 5 has a 1 above it or a 9 below it."})
					break
		"jigsaw", "toroidal":
			var rg: Array = range(_n * _n).filter(func(c): return pz.regions[c] == pz.regions[0])
			out.append({"cells": rg, "text": "This region holds 1 to %d once%s." % [_n, " (it wraps around the edge)" if pz.rule == "toroidal" else ""]})

	if out.is_empty() or pz.rule == "classic":
		var box: Array = range(_n * _n).filter(func(c): return pz.regions[c] == pz.regions[0])
		var shown := " ".join(PackedStringArray(box.map(func(c): return Board.glyph_for(pz, sol[c]))))
		match pz.variant:
			"color": out.append({"cells": box, "text": "Every row, column and box holds each of the nine colours once."})
			"alphabet", "wordoku", "symbol", "roman":
				out.append({"cells": box, "text": "Every row, column and box holds each of the nine once: %s." % shown})
			_: out.append({"cells": box, "text": "Every row, column and box holds 1 to %d once: %s." % [_n, shown]})
	return out.slice(0, 6)


static func _orth(i: int) -> Array:
	var r := i / _n
	var c := i % _n
	var out: Array = []
	if r > 0: out.append(i - _n)
	if r < _n - 1: out.append(i + _n)
	if c > 0: out.append(i - 1)
	if c < _n - 1: out.append(i + 1)
	return out


## "5 or 7", or just "2" for 1 / "8" for 9.
static func _consecutive_of(d: int) -> String:
	if d == 1: return "2"
	if d == _n: return str(_n - 1)
	return "%d or %d" % [d - 1, d + 1]


static func _ordinal(n: int) -> String:
	return str(n) + ({1: "st", 2: "nd", 3: "rd"}.get(n, "th") as String)
