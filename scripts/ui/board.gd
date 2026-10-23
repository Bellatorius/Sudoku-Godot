class_name Board
extends Control
## Draws a 9x9 variant board (regions, cages, lines, dots, notes) and handles cell selection.

signal selection_changed

var session: Session
var interactive := true
var selected: Array = []        # ordered; last = cursor
var flash_cells: Array = []
var flash_t := 0.0
var celebrate_t := -1.0
var align_top := false
var emphasis: Array = []   # example popup: cells to spotlight (the rest of the board is dimmed)
var versus := false   # multiplayer: only rule conflicts are marked, never solution mismatches

var _dragging := false
var _drag_add := true
var _rect := Rect2()
var _cell := 0.0

## Line-clue colours (same hues as the variant icons).
const LINE_COLORS := {"gw": Color(0.18, 0.70, 0.42, 0.75), "rb": Color(0.76, 0.31, 0.84, 0.55),
	"dw": Color(0.94, 0.54, 0.14, 0.75), "pal": Color(0.25, 0.65, 0.91, 0.55), "bt": Color(0.45, 0.47, 0.58, 0.75),
	"lo": Color(0.55, 0.60, 0.20, 0.75), "st": Color(0.55, 0.80, 0.55, 0.7), "bi": Color(0.80, 0.58, 0.15, 0.6),
	"rf": Color(0.96, 0.62, 0.40, 0.7), "zp": Color(0.56, 0.48, 0.88, 0.6),
	"rs": Color(0.30, 0.72, 0.86, 0.6), "en": Color(0.85, 0.55, 0.25, 0.65), "mo": Color(0.20, 0.62, 0.58, 0.65),
	"pa": Color(0.90, 0.36, 0.45, 0.6), "nb": Color(0.92, 0.80, 0.20, 0.7), "tn": Color(0.50, 0.56, 0.68, 0.65),
	"da": Color(0.45, 0.47, 0.58, 0.75), "pl": Color(0.45, 0.47, 0.58, 0.85),
	"pr": Color(0.62, 0.42, 0.85, 0.6), "df": Color(0.95, 0.45, 0.30, 0.6), "rt": Color(0.30, 0.75, 0.55, 0.6)}
const LINE_WIDTH := {"gw": 0.16, "dw": 0.16, "rb": 0.24, "pal": 0.22, "bt": 0.07, "lo": 0.09, "st": 0.26,
	"bi": 0.14, "rf": 0.16, "zp": 0.18, "rs": 0.18, "en": 0.16, "mo": 0.16, "pa": 0.16, "nb": 0.16,
	"tn": 0.16, "da": 0.07, "pl": 0.045, "pr": 0.18, "df": 0.16, "rt": 0.16}
const SYMBOLS := ["★", "●", "▲", "■", "♦", "♥", "♣", "♠", "✚"]
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]


## How digit d is shown in this puzzle: letters, Roman numerals, symbols, the Wordoku word's letters, or the digit.
## (Color Sudoku draws coloured discs instead, see _draw_digit.)
static func glyph_for(pz: Puzzle, d: int) -> String:
	if d < 1 or d > 9:
		return ""
	match pz.variant:
		"alphabet": return "ABCDEFGHI"[d - 1]
		"roman": return ROMAN[d - 1]
		"symbol": return SYMBOLS[d - 1]
		"wordoku":
			if pz.word.length() == 9:
				return pz.word[d - 1]
	return str(d)


## Extra regions of the fixed-pattern variants, shaded like Windoku's windows.
const SHADED := {"center_dot": [10, 13, 16, 37, 40, 43, 64, 67, 70], "asterisk": Solver.ASTERISK, "girandola": Solver.GIRANDOLA}
## Margin around the grid (in cells) when clues sit outside it.
const OUTER_MARGIN := 0.8
var _n := 9   # grid size of the shown puzzle (6 for Mini)
var _intro := -1.0        # seconds since a new puzzle opened: the lines draw themselves in; -1 = done
const INTRO_STAGGER := 0.07   # delay between one line starting to draw and the next
const INTRO_DRAW := 0.55      # how long one line takes to draw
const C_DIAG := Color(0.165, 0.31, 1.0, 0.22)


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(300, 300)


static var _examples = null   # res://puzzles/examples.json: one ready puzzle per variant (opens instantly)


## A solved example of a variant for the rules: the variant's puzzle from puzzles/examples.json, or else
## an easy pack puzzle (never `avoid_id`, the one being played), with every cell filled.
static func solved_example(variant: String, avoid_id := "") -> Session:
	var pz: Puzzle = null
	if _examples == null:
		_examples = {}
		if FileAccess.file_exists("res://puzzles/examples.json"):
			var data = JSON.parse_string(FileAccess.get_file_as_string("res://puzzles/examples.json"))
			if data is Dictionary:
				_examples = data
	if _examples.has(variant) and str(_examples[variant].get("id", "")) != avoid_id:
		pz = Puzzle.from_dict(_examples[variant])
	for lv in ["easy", "beginner", "medium"]:
		if pz:
			break
		for d in GameState.pack_puzzles(variant, lv):
			if str(d.get("id", "")) != avoid_id:
				pz = Puzzle.from_dict(d)
				break
		if pz:
			break
	if pz == null:
		pz = Generator.make(variant, "easy", 7)
	if pz == null:
		return null
	var s := Session.new(pz)
	for c in pz.cell_count():
		s.values[c] = pz.solution[c]
	return s


func set_session(s: Session) -> void:
	var fresh := session == null or session.puzzle != s.puzzle
	if session and session.changed.is_connected(queue_redraw):
		session.changed.disconnect(queue_redraw)
	if fresh and interactive and GameState.settings.get("line_intro", true):
		_intro = 0.0
	session = s
	session.changed.connect(queue_redraw)
	selected = []
	queue_redraw()


func _process(delta: float) -> void:
	var redraw := false
	if flash_t > 0.0:
		flash_t = maxf(0.0, flash_t - delta)
		redraw = true
	if _intro >= 0.0:
		_intro += delta
		if session == null or _intro > INTRO_DRAW + INTRO_STAGGER * _shape_count() + 0.1:
			_intro = -1.0
		redraw = true
	if celebrate_t >= 0.0:
		celebrate_t += delta
		if celebrate_t > 2.2:
			celebrate_t = -1.0
		redraw = true
	if redraw:
		queue_redraw()


func flash(cells: Array) -> void:
	flash_cells = cells
	flash_t = 1.4


func celebrate() -> void:
	celebrate_t = 0.0
	selected = []


# ------------------------------------------------------------------ geometry

func _layout() -> void:
	var margin := 0.0
	if session and (not session.puzzle.outer.is_empty() or not session.puzzle.sums.is_empty()):
		margin = OUTER_MARGIN
	_n = session.puzzle.size if session else 9
	var s := floorf(minf(size.x, size.y))
	_cell = floorf(s / (_n + margin * 2.0))
	var grid := _cell * _n
	var m := floorf(margin * _cell)
	var full := grid + m * 2.0
	var off := ((size - Vector2(full, full)) / 2.0).floor() + Vector2(m, m)
	if align_top:
		off.y = m
	_rect = Rect2(off, Vector2(grid, grid))


func cell_rect(c: int) -> Rect2:
	return Rect2(_rect.position + Vector2(c % _n, c / _n) * _cell, Vector2(_cell, _cell))


func cell_center(c: int) -> Vector2:
	return _rect.position + (Vector2(c % _n, c / _n) + Vector2(0.5, 0.5)) * _cell


func cell_at(pos: Vector2) -> int:
	if not _rect.has_point(pos):
		return -1
	var local := (pos - _rect.position) / _cell
	return clampi(int(local.y), 0, _n - 1) * _n + clampi(int(local.x), 0, _n - 1)


# ------------------------------------------------------------------ input

func _gui_input(event: InputEvent) -> void:
	if not interactive or session == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Clicking the board takes the keyboard back from a text field (e.g. the race chat),
			# so digits go into the grid again.
			var f := get_viewport().gui_get_focus_owner()
			if f:
				f.release_focus()
			var c := cell_at(event.position)
			if c < 0:
				return
			var additive: bool = event.ctrl_pressed or event.shift_pressed or event.meta_pressed
			if event.double_click and session.values[c] != 0:
				# Double-click selects all cells with the same digit.
				var d := session.values[c]
				selected = []
				for i in _n * _n:
					if session.values[i] == d:
						selected.append(i)
			elif additive:
				_drag_add = not selected.has(c)
				if _drag_add: selected.append(c)
				else: selected.erase(c)
			else:
				selected = [c]
				_drag_add = true
			_dragging = true
			selection_changed.emit()
			queue_redraw()
			accept_event()
		else:
			_dragging = false
	if event is InputEventMouseMotion and _dragging:
		var c := cell_at(event.position)
		if c >= 0:
			if _drag_add and not selected.has(c):
				selected.append(c)
				selection_changed.emit()
				queue_redraw()
			elif not _drag_add and selected.has(c):
				selected.erase(c)
				selection_changed.emit()
				queue_redraw()


# ------------------------------------------------------------------ line highlight + draw-in

func _shape_count() -> int:
	var pz := session.puzzle
	return pz.thermos.size() + pz.lines.size() + pz.arrows.size()


## How much of shape number k (thermos, then lines, then arrows) is drawn during the intro, 0..1.
func _reveal(k: int) -> float:
	if _intro < 0.0:
		return 1.0
	var f := clampf((_intro - k * INTRO_STAGGER) / INTRO_DRAW, 0.0, 1.0)
	return 1.0 - pow(1.0 - f, 3.0)   # ease out


## The first fraction f of a polyline (by length).
func _partial(pts: PackedVector2Array, f: float) -> PackedVector2Array:
	if f >= 1.0 or pts.size() < 2:
		return pts
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	var left := total * f
	var out := PackedVector2Array([pts[0]])
	for i in pts.size() - 1:
		var d := pts[i].distance_to(pts[i + 1])
		if left >= d:
			out.append(pts[i + 1])
			left -= d
		else:
			out.append(pts[i].lerp(pts[i + 1], left / maxf(d, 0.001)))
			break
	return out


func move_cursor(dx: int, dy: int, extend := false) -> void:
	var c: int = selected[-1] if not selected.is_empty() else (_n * _n) / 2
	var r := wrapi(c / _n + dy, 0, _n)
	var k := wrapi(c % _n + dx, 0, _n)
	var n := r * _n + k
	if extend:
		if not selected.has(n): selected.append(n)
	else:
		selected = [n]
	selection_changed.emit()
	queue_redraw()


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	_layout()
	if session == null:
		return
	var pz := session.puzzle
	var cell := _cell

	# Board background + soft shadow
	var shadow := UI.box(Color(0, 0, 0, 0.0), Color(0, 0, 0, 0), 6, 0)
	shadow.shadow_color = Color(0.055, 0.055, 0.07, 0.08)
	shadow.shadow_size = 18
	shadow.shadow_offset = Vector2(0, 6)
	draw_style_box(shadow, _rect)
	draw_rect(_rect, UI.SURFACE)

	# Player colours (multiple colours split the cell into vertical stripes)
	for c in _n * _n:
		var km := session.colors[c]
		if km == 0: continue
		var cols: Array = []
		for k in range(1, 10):
			if km & (1 << k): cols.append(UI.CELL_COLORS[k])
		var r := cell_rect(c)
		var w := r.size.x / cols.size()
		for i in cols.size():
			draw_rect(Rect2(r.position + Vector2(w * i, 0), Vector2(w, r.size.y)), cols[i])

	# Windoku: the four extra boxes are shaded
	if pz.variant == "windoku":
		for top in [1, 5]:
			for left in [1, 5]:
				draw_rect(Rect2(cell_rect(top * 9 + left).position, Vector2(cell, cell) * 3.0), Color(UI.ACCENT, 0.09 if not UI.dark else 0.18))

	for c in SHADED.get(pz.variant, []):
		draw_rect(cell_rect(c), Color(UI.ACCENT, 0.12 if not UI.dark else 0.22))
	if pz.variant == "magic_square":
		draw_rect(Rect2(cell_rect(30).position, Vector2(cell, cell) * 3.0), Color(UI.GOLD, 0.12))
	# Even-Odd Regions: tinted areas (blue = even, orange = odd), labelled E / O in their first cell
	for ar in pz.areas:
		var acol := Color(0.3, 0.55, 1.0, 0.16) if ar.t == "e" else Color(1.0, 0.6, 0.2, 0.18)
		for c in ar.cells:
			draw_rect(cell_rect(c), acol)
	# Clone pairs: one pastel per pair
	for ci in pz.clones.size():
		var ccol: Color = UI.CELL_COLORS[1 + ci % 9]
		for c in pz.clones[ci].a + pz.clones[ci].b:
			draw_rect(cell_rect(c), Color(ccol, 0.55))
	# Fortress grey cells, minimum (blue) / maximum (red) cells
	for k in pz.marks:
		var mk: String = pz.marks[k]
		if mk == "fo":
			draw_rect(cell_rect(int(k)), Color(UI.INK, 0.16 if not UI.dark else 0.22))
		elif mk == "mn" or mk == "mx":
			draw_rect(cell_rect(int(k)), Color(0.3, 0.5, 1.0, 0.16) if mk == "mn" else Color(1.0, 0.35, 0.35, 0.16))

	# Highlights
	var cursor: int = selected[-1] if not selected.is_empty() else -1
	var sel_digit := session.values[cursor] if cursor >= 0 else 0
	var peers := {}
	if cursor >= 0 and GameState.settings.highlight_peers and selected.size() == 1:
		for u in session.solver.cell_units[cursor]:
			if u >= 3 * _n + (2 if pz.diagonals else 0):
				continue  # skip cage units
			for o in session.solver.units[u]:
				peers[o] = true
	for c in _n * _n:
		var r := cell_rect(c)
		var col := Color(0, 0, 0, 0)
		if peers.has(c):
			col = Color(UI.PAPER_WARM, 0.9)
		if GameState.settings.highlight_same and sel_digit != 0 and session.values[c] == sel_digit:
			col = UI.ACCENT_SOFT.darkened(0.03)
		if GameState.settings.highlight_conflicts and _marked_wrong(c):
			col = UI.DANGER_SOFT
		if selected.has(c):
			col = UI.ACCENT_MID
		if flash_t > 0.0 and flash_cells.has(c):
			col = col.lerp(Color(UI.DANGER, 0.55), clampf(flash_t, 0.0, 1.0) * (0.6 + 0.4 * sin(flash_t * 12.0)))
		if celebrate_t >= 0.0:
			var dist := float(c / _n + c % _n) / (2.0 * _n - 2.0)
			var w := clampf(1.0 - absf(celebrate_t * 1.2 - dist - 0.15) * 4.0, 0.0, 1.0)
			col = col.lerp(Color(UI.GOLD, 0.45), w)
		if col.a > 0.0:
			if session.colors[c] != 0:
				col.a *= 0.45  # keep player colours visible under soft highlights
			draw_rect(r, col)

	# Selection outline (visible even on coloured cells)
	for c in selected:
		draw_rect(cell_rect(c).grow(-2), UI.ACCENT, false, 3.0)

	# Argyle lines / Anti-Diagonal's two diagonals
	if pz.variant == "argyle":
		for ln in Solver.ARGYLE:
			var a0 := cell_center(ln[0])
			var a1 := cell_center(ln[0] + ln[1] * (ln[2] - 1))
			var dv := (a1 - a0).normalized() * cell * 0.5
			draw_line(a0 - dv, a1 + dv, C_DIAG, maxf(2.0, cell * 0.05), true)
	if pz.variant == "anti_diagonal":
		var ad := Color(UI.GOLD, 0.35)
		draw_line(_rect.position, _rect.end, ad, maxf(2.0, cell * 0.05), true)
		draw_line(Vector2(_rect.end.x, _rect.position.y), Vector2(_rect.position.x, _rect.end.y), ad, maxf(2.0, cell * 0.05), true)

	# Diagonals
	if pz.diagonals:
		draw_line(_rect.position, _rect.end, C_DIAG, maxf(2.0, cell * 0.05), true)
		draw_line(Vector2(_rect.end.x, _rect.position.y), Vector2(_rect.position.x, _rect.end.y), C_DIAG, maxf(2.0, cell * 0.05), true)

	# Even-Odd: grey square = even, grey circle = odd
	var mark := Color(UI.INK, 0.13 if not UI.dark else 0.18)
	for k in pz.parity:
		var pc := cell_center(int(k))
		if pz.parity[k] == "e":
			var half := cell * 0.34
			var sb := UI.box(mark, Color(0, 0, 0, 0), int(cell * 0.08), 0)
			draw_style_box(sb, Rect2(pc - Vector2(half, half), Vector2(half, half) * 2.0))
		else:
			draw_circle(pc, cell * 0.36, mark, true, -1.0, true)

	# Line clues (colour per type), plus end circles / squares / bulbs / reflection symbols
	for li in pz.lines.size():
		var ln: Dictionary = pz.lines[li]
		var reveal := _reveal(pz.thermos.size() + li)
		if reveal <= 0.0:
			continue
		var lpts := PackedVector2Array()
		for c in ln.cells: lpts.append(cell_center(c))
		var lcol: Color = LINE_COLORS.get(ln.t, UI.THERMO)
		var lw: float = cell * float(LINE_WIDTH.get(ln.t, 0.2))
		var shown := _partial(lpts, reveal)
		draw_polyline(shown, lcol, lw, true)
		for pt in shown: draw_circle(pt, lw * 0.5, lcol, true, -1.0, true)
		if reveal < 1.0:
			continue   # end symbols appear once the line is drawn
		match ln.t:
			"st":
				draw_circle(lpts[0], cell * 0.34, lcol, true, -1.0, true)
			"bt":
				for pt in [lpts[0], lpts[-1]]:
					draw_circle(pt, cell * 0.38, UI.SURFACE, true, -1.0, true)
					draw_circle(pt, cell * 0.38, Color(lcol, 1.0), false, maxf(2.0, cell * 0.045), true)
			"lo":
				for pt in [lpts[0], lpts[-1]]:
					var half := Vector2(cell, cell) * 0.36
					draw_rect(Rect2(pt - half, half * 2.0), UI.SURFACE)
					draw_rect(Rect2(pt - half, half * 2.0), Color(lcol, 1.0), false, maxf(2.0, cell * 0.045))
			"rf":
				_draw_symbol(int(ln.get("g", 0)), lpts[0], cell * 0.2, Color(lcol.darkened(0.15), 0.9))
			"da":
				for pt in [lpts[0], lpts[-1]]:
					draw_circle(pt, cell * 0.38, UI.SURFACE, true, -1.0, true)
					draw_circle(pt, cell * 0.38, Color(lcol, 1.0), false, maxf(2.0, cell * 0.045), true)
			"pl":   # the pill (first two cells) and an arrowhead at the end
				var a0 := lpts[0]
				var a1 := lpts[1]
				var half := Vector2(absf(a1.x - a0.x), absf(a1.y - a0.y)) / 2.0 + Vector2(cell, cell) * 0.36
				var pr := Rect2((a0 + a1) / 2.0 - half, half * 2.0)
				draw_style_box(UI.box(UI.SURFACE, Color(lcol, 1.0), int(cell * 0.36), int(maxf(2.0, cell * 0.045))), pr)
				var tip := lpts[-1]
				var dir := (tip - lpts[-2]).normalized()
				_arrow_head(tip, dir, cell * 0.2, Color(lcol, 1.0), lw)

	# Thermometers
	for ti in pz.thermos.size():
		var t: Array = pz.thermos[ti]
		var reveal := _reveal(ti)
		if reveal <= 0.0:
			continue
		var pts := PackedVector2Array()
		for c in t: pts.append(cell_center(c))
		var tcol := UI.THERMO
		var tw := cell * 0.26
		var shown := _partial(pts, reveal)
		draw_polyline(shown, tcol, tw, true)
		for pt in shown: draw_circle(pt, cell * 0.13, tcol, true, -1.0, true)
		draw_circle(pts[0], cell * 0.36 * minf(1.0, reveal * 2.0), tcol, true, -1.0, true)

	# Arrows
	for ai in pz.arrows.size():
		var a: Dictionary = pz.arrows[ai]
		if _reveal(pz.thermos.size() + pz.lines.size() + ai) <= 0.0:
			continue
		var cc := cell_center(a.circle)
		var rad := cell * 0.40
		draw_circle(cc, rad, UI.SURFACE, true, -1.0, true)
		draw_circle(cc, rad, UI.ARROW, false, maxf(2.0, cell * 0.045), true)
		var pts := PackedVector2Array()
		var first := cell_center(a.line[0])
		pts.append(cc + (first - cc).normalized() * rad)
		for c in a.line: pts.append(cell_center(c))
		var w := maxf(2.0, cell * 0.045)
		draw_polyline(pts, UI.ARROW, w, true)
		var tip := pts[-1]
		var dir := (tip - pts[-2]).normalized()
		var side := Vector2(-dir.y, dir.x)
		var hl := cell * 0.22
		draw_polyline(PackedVector2Array([tip - dir * hl + side * hl * 0.8, tip, tip - dir * hl - side * hl * 0.8]), UI.ARROW, w, true)

	# Thin grid
	var thin := Color(UI.INK, 0.16)
	for i in range(1, _n):
		var x := _rect.position.x + i * cell
		var y := _rect.position.y + i * cell
		draw_line(Vector2(x, _rect.position.y), Vector2(x, _rect.end.y), thin, 1.0)
		draw_line(Vector2(_rect.position.x, y), Vector2(_rect.end.x, y), thin, 1.0)

	# Region borders
	var thick := maxf(2.0, roundf(cell * 0.045))
	for c in (_n * _n if pz.uses_boxes() or pz.rule != "kenken" else 0):
		var r := cell_rect(c)
		if c % _n < _n - 1 and pz.regions[c] != pz.regions[c + 1]:
			draw_line(Vector2(r.end.x, r.position.y - thick / 2), Vector2(r.end.x, r.end.y + thick / 2), UI.INK, thick)
		if c / _n < _n - 1 and pz.regions[c] != pz.regions[c + _n]:
			draw_line(Vector2(r.position.x - thick / 2, r.end.y), Vector2(r.end.x + thick / 2, r.end.y), UI.INK, thick)
	if pz.variant == "toroidal":
		# the board wraps: the outer edge is thick only where the region changes across the wrap
		draw_rect(_rect, Color(UI.INK, 0.35), false, 1.0)
		for k in 9:
			var top := k
			var bottom := 72 + k
			var left := k * 9
			var right := k * 9 + 8
			if pz.regions[top] != pz.regions[bottom]:
				var r := cell_rect(top)
				draw_line(Vector2(r.position.x, _rect.position.y), Vector2(r.end.x, _rect.position.y), UI.INK, thick)
				draw_line(Vector2(r.position.x, _rect.end.y), Vector2(r.end.x, _rect.end.y), UI.INK, thick)
			if pz.regions[left] != pz.regions[right]:
				var r := cell_rect(left)
				draw_line(Vector2(_rect.position.x, r.position.y), Vector2(_rect.position.x, r.end.y), UI.INK, thick)
				draw_line(Vector2(_rect.end.x, r.position.y), Vector2(_rect.end.x, r.end.y), UI.INK, thick)
	else:
		draw_rect(_rect.grow(thick / 2), UI.INK, false, thick)

	# Killer cages
	var cage_label := {}
	if not pz.cages.is_empty():
		_draw_cages(pz, cage_label)

	# Kropki / XV
	for key in pz.edges:
		var parts: PackedStringArray = key.split(",")
		var a := int(parts[0]); var b := int(parts[1])
		var mid := (cell_center(a) + cell_center(b)) / 2.0
		var t: String = pz.edges[key]
		match t:
			"w":
				draw_circle(mid, cell * 0.11, UI.DOT_WHITE, true, -1.0, true)
				draw_circle(mid, cell * 0.11, UI.DOT_BLACK, false, maxf(1.5, cell * 0.03), true)
			"b":
				draw_circle(mid, cell * 0.11, UI.DOT_BLACK, true, -1.0, true)
				if UI.dark:
					draw_circle(mid, cell * 0.11, UI.INK, false, maxf(1.5, cell * 0.03), true)
			"c":
				var sz := Vector2(cell * 0.12, cell * 0.36) if b == a + 1 else Vector2(cell * 0.36, cell * 0.12)
				draw_rect(Rect2(mid - sz / 2.0, sz), UI.SURFACE)
				draw_rect(Rect2(mid - sz / 2.0, sz), UI.INK, false, maxf(1.5, cell * 0.03))
			">", "<":
				# the point faces the smaller cell, the open side the bigger one
				var dv := (cell_center(b if t == ">" else a) - mid).normalized()
				var pv := Vector2(-dv.y, dv.x)
				var k := cell * 0.08
				draw_polyline(PackedVector2Array([mid - dv * k + pv * k * 1.7, mid + dv * k, mid - dv * k - pv * k * 1.7]),
					UI.INK, maxf(2.0, cell * 0.04), true)
			_ when t.length() > 1 and t[0] in ["+", "*", "/", "-"]:
				var fs := int(cell * 0.25)
				var f := UI.font_sans_bold
				var txt: String = {"*": "×" + t.substr(1), "/": "1:" + t.substr(1), "-": t.substr(1)}.get(t[0], t)
				var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
				var rr := Rect2(mid - Vector2(sz.x / 2 + 4, fs * 0.55), Vector2(sz.x + 8, fs * 1.1))
				draw_style_box(UI.box(UI.SURFACE, UI.INK, int(fs * 0.55), 1), rr)
				draw_string(f, mid + Vector2(-sz.x / 2, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.INK)
			"s", "d":
				var dv := (cell_center(b) - cell_center(a)).normalized()
				var pv := Vector2(-dv.y, dv.x)
				var pts := PackedVector2Array()
				for i in 13:
					var x := -1.0 + i / 6.0
					pts.append(mid + dv * x * cell * 0.17 + pv * sin(x * PI) * cell * 0.065)
				var tw := maxf(2.0, cell * 0.04)
				draw_polyline(pts, UI.INK, tw, true)
				if t == "d":
					draw_line(mid - (dv * 0.07 + pv * 0.16) * cell, mid + (dv * 0.07 + pv * 0.16) * cell, UI.INK, tw, true)
			"x", "v":
				var fs := int(cell * 0.30)
				var f := UI.font_sans_bold
				var txt := t.to_upper()
				var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
				draw_rect(Rect2(mid - Vector2(sz.x / 2 + 2, fs * 0.42), Vector2(sz.x + 4, fs * 0.84)), UI.SURFACE)
				draw_string(f, mid + Vector2(-sz.x / 2, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.INK)

	_draw_extra_clues(pz)

	# Digits & notes
	var big := int(cell * 0.56)
	var small := int(cell * 0.21)
	for c in _n * _n:
		var v := session.values[c]
		var center := cell_center(c)
		if v != 0:
			var f: Font = UI.font_sans_medium   # entered digits as heavy as givens (they differ by colour)
			var col := UI.INK
			if not session.is_given(c):
				col = UI.HINT if session.hinted[c] else UI.ACCENT
			if GameState.settings.highlight_conflicts and _marked_wrong(c) and not session.is_given(c):
				col = UI.DANGER
			_draw_digit(f, v, center + Vector2(0, cell * 0.02), big, col, session.is_given(c))
			continue
		# Pencil marks. Corner marks sit in fixed keypad spots (1 2 3 / 4 5 6 / 7 8 9); under a cage sum
		# the rows are squeezed down so the top row clears the label. Centre marks go in the middle.
		# When a cell has both, nothing may overlap: the centre marks only use the space between the
		# corner 4 and 6 spots (wrapping to two lines / shrinking if needed) and corner 5 moves into
		# the top row, between 1 and 2.
		var cm := session.center[c]
		var km := session.corner[c]
		var rows := [-0.5, 0.25, 1.0] if cage_label.has(c) else [-1.0, 0.0, 1.0]
		if cm:
			var s := ""
			for d in range(1, 10):
				if cm & (1 << d): s += str(d)
			var f: Font = UI.font_sans
			var fs := int(small * 1.15)
			var mid := center
			var max_w := cell * 0.88
			if km:
				mid = center + Vector2(0, float(rows[1]) * cell * 0.31)
				max_w = cell * 0.40
			var lines: Array = [s]
			if not km and s.length() > 5:
				lines = [s.substr(0, 5), s.substr(5)]   # 6+ marks: two centred lines, 5 on the first
			elif f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w and km and s.length() > 2:
				var half := (s.length() + 1) / 2
				lines = [s.substr(0, half), s.substr(half)]
				fs = mini(fs, int(cell * 0.19))
			for ln in lines:
				var wdt := f.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				if wdt > max_w:
					fs = maxi(7, int(fs * max_w / wdt))
			var lh := fs * 0.95
			for i in lines.size():
				_draw_notes_row(c, lines[i], mid + Vector2(0, (i - (lines.size() - 1) / 2.0) * lh), fs)
		if km:
			for d in range(1, 10):
				if km & (1 << d):
					var off := Vector2((d - 1) % 3 - 1, rows[(d - 1) / 3]) * cell * 0.31
					if d == 5 and cm:
						off = Vector2(-0.5, float(rows[0])) * cell * 0.31   # make room for the centre marks
					_draw_digit(UI.font_sans, d, center + off, small, _note_color(c, d, UI.INK_MUTED), true)

	if not emphasis.is_empty():
		for c in _n * _n:
			if not emphasis.has(c):
				draw_rect(cell_rect(c), Color(UI.SURFACE, 0.62))
		for c in emphasis:
			draw_rect(cell_rect(c).grow(-1.5), UI.GOLD, false, 3.0)


## Shown in red: rule breaks always; on easy and medium also any placed digit that doesn't match the
## solution (the same rule that counts mistakes there). Givens and hinted digits are never wrong.
func _marked_wrong(c: int) -> bool:
	if session.conflicts[c]:
		return true
	if versus or session.puzzle.difficulty in Session.RULE_BREAK_LEVELS or session.is_given(c) or session.hinted[c]:
		return false
	return session.values[c] != 0 and session.values[c] != session.puzzle.solution[c]


func _note_color(c: int, d: int, normal: Color) -> Color:
	if not GameState.settings.get("color_notes", true):
		return normal
	return UI.NOTE_OK if session.note_possible(c, d) else UI.NOTE_BAD


## Centre marks drawn as one row, each digit coloured blue (possible) / red (blocked).
func _draw_notes_row(c: int, s: String, center: Vector2, fs: int) -> void:
	var f: Font = UI.font_sans
	var pz := session.puzzle
	var gap := fs * 0.18 if pz.variant == "roman" else 0.0
	var widths: Array = []
	var total := 0.0
	for ch in s:
		var w := fs * 0.62 if pz.variant == "color" else f.get_string_size(glyph_for(pz, int(ch)), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + gap
		widths.append(w)
		total += w
	var x := center.x - total / 2.0
	var y := center.y + (f.get_ascent(fs) - f.get_descent(fs)) / 2.0 - fs * 0.04
	for i in s.length():
		var d := int(s[i])
		if pz.variant == "color":
			draw_circle(Vector2(x + widths[i] / 2.0, center.y), fs * 0.26, Color(UI.CELL_COLORS[d], 1.0), true, -1.0, true)
		else:
			draw_string(f, Vector2(x, y), glyph_for(pz, d), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _note_color(c, d, UI.ACCENT))
		x += widths[i]


## A digit as this variant shows it: the glyph, or for Color Sudoku a coloured disc (a ring marks the
## player's own entries, a red ring a mistake).
func _draw_digit(f: Font, d: int, center: Vector2, fs: int, col: Color, given: bool) -> void:
	if session.puzzle.variant != "color":
		var g := glyph_for(session.puzzle, d)
		var fsz := fs if g.length() < 3 else int(fs * (0.7 if g.length() == 3 else 0.58))
		_draw_centered(f, g, center, fsz, col, maxi(3, int(fsz * 0.14)))
		return
	var r := fs * 0.42
	draw_circle(center, r, Color(UI.CELL_COLORS[d], 1.0), true, -1.0, true)
	draw_arc(center, r, 0, TAU, 32, Color(UI.INK, 0.35), 1.0, true)
	if not given:
		draw_arc(center, r + 3.0, 0, TAU, 32, col, 2.0, true)


## outline > 0: a ring of the board colour around the glyphs, so digits read clearly over lines and colours.
func _draw_centered(f: Font, s: String, center: Vector2, fs: int, col: Color, outline := 0) -> void:
	var sz := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var asc := f.get_ascent(fs)
	var desc := f.get_descent(fs)
	var at := Vector2(center.x - sz.x / 2.0, center.y + (asc - desc) / 2.0 - fs * 0.04)
	if outline > 0:
		draw_string_outline(f, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, Color(UI.SURFACE, 0.92))
	draw_string(f, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw_cages(pz: Puzzle, cage_label: Dictionary) -> void:
	var owner := PackedInt32Array()
	owner.resize(_n * _n)
	owner.fill(-1)
	for i in pz.cages.size():
		for c in pz.cages[i].cells:
			owner[c] = i
	var m := _cell * 0.09
	var col := Color(UI.INK, 0.62)
	var w := maxf(1.0, _cell * 0.022)
	var dash := maxf(3.0, _cell * 0.07)
	var same := func(c: int, dr: int, dc: int) -> bool:
		var r := c / _n + dr
		var k := c % _n + dc
		if r < 0 or r >= _n or k < 0 or k >= _n: return false
		return owner[r * _n + k] == owner[c]
	for c in _n * _n:
		if owner[c] < 0: continue
		var r := cell_rect(c)
		var x0 := r.position.x; var y0 := r.position.y; var x1 := r.end.x; var y1 := r.end.y
		var up: bool = same.call(c, -1, 0); var dn: bool = same.call(c, 1, 0)
		var lf: bool = same.call(c, 0, -1); var rt: bool = same.call(c, 0, 1)
		if not up:
			var sx := x0 + m if not lf else (x0 - m if same.call(c, -1, -1) else x0)
			var ex := x1 - m if not rt else (x1 + m if same.call(c, -1, 1) else x1)
			draw_dashed_line(Vector2(sx, y0 + m), Vector2(ex, y0 + m), col, w, dash)
		if not dn:
			var sx := x0 + m if not lf else (x0 - m if same.call(c, 1, -1) else x0)
			var ex := x1 - m if not rt else (x1 + m if same.call(c, 1, 1) else x1)
			draw_dashed_line(Vector2(sx, y1 - m), Vector2(ex, y1 - m), col, w, dash)
		if not lf:
			var sy := y0 + m if not up else (y0 - m if same.call(c, -1, -1) else y0)
			var ey := y1 - m if not dn else (y1 + m if same.call(c, 1, -1) else y1)
			draw_dashed_line(Vector2(x0 + m, sy), Vector2(x0 + m, ey), col, w, dash)
		if not rt:
			var sy := y0 + m if not up else (y0 - m if same.call(c, -1, 1) else y0)
			var ey := y1 - m if not dn else (y1 + m if same.call(c, 1, 1) else y1)
			draw_dashed_line(Vector2(x1 - m, sy), Vector2(x1 - m, ey), col, w, dash)
	var fs := int(_cell * 0.2)
	for cg in pz.cages:
		var first: int = cg.cells.min()
		cage_label[first] = true
		var r := cell_rect(first)
		var txt: String = str(cg.sum) + str({"+": "+", "-": "−", "*": "×", "/": "÷"}.get(str(cg.get("op", "")), ""))
		var sz := UI.font_sans_bold.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var pos := r.position + Vector2(m * 0.6, m * 0.4)
		draw_rect(Rect2(pos, Vector2(sz.x + 3, fs * 1.05)), UI.SURFACE)
		draw_string(UI.font_sans_bold, pos + Vector2(1.5, fs * 0.88), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.INK)


## Reflection start symbols: circle, square, triangle, diamond, hexagon (by group).
func _draw_symbol(g: int, at: Vector2, r: float, col: Color) -> void:
	match g % 5:
		0: draw_circle(at, r, col, true, -1.0, true)
		1: draw_rect(Rect2(at - Vector2(r, r) * 0.85, Vector2(r, r) * 1.7), col)
		_:
			var n: int = [3, 4, 6][g % 5 - 2]
			var pts := PackedVector2Array()
			for i in n:
				var ang := -PI / 2.0 + TAU * i / n
				pts.append(at + Vector2(cos(ang), sin(ang)) * r * 1.15)
			draw_colored_polygon(pts, col)


func _arrow_head(tip: Vector2, dir: Vector2, size: float, col: Color, w: float) -> void:
	var side := Vector2(-dir.y, dir.x)
	draw_polyline(PackedVector2Array([tip - dir * size + side * size * 0.8, tip, tip - dir * size - side * size * 0.8]), col, w, true)


## Outside clues, little killer sums, twisted squares, quadruples, cell marks, vertices, slingshots.
func _draw_extra_clues(pz: Puzzle) -> void:
	var cell := _cell
	var ink := UI.INK
	var m := floorf(OUTER_MARGIN * cell)

	for o in pz.outer:
		var i: int = o.i
		var at := Vector2.ZERO
		match o.s:
			"L": at = Vector2(_rect.position.x - m / 2.0, _rect.position.y + (i + 0.5) * cell)
			"R": at = Vector2(_rect.end.x + m / 2.0, _rect.position.y + (i + 0.5) * cell)
			"T": at = Vector2(_rect.position.x + (i + 0.5) * cell, _rect.position.y - m / 2.0)
			_: at = Vector2(_rect.position.x + (i + 0.5) * cell, _rect.end.y + m / 2.0)
		if o.t == "ro":   # Rossini: arrow pointing the way the first three digits go up; 0 = no arrow
			if int(o.v) == 0:
				continue
			var inward := {"L": Vector2.RIGHT, "R": Vector2.LEFT, "T": Vector2.DOWN, "B": Vector2.UP}[o.s] as Vector2
			var dv := inward if int(o.v) == 1 else -inward
			var aw := maxf(2.0, cell * 0.045)
			draw_line(at - dv * cell * 0.22, at + dv * cell * 0.22, ink, aw, true)
			_arrow_head(at + dv * cell * 0.22, dv, cell * 0.12, ink, aw)
			continue
		_draw_centered(UI.font_sans_medium, str(o.v), at, int(cell * 0.36), ink)

	for sm in pz.sums:
		var o: Array = sm.o
		if o.is_empty():
			continue   # a sum without an outside clue (magic square lines)
		var dv := Vector2(sm.dir[1], sm.dir[0]).normalized()
		var vc := _rect.position + (Vector2(o[1], o[0]) + Vector2(0.5, 0.5)) * cell
		# pull the clue into the margin band next to the grid
		vc.x = clampf(vc.x, _rect.position.x - m / 2.0, _rect.end.x + m / 2.0)
		vc.y = clampf(vc.y, _rect.position.y - m / 2.0, _rect.end.y + m / 2.0)
		_draw_centered(UI.font_sans_medium, str(sm.sum), vc - dv * cell * 0.1, int(cell * 0.28), ink)
		var a0 := vc + dv * cell * 0.2
		var a1 := vc + dv * cell * 0.42
		var aw := maxf(1.5, cell * 0.03)
		draw_line(a0, a1, ink, aw, true)
		_arrow_head(a1, dv, cell * 0.08, ink, aw)

	for t in pz.twists:
		var at := cell_rect(int(t)).end
		var half := Vector2(cell, cell) * 0.13
		draw_rect(Rect2(at - half, half * 2.0), UI.SURFACE)
		draw_rect(Rect2(at - half, half * 2.0), ink, false, maxf(1.5, cell * 0.03))

	for q in pz.quads:
		var at := cell_rect(int(q.c)).end
		var rad := cell * 0.27
		draw_circle(at, rad, UI.SURFACE, true, -1.0, true)
		draw_circle(at, rad, ink, false, maxf(1.5, cell * 0.03), true)
		var ds: Array = q.d
		var fs := int(cell * 0.18)
		if ds.size() <= 2:
			_draw_centered(UI.font_sans_medium, " ".join(PackedStringArray(ds.map(func(x): return str(x)))), at, fs, ink)
		else:
			var top := " ".join(PackedStringArray(ds.slice(0, 2).map(func(x): return str(x))))
			var bot := " ".join(PackedStringArray(ds.slice(2).map(func(x): return str(x))))
			_draw_centered(UI.font_sans_medium, top, at - Vector2(0, fs * 0.5), fs, ink)
			_draw_centered(UI.font_sans_medium, bot, at + Vector2(0, fs * 0.5), fs, ink)

	for k in pz.marks:
		var mc := int(k)
		var t: String = pz.marks[k]
		if t == "mn" or t == "mx":
			var rr := cell_rect(mc)
			_draw_centered(UI.font_sans_bold, "MIN" if t == "mn" else "MAX", rr.position + Vector2(cell * 0.5, cell * 0.86),
				int(cell * 0.14), Color(UI.INK, 0.55))
			continue
		if t == "fo":
			continue
		if t in ["pm", "cm", "d2", "d3", "d4"]:   # small label in the top-left corner
			var lbl: String = {"pm": "P", "cm": "C", "d2": "÷2", "d3": "÷3", "d4": "÷4"}[t]
			var lr := cell_rect(mc)
			draw_rect(lr.grow(-1), Color(UI.ACCENT, 0.07))
			_draw_centered(UI.font_sans_bold, lbl, lr.position + Vector2(cell * (0.2 if lbl.length() == 1 else 0.24), cell * 0.19), int(cell * 0.24), UI.ACCENT)
			continue
		if t.begins_with("x") and t.length() == 2:   # forbidden digit: small crossed-out digit, bottom right
			var at := cell_rect(mc).position + Vector2(cell * 0.8, cell * 0.8)
			var fcol := Color(UI.DANGER, 0.75)
			_draw_centered(UI.font_sans_bold, glyph_for(pz, int(t[1])), at, int(cell * 0.2), fcol)
			draw_line(at + Vector2(-cell * 0.1, cell * 0.08), at + Vector2(cell * 0.1, -cell * 0.08), fcol, 1.6, true)
			continue
		var r := cell_rect(mc)
		var ctr := cell_center(mc)
		match t:
			"ax":   # short ticks pointing along both diagonals
				var acol := Color(UI.ACCENT, 0.55)
				for dv in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
					draw_line(ctr + dv * cell * 0.33, ctr + dv * cell * 0.47, acol, maxf(2.0, cell * 0.045), true)
			"fr":   # faint heart behind the digit
				var pts := PackedVector2Array()
				for i in 40:
					var a := TAU * i / 40.0
					var hx := 16.0 * pow(sin(a), 3)
					var hy := 13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a)
					pts.append(ctr + Vector2(hx, -hy - 2.0) * cell * 0.024)
				draw_colored_polygon(pts, Color(0.92, 0.32, 0.48, 0.2 if not UI.dark else 0.3))
			"pu":   # two rings
				var pcol := Color(0.86, 0.27, 0.36, 0.6)
				draw_arc(ctr, cell * 0.43, 0, TAU, 40, pcol, maxf(1.5, cell * 0.03), true)
				draw_arc(ctr, cell * 0.35, 0, TAU, 40, Color(pcol, 0.3), maxf(1.0, cell * 0.02), true)
			_:   # index lookup: double arrow along the bottom (row) and/or right side (column)
				var icol := Color(UI.ACCENT, 0.6)
				var iw := maxf(1.5, cell * 0.03)
				if t.contains("h"):
					var y := r.end.y - cell * 0.1
					var p0 := Vector2(r.position.x + cell * 0.12, y)
					var p1 := Vector2(r.end.x - cell * 0.12, y)
					draw_line(p0, p1, icol, iw, true)
					_arrow_head(p1, Vector2.RIGHT, cell * 0.07, icol, iw)
					_arrow_head(p0, Vector2.LEFT, cell * 0.07, icol, iw)
				if t.contains("v"):
					var x := r.end.x - cell * 0.1
					var p0 := Vector2(x, r.position.y + cell * 0.12)
					var p1 := Vector2(x, r.end.y - cell * 0.12)
					draw_line(p0, p1, icol, iw, true)
					_arrow_head(p1, Vector2.DOWN, cell * 0.07, icol, iw)
					_arrow_head(p0, Vector2.UP, cell * 0.07, icol, iw)

	var vcol := Color(0.16, 0.63, 0.60, 0.75)
	for vx in pz.vertices:
		var tp := cell_center(vx.tip)
		draw_polyline(PackedVector2Array([cell_center(vx.a), tp, cell_center(vx.b)]), vcol, maxf(2.0, cell * 0.06), true)
		draw_circle(tp, cell * 0.08, vcol, true, -1.0, true)

	var scol := Color(0.48, 0.36, 0.84, 0.9)
	var sw := maxf(2.0, cell * 0.045)
	for sl in pz.slings:
		# a small bent arrow in the corner of the arrow cell: in from the source side, out towards dir
		var ac := cell_center(sl.a)
		var u := (ac - cell_center(sl.s)).normalized()
		var dv := Vector2(sl.dir[1], sl.dir[0])
		var p0 := ac - u * cell * 0.46 + dv * cell * 0.26
		var bend := ac - u * cell * 0.24 + dv * cell * 0.26
		var p1 := ac - u * cell * 0.24 + dv * cell * 0.46
		draw_polyline(PackedVector2Array([p0, bend, p1]), scol, sw, true)
		_arrow_head(p1, dv, cell * 0.08, scol, sw)
