extends TestCase
## Synthesized audio (D78): data/audio/*.json is well formed, SoundSynth renders it, Audio plays it.

const SFX := "res://data/audio/sfx.json"
const MUSIC := "res://data/audio/music.json"


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())


func test_every_sound_renders() -> void:
	var sfx := _json(SFX)
	for id: String in sfx:
		if id.begins_with("_"):
			continue
		var recipe: Dictionary = sfx[id]
		assert_true(recipe.has("volume_db") and recipe.has("cooldown"), id)
		var stream := SoundSynth.sfx_stream(recipe)
		var seconds := stream.data.size() / 2.0 / SoundSynth.RATE
		assert_true(seconds > 0.02 and seconds < 1.5, "%s lasts %.2f s" % [id, seconds])
		assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_DISABLED, id)


func test_music_data_is_well_formed() -> void:
	var music := _json(MUSIC)
	for id in ["town", "night", "wild", "boss"]:
		assert_true(music.has(id), "track " + id)
	for id: String in music:
		if id.begins_with("_"):
			continue
		var track: Dictionary = music[id]
		var bars := -1
		for channel: Dictionary in track["channels"]:
			var channel_bars: Array = channel["bars"]
			assert_true(bars < 0 or channel_bars.size() == bars, "%s %s bars" % [id, channel["name"]])
			bars = channel_bars.size()
			for bar: String in channel_bars:
				var tokens := bar.split(" ", false)
				assert_eq(tokens.size(), SoundSynth.STEPS_PER_BAR, "%s %s: %s" % [id, channel["name"], bar])
				for token in tokens:
					if token == "-" or token == ".":
						continue
					if channel.get("drums", false):
						assert_true((track["kit"] as Dictionary).has(token), "%s drum %s" % [id, token])
					else:
						var midi := SoundSynth.midi_of(token)
						assert_true(midi >= 20 and midi <= 100, "%s note %s" % [id, token])


func test_notes_and_a_short_loop() -> void:
	assert_eq(SoundSynth.midi_of("A4"), 69)
	assert_eq(SoundSynth.midi_of("C4"), 60)
	assert_eq(SoundSynth.midi_of("F#3"), 54)
	assert_eq(SoundSynth.midi_of("Bb1"), 34)
	var track := {"bpm": 120, "kit": {"k": {"wave": "sine", "dur": 0.1, "freq": 100, "freq_end": 40, "vol": 0.8}},
		"channels": [
			{"name": "lead", "wave": "square", "vol": 0.3, "bars": ["C4 - - - E4 - - - G4 - - - . . . ."]},
			{"name": "drums", "drums": true, "vol": 0.3, "bars": ["k . . . k . . . k . . . k . . ."]},
		]}
	var samples := SoundSynth.render_track(track)
	# One bar of 16 sixteenths at 120 BPM = 2 s.
	assert_eq(samples.size(), roundi(2.0 * SoundSynth.RATE))
	var stream := SoundSynth.to_stream(samples, SoundSynth.MUSIC_PEAK, true)
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(stream.loop_end, samples.size())
	var loudest := 0
	for i in range(0, stream.data.size(), 2):
		loudest = maxi(loudest, absi(stream.data.decode_s16(i)))
	assert_true(loudest > 20000 and loudest <= 32767, "normalised, not clipped: %d" % loudest)


func test_audio_plays_known_sounds_once_per_cooldown() -> void:
	assert_true(Audio.has_sound(&"click"))
	assert_false(Audio.play(&"no_such_sound"))
	assert_true(Audio.play(&"level_up"), "plays")
	assert_false(Audio.play(&"level_up"), "not again within its cooldown")
	var saved := Audio.get_volume(Audio.SFX_BUS)
	Audio.set_volume(Audio.SFX_BUS, 0.5)
	assert_almost_eq(Audio.get_volume(Audio.SFX_BUS), 0.5, 0.001)
	Audio.set_volume(Audio.SFX_BUS, saved)
