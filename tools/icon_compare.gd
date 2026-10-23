extends Control
## Dev helper: old (top) and new (bottom) icon of every variant, numbered → user://shots/icons_compare_<n>.png

func _ready() -> void:
	var all: Array = Variants.standard()
	var pages := int(ceil(all.size() / 40.0))
	for page in pages:
		for ch in get_children():
			ch.queue_free()
		var bg := ColorRect.new()
		bg.color = UI.PAPER
		bg.size = Vector2(1500, 900)
		add_child(bg)
		var ids: Array = all.slice(page * 40, page * 40 + 40)
		for i in ids.size():
			var n: int = page * 40 + i + 1
			var x := (i % 10) * 141 + 4
			var y := (i / 10) * 200 + 4
			var card := Panel.new()
			card.position = Vector2(x, y)
			card.size = Vector2(136, 194)
			card.add_theme_stylebox_override("panel", UI.box(UI.SURFACE, Color(UI.INK, 0.12), 10, 1))
			add_child(card)
			var l := UI.label("%d. %s" % [n, Variants.display_name(ids[i])], 11, UI.INK, UI.font_sans_bold)
			l.position = Vector2(x + 6, y + 4)
			l.size = Vector2(126, 30)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(l)
			for k in 2:
				var ic := VariantIcon.new(ids[i], 56)
				ic.style = 1 if k == 0 else 0
				ic.position = Vector2(x + 40, y + 36 + k * 76)
				ic.size = Vector2(56, 56)
				add_child(ic)
				var tag := UI.label("old" if k == 0 else "new", 10, UI.INK_MUTED)
				tag.position = Vector2(x + 8, y + 56 + k * 76)
				add_child(tag)
		for f in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
		get_viewport().get_texture().get_image().save_png("user://shots/icons_compare_%d.png" % (page + 1))
	get_tree().quit()
