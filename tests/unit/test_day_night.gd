extends TestCase
## DayNight (D77): the hour's tint and how dark the night is.


func test_day_is_clear_and_night_is_blue_and_lit() -> void:
	assert_eq(DayNight.tint_at(0.3), Color.WHITE, "noon")
	assert_almost_eq(DayNight.night_of(DayNight.tint_at(0.3)), 0.0, 0.001, "no lights by day")
	var night := DayNight.tint_at(0.8)
	assert_true(night.b > night.r and night.get_luminance() < 0.6, "blue night")
	assert_almost_eq(DayNight.night_of(night), 1.0, 0.001, "lights on at night")
	var dusk := DayNight.tint_at(0.62)
	assert_true(dusk.r > dusk.b, "warm dusk")
	# The cycle wraps from the late night back to dawn without a jump.
	assert_true(DayNight.tint_at(0.999).is_equal_approx(DayNight.tint_at(0.0)) or DayNight.tint_at(0.999).get_luminance() < DayNight.tint_at(0.0).get_luminance() + 0.05)


func test_shadows_follow_the_sun() -> void:
	var dawn := DayNight.shadow_of(0.02)
	var noon := DayNight.shadow_of(0.34)
	var dusk := DayNight.shadow_of(0.62)
	var night := DayNight.shadow_of(0.8)
	assert_true(dawn["shift"] < -0.5 and dusk["shift"] > 0.5, "shadows lean away from the sun")
	assert_almost_eq(noon["shift"], 0.0, 0.05, "no lean at noon")
	assert_true(dawn["stretch"] > noon["stretch"], "long at dawn, short at noon")
	assert_almost_eq(night["strength"], 0.5, 0.001, "faint at night")
	assert_almost_eq(night["shift"], 0.0, 0.001, "no sun at night")
