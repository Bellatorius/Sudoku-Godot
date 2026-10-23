class_name VariantIcon
extends Control
## Small icon for a variant: a tiny board showing its clue (STYLE 2) or the original line art (STYLE 1).

var variant := "classic"
var color := Color("#0e0e12")


func _init(id := "classic", px := 34) -> void:
	variant = id
	color = UI.INK
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 1 = the original line-art icons (kept for rollback), 2 = tiny boards showing each variant's clue.
const STYLE := 2
## Variants that keep the original icon even with STYLE 2 (the user picks per variant).
const OLD_STYLE: Array = []
var style := 0   # 0 = STYLE / OLD_STYLE decide; 1 or 2 forces one (comparison sheet)


func _draw() -> void:
	var st := style if style != 0 else (1 if STYLE == 1 or OLD_STYLE.has(variant.trim_prefix("mini_")) else 2)
	if st == 1:
		_draw_v1()
	else:
		_draw_v2()


func _draw_v1() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) / 2.0
	var w := maxf(1.6, s * 0.075)
	var P := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	var line := func(a: Vector2, b: Vector2, ww := w): draw_line(a, b, color, ww, true)
	var ring := func(c: Vector2, r: float): draw_arc(c, r, 0, TAU, 32, color, w, true)
	var dot := func(c: Vector2, r: float): draw_circle(c, r, color, true, -1.0, true)
	var txt := func(t: String, c: Vector2, fs: int):
		var f: Font = UI.font_sans_bold
		var sz := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(f, c + Vector2(-sz.x / 2, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)

	var vid := variant.trim_prefix("mini_")
	match vid:   # Mini variants use their rule's icon plus a "6" badge
		"classic":
			line.call(P.call(0.38, 0.12), P.call(0.32, 0.88)); line.call(P.call(0.68, 0.12), P.call(0.62, 0.88))
			line.call(P.call(0.14, 0.36), P.call(0.88, 0.36)); line.call(P.call(0.12, 0.64), P.call(0.86, 0.64))
		"arrow":
			ring.call(P.call(0.3, 0.7), s * 0.14)
			line.call(P.call(0.4, 0.6), P.call(0.82, 0.18))
			line.call(P.call(0.82, 0.18), P.call(0.56, 0.2)); line.call(P.call(0.82, 0.18), P.call(0.8, 0.44))
		"thermo", "slow_thermo":
			dot.call(P.call(0.26, 0.74), s * 0.16)
			line.call(P.call(0.26, 0.74), P.call(0.8, 0.2), s * 0.14)
			dot.call(P.call(0.8, 0.2), s * 0.07)
		"killer", "little_killer":
			var r := Rect2(P.call(0.14, 0.14), Vector2(s, s) * 0.72)
			for e in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.end.x, r.position.y), r.end], [r.end, Vector2(r.position.x, r.end.y)], [Vector2(r.position.x, r.end.y), r.position]]:
				draw_dashed_line(e[0], e[1], color, w * 0.8, s * 0.1, true, true)
			txt.call("12", P.call(0.42, 0.38), int(s * 0.3))
		"jigsaw", "toroidal":
			var pts := [P.call(0.12, 0.12), P.call(0.55, 0.12), P.call(0.55, 0.4), P.call(0.88, 0.4), P.call(0.88, 0.88), P.call(0.4, 0.88), P.call(0.4, 0.6), P.call(0.12, 0.6), P.call(0.12, 0.12)]
			draw_polyline(PackedVector2Array(pts), color, w, true)
		"diagonal", "axia", "bishop", "anti_diagonal", "argyle":
			draw_rect(Rect2(P.call(0.14, 0.14), Vector2(s, s) * 0.72), color, false, w)
			line.call(P.call(0.14, 0.14), P.call(0.86, 0.86)); line.call(P.call(0.86, 0.14), P.call(0.14, 0.86))
		"kropki":
			draw_rect(Rect2(P.call(0.08, 0.3), Vector2(s * 0.84, s * 0.4)), color, false, w)
			line.call(P.call(0.5, 0.3), P.call(0.5, 0.7))
			draw_circle(P.call(0.5, 0.5), s * 0.11, UI.PAPER, true, -1.0, true)
			ring.call(P.call(0.5, 0.5), s * 0.11)
		"xv":
			txt.call("XV", P.call(0.5, 0.5), int(s * 0.5))
		"consecutive", "twisted", "non_consecutive":
			draw_rect(Rect2(P.call(0.08, 0.3), Vector2(s * 0.84, s * 0.4)), color, false, w)
			draw_rect(Rect2(P.call(0.44, 0.38), Vector2(s * 0.12, s * 0.24)), color, false, w * 0.8)
		"greater_than":
			txt.call(">", P.call(0.5, 0.5), int(s * 0.7))
		"even_odd":
			draw_rect(Rect2(P.call(0.1, 0.3), Vector2(s, s) * 0.36), color, false, w)
			ring.call(P.call(0.72, 0.5), s * 0.18)
		"king":
			draw_polyline(PackedVector2Array([P.call(0.14, 0.72), P.call(0.14, 0.3), P.call(0.34, 0.5), P.call(0.5, 0.24), P.call(0.66, 0.5), P.call(0.86, 0.3), P.call(0.86, 0.72), P.call(0.14, 0.72)]), color, w, true)
		"knight":
			draw_polyline(PackedVector2Array([P.call(0.25, 0.85), P.call(0.25, 0.2), P.call(0.75, 0.2)]), color, w, true)
			dot.call(P.call(0.25, 0.85), s * 0.08); dot.call(P.call(0.75, 0.2), s * 0.08)
		"sandwich":
			line.call(P.call(0.12, 0.28), P.call(0.88, 0.28)); line.call(P.call(0.12, 0.72), P.call(0.88, 0.72))
			line.call(P.call(0.22, 0.5), P.call(0.78, 0.5), w * 0.7)
		"skyscraper":
			for i in 4:
				var h: float = [0.3, 0.6, 0.45, 0.75][i]
				draw_rect(Rect2(P.call(0.12 + i * 0.2, 0.88 - h), Vector2(s * 0.14, s * h)), color)
		"ascending", "running":
			for i in 4:
				var h: float = 0.2 + i * 0.18
				draw_rect(Rect2(P.call(0.12 + i * 0.2, 0.86 - h), Vector2(s * 0.14, s * h)), color)
		"windoku", "universal":
			for x in 2:
				for y in 2:
					draw_rect(Rect2(P.call(0.14 + x * 0.4, 0.14 + y * 0.4), Vector2(s, s) * 0.3), color, false, w)
		"german_whispers", "dutch_whispers", "renban", "palindrome", "zipper", "reflection", "lockout", "between", 				"region_sum", "entropic", "modular", "parity_lines", "nabner", "ten_lines", "double_arrow", 				"product_lines", "difference_lines", "ratio_lines":
			var cols := {"german_whispers": Color("#2fb36b"), "dutch_whispers": Color("#f08a24"), "renban": Color("#c14fd6"), "palindrome": Color("#3fa6e8"),
				"region_sum": Color("#4db8db"), "entropic": Color("#d98c40"), "modular": Color("#33a094"), "parity_lines": Color("#e65c73"),
				"nabner": Color("#ebcc33"), "ten_lines": Color("#808fad"), "product_lines": Color("#9e6bd9"),
				"difference_lines": Color("#f2734d"), "ratio_lines": Color("#4dbf8c")}
			var lc: Color = cols.get(vid, color)
			draw_polyline(PackedVector2Array([P.call(0.14, 0.78), P.call(0.4, 0.4), P.call(0.62, 0.62), P.call(0.86, 0.22)]), lc, w * 1.4, true)
			if vid == "between" or vid == "lockout" or vid == "double_arrow":
				draw_circle(P.call(0.14, 0.78), s * 0.11, UI.PAPER, true, -1.0, true); ring.call(P.call(0.14, 0.78), s * 0.11)
				draw_circle(P.call(0.86, 0.22), s * 0.11, UI.PAPER, true, -1.0, true); ring.call(P.call(0.86, 0.22), s * 0.11)
		"quadruple":
			line.call(P.call(0.5, 0.1), P.call(0.5, 0.9)); line.call(P.call(0.1, 0.5), P.call(0.9, 0.5))
			draw_circle(P.call(0.5, 0.5), s * 0.2, UI.PAPER, true, -1.0, true); ring.call(P.call(0.5, 0.5), s * 0.2)
		"pill_arrow":
			draw_rect(Rect2(P.call(0.1, 0.12), Vector2(s * 0.5, s * 0.26)), color, false, w)
			line.call(P.call(0.6, 0.25), P.call(0.84, 0.82))
			line.call(P.call(0.84, 0.82), P.call(0.62, 0.72)); line.call(P.call(0.84, 0.82), P.call(0.88, 0.58))
		"fortress":
			draw_rect(Rect2(P.call(0.36, 0.36), Vector2(s, s) * 0.28), color)
			draw_rect(Rect2(P.call(0.08, 0.08), Vector2(s, s) * 0.84), color, false, w)
		"min_max":
			txt.call("<>", P.call(0.5, 0.48), int(s * 0.55))
		"clone":
			draw_rect(Rect2(P.call(0.1, 0.14), Vector2(s * 0.34, s * 0.3)), color)
			draw_rect(Rect2(P.call(0.56, 0.56), Vector2(s * 0.34, s * 0.3)), color)
		"frame", "numbered_rooms", "battlefield", "missing_digit":
			draw_rect(Rect2(P.call(0.3, 0.3), Vector2(s, s) * 0.6), color, false, w)
			txt.call({"frame": "15", "numbered_rooms": "4", "battlefield": "8", "missing_digit": "7"}[vid], P.call(0.16, 0.16), int(s * 0.3))
		"rossini":
			draw_rect(Rect2(P.call(0.3, 0.3), Vector2(s, s) * 0.6), color, false, w)
			line.call(P.call(0.04, 0.6), P.call(0.22, 0.6)); line.call(P.call(0.22, 0.6), P.call(0.14, 0.52)); line.call(P.call(0.22, 0.6), P.call(0.14, 0.68))
		"sum_product_dots":
			txt.call("×", P.call(0.5, 0.48), int(s * 0.8))
		"center_dot", "asterisk", "girandola":
			for x in 3:
				for y in 3:
					dot.call(P.call(0.2 + x * 0.3, 0.2 + y * 0.3), s * 0.06)
		"ratio_dots", "difference_dots", "prime_composite", "forbidden_digit", "divisibility", "kenken", "alphabet", "wordoku", 				"symbol", "roman":
			var t: String = {"ratio_dots": "1:2", "difference_dots": "Δ", "prime_composite": "P", "forbidden_digit": "✕",
				"divisibility": "÷", "kenken": "+×", "alphabet": "A", "wordoku": "W", "symbol": "★", "roman": "IV"}[vid]
			txt.call(t, P.call(0.5, 0.48), int(s * (0.42 if t.length() > 1 else 0.7)))
		"color":
			for i in 3:
				draw_circle(P.call(0.22 + i * 0.28, 0.5), s * 0.12, UI.CELL_COLORS[1 + i * 3], true, -1.0, true)
		"parity_regions":
			draw_rect(Rect2(P.call(0.12, 0.12), Vector2(s * 0.46, s * 0.46)), Color(color, 0.35))
			draw_rect(Rect2(P.call(0.42, 0.42), Vector2(s * 0.46, s * 0.46)), color, false, w)
		"queen":
			txt.call("♛", P.call(0.5, 0.46), int(s * 0.75))
		"miracle":
			txt.call("✦", P.call(0.5, 0.46), int(s * 0.75))
		"magic_square":
			txt.call("15", P.call(0.5, 0.5), int(s * 0.45))
		"friendly":
			txt.call("♥", P.call(0.5, 0.48), int(s * 0.7))
		"xsum":
			txt.call("Σ", P.call(0.5, 0.48), int(s * 0.7))
		"vertex":
			line.call(P.call(0.18, 0.22), P.call(0.5, 0.78)); line.call(P.call(0.5, 0.78), P.call(0.82, 0.22))
			dot.call(P.call(0.5, 0.78), s * 0.09)
		"pulse":
			ring.call(P.call(0.5, 0.5), s * 0.34); ring.call(P.call(0.5, 0.5), s * 0.16)
		"couples":
			txt.call("~", P.call(0.5, 0.44), int(s * 0.9))
		"index":
			line.call(P.call(0.12, 0.5), P.call(0.88, 0.5))
			line.call(P.call(0.12, 0.5), P.call(0.3, 0.32)); line.call(P.call(0.12, 0.5), P.call(0.3, 0.68))
			line.call(P.call(0.88, 0.5), P.call(0.7, 0.32)); line.call(P.call(0.88, 0.5), P.call(0.7, 0.68))
		"slingshot":
			line.call(P.call(0.15, 0.75), P.call(0.6, 0.75)); line.call(P.call(0.6, 0.75), P.call(0.6, 0.15))
			line.call(P.call(0.6, 0.15), P.call(0.42, 0.33)); line.call(P.call(0.6, 0.15), P.call(0.78, 0.33))
		"dutch_flatmates":
			txt.call("1", P.call(0.5, 0.2), int(s * 0.36)); txt.call("5", P.call(0.5, 0.5), int(s * 0.36))
			txt.call("9", P.call(0.5, 0.8), int(s * 0.36))
		_:
			for x in 3:
				for y in 3:
					var rr := Rect2(P.call(0.12 + x * 0.27, 0.12 + y * 0.27), Vector2(s, s) * 0.2)
					if (x + y) % 2 == 0:
						draw_rect(rr, color)
					else:
						draw_rect(rr, color, false, w * 0.6)
	if variant.begins_with("mini_"):
		var bc: Vector2 = P.call(0.86, 0.86)
		draw_circle(bc, s * 0.2, UI.ACCENT, true, -1.0, true)
		var bf: Font = UI.font_sans_bold
		var bfs := int(s * 0.26)
		var bsz := bf.get_string_size("6", HORIZONTAL_ALIGNMENT_LEFT, -1, bfs)
		draw_string(bf, bc + Vector2(-bsz.x / 2, bfs * 0.36), "6", HORIZONTAL_ALIGNMENT_LEFT, -1, bfs, Color.WHITE)


# ----------------------------------------------------------------- style 2: tiny boards
# Each icon is a little piece of board (3x3 cells, or a row of 3 with an outside clue) showing the
# variant's clue the way it looks in a puzzle, with real digits, so the icon explains the rule.

var _o := Vector2.ZERO   # top-left of the mini grid
var _cs := 0.0           # cell size
var _n := 3

## Dots, signs and cages are shown on 2x2 bigger cells so their labels have room.
const _TWO := ["kropki", "xv", "consecutive", "twisted", "greater_than", "couples", "sum_product_dots", "ratio_dots",
	"difference_dots", "quadruple", "killer", "kenken", "prime_composite", "divisibility", "forbidden_digit", "slingshot"]
## Outside-clue variants get room on the left / top for their clue.
const _OUTSIDE := ["sandwich", "skyscraper", "xsum", "ascending", "running", "frame", "numbered_rooms", "rossini",
	"battlefield", "missing_digit", "little_killer"]


func _draw_v2() -> void:
	var s := minf(size.x, size.y)
	var vid := variant.trim_prefix("mini_")
	var off := (size - Vector2(s, s)) / 2.0
	_n = 2 if vid in _TWO else 3
	if vid in _OUTSIDE:
		_cs = s / 3.7
		_o = off + Vector2(s - 3.0 * _cs, (s - 3.0 * _cs) * (0.5 if vid != "little_killer" else 1.0))
	else:
		_cs = s / _n
		_o = off
	_grid(vid != "kenken")
	var ink := color
	var lc: Dictionary = Board.LINE_COLORS
	match vid:
		"classic":
			for i in 9:
				_d(i / 3, i % 3, str(i + 1), ink, 0.5)
		"jigsaw":
			_wall([Vector2(1, 0), Vector2(1, 1), Vector2(2, 1), Vector2(2, 3)])
			_d(0, 0, "4"); _d(1, 2, "7"); _d(2, 0, "2")
		"toroidal":
			_wall([Vector2(0, 1), Vector2(2, 1), Vector2(2, 2), Vector2(3, 2)])
			_arrow_head(_o + Vector2(3, 1.5) * _cs + Vector2(_cs * 0.1, 0), Vector2.RIGHT, _cs * 0.28, UI.ACCENT)
			_arrow_head(_o + Vector2(0, 1.5) * _cs + Vector2(_cs * 0.32, 0), Vector2.RIGHT, _cs * 0.28, UI.ACCENT)
		"diagonal":
			_path([Vector2(0, 0), Vector2(2, 2)], Board.C_DIAG, 0.16, false)
			_d(0, 0, "1"); _d(1, 1, "5"); _d(2, 2, "9")
		"anti_diagonal":
			_path([Vector2(0, 0), Vector2(2, 2)], Color(UI.GOLD, 0.45), 0.16, false)
			_d(0, 0, "2"); _d(1, 1, "7"); _d(2, 2, "2")
		"windoku":
			draw_rect(Rect2(_o + Vector2(_cs, _cs) * 0.5, Vector2(_cs, _cs) * 2.0), Color(UI.ACCENT, 0.18))
			_d(1, 1, "5")
		"universal":
			for r in 3:
				for c in 3:
					draw_circle(_o + Vector2(c + 0.28, r + 0.28) * _cs, _cs * 0.12, UI.ACCENT, true, -1.0, true)
			_d(1, 1, "4", ink, 0.5)
		"center_dot":
			_shade(1, 1, Color(UI.ACCENT, 0.25)); _d(1, 1, "6")
		"asterisk":
			for p in [[0, 1], [1, 2], [2, 0]]:
				_shade(p[0], p[1], Color(UI.ACCENT, 0.25))
			_d(0, 1, "3"); _d(2, 0, "8")
		"girandola":
			for p in [[0, 0], [0, 2], [2, 0], [2, 2]]:
				_shade(p[0], p[1], Color(UI.ACCENT, 0.25))
			_d(0, 0, "1"); _d(2, 2, "6")
		"argyle":
			_path([Vector2(0, 1), Vector2(1, 2)], Board.C_DIAG, 0.14, false)
			_path([Vector2(1, 0), Vector2(2, 1)], Board.C_DIAG, 0.14, false)
			_d(0, 1, "2"); _d(1, 2, "6"); _d(2, 1, "4")
		"magic_square":
			draw_rect(Rect2(_o, Vector2(_cs, _cs) * 3.0), Color(UI.GOLD, 0.12))
			var ms := "276951438"
			for i in 9:
				_d(i / 3, i % 3, ms[i], ink, 0.5)
		# lines
		"thermo":
			_thermo([Vector2(2, 0), Vector2(1, 1), Vector2(0, 2)], UI.THERMO)
			_d(2, 0, "1"); _d(1, 1, "4"); _d(0, 2, "8")
		"slow_thermo":
			_thermo([Vector2(2, 0), Vector2(1, 1), Vector2(0, 2)], lc.st)
			_d(2, 0, "2"); _d(1, 1, "2"); _d(0, 2, "5")
		"german_whispers":
			_line3(lc.gw, "1", "7", "2", true)
		"dutch_whispers":
			_line3(lc.dw, "1", "6", "2", true)
		"renban":
			_line3(lc.rb, "4", "2", "3")
		"palindrome":
			_line3(lc.pal, "3", "8", "3")
		"between":
			_path([Vector2(1, 0), Vector2(1, 2)], lc.bt, 0.07)
			_end_ring(1, 0, lc.bt); _end_ring(1, 2, lc.bt)
			_d(1, 0, "2"); _d(1, 1, "5"); _d(1, 2, "9")
		"lockout":
			_path([Vector2(1, 0), Vector2(1, 2)], lc.lo, 0.09)
			_end_square(1, 0, lc.lo); _end_square(1, 2, lc.lo)
			_d(1, 0, "1"); _d(1, 1, "8"); _d(1, 2, "6")
		"zipper":
			_line3(lc.zp, "2", "7", "5")
		"bishop":
			_path([Vector2(0, 0), Vector2(2, 2)], lc.bi, 0.16)
			_d(0, 0, "3"); _d(1, 1, "8"); _d(2, 2, "1")
		"reflection":
			_path([Vector2(0, 0), Vector2(0, 2)], lc.rf, 0.16)
			_path([Vector2(2, 0), Vector2(2, 2)], lc.rf, 0.16)
			draw_circle(_c(0, 0), _cs * 0.16, Color(lc.rf, 1.0), true, -1.0, true)
			draw_circle(_c(2, 0), _cs * 0.16, Color(lc.rf, 1.0), true, -1.0, true)
			_d(0, 1, "6"); _d(2, 1, "6"); _d(0, 2, "2"); _d(2, 2, "2")
		"region_sum":
			_wall([Vector2(2, 0), Vector2(2, 3)])
			_line3(lc.rs, "4", "3", "7")
		"entropic":
			_line3(lc.en, "1", "5", "9")
		"modular":
			_line3(lc.mo, "3", "4", "8")
		"parity_lines":
			_line3(lc.pa, "2", "7", "4")
		"nabner":
			_line3(lc.nb, "1", "4", "9")
		"product_lines":
			_wall([Vector2(2, 0), Vector2(2, 3)])
			_line3(lc.pr, "2", "3", "6")
		"difference_lines":
			_line3(lc.df, "1", "4", "7")
		"ratio_lines":
			_line3(lc.rt, "2", "4", "8")
		"ten_lines":
			_path([Vector2(0, 0), Vector2(1, 0), Vector2(1, 2)], lc.tn, 0.16)
			_d(0, 0, "3"); _d(1, 0, "7"); _d(1, 1, "1"); _d(1, 2, "9")
		# sums & arrows
		"killer":
			_cage(0, 0, 1, 0, "11")
			_d(0, 0, "5", color, 0.5); _d(1, 0, "6", color, 0.5); _d(0, 1, "2", color, 0.5)
		"kenken":
			_cage(0, 0, 1, 0, "6×")
			_d(0, 0, "2", color, 0.5); _d(1, 0, "3", color, 0.5); _d(1, 1, "1", color, 0.5)
		"little_killer":
			_small("15", _o + Vector2(-0.5, -0.45) * _cs, ink, 0.62)
			_arrow_head(_o + Vector2(0.08, 0.08) * _cs, Vector2(1, 1).normalized(), _cs * 0.24, ink)
			_d(0, 0, "4"); _d(1, 1, "5"); _d(2, 2, "6")
		"arrow":
			_path([Vector2(2, 0), Vector2(1, 1), Vector2(0, 2)], UI.ARROW, 0.05, false)
			_arrow_head(_c(0, 2) + Vector2(0.22, -0.22) * _cs, Vector2(1, -1).normalized(), _cs * 0.24, UI.ARROW)
			_end_ring(2, 0, UI.ARROW, 0.4)
			_d(2, 0, "9"); _d(1, 1, "4"); _d(0, 2, "5")
		"double_arrow":
			_path([Vector2(1, 0), Vector2(1, 2)], lc.da, 0.07)
			_end_ring(1, 0, lc.da); _end_ring(1, 2, lc.da)
			_d(1, 0, "3"); _d(1, 1, "7"); _d(1, 2, "4")
		"pill_arrow":
			var pr := Rect2(_c(0, 0) - Vector2(_cs, _cs) * 0.38, Vector2(_cs * 1.76, _cs * 0.76))
			draw_style_box(UI.box(Color(0, 0, 0, 0), UI.ARROW, int(_cs * 0.38), 2), pr)
			_path([Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)], UI.ARROW, 0.05, false)
			_arrow_head(_c(2, 1) + Vector2(0, 0.3) * _cs, Vector2.DOWN, _cs * 0.24, UI.ARROW)
			_d(0, 0, "1"); _d(0, 1, "2"); _d(1, 1, "5"); _d(2, 1, "7")
		# outside clues
		"sandwich": _row("5", "1", "5", "9")
		"skyscraper": _row("2", "1", "3", "2")
		"xsum": _row("6", "2", "4", "1")
		"ascending": _row("1", "1", "2", "3")
		"running": _row("3", "4", "5", "6")
		"frame": _row("15", "4", "5", "6")
		"numbered_rooms": _row("7", "2", "7", "5")
		"battlefield": _row("3", "2", "4", "1")
		"missing_digit": _row("7", "1", "2", "3")
		"rossini":
			_row("", "1", "4", "8")
			var at := _o + Vector2(-0.5, 1.5) * _cs
			draw_line(at - Vector2(_cs * 0.25, 0), at + Vector2(_cs * 0.2, 0), ink, maxf(1.5, _cs * 0.08), true)
			_arrow_head(at + Vector2(_cs * 0.22, 0), Vector2.RIGHT, _cs * 0.18, ink)
		# dots & signs
		"kropki":
			_d(0, 0, "3"); _d(0, 1, "4"); _d(1, 1, "8")
			_edot(0, 0, 0, 1, false); _edot(0, 1, 1, 1, true)
		"xv":
			_d(0, 0, "2"); _d(0, 1, "3"); _d(1, 0, "4"); _d(1, 1, "6")
			_etext(0, 0, 0, 1, "V"); _etext(1, 0, 1, 1, "X")
		"consecutive":
			_d(0, 0, "5"); _d(0, 1, "6")
			var mid := (_c(0, 0) + _c(0, 1)) / 2.0
			var bsz := Vector2(_cs * 0.16, _cs * 0.5)
			draw_rect(Rect2(mid - bsz / 2.0, bsz), UI.SURFACE)
			draw_rect(Rect2(mid - bsz / 2.0, bsz), ink, false, maxf(1.0, _cs * 0.06))
		"twisted":
			_d(0, 0, "3"); _d(1, 1, "4"); _d(0, 1, "7"); _d(1, 0, "6")
			var corner := _o + Vector2(1, 1) * _cs
			var half := Vector2(_cs, _cs) * 0.14
			draw_rect(Rect2(corner - half, half * 2.0), UI.SURFACE)
			draw_rect(Rect2(corner - half, half * 2.0), ink, false, maxf(1.0, _cs * 0.06))
		"greater_than":
			_d(0, 0, "7"); _d(0, 1, "2"); _etext(0, 0, 0, 1, ">")
		"couples":
			_d(0, 0, "2"); _d(0, 1, "8"); _etext(0, 0, 0, 1, "~")
		"sum_product_dots":
			_d(0, 0, "3", color, 0.42); _d(0, 1, "4", color, 0.42); _ebubble(0, 0, 0, 1, "+7")
		"ratio_dots":
			_d(0, 0, "3", color, 0.42); _d(0, 1, "6", color, 0.42); _ebubble(0, 0, 0, 1, "1:2")
		"difference_dots":
			_d(0, 0, "2", color, 0.42); _d(0, 1, "5", color, 0.42); _ebubble(0, 0, 0, 1, "3")
		"quadruple":
			_d(0, 0, "1"); _d(1, 1, "5")
			var q := _o + Vector2(1, 1) * _cs
			draw_circle(q, _cs * 0.36, UI.SURFACE, true, -1.0, true)
			draw_circle(q, _cs * 0.36, ink, false, maxf(1.0, _cs * 0.06), true)
			_small("15", q, ink)
		# cell marks
		"even_odd":
			var hs := _cs * 0.34
			draw_style_box(UI.box(Color(ink, 0.16), Color(0, 0, 0, 0), int(_cs * 0.08), 0), Rect2(_c(1, 0) - Vector2(hs, hs), Vector2(hs, hs) * 2.0))
			draw_circle(_c(1, 2), _cs * 0.36, Color(ink, 0.16), true, -1.0, true)
			_d(1, 0, "4"); _d(1, 2, "7")
		"axia":
			for dv in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
				draw_line(_c(1, 1) + dv * _cs * 0.32, _c(1, 1) + dv * _cs * 0.46, Color(UI.ACCENT, 0.7), maxf(1.5, _cs * 0.07), true)
			_d(1, 1, "5")
		"friendly":
			_heart(_c(1, 1)); _d(1, 1, "2")
		"pulse":
			draw_arc(_c(1, 1), _cs * 0.43, 0, TAU, 32, Color(0.86, 0.27, 0.36, 0.7), maxf(1.2, _cs * 0.05), true)
			_d(1, 1, "4"); _d(1, 2, "8")
		"index":
			var y := _c(1, 1).y + _cs * 0.36
			draw_line(Vector2(_c(1, 0).x - _cs * 0.4, y), Vector2(_c(1, 2).x + _cs * 0.4, y), Color(UI.ACCENT, 0.7), maxf(1.2, _cs * 0.05), true)
			_arrow_head(Vector2(_c(1, 2).x + _cs * 0.4, y), Vector2.RIGHT, _cs * 0.15, Color(UI.ACCENT, 0.7))
			_arrow_head(Vector2(_c(1, 0).x - _cs * 0.4, y), Vector2.LEFT, _cs * 0.15, Color(UI.ACCENT, 0.7))
			_d(1, 1, "3")
		"fortress":
			_shade(1, 1, Color(ink, 0.18)); _d(1, 1, "8"); _d(1, 0, "3"); _d(1, 2, "5")
		"min_max":
			_shade(1, 1, Color(0.3, 0.5, 1.0, 0.22)); _d(1, 1, "1"); _d(0, 1, "6"); _d(1, 2, "4")
		"clone":
			_shade(0, 0, Color(UI.CELL_COLORS[3], 0.6)); _shade(2, 2, Color(UI.CELL_COLORS[3], 0.6))
			_d(0, 0, "7"); _d(2, 2, "7")
		"vertex":
			_path([Vector2(2, 0), Vector2(1, 1), Vector2(2, 2)], Color(0.16, 0.63, 0.60, 0.75), 0.08, false)
			_d(1, 1, "5"); _d(2, 0, "2"); _d(2, 2, "3")
		"slingshot":   # the 6 flies from its cell, round the bend, 2 cells on: it lands on another 6
			var scol := Color(0.48, 0.36, 0.84, 0.9)
			var sw := maxf(1.5, _cs * 0.07)
			var a := _c(0, 0) + Vector2(0.3, 0) * _cs
			var bend := _c(0, 1)
			var tip := _c(1, 1) + Vector2(0, -0.3) * _cs
			draw_polyline(PackedVector2Array([a, bend, tip]), scol, sw, true)
			_arrow_head(tip, Vector2.DOWN, _cs * 0.16, scol)
			_d(0, 0, "6", color, 0.45); _d(0, 1, "1", color, 0.45); _d(1, 1, "6", color, 0.45)
		"prime_composite":
			_tag(1, 1, "P"); _d(1, 1, "7")
		"parity_regions":
			for p in [[0, 0], [0, 1], [1, 0]]:
				_shade(p[0], p[1], Color(0.3, 0.55, 1.0, 0.2))
			_d(0, 0, "2"); _d(0, 1, "4"); _d(1, 0, "8")
		"forbidden_digit":
			var at := _o + Vector2(1.76, 1.74) * _cs
			_small("3", at, Color(UI.DANGER, 0.85), 0.36)
			draw_line(at + Vector2(-0.14, 0.12) * _cs, at + Vector2(0.14, -0.12) * _cs, Color(UI.DANGER, 0.85), maxf(1.0, _cs * 0.05), true)
			_d(1, 1, "5")
		"divisibility":
			_tag(1, 1, "÷3"); _d(1, 1, "6")
		# letters & symbols
		"alphabet": _d(0, 0, "A"); _d(1, 1, "B"); _d(2, 2, "C")
		"wordoku": _d(0, 0, "W"); _d(1, 1, "O"); _d(2, 2, "R")
		"symbol":
			_d(0, 0, "★", ink, 0.55); _d(1, 1, "●", ink, 0.5); _d(2, 2, "▲", ink, 0.5)
		"color":
			for p in [[0, 0, 1], [1, 1, 3], [2, 2, 5]]:
				draw_circle(_c(p[0], p[1]), _cs * 0.3, Color(UI.CELL_COLORS[p[2]], 1.0), true, -1.0, true)
		"roman": _d(0, 0, "I", ink, 0.5); _d(1, 1, "IV", ink, 0.45); _d(2, 2, "IX", ink, 0.45)
		# chess & global
		"king":
			for r in 3:
				for c in 3:
					if r != 1 or c != 1:
						_shade(r, c, Color(UI.DANGER, 0.12))
			_d(1, 1, "5")
		"knight":
			_shade(0, 1, Color(UI.DANGER, 0.15))
			_d(2, 0, "7"); _d(0, 1, "7", Color(UI.DANGER, 0.9))
		"queen":
			_path([Vector2(0, 0), Vector2(2, 2)], Color(UI.DANGER, 0.25), 0.12, false)
			_d(1, 1, "9")
		"miracle":
			_d(1, 0, "3"); _d(1, 1, "5"); _d(1, 2, "8"); _d(0, 2, "1")
		"non_consecutive":
			_d(1, 0, "2"); _d(1, 1, "5"); _d(1, 2, "8")
		"dutch_flatmates":
			_d(0, 1, "1"); _d(1, 1, "5"); _d(2, 1, "9")
		_:
			_d(1, 1, "?")
	if variant.begins_with("mini_"):
		var bc := off + Vector2(s, s) * 0.86
		draw_circle(bc, s * 0.17, UI.ACCENT, true, -1.0, true)
		var bf: Font = UI.font_sans_bold
		var bfs := int(s * 0.22)
		var bsz2 := bf.get_string_size("6", HORIZONTAL_ALIGNMENT_LEFT, -1, bfs)
		draw_string(bf, bc + Vector2(-bsz2.x / 2, bfs * 0.36), "6", HORIZONTAL_ALIGNMENT_LEFT, -1, bfs, Color.WHITE)


func _c(r: float, c: float) -> Vector2:
	return _o + Vector2(c + 0.5, r + 0.5) * _cs


## Faint cell lines and a darker frame (kenken: no box feel, same look).
func _grid(_boxes := true) -> void:
	var g := Color(color, 0.16)
	for i in range(1, _n):
		draw_line(_o + Vector2(i * _cs, 0), _o + Vector2(i * _cs, _n * _cs), g, 1.0)
		draw_line(_o + Vector2(0, i * _cs), _o + Vector2(_n * _cs, i * _cs), g, 1.0)
	draw_rect(Rect2(_o, Vector2(_n, _n) * _cs), Color(color, 0.55), false, maxf(1.0, _cs * 0.06))


## A digit (or short text) centred in a cell.
func _d(r: float, c: float, t: String, col := Color(0, 0, 0, 0), k := 0.62) -> void:
	if col.a == 0.0:
		col = color
	var f: Font = UI.font_sans_medium
	var fs := maxi(6, int(_cs * k))
	var sz := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var at := _c(r, c) + Vector2(-sz.x / 2.0, (f.get_ascent(fs) - f.get_descent(fs)) / 2.0 - fs * 0.04)
	draw_string_outline(f, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(2, int(fs * 0.18)), Color(UI.SURFACE, 0.9))
	draw_string(f, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _small(t: String, at: Vector2, col: Color, k := 0.42) -> void:
	var f: Font = UI.font_sans_bold
	var fs := maxi(6, int(_cs * k))
	var sz := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(f, at + Vector2(-sz.x / 2.0, (f.get_ascent(fs) - f.get_descent(fs)) / 2.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## A line through cell centres (r, c as Vector2(r, c)), round ends.
func _path(cells: Array, col: Color, wk := 0.2, dots := true) -> void:
	var pts := PackedVector2Array()
	for v in cells:
		pts.append(_c(v.x, v.y))
	var w := maxf(1.5, _cs * wk)
	draw_polyline(pts, col, w, true)
	if dots:
		for p in pts:
			draw_circle(p, w * 0.5, col, true, -1.0, true)


func _line3(col: Color, a: String, b: String, c: String, bend := false) -> void:
	var cells := [Vector2(1, 0), Vector2(0, 1), Vector2(1, 2)] if bend else [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2)]
	_path(cells, col, 0.2)
	_d(cells[0].x, cells[0].y, a); _d(cells[1].x, cells[1].y, b); _d(cells[2].x, cells[2].y, c)


func _thermo(cells: Array, col: Color) -> void:
	_path(cells, col, 0.26)
	draw_circle(_c(cells[0].x, cells[0].y), _cs * 0.36, col, true, -1.0, true)


func _end_ring(r: int, c: int, col: Color, k := 0.38) -> void:
	draw_circle(_c(r, c), _cs * k, UI.SURFACE, true, -1.0, true)
	draw_circle(_c(r, c), _cs * k, Color(col, 1.0), false, maxf(1.2, _cs * 0.06), true)


func _end_square(r: int, c: int, col: Color) -> void:
	var h := Vector2(_cs, _cs) * 0.36
	draw_rect(Rect2(_c(r, c) - h, h * 2.0), UI.SURFACE)
	draw_rect(Rect2(_c(r, c) - h, h * 2.0), Color(col, 1.0), false, maxf(1.2, _cs * 0.06))


## A thick region border along grid corners (Vector2(x = column line, y = row line)).
func _wall(pts: Array) -> void:
	var p2 := PackedVector2Array()
	for v in pts:
		p2.append(_o + v * _cs)
	draw_polyline(p2, color, maxf(2.0, _cs * 0.1), true)


func _shade(r: int, c: int, col: Color) -> void:
	draw_rect(Rect2(_o + Vector2(c, r) * _cs, Vector2(_cs, _cs)), col)


## Dashed cage around the block of cells r0..r1 x c0..c1, with its label in the corner.
func _cage(r0: int, c0: int, r1: int, c1: int, label: String) -> void:
	var m := _cs * 0.1
	var rr := Rect2(_o + Vector2(c0, r0) * _cs + Vector2(m, m), Vector2(c1 - c0 + 1, r1 - r0 + 1) * _cs - Vector2(m, m) * 2.0)
	var col := Color(color, 0.7)
	var dash := maxf(2.0, _cs * 0.12)
	var w := maxf(1.0, _cs * 0.05)
	draw_dashed_line(rr.position, Vector2(rr.end.x, rr.position.y), col, w, dash)
	draw_dashed_line(Vector2(rr.end.x, rr.position.y), rr.end, col, w, dash)
	draw_dashed_line(rr.end, Vector2(rr.position.x, rr.end.y), col, w, dash)
	draw_dashed_line(Vector2(rr.position.x, rr.end.y), rr.position, col, w, dash)
	var f: Font = UI.font_sans_bold
	var fs := maxi(6, int(_cs * 0.32))
	var sz := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_rect(Rect2(rr.position + Vector2(-1, -1), Vector2(sz.x + 3, fs * 1.0)), UI.SURFACE)
	draw_string(f, rr.position + Vector2(0.5, fs * 0.8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


## Outside clue on the left of the middle row, three digits in the row.
func _row(clue: String, a: String, b: String, c: String) -> void:
	if clue != "":
		_small(clue, _o + Vector2(-0.5, 1.5) * _cs, color, 0.62 if clue.length() == 1 else 0.48)
	_d(1, 0, a); _d(1, 1, b); _d(1, 2, c)


func _edot(r: int, c: int, r2: int, c2: int, black: bool) -> void:
	var mid := (_c(r, c) + _c(r2, c2)) / 2.0
	var rad := _cs * 0.15
	if black:
		draw_circle(mid, rad, UI.DOT_BLACK, true, -1.0, true)
	else:
		draw_circle(mid, rad, UI.DOT_WHITE, true, -1.0, true)
		draw_circle(mid, rad, UI.DOT_BLACK, false, maxf(1.0, _cs * 0.05), true)


func _etext(r: int, c: int, r2: int, c2: int, t: String) -> void:
	var mid := (_c(r, c) + _c(r2, c2)) / 2.0
	var f: Font = UI.font_sans_bold
	var fs := maxi(6, int(_cs * 0.42))
	var sz := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_rect(Rect2(mid - Vector2(sz.x / 2 + 1, fs * 0.42), Vector2(sz.x + 2, fs * 0.84)), UI.SURFACE)
	draw_string(f, mid + Vector2(-sz.x / 2, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _ebubble(r: int, c: int, r2: int, c2: int, t: String) -> void:
	var mid := (_c(r, c) + _c(r2, c2)) / 2.0
	var f: Font = UI.font_sans_bold
	var fs := maxi(6, int(_cs * 0.28))
	var sz := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var rr := Rect2(mid - Vector2(sz.x / 2 + 2, fs * 0.55), Vector2(sz.x + 4, fs * 1.1))
	draw_style_box(UI.box(UI.SURFACE, color, int(fs * 0.55), 1), rr)
	draw_string(f, mid + Vector2(-sz.x / 2, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _tag(r: int, c: int, t: String) -> void:
	var f: Font = UI.font_sans_bold
	var fs := maxi(6, int(_cs * 0.34))
	draw_rect(Rect2(_o + Vector2(c, r) * _cs, Vector2(_cs, _cs)), Color(UI.ACCENT, 0.08))
	draw_string(f, _o + Vector2(c + 0.06, r + 0.06) * _cs + Vector2(0, fs * 0.85), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.ACCENT)


func _heart(ctr: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		var hx := 16.0 * pow(sin(a), 3)
		var hy := 13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a)
		pts.append(ctr + Vector2(hx, -hy - 2.0) * _cs * 0.024)
	draw_colored_polygon(pts, Color(0.92, 0.32, 0.48, 0.3))


func _arrow_head(tip: Vector2, dir: Vector2, sz: float, col: Color) -> void:
	var side := Vector2(-dir.y, dir.x)
	draw_polyline(PackedVector2Array([tip - dir * sz + side * sz * 0.8, tip, tip - dir * sz - side * sz * 0.8]), col, maxf(1.5, _cs * 0.07), true)
