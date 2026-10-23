extends Control
## Dev helper: every variant icon with its name → user://shots/icons_<light|dark>.png (run with a display).

func _ready() -> void:
	for job in [[false, 0], [false, 1], [true, 0], [true, 1]]:
		var dark: bool = job[0]
		var page: int = job[1]
		UI.set_dark(dark)
		for ch in get_children():
			ch.queue_free()
		var bg := ColorRect.new()
		bg.color = UI.PAPER
		bg.size = Vector2(1900, 1060)
		add_child(bg)
		var all: Array = Variants.standard() + ["mini_killer", "mini_thermo"]
		var ids: Array = all.slice(page * 50, page * 50 + 50)
		for i in ids.size():
			var x := (i % 10) * 141 + 4
			var y := (i / 10) * 158 + 4
			var card := Panel.new()
			card.position = Vector2(x, y)
			card.size = Vector2(136, 152)
			card.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, Color(UI.INK, 0.12), 10, 1))
			add_child(card)
			var ic := VariantIcon.new(ids[i], 64)
			ic.position = Vector2(x + 36, y + 8)
			ic.size = Vector2(64, 64)
			add_child(ic)
			var small := VariantIcon.new(ids[i], 30)
			small.position = Vector2(x + 6, y + 84)
			small.size = Vector2(30, 30)
			add_child(small)
			var l := UI.label(Variants.display_name(ids[i]), 11, UI.INK)
			l.position = Vector2(x + 40, y + 84)
			l.size = Vector2(94, 60)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(l)
		for k in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
		get_viewport().get_texture().get_image().save_png("user://shots/icons_%s_%d.png" % ["dark" if dark else "light", page + 1])
	get_tree().quit()
