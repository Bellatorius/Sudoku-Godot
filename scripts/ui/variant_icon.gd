class_name VariantIcon
extends Control
## Small line-art icon for a variant, drawn with vector primitives (style of logic-wiz.com cards).

var variant := "classic"
var color := Color("#0e0e12")


func _init(id := "classic", px := 34) -> void:
	variant = id
	color = UI.INK
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
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
