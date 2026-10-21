class_name ExampleHint
extends Control
## Small clickable "i" icon next to the rules. Clicking it emits `pressed` (the game screen then shows
## a solved example puzzle of the variant).

signal pressed

var _hover := false


func _init() -> void:
	custom_minimum_size = Vector2(24, 24)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Show a solved example"
	mouse_entered.connect(func():
		_hover = true
		queue_redraw())
	mouse_exited.connect(func():
		_hover = false
		queue_redraw())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		pressed.emit()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 1.5
	var col := UI.ACCENT if _hover else UI.INK_MUTED
	if _hover:
		draw_circle(c, r, Color(UI.ACCENT, 0.15), true, -1.0, true)
	draw_arc(c, r, 0, TAU, 32, col, 1.6, true)
	draw_circle(c + Vector2(0, -r * 0.45), 1.6, col, true, -1.0, true)
	draw_line(c + Vector2(0, -r * 0.1), c + Vector2(0, r * 0.55), col, 1.8, true)
