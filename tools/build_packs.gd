extends SceneTree
## Builds curated puzzle packs into res://puzzles/<variant>.json.
## Existing puzzles (including hand-made ones) are kept; new ones are added until each
## difficulty has `count` puzzles. Every new puzzle is checked for a unique solution and duplicates are skipped.
##
## Everything, one process:   godot --headless -s tools/build_packs.gd -- 500
## One variant/difficulty:    godot --headless -s tools/build_packs.gd -- part killer hard 500
## One shard of it (CI):       godot --headless -s tools/build_packs.gd -- part killer master 100 3
##                             (shard 3 of several: its own seeds and file killer_master_s3.json; merge joins them)
##                            (writes res://puzzles/_parts/killer_hard.json, so many can run in parallel)
## Merge parts into packs:    godot --headless -s tools/build_packs.gd -- merge
##                            (with no parts present this just rewrites the packs one puzzle per line)
## See scripts/core/puzzle.gd for the puzzle format.

const DIFFS := ["beginner", "easy", "medium", "hard", "expert", "master"]
const PARTS := "res://puzzles/_parts/"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 4 and args[0] == "part":
		var shard := int(args[4]) if args.size() >= 5 else -1
		var path := PARTS + ("%s_%s.json" % [args[1], args[2]] if shard < 0 else "%s_%s_s%d.json" % [args[1], args[2], shard])
		_write(path, _build(args[1], args[2], int(args[3]), path, shard))
	elif args.size() >= 1 and args[0] == "merge":
		_merge()
	else:
		var count := int(args[0]) if args.size() > 0 else 10
		for v in Variants.CORE:
			for d in DIFFS:
				var path := PARTS + "%s_%s.json" % [v, d]
				_write(path, _build(v, d, count, path))
		_merge()
	quit()


func _existing(v: String) -> Array:
	var path := "res://puzzles/%s.json" % v
	if not FileAccess.file_exists(path):
		return []
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		return data.get("puzzles", [])
	return data if data is Array else []


## Saves progress to `part_path` every 25 puzzles and resumes from it if it already exists.
func _build(v: String, d: String, count: int, part_path: String, shard := -1) -> Array:
	var list: Array = [] if shard >= 0 else _existing(v).filter(func(p): return p.get("difficulty", "") == d)
	if FileAccess.file_exists(part_path):
		var saved = JSON.parse_string(FileAccess.get_file_as_string(part_path))
		if saved is Array and saved.size() > list.size():
			list = saved
	var seen := {}
	var ids := {}
	for p in list:
		seen[str(p.get("givens", "")) + str(p.get("solution", ""))] = true
		ids[p.get("id", "")] = true
	var seed_value := (hash(v + d) & 0xFFFFFF) + 100000 + list.size() * 1000 + maxi(0, shard) * 50000000
	var next_num := list.size() + 1
	var t0 := Time.get_ticks_msec()
	while list.size() < count:
		seed_value += 1
		Generator.pic_plan = maxi(0, shard) * count + list.size()   # deal pictures evenly (picture variants)
		var p := Generator.make(v, d, seed_value)
		Generator.pic_plan = -1
		if p == null:
			continue
		var key := Puzzle._arr_to_str(p.givens) + Puzzle._arr_to_str(p.solution)
		if seen.has(key):
			continue
		if Solver.new(p).count_solutions(p.givens, 2, 0) != 1:
			continue
		seen[key] = true
		var tag := "" if shard < 0 else "s%d-" % shard
		while ids.has("pack-%s-%s-%s%03d" % [v, d, tag, next_num]):
			next_num += 1
		p.id = "pack-%s-%s-%s%03d" % [v, d, tag, next_num]
		ids[p.id] = true
		next_num += 1
		list.append(p.to_dict())
		if list.size() % 25 == 0:
			_write(part_path, list)
			print("%s %s: %d/%d  (%ds)" % [v, d, list.size(), count, (Time.get_ticks_msec() - t0) / 1000])
	return list


func _merge() -> void:
	for v in Variants.CORE:
		# Keep puzzles whose difficulty isn't one of the three (hand-made extras).
		var list: Array = _existing(v).filter(func(p): return not DIFFS.has(p.get("difficulty", "")))
		for d in DIFFS:
			var path := PARTS + "%s_%s.json" % [v, d]
			var got: Array = []
			if FileAccess.file_exists(path):
				got.append_array(JSON.parse_string(FileAccess.get_file_as_string(path)))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			else:
				got.append_array(_existing(v).filter(func(p): return p.get("difficulty", "") == d))
			# shards from CI: <v>_<d>_s<k>.json, added to what is already there (duplicates skipped)
			var dir := DirAccess.open(PARTS)
			if dir:
				for fn in dir.get_files():
					if fn.begins_with("%s_%s_s" % [v, d]) and fn.ends_with(".json"):
						var seen := {}
						for p in got:
							seen[str(p.get("givens", "")) + str(p.get("solution", ""))] = true
						for p in JSON.parse_string(FileAccess.get_file_as_string(PARTS + fn)):
							var key := str(p.get("givens", "")) + str(p.get("solution", ""))
							if not seen.has(key):
								seen[key] = true
								got.append(p)
						DirAccess.remove_absolute(ProjectSettings.globalize_path(PARTS + fn))
			list.append_array(got)
		_write_pack(v, list)
		print(v, ": ", list.size(), " puzzles")


## One puzzle per line: still valid JSON, but text editors open it quickly
## (a single 1 MB line makes most editors crawl).
func _write_pack(v: String, list: Array) -> void:
	var lines := PackedStringArray()
	for p in list:
		lines.append(JSON.stringify(p, "", false))
	var f := FileAccess.open("res://puzzles/%s.json" % v, FileAccess.WRITE)
	f.store_string('{"variant": "%s", "version": 1, "puzzles": [
%s
]}
' % [v, ",
".join(lines)])


func _write(path: String, list: Array) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PARTS))
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(list, "", false))
