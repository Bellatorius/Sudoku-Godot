extends Control
## Root: top navigation bar (like logic-wiz.com's header) + swappable screen area + toast.

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
	var line := ColorRect.new()
	line.color = UI.LINE
	line.custom_minimum_size = Vector2(0, 1)
	root.add_child(line)

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


func _build_nav() -> Control:
	var bar := MarginContainer.new()
	bar.custom_minimum_size = Vector2(0, 70)
	bar.add_theme_constant_override("margin_left", 40)
	bar.add_theme_constant_override("margin_right", 32)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	bar.add_child(h)

	var logo := Button.new()
	logo.theme_type_variation = "NavButton"
	logo.focus_mode = Control.FOCUS_NONE
	logo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	logo.pressed.connect(func(): GameState.go("home"))
	var lh := HBoxContainer.new()
	lh.add_theme_constant_override("separation", 10)
	lh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lh.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dot := Control.new()
	dot.custom_minimum_size = Vector2(10, 10)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.draw.connect(func(): dot.draw_circle(Vector2(5, 5), 5, UI.ACCENT, true, -1.0, true))
	lh.add_child(dot)
	var name_l := UI.label("Sudoku Variants", 26, UI.INK, UI.font_serif)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lh.add_child(name_l)
	logo.custom_minimum_size = Vector2(150, 44)
	logo.add_child(lh)
	h.add_child(logo)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sp)

	continue_btn = UI.button("", "", func():
		var slot := GameState.last_unfinished()
		if slot != "":
			GameState.go("game", GameState.resume_params(slot)))
	continue_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	continue_btn.add_theme_color_override("font_color", UI.ACCENT)
	continue_btn.add_theme_color_override("font_hover_color", UI.ACCENT)
	continue_btn.visible = false
	h.add_child(continue_btn)
	h.add_child(UI.spacer(0, 8))

	for item in [["Home", "home"], ["Daily", "daily"], ["Multiplayer", "multiplayer"], ["Stats", "stats"], ["Settings", "settings"]]:
		var b := UI.button(item[0], "NavButton")
		b.add_theme_font_size_override("font_size", 16)
		var target: String = item[1]
		b.pressed.connect(func(): _nav_pressed(target))
		h.add_child(b)
		nav_buttons[target] = b
	h.add_child(_build_music_button())
	h.add_child(UI.spacer(0, 12))
	var quit := UI.button("Quit", "PrimaryButton", func(): get_tree().quit())
	quit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(quit)
	return bar


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
		nav_buttons[k].add_theme_color_override("font_color", UI.INK if active else UI.INK_MUTED)
	_refresh_continue()


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
