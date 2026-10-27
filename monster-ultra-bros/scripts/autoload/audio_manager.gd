extends Node
## Music (with cross-fade) and pooled sound effects.

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const SFX_VOICES := 14

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current: AudioStreamPlayer
var _current_name := ""
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _sfx_cache: Dictionary = {}
var _last_played: Dictionary = {}   # sfx name -> msec, avoids stacking identical sounds
var _fade_tween: Tween
var _duck := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_a = _make_player("Music")
	_music_b = _make_player("Music")
	_current = _music_a
	for i in SFX_VOICES:
		_voices.append(_make_player("SFX"))


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func current_music() -> String:
	return _current_name


func play_music(track: String, fade := 0.6, restart := false) -> void:
	if track == _current_name and _current.playing and not restart:
		return
	var path := MUSIC_DIR + track + ".wav"
	if not ResourceLoader.exists(path):
		push_warning("Missing music: " + path)
		return
	var stream: AudioStream = load(path)
	var old := _current
	var nxt := _music_b if _current == _music_a else _music_a
	nxt.stream = stream
	nxt.volume_db = -40.0
	nxt.pitch_scale = 1.0
	nxt.play()
	_current = nxt
	_current_name = track
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(nxt, "volume_db", linear_to_db(_duck), fade)
	if old.playing:
		_fade_tween.tween_property(old, "volume_db", -40.0, fade)
		_fade_tween.chain().tween_callback(old.stop)


func stop_music(fade := 0.5) -> void:
	_current_name = ""
	if _fade_tween:
		_fade_tween.kill()
	var p := _current
	if not p.playing:
		return
	_fade_tween = create_tween()
	_fade_tween.tween_property(p, "volume_db", -40.0, fade)
	_fade_tween.tween_callback(p.stop)


func set_music_pitch(pitch: float) -> void:
	_current.pitch_scale = pitch


## Lowers the music (e.g. while paused). 1.0 = normal.
func duck_music(amount: float) -> void:
	_duck = amount
	if _current.playing:
		_current.volume_db = linear_to_db(max(amount, 0.01))


func play_sfx(sfx_name: String, pitch_jitter := 0.0, volume_db := 0.0) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sfx_name, -1000)) < 35:
		return
	_last_played[sfx_name] = now
	var stream: AudioStream = _sfx_cache.get(sfx_name)
	if stream == null:
		var path := SFX_DIR + sfx_name + ".wav"
		if not ResourceLoader.exists(path):
			push_warning("Missing sfx: " + path)
			return
		stream = load(path)
		_sfx_cache[sfx_name] = stream
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = 1.0 + (randf_range(-pitch_jitter, pitch_jitter) if pitch_jitter > 0.0 else 0.0)
	voice.play()


func preload_sfx(names: Array) -> void:
	for n in names:
		var path: String = SFX_DIR + str(n) + ".wav"
		if ResourceLoader.exists(path) and not _sfx_cache.has(n):
			_sfx_cache[n] = load(path)
