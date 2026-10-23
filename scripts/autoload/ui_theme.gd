extends Node
## Global look & feel, mirroring the reference site:
## warm paper background, ink text, electric-blue accent, gold highlight,
## DM Serif Display headings + DM Sans body, 14px rounded cards.

## Colours are vars so the palette can switch between light and dark at runtime
## (set_dark). Screens read them when they are built, so Main rebuilds on palette_changed.
signal palette_changed

const LIGHT := {
	"PAPER": "#ebe8e0", "PAPER_WARM": "#e2ded3", "SURFACE": "#f5f3ed",
	"INK": "#0e0e12", "INK_MUTED": "#44445a", "INK_FAINT": "#727288",
	"ACCENT": "#2a4fff", "ACCENT_SOFT": "#e8edff", "ACCENT_MID": "#c7d2ff",
	"GOLD": "#e8a020", "GOLD_SOFT": "#fff8ea", "GOLD_TEXT": "#97680f", "HINT": "#c58819",
	"DANGER": "#e5484d", "DANGER_SOFT": "#fde8e8", "SUCCESS": "#1f9d55",
	"THERMO": "#cfd0da", "ARROW": "#a6a8b8",
	"NOTE_OK": "#2a6df4", "NOTE_BAD": "#d6453d",
	"CELL_COLORS": ["#c9c9cf", "#ff9e9e", "#ffc46b", "#fff07a", "#a6e39a", "#8fd8e6", "#9db4ff", "#d2a8ff", "#ffb3dc"],
}
const DARK := {
	"PAPER": "#131318", "PAPER_WARM": "#1e1e26", "SURFACE": "#1b1b22",
	"INK": "#ecebe4", "INK_MUTED": "#a4a4b6", "INK_FAINT": "#6b6b80",
	"ACCENT": "#6f8bff", "ACCENT_SOFT": "#1f2647", "ACCENT_MID": "#33427c",
	"GOLD": "#f0b040", "GOLD_SOFT": "#29231a", "GOLD_TEXT": "#f0b040", "HINT": "#f0b040",
	"DANGER": "#ff6b6e", "DANGER_SOFT": "#3d2024", "SUCCESS": "#3ccf7e",
	"THERMO": "#454857", "ARROW": "#7d8096",
	"NOTE_OK": "#7fa4ff", "NOTE_BAD": "#ff7b72",
	"CELL_COLORS": ["#56565f", "#8c3f3f", "#8c5d22", "#7d7228", "#3e7838", "#2e6c79", "#3c509a", "#67489a", "#8c3e6b"],
}

var dark := true    # dark is the default look (GameState applies the saved choice)
var PAPER: Color
var PAPER_WARM: Color
var SURFACE: Color
var INK: Color
var INK_MUTED: Color
var INK_FAINT: Color
var ACCENT: Color
var ACCENT_SOFT: Color
var ACCENT_MID: Color
var GOLD: Color
var GOLD_SOFT: Color
var GOLD_TEXT: Color     # gold text on GOLD_SOFT
var HINT: Color          # hinted digits
var DANGER: Color
var DANGER_SOFT: Color
var SUCCESS: Color
var LINE: Color
var LINE_STRONG: Color
var THERMO: Color
var ARROW: Color
## Pencil marks: blue = still possible, red = already placed in a unit.
var NOTE_OK: Color
var NOTE_BAD: Color
## Cell colouring palette (index 1..9 ↔ keys 1..9 in colour mode).
var CELL_COLORS: Array = []
## Kropki dots keep their meaning (black/white) in both palettes.
const DOT_BLACK := Color("#0e0e12")
const DOT_WHITE := Color("#fffffd")
const RADIUS := 14

var font_sans: FontVariation
var font_sans_medium: FontVariation
var font_sans_bold: FontVariation
var font_serif: Font
var theme: Theme


func _ready() -> void:
	_load_fonts()
	_apply_palette()
	theme = Theme.new()
	_build_theme(theme)
	get_tree().root.theme = theme


## Switches between the light and dark palette; Main listens to palette_changed and rebuilds.
func set_dark(on: bool) -> void:
	if on == dark:
		return
	dark = on
	_apply_palette()
	theme.clear()
	_build_theme(theme)
	palette_changed.emit()


func _apply_palette() -> void:
	var p: Dictionary = DARK if dark else LIGHT
	for k in p:
		if k != "CELL_COLORS":
			set(k, Color(p[k]))
	CELL_COLORS = [Color(0, 0, 0, 0)]
	for hex in p.CELL_COLORS:
		CELL_COLORS.append(Color(hex))
	LINE = Color(INK, 0.16 if not dark else 0.14)
	LINE_STRONG = Color(INK, 0.30 if not dark else 0.22)
	RenderingServer.set_default_clear_color(PAPER)


func _load_fonts() -> void:
	var base: FontFile = load("res://fonts/DMSans-Variable.ttf")
	font_sans = _weight(base, 400)
	font_sans_medium = _weight(base, 500)
	font_sans_bold = _weight(base, 650)
	font_serif = load("res://fonts/DMSerifDisplay-Regular.ttf")


func _weight(base: Font, w: int) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = base
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): w, ts.name_to_tag("opsz"): 14}
	return fv


# ---------------------------------------------------------------- styleboxes

func box(bg: Color, border: Color = LINE, radius: int = RADIUS, border_w: int = 1, pad: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	sb.set_content_margin_all(pad)
	return sb


func card_box(hover := false) -> StyleBoxFlat:
	var sb := box(SURFACE if hover else PAPER, ACCENT if hover else LINE_STRONG, RADIUS, 1, 18)
	if hover:
		sb.shadow_color = Color(0.165, 0.31, 1.0, 0.10)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 4)
	return sb


func _build_theme(t: Theme) -> void:
	t.default_font = font_sans
	t.default_font_size = 16

	# Labels
	t.set_color("font_color", "Label", INK)

	# Buttons — default: outlined pill
	var normal := box(SURFACE, LINE_STRONG, 999, 1)
	normal.content_margin_left = 18; normal.content_margin_right = 18
	normal.content_margin_top = 9; normal.content_margin_bottom = 9
	var hover := normal.duplicate(); hover.border_color = INK; hover.bg_color = SURFACE
	var pressed := normal.duplicate(); pressed.bg_color = ACCENT_SOFT; pressed.border_color = ACCENT
	var disabled := normal.duplicate(); disabled.bg_color = PAPER_WARM; disabled.border_color = LINE
	var focus := normal.duplicate(); focus.bg_color = Color(0, 0, 0, 0); focus.border_color = ACCENT; focus.set_border_width_all(2)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", focus)
	t.set_font("font", "Button", font_sans_medium)
	t.set_font_size("font_size", "Button", 15)
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(k, "Button", INK)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", INK_FAINT)

	# Primary button variation (solid ink, like the site's CTA)
	t.set_type_variation("PrimaryButton", "Button")
	var p_n := box(INK, INK, 999, 1)
	p_n.content_margin_left = 22; p_n.content_margin_right = 22
	p_n.content_margin_top = 10; p_n.content_margin_bottom = 10
	var p_h := p_n.duplicate(); p_h.bg_color = ACCENT; p_h.border_color = ACCENT
	var p_d := p_n.duplicate(); p_d.bg_color = INK_FAINT; p_d.border_color = INK_FAINT
	t.set_stylebox("normal", "PrimaryButton", p_n)
	t.set_stylebox("hover", "PrimaryButton", p_h)
	t.set_stylebox("pressed", "PrimaryButton", p_h)
	t.set_stylebox("hover_pressed", "PrimaryButton", p_h)
	t.set_stylebox("disabled", "PrimaryButton", p_d)
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		t.set_color(k, "PrimaryButton", PAPER)

	# Flat link-like button (nav)
	t.set_type_variation("NavButton", "Button")
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 12; empty.content_margin_right = 12
	empty.content_margin_top = 6; empty.content_margin_bottom = 6
	for s in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		t.set_stylebox(s, "NavButton", empty)
	t.set_color("font_color", "NavButton", INK_MUTED)
	t.set_color("font_hover_color", "NavButton", INK)
	t.set_color("font_pressed_color", "NavButton", ACCENT)
	t.set_color("font_hover_pressed_color", "NavButton", ACCENT)
	t.set_color("font_focus_color", "NavButton", INK)

	# Toggle chip (note modes)
	t.set_type_variation("ChipButton", "Button")
	var c_n := box(SURFACE, LINE_STRONG, 10, 1)
	c_n.content_margin_left = 12; c_n.content_margin_right = 12
	c_n.content_margin_top = 8; c_n.content_margin_bottom = 8
	var c_h := c_n.duplicate(); c_h.border_color = INK
	var c_p := c_n.duplicate(); c_p.bg_color = INK; c_p.border_color = INK
	t.set_stylebox("normal", "ChipButton", c_n)
	t.set_stylebox("hover", "ChipButton", c_h)
	t.set_stylebox("pressed", "ChipButton", c_p)
	t.set_stylebox("hover_pressed", "ChipButton", c_p)
	t.set_stylebox("focus", "ChipButton", StyleBoxEmpty.new())
	t.set_color("font_color", "ChipButton", INK)
	t.set_color("font_hover_color", "ChipButton", INK)
	t.set_color("font_pressed_color", "ChipButton", PAPER)
	t.set_color("font_hover_pressed_color", "ChipButton", PAPER)

	# Number pad keys
	t.set_type_variation("PadButton", "Button")
	var k_n := box(SURFACE, LINE_STRONG, 12, 1)
	var k_h := k_n.duplicate(); k_h.border_color = ACCENT; k_h.bg_color = ACCENT_SOFT
	var k_p := k_n.duplicate(); k_p.bg_color = ACCENT; k_p.border_color = ACCENT
	t.set_stylebox("normal", "PadButton", k_n)
	t.set_stylebox("hover", "PadButton", k_h)
	t.set_stylebox("pressed", "PadButton", k_p)
	t.set_stylebox("hover_pressed", "PadButton", k_p)
	t.set_stylebox("focus", "PadButton", StyleBoxEmpty.new())
	var k_d := k_n.duplicate(); k_d.bg_color = PAPER_WARM; k_d.border_color = LINE
	t.set_stylebox("disabled", "PadButton", k_d)
	t.set_font("font", "PadButton", font_sans_medium)
	t.set_font_size("font_size", "PadButton", 26)
	t.set_color("font_color", "PadButton", INK)
	t.set_color("font_hover_color", "PadButton", ACCENT)
	t.set_color("font_pressed_color", "PadButton", PAPER)
	t.set_color("font_hover_pressed_color", "PadButton", PAPER)
	t.set_color("font_disabled_color", "PadButton", INK_FAINT)

	# LineEdit (search box)
	var le := box(SURFACE, LINE_STRONG, 12, 1)
	le.content_margin_left = 16; le.content_margin_right = 16
	le.content_margin_top = 11; le.content_margin_bottom = 11
	var le_f := le.duplicate(); le_f.border_color = ACCENT
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le_f)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", INK_FAINT)
	t.set_color("caret_color", "LineEdit", ACCENT)
	t.set_color("selection_color", "LineEdit", ACCENT_MID)

	# CheckButton / CheckBox text
	t.set_color("font_color", "CheckButton", INK)
	t.set_color("font_hover_color", "CheckButton", INK)
	t.set_color("font_pressed_color", "CheckButton", INK)
	t.set_color("font_hover_pressed_color", "CheckButton", INK)
	t.set_color("font_focus_color", "CheckButton", INK)
	_style_switches(t)

	# Drop-down lists (OptionButton popups)
	t.set_stylebox("panel", "PopupMenu", box(SURFACE, LINE_STRONG, 10, 1, 6))
	var pm_hover := box(ACCENT_SOFT, Color(0, 0, 0, 0), 6, 0)
	t.set_stylebox("hover", "PopupMenu", pm_hover)
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", ACCENT)
	t.set_font_size("font_size", "PopupMenu", 15)

	# Lists (searchable variant picker)
	t.set_stylebox("panel", "ItemList", box(SURFACE, LINE_STRONG, 12, 1, 6))
	t.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	t.set_stylebox("hovered", "ItemList", box(PAPER_WARM, Color(0, 0, 0, 0), 8, 0))
	t.set_stylebox("selected", "ItemList", box(ACCENT_SOFT, Color(0, 0, 0, 0), 8, 0))
	t.set_stylebox("selected_focus", "ItemList", box(ACCENT_SOFT, Color(0, 0, 0, 0), 8, 0))
	t.set_stylebox("hovered_selected", "ItemList", box(ACCENT_SOFT, Color(0, 0, 0, 0), 8, 0))
	t.set_stylebox("hovered_selected_focus", "ItemList", box(ACCENT_SOFT, Color(0, 0, 0, 0), 8, 0))
	t.set_color("font_color", "ItemList", INK)
	t.set_color("font_hovered_color", "ItemList", INK)
	t.set_color("font_selected_color", "ItemList", ACCENT)
	t.set_color("font_hovered_selected_color", "ItemList", ACCENT)
	t.set_color("guide_color", "ItemList", Color(0, 0, 0, 0))
	t.set_constant("v_separation", "ItemList", 6)
	t.set_font_size("font_size", "ItemList", 15)

	# Panels
	t.set_stylebox("panel", "PanelContainer", box(PAPER, LINE_STRONG, RADIUS, 1, 20))
	t.set_stylebox("panel", "Panel", box(PAPER, LINE_STRONG, RADIUS, 1))

	# Scrollbars — slim
	var sb_bg := box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 4, 0)
	sb_bg.content_margin_left = 3; sb_bg.content_margin_right = 3
	var grab := box(Color(INK, 0.18), Color(0, 0, 0, 0), 4, 0)
	var grab_h := box(Color(INK, 0.35), Color(0, 0, 0, 0), 4, 0)
	t.set_stylebox("scroll", "VScrollBar", sb_bg)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab_h)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab_h)

	# Tooltip
	t.set_stylebox("panel", "TooltipPanel", box(INK, INK, 8, 0, 8))
	t.set_color("font_color", "TooltipLabel", PAPER)

	# HSeparator
	var sep := StyleBoxLine.new()
	sep.color = LINE_STRONG
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)


# ---------------------------------------------------------------- toggle switches

## Clear on/off switches for CheckButton: ON = accent track with a white knob on the right,
## OFF = grey track with the knob on the left. Drawn at 3x and scaled down for smooth edges.
func _switch_icon(on: bool, disabled := false) -> ImageTexture:
	var w := 48
	var h := 28
	var ss := 3
	var img := Image.create(w * ss, h * ss, false, Image.FORMAT_RGBA8)
	var track: Color = ACCENT if on else Color(INK, 0.28 if not dark else 0.35)
	var knob := Color.WHITE if not dark or on else Color("#d8d8de")
	if disabled:
		track.a *= 0.4
		knob.a *= 0.6
	var W := float(w * ss)
	var H := float(h * ss)
	var r := H / 2.0
	var kr := r - 3.0 * ss
	var kx := W - r if on else r
	for y in h * ss:
		for x in w * ss:
			var px := float(x) + 0.5
			var py := float(y) + 0.5
			# rounded track (capsule)
			var cx := clampf(px, r, W - r)
			var d := Vector2(px - cx, py - r).length() - r
			var col := Color(track, track.a * clampf(0.5 - d, 0.0, 1.0))
			# knob with a soft shadow
			var dk := Vector2(px - kx, py - r - ss).length() - kr
			var sh := clampf(0.5 - dk / (2.0 * ss), 0.0, 1.0) * 0.18
			col = col.blend(Color(0, 0, 0, sh))
			var dk2 := Vector2(px - kx, py - r).length() - kr
			col = col.blend(Color(knob, knob.a * clampf(0.5 - dk2, 0.0, 1.0)))
			img.set_pixel(x, y, col)
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _style_switches(t: Theme) -> void:
	var on := _switch_icon(true)
	var off := _switch_icon(false)
	t.set_icon("checked", "CheckButton", on)
	t.set_icon("unchecked", "CheckButton", off)
	t.set_icon("checked_mirrored", "CheckButton", on)
	t.set_icon("unchecked_mirrored", "CheckButton", off)
	t.set_icon("checked_disabled", "CheckButton", _switch_icon(true, true))
	t.set_icon("unchecked_disabled", "CheckButton", _switch_icon(false, true))
	t.set_icon("checked_disabled_mirrored", "CheckButton", _switch_icon(true, true))
	t.set_icon("unchecked_disabled_mirrored", "CheckButton", _switch_icon(false, true))
	# No button frame around the switch (it inherited the pill/outline from Button).
	var empty := StyleBoxEmpty.new()
	empty.set_content_margin_all(4)
	for s in ["normal", "pressed", "hover", "hover_pressed", "focus", "disabled"]:
		t.set_stylebox(s, "CheckButton", empty)

# ---------------------------------------------------------------- helpers

func label(text: String, size := 16, color := INK, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	return l


func heading(text: String, size := 44) -> Label:
	return label(text, size, INK, font_serif)


func button(text: String, variation := "", cb: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if variation != "":
		b.theme_type_variation = variation
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


func spacer(h := 0, w := 0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	return c


func tag(text: String, fg: Color, bg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := box(bg, Color(0, 0, 0, 0), 999, 0)
	sb.content_margin_left = 9; sb.content_margin_right = 9
	sb.content_margin_top = 2; sb.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", sb)
	var l := label(text, 12, fg, font_sans_bold)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func toast(text: String) -> void:
	if has_meta("toast"):
		get_meta("toast").show_toast(text)


## Centered column with a max width, inside a vertical scroll.
func page(max_width := 1120, pad_top := 48) -> Array:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var center := MarginContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("margin_top", pad_top)
	center.add_theme_constant_override("margin_bottom", 48)
	scroll.add_child(center)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.custom_minimum_size = Vector2(320, 0)
	col.add_theme_constant_override("separation", 16)
	center.add_child(col)
	# Size from the parent, not the scroll: with horizontal scrolling off, the scroll grows to fit
	# its content and would never shrink back (content would be cut off on narrower layouts).
	var fit := func():
		var w := mini(max_width, int(scroll.get_parent_area_size().x) - 62)
		col.custom_minimum_size.x = maxf(320, w)
	scroll.ready.connect(func():
		scroll.get_parent().resized.connect(fit)
		fit.call())
	return [scroll, col]


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]
