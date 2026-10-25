# DARK HUNTER TYCOON — AGENT RULES

> Đọc file này trước khi làm bất kỳ thay đổi nào. Nếu conflicts với DOCS/, file này ưu tiên hơn.

## 1. Dự án là gì

**Dark Hunter Tycoon** — game mobile 2D pixel-art (portrait, touch) viết bằng **Godot 4.7 + GDScript**.

Thể loại: Hunter management / town building / idle RPG / auto-combat.
Người chơi là **village chief**: xây dựng settlement, nuôi dưỡng Hunters, Hunters tự đi săn, chiến đấu tự động, thu thập tài nguyên.

**Không có endgame.** Không final boss, không win condition. Progression mở.

## 2. Engine & Rendering

| Key | Value |
|---|---|
| Engine | Godot 4.7, GDScript |
| Renderer | GL Compatibility (2D, broadest mobile support) |
| Viewport | 1170×2532 (portrait), stretch `canvas_items`, aspect `expand` |
| Scaling | `scale=3.25`, nearest-neighbor filtering (pixel art) |
| Target | Android + iOS (portrait, touch). Desktop chỉ để dev/test |
| Physics | Jolt Physics (3D engine nhưng dùng 2D physics layers) |

### Physics Layers
- Layer 1 `world`: static obstacles (rocks, walls, buildings)
- Layer 2 `actors`: Hunters and enemies (collide chỉ với layer 1, không body-block nhau)

## 3. Autoloads

Chỉ có 5 autoloads — **không thêm autoload mới** trừ khi được yêu cầu:

| Name | Path | Vai trò |
|---|---|---|
| `Loc` | `core/localization.gd` | i18n, `Loc.t(key, args)` |
| `DataRegistry` | `core/data_registry.gd` | Load static definitions từ `res://data/` |
| `GameManager` | `core/game_manager.gd` | Owns all gameplay services |
| `SaveManager` | `core/save_manager.gd` | Save/load, autosave, offline catch-up |
| `Audio` | `core/audio/audio_manager.gd` | Audio playback |

## 4. Kiến trúc (Architecture)

### 4.1 Folder Structure

```
res://
├── core/           # Autoload scripts
├── game/
│   ├── definitions/  # Resource classes (static data schemas)
│   ├── runtime/      # Runtime state objects (HunterRuntime, etc.)
│   └── services/     # Gameplay services (plain RefCounted/Object)
├── actors/
│   ├── common/       # Shared: Actor, ActorVisual, controllers
│   ├── hunter/       # Hunter scene, chibi body system
│   └── enemies/      # Enemy scenes and visuals
├── buildings/        # (placeholder, reserved)
├── world/
│   ├── world/        # Main map: WorldMap, buildings, props, camera
│   ├── expedition/   # Dungeon scenes
│   ├── vfx/          # Combat feedback, damage numbers, particles
│   ├── props/        # Trees, rocks
│   └── test_arena/   # Debug combat sandbox
├── ui/
│   ├── ui_root.gd    # Main UI controller
│   ├── sheets/       # Bottom sheets (one per panel)
│   ├── hud/          # Expedition HUD
│   ├── widgets/      # Reusable UI widgets
│   ├── kit/          # UIKit builders
│   ├── theme/        # RarityColors, ItemText, GameTheme
│   └── debug/        # Debug panel (dev builds only)
├── data/             # .tres content files by category
│   ├── config/       # game_config.tres
│   ├── hunters/      # HunterDefinition .tres
│   ├── enemies/      # EnemyDefinition .tres
│   ├── items/        # ItemDefinition .tres
│   ├── i18n/         # translations.json
│   └── ...           # 19 category folders
├── save/             # SaveCodec (snapshot ↔ services)
├── tests/            # Headless test runner
├── scenes/           # main.tscn + main.gd
├── tools/            # Offline tools (character forge, etc.)
├── assets/           # Art, audio files
└── DOCS/             # Design, architecture, decisions docs
```

### 4.2 Scene Structure

```
Main (scenes/main.gd)
├── GameRoot
├── WorldContainer       # Active world (WorldMap or ExpeditionScene)
├── UI/UIRoot            # Mobile portrait UI
├── UI/DebugPanel        # Debug only
└── Transition/Fade      # World switch fade
```

### 4.3 Separation Rules (QUAN TRỌNG)

1. **Static definitions** (`game/definitions/`) → Resource classes, `@export` fields
2. **Runtime state** (`game/runtime/`) → Plain RefCounted, ids + values only, serializable
3. **Gameplay services** (`game/services/`) → Logic, owned by GameManager, NOT autoloads
4. **Scene presentation** (`actors/`, `world/`) → Visual nodes
5. **UI** (`ui/`) → Reads services, calls actions, **never owns game state**

**Dependency direction:** Gameplay → ←  UI (UI depends on gameplay, not the reverse)

### 4.4 Service Pattern

Services là plain objects (RefCounted) tạo trong `GameManager.build()`:

```gdscript
# Đúng: Service nhận dependencies qua constructor
var combat = CombatService.new(stats, rng)

# Sai: Service tự access autoload
# var combat = CombatService.new()  # rồi bên trong dùng GameManager.xxx
```

Hiện có ~35 services: `StatService`, `HunterService`, `CombatService`, `WalletService`, `ProgressService`, `InventoryService`, `LootService`, `WorldService`, `BuildingService`, `HousingService`, `RecruitmentService`, `TempleService`, `EquipmentService`, `CraftingService`, `TraitService`, `MoodService`, `BondService`, `ActivityService`, `PurseService`, `SupplyService`, `NeedsService`, `RegionService`, `CorpseService`, `TalentService`, `ExpeditionService`, `ReincarnationService`, `AcademyService`, `ForgeService`, `TradingService`, `QuestService`, `ArenaService`, `WeeklyBossService`, `ClassSkillService`, `BarberService`, `StatGradeService`.

## 5. Data Pipeline

### 5.1 Definitions

Mọi definition extend `GameDefinition` (có `id: StringName`, `display_name: String`).

`display_name` là **translation key**, không phải text literal. Getter tự gọi `tr()`.

Danh sách categories (DataRegistry):

| Category | Folder | Class |
|---|---|---|
| `hunter` | `data/hunters/` | `HunterDefinition` |
| `trait` | `data/traits/` | `TraitDefinition` |
| `activity` | `data/activities/` | `ActivityDefinition` |
| `enemy` | `data/enemies/` | `EnemyDefinition` |
| `loot_table` | `data/loot_tables/` | `LootTableDefinition` |
| `item` | `data/items/` | `ItemDefinition` |
| `recipe` | `data/recipes/` | `RecipeDefinition` |
| `building` | `data/buildings/` | `BuildingDefinition` |
| `expedition` | `data/expeditions/` | `ExpeditionDefinition` |
| `region` | `data/regions/` | `RegionDefinition` |
| `talent` | `data/talents/` | `TalentDefinition` |
| `status_effect` | `data/status_effects/` | `StatusEffectDefinition` |
| `skill` | `data/skills/` | `SkillDefinition` |
| `quest` | `data/quests/` | `QuestDefinition` |
| `monster_skill` | `data/monster_skills/` | `MonsterSkillDefinition` |
| `class_skill` | `data/class_skills/` | `ClassSkillDefinition` |

### 5.2 Config

Balance values sống trong `GameConfig` (`data/config/game_config.tres`). **Không hard-code balance values trong code.**

### 5.3 Stat Formula

```
final = (base + level_growth * (level - 1) + Σflat) * (1 + Σpercent)
```

`StatModifier`: `stat`, `type` (FLAT/PERCENT), `value` (PERCENT as fraction: 0.15 = +15%), optional `condition`.

## 6. Localization (BẮT BUỘC)

### Rules

- **Mọi** player-facing text phải là translation key, **KHÔNG BAO GIỜ** literal string
- Keys sống trong `data/i18n/translations.json`
- Format: `{ "key": { "en": "...", "vi": "..." } }`
- Code đọc bằng `Loc.t(key, {placeholders})`
- Thêm text mới = thêm key với **cả** `en` và `vi` trong cùng change
- Dùng named placeholders (`{gold}`, `{name}`), **không** ghép fragments
- Developer-only messages (`push_error`, test asserts) = English, không cần key

### Ví dụ

```gdscript
# Đúng
toast(Loc.t("toast.root.reached_level", {"name": hunter.display_name, "level": level}))

# Sai
toast("Reached level %d!" % level)  # ← literal, KHÔNG ĐƯỢC
```

## 7. Save System

- JSON single-slot với backup. Schema versioned (`SaveCodec.SCHEMA_VERSION`)
- **Không serialize Godot Nodes.** Save ids + primitive data → reconstruct runtime objects
- `HunterRuntime.to_dict()` / `from_dict()` pattern
- Safe write: temp file → verify → backup → replace
- `SaveCodec.capture()` / `restore()` / `migrate()`
- Offline catch-up: `SaveManager.apply_offline_progress()` → `GameManager.advance_town_time(seconds, offline=true)`
- Autosave: services emit `autosave_requested` signal → `SaveManager` batches writes

## 8. Code Conventions

### GDScript Style

```gdscript
# Prefer typed GDScript
var hunters: Array[HunterRuntime] = []
var _definitions: Dictionary[StringName, Dictionary] = {}

# Class naming: PascalCase, file naming: snake_case
class_name HunterService  # → hunter_service.gd

# StringName for IDs/keys (performance)
var id: StringName
const HUNTER := &"hunter"

# Signals for decoupling
signal hunter_added(hunter: HunterRuntime)
signal gold_changed(new_amount: int, delta: int)

# Comment format: ## for documentation, # for inline
## Autoload. Owns game-wide state.
extends Node
```

### Patterns

- **Small, focused classes.** Không giant scripts
- **Resources/data definitions** cho content, không hard-code
- **Signals/events** cho decoupling
- **Không dùng** deep relative node paths (fragile)
- **Không thêm plugins** trừ khi được yêu cầu
- `ui/theme/` helpers nhận `DataRegistry` as parameter, không dùng autoload name trực tiếp
- UI widgets dùng `UIKit` builders (`UIKit.hbox()`, `UIKit.label()`, `UIKit.button()`, etc.)
- Sheets extend `Sheet` base class (title, close, scroll, rebuild on watched signals)

### Actor Composition

```
Hunter / Enemy extends Actor
├── Visual (extends ActorVisual)
├── NavigationAgent2D
├── HealthController
├── CombatController
├── StateController
├── StatusEffectController (added in code)
└── StatusEffectView (added in code)
```

Hunter visuals: `ChibiBody` (32×48 pixel body map, parts, facings, skin/dye recolour).

## 9. Testing

- **Runner:** `godot --headless --path . -s res://tests/run_tests.gd [-- <filter>]`
- Tests extend `TestCase` (`tests/test_case.gd`)
- Files: `tests/unit/test_*.gd` (auto-discovered)
- Methods: `test_*()` prefix
- Lifecycle: `before_each()` / `after_each()`
- Tests run bằng English locale
- Runtime errors tự động fail test
- **Không dùng test plugins** — plain GDScript runner only

## 10. Mobile Lifecycle

- Handle `NOTIFICATION_APPLICATION_PAUSED` / `FOCUS_OUT`: pause expedition, autosave
- Handle `NOTIFICATION_APPLICATION_RESUMED` / `FOCUS_IN`: apply offline progress, resume
- Input: touch/pointer events (`InputEventScreenTouch`, `InputEventScreenDrag`)
- **Không depend on hover hoặc keyboard input**

## 11. Workflow cho mỗi task

1. Đọc docs liên quan (DOCS/ folder)
2. Inspect existing code
3. Identify dependencies
4. Implement smallest complete slice
5. Validate
6. Fix errors
7. Update docs nếu architecture/design thay đổi
8. Report: implemented / files changed / validation / known limitations / next step

## 12. Documentation Priority

Khi conflicts giữa các nguồn:

1. File này (`AGENTS.md`)
2. Explicit user request
3. `DOCS/00_RULES.md`
4. `DOCS/DECISIONS.md` + `DOCS/BALANCE.md`
5. Design docs (`DOCS/DESIGN/`)
6. System specs (`DOCS/SYSTEMS/`)
7. Architecture (`DOCS/ARCHITECTURE/`)
8. Roadmap (`DOCS/ROADMAP/`)

**Không silently choose** khi conflict — báo cáo conflict.

## 13. KHÔNG BAO GIỜ

- Rewrite code không liên quan đến task
- Xóa working systems không có lý do
- Giấu gameplay rules trong UI code
- Invent arbitrary systems chỉ để fill gaps
- Tạo massive files không cần thiết
- Optimize mà không có evidence
- Claim success mà không validate
- Viết player-facing text literal thay vì translation key
- Thêm autoload mới
- Thêm plugin mới
- Implement multiplayer, online backend, monetization, PvP (trừ offline Colosseum)
- Hard-code balance values
- Serialize Godot Nodes
- Depend on hover/keyboard cho gameplay
- Dùng deep relative node paths
- Tạo "endgame" / "final boss" / "win condition" features
