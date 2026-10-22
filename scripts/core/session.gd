class_name Session
extends RefCounted
## Mutable state of one game in progress: digits, pencil marks, undo history, timer, hints.

signal changed

var puzzle: Puzzle
var solver: Solver
var values := PackedInt32Array()
var corner := PackedInt32Array()   # bitmask of corner marks per cell
var center := PackedInt32Array()   # bitmask of centre marks per cell
var hinted := PackedByteArray()
var colors := PackedInt32Array()   # bitmask of colour indices 1..9 per cell
var conflicts := PackedByteArray()
var elapsed := 0.0
var hints_used := 0
## Hints allowed per puzzle, by difficulty (restart and undo don't give hints back).
const HINT_LIMITS := {"beginner": 20, "easy": 10, "medium": 3, "hard": 0, "expert": 0, "master": 0}
## "Check" uses allowed per puzzle, by difficulty (also not refunded by restart/undo).
const CHECK_LIMITS := {"beginner": 10, "easy": 5, "medium": 2, "hard": 0, "expert": 0, "master": 0}
var checks_used := 0
var mistakes := 0          # mistakes so far (see MISTAKE_LIMITS)
var solved := false
var auto_clear_notes := true

var _undo: Array = []
var _redo: Array = []


func _init(pz: Puzzle) -> void:
	puzzle = pz
	solver = Solver.new(pz)
	values = pz.givens.duplicate()
	corner.resize(pz.cell_count())
	center.resize(pz.cell_count())
	hinted.resize(pz.cell_count())
	colors.resize(pz.cell_count())
	conflicts.resize(pz.cell_count())
	_refresh()


func is_given(c: int) -> bool:
	return puzzle.givens[c] != 0


func _snapshot() -> Dictionary:
	return {"v": values.duplicate(), "c": corner.duplicate(), "m": center.duplicate(), "h": hinted.duplicate(), "k": colors.duplicate()}


func _restore(s: Dictionary) -> void:
	values = s.v.duplicate(); corner = s.c.duplicate(); center = s.m.duplicate(); hinted = s.h.duplicate()
	colors = s.k.duplicate()


func _push() -> void:
	_undo.append(_snapshot())
	if _undo.size() > 400:
		_undo.pop_front()
	_redo.clear()


func can_undo() -> bool: return not _undo.is_empty()
func can_redo() -> bool: return not _redo.is_empty()


func undo() -> void:
	if _undo.is_empty() or solved: return
	_redo.append(_snapshot())
	_restore(_undo.pop_back())
	_refresh()


func redo() -> void:
	if _redo.is_empty() or solved: return
	_undo.append(_snapshot())
	_restore(_redo.pop_back())
	_refresh()


func _editable(cells: Array) -> Array:
	return cells.filter(func(c): return not is_given(c) and not hinted[c])


## mode: "normal" | "corner" | "center" | "color"
func input_digit(cells: Array, d: int, mode: String) -> void:
	if solved: return
	if mode == "color":
		_toggle_color(cells, d)
		return
	var ed := _editable(cells)
	if ed.is_empty(): return
	_push()
	var bit := 1 << d
	if mode == "normal":
		var all_have := ed.all(func(c): return values[c] == d)
		for c in ed:
			values[c] = 0 if all_have else d
			if not all_have and auto_clear_notes:
				_clear_peer_notes(c, d)
	else:
		var marks := corner if mode == "corner" else center
		var targets := ed.filter(func(c): return values[c] == 0)
		if targets.is_empty():
			_undo.pop_back(); return
		var all_have := targets.all(func(c): return marks[c] & bit)
		for c in targets:
			if all_have: marks[c] &= ~bit
			else: marks[c] |= bit
	_refresh()


## Colours can be painted on any cell (givens too). Toggles colour `k` (1..9) on all cells.
func _toggle_color(cells: Array, k: int) -> void:
	if cells.is_empty(): return
	_push()
	var bit := 1 << k
	var all_have := cells.all(func(c): return colors[c] & bit)
	for c in cells:
		if all_have: colors[c] &= ~bit
		else: colors[c] |= bit
	_refresh()


## Erases in layers: digits first, then pencil marks, then colours.
## In colour mode only colours are erased.
func erase(cells: Array, mode := "") -> void:
	if solved or cells.is_empty(): return
	if mode == "color":
		if cells.any(func(c): return colors[c] != 0):
			_push()
			for c in cells: colors[c] = 0
			_refresh()
		return
	var ed := _editable(cells)
	var any_val := ed.any(func(c): return values[c] != 0)
	var any_note := ed.any(func(c): return corner[c] != 0 or center[c] != 0)
	var any_col := cells.any(func(c): return colors[c] != 0)
	if not (any_val or any_note or any_col): return
	_push()
	if any_val:
		for c in ed: values[c] = 0
	elif any_note:
		for c in ed:
			corner[c] = 0
			center[c] = 0
	else:
		for c in cells: colors[c] = 0
	_refresh()


## True if digit d is not already placed in any unit (row/col/region/cage…) seen by cell c.
func note_possible(c: int, d: int) -> bool:
	for u in solver.cell_units[c]:
		for o in solver.units[u]:
			if o != c and values[o] == d:
				return false
	return true


func _clear_peer_notes(c: int, d: int) -> void:
	var bit := ~(1 << d)
	for u in solver.cell_units[c]:
		for o in solver.units[u]:
			corner[o] &= bit
			center[o] &= bit


## Reveals the solution digit in `cell` (or the most constrained empty cell). Returns the cell or -1.
## Mistakes allowed per puzzle; reaching the limit loses the puzzle.
## Easy/medium: a mistake is any placed digit that doesn't match the solution.
## Hard: only a digit that breaks a rule (row/column/box/cage/…) counts.
## 0 = no limit (beginner).
const MISTAKE_LIMITS := {"beginner": 0, "easy": 14, "medium": 7, "hard": 3, "expert": 2, "master": 1}
## Levels where a mistake is a rule break (others: any digit that doesn't match the solution).
const RULE_BREAK_LEVELS := ["hard", "expert", "master"]


func mistake_limit() -> int:
	return int(MISTAKE_LIMITS.get(puzzle.difficulty, 3))


## Whether the digit now in cell c counts as a mistake under this difficulty's rule.
func counts_as_mistake(c: int) -> bool:
	if values[c] == 0:
		return false
	if puzzle.difficulty in RULE_BREAK_LEVELS:
		return conflicts[c] != 0
	return values[c] != puzzle.solution[c]


func is_lost() -> bool:
	return not solved and mistake_limit() > 0 and mistakes >= mistake_limit()


## "Try again" after losing: back to the givens with the timer and mistakes at 0, no undo history.
## Hints and checks already used stay used.
func retry() -> void:
	values = puzzle.givens.duplicate()
	corner.fill(0); center.fill(0); hinted.fill(0); colors.fill(0)
	elapsed = 0.0
	mistakes = 0
	_undo.clear()
	_redo.clear()
	_refresh()


func checks_left() -> int:
	return maxi(0, int(CHECK_LIMITS.get(puzzle.difficulty, 0)) - checks_used)


func hints_left() -> int:
	return maxi(0, int(HINT_LIMITS.get(puzzle.difficulty, 0)) - hints_used)


func hint(cell := -1) -> int:
	if hints_left() <= 0:
		return -1
	if solved: return -1
	if cell < 0 or values[cell] == puzzle.solution[cell] or is_given(cell):
		cell = -1
		var best := 10
		solver.grid = values
		# Prefer cells that are currently wrong, then the most constrained empty cell.
		for c in values.size():
			if values[c] != 0 and values[c] != puzzle.solution[c]:
				cell = c; break
		if cell < 0:
			var g := values.duplicate()
			for c in values.size():
				if g[c] != 0 and g[c] != puzzle.solution[c]:
					g[c] = 0
			solver._load(g)
			for c in values.size():
				if g[c] != 0: continue
				var n := solver._popc[solver.candidates(c)]
				if n < best:
					best = n; cell = c
	if cell < 0: return -1
	_push()
	values[cell] = puzzle.solution[cell]
	hinted[cell] = 1
	corner[cell] = 0
	center[cell] = 0
	if auto_clear_notes:
		_clear_peer_notes(cell, values[cell])
	hints_used += 1
	_refresh()
	return cell


## Cells whose digit disagrees with the solution.
func wrong_cells() -> Array:
	var out: Array = []
	for c in values.size():
		if values[c] != 0 and values[c] != puzzle.solution[c]:
			out.append(c)
	return out


func filled_count() -> int:
	var n := 0
	for v in values:
		if v: n += 1
	return n


func digit_count(d: int) -> int:
	var n := 0
	for v in values:
		if v == d: n += 1
	return n


## Fills every cell with the solution (dev cheat; see game_screen CHEAT). Undoable.
## Fills every cell with the solution except one cell that isn't solved yet, which is left empty
## (dev cheat → → ←; see game_screen CHEAT_ALL_BUT_ONE). Returns the cell left empty, or -1. Undoable.
func autofill_all_but_one() -> int:
	if solved: return -1
	var open: Array = []
	for c in values.size():
		if values[c] != puzzle.solution[c]:
			open.append(c)
	if open.size() <= 1:
		return -1
	var keep: int = open.pick_random()
	_push()
	for c in open:
		values[c] = 0 if c == keep else puzzle.solution[c]
	_refresh()
	return keep


func autofill() -> void:
	if solved: return
	_push()
	values = puzzle.solution.duplicate()
	_refresh()


## Back to the givens with the timer at 0. Can't be undone (undo history is cleared).
## Hints, checks and mistakes stay counted, so restarting isn't a free reset.
func restart() -> void:
	values = puzzle.givens.duplicate()
	corner.fill(0); center.fill(0); hinted.fill(0); colors.fill(0)
	elapsed = 0.0
	_undo.clear()
	_redo.clear()
	_refresh()


func _refresh() -> void:
	conflicts = solver.find_conflicts(values)
	if not solved and values == puzzle.solution:
		solved = true
	changed.emit()


func to_dict() -> Dictionary:
	return {
		"puzzle": puzzle.to_dict(),
		"values": Array(values), "corner": Array(corner), "center": Array(center),
		"hinted": Array(hinted), "colors": Array(colors), "elapsed": elapsed, "hints": hints_used, "checks": checks_used, "mistakes": mistakes,
	}


static func from_dict(d: Dictionary) -> Session:
	var s := Session.new(Puzzle.from_dict(d.puzzle))
	s.values = PackedInt32Array(d.get("values", s.values))
	s.corner = PackedInt32Array(d.get("corner", s.corner))
	s.center = PackedInt32Array(d.get("center", s.center))
	s.hinted = PackedByteArray(d.get("hinted", s.hinted))
	s.colors = PackedInt32Array(d.get("colors", s.colors))
	s.elapsed = float(d.get("elapsed", 0.0))
	s.hints_used = int(d.get("hints", 0))
	s.checks_used = int(d.get("checks", 0))
	s.mistakes = int(d.get("mistakes", 0))
	s._refresh()
	return s
