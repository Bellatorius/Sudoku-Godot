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

	match variant:
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
		"jigsaw":
			var pts := [P.call(0.12, 0.12), P.call(0.55, 0.12), P.call(0.55, 0.4), P.call(0.88, 0.4), P.call(0.88, 0.88), P.call(0.4, 0.88), P.call(0.4, 0.6), P.call(0.12, 0.6), P.call(0.12, 0.12)]
			draw_polyline(PackedVector2Array(pts), color, w, true)
		"diagonal", "axia", "bishop":
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
		"german_whispers", "dutch_whispers", "renban", "palindrome", "zipper", "reflection", "lockout", "between":
			var cols := {"german_whispers": Color("#2fb36b"), "dutch_whispers": Color("#f08a24"), "renban": Color("#c14fd6"), "palindrome": Color("#3fa6e8")}
			var lc: Color = cols.get(variant, color)
			draw_polyline(PackedVector2Array([P.call(0.14, 0.78), P.call(0.4, 0.4), P.call(0.62, 0.62), P.call(0.86, 0.22)]), lc, w * 1.4, true)
			if variant == "between" or variant == "lockout":
				draw_circle(P.call(0.14, 0.78), s * 0.11, UI.PAPER, true, -1.0, true); ring.call(P.call(0.14, 0.78), s * 0.11)
				draw_circle(P.call(0.86, 0.22), s * 0.11, UI.PAPER, true, -1.0, true); ring.call(P.call(0.86, 0.22), s * 0.11)
		"quadruple":
			line.call(P.call(0.5, 0.1), P.call(0.5, 0.9)); line.call(P.call(0.1, 0.5), P.call(0.9, 0.5))
			draw_circle(P.call(0.5, 0.5), s * 0.2, UI.PAPER, true, -1.0, true); ring.call(P.call(0.5, 0.5), s * 0.2)
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
