extends Node
## Optional Steam integration via the GodotSteam GDExtension
## (https://godotsteam.com — install "GodotSteam GDExtension" from the Asset Library).
## The game runs normally without it; achievements are then only logged.
##
## Achievement API names below must match the ones you create in Steamworks
## (App Admin → Stats & Achievements).

## 480 = Valve's "Spacewar" test app. Replace with your own App ID.
const APP_ID := 480

const ACHIEVEMENTS := {
	"FIRST_SOLVE":    "First Steps — solve your first puzzle",
	"SOLVE_10":       "Getting Warm — solve 10 puzzles",
	"SOLVE_50":       "Puzzle Addict — solve 50 puzzles",
	"SOLVE_100":      "Sudoku Wizard — solve 100 puzzles",
	"ALL_CORE":       "Variety Pack — solve every core variant",
	"HARD_SOLVE":     "Hard Boiled — solve a Hard puzzle",
	"HARD_NO_HINTS":  "Unassisted — solve a Hard puzzle without hints",
	"SPEED_CLASSIC":  "Speed Demon — solve a Medium or Hard Classic in under 5 minutes",
	"KILLER_INSTINCT":"Killer Instinct — solve 10 Killer puzzles",
	"DAILY_FIRST":    "Daily Habit — complete a daily puzzle",
	"DAILY_STREAK_7": "On a Roll — 7-day daily streak",
	"DAILY_STREAK_30":"Devoted — 30-day daily streak",
	# added 2026-10-22 (levels, groups, Mini, multiplayer)
	"SOLVE_250":      "Grid Regular — solve 250 puzzles",
	"SOLVE_500":      "Grid Veteran — solve 500 puzzles",
	"SOLVE_1000":     "Thousand Grids — solve 1,000 puzzles",
	"EXPERT_SOLVE":   "Expert Eye — solve an Expert puzzle",
	"EXPERT_10":      "Sharp Mind — solve 10 Expert puzzles",
	"MASTER_SOLVE":   "Master Class — solve a Master puzzle",
	"MASTER_10":      "Grandmaster — solve 10 Master puzzles",
	"MASTER_50":      "Living Legend — solve 50 Master puzzles",
	"MASTER_FLAWLESS":"Flawless — solve a Master puzzle without a mistake",
	"ALL_LEVELS":     "Full Ladder — solve one variant at all six levels",
	"BLANK_SLATE":    "Blank Slate — solve a puzzle that starts with no digits",
	"NO_HINTS_25":    "Self-Made — solve 25 puzzles without hints",
	"VARIETY_25":     "Explorer — solve 25 different variants",
	"CAT_REGIONS":    "Region Ranger — solve every Regions variant",
	"CAT_LINES":      "Line Walker — solve every Lines variant",
	"CAT_SUMS":       "Sum Total — solve every Sums & Arrows variant",
	"CAT_OUTSIDE":    "Outsider — solve every Outside Clues variant",
	"CAT_DOTS":       "Dot Connector — solve every Dots & Signs variant",
	"CAT_MARKS":      "Marked Cells — solve every Cell Marks variant",
	"CAT_THEMES":     "Polyglot — solve every Letters & Symbols variant",
	"CAT_GLOBAL":     "Chess Club — solve every Chess & Global Rules variant",
	"CAT_MINI":       "Small Wonders — solve every Mini 6×6 variant",
	"MINI_FIRST":     "Pocket Puzzle — solve a Mini 6×6 puzzle",
	"MINI_SPRINT":    "Mini Sprint — solve a Mini Medium or harder in under 2 minutes",
	"DAILY_10":       "Ten Days — complete 10 daily puzzles",
	"DAILY_STREAK_100":"Unbreakable — 100-day daily streak",
	"MP_FIRST_RACE":  "At the Start Line — finish a 1v1 race",
	"MP_FIRST_WIN":   "First Blood — win a 1v1 race",
	"MP_WINS_10":     "Racer — win 10 races",
	"MP_WINS_50":     "Champion — win 50 races",
}

## Emitted when a daily leaderboard download finishes.
## entries: [{rank, name, seconds, is_me}]; error is "" on success.
signal daily_leaderboard_loaded(date: String, friends: bool, entries: Array, error: String)

var steam: Object = null
var enabled := false

# Leaderboards: one board per day, "daily_YYYY-MM-DD", created on first use, lowest time first.
const LB_SORT_ASCENDING := 1
const LB_DISPLAY_MILLISECONDS := 3
const LB_GLOBAL := 0
const LB_FRIENDS := 2
var _boards := {}            # board name -> handle
var _finding := ""           # board name currently being looked up (Steam answers one at a time)
var _find_queue: Array = []  # [board name, Callable(handle)]
var _downloads := {}         # handle -> [date, friends]


var last_status := -1        # steamInitEx status: 0 ok, 1 failed, 2 Steam not running, 3 version mismatch
var _signals_connected := false


func _ready() -> void:
	if not Engine.has_singleton("Steam"):
		print("[Steam] GodotSteam not installed — running without Steam.")
		return
	try_init()


## True when the GodotSteam plugin is part of this build.
func plugin_installed() -> bool:
	return Engine.has_singleton("Steam")


## (Re)tries to connect to the Steam client, e.g. after the player starts Steam. Returns enabled.
func try_init() -> bool:
	if enabled or not plugin_installed():
		return enabled
	steam = Engine.get_singleton("Steam")
	OS.set_environment("SteamAppId", str(APP_ID))
	OS.set_environment("SteamGameId", str(APP_ID))
	var res = steam.call("steamInitEx")
	var status := -1
	if res is Dictionary:
		status = int(res.get("status", -1))
	elif res is int or res is bool:
		status = 0 if res else -1
	last_status = status
	enabled = status == 0
	print("[Steam] init status=", status, " result=", res)
	if enabled and steam.has_method("requestCurrentStats"):
		steam.call("requestCurrentStats")
	if enabled and not _signals_connected:
		_signals_connected = true
		# Lambdas with optional args: the signal signatures differ slightly between GodotSteam versions.
		steam.connect("leaderboard_find_result", func(a = null, b = null, _c = null): _on_find_result(a, b))
		steam.connect("leaderboard_scores_downloaded", func(a = null, b = null, c = null): _on_scores(a, b, c))
	return enabled


## Whether the Steam client is running on this PC (works without the plugin; Windows only).
static func client_running() -> bool:
	if OS.get_name() != "Windows":
		return false
	var out: Array = []
	OS.execute("tasklist", ["/FI", "IMAGENAME eq steam.exe", "/NH"], out)
	return not out.is_empty() and str(out[0]).to_lower().contains("steam.exe")


func _process(_delta: float) -> void:
	if enabled:
		steam.call("run_callbacks")


func persona_name() -> String:
	if enabled:
		return str(steam.call("getPersonaName"))
	return ""


func unlock(api_name: String) -> void:
	if not ACHIEVEMENTS.has(api_name):
		push_warning("Unknown achievement " + api_name)
	if not enabled:
		print("[Steam] (offline) achievement: ", api_name)
		return
	var cur = steam.call("getAchievement", api_name)
	if cur is Dictionary and cur.get("achieved", false):
		return
	steam.call("setAchievement", api_name)
	steam.call("storeStats")


func on_solve(puzzle: Puzzle, seconds: float, hints: int, is_daily: bool, stats: Dictionary, mistakes := 0) -> void:
	var total := int(stats.total_solved)
	unlock("FIRST_SOLVE")
	for n in [10, 50, 100, 250, 500, 1000]:
		if total >= n: unlock("SOLVE_%d" % n)
	if puzzle.difficulty in ["hard", "expert", "master"]:
		unlock("HARD_SOLVE")
		if hints == 0:
			unlock("HARD_NO_HINTS")
	var levels: Dictionary = stats.get("levels", {})
	var at := int(levels.get(puzzle.difficulty, 0))
	if puzzle.difficulty == "expert":
		unlock("EXPERT_SOLVE")
		if at >= 10: unlock("EXPERT_10")
	if puzzle.difficulty == "master":
		unlock("MASTER_SOLVE")
		if at >= 10: unlock("MASTER_10")
		if at >= 50: unlock("MASTER_50")
		if mistakes == 0 and hints == 0: unlock("MASTER_FLAWLESS")
	if puzzle.given_count() == 0:
		unlock("BLANK_SLATE")
	if puzzle.size == 6:
		unlock("MINI_FIRST")
		if not puzzle.difficulty in ["beginner", "easy"] and seconds < 120:
			unlock("MINI_SPRINT")
	if puzzle.variant == "classic" and not puzzle.difficulty in ["beginner", "easy"] and seconds < 300:
		unlock("SPEED_CLASSIC")
	var vs: Dictionary = stats.variants
	if int(vs.get("killer", {}).get("solved", 0)) >= 10:
		unlock("KILLER_INSTINCT")
	var solved := func(id: String) -> bool: return int(vs.get(id, {}).get("solved", 0)) > 0
	if Variants.CORE.all(solved):
		unlock("ALL_CORE")
	if Variants.CORE.filter(solved).size() >= 25:
		unlock("VARIETY_25")
	for g in Variants.CATEGORIES:
		if (g[2] as Array).all(solved):
			unlock("CAT_" + str(g[0]).to_upper())
	var no_hint := 0
	var ladder := false
	for id in vs:
		no_hint += int(vs[id].get("no_hint", 0))
		ladder = ladder or (vs[id].get("best", {}) as Dictionary).size() >= 6   # a best time at every level
	if ladder:
		unlock("ALL_LEVELS")
	if no_hint >= 25:
		unlock("NO_HINTS_25")
	if is_daily:
		unlock("DAILY_FIRST")
		var streak := int(stats.daily.streak)
		if streak >= 7: unlock("DAILY_STREAK_7")
		if streak >= 30: unlock("DAILY_STREAK_30")
		if streak >= 100: unlock("DAILY_STREAK_100")
		if (stats.daily.done as Dictionary).size() >= 10: unlock("DAILY_10")


## After a 1v1 race (stats.multiplayer already counts it).
func on_versus(won: bool, mp: Dictionary) -> void:
	unlock("MP_FIRST_RACE")
	var wins := int(mp.get("wins", 0))
	if won: unlock("MP_FIRST_WIN")
	if wins >= 10: unlock("MP_WINS_10")
	if wins >= 50: unlock("MP_WINS_50")


# ------------------------------------------------------------------ daily leaderboards

static func daily_board(date: String) -> String:
	return "daily_" + date


## Uploads a daily solve time (kept only if it's the player's best on that board).
func upload_daily_time(date: String, seconds: float) -> void:
	if not enabled:
		print("[Steam] (offline) daily time ", date, " ", seconds)
		return
	var ms := int(round(seconds * 1000.0))
	_with_board(daily_board(date), func(h: int):
		steam.call("uploadLeaderboardScore", ms, true, PackedInt32Array(), h))


## Requests the top 10 (or friends) for a day; answers via daily_leaderboard_loaded.
func request_daily_leaderboard(date: String, friends := false) -> void:
	if not enabled:
		daily_leaderboard_loaded.emit(date, friends, [], "offline")
		return
	_with_board(daily_board(date), func(h: int):
		_downloads[h] = [date, friends]
		if friends:
			steam.call("downloadLeaderboardEntries", 1, 100, LB_FRIENDS, h)
		else:
			steam.call("downloadLeaderboardEntries", 1, 10, LB_GLOBAL, h))


func _with_board(board: String, then: Callable) -> void:
	if _boards.has(board):
		then.call(int(_boards[board]))
		return
	_find_queue.append([board, then])
	_next_find()


func _next_find() -> void:
	if _finding != "" or _find_queue.is_empty():
		return
	_finding = _find_queue[0][0]
	steam.call("findOrCreateLeaderboard", _finding, LB_SORT_ASCENDING, LB_DISPLAY_MILLISECONDS)


func _on_find_result(handle, found) -> void:
	var board := _finding
	_finding = ""
	var h := int(handle) if handle != null else 0
	if h != 0 and found != null and int(found) != 0:
		_boards[board] = h
	var waiting: Array = _find_queue.filter(func(q): return q[0] == board)
	_find_queue = _find_queue.filter(func(q): return q[0] != board)
	for q in waiting:
		if h != 0:
			q[1].call(h)
	_next_find()


func _on_scores(a, b, c) -> void:
	# GodotSteam 4.x: (message, handle, entries); older builds: (message, entries).
	var handle := int(b) if c != null else 0
	var raw: Array = c if c is Array else (b if b is Array else [])
	var req: Array = _downloads.get(handle, [])
	_downloads.erase(handle)
	if req.is_empty():
		if _downloads.is_empty():
			return
		var k = _downloads.keys()[0]
		req = _downloads[k]
		_downloads.erase(k)
	var me := int(steam.call("getSteamID"))
	var entries: Array = []
	for e in raw:
		var sid := int(e.get("steam_id", 0))
		entries.append({
			"rank": int(e.get("global_rank", entries.size() + 1)),
			"name": str(steam.call("getFriendPersonaName", sid)) if sid != me else persona_name(),
			"seconds": float(e.get("score", 0)) / 1000.0,
			"is_me": sid == me,
		})
	daily_leaderboard_loaded.emit(req[0], req[1], entries, "")
