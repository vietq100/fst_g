# CLASS SKILL SYSTEM

Status: **implemented** (D69, D70). Full skill list with numbers: `guide/skills_guide.md` (and the interactive `guide/skills_guide.html`).

## 1. Pools

- Each base class (Warrior, Ranger, Rogue, Guardian) has **30 skills**: 18 active, 12 passive. Data: `data/class_skills/*.tres` (`ClassSkillDefinition`, registry category `class_skill`).
- Promoted classes (Duelist, Slayer, Hawkeye, Sniper, Assassin, Nightblade, Crusader, Templar) use the pool of their base class (`promotion_of`).
- Every skill scales with one main stat (`scale_stat`): attack, defense, max HP, attack speed, move speed, crit chance, crit damage, attack range, Hunter level or gold find.
- Every skill has a 1–3 star rating against monsters, people and bosses (`ratings`, display only).

## 2. Skill points

- A Hunter earns **1 skill point every 10 levels** (10, 20 … 100) of the current life. Recruits start with 0 points and 0 skills (`class_skill_start_count`).
- A point does one of two things:
  - **Learn**: opens a **random** skill of the pool that the Hunter does not own, at level 1. At most **7 skills** per Hunter.
  - **Level up**: one owned skill +1 level, up to **level 6**.
- Unspent points are kept, also through reincarnation.
- `HunterRuntime.skill_point_level` remembers the level up to which points were paid in this life; `ClassSkillService.sync_points` pays the rest (level-ups, debug level changes, saves from before D70).

## 3. Skill level

- Power at skill level L: `1 + 0.15 × (L − 1)` → Lv 1 ×1.00, Lv 6 ×1.75. It multiplies damage ratios, heals, shields, passive bonuses and on-hit chances.
- Mana cost at level L: `cost × (1 + 0.06 × (L − 1))` → Lv 6 ×1.30.
- Durations of effects applied by a skill grow too: buffs × power (Lv 6 ×1.75), debuffs × (1 + 0.5 × (power − 1)) (Lv 6 ×1.375, `class_skill_debuff_duration_share`). The base durations come from the status effect data.

## 4. Mana

- New Hunter stats (`HunterService`): `max_mana` (class `base_mana` 100 + `mana_per_level` 2 per level) and `mana_regen` (class `mana_regen` 5 per second). They go through the normal stat pipeline (D18).
- Regeneration is ×3 while the Hunter has no target. `HunterRuntime.current_mana` is saved.
- Only actives cost mana: `8 + 1.5 × cooldown` at level 1 (cooldown 6 s → 17, 20 s → 38).
- Hunters show a thin blue mana bar under the HP bar while mana is not full.

## 5. Casting (`ClassSkillCaster`, one per Hunter actor)

- Every frame: regenerate mana, tick cooldowns. While the Hunter has a target and may attack, it casts the first owned skill (in opening order) that is off cooldown, affordable and whose conditions hold; then waits `class_skill_cast_gap` (0.8 s).
- Conditions: enemy skills need an enemy in range (`cast_range` or the attack range); heals and cleanses wait until an ally is below 70% HP or has a debuff; `trigger_hp_below` skills wait for low HP.
- Passives with a cooldown (Unyielding, Escape Artist, Perseverance, Protective Aura, Bodyguard, Resolve) trigger on their own and cost no mana.
- Damage per hit: `(attack_ratio × ATK + stat_ratio × stat) × power`, optionally × (stat / class base) for move speed, attack speed and range skills, then `max(1, value − DEF × 0.5)`, critical (with skill bonuses), damage multipliers, execute and tag bonuses. Each hit subtracts defense again, so many small hits are weak against bosses.
- Skill hits can be dodged unless `ignore_dodge`. They do not trigger normal on-hit effects.
- Presentation: the skill name pops over the caster, heals show green numbers, dodges show "Miss".

## 6. New combat stats

| Stat | Kind | Effect | Cap |
|---|---|---|---|
| `dodge` | additive from 0 | chance that an incoming hit misses | 40% (`dodge_cap`) |
| `tenacity` | additive from 0 | shortens incoming crowd control (stun, freeze, root, disarm, slows) | 70% (`tenacity_cap`) |
| `range_bonus` | additive from 0 | attack range × (1 + value) | — |
| `healing` | multiplier | heals done by class skills | — |

## 7. Conditions for passive modifiers

`Hunter.get_conditions(against)` adds: `vs_boss`, `vs_<tag>` from `EnemyDefinition.tags` (humanoid: Goblin, Skeleton; undead: Skeleton, Abyss Warden; beast: Wolf, Forest Guardian; slime), `unnoticed` (the enemy targets someone else), `vs_full_hp` (target ≥ 90% HP), `low_hp` (own HP < 50%), `high_hp` (own HP > 70%).

## 8. Bosses

- Stun, freeze, root and disarm from skills become **Stagger** on bosses (`data/status_effects/stagger.tres`: +10% damage taken, 2 s).
- Soft debuffs with stat modifiers (Slowed, Weakened, Armor Break, Burn…) from skills last half as long on bosses (`boss_soft_debuff_scale` 0.5).
- Damage over time in % of max HP (Bleed) deals 25% on bosses (`boss_ratio_dot_scale`); this applies to every source, not only skills.
- Execute thresholds drop to 15% (`boss_execute_threshold`); kill-reset skills do not reset on a boss.
- Taunt switches the enemy's target to the caster; the enemy keeps it until it picks a new target (no timed taunt yet).

## 9. Reincarnation (D70)

- Needs **level 100** (`reincarnate_level`) and the Portal. Level goes back to 1; class skills and their levels stay; the Hunter gets **1 swap point** (`skill_swap_points`, saved per Hunter).
- **Swap**: spend 1 swap point on an owned skill; it is replaced in the same slot by a random skill of the pool that the Hunter does not own, **keeping the old skill's level**.
- The point counter restarts: the new life earns 1 point every 10 levels again.
- Blocker today: the Town Hall has 5 levels, so the level cap is 50. Town Hall levels 6–10 are needed before anyone can reach 100.

## 10. UI

Hunter dialog → Skills tab, top section "Class skills": mana bar, skill points, swap points, next point level, owned skills (name, level x/6, description, numbers at the current level, Level up and Swap buttons), and "Learn a random skill". The Portal panel says that reincarnation keeps class skills and gives a swap point.

## 11. Simplifications (v1 of the implementation)

Some designs of the first guide are approximated with the generic skill data; the guide lists the exact implemented numbers.

- Movement skills (Leap Strike, Shadow Step, Disengage, Intercept…) do not move the Hunter; they keep their damage or buff.
- Hunting Companion is a 3-hit bite with Bleed, not a summoned wolf.
- Vanish uses Invulnerable + Focus; Reflex uses Thorns + Haste; Riposte uses Thorns.
- Oath and Bodyguard give Fortify or a shield instead of redirecting damage.
- Aura passives pulse a buff on a cooldown instead of a permanent aura.
- Bloodlust, Long Shot, Double Nock, Vengeance and Gatekeeper are flat bonuses instead of counting enemies, distance or defense.
- Effect durations are the data durations scaled by the skill level (no per-skill base durations).
