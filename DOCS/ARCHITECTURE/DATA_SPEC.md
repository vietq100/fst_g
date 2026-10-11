# DATA SPEC

All definitions are Resources loaded by `DataRegistry`. Values: `BALANCE.md`.

Code: classes in `res://game/definitions/`, data in `res://data/<category>/*.tres`. Every definition extends `GameDefinition` (`id`, `display_name`).

## GameConfig (`res://data/config/game_config.tres`)

Formula and rule constants: defense_factor, min_damage, retarget_interval, base_xp, xp_exponent, level_cap_per_town_level, level_up_heal_ratio, start_gold, starting_hunter_class, starting_hunter_count, mood values (start, max, thresholds, state modifiers, event amounts), overwork / trait event thresholds, traits_min/max, bond values, day_length_seconds, offline_cap_hours, max_party_size, failure_loot_keep_ratio.

Building effect keys used by code: `hunter_capacity` (Town Hall), `candidate_count`, `refresh_cost` (Tavern), `recipe_level` (Blacksmith), `recovery_seconds`, `speedup_gold_per_minute` (Hospital), `inventory_slots` (Warehouse).

## StatModifier (shared format)

- stat
- type: `FLAT` | `PERCENT`
- value (PERCENT as fraction, 0.15 = +15%)
- condition (optional tag, e.g. `vs_boss`; empty = always active)

Final stat = `(base + level_growth * (level - 1) + Σflat) * (1 + Σpercent)`.

Helper resources: `ItemAmount` (item_id, quantity), `LootEntry`, `BuildingLevel`, `EnemyGroup`, `EnemySpawn`.

## HunterDefinition (class template)

- id
- display_name (class name)
- class_id
- base_hp
- base_attack
- base_defense
- hp_per_level
- attack_per_level
- defense_per_level
- attack_speed
- move_speed
- critical_chance
- critical_damage
- attack_range (px, feet to feet)
- portrait
- sprite_frames
- recruit_cost
- stat_roll_variance (±fraction applied to recruits)
- name_pool (names for recruits, unused first)
- starting_items (created and equipped on every recruit)

Individual identity (name, appearance, stat rolls, traits) lives in `HunterRuntime`.

## TraitDefinition

- id
- display_name
- description
- modifiers (list of Modifier, may include conditions such as `vs_boss`)
- activity_rate_modifiers (e.g. training ×1.5)
- mood_likes (event tags)
- mood_dislikes (event tags)
- icon

## ActivityDefinition

- id
- display_name
- location_id
- player_assignable
- tick_seconds
- effects per tick: hp_percent, mood, xp, bond

## EnemyDefinition

- id
- display_name
- hp
- attack
- defense
- attack_speed
- move_speed
- critical_chance
- critical_damage
- is_boss
- attack_range (px, feet to feet)
- hit_radius (extra body size added to attackers' reach; big bosses)
- on_hit_effects (StatusEffectChance list: effect, chance, stacks; D48)
- actor_scene (scene with an `Enemy` root, spawned for this definition)
- sprite_frames
- xp_reward
- gold_min
- gold_max
- loot_table_id

## StatusEffectDefinition (D48)

- id, display_name
- kind (BUFF / DEBUFF), duration (s; ≤ 0 = until removed), stacking (REFRESH / STACK / IGNORE), max_stacks, dispellable
- tick_interval, damage_per_tick, heal_per_tick, tick_is_ratio (fraction of max HP)
- stuns, roots, disarms, invulnerable
- modifiers (StatModifier list on attack, defense, attack_speed, move_speed, critical_chance, critical_damage, damage_dealt, damage_taken)
- shield, thorns, lifesteal
- color, icon (glyph), aura, tints_actor (visuals)

Data: `data/status_effects/` (20 effects, see `COMBAT_SYSTEM.md` → Status effects).

## LootTableDefinition

- id
- entries (item_id, quantity_min, quantity_max, chance)

MVP tables: `goblin`, `wolf`, `forest_guardian_first`, `forest_guardian_repeat`. Bosses leave `loot_table_id` empty; their drops come from the expedition's first-clear / repeat tables.

## ItemDefinition

- id
- display_name
- item_type (weapon, armor, accessory, material, consumable)
- rarity (common, uncommon, rare)
- stackable
- max_stack
- sell_price
- equipment_slot
- modifiers (list of Modifier)
- icon
- tint (colour on placeholder characters)
- outfit_id (armor only: Hunter outfit shown while worn, id in `wardrobe.json`; empty = default outfit, D47)

## Hunter body art (D49)

The chibi body is a pixel map in `actors/hunter/chibi/chibi_body.gd` (art, not balance data). The D47 wardrobe (`wardrobe.json`, reference bodies, outfits, hair styles) was removed; `HunterAppearance` and `ItemDefinition.outfit_id` stay in data/saves for the future hair and outfit layers.

## RecipeDefinition

- id
- result_item_id
- gold_cost
- material_costs (item_id, quantity)
- required_blacksmith_level

## BuildingDefinition

- id
- display_name
- levels: Array[BuildingLevel] (index 0 = level 1; max level = size, can grow over time)
  - gold_cost, material_costs, required_flags, effects (key → value), visual_variant

## ExpeditionDefinition

- id
- display_name
- recommended_level
- enemy_groups: Array[EnemyGroup] (section_id + spawns of enemy_id/count), entrance first
- boss_id
- completion_bonus_gold
- first_clear_loot_table_id
- repeat_clear_loot_table_id
- first_clear_flags (e.g. `first_boss_clear`)
- unlock_flag (empty = always available)
- scene
