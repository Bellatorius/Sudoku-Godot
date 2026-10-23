class_name Daily
extends RefCounted
## The daily puzzle schedule: which variant and difficulty each date gets, and its generator seed.
## Pure functions of the date, so every player (and tools/build_daily.gd) gets the same answer.
##
## Dates are UTC (one world-wide day), so everyone plays the same puzzle on the same day.
## The puzzles themselves are pre-built into res://puzzles/daily.json, so later changes to the
## generator can never change a day's puzzle. Dates outside the file fall back to generating from
## the same seed.

## First day the daily calendar lets players go back to. Set this to the game's release date.
const FIRST_DATE := "2026-01-01"
## Every daily is a hard puzzle (the UI doesn't label it "Hard").
const DIFFICULTY := "hard"


static func today() -> String:
	return Time.get_date_string_from_system(true)   # UTC


static func date_unix(date: String) -> int:
	return Time.get_unix_time_from_datetime_string(date + "T12:00:00")


static func day_index(date: String) -> int:
	return int(floor(float(date_unix(date) - date_unix(FIRST_DATE)) / 86400.0))


static func weekday(date: String) -> int:
	# Time's weekday: 0 = Sunday … 6 = Saturday → 0 = Monday
	var wd: int = Time.get_datetime_dict_from_unix_time(date_unix(date)).weekday
	return (wd + 6) % 7


## Every variant once per cycle of Variants.standard().size() days (the 9x9 variants), in a shuffled order per cycle;
## never the same variant two days in a row across cycles.
static func variant(date: String) -> String:
	var n: int = Variants.standard().size()
	var idx := day_index(date)
	var cycle := int(floor(float(idx) / n))
	var order := _cycle_order(cycle)
	return order[idx - cycle * n]


static func _cycle_order(cycle: int) -> Array:
	var order: Array = Variants.standard()
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash("sudokuvariants-daily-cycle-%d" % cycle))
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = order[i]; order[i] = order[j]; order[j] = t
	if cycle > 0 and order[0] == _cycle_order(cycle - 1)[-1]:
		var t = order[0]; order[0] = order[1]; order[1] = t
	return order


static func info(date: String) -> Dictionary:
	return {
		"date": date,
		"variant": variant(date),
		"difficulty": DIFFICULTY,
		"seed": absi(hash("sudokuvariants-daily-" + date)),
	}
