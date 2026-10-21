extends Node
## Persistent player data (settings, stats, in-progress saves), puzzle packs,
## daily puzzle selection and screen navigation.

signal navigate(screen: String, params: Dictionary)
signal settings_changed

const SETTINGS_PATH := "user://settings.json"
const STATS_PATH := "user://stats.json"
const SAVES_PATH := "user://saves.json"
const DIFFICULTIES := ["beginner", "easy", "medium", "hard", "expert", "master"]

var settings := {
	"highlight_conflicts": true,
	"highlight_same": true,
	"highlight_peers": true,
	"show_timer": true,
	"auto_clear_notes": true,
	"color_notes": true,
	"fullscreen": false,
	"dark_mode": true,  # dark is the main look; players can switch it off in Settings
	"music_on": true,
	"music_volume": 0.5,
	"sfx_on": true,
	"sfx_volume": 0.7,
	"random_difficulty": "medium",   # last difficulty picked for the random puzzle
	"fps_cap": 240,     # frames per second limit (30–240; with V-Sync on, at most the monitor's refresh rate)
	"vsync": true,      # V-Sync also limits the game to the monitor's refresh rate
}
var stats := {
	"total_solved": 0,
	"variants": {},        # id -> {solved, best: {easy, medium, hard}, no_hint}
	"pack_done": {},       # puzzle id -> true
	"daily": {"last": "", "streak": 0, "best_streak": 0, "done": {}},
}
var saves := {}            # slot -> serialized game state

var _packs := {}


func _ready() -> void:
	settings.merge(_read(SETTINGS_PATH), true)
	var s := _read(STATS_PATH)
	for k in s:
		stats[k] = s[k]
	stats.erase("abandoned")   # the old "unfinished puzzles" list is no longer used
	saves = _read(SAVES_PATH)
	apply_settings()


func go(screen: String, params := {}) -> void:
	navigate.emit(screen, params)


# ------------------------------------------------------------------ io

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


func _write(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func save_settings() -> void:
	_clamp_fps()
	_write(SETTINGS_PATH, settings)
	apply_settings()
	settings_changed.emit()


func apply_settings() -> void:
	UI.set_dark(bool(settings.get("dark_mode", true)))
	_clamp_fps()
	Engine.max_fps = fps_limit()
	if DisplayServer.get_name() == "headless":
		return
	var vs := DisplayServer.VSYNC_ENABLED if bool(settings.get("vsync", true)) else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != vs:
		DisplayServer.window_set_vsync_mode(vs)
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want:
		DisplayServer.window_set_mode(want)


## Highest FPS cap allowed now: 240, or the monitor's refresh rate while V-Sync is on.
func fps_max() -> int:
	var top := 240
	if bool(settings.get("vsync", true)) and DisplayServer.get_name() != "headless":
		var hz := int(roundf(DisplayServer.screen_get_refresh_rate()))
		if hz > 0:
			top = mini(top, hz)
	return top


## With V-Sync on the cap can't be above the monitor, so the saved value comes down to it too:
## turning V-Sync off later keeps that value (the slider stays where it was) instead of jumping back up.
func _clamp_fps() -> void:
	var cap := int(settings.get("fps_cap", 240))
	if cap <= 0:
		cap = 240
	settings.fps_cap = clampi(cap, 30, fps_max())


## The cap actually in use (older saves stored 0 for "no limit").
func fps_limit() -> int:
	var cap := int(settings.get("fps_cap", 240))
	if cap <= 0:
		cap = 240
	return clampi(cap, 30, fps_max())


func save_stats() -> void:
	_write(STATS_PATH, stats)


# ------------------------------------------------------------------ saves

func store_game(slot: String, state: Dictionary) -> void:
	state["saved_at"] = Time.get_unix_time_from_system()
	saves[slot] = state
	_write(SAVES_PATH, saves)


func load_game(slot: String) -> Dictionary:
	return saves.get(slot, {})


func clear_game(slot: String) -> void:
	if saves.erase(slot):
		_write(SAVES_PATH, saves)


func has_game(slot: String) -> bool:
	return saves.has(slot)


## Slot of the most recently saved unfinished game, or "" if there is none.
func last_unfinished() -> String:
	var best := ""
	var best_t := -1.0
	for slot in saves:
		var t: float = float(saves[slot].get("saved_at", 0.0))
		if t > best_t:
			best = slot
			best_t = t
	return best


## Navigation params that resume a saved slot.
func resume_params(slot: String) -> Dictionary:
	if slot.begins_with("daily:"):
		return {"daily": slot.substr(6)}
	return {"slot": slot}


# ------------------------------------------------------------------ packs

func pack(variant: String) -> Array:
	if not _packs.has(variant):
		var list: Array = []
		var path := "res://puzzles/%s.json" % variant
		if FileAccess.file_exists(path):
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			if data is Dictionary:
				list = data.get("puzzles", [])
			elif data is Array:
				list = data
		_packs[variant] = list
	return _packs[variant]


func pack_puzzles(variant: String, difficulty: String) -> Array:
	return pack(variant).filter(func(d): return d.get("difficulty", "") == difficulty)


func pack_progress(variant: String, difficulty: String) -> Vector2i:
	var list := pack_puzzles(variant, difficulty)
	var done := 0
	for d in list:
		if stats.pack_done.has(d.get("id", "")):
			done += 1
	return Vector2i(done, list.size())


## Different pack puzzles solved in a variant, summed over the difficulties: the same numbers the
## variant page shows per difficulty (dailies and repeat solves are counted on the Stats page).
func variant_solved_count(variant: String) -> int:
	var n := 0
	for d in DIFFICULTIES:
		n += pack_progress(variant, d).x
	return n


## Params for a random Free Play puzzle: a random playable variant at difficulty `d` (the
## Easy / Medium / Hard buttons on the home page). Prefers variants without an unfinished game at
## that difficulty, so starting a random puzzle doesn't shelve something you're in the middle of.
func random_game_params(d: String) -> Dictionary:
	if not DIFFICULTIES.has(d):
		d = "easy"
	var pool: Array = Variants.CORE.filter(func(v): return not has_game("%s:%s" % [v, d]))
	if pool.is_empty():
		pool = Variants.CORE.duplicate()
	return new_game_params(pool.pick_random(), d)


## Navigation params for a brand-new game in "<variant>:<difficulty>". There is one game per slot:
## an unfinished game there is simply replaced (not kept), and the new puzzle is always a different
## one. Solved pack puzzles never repeat. Falls back to the generator once the pack is all solved.
func new_game_params(variant: String, difficulty: String) -> Dictionary:
	var slot := "%s:%s" % [variant, difficulty]
	var last := ""
	if saves.has(slot):
		last = puzzle_key(saves[slot].get("puzzle", {}))
		clear_game(slot)
	var fresh := pack_puzzles(variant, difficulty).filter(func(p):
		return not stats.pack_done.has(p.get("id", "")) and puzzle_key(p) != last)
	if not fresh.is_empty():
		return {"slot": slot, "pack": fresh.pick_random()}
	return {"slot": slot, "generate": {"variant": variant, "difficulty": difficulty, "seed": randi()}}


## Identifies a puzzle: its id plus givens (some Kropki puzzles have no givens at all).
static func puzzle_key(p: Dictionary) -> String:
	return "%s|%s" % [p.get("id", ""), p.get("givens", "")]


# ------------------------------------------------------------------ daily

## Today's date for the daily puzzle and streaks: UTC, so it is the same day for every player.
func today() -> String:
	return Daily.today()


## First day the daily calendar lets players go back to (see Daily.FIRST_DATE).
const DAILY_FIRST_DATE := Daily.FIRST_DATE
const DAILY_PATH := "res://puzzles/daily.json"
var _daily_days = null   # date -> puzzle dict, loaded on first use
var _daily_keys: Array = []   # the file's dates, sorted (for starting over after the last one)


## Variant (rotating through all of them), difficulty (by weekday) and the puzzle for a date.
## The puzzle comes from the pre-built puzzles/daily.json ("puzzle" key), so every player gets
## exactly the same one; after the file's last day it starts again from its first day.
## Only without the file is it generated from the date's seed.
func daily_info(date := "") -> Dictionary:
	if date == "":
		date = today()
	var info := Daily.info(date)
	if _daily_days == null:
		_daily_days = {}
		if FileAccess.file_exists(DAILY_PATH):
			var data = JSON.parse_string(FileAccess.get_file_as_string(DAILY_PATH))
			if data is Dictionary:
				_daily_days = data.get("days", {})
		_daily_keys = _daily_days.keys()
		_daily_keys.sort()
	var key := date
	if not _daily_days.has(key) and not _daily_keys.is_empty() and date > str(_daily_keys[-1]):
		# past the last pre-built day: start again from the first one (same for every player)
		var n := _daily_keys.size()
		key = _daily_keys[posmod(Daily.day_index(date) - Daily.day_index(_daily_keys[0]), n)]
	if _daily_days.has(key):
		info.puzzle = _daily_days[key].duplicate()
		info.puzzle.id = "daily-" + date
		info.variant = str(info.puzzle.get("variant", info.variant))
		info.difficulty = str(info.puzzle.get("difficulty", info.difficulty))
	return info


func daily_done(date := "") -> bool:
	return stats.daily.done.has(date if date != "" else today())


## Solve time in seconds for a daily, or 0 if unknown / not solved.
func daily_time(date: String) -> float:
	var d = stats.daily.done.get(date, null)
	return float(d.get("time", 0.0)) if d is Dictionary else 0.0


static func date_unix(date: String) -> int:
	return Time.get_unix_time_from_datetime_string(date + "T12:00:00")


static func add_days(date: String, n: int) -> String:
	return Time.get_date_string_from_unix_time(date_unix(date) + n * 86400)


## 0 = Monday … 6 = Sunday.
static func weekday(date: String) -> int:
	var wd: int = Time.get_datetime_dict_from_unix_time(date_unix(date)).weekday  # 0 = Sunday
	return (wd + 6) % 7


# ------------------------------------------------------------------ stats

func variant_stats(id: String) -> Dictionary:
	if not stats.variants.has(id):
		stats.variants[id] = {"solved": 0, "best": {}, "no_hint": 0}
	return stats.variants[id]


## Records a solve and returns a summary {new_best: bool, streak: int}.
func record_solve(puzzle: Puzzle, seconds: float, hints: int, daily_date: String) -> Dictionary:
	var vs := variant_stats(puzzle.variant)
	vs.solved = int(vs.solved) + 1
	if hints == 0:
		vs.no_hint = int(vs.get("no_hint", 0)) + 1
	var best: Dictionary = vs.best
	var prev: float = float(best.get(puzzle.difficulty, 0.0))
	var new_best := prev <= 0.0 or seconds < prev
	if new_best:
		best[puzzle.difficulty] = seconds
	stats.total_solved = int(stats.total_solved) + 1
	if puzzle.id.begins_with("pack-"):
		stats.pack_done[puzzle.id] = true

	var streak := int(stats.daily.streak)
	if daily_date != "" and not stats.daily.done.has(daily_date):
		stats.daily.done[daily_date] = {"time": seconds, "hints": hints}
		# Only today's daily counts toward the streak; catching up on past days doesn't.
		if daily_date == today():
			streak = streak + 1 if stats.daily.last == add_days(daily_date, -1) else 1
			stats.daily.streak = streak
			stats.daily.last = daily_date
			stats.daily.best_streak = maxi(int(stats.daily.best_streak), streak)
		SteamManager.upload_daily_time(daily_date, seconds)
	save_stats()
	SteamManager.on_solve(puzzle, seconds, hints, daily_date != "", stats)
	return {"new_best": new_best, "streak": streak}


func current_streak() -> int:
	var last: String = stats.daily.last
	if last == "":
		return 0
	var yesterday := Time.get_date_string_from_unix_time(
		Time.get_unix_time_from_datetime_string(today() + "T12:00:00") - 86400)
	if last == today() or last == yesterday:
		return int(stats.daily.streak)
	return 0
