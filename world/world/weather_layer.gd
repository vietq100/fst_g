class_name WeatherLayer
extends Node2D
## Dynamic weather system over the settlement world map (CLEAR, RAIN, MIST).
## Provides subtle pixel-art environmental atmosphere and light gameplay bonuses:
## - Rain: +10% mana regen
## - Mist: -15% monster aggro detection radius

signal weather_changed(weather: int)

enum WeatherType { CLEAR = 0, RAIN = 1, MIST = 2 }

const WEATHER_Z := 24
const CYCLE_INTERVAL := 240.0
const DROP_COLOR := Color(0.65, 0.8, 1.0, 0.4)
const MIST_COLOR := Color(0.85, 0.9, 1.0, 0.12)
const DROP_COUNT := 90
const MIST_BANDS := 6

var current_weather: int = WeatherType.CLEAR
var _timer: float = CYCLE_INTERVAL
var _drops: Array[Vector2] = []
var _mist_offsets: Array[float] = []
var _rng: RandomNumberGenerator
var _viewport_size := Vector2(400, 800)


func _ready() -> void:
	z_index = WEATHER_Z
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_timer = _rng.randf_range(CYCLE_INTERVAL * 0.5, CYCLE_INTERVAL)

	for i in DROP_COUNT:
		_drops.append(Vector2(_rng.randf_range(-100, 600), _rng.randf_range(-100, 1000)))
	for i in MIST_BANDS:
		_mist_offsets.append(_rng.randf_range(0, 1000))


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = CYCLE_INTERVAL
		_roll_weather()

	match current_weather:
		WeatherType.RAIN:
			for i in _drops.size():
				_drops[i].y += 380.0 * delta
				_drops[i].x -= 70.0 * delta
				if _drops[i].y > 900.0:
					_drops[i].y = -20.0
					_drops[i].x = _rng.randf_range(-50, 550)
			queue_redraw()
		WeatherType.MIST:
			for i in _mist_offsets.size():
				_mist_offsets[i] += (20.0 + i * 5.0) * delta
				if _mist_offsets[i] > 1200.0:
					_mist_offsets[i] = -200.0
			queue_redraw()
		WeatherType.CLEAR:
			pass


func _roll_weather() -> void:
	var roll := _rng.randf()
	var next_weather: int
	if roll < 0.60:
		next_weather = WeatherType.CLEAR
	elif roll < 0.85:
		next_weather = WeatherType.RAIN
	else:
		next_weather = WeatherType.MIST

	if next_weather != current_weather:
		current_weather = next_weather
		weather_changed.emit(current_weather)
		queue_redraw()


func _draw() -> void:
	var canvas := get_viewport_rect()
	if GameManager.town_events != null and GameManager.town_events.is_blood_moon():
		draw_rect(canvas, Color(0.9, 0.1, 0.1, 0.22))
	match current_weather:
		WeatherType.RAIN:
			for drop in _drops:
				draw_line(drop, drop + Vector2(-3, 8), DROP_COLOR, 1.2)
		WeatherType.MIST:
			for i in MIST_BANDS:
				var y := 100.0 + i * 130.0
				var x := _mist_offsets[i] - 200.0
				var rect := Rect2(x, y, 350.0, 60.0)
				draw_rect(rect, MIST_COLOR)
		WeatherType.CLEAR:
			pass


func get_mana_regen_bonus() -> float:
	return 0.10 if current_weather == WeatherType.RAIN else 0.0


func get_aggro_modifier() -> float:
	return 0.85 if current_weather == WeatherType.MIST else 1.0
