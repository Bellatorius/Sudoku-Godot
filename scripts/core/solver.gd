class_name Solver
extends RefCounted
## Bitmask backtracking solver (MRV heuristic) supporting:
## rows/cols/regions, diagonals, killer cages, thermometers, arrows,
## Kropki dots and XV (with optional negative constraint), Even-Odd cells,
## line clues (whispers, renban, palindrome, between, lockout, slow thermo, bishop, reflection,
## zipper), outside clues (sandwich, skyscraper, X-sum, ascending, running cells), little killer
## sums, quadruples, cell marks (axia, friendly, pulse, index), vertices, slingshots, extra units
## (universal, windoku) and the clue-less global rules (non-consecutive, anti-king/knight,
## dutch flatmates, twisted consecutive).
## Also provides rule-conflict detection for the game UI.

const ALL := 0x3FE  # bits 1..9
const EVEN := (1 << 2) | (1 << 4) | (1 << 6) | (1 << 8)
const ODD := (1 << 1) | (1 << 3) | (1 << 5) | (1 << 7) | (1 << 9)

enum Edge { NONE, WHITE, BLACK, X, V, GT, LT, SAME, DIFF, PULSE, SUMN, PRODN, RATION, DIFFN }

var p: Puzzle
var N := 9            # grid size (6 for Mini)
var NC := 81          # cells
var all_mask := ALL   # bits 1..N
var grid := PackedInt32Array()
var units: Array[PackedInt32Array] = []
var cell_units: Array[PackedInt32Array] = []
var unit_used := PackedInt32Array()

var cell_thermos: Array = []   # per cell: [[thermo_idx, pos], ...]
var cell_arrows: Array = []    # per cell: [[arrow_idx, role]] role -1 = circle, else line pos
var cell_cage := PackedInt32Array()
var cage_unit := PackedInt32Array()  # cage idx -> unit idx
var cell_edges: Array = []     # per cell: [[nbr, Edge], ...]
var neg_types: Array = []      # relations forbidden on edges without a symbol
var has_extra := PackedByteArray()
var cell_mask := PackedInt32Array()   # allowed digits per cell (Even-Odd)
var cell_diff: Array = []             # per cell: cells that may not hold the same digit (king/knight)
var cell_orth: Array = []             # per cell: orthogonal neighbours
var non_consecutive := false          # orthogonal neighbours may not be consecutive
var cell_lines: Array = []            # per cell: [[line_idx, pos], ...]
var cell_eq: Array = []               # per cell: cells that must hold the same digit (palindrome, reflection)
var cell_outer: Array = []            # per cell: outside clue indices
var outer_lines: Array = []           # per outside clue: its 9 cells, read from the clue's side
var cell_sums: Array = []             # per cell: little killer sum indices
var cell_quads: Array = []            # per cell: quadruple indices
var cell_index: Array = []            # per cell: [[marked cell, horizontal?], ...] (index lookup)
var cell_vertex: Array = []           # per cell: vertex indices
var cell_sling: Array = []            # per cell: slingshot indices
var flatmates := false
var anti_diag := false                # Anti-Diagonal: each main diagonal holds only 3 different digits
var queen := false                    # Chess Queen: a 9 never sees another 9 on a diagonal
## Extra 9-cell regions of the fixed-pattern variants (cells listed row by row, 0-based).
const ASTERISK := [13, 20, 24, 37, 40, 43, 56, 60, 67]
const GIRANDOLA := [0, 8, 13, 37, 40, 43, 67, 72, 80]
## Argyle: eight diagonal lines (start cell, step) whose digits can't repeat.
const ARGYLE := [[1, 10, 8], [9, 10, 8], [7, 8, 8], [17, 8, 8], [4, 10, 5], [36, 10, 5], [4, 8, 5], [44, 8, 5]]
var twist_gen := false

var _popc := PackedInt32Array()
var _count := 0
var _limit := 2
var _nodes := 0
var _node_limit := 0
var _aborted := false
var _rng: RandomNumberGenerator = null
var _found := PackedInt32Array()


func _init(puzzle: Puzzle) -> void:
	p = puzzle
	N = p.size
	NC = N * N
	all_mask = ((1 << (N + 1)) - 1) & ~1
	_popc.resize(1024)
	for i in 1024:
		var n := 0
		var x := i
		while x:
			n += x & 1
			x >>= 1
		_popc[i] = n
	_build()


func _add_unit(cells: PackedInt32Array) -> int:
	units.append(cells)
	var u := units.size() - 1
	for c in cells:
		cell_units[c].append(u)
	return u


func _build() -> void:
	cell_units.resize(NC)
	for i in NC:
		cell_units[i] = PackedInt32Array()
	for r in N:
		var row := PackedInt32Array()
		var col := PackedInt32Array()
		for k in N:
			row.append(r * N + k)
			col.append(k * N + r)
		_add_unit(row)
		_add_unit(col)
	var regs: Array[PackedInt32Array] = []
	regs.resize(N)
	for i in N:
		regs[i] = PackedInt32Array()
	for i in NC:
		regs[p.regions[i]].append(i)
	for rg in regs:
		_add_unit(rg if p.rule != "kenken" else PackedInt32Array())   # Mathdoku has no boxes (empty units keep the indices)
	if p.diagonals:
		var d1 := PackedInt32Array()
		var d2 := PackedInt32Array()
		for k in N:
			d1.append(k * N + k)
			d2.append(k * N + (N - 1 - k))
		_add_unit(d1)
		_add_unit(d2)

	cell_cage.resize(NC)
	cell_cage.fill(-1)
	has_extra.resize(NC)
	has_extra.fill(0)
	cell_thermos.resize(NC)
	cell_arrows.resize(NC)
	cell_edges.resize(NC)
	for i in NC:
		cell_thermos[i] = []
		cell_arrows[i] = []
		cell_edges[i] = []

	for ci in p.cages.size():
		var cg: Dictionary = p.cages[ci]
		var cells := PackedInt32Array(cg.cells)
		cage_unit.append(_add_unit(cells))
		for c in cells:
			cell_cage[c] = ci
			has_extra[c] = 1
	for ti in p.thermos.size():
		var t: Array = p.thermos[ti]
		for pos in t.size():
			cell_thermos[t[pos]].append([ti, pos])
			has_extra[t[pos]] = 1
	for ai in p.arrows.size():
		var a: Dictionary = p.arrows[ai]
		cell_arrows[a.circle].append([ai, -1])
		has_extra[a.circle] = 1
		for pos in a.line.size():
			cell_arrows[a.line[pos]].append([ai, pos])
			has_extra[a.line[pos]] = 1

	_build_new_rules()

	if p.rule == "kropki":
		neg_types = [Edge.WHITE, Edge.BLACK]
	elif p.rule == "xv":
		neg_types = [Edge.X, Edge.V]
	elif p.rule == "consecutive" or p.rule == "twisted":
		neg_types = [Edge.WHITE]
	var codes := {"w": Edge.WHITE, "b": Edge.BLACK, "x": Edge.X, "v": Edge.V, "c": Edge.WHITE,
		"s": Edge.SAME, "d": Edge.DIFF}
	if not p.edges.is_empty() or p.negative:
		for i in NC:
			var r := i / N
			var c := i % N
			for nb in [[r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]]:
				if nb[0] < 0 or nb[0] >= N or nb[1] < 0 or nb[1] >= N:
					continue
				var n: int = nb[0] * N + nb[1]
				var key := Puzzle.edge_key(i, n)
				var code: String = p.edges.get(key, "")
				var tcode: int = codes.get(code, Edge.NONE)
				if code.length() > 1 and code[0] in ["+", "*", "/", "-"]:   # dot with a number: sum / product / ratio / difference
					var et: int = {"+": Edge.SUMN, "*": Edge.PRODN, "/": Edge.RATION, "-": Edge.DIFFN}[code[0]]
					cell_edges[i].append([n, et, int(code.substr(1))])
					has_extra[i] = 1
					continue
				if code == ">" or code == "<":   # stored for the lower-index cell
					tcode = Edge.GT if (i < n) == (code == ">") else Edge.LT
				if tcode == Edge.NONE and not p.negative:
					continue
				cell_edges[i].append([n, tcode])
				has_extra[i] = 1


## Even-Odd marks, line clues and the global neighbour rules.
func _build_new_rules() -> void:
	cell_mask.resize(NC)
	cell_mask.fill(all_mask)
	cell_diff.resize(NC)
	cell_orth.resize(NC)
	cell_lines.resize(NC)
	for i in NC:
		cell_diff[i] = []
		cell_orth[i] = []
		cell_lines[i] = []
		var r := i / N
		var c := i % N
		for nb in [[r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]]:
			if nb[0] >= 0 and nb[0] < N and nb[1] >= 0 and nb[1] < N:
				cell_orth[i].append(nb[0] * N + nb[1])
	var moves: Array = []
	if p.rule == "king" or p.rule == "miracle":
		moves = [[-1, -1], [-1, 1], [1, -1], [1, 1]]   # orthogonal ones are already row/column
	if p.rule == "knight" or p.rule == "miracle":
		moves.append_array([[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]])
	for i in NC:
		for mv in moves:
			var r: int = i / N + mv[0]
			var c: int = i % N + mv[1]
			if r >= 0 and r < N and c >= 0 and c < N:
				cell_diff[i].append(r * N + c)
		if not moves.is_empty():
			has_extra[i] = 1
	non_consecutive = p.rule == "non_consecutive" or p.rule == "miracle"
	if non_consecutive:
		has_extra.fill(1)
	queen = p.rule == "queen"
	anti_diag = p.rule == "anti_diagonal"
	if queen or anti_diag:
		has_extra.fill(1)
	var extra_regions: Array = []
	match p.rule:
		"center_dot":
			extra_regions = [[10, 13, 16, 37, 40, 43, 64, 67, 70]]
		"asterisk":
			extra_regions = [ASTERISK]
		"girandola":
			extra_regions = [GIRANDOLA]
		"argyle":
			for ln in ARGYLE:
				var cells: Array = []
				for k in ln[2]:
					cells.append(ln[0] + ln[1] * k)
				extra_regions.append(cells)
	for rg in extra_regions:
		_add_unit(PackedInt32Array(rg))
	for k in p.parity:
		cell_mask[int(k)] = EVEN if p.parity[k] == "e" else ODD
		has_extra[int(k)] = 1
	for arr in [cell_eq, cell_outer, cell_sums, cell_quads, cell_index, cell_vertex, cell_sling]:
		arr.resize(NC)
		for i in NC:
			arr[i] = []
	if p.rule == "universal":   # same position in every box
		for k in 9:
			var u := PackedInt32Array()
			for b in 9:
				u.append(((b / 3) * 3 + k / 3) * 9 + (b % 3) * 3 + k % 3)
			_add_unit(u)
	elif p.rule == "windoku":
		for top in [1, 5]:
			for left in [1, 5]:
				var u := PackedInt32Array()
				for k in 9:
					u.append((top + k / 3) * 9 + left + k % 3)
				_add_unit(u)
	var groups := {}
	for li in p.lines.size():
		var ln: Dictionary = p.lines[li]
		var cells: Array = ln.cells
		if ln.t == "bi":
			_add_unit(PackedInt32Array(cells))
		elif ln.t == "pal":
			for pos in cells.size() / 2:
				_link_eq(cells[pos], cells[cells.size() - 1 - pos])
		elif ln.t == "rf":
			var g: int = int(ln.get("g", 0))
			if not groups.has(g):
				groups[g] = []
			groups[g].append(cells)
		else:
			for pos in cells.size():
				cell_lines[cells[pos]].append([li, pos])
				has_extra[cells[pos]] = 1
	for g in groups:
		var ls: Array = groups[g]
		for a in ls.size():
			for b in range(a + 1, ls.size()):
				for pos in mini(ls[a].size(), ls[b].size()):
					_link_eq(ls[a][pos], ls[b][pos])
	for cl in p.clones:
		for k in mini(cl.a.size(), cl.b.size()):
			_link_eq(cl.a[k], cl.b[k])
	for ar in p.areas:
		for c in ar.cells:
			cell_mask[c] &= EVEN if ar.t == "e" else ODD
			has_extra[c] = 1
	for oi in p.outer.size():
		var cells := outer_cells(p.outer[oi].s, p.outer[oi].i, N)
		outer_lines.append(cells)
		for c in cells:
			cell_outer[c].append(oi)
			has_extra[c] = 1
	for si in p.sums.size():
		var cells: Array = p.sums[si].cells
		_add_unit(PackedInt32Array(cells))
		for c in cells:
			cell_sums[c].append(si)
			has_extra[c] = 1
	for qi in p.quads.size():
		var t: int = p.quads[qi].c
		for c in [t, t + 1, t + N, t + N + 1]:
			cell_quads[c].append(qi)
			has_extra[c] = 1
	for vi in p.vertices.size():
		var vx: Dictionary = p.vertices[vi]
		for c in [vx.tip, vx.a, vx.b]:
			cell_vertex[c].append(vi)
			has_extra[c] = 1
	for si in p.slings.size():
		var sl: Dictionary = p.slings[si]
		var a: int = sl.a
		var dr: int = sl.dir[0]
		var dc: int = sl.dir[1]
		var reach := 0   # cells between the arrow cell and the edge, in the arrow direction
		while true:
			var rr: int = a / 9 + dr * (reach + 1)
			var cc: int = a % 9 + dc * (reach + 1)
			if rr < 0 or rr > 8 or cc < 0 or cc > 8:
				break
			reach += 1
		cell_mask[a] &= (2 << reach) - 2
		var axis: Array = [sl.s]
		for k in 9:
			axis.append((a / 9) * 9 + k if dr == 0 else k * 9 + a % 9)
		for c in axis:
			cell_sling[c].append(si)
			has_extra[c] = 1
	for k in p.marks:
		var m: int = int(k)
		var t: String = p.marks[k]
		var r := m / 9
		var cc := m % 9
		has_extra[m] = 1
		if t == "ax":   # the digit doesn't repeat on either diagonal through the cell
			for dir in [[1, 1], [1, -1], [-1, 1], [-1, -1]]:
				var rr: int = r + dir[0]
				var c2: int = cc + dir[1]
				while rr >= 0 and rr <= 8 and c2 >= 0 and c2 <= 8:
					var n := rr * 9 + c2
					cell_diff[m].append(n)
					cell_diff[n].append(m)
					has_extra[n] = 1
					rr += dir[0]
					c2 += dir[1]
		elif t == "fr":   # row, column or box number
			cell_mask[m] &= (1 << (r + 1)) | (1 << (cc + 1)) | (1 << ((r / 3) * 3 + cc / 3 + 1))
		elif t == "pu":
			cell_mask[m] &= ~2
			for n in cell_orth[m]:
				cell_mask[n] &= ~2
				_add_rel(m, n, Edge.PULSE)
		elif t == "fo":   # Fortress: a grey cell is bigger than its white neighbours
			for n in cell_orth[m]:
				if not p.marks.has(n) or p.marks[n] != "fo":
					_add_dir(m, n)
		elif t == "pm":   # prime
			cell_mask[m] &= (1 << 2) | (1 << 3) | (1 << 5) | (1 << 7)
		elif t == "cm":   # composite
			cell_mask[m] &= (1 << 4) | (1 << 6) | (1 << 8) | (1 << 9)
		elif t.begins_with("x") and t.length() == 2:   # forbidden digit
			cell_mask[m] &= ~(1 << int(t[1]))
		elif t in ["d2", "d3", "d4"]:   # divisible by 2 / 3 / 4
			var q := int(t[1])
			var mask := 0
			for dd in range(q, 10, q):
				mask |= 1 << dd
			cell_mask[m] &= mask
		elif t == "mn" or t == "mx":   # smaller / bigger than every orthogonal neighbour
			for n in cell_orth[m]:
				if t == "mx": _add_dir(m, n)
				else: _add_dir(n, m)
		elif t.begins_with("i"):
			if t.contains("h"):
				for j in 9:
					cell_index[r * 9 + j].append([m, true])
					has_extra[r * 9 + j] = 1
			if t.contains("v"):
				for j in 9:
					cell_index[j * 9 + cc].append([m, false])
					has_extra[j * 9 + cc] = 1
	flatmates = p.rule == "dutch_flatmates"
	twist_gen = p.twist_gen
	if flatmates or twist_gen:
		has_extra.fill(1)
	if p.rule == "twisted" and not twist_gen:
		var tw := {}
		for t in p.twists:
			tw[int(t)] = true
		for r in 8:
			for c in 8:
				var t := r * 9 + c
				var code: int = Edge.WHITE if tw.has(t) else Edge.NONE
				_add_rel(t, t + 10, code)
				_add_rel(t + 1, t + 9, code)


func _link_eq(a: int, b: int) -> void:
	cell_eq[a].append(b)
	cell_eq[b].append(a)
	has_extra[a] = 1
	has_extra[b] = 1


## a must be bigger than b.
func _add_dir(a: int, b: int) -> void:
	cell_edges[a].append([b, Edge.GT])
	cell_edges[b].append([a, Edge.LT])
	has_extra[a] = 1
	has_extra[b] = 1


func _add_rel(a: int, b: int, code: int) -> void:
	cell_edges[a].append([b, code])
	cell_edges[b].append([a, code])
	has_extra[a] = 1
	has_extra[b] = 1


## The 9 cells of an outside clue, in reading order from the clue's side (L/R = row i, T/B = column i).
static func outer_cells(side: String, i: int, n := 9) -> PackedInt32Array:
	var out := PackedInt32Array()
	for k in n:
		match side:
			"L": out.append(i * n + k)
			"R": out.append(i * n + n - 1 - k)
			"T": out.append(k * n + i)
			_: out.append((n - 1 - k) * n + i)
	return out


## The clue value of a full line (9 digits read from the clue side).
static func outer_value(t: String, a: PackedInt32Array) -> int:
	match t:
		"sw":
			var i1 := a.find(1)
			var i9 := a.find(a.size())   # the biggest digit (9, or 6 on Mini)
			var s := 0
			for j in range(mini(i1, i9) + 1, maxi(i1, i9)):
				s += a[j]
			return s
		"sk":
			var vis := 0
			var mx := 0
			for x in a:
				if x > mx:
					vis += 1
					mx = x
			return vis
		"xs":
			var s := 0
			for j in a[0]:
				s += a[j]
			return s
		"as":
			var n := 0
			for i in 8:
				if a[i] < a[i + 1] and (i == 0 or a[i - 1] > a[i]):
					n += 1
			return n
		"rn":
			var n := 0
			for i in a.size():
				if (i > 0 and absi(a[i] - a[i - 1]) == 1) or (i < a.size() - 1 and absi(a[i] - a[i + 1]) == 1):
					n += 1
			return n
		"fs":
			return a[0] + a[1] + a[2]
		"nr":
			return a[a[0] - 1]
		"ro":
			if a[0] < a[1] and a[1] < a[2]: return 1
			if a[0] > a[1] and a[1] > a[2]: return -1
			return 0
		"bf":
			var x := a[0]
			var y := a[8]
			var s := 0
			if x + y > 9:   # overlap of the first x and last y cells
				for j in range(9 - y, x): s += a[j]
			else:           # the gap between them
				for j in range(x, 9 - y): s += a[j]
			return s
	return 0


## Line rules for placing d at position `pos` of line `ln` (other cells read from grid).
func _line_ok(ln: Dictionary, pos: int, d: int) -> bool:
	var cells: Array = ln.cells
	match ln.t:
		"gw":   # German Whispers: neighbours on the line differ by at least 5
			if d == 5:
				return false
			for j in [pos - 1, pos + 1]:
				if j >= 0 and j < cells.size():
					var v: int = grid[cells[j]]
					if v != 0 and absi(v - d) < 5:
						return false
		"rb":   # Renban: distinct digits forming a consecutive run
			var lo := d
			var hi := d
			for j in cells.size():
				if j == pos:
					continue
				var v: int = grid[cells[j]]
				if v == 0:
					continue
				if v == d:
					return false
				lo = mini(lo, v)
				hi = maxi(hi, v)
			if hi - lo > cells.size() - 1:
				return false
		"dw":   # Dutch Whispers: neighbours differ by at least 4
			for j in [pos - 1, pos + 1]:
				if j >= 0 and j < cells.size():
					var v: int = grid[cells[j]]
					if v != 0 and absi(v - d) < 4:
						return false
		"st":   # Slow Thermo: never decreases from the bulb
			for j in cells.size():
				var v: int = grid[cells[j]]
				if j == pos or v == 0:
					continue
				if (j < pos and v > d) or (j > pos and v < d):
					return false
		"bt", "lo":   # Between / Lockout: compare the inner digits with the two ends
			var n := cells.size()
			var e1: int = d if pos == 0 else grid[cells[0]]
			var e2: int = d if pos == n - 1 else grid[cells[n - 1]]
			if e1 and e2:
				if ln.t == "lo" and absi(e1 - e2) < 4:
					return false
				if ln.t == "bt" and absi(e1 - e2) < 2:
					return false
			var lo := mini(e1, e2)
			var hi := maxi(e1, e2)
			var below := false
			var above := false
			for j in range(1, n - 1):
				var v: int = d if j == pos else grid[cells[j]]
				if v == 0:
					continue
				if e1 and e2:
					if ln.t == "bt" and (v <= lo or v >= hi):
						return false
					if ln.t == "lo" and v >= lo and v <= hi:
						return false
				elif e1 or e2:
					var e := e1 + e2
					if v == e:
						return false
					if v < e: below = true
					else: above = true
			if ln.t == "bt" and below and above:
				return false
		"rs":   # Region Sum: every box-segment of the line has the same sum
			var segs: Array = []   # [known sum, unknown count]
			for j in cells.size():
				if j == 0 or p.regions[cells[j]] != p.regions[cells[j - 1]]:
					segs.append([0, 0])
				var v: int = d if j == pos else grid[cells[j]]
				if v == 0: segs[-1][1] += 1
				else: segs[-1][0] += v
			var lo := 0
			var hi := 999
			for sg in segs:
				lo = maxi(lo, sg[0] + sg[1])
				hi = mini(hi, sg[0] + N * sg[1])
			if lo > hi:
				return false
		"en", "mo":   # Entropic (low/mid/high) / Modular (remainders): any 3 in a row all differ
			var third := N / 3   # Entropic groups: 1-3 / 4-6 / 7-9 (Mini: 1-2 / 3-4 / 5-6)
			var g := (d - 1) / third if ln.t == "en" else d % 3
			for j in range(pos - 2, pos + 3):
				if j == pos or j < 0 or j >= cells.size():
					continue
				var v: int = grid[cells[j]]
				if v != 0 and ((v - 1) / third if ln.t == "en" else v % 3) == g:
					return false
		"pa":   # Parity: odd and even alternate
			for j in [pos - 1, pos + 1]:
				if j >= 0 and j < cells.size():
					var v: int = grid[cells[j]]
					if v != 0 and v % 2 == d % 2:
						return false
		"nb":   # Nabner: no two digits on the line are equal or consecutive
			for j in cells.size():
				var v: int = grid[cells[j]]
				if j != pos and v != 0 and absi(v - d) <= 1:
					return false
		"tn":   # Ten Lines: the line splits into pieces that each sum to 10
			var reach := {0: true}   # running sums of the open piece that are still possible
			for j in cells.size():
				var v: int = d if j == pos else grid[cells[j]]
				var nxt := {}
				for r in reach:
					for x in ([v] if v != 0 else range(1, 10)):
						var t: int = r + x
						if t == 10: nxt[0] = true
						elif t < 10: nxt[t] = true
				reach = nxt
				if reach.is_empty():
					return false
			if not reach.has(0):
				return false
		"da":   # Double Arrow: the two end circles sum to the digits between them
			var n := cells.size()
			var es := 0
			var ek := 0
			for j in [0, n - 1]:
				var v: int = d if j == pos else grid[cells[j]]
				if v == 0: ek += 1
				else: es += v
			var s := 0
			var k := 0
			for j in range(1, n - 1):
				var v: int = d if j == pos else grid[cells[j]]
				if v == 0: k += 1
				else: s += v
			if maxi(es + ek, s + k) > mini(es + 9 * ek, s + 9 * k):
				return false
		"pl":   # Pill Arrow: the arrow's digits sum to the 2-digit number in the pill (cells 0-1)
			var a0: int = d if pos == 0 else grid[cells[0]]
			var a1: int = d if pos == 1 else grid[cells[1]]
			var plo := (a0 if a0 else 1) * 10 + (a1 if a1 else 1)
			var phi := (a0 if a0 else 9) * 10 + (a1 if a1 else 9)
			var s := 0
			var k := 0
			for j in range(2, cells.size()):
				var v: int = d if j == pos else grid[cells[j]]
				if v == 0: k += 1
				else: s += v
			if maxi(plo, s + k) > mini(phi, s + 9 * k):
				return false
		"pr":   # Product Lines: every box piece of the line has the same product
			var pieces: Array = []   # [known product, unknown count]
			for j in cells.size():
				if j == 0 or p.regions[cells[j]] != p.regions[cells[j - 1]]:
					pieces.append([1, 0])
				var v: int = d if j == pos else grid[cells[j]]
				if v == 0: pieces[-1][1] += 1
				else: pieces[-1][0] *= v
			var target := -1
			for pc in pieces:
				if pc[1] == 0:
					if target == -1: target = pc[0]
					elif target != pc[0]: return false
			if target != -1:
				for pc in pieces:
					if pc[1] > 0 and (target % pc[0] != 0 or target / pc[0] > int(pow(9, pc[1]))):
						return false
		"df":   # Difference Lines: neighbours on the line all differ by the same amount
			var gaps := {}
			for j in cells.size() - 1:
				var x: int = d if j == pos else grid[cells[j]]
				var y: int = d if j + 1 == pos else grid[cells[j + 1]]
				if x and y:
					gaps[absi(x - y)] = true
			if gaps.size() > 1 or gaps.has(0):
				return false
		"rt":   # Ratio Lines: neighbours on the line are always in a 2:1 ratio
			for j in [pos - 1, pos + 1]:
				if j >= 0 and j < cells.size():
					var v: int = grid[cells[j]]
					if v != 0 and v != d * 2 and d != v * 2:
						return false
		"zp":   # Zipper: digits the same distance from the centre sum to the centre digit
			var n := cells.size()
			var m := n / 2
			var cv: int = d if pos == m else grid[cells[m]]
			for k in range(1, m + 1):
				var x: int = d if pos == m - k else grid[cells[m - k]]
				var y: int = d if pos == m + k else grid[cells[m + k]]
				if x and y:
					if (cv and x + y != cv) or (not cv and x + y > N):
						return false
				elif cv and (x >= cv or y >= cv):
					return false
	return true


func _v(cell: int, c: int, d: int) -> int:
	return d if cell == c else grid[cell]


## Outside clue check with d placed in c: exact when the line is known, bounds otherwise.
func _outer_ok(oi: int, c: int, d: int) -> bool:
	var o: Dictionary = p.outer[oi]
	var cells: PackedInt32Array = outer_lines[oi]
	var v: int = o.v
	var a := PackedInt32Array()
	a.resize(N)
	for k in N:
		a[k] = _v(cells[k], c, d)
	match o.t:
		"sw":
			var i1 := a.find(1)
			var i9 := a.find(N)
			if i1 < 0 or i9 < 0:
				return true
			var s := 0
			var k := 0
			for j in range(mini(i1, i9) + 1, maxi(i1, i9)):
				if a[j] == 0: k += 1
				else: s += a[j]
			return s + 2 * k <= v and v <= s + (N - 1) * k
		"sk":
			var i9 := a.find(N)
			if i9 >= 0 and v > i9 + 1:
				return false
			var vis := 0
			var mx := 0
			for j in N:
				var x := a[j]
				if x == 0:
					return vis <= v and vis + mini(N - j, N - mx) >= v
				if x > mx:
					vis += 1
					mx = x
				if x == N:
					return vis == v
			return vis == v
		"xs":
			var x := a[0]
			if x == 0:
				return true
			var s := 0
			var k := 0
			for j in x:
				if a[j] == 0: k += 1
				else: s += a[j]
			return s + k <= v and v <= s + N * k
		"as":
			if 9 - a.count(0) < 6:
				return true   # too few digits to prune much; skip the cost
			# min / max number of run starts over the up/down steps the known digits allow
			var mn := [0, 99]
			var mxs := [0, -99]
			for i in 8:
				var opts: Array = [0, 1]
				if a[i] and a[i + 1]:
					opts = [1 if a[i] < a[i + 1] else 0]
				elif a[i] == 9 or a[i + 1] == 1:
					opts = [0]
				elif a[i] == 1 or a[i + 1] == 9:
					opts = [1]
				var nmn := [99, 99]
				var nmx := [-99, -99]
				for pu in 2:
					if mn[pu] == 99:
						continue
					for u in opts:
						var add := 1 if u == 1 and pu == 0 else 0
						nmn[u] = mini(nmn[u], mn[pu] + add)
						nmx[u] = maxi(nmx[u], mxs[pu] + add)
				mn = nmn
				mxs = nmx
			return mini(mn[0], mn[1]) <= v and v <= maxi(mxs[0], mxs[1])
		"rn":
			var lb := 0
			var ub := 0
			for i in N:
				var yes := false
				var maybe := false
				for j in [i - 1, i + 1]:
					if j < 0 or j >= N:
						continue
					if a[i] == 0 or a[j] == 0:
						maybe = true
					elif absi(a[i] - a[j]) == 1:
						yes = true
				if yes:
					lb += 1
					ub += 1
				elif maybe:
					ub += 1
			return lb <= v and v <= ub
		"md":   # the clue digit isn't among the first three cells
			return a[0] != v and a[1] != v and a[2] != v
		"fs":
			var s := 0
			var k := 0
			for j in 3:
				if a[j] == 0: k += 1
				else: s += a[j]
			return s + k <= v and v <= s + N * k
		"nr":
			if a[0] == 0:
				return true
			var t := a[0] - 1
			if a[t] != 0 and a[t] != v:
				return false
			for j in N:
				if j != t and a[j] == v:
					return false
			return true
		"ro":
			if a[0] and a[1] and a[2]:
				return outer_value("ro", a) == v
			# two known cells already show the direction they go
			for pr in [[0, 1], [1, 2], [0, 2]]:
				var x := a[pr[0]]
				var y := a[pr[1]]
				if x and y:
					if v == 1 and x > y: return false
					if v == -1 and x < y: return false
			return true
		"bf":
			var x := a[0]
			var y := a[8]
			if x == 0 or y == 0:
				return true
			var lo := 9 - y if x + y > 9 else x
			var hi := x if x + y > 9 else 9 - y
			var s := 0
			var k := 0
			for j in range(lo, hi):
				if a[j] == 0: k += 1
				else: s += a[j]
			return s + k <= v and v <= s + 9 * k
	return true


## Mathdoku cages: product of all cells, or difference / quotient of a 2-cell cage.
func _op_ok(cells: Array, op: String, target: int, c: int, d: int) -> bool:
	if op == "*":
		var prod := 1
		var k := 0
		for cc in cells:
			var v := _v(cc, c, d)
			if v == 0: k += 1
			else: prod *= v
		if target % prod != 0:
			return false
		return prod == target if k == 0 else target / prod <= int(pow(9, k))
	var other: int = cells[0] if cells[1] == c else cells[1]
	var o: int = grid[other]
	if op == "-":
		if o: return absi(d - o) == target
		return d + target <= 9 or d - target >= 1
	# "/"
	if o: return d == o * target or o == d * target
	return d * target <= 9 or d % target == 0


## Sum of distinct digits over `cells` (killer cages, little killer diagonals) with d placed in c.
func _sum_ok(cells: Array, total: int, c: int, d: int) -> bool:
	var s := 0
	var k := 0
	var used := 1 << d
	for cc in cells:
		if cc == c: continue
		var v: int = grid[cc]
		if v == 0: k += 1
		else:
			s += v
			used |= 1 << v
	var rem: int = total - s - d
	if k == 0:
		return rem == 0
	var lo := 0
	var hi := 0
	var n := 0
	for dd in range(1, N + 1):
		if n == k: break
		if not (used & (1 << dd)):
			lo += dd; n += 1
	if n < k: return false
	n = 0
	for dd in range(N, 0, -1):
		if n == k: break
		if not (used & (1 << dd)):
			hi += dd; n += 1
	return rem >= lo and rem <= hi


func _quad_ok(qi: int, c: int, d: int) -> bool:
	var q: Dictionary = p.quads[qi]
	var t: int = q.c
	var need: Array = q.d.duplicate()
	var free := 0
	for x in [t, t + 1, t + N, t + N + 1]:
		var v := _v(x, c, d)
		if v == 0: free += 1
		else: need.erase(v)
	return need.size() <= free


static func vertex_rel(t: int, a: int, b: int) -> bool:
	return t == a + b or t == absi(a - b)


func _vertex_ok(vi: int, c: int, d: int) -> bool:
	var vx: Dictionary = p.vertices[vi]
	var t := _v(vx.tip, c, d)
	var a := _v(vx.a, c, d)
	var b := _v(vx.b, c, d)
	var known := (1 if t else 0) + (1 if a else 0) + (1 if b else 0)
	if known == 3:
		return vertex_rel(t, a, b)
	if known < 2:
		return true
	for x in range(1, N + 1):
		if vertex_rel(t if t else x, a if a else x, b if b else x):
			return true
	return false


## Index lookup: a horizontal mark at (r, c) holding X means column X of row r holds c + 1
## (vertical: row X of column c holds r + 1).
func _index_ok(e: Array, c: int, d: int) -> bool:
	var m: int = e[0]
	var h: bool = e[1]
	var x := _v(m, c, d)
	if x == 0:
		return true
	var mr := m / 9
	var mc := m % 9
	var k := (mc if h else mr) + 1
	var t := mr * 9 + x - 1 if h else (x - 1) * 9 + mc
	for j in 9:
		var cell := mr * 9 + j if h else j * 9 + mc
		var v := _v(cell, c, d)
		if cell == t:
			if v != 0 and v != k:
				return false
		elif v == k:
			return false
	return true


## Slingshot: digit N in the arrow cell a means the source digit X repeats N cells further in dir.
func _sling_ok(si: int, c: int, d: int) -> bool:
	var sl: Dictionary = p.slings[si]
	var a: int = sl.a
	var dr: int = sl.dir[0]
	var dc: int = sl.dir[1]
	var x := _v(sl.s, c, d)
	if x == 0:
		return true
	var n := _v(a, c, d)
	var found := -99   # signed distance of X from a along dir
	for k in range(-8, 9):
		var rr: int = a / 9 + dr * k
		var cc: int = a % 9 + dc * k
		if rr < 0 or rr > 8 or cc < 0 or cc > 8:
			continue
		if _v(rr * 9 + cc, c, d) == x:
			found = k
			break
	if n:
		if found != -99 and found != n:
			return false
	elif found != -99 and found < 1:
		return false
	return true


func _five_ok(f: int, c: int, d: int) -> bool:
	if f >= 9:
		var u := _v(f - 9, c, d)
		if u == 0 or u == 1:
			return true
	if f < 72:
		var b := _v(f + 9, c, d)
		if b == 0 or b == 9:
			return true
	return false


## Generator only (Twisted): in every 2x2 both diagonal pairs are consecutive or neither is.
func _twist_ok(c: int, d: int) -> bool:
	for t in [c, c - 1, c - 9, c - 10]:
		if t < 0 or t % 9 == 8 or t / 9 >= 8:
			continue
		var a1 := _v(t, c, d)
		var a2 := _v(t + 10, c, d)
		var b1 := _v(t + 1, c, d)
		var b2 := _v(t + 9, c, d)
		if a1 and a2 and b1 and b2 and ((absi(a1 - a2) == 1) != (absi(b1 - b2) == 1)):
			return false
	return true


static func edge_rel(t: int, a: int, b: int) -> bool:
	match t:
		Edge.WHITE: return absi(a - b) == 1
		Edge.BLACK: return a == 2 * b or b == 2 * a
		Edge.X: return a + b == 10
		Edge.V: return a + b == 5
		Edge.GT: return a > b
		Edge.LT: return a < b
		Edge.SAME: return a % 2 == b % 2
		Edge.DIFF: return a % 2 != b % 2
		Edge.PULSE: return a != 1 and b != 1 and (absi(a - b) == 1 or a % b == 0 or b % a == 0)
	return true


func _edge_ok(t: int, a: int, b: int, val := 0) -> bool:
	if t == Edge.SUMN:
		return a + b == val
	if t == Edge.PRODN:
		return a * b == val
	if t == Edge.RATION:
		return a == b * val or b == a * val
	if t == Edge.DIFFN:
		return absi(a - b) == val
	if t != Edge.NONE:
		return edge_rel(t, a, b)
	for nt in neg_types:
		if edge_rel(nt, a, b):
			return false
	return true


## Checks the non-unit constraints for placing digit d in cell c given current grid.
func extra_ok(c: int, d: int) -> bool:
	if not (cell_mask[c] & (1 << d)):
		return false
	for n in cell_diff[c]:
		if grid[n] == d:
			return false
	if non_consecutive:
		for n in cell_orth[c]:
			var v: int = grid[n]
			if v != 0 and absi(v - d) == 1:
				return false
	for lp in cell_lines[c]:
		if not _line_ok(p.lines[lp[0]], lp[1], d):
			return false
	for n in cell_eq[c]:
		var v: int = grid[n]
		if v != 0 and v != d:
			return false
	for oi in cell_outer[c]:
		if not _outer_ok(oi, c, d):
			return false
	for si in cell_sums[c]:
		if not _sum_ok(p.sums[si].cells, p.sums[si].sum, c, d):
			return false
	for qi in cell_quads[c]:
		if not _quad_ok(qi, c, d):
			return false
	for vi in cell_vertex[c]:
		if not _vertex_ok(vi, c, d):
			return false
	for e in cell_index[c]:
		if not _index_ok(e, c, d):
			return false
	for si in cell_sling[c]:
		if not _sling_ok(si, c, d):
			return false
	if flatmates:
		if d == 5 and not _five_ok(c, c, d):
			return false
		if c >= 9 and grid[c - 9] == 5 and not _five_ok(c - 9, c, d):
			return false
		if c < 72 and grid[c + 9] == 5 and not _five_ok(c + 9, c, d):
			return false
	if twist_gen and not _twist_ok(c, d):
		return false
	if queen and d == 9:
		for dir in [[1, 1], [1, -1], [-1, 1], [-1, -1]]:
			var rr: int = c / 9 + dir[0]
			var cc: int = c % 9 + dir[1]
			while rr >= 0 and rr <= 8 and cc >= 0 and cc <= 8:
				if grid[rr * 9 + cc] == 9:
					return false
				rr += dir[0]
				cc += dir[1]
	if anti_diag:
		for diag in ([0] if c % 10 == 0 else []) + ([1] if c % 8 == 0 and c > 0 and c < 80 else []):
			var seen := 1 << d
			for k in 9:
				var x := k * 10 if diag == 0 else 8 + k * 8
				if x != c and grid[x] != 0:
					seen |= 1 << grid[x]
			if _popc[seen] > 3:
				return false
	for tp in cell_thermos[c]:
		var t: Array = p.thermos[tp[0]]
		var i: int = tp[1]
		var L := t.size()
		if d < i + 1 or d > N - (L - 1 - i):
			return false
		for j in L:
			if j == i:
				continue
			var v: int = grid[t[j]]
			if v == 0:
				continue
			if j < i and d < v + (i - j):
				return false
			if j > i and d > v - (j - i):
				return false
	for ap in cell_arrows[c]:
		var a: Dictionary = p.arrows[ap[0]]
		var line: Array = a.line
		var s := 0
		var k := 0
		if ap[1] == -1:
			for lc in line:
				var v: int = grid[lc]
				if v == 0: k += 1
				else: s += v
			if d < s + k or d > s + N * k:
				return false
		else:
			for lc in line:
				if lc == c: continue
				var v: int = grid[lc]
				if v == 0: k += 1
				else: s += v
			var cv: int = grid[a.circle]
			if cv > 0:
				if s + d + k > cv or s + d + N * k < cv:
					return false
			elif s + d + k > N:
				return false
	var cg := cell_cage[c]
	if cg >= 0:
		var cage: Dictionary = p.cages[cg]
		var op: String = cage.get("op", "+")
		if op == "+":
			if not _sum_ok(cage.cells, int(cage.sum), c, d):
				return false
		elif not _op_ok(cage.cells, op, int(cage.sum), c, d):
			return false
	for e in cell_edges[c]:
		var v: int = grid[e[0]]
		if v != 0 and not _edge_ok(e[1], d, v, e[2] if e.size() > 2 else 0):
			return false
	return true


func candidates(c: int) -> int:
	var used := 0
	for u in cell_units[c]:
		used |= unit_used[u]
	var m := all_mask & ~used & cell_mask[c]
	# fast masks for the global neighbour rules before the full per-digit check
	for n in cell_diff[c]:
		var v: int = grid[n]
		if v != 0:
			m &= ~(1 << v)
	if non_consecutive:
		for n in cell_orth[c]:
			var v: int = grid[n]
			if v != 0:
				m &= ~((1 << (v - 1)) | (1 << (v + 1)))
		m &= all_mask
	if m and has_extra[c]:
		for d in range(1, N + 1):
			if (m & (1 << d)) and not extra_ok(c, d):
				m &= ~(1 << d)
	return m


func _load(g: PackedInt32Array) -> bool:
	grid = g.duplicate()
	unit_used = PackedInt32Array()
	unit_used.resize(units.size())
	unit_used.fill(0)
	for c in NC:
		var d := grid[c]
		if d == 0: continue
		var b := 1 << d
		for u in cell_units[c]:
			if unit_used[u] & b:
				return false
			unit_used[u] |= b
	# Verify given digits against extra constraints.
	for c in NC:
		var d := grid[c]
		if d and has_extra[c]:
			grid[c] = 0
			var ok := extra_ok(c, d)
			grid[c] = d
			if not ok:
				return false
	return true


func _search() -> void:
	if _aborted or _count >= _limit:
		return
	_nodes += 1
	if _node_limit > 0 and _nodes > _node_limit:
		_aborted = true
		return
	var best := -1
	var best_m := 0
	var best_n := 10
	for c in NC:
		if grid[c] != 0: continue
		var m := candidates(c)
		var n := _popc[m]
		if n < best_n:
			best_n = n; best = c; best_m = m
			if n <= 1: break
	if best == -1:
		_count += 1
		if _found.is_empty():
			_found = grid.duplicate()
		return
	if best_n == 0:
		return
	var digits: Array[int] = []
	for d in range(1, N + 1):
		if best_m & (1 << d):
			digits.append(d)
	if _rng:
		for i in range(digits.size() - 1, 0, -1):
			var j := _rng.randi_range(0, i)
			var tmp := digits[i]; digits[i] = digits[j]; digits[j] = tmp
	var us := cell_units[best]
	for d in digits:
		var b := 1 << d
		grid[best] = d
		for u in us: unit_used[u] |= b
		_search()
		for u in us: unit_used[u] &= ~b
		grid[best] = 0
		if _aborted or _count >= _limit:
			return


## Returns number of solutions up to `limit`, or -1 if node_limit was exceeded.
func count_solutions(g: PackedInt32Array, limit := 2, node_limit := 0) -> int:
	_count = 0; _limit = limit; _nodes = 0; _node_limit = node_limit
	_aborted = false; _rng = null; _found = PackedInt32Array()
	if not _load(g):
		return 0
	_search()
	return -1 if _aborted else _count


## Returns a solution (empty array if none / aborted). Random digit order when rng given.
func solve(g: PackedInt32Array, rng: RandomNumberGenerator = null, node_limit := 0) -> PackedInt32Array:
	_count = 0; _limit = 1; _nodes = 0; _node_limit = node_limit
	_aborted = false; _rng = rng; _found = PackedInt32Array()
	if not _load(g):
		return PackedInt32Array()
	_search()
	_rng = null
	return _found


func last_nodes() -> int:
	return _nodes


## Flags (1 = conflict) for every filled cell that breaks a rule given the other filled cells.
func find_conflicts(g: PackedInt32Array) -> PackedByteArray:
	var bad := PackedByteArray()
	bad.resize(NC)
	bad.fill(0)
	grid = g.duplicate()
	for u in units:
		for i in u.size():
			var a := grid[u[i]]
			if a == 0: continue
			for j in range(i + 1, u.size()):
				if grid[u[j]] == a:
					bad[u[i]] = 1; bad[u[j]] = 1
	for c in NC:
		var d := grid[c]
		if d == 0 or not has_extra[c]: continue
		grid[c] = 0
		if not extra_ok(c, d):
			bad[c] = 1
		grid[c] = d
	return bad
