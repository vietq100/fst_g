# AUDIO DESIGN

## Music

Town:
- calm fantasy
- warm
- relaxed

Wilderness:
- mysterious
- slightly tense

Boss:
- stronger rhythm
- danger

## SFX

Required MVP:
- button click
- sword hit
- enemy hit
- enemy death
- loot pickup
- level up
- building upgrade
- expedition start
- expedition complete

## Audio rules

Do not make every action loud.

Important events should have stronger feedback.

## Implementation (D78)

No recorded audio files: every sound is synthesized from data, chiptune style, so it needs no asset import and stays small.

- **Data**: `data/audio/sfx.json` (sound effects: layers of square / triangle / saw / sine / noise voices with pitch sweeps, arpeggios, vibrato, envelopes and low-pass filters; volume and minimum replay interval per sound) and `data/audio/music.json` (tracks: tempo, bars of 16 steps per channel written like a tracker, a drum kit).
- **Synth**: `SoundSynth` renders a sound or a looping track into an `AudioStreamWAV` (16-bit mono, 22 050 Hz). Effects render on first use and are cached; music renders on a background thread.
- **Preview**: `python3 tools/audio/preview_audio.py` renders the same data with the same algorithm to WAV files in `build/audio_preview/`, to listen without Godot.
- **Player** (`Audio` autoload): buses Music and SFX; volumes saved in `user://settings.cfg` (Settings sheet sliders); a pool of players; each sound keeps its minimum interval (hits and clicks never pile up); world sounds play only near the screen and get quieter towards its edge, with a slight pitch variation.

### Music
| Track | When | Feel |
|---|---|---|
| town | camera over the Town by day | C major, 84 BPM, warm arpeggios, light drums |
| night | camera over the Town at night | A minor, 66 BPM, soft pad and bells, no drums |
| wild | hunting regions, dungeon runs | D minor, 100 BPM, pulsing bass, tense ostinato |
| boss | boss arena, a weekly boss fight | E minor, 140 BPM, driving bass and drums |

### Sound effects
| Sound | Event | Loudness |
|---|---|---|
| click / error | any button / an error toast | soft |
| hit / crit / dodge | damage dealt (critical) / attack dodged, near the screen | soft |
| enemy_death / hunter_fall | a monster / a Hunter falls | medium |
| loot / coins | loot picked up / a bag sold | soft |
| level_up, recruit, craft, build, upgrade | Hunter levels up, recruited, item crafted, building placed / upgraded | medium |
| expedition_start / expedition_complete / victory | dungeon run starts / ends / weekly boss defeated | strong |
| skill_<element>, heal | class or monster skill in its element / a heal | medium |
