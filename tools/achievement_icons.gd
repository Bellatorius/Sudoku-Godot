extends Node
## Dev helper: renders the Steam achievement icons (256x256, unlocked + locked grey) into
## res://docs/steam/achievements/<API_NAME>.png and <API_NAME>_locked.png. Run with a display:
##   godot --path . res://tools/achievement_icons.tscn

const BLUE := Color("#2a4fff")
const GOLD := Color("#e8a020")
const TEAL := Color("#14a39a")
const PURPLE := Color("#7b4fe0")
const ORANGE := Color("#e86a20")
const RED := Color("#e0405a")
const INK := Color("#26263a")

## API name -> [colour, symbol ("@variant" draws that variant's icon), caption]
const ICONS := {
	"FIRST_SOLVE": [BLUE, "@classic", "FIRST"],
	"SOLVE_10": [BLUE, "10", "SOLVED"], "SOLVE_50": [BLUE, "50", "SOLVED"], "SOLVE_100": [BLUE, "100", "SOLVED"],
	"SOLVE_250": [BLUE, "250", "SOLVED"], "SOLVE_500": [BLUE, "500", "SOLVED"], "SOLVE_1000": [BLUE, "1K", "SOLVED"],
	"ALL_CORE": [INK, "★", "EVERY VARIANT"], "VARIETY_25": [INK, "25", "VARIANTS"],
	"HARD_SOLVE": [GOLD, "H", "HARD"], "HARD_NO_HINTS": [GOLD, "H", "NO HINTS"],
	"EXPERT_SOLVE": [GOLD, "E", "EXPERT"], "EXPERT_10": [GOLD, "10", "EXPERT"],
	"MASTER_SOLVE": [GOLD, "M", "MASTER"], "MASTER_10": [GOLD, "10", "MASTER"], "MASTER_50": [GOLD, "50", "MASTER"],
	"MASTER_FLAWLESS": [GOLD, "✓", "FLAWLESS"], "ALL_LEVELS": [GOLD, "6", "ALL LEVELS"],
	"BLANK_SLATE": [INK, "0", "GIVENS"], "NO_HINTS_25": [INK, "25", "NO HINTS"],
	"SPEED_CLASSIC": [RED, "5:00", "SPEED"], "KILLER_INSTINCT": [RED, "@killer", "10 KILLER"],
	"CAT_REGIONS": [TEAL, "@jigsaw", "REGIONS"], "CAT_LINES": [TEAL, "@thermo", "LINES"],
	"CAT_SUMS": [TEAL, "@arrow", "SUMS"], "CAT_OUTSIDE": [TEAL, "@sandwich", "OUTSIDE"],
	"CAT_DOTS": [TEAL, "@kropki", "DOTS"], "CAT_MARKS": [TEAL, "@even_odd", "MARKS"],
	"CAT_THEMES": [TEAL, "@alphabet", "LETTERS"], "CAT_GLOBAL": [TEAL, "@knight", "CHESS"],
	"CAT_MINI": [PURPLE, "6×6", "ALL MINI"], "MINI_FIRST": [PURPLE, "6×6", "MINI"], "MINI_SPRINT": [PURPLE, "2:00", "MINI SPRINT"],
	"DAILY_FIRST": [ORANGE, "1", "DAILY"], "DAILY_10": [ORANGE, "10", "DAILIES"], "DAILY_STREAK_7": [ORANGE, "7", "DAY STREAK"],
	"DAILY_STREAK_30": [ORANGE, "30", "DAY STREAK"], "DAILY_STREAK_100": [ORANGE, "100", "DAY STREAK"],
	"MP_FIRST_RACE": [RED, "1v1", "RACE"], "MP_FIRST_WIN": [RED, "1v1", "FIRST WIN"],
	"MP_WINS_10": [RED, "10", "WINS"], "MP_WINS_50": [RED, "50", "WINS"],
}


class Tile extends Control:
	var col: Color
	var sym: String
	var cap: String
	var locked := false

	func _draw() -> void:
		var c := col if not locked else Color(0.42, 0.42, 0.46)
		var bg := StyleBoxFlat.new()
		bg.bg_color = c.darkened(0.15)
		bg.set_corner_radius_all(0)
		draw_style_box(bg, Rect2(Vector2.ZERO, size))
		var inner := StyleBoxFlat.new()
		inner.bg_color = c
		inner.set_corner_radius_all(36)
		draw_style_box(inner, Rect2(Vector2(14, 14), size - Vector2(28, 28)))
		var fg := Color.WHITE if not locked else Color(0.82, 0.82, 0.85)
		if not sym.begins_with("@"):
			var f: Font = UI.font_serif
			var fs := 120 if sym.length() <= 2 else (92 if sym.length() == 3 else 74)
			var sz := f.get_string_size(sym, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			draw_string(f, Vector2((size.x - sz.x) / 2.0, 128 + fs * 0.32), sym, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fg)
		var cf: Font = UI.font_sans_bold
		var cfs := 22 if cap.length() < 12 else 18
		var csz := cf.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, cfs)
		draw_string(cf, Vector2((size.x - csz.x) / 2.0, 222), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, cfs, Color(fg, 0.9))


func _ready() -> void:
	var out := "res://docs/steam/achievements/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 256)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	for api in ICONS:
		for locked in [false, true]:
			for ch in vp.get_children():
				ch.queue_free()
			await get_tree().process_frame
			var spec: Array = ICONS[api]
			var t := Tile.new()
			t.col = spec[0]; t.sym = spec[1]; t.cap = spec[2]; t.locked = locked
			t.size = Vector2(256, 256)
			vp.add_child(t)
			if str(spec[1]).begins_with("@"):
				var ic := VariantIcon.new(str(spec[1]).substr(1), 130)
				ic.color = Color.WHITE if not locked else Color(0.82, 0.82, 0.85)
				ic.position = Vector2(63, 48)
				ic.size = Vector2(130, 130)
				vp.add_child(ic)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			img.save_png(ProjectSettings.globalize_path(out + api + ("_locked" if locked else "") + ".png"))
	var missing: Array = SteamManager.ACHIEVEMENTS.keys().filter(func(k): return not ICONS.has(k))
	print("icons: ", ICONS.size(), "  missing: ", missing)
	get_tree().quit()
