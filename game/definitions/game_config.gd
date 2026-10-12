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
@export var base_xp: float = 30.0
@export var xp_exponent: float = 2.2
## Hunter max level = Town Hall level × this (DECISIONS.md D12).
@export var level_cap_per_town_level: int = 10
## Fraction of max HP restored on level-up.
@export_range(0.0, 1.0) var level_up_heal_ratio: float = 0.2

@export_group("New game")
## DECISIONS.md D25.
@export var start_gold: int = 200
## Food in the Warehouse of a new village (D40): item id -> portions.
@export var starting_food: Dictionary[StringName, int] = {&"meat_stew": 6}
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

@export_group("Needs")
## Stamina / energy 0..needs_max, changed once per activity tick (BALANCE.md → Needs, D31).
@export var needs_max: float = 100.0
@export var stamina_drain_active: float = 1.5
@export var stamina_sleep_bed: float = 6.0
@export var stamina_sleep_outdoors: float = 3.0
@export var outdoors_sleep_mood: float = -1.0
@export var energy_drain: float = 0.6
@export var energy_drain_sleeping: float = 0.3
## Energy at 0: this share of max HP lost per tick (never below 1 HP) and this mood change.
@export var starving_hp_ratio: float = 0.02
@export var starving_mood: float = -1.0
## Brain thresholds: sleep below / wake at; eat below.
@export var sleep_below_stamina: float = 25.0
@export var wake_at_stamina: float = 95.0
@export var eat_below_energy: float = 35.0
## Stamina 0: percent modifiers on move / attack speed.
@export var exhausted_move_speed: float = -0.4
@export var exhausted_attack_speed: float = -0.3

@export_group("Regions")
## Region monsters (BALANCE.md → Regions, D29): level L scales stats by 1 + per_level × (L − 1).
@export var monster_stat_per_level: float = 0.12
@export var monster_reward_per_level: float = 0.10
## Monsters notice Hunters this close and give up past this distance from their spawn point.
@export var monster_aggro_range: float = 90.0
@export var monster_leash_range: float = 220.0
## Hunters engage monsters this close while hunting.
@export var hunter_engage_range: float = 150.0
## Items a Hunter carries before walking home to the Warehouse.
@export var loot_bag_capacity: int = 10
## Go home to rest below this share of max HP, leave again from this share.
@export var rest_below_hp_ratio: float = 0.35
@export var rest_until_hp_ratio: float = 0.9

@export_group("Bodies")
## D30: a carrier drags a body at this share of its speed; carriers need this much stamina;
## revived Hunters start with this share of HP, stamina and energy.
@export var carry_speed_ratio: float = 0.7
@export var carrier_min_stamina: float = 25.0
@export_range(0.0, 1.0) var revive_ratio: float = 0.5
## Nobody able to carry a body for this long (everyone fell): the town brings it to the Hospital.
@export var body_rescue_seconds: float = 120.0
## D42: share of the XP needed for the current level lost on revival.
@export_range(0.0, 1.0) var revive_xp_loss_ratio: float = 0.1
## D43: village staff that carry bodies, their speed and the fee per trip.
@export var staff_count: int = 2
@export var staff_move_speed: float = 70.0
@export var staff_fee: int = 15

@export_group("Talents")
## D46: chance weight of recruiting a Hunter without a talent.
@export var talent_none_weight: float = 0.3

@export_group("Money")
## D34: purse of a new Hunter; share of a treasury ↔ purse transfer lost as fee.
@export var purse_start: int = 20
@export_range(0.0, 1.0) var transfer_fee: float = 0.1

@export_group("Offline")
## Max real time applied to town timers after the app was closed (DECISIONS.md D24).
@export var offline_cap_hours: float = 8.0
## Share of Training XP gained while the app is closed (D44).
@export_range(0.0, 1.0) var offline_training_ratio: float = 0.25

@export_group("Expedition")
@export var max_party_size: int = 3
## Share of stash gold/materials kept on failure (DECISIONS.md D4).
@export_range(0.0, 1.0) var failure_loot_keep_ratio: float = 0.5

@export_group("Reincarnation")
## Hunter level needed to reincarnate at the Portal.
@export var reincarnate_level: int = 20
## Permanent bonus per reincarnation to max HP / attack / defense.
@export var reincarnation_stat_bonus: float = 0.06
## Total reincarnations needed to unlock each difficulty (index = difficulty).
@export var difficulty_unlocks: Array[int] = [0, 1, 3, 6]
@export var difficulty_names: PackedStringArray = ["Easy", "Normal", "Hard", "Nightmare"]
## Monster stat and reward multipliers per difficulty.
@export var difficulty_stat_scale: Array[float] = [1.0, 1.4, 2.0, 3.0]
@export var difficulty_reward_scale: Array[float] = [1.0, 1.5, 2.2, 3.5]

@export_group("Enhancement")
## Gold = enhance_gold_base × (level + 1) ^ 1.5; stat modifiers grow by this much per level.
@export var enhance_gold_base: int = 40
@export var enhance_stat_bonus: float = 0.12
@export var enhance_ore_per_level: int = 2

@export_group("Trading Post")
## Bounty paid to the Hunter on top of the village price, as a share of the price.
@export var bounty_ratio: float = 0.5
