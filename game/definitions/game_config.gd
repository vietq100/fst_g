class_name GameConfig
extends Resource
## Global formula and rule constants. Values come from data/config/game_config.tres (BALANCE.md).

@export_group("Combat")
## damage = max(min_damage, attack - defense * defense_factor)
@export var defense_factor: float = 0.5
@export var min_damage: float = 1.0
## Seconds between retarget checks (DECISIONS.md D19).
@export var retarget_interval: float = 0.5

@export_group("Progression")
## required_xp = base_xp * pow(level, xp_exponent)
@export var base_xp: float = 20.0
@export var xp_exponent: float = 1.5
## Hunter max level = Town Hall level × this (DECISIONS.md D12).
@export var level_cap_per_town_level: int = 10
## Fraction of max HP restored on level-up.
@export_range(0.0, 1.0) var level_up_heal_ratio: float = 0.2

@export_group("New game")
## DECISIONS.md D25.
@export var start_gold: int = 200
@export var starting_hunter_class: StringName = &"warrior"
@export var starting_hunter_count: int = 1

@export_group("Hunter life")
## Mood 0..mood_max (HUNTER_LIFE_SYSTEM.md §2, BALANCE.md → Mood).
@export var mood_start: float = 60.0
@export var mood_max: float = 100.0
@export var mood_high_threshold: float = 70.0
@export var mood_low_threshold: float = 30.0
## Percent modifiers on attack/defense and XP gain for High / Low mood.
@export var mood_high_stat_bonus: float = 0.05
@export var mood_low_stat_penalty: float = -0.10
@export var mood_high_xp_bonus: float = 0.10
@export var mood_low_xp_penalty: float = -0.10
## Mood events.
@export var mood_success: float = 10.0
@export var mood_failure: float = -15.0
@export var mood_injured: float = -10.0
@export var mood_trait_like: float = 5.0
@export var mood_trait_dislike: float = -5.0
@export var mood_overwork: float = -5.0
## Expeditions in a row without resting: overwork penalty from this many on.
@export var overwork_expeditions: int = 3
## Trait event thresholds (DECISIONS.md D26).
@export var back_to_back_expeditions: int = 2
@export var idle_cycles_for_event: int = 2
@export var long_rest_ticks: int = 3
## Activity like/dislike events fire once per this many ticks of the activity.
@export var activity_event_every_ticks: int = 6
## Default activity: rest while HP is not full or mood is below this, otherwise train.
@export var rest_when_mood_below: float = 50.0
## Traits per recruit.
@export var traits_min: int = 1
@export var traits_max: int = 2
## Bonds 0..bond_max; bonded at bond_max.
@export var bond_max: float = 100.0
@export var bond_shared_expedition: float = 20.0
@export var bonded_attack_bonus: float = 0.05
@export var bonded_social_mood: float = 2.0
## Real seconds per in-game day (Hunter history dates).
@export var day_length_seconds: float = 300.0

@export_group("Offline")
## Max real time applied to town timers after the app was closed (DECISIONS.md D24).
@export var offline_cap_hours: float = 8.0

@export_group("Expedition")
@export var max_party_size: int = 3
## Share of stash gold/materials kept on failure (DECISIONS.md D4).
@export_range(0.0, 1.0) var failure_loot_keep_ratio: float = 0.5
