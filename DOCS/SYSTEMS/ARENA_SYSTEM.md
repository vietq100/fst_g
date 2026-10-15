# ARENA SYSTEM (Đấu Trường)

Status: **phase 1 implemented** (D72): the Colosseum building, safe 1vs1 matches (rivals or a friendly match with one of your own Hunters), a replay view and the result. Ranking, tickets, rewards, 4vs4 / 6vs6, class skills in fights and the Token shop are not built yet. The rest of this file is the full design (D68). Hunter-versus-Hunter fights in three formats: **1vs1, 4vs4, 6vs6**.

Naming: the in-game name is **Đấu Trường**. The English id is `colosseum` (English UI "Colosseum") so it never clashes with the weekly-boss **Boss Arena** (`boss_arena`, D58).

See also: `COMBAT_SYSTEM.md` (damage, status effects), `CHARACTER_SYSTEM.md`, `guide/skills_guide.html` (class skills and their PvP ratings).

## 1. Scope

- Offline only. Opponents are **generated rival teams** (AI Hunters built from the same class, tier and skill rules as the player's). No online matchmaking, no backend, no real players (`00_RULES.md` §8 still bans online multiplayer).
- **Friendly matches** between the player's own Hunters use the same rules but give no ranking points.
- Fights are fully automatic, like every other fight. The player only picks the team, the formation and the format.

## 2. Formats

| Format | Team | Formation | Time limit | Unlock |
|---|---|---|---|---|
| 1vs1 (Song đấu) | 1 Hunter | — | 60 s | Colosseum Lv 1 |
| 4vs4 (Tổ đội) | 4 Hunters | 2 front + 2 back | 90 s | Colosseum Lv 2 |
| 6vs6 (Quân đoàn) | 6 Hunters | 3 front + 3 back | 120 s | Colosseum Lv 3 |

- Front row spawns 40 px ahead of the back row. Melee classes default to front, Ranger to back; the player can swap.
- A Hunter can be in one team per format at a time.
- **Win**: every enemy Hunter is down. **Time out**: the team with the higher sum of remaining HP % wins; equal → draw.

## 3. Eligibility

- Hunter must be in town, not injured, not asleep, not on duty in a dungeon or the Boss Arena.
- Minimum level 10. The match uses the Hunter's real stats (level, gear, traits, mood, bond, skills).
- Stamina cost per match: 10 (the need from D31). Below 25 stamina a Hunter cannot enter.

## 4. Consequences (arena is safe)

- Being downed in the arena is **not death**: no body, no Temple revival, no XP loss, no injury.
- Hunters leave the arena at their pre-match HP, minus nothing. Weapons do not wear (D64 durability is untouched).
- Mood: win +5, draw +1, loss −3. Trait hooks: Brave likes 1vs1, Cautious dislikes it, Reckless likes every format.
- Bond: +5 for every pair of Hunters in the same team that wins 4vs4 or 6vs6.

## 5. PvP combat rules

Applied whenever both attacker and target are Hunters. Numbers live in data (`BALANCE.md` → Colosseum).

| Rule | Value |
|---|---|
| Damage dealt (PvP dampening) | × 0.8 |
| Crowd control duration (Stunned, Frozen, Rooted, Disarmed, Slowed, Taunt) | × 0.6 |
| Same-type crowd control immunity after it ends | 2 s |
| Healing and shields | × 0.7 |
| Invulnerable, "survive a fatal hit" effects | once per match |
| Dodge cap | 25 % (PvE 40 %) |
| Damage reduction cap | 50 % (PvE 60 %) |
| Tenacity cap | 50 % (PvE 70 %) |
| Lifesteal cap | 20 % (PvE 30 %) |
| Thorns cap | 30 % (PvE 60 %) |
| Crit chance cap | 75 % (PvE 100 %) |
| Gold Find, boss-only and monster-type bonuses | no effect |

- Skill effects that say "vs Người" (Gladiator, Manhunter…) apply to Hunters and to humanoid monsters (Goblin, Skeleton).
- New debuff **Grievous**: −30 % healing received for 3 s. Used by PvP skills.
- Each match starts with every skill off cooldown.

## 6. Ranking and seasons

- Each format has its own **rank points** (start 1000). Win +20, draw +5, loss −15, scaled by the rating gap (Elo-like, K = 32).
- Tiers: Đồng < 1100 ≤ Bạc < 1300 ≤ Vàng < 1500 ≤ Bạch Kim < 1700 ≤ Kim Cương < 1900 ≤ Huyền Thoại.
- **Season = 7 real days**, same clock as the weekly boss. At season end: rewards by tier, then points move halfway back to 1000.
- **Tickets**: 5 ranked matches per format per day (real day), refilled at local midnight. Friendly matches are free.

## 7. Rival generation

- The board offers 3 rival teams per format, refreshable for 20 gold.
- Team power = Σ Hunter power, Hunter power = `HP × 0.2 + ATK × 2 + DEF × 1.5` × (1 + 0.1 × skills).
- Rivals: one weaker (×0.85), one even (×1.0), one stronger (×1.15) than the player's team. Win points: ×0.8 / ×1.0 / ×1.3.
- Rival Hunters are rolled like Tavern candidates (class, tier, traits, 7 random class skills) and levelled to match power. They have names from the class name pools and a rival guild name.

## 8. Rewards

| Source | Reward |
|---|---|
| Ranked win | 15 gold × format size factor (1vs1 ×1, 4vs4 ×3, 6vs6 ×4) + 1 Arena Token |
| Season tier | Đồng 50 · Bạc 150 · Vàng 400 · Bạch Kim 800 · Kim Cương 1500 · Huyền Thoại 3000 gold, plus Arena Tokens |
| Arena Token shop | cosmetic hats and dyes, skill re-roll scrolls (see §9), rare gear |

## 9. Skill swaps (link with class skills)

- Class skills are opened at random with skill points (D70). Reincarnation gives 1 swap point per Hunter.
- The Token shop sells a **Swap Scroll**: +1 swap point for one Hunter (replaces one chosen skill with a random one it does not own, same level).

## 10. Building: Colosseum (Đấu Trường)

| Level | Cost | Effect |
|---|---|---|
| 1 | 400 gold + 10 Iron Ore, needs Town Hall Lv 2 | 1vs1, friendly matches |
| 2 | 900 gold + 3 Dark Essence | 4vs4, Token shop |
| 3 | 2000 gold + 8 Dark Essence | 6vs6, +1 daily ticket per format |

Footprint 3 × 3, unique. Visual: round stone arena with banners in the class colours.

## 11. UI

- `ColosseumSheet`: three tabs (1vs1, 4vs4, 6vs6); each shows rank, tier badge, tickets, the team slots with formation, the 3 rival cards (power, classes, tier), Fight and Refresh.
- Match view: the arena scene with health bars and skill names over casters; speed ×1 / ×2; skip to result.
- Result: win / loss, points change, rewards, best damage and best healing Hunter.

## 12. Save

New section `colosseum`: per format rank points, tickets, teams (Hunter ids + formation), rival boards (seeds), season start unix, token balance. Missing section = defaults.

## 13. Open questions

- Should Colosseum fights be watchable on the world map (spectators at the building) or only in the match view?
- Do pets and talents (Cook, Herbalist) take part in arena fights? Proposal: pets yes, field crafting no.


## 14. Phase 1 as built (2026-10-16)

- **Building**: `colosseum` (3×3, unique, needs Town Hall Lv 2, 400 gold; levels 2 and 3 are defined for the later formats). Panel: BuildingSheet → "Enter the Colosseum" (`ColosseumSheet`); also listed in the Shop sheet.
- **Rules**: `ArenaService` — eligibility (level ≥ `colosseum_min_level` = 5, alive, not hurt, not on an expedition, stamina ≥ 25), three generated rivals (power × 0.85 / 1.0 / 1.15, level chosen by search so HP×0.2 + ATK×2 + DEF×1.5 matches), friendly matches against another own Hunter.
- **The fight** is a **simulation** from the real stats (level, gear, traits, mood, skill stat bonuses), not an actor fight in a scene: opening delay 0.8 s, then each fighter strikes every 1/attack-speed s; damage = `calculate_damage` × crit × dealt × taken × **0.8**; dodge capped at 25 %, crit at 75 %; 60 s limit, then higher HP % wins (within 0.5 % = draw). Deterministic for a seed. Class skills, mana, status effects and movement are **not** simulated yet.
- **Consequences** (`apply_result`): stamina −10, mood +5 / +1 / −3, history counters `arena_wins` / `arena_draws` / `arena_losses`. HP, XP, injuries and gear are untouched. The match is applied when the player closes the result screen.
- **Replay** (`ColosseumMatchView`): full-screen over the UI (takes every tap): both Hunters' figures on a sand arena, lunge and flash on each hit, floating damage / crit / miss, live HP bars and clock, speed ×1/×2, skip, then the result.
- Texts are keys (`ui.arena.*`, `err.arena.*`, `building.colosseum.name`) in English and Vietnamese. Tests: `tests/unit/test_arena.gd` and two UI tests.
