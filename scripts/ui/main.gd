extends Control
## Root: top navigation bar + swappable screen area + toast.

const SCREENS := {
	"home": preload("res://scripts/ui/home_screen.gd"),
	"variant": preload("res://scripts/ui/variant_screen.gd"),
	"game": preload("res://scripts/ui/game_screen.gd"),
	"stats": preload("res://scripts/ui/stats_screen.gd"),
	"settings": preload("res://scripts/ui/settings_screen.gd"),
	"daily": preload("res://scripts/ui/daily_screen.gd"),
	"multiplayer": preload("res://scripts/ui/multiplayer_screen.gd"),
}

var content: Control
var current: Control
var toast: PanelContainer
var toast_label: Label
var nav_buttons := {}
var continue_btn: Button
var _toast_tween: Tween
var _screen := "home"
var _params := {}
var _back: Array = []      # history entries [screen, params]; mouse 4 / Alt+Left
var _forward: Array = []   # mouse 5 / Alt+Right
const HISTORY_MAX := 50


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	_build()
	GameState.navigate.connect(_on_navigate)
	UI.palette_changed.connect(_rebuild, CONNECT_DEFERRED)
	# Guest browsing elsewhere when the host leaves: tell them (the multiplayer and race screens handle it themselves).
	Net.room_closed.connect(func():
		var race: bool = _screen == "game" and current != null and not current.versus.is_empty()
		if _screen != "multiplayer" and not race:
			UI.toast("The host left, so your multiplayer room was closed."))
	_on_navigate("home", {})


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UI.PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	root.add_child(_build_nav())

	content = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)

	_build_toast()


## Screens read UI colours when they are built, so a palette switch rebuilds everything
## and re-opens the current screen.
func _rebuild() -> void:
	if current and current.has_method("on_leave"):
		current.on_leave()
	var here := _here()
	current = null
	for c in get_children():
		remove_child(c)
		c.queue_free()
	nav_buttons.clear()
	_build()
	if here.is_empty():
		here = ["home", {}]
	_show(here[0], here[1])


## Nine Smile mark on its rounded tile (docs/logo/kit/master/nine-smile-tile-blue.svg), rendered at runtime.
const LOGO_SVG := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256"><path fill="#2a4fff" d="M68 12H188A56 56 0 0 1 244 68V188A56 56 0 0 1 188 244H68A56 56 0 0 1 12 188V68A56 56 0 0 1 68 12Z"/><g transform="translate(128 128) scale(0.68) translate(-128 -128)"><path fill="#ffffff" d="M56.95 71.45A24.65 24.65 0 1 0 106.25 71.45A24.65 24.65 0 1 0 56.95 71.45ZM213.55 71.45L213.55 143.95A85.55 68.15 0 0 1 50.47 172.75A10.15 10.15 0 0 1 68.86 164.17A65.25 47.85 0 0 0 193.25 143.95L193.25 71.45Z"/><path fill="#ffffff" fill-rule="evenodd" d="M135.25 71.45A39.15 39.15 0 1 0 213.55 71.45A39.15 39.15 0 1 0 135.25 71.45ZM155.55 71.45A18.85 18.85 0 1 0 193.25 71.45A18.85 18.85 0 1 0 155.55 71.45Z"/></g></svg>'
const NAV_ITEMS := [["Home", "home"], ["Daily", "daily"], ["Multiplayer", "multiplayer"], ["Stats", "stats"], ["Settings", "settings"]]

var _nav_bar: Control
var _nav_row: HBoxContainer
var _nav_pill: Control
var _nav_word: Control     # "Variants" half of the wordmark, hidden when the window is very narrow


## Top bar: logo + wordmark on the left, a pill of icon tabs in the middle, Continue / music / Quit on the right.
## The pill sits right after the logo, so it never moves when Continue shows or hides.
## When the window is too narrow the tabs drop their text (icons + tooltips only).
func _build_nav() -> Control:
	var bar := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UI.SURFACE
	sb.border_width_bottom = 1
	sb.border_color = UI.LINE
	sb.shadow_color = Color(0, 0, 0, 0.30 if UI.dark else 0.06)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = 24; sb.content_margin_right = 20
	sb.content_margin_top = 12; sb.content_margin_bottom = 12
	bar.add_theme_stylebox_override("panel", sb)
	bar.z_index = 1   # so the shadow falls over the screen below
	_nav_bar = bar
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	bar.add_child(h)
	_nav_row = h

	h.add_child(_build_logo())
	h.add_child(UI.spacer(0, 28))

	var pill := PanelContainer.new()
	var psb := UI.box(UI.PAPER, UI.LINE, 999, 1, 4)
	pill.add_theme_stylebox_override("panel", psb)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	pill.add_child(tabs)
	for item in NAV_ITEMS:
		var target: String = item[1]
		var b := _nav_tab(item[0], target)
		tabs.add_child(b)
		nav_buttons[target] = b
	h.add_child(pill)
	_nav_pill = pill

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sp)

	continue_btn = UI.button("", "", func():
		var slot := GameState.last_unfinished()
		if slot != "":
			GameState.go("game", GameState.resume_params(slot)))
	var c_n := UI.box(UI.GOLD_SOFT, UI.GOLD, 999, 1)
	c_n.content_margin_left = 16; c_n.content_margin_right = 16
	c_n.content_margin_top = 8; c_n.content_margin_bottom = 8
	var c_h := c_n.duplicate(); c_h.bg_color = UI.GOLD
	for s in ["normal", "focus"]:
		continue_btn.add_theme_stylebox_override(s, c_n)
	for s in ["hover", "pressed", "hover_pressed"]:
		continue_btn.add_theme_stylebox_override(s, c_h)
	continue_btn.add_theme_color_override("font_color", UI.GOLD_TEXT)
	continue_btn.add_theme_color_override("font_hover_color", UI.INK if not UI.dark else UI.PAPER)
	continue_btn.add_theme_color_override("font_pressed_color", UI.INK if not UI.dark else UI.PAPER)
	continue_btn.add_theme_font_override("font", UI.font_sans_medium)
	continue_btn.add_theme_font_size_override("font_size", 14)
	continue_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	continue_btn.visible = false
	h.add_child(continue_btn)

	h.add_child(_build_music_button())
	var quit := UI.button("Quit", "", func(): get_tree().quit())
	var q_n := UI.box(Color(0, 0, 0, 0), UI.LINE_STRONG, 999, 1)
	q_n.content_margin_left = 18; q_n.content_margin_right = 18
	q_n.content_margin_top = 8; q_n.content_margin_bottom = 8
	var q_h := q_n.duplicate(); q_h.border_color = UI.INK
	for s in ["normal", "focus"]:
		quit.add_theme_stylebox_override(s, q_n)
	for s in ["hover", "pressed", "hover_pressed"]:
		quit.add_theme_stylebox_override(s, q_h)
	quit.add_theme_color_override("font_color", UI.INK_MUTED)
	quit.add_theme_color_override("font_hover_color", UI.INK)
	quit.add_theme_color_override("font_pressed_color", UI.INK)
	quit.add_theme_font_size_override("font_size", 14)
	quit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(quit)

	bar.resized.connect(_fit_nav)
	return bar


func _build_logo() -> Control:
	var logo := HBoxContainer.new()
	logo.add_theme_constant_override("separation", 10)
	logo.mouse_filter = Control.MOUSE_FILTER_STOP
	logo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	logo.tooltip_text = "Home"
	logo.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			GameState.go("home"))
	var img := Image.new()
	img.load_svg_from_string(LOGO_SVG.replace("#2a4fff", "#" + UI.ACCENT.to_html(false)), 80.0 / 256.0)
	var mark := TextureRect.new()
	mark.texture = ImageTexture.create_from_image(img)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size = Vector2(40, 40)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.add_child(mark)
	var words := HBoxContainer.new()
	words.add_theme_constant_override("separation", 6)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var w1 := UI.label("Sudoku", 21, UI.INK, UI.font_sans_bold)
	var w2 := UI.label("Variants", 21, UI.ACCENT, UI.font_sans_bold)
	for w in [w1, w2]:
		w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_child(w)
	logo.add_child(words)
	_nav_word = words
	return logo


## One tab of the nav pill: a small drawn icon + its name; the active tab is filled with the accent colour.
func _nav_tab(text: String, target: String) -> Button:
	var b := UI.button(text, "", func(): _nav_pressed(target))
	b.tooltip_text = text
	b.set_meta("label", text)
	b.add_theme_font_override("font", UI.font_sans_medium)
	b.add_theme_font_size_override("font_size", 15)
	b.custom_minimum_size = Vector2(40, 36)
	var icon := Control.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func():
		var c := Vector2(24, icon.size.y / 2.0) if b.text != "" else icon.size / 2.0
		_draw_nav_icon(icon, target, c, b.get_theme_color("font_hover_color" if b.is_hovered() else "font_color")))
	b.add_child(icon)
	b.mouse_entered.connect(icon.queue_redraw)
	b.mouse_exited.connect(icon.queue_redraw)
	b.set_meta("icon", icon)
	_style_tab(b, false)
	return b


func _style_tab(b: Button, active: bool) -> void:
	var compact: bool = b.text == ""
	var n := UI.box(UI.ACCENT if active else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
	n.content_margin_left = 12 if compact else 38
	n.content_margin_right = 12 if compact else 16
	n.content_margin_top = 7; n.content_margin_bottom = 7
	var hv := n.duplicate()
	if not active:
		hv.bg_color = Color(UI.INK, 0.07)
	for s in ["normal", "focus"]:
		b.add_theme_stylebox_override(s, n)
	for s in ["hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, hv)
	var fg := Color.WHITE if active else UI.INK_MUTED
	var fg_h := Color.WHITE if active else UI.INK
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_focus_color", fg)
	for k in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, fg_h)
	b.set_meta("active", active)
	(b.get_meta("icon") as Control).queue_redraw()


func _draw_nav_icon(ci: Control, id: String, c: Vector2, col: Color) -> void:
	var w := 1.8
	match id:
		"home":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-8, -0.5), c + Vector2(0, -7.5), c + Vector2(8, -0.5)]), col, w, true)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-5.5, -2.5), c + Vector2(-5.5, 7), c + Vector2(5.5, 7), c + Vector2(5.5, -2.5)]), col, w, true)
			ci.draw_line(c + Vector2(0, 7), c + Vector2(0, 3), col, w, true)
		"daily":
			ci.draw_rect(Rect2(c + Vector2(-7.5, -5.5), Vector2(15, 13)), col, false, w, true)
			ci.draw_line(c + Vector2(-7.5, -1), c + Vector2(7.5, -1), col, w, true)
			ci.draw_line(c + Vector2(-3.5, -8.5), c + Vector2(-3.5, -3.5), col, w, true)
			ci.draw_line(c + Vector2(3.5, -8.5), c + Vector2(3.5, -3.5), col, w, true)
			ci.draw_rect(Rect2(c + Vector2(1.5, 2), Vector2(3, 3)), col)
		"multiplayer":
			ci.draw_arc(c + Vector2(-3.5, -3), 3.2, 0, TAU, 20, col, w, true)
			ci.draw_arc(c + Vector2(-3.5, 8), 6.0, PI, TAU, 16, col, w, true)
			ci.draw_arc(c + Vector2(5, -2), 2.6, 0, TAU, 16, col, w, true)
			ci.draw_arc(c + Vector2(5.5, 8), 4.6, PI * 1.25, TAU, 12, col, w, true)
		"stats":
			ci.draw_rect(Rect2(c + Vector2(-7.5, 0), Vector2(3.6, 7.5)), col)
			ci.draw_rect(Rect2(c + Vector2(-1.8, -4), Vector2(3.6, 11.5)), col)
			ci.draw_rect(Rect2(c + Vector2(3.9, -8), Vector2(3.6, 15.5)), col)
		"settings":
			ci.draw_arc(c, 4.6, 0, TAU, 24, col, w, true)
			for k in 8:
				var d := Vector2.from_angle(k * TAU / 8.0)
				ci.draw_line(c + d * 6.2, c + d * 8.6, col, 2.6, true)
			ci.draw_arc(c, 1.4, 0, TAU, 10, col, w, true)


## Drops the tab names (icons only), then the second wordmark word, when the bar runs out of room.
func _fit_nav() -> void:
	if _nav_bar == null or _nav_row == null:
		return
	var room := _nav_bar.size.x - 44.0
	for compact in [false, true]:
		for k in nav_buttons:
			var b: Button = nav_buttons[k]
			var t: String = "" if compact else String(b.get_meta("label"))
			if b.text != t:
				b.text = t
				_style_tab(b, bool(b.get_meta("active")))
		_nav_word.visible = true
		if _nav_row.get_combined_minimum_size().x <= room:
			return
	_nav_word.visible = false


## Speaker icon that mutes / unmutes the music (same as the M key).
func _build_music_button() -> Button:
	var b := UI.button("", "NavButton", func(): Audio.toggle_music())
	b.custom_minimum_size = Vector2(44, 44)
	b.tooltip_text = "Mute / unmute music (M)"
	var icon := Control.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func():
		var c := icon.size / 2.0 + Vector2(-3, 0)
		var col := UI.INK_MUTED if not b.is_hovered() else UI.INK
		var w := 1.8
		icon.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -3.5), c + Vector2(-4, -3.5), c + Vector2(1, -8.5),
			c + Vector2(1, 8.5), c + Vector2(-4, 3.5), c + Vector2(-8, 3.5)]), col)
		if Audio.music_on():
			icon.draw_arc(c + Vector2(2, 0), 5.5, -0.9, 0.9, 12, col, w, true)
			icon.draw_arc(c + Vector2(2, 0), 10.0, -0.9, 0.9, 16, col, w, true)
		else:
			icon.draw_line(c + Vector2(5, -4.5), c + Vector2(13, 4.5), col, w, true)
			icon.draw_line(c + Vector2(5, 4.5), c + Vector2(13, -4.5), col, w, true))
	b.add_child(icon)
	b.mouse_entered.connect(icon.queue_redraw)
	b.mouse_exited.connect(icon.queue_redraw)
	GameState.settings_changed.connect(icon.queue_redraw)
	return b


func _nav_pressed(target: String) -> void:
	GameState.go(target)


func _on_navigate(screen: String, params: Dictionary) -> void:
	var here := _here()
	if not here.is_empty():
		_back.append(here)
		if _back.size() > HISTORY_MAX:
			_back.pop_front()
	_forward.clear()
	_show(screen, params)


func go_back() -> void:
	_step(_back, _forward)


func go_forward() -> void:
	_step(_forward, _back)


func _step(from: Array, to: Array) -> void:
	while not from.is_empty():
		var entry: Array = from.pop_back()
		if not _valid(entry):
			continue  # e.g. a game that has since been solved or replaced
		var here := _here()
		if not here.is_empty():
			to.append(here)
		_show(entry[0], entry[1])
		return


## History entry for the current screen. A game is stored as "resume this save"
## (never "start this puzzle again"); a game with no save left (solved) is not stored.
func _here() -> Array:
	if current == null:
		return []
	if _screen == "game":
		var slot: String = current.slot
		if slot == "" or not GameState.has_game(slot):
			return []
		return ["game", GameState.resume_params(slot)]
	return [_screen, _params]


func _valid(entry: Array) -> bool:
	if entry[0] != "game":
		return true
	var p: Dictionary = entry[1]
	var slot: String = "daily:" + str(p.daily) if p.has("daily") else str(p.get("slot", ""))
	return GameState.has_game(slot)


func _show(screen: String, params: Dictionary) -> void:
	if current:
		if current.has_method("on_leave"):
			current.on_leave()
		current.queue_free()
	var scr: GDScript = SCREENS.get(screen, SCREENS.home)
	current = scr.new()
	current.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(current)
	if current.has_method("setup"):
		current.setup(params)
	_screen = screen
	_params = params
	for k in nav_buttons:
		var active: bool = (k == screen) or (k == "home" and screen == "variant")
		_style_tab(nav_buttons[k], active)
	_refresh_continue()
	_fit_nav.call_deferred()


## Shows the most recent unfinished game in the nav bar while on any other screen.
func _refresh_continue() -> void:
	var slot := GameState.last_unfinished()
	continue_btn.visible = slot != "" and _screen != "game"
	if not continue_btn.visible:
		return
	var state: Dictionary = GameState.load_game(slot)
	var pz: Dictionary = state.get("puzzle", {})
	var what := "Daily" if slot.begins_with("daily:") else 		"%s · %s" % [Variants.display_name(String(pz.get("variant", ""))), String(pz.get("difficulty", "")).capitalize()]
	continue_btn.text = "Continue  %s  %s" % [what, UI.format_time(float(state.get("elapsed", 0.0)))]
	continue_btn.tooltip_text = "Resume your last unfinished puzzle"


func _input(event: InputEvent) -> void:
	# Mouse side buttons work anywhere, even over the board.
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_XBUTTON1:
			go_back()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_XBUTTON2:
			go_forward()
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# Esc on any screen goes back one screen (screens that use Esc themselves handle it first).
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		var before := _screen
		go_back()
		if _screen == before and _screen != "home":
			GameState.go("home")
		return
	if event is InputEventKey and event.pressed and event.alt_pressed:
		if event.keycode == KEY_LEFT:
			go_back()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_RIGHT:
			go_forward()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M 			and not (get_viewport().gui_get_focus_owner() is LineEdit):
		Audio.toggle_music()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		GameState.settings.fullscreen = not GameState.settings.fullscreen
		GameState.save_settings()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if current and current.has_method("on_leave"):
			current.on_leave()


# ------------------------------------------------------------------ toast

func _build_toast() -> void:
	toast = PanelContainer.new()
	var sb := UI.box(UI.INK, UI.INK, 12, 0, 0)
	sb.content_margin_left = 20; sb.content_margin_right = 20
	sb.content_margin_top = 12; sb.content_margin_bottom = 12
	toast.add_theme_stylebox_override("panel", sb)
	toast_label = UI.label("", 15, UI.PAPER)
	toast.add_child(toast_label)
	toast.modulate.a = 0.0
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast)
	UI.set_meta("toast", self)


func show_toast(text: String) -> void:
	toast_label.text = text
	toast.reset_size()
	await get_tree().process_frame
	toast.position = Vector2((size.x - toast.size.x) / 2.0, size.y - toast.size.y - 28)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast, "modulate:a", 1.0, 0.15)
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.35)
