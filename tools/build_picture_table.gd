extends SceneTree
## Tests every hand-drawn picture against every picture line type (Generator.PICTURE) and writes
## res://puzzles/pictures.json: {"9": {type: [picture names that fit]}, "6": {...}}. The generator only
## picks pictures from that table, so it never wastes time on a picture a rule can't satisfy.
##   godot --headless -s tools/build_picture_table.gd -- part <type> <type> …   (writes _parts/pictures_<type>.json)
##   godot --headless -s tools/build_picture_table.gd -- merge
## Only new pictures: put {"9": [names], "6": [names]} of the already tested ones in
## res://puzzles/_parts/pictures_tested.json; part skips those and merge keeps the old results.

const TRIES := 5
const NODES := 12000


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1 and args[0] == "merge":
		_merge()
	elif args.size() >= 4 and args[0] == "shard":   # shard <type> <k> <n>: only pictures k, k+n, k+2n … (for CI)
		_part(args[1], int(args[2]), int(args[3]))
	else:
		var types: Array = args.slice(1) if args.size() > 1 else Generator.PICTURE.values()
		for t in types:
			_part(t)
	quit()


func _part(t: String, shard := 0, shards := 1) -> void:
	var out := {}
	for n in [9, 6]:
		var rule := ""
		for v in Generator.PICTURE:
			if Generator.PICTURE[v] == t and (n == 9 or v in Variants.MINI):
				rule = v
		if rule == "":
			continue
		var ok: Array = []
		var lib: Array = Shapes.PICTURES_9 if n == 9 else Shapes.PICTURES_6
		var skip: Array = _tested().get(str(n), [])
		for pi in lib.size():
			var pic: Array = lib[pi]
			if skip.has(pic[0]) or pi % shards != shard:
				continue
			for k in TRIES:
				var g := Generator.new()
				g.rng.seed = hash(pic[0] + t) + k
				g._n = n
				g._nc = n * n
				var pz := Puzzle.new()
				pz.variant = rule if n == 9 else "mini_" + rule
				var lines: Array = g._picture_lines(pz, Shapes.parse(pic[1], n), t)
				if lines.size() < 3:
					continue
				for cells in lines:
					if t == "th": pz.thermos.append(cells)
					else: pz.lines.append({"t": t, "cells": cells})
				var empty := PackedInt32Array()
				empty.resize(n * n)
				if Solver.new(pz).solve(empty, g.rng, NODES).size() == n * n:
					ok.append(pic[0])
					break
		out[str(n)] = ok
		print("%s %dx%d: %d / %d pictures" % [t, n, n, ok.size(), lib.size()])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://puzzles/_parts/"))
	var f := FileAccess.open("res://puzzles/_parts/pictures_%s.json" % (t if shards == 1 else "%s_s%d" % [t, shard]), FileAccess.WRITE)
	f.store_string(JSON.stringify(out))


func _tested() -> Dictionary:
	var path := "res://puzzles/_parts/pictures_tested.json"
	if not FileAccess.file_exists(path):
		return {}
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _merge() -> void:
	var table := {"9": {}, "6": {}}
	if not _tested().is_empty() and FileAccess.file_exists("res://puzzles/pictures.json"):
		table = JSON.parse_string(FileAccess.get_file_as_string("res://puzzles/pictures.json"))   # keep earlier results
	var dir := DirAccess.open("res://puzzles/_parts/")
	for fn in dir.get_files():
		if fn.begins_with("pictures_") and fn.ends_with(".json"):
			var t := fn.trim_prefix("pictures_").trim_suffix(".json").get_slice("_s", 0)   # shards: pictures_tn_s3.json
			var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://puzzles/_parts/" + fn))
			for n in d:
				var have: Array = table[n].get(t, [])
				for name in d[n]:
					if not have.has(name):
						have.append(name)
				table[n][t] = have
	var f := FileAccess.open("res://puzzles/pictures.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(table, "  "))
	print("pictures.json written")
