extends Node
## Background a cappella music and Arabic frame drum (daf/bendir) sound effects.
## Music: every track in res://audio/music/ (ogg/mp3/wav), shuffled, with fades between tracks.
## Effects: synthesised at startup, so they need no audio files.
##   correct → open "tek" stroke with the daf's jingle rings
##   wrong   → dead, muffled double "dum" (palm-damped skin)
##   solved  → short dum-tek rhythm flourish

const MUSIC_DIR := "res://audio/music/"
const RATE := 44100
const FADE := 2.5
const GAP := 4.0

var _music: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_i := 0
var _tracks: Array[String] = []
var _queue: Array[String] = []
var _tween: Tween
var _sounds := {}  # name -> Array[AudioStreamWAV] (variations)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.finished.connect(_on_track_finished)
	add_child(_music)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx.append(p)
	_build_sounds()
	_find_tracks()
	GameState.settings_changed.connect(apply_settings)
	apply_settings.call_deferred()


## Runs whenever settings change.
func apply_settings() -> void:
	var s: Dictionary = GameState.settings
	var music_on: bool = s.get("music_on", true) and not _tracks.is_empty()
	var vol := _db(float(s.get("music_volume", 0.5)))
	if not music_on:
		if _music.playing:
			_fade_to(-60.0, 0.6, true)
		return
	if not _music.playing:
		_play_next()
	else:
		if _tween: _tween.kill()
		_music.volume_db = vol


func toggle_music() -> void:
	GameState.settings.music_on = not bool(GameState.settings.get("music_on", true))
	GameState.save_settings()


func music_on() -> bool:
	return bool(GameState.settings.get("music_on", true))


func has_music() -> bool:
	return not _tracks.is_empty()


func play(sound: String) -> void:
	var s: Dictionary = GameState.settings
	if not s.get("sfx_on", true) or not _sounds.has(sound):
		return
	var vars: Array = _sounds[sound]
	var p := _sfx[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx.size()
	p.stream = vars[randi() % vars.size()]
	p.volume_db = _db(float(s.get("sfx_volume", 0.7)))
	p.pitch_scale = randf_range(0.98, 1.02)
	p.play()


func _db(v: float) -> float:
	return -60.0 if v <= 0.001 else linear_to_db(v)


# ------------------------------------------------------------------ music

func _find_tracks() -> void:
	if not DirAccess.dir_exists_absolute(MUSIC_DIR):
		return
	for f in ResourceLoader.list_directory(MUSIC_DIR):
		if f.get_extension().to_lower() in ["ogg", "mp3", "wav"]:
			_tracks.append(MUSIC_DIR + f)


func _play_next() -> void:
	if _tracks.is_empty():
		return
	if _queue.is_empty():
		_queue = _tracks.duplicate()
		_queue.shuffle()
	var path: String = _queue.pop_back()
	var stream: AudioStream = load(path)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = false
	_music.stream = stream
	_music.volume_db = -60.0
	_music.play()
	_fade_to(_db(float(GameState.settings.get("music_volume", 0.5))), FADE, false)


func _fade_to(db: float, t: float, stop_after: bool) -> void:
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(_music, "volume_db", db, t)
	if stop_after:
		_tween.tween_callback(_music.stop)


func _on_track_finished() -> void:
	if not music_on():
		return
	await get_tree().create_timer(GAP).timeout
	if music_on() and not _music.playing:
		_play_next()


# ------------------------------------------------------------------ frame drum synthesis

func _build_sounds() -> void:
	_sounds.correct = [_tek(1.0, 0), _tek(1.04, 1), _tek(0.97, 2)]
	_sounds.wrong = [_dead_dum(0)]
	var flourish := PackedFloat32Array()
	flourish.resize(int(RATE * 1.6))
	# dum . tek tek dum . tek-a-tek  (a common maqsum-like figure)
	var hits := [[0.0, "dum"], [0.24, "tek"], [0.36, "tek"], [0.48, "dum"], [0.84, "tek"], [0.92, "tek"], [1.0, "tek"]]
	var i := 0
	for h in hits:
		var buf := _dum_buf(1.0, i) if h[1] == "dum" else _tek_buf(1.0 + 0.03 * (i % 3), i)
		_mix(flourish, buf, int(float(h[0]) * RATE), 0.9)
		i += 1
	_sounds.solved = [_wav(flourish)]
	# chat message: a quick high "tek-tek" on the rim
	var ping := PackedFloat32Array()
	ping.resize(int(RATE * 0.6))
	_mix(ping, _tek_buf(1.32, 7), 0, 0.75)
	_mix(ping, _tek_buf(1.5, 8), int(0.11 * RATE), 0.65)
	_sounds.chat = [_wav(ping)]


## Bright rim stroke ("tek"): short skin ping + noise slap + jingle rings.
func _tek_buf(pitch: float, seed_: int) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + seed_
	var n := int(RATE * 0.45)
	var out := PackedFloat32Array()
	out.resize(n)
	var f0 := 330.0 * pitch
	var modes := [[1.0, 1.0], [1.59, 0.55], [2.14, 0.35], [2.65, 0.2]]
	var bp := _BandPass.new(3200.0 * pitch, 1.2)
	var jingles: Array = []
	for k in 7:
		jingles.append([rng.randf_range(3500.0, 9500.0), rng.randf() * TAU, rng.randf_range(0.5, 1.0)])
	for i in n:
		var t := float(i) / RATE
		var skin := 0.0
		for m in modes:
			skin += sin(TAU * f0 * float(m[0]) * t) * float(m[1])
		skin *= exp(-t * 38.0) * 0.45
		var slap := bp.process(rng.randf_range(-1.0, 1.0)) * exp(-t * 90.0) * 0.9
		var jing := 0.0
		for j in jingles:
			jing += sin(TAU * float(j[0]) * t + float(j[1])) * float(j[2])
		# jingle rings shimmer: noisy, slightly delayed, longer tail
		var shimmer := (jing / 7.0) * (0.6 + 0.4 * rng.randf()) * exp(-t * 11.0) * minf(1.0, t * 300.0) * 0.28
		out[i] = skin + slap + shimmer
	return out


## Deep centre stroke ("dum"): low skin tone with a downward pitch glide.
func _dum_buf(pitch: float, seed_: int) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2000 + seed_
	var n := int(RATE * 0.7)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var phase2 := 0.0
	var lp := _LowPass.new(900.0)
	for i in n:
		var t := float(i) / RATE
		var f := 92.0 * pitch * (1.0 + 0.35 * exp(-t * 30.0))
		phase += TAU * f / RATE
		phase2 += TAU * f * 1.59 / RATE
		var body := (sin(phase) + 0.3 * sin(phase2) * exp(-t * 12.0)) * exp(-t * 6.5)
		var thump := lp.process(rng.randf_range(-1.0, 1.0)) * exp(-t * 60.0) * 0.8
		out[i] = (body + thump) * 0.75
	return out


## Wrong input: two quick palm-muted strokes, low and dull, the second one lower.
func _dead_dum(seed_: int) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	out.resize(int(RATE * 0.42))
	for k in 2:
		var rng := RandomNumberGenerator.new()
		rng.seed = 3000 + seed_ + k
		var start := int(RATE * 0.13 * k)
		var lp := _LowPass.new(500.0)
		var phase := 0.0
		var pitch := 1.0 if k == 0 else 0.84
		for i in int(RATE * 0.25):
			var t := float(i) / RATE
			var f := 118.0 * pitch * (1.0 + 0.15 * exp(-t * 40.0))
			phase += TAU * f / RATE
			var body := (sin(phase) + 0.45 * sin(phase * 1.41)) * exp(-t * 26.0)  # damped: dies fast
			var slap := lp.process(rng.randf_range(-1.0, 1.0)) * exp(-t * 70.0)
			if start + i < out.size():
				out[start + i] += (body * 0.8 + slap * 0.9) * 0.8
	return _wav(out)


func _tek(pitch: float, seed_: int) -> AudioStreamWAV:
	return _wav(_tek_buf(pitch, seed_))


func _mix(dst: PackedFloat32Array, src: PackedFloat32Array, at: int, gain: float) -> void:
	for i in src.size():
		if at + i >= dst.size(): break
		dst[at + i] += src[i] * gain


func _wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var peak := 0.0001
	for v in buf: peak = maxf(peak, absf(v))
	var g := 0.85 / peak
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		var fade := minf(1.0, float(buf.size() - i) / 400.0)  # avoid a click at the end
		data.encode_s16(i * 2, int(clampf(buf[i] * g * fade, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


class _LowPass:
	var a := 0.0
	var y := 0.0
	func _init(cutoff: float) -> void:
		a = 1.0 - exp(-TAU * cutoff / 44100.0)
	func process(x: float) -> float:
		y += a * (x - y)
		return y


class _BandPass:
	## RBJ biquad band-pass (constant skirt gain).
	var b0 := 0.0
	var b2 := 0.0
	var a1 := 0.0
	var a2 := 0.0
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	func _init(f: float, q: float) -> void:
		var w := TAU * f / 44100.0
		var alpha := sin(w) / (2.0 * q)
		var a0 := 1.0 + alpha
		b0 = alpha / a0; b2 = -alpha / a0
		a1 = -2.0 * cos(w) / a0; a2 = (1.0 - alpha) / a0
	func process(x: float) -> float:
		var y := b0 * x + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1; x1 = x; y2 = y1; y1 = y
		return y
