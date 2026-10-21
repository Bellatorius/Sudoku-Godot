extends SceneTree
## Pre-builds the daily puzzles into res://puzzles/daily.json, so every player gets exactly the same
## puzzle for a date and later generator changes never alter a day. Schedule: scripts/core/daily.gd.
##
## One range (parallel-safe):  godot --headless -s tools/build_daily.gd -- part 2026-01-01 60
##                             (writes res://puzzles/_parts/daily_2026-01-01.json, resumable)
## Merge parts into the file:  godot --headless -s tools/build_daily.gd -- merge
##                             (keeps days already in daily.json; never changes an existing day)

const PARTS := "res://puzzles/_parts/"
const OUT := "res://puzzles/daily.json"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 3 and args[0] == "part":
		_part(args[1], int(args[2]))
	elif args.size() >= 1 and args[0] == "merge":
		_merge()
	quit()


func _existing() -> Dictionary:
	if not FileAccess.file_exists(OUT):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(OUT))
	return data.get("days", {}) if data is Dictionary else {}


func _part(start: String, count: int) -> void:
	var path := PARTS + "daily_%s.json" % start
	var done := {}
	if FileAccess.file_exists(path):
		var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
		if saved is Dictionary:
			done = saved
	var have := _existing()
	var t0 := Time.get_ticks_msec()
	for k in count:
		var date := Time.get_date_string_from_unix_time(Daily.date_unix(start) + k * 86400)
		if done.has(date) or have.has(date):
			continue
		var info := Daily.info(date)
		var p: Puzzle = null
		var seed_value: int = info.seed
		while p == null:   # deterministic: the same seeds are tried in the same order everywhere
			p = Generator.make(info.variant, info.difficulty, seed_value)
			if p and Solver.new(p).count_solutions(p.givens, 2, 0) != 1:
				p = null
			seed_value += 1
		p.id = "daily-" + date
		done[date] = p.to_dict()
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(done))
		f = null
		print("%s %s %s  (%ds)" % [date, info.variant, info.difficulty, (Time.get_ticks_msec() - t0) / 1000])


func _merge() -> void:
	var days := _existing()
	var dir := DirAccess.open(PARTS)
	if dir:
		for fn in dir.get_files():
			if not fn.begins_with("daily_"):
				continue
			var data = JSON.parse_string(FileAccess.get_file_as_string(PARTS + fn))
			if data is Dictionary:
				for d in data:
					if not days.has(d):
						days[d] = data[d]
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PARTS + fn))
	var keys := days.keys()
	keys.sort()
	var lines := PackedStringArray()
	for d in keys:
		lines.append('"%s": %s' % [d, JSON.stringify(days[d], "", false)])
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string('{"version": 1, "days": {\n%s\n}}\n' % ",\n".join(lines))
	print("daily.json: %d days (%s … %s)" % [keys.size(), keys[0] if keys.size() else "-", keys[-1] if keys.size() else "-"])
