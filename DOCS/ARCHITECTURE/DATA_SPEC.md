# DATA SPEC

All definitions are Resources loaded by `DataRegistry`. Values: `BALANCE.md`.

## Modifier (shared format)

- stat
- type: `flat` | `percent`
- value

Final stat = `(base + level_growth * (level - 1) + Σflat) * (1 + Σpercent)`.

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
- portrait
- sprite
- recruit_cost

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
- tick_seconds
- effects (hp_percent, mood, xp, bond per tick)

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
- xp_reward
- gold_min
- gold_max
- loot_table_id

## LootTableDefinition

- id
- entries (item_id, quantity_min, quantity_max, chance)

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

## RecipeDefinition

- id
- result_item_id
- gold_cost
- material_costs (item_id, quantity)
- required_blacksmith_level

## BuildingDefinition

- id
- display_name
- max_level (data only; can grow over time)
- levels (per level: costs, requirements, effects, visual variant)

## ExpeditionDefinition

- id
- display_name
- recommended_level
- enemy_groups (list of sections, each a list of enemy_id + count)
- boss_id
- completion_bonus_gold
- first_clear_rewards
- repeat_clear_rewards
- unlock_requirement
