extends Node
class_name Sfx

# Small synthesized sound effects, so the project needs no external audio assets.

const RATE := 22050

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	_sounds["flap"] = _make(0.12, func(_t: float, p: float) -> float: return randf_range(-1.0, 1.0) * (1.0 - p) * 0.35 * sin(p * PI))
	_sounds["fold"] = _make(0.08, func(t: float, p: float) -> float: return signf(sin(TAU * lerpf(900.0, 500.0, p) * t)) * (1.0 - p) * 0.18)
	_sounds["stamp"] = _make(0.25, func(t: float, p: float) -> float: return sin(TAU * (880.0 if p < 0.4 else 1320.0) * t) * (1.0 - p) * 0.35)
	_sounds["gust"] = _make(0.35, func(_t: float, p: float) -> float: return randf_range(-1.0, 1.0) * sin(p * PI) * 0.18)
	_sounds["crash"] = _make(0.45, func(t: float, p: float) -> float: return (randf_range(-1.0, 1.0) * 0.6 + sin(TAU * lerpf(220.0, 60.0, p) * t) * 0.4) * pow(1.0 - p, 2.0) * 0.5)
	_sounds["win"] = _make(0.6, _win_wave)
	for i in 6:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)

func play(sound: String) -> void:
	for player in _players:
		if not player.playing:
			player.stream = _sounds[sound]
			player.play()
			return

func _win_wave(t: float, p: float) -> float:
	# Rising four-note arpeggio.
	var notes := [523.25, 659.25, 783.99, 1046.5]
	return sin(TAU * notes[mini(3, int(p * 4.0))] * t) * (1.0 - fmod(p * 4.0, 1.0) * 0.6) * 0.3

func _make(duration: float, wave: Callable) -> AudioStreamWAV:
	var samples := int(duration * RATE)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var value := clampf(wave.call(float(i) / RATE, float(i) / samples), -1.0, 1.0)
		data.encode_s16(i * 2, int(value * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream
