class_name SoundSynth
extends RefCounted
## Chiptune synthesizer of the game's sounds (AUDIO_DESIGN.md, D78): sound effects (layers of voices) and
## looping music (tracker-like bars) from data/audio/*.json, rendered to 16-bit mono AudioStreamWAV.
## Pure functions, safe to run on a worker thread. tools/audio/preview_audio.py is the same algorithm in
## Python (to listen without Godot): keep them in step.

const RATE := 22050
## Peak level after normalisation (the player sets the loudness of each sound).
const SFX_PEAK := 0.85
const MUSIC_PEAK := 0.8
## Steps per bar in music.json (16th notes).
const STEPS_PER_BAR := 16
const PITCH := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
enum Wave { SQUARE, TRIANGLE, SAW, SINE, NOISE }
const WAVES := {"square": Wave.SQUARE, "triangle": Wave.TRIANGLE, "saw": Wave.SAW, "sine": Wave.SINE, "noise": Wave.NOISE}
const NOISE_MASK := 0x7FFFFFFF


## One sound effect, normalised, ready to play.
static func sfx_stream(recipe: Dictionary) -> AudioStreamWAV:
	return to_stream(render_sfx(recipe), SFX_PEAK, false)


## One music track, centred, normalised and looping.
static func music_stream(track: Dictionary) -> AudioStreamWAV:
	return to_stream(render_track(track), MUSIC_PEAK, true)


static func render_sfx(recipe: Dictionary) -> PackedFloat32Array:
	var length := 0.0
	for layer: Dictionary in recipe["layers"]:
		length = maxf(length, float(layer.get("start", 0.0)) + float(layer["dur"]))
	var buf := PackedFloat32Array()
	buf.resize(int(length * RATE) + 1)
	for layer: Dictionary in recipe["layers"]:
		render_layer(buf, layer)
	return buf


## Adds one sound layer to `buf` from sample `offset`, its volume times `scale`; `wrap` > 0 wraps the
## indices (looping music). Envelope: a linear attack, then a decay to silence at the end (power `curve`).
static func render_layer(buf: PackedFloat32Array, layer: Dictionary, offset := 0, scale := 1.0, wrap := 0) -> void:
	var dur: float = layer["dur"]
	var n := int(dur * RATE)
	if n <= 0:
		return
	var attack: float = layer.get("attack", 0.003)
	var curve: float = layer.get("curve", 2.0)
	var vol: float = float(layer.get("vol", 0.5)) * scale
	var envelope := PackedFloat32Array()
	envelope.resize(n)
	for i in n:
		var t := float(i) / RATE
		var level := t / attack if t < attack else pow(maxf(0.0, 1.0 - (t - attack) / maxf(dur - attack, 0.000001)), curve)
		envelope[i] = level * vol
	var start := offset + int(float(layer.get("start", 0.0)) * RATE)
	var f0: float = layer["freq"]
	_voice(buf, start, wrap, layer, f0, float(layer.get("freq_end", f0)) / f0, envelope)


## Adds a held note of a music channel: attack, decay to the sustain level, then the release tail.
static func render_note(buf: PackedFloat32Array, channel: Dictionary, freq: float, start: int, dur: float) -> void:
	var attack: float = channel.get("attack", 0.01)
	var decay: float = channel.get("decay", 0.1)
	var sustain: float = channel.get("sustain", 0.7)
	var release: float = channel.get("release", 0.1)
	var vol: float = channel.get("vol", 0.3)
	var n := int((dur + release) * RATE)
	var held_end := _held(dur, attack, decay, sustain)
	var envelope := PackedFloat32Array()
	envelope.resize(n)
	for i in n:
		var t := float(i) / RATE
		var level := _held(t, attack, decay, sustain) if t < dur else held_end * maxf(0.0, 1.0 - (t - dur) / release)
		envelope[i] = level * vol
	_voice(buf, start, buf.size(), channel, freq, 1.0, envelope)


static func _held(t: float, attack: float, decay: float, sustain: float) -> float:
	if t < attack:
		return t / attack
	return sustain + (1.0 - sustain) * maxf(0.0, 1.0 - (t - attack) / decay)


## The oscillator: `voice` holds wave, duty, arp + arp_rate, vibrato, lowpass and seed; the pitch sweeps
## exponentially from f0 by `ratio` over the envelope's length.
static func _voice(buf: PackedFloat32Array, start: int, wrap: int, voice: Dictionary, f0: float, ratio: float,
		envelope: PackedFloat32Array) -> void:
	var n := envelope.size()
	var kind: int = WAVES.get(voice.get("wave", "square"), Wave.SQUARE)
	var duty: float = voice.get("duty", 0.5)
	var lowpass: float = voice.get("lowpass", 0.0)
	var alpha := 1.0 - exp(-TAU * lowpass / RATE) if lowpass > 0.0 else 0.0
	var arp: Array = voice.get("arp", [])
	var arp_rate: float = voice.get("arp_rate", 0.0)
	var vibrato: Variant = voice.get("vibrato")
	var vib_rate := 0.0
	var vib_depth := 0.0
	if vibrato is Array:
		vib_rate = vibrato[0]
		vib_depth = vibrato[1]
	var arp_ratios := PackedFloat32Array()
	for semitones in arp:
		arp_ratios.append(pow(2.0, float(semitones) / 12.0))
	var noise_state: int = int(voice.get("seed", 1))
	var noise_value := 0.0
	var noise_cycle := -1
	var phase := 0.0
	var y := 0.0
	var size := buf.size()
	for i in n:
		var t := float(i) / RATE
		var f := f0 if ratio == 1.0 else f0 * pow(ratio, float(i) / n)
		if not arp_ratios.is_empty():
			f *= arp_ratios[int(t * arp_rate) % arp_ratios.size()]
		if vib_depth != 0.0:
			f *= pow(2.0, vib_depth * sin(TAU * vib_rate * t) / 12.0)
		phase += f / RATE
		var p := phase - floorf(phase)
		var x := 0.0
		match kind:
			Wave.SQUARE:
				x = 1.0 if p < duty else -1.0
			Wave.TRIANGLE:
				x = 4.0 * absf(p - 0.5) - 1.0
			Wave.SAW:
				x = 2.0 * p - 1.0
			Wave.SINE:
				x = sin(TAU * phase)
			Wave.NOISE:
				# A new random value each cycle: the pitch sets how fast the noise changes.
				var cycle := floori(phase)
				if cycle != noise_cycle:
					noise_state = (noise_state * 1103515245 + 12345) & NOISE_MASK
					noise_value = float(noise_state) / 2147483647.0 * 2.0 - 1.0
					noise_cycle = cycle
				x = noise_value
		var v := x * envelope[i]
		if alpha > 0.0:
			y += alpha * (v - y)
			v = y
		var index := start + i
		if wrap > 0:
			index %= wrap
		if index >= 0 and index < size:
			buf[index] += v


static func midi_of(token: String) -> int:
	var letter := token[0]
	var accidental := 0
	var octave_at := 1
	if token.length() > 1 and (token[1] == "#" or token[1] == "b"):
		accidental = 1 if token[1] == "#" else -1
		octave_at = 2
	return (int(token.substr(octave_at)) + 1) * 12 + int(PITCH.get(letter, 0)) + accidental


## A looping track: every channel's bars (16 steps each) at the track's tempo; drums use the kit.
static func render_track(track: Dictionary) -> PackedFloat32Array:
	var step := 60.0 / float(track["bpm"]) / 4.0
	var channels: Array = track["channels"]
	var bars: int = (channels[0]["bars"] as Array).size()
	var total := roundi(bars * STEPS_PER_BAR * step * RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var kit: Dictionary = track.get("kit", {})
	for channel: Dictionary in channels:
		var tokens := " ".join(channel["bars"]).split(" ", false)
		for i in tokens.size():
			var token := tokens[i]
			if token == "-" or token == ".":
				continue
			var start := roundi(i * step * RATE)
			if channel.get("drums", false):
				if kit.has(token):
					render_layer(buf, kit[token], start, channel.get("vol", 0.3), total)
				continue
			var hold := 1
			while i + hold < tokens.size() and tokens[i + hold] == "-":
				hold += 1
			var freq := 440.0 * pow(2.0, (midi_of(token) - 69) / 12.0)
			render_note(buf, channel, freq, start, hold * step)
	return buf


## 16-bit mono stream at `peak` (music: centred and looping).
static func to_stream(buf: PackedFloat32Array, peak: float, loop: bool) -> AudioStreamWAV:
	var n := buf.size()
	var mean := 0.0
	if loop and n > 0:
		for v in buf:
			mean += v
		mean /= n
	var top := 0.0
	for v in buf:
		top = maxf(top, absf(v - mean))
	var scale := peak / top if top > 0.0 else 1.0
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf((buf[i] - mean) * scale, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = n
	return stream
