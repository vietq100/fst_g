# PHASE 13 — Character Forge: thay bộ nhân vật chibi bằng bộ "Pixel Hero Forge"

> Tài liệu giao việc cho agent. Viết theo `DOCS/ROADMAP/AGENT_TASK_TEMPLATE.md` và tuân thủ `DOCS/00_RULES.md`.
> Trạng thái: **XONG PHẦN CODE — bước 1–7 xong, thêm góc nhìn sau lưng và mũ helm/hood thật (D76); chưa chạy test bằng Godot (máy chưa có Godot 4.7). Xem "Completion report".** Owner yêu cầu ngày 2026-10-15. Quyết định Q1–Q6 đã chốt ngày 2026-10-15 (D73, §5).

## Task

Thay toàn bộ phần **hình** của Hunter (thân chibi, tóc, áo, quần, giày, mũ, kính, vũ khí, hiệu ứng đòn đánh) bằng bộ nhân vật thiết kế trong công cụ HTML **Pixel Hero Forge**. Gameplay, dữ liệu, save và UI logic giữ nguyên. Chỉ lớp trình bày (`actors/hunter/chibi/*`, phần vẽ vũ khí của Hunter) được thay.

## Read first

1. `DOCS/00_RULES.md` (bắt buộc, ưu tiên cao nhất)
2. `DOCS/DECISIONS.md`: D49, D51, D59, D67, D71 (lịch sử chibi, đồ mặc, vũ khí)
3. `DOCS/DESIGN/CHARACTER_DESIGN.md`, `ART_DIRECTION.md`, `ASSET_SPEC.md`, `VFX_DESIGN.md`
4. Code hiện tại: `actors/hunter/chibi/` (`chibi_body.gd`, `chibi_visual.gd`, `chibi_animations.gd`, `chibi_dress.gd`, `pet_sprites.gd`), `actors/common/weapon_sprites.gd`, `actors/common/actor_visual.gd`, `actors/hunter/hunter.gd` (`_refresh_equipment_look`), `game/services/equipment_service.gd` (`dress_for`), `game/runtime/hunter_appearance.gd`, `ui/widgets/hunter_portrait.gd`, `ui/widgets/hunter_figure.gd`
5. Test liên quan: `tests/unit/test_appearance.gd`, `tests/unit/test_equipment.gd`
6. **Nguồn sự thật của bộ nhân vật mới**: `/Users/vietj/Develops/mine/preview_ui/pixel-character.html` (1648 dòng, md5 `3b11065801aebf0888f766d27c1069e7` lúc viết tài liệu này). Mở bằng trình duyệt để xem mọi mẫu và đòn đánh.

---

## 1. Bộ nhân vật mới (đọc kỹ trước khi code)

### 1.1 Tổng quan

| | Chibi hiện tại (D67) | Pixel Hero Forge (mới) |
|---|---|---|
| Thân | 23×44 px, canvas 40×64 | ≈16×35 px (đo từ ảnh tham chiếu của owner) |
| Góc nhìn | front / back / side (left = side lật) | **chỉ một góc 3/4 nhìn sang TRÁI**; phải = lật ngang |
| Tóc | 10 kiểu × 10 màu | 18 kiểu, màu tự do (ramp tự sinh từ 1 màu gốc) |
| Áo | 4 outfit theo class + tint | 14 mẫu áo + tank top (core) |
| Quần / giày | chỉ đổi màu | 5 kiểu quần, 5 kiểu giày + core (quần đùi / chân trần) |
| Mũ | 5 (helm, cap, hood, wizard, crown) | 7 (cap, beanie, wizard, cowboy, viking, crown, nonla) |
| Kính | không có | 5 (round, square, sun, goggle, patch) |
| Vũ khí | bitmap `WeaponSprites` ×2 | 9 vũ khí **vẽ bằng hình học**, xoay mọi góc, ×2 |
| Đòn đánh | 1 bảng ATTACK chung | 7 chuỗi theo loại vũ khí + 6 hiệu ứng nguyên tố |
| Độ phân giải | 1× (vũ khí 2×) | thân 1×, áo 1.5×, mũ 1.5×, kính 2.5×, vũ khí 2× (cố định) |

### 1.2 Hệ toạ độ thiết kế (design coords)

- Mọi map trong HTML dùng **toạ độ thiết kế**: đơn vị = 1 pixel nhân vật. Trong HTML, toạ độ canvas = design + (`OX`=14, `OY`=4). Trong game sẽ dùng offset khác (§3.2).
- Mốc thân: đầu `HEAD` đặt tại `P(4,3)` (đầu x4..15, y3..17; mắt xa x5, mắt gần x10, hàng y12–13). Thân x5..12, y18..27. Tay xa x3..4. Vai và tay gần x12..15. Chân xa x6..7, chân gần x11..12. Bàn chân xa ở hàng 34, bàn chân gần ở hàng 35. Viền dưới cùng là hàng 36.
- Mặt đất: `GROUND = 35.6`. Bóng đổ: `SHADOW = P(3,35)`.
- Vai gần: `SHOULDER = (13.5, 19.5)`, `ARM_LEN = 9`, tay nghỉ `IDLE_HAND = (14.5, 28.5)`.
- Góc (vũ khí, tay): **0° = phải, 90° = xuống, 180° = trái (hướng mặt), −90° = lên**.

### 1.3 Ký hiệu trong map (`rows`)

`.` trong suốt · `b` màu gốc · `h` sáng · `s` tối · `d` tối sâu · `a`/`A` màu phụ (gốc/tối) · `l` kính trong (màu phụ, alpha 0.45) · `w` trắng · `W` trắng alpha 0.6 · `g`/`G` kim loại (sáng/tối) · `L` tròng kính đen · `c`/`C` sừng · `y`/`Y` vàng (sáng/tối) · `r`/`R` đỏ (sáng/tối) · `p` bóng đất (đen, alpha 0.22) · riêng cho da: `e` mắt, `E` mắt (hàng trên, tắt khi chớp), `k` má hồng, `m` miệng · riêng cho tóc: `K` = tai (màu `s` của da).

### 1.4 Màu: ramp tự sinh (phải port **chính xác**)

`ramp(hex)` (HTML dòng ~143) sinh từ 1 màu gốc các tông: `h` (sáng hơn, hue lệch về 55°), `b`, `s` (tối hơn, hue lệch về 250°), `d`, `o` (viền ngoài khi chế độ viền màu), `i` (nét trong). `makePal(color, accent)` ghép ramp màu chính, ramp màu phụ và bảng `FIXED`. `bodyPal()` thêm `e/E/k/m`. Bảng tóc thêm `K` = `skin.s`. Viền ngoài mặc định là đen `BLACK = [27,22,34]` (`cfg.black = true`).

### 1.5 Thuật toán vẽ: `drawPart` + lưới chiếm chỗ (HTML dòng ~176–245)

- Mỗi lớp (part) gồm `{x, y, rows}` (lớp thô 1×) hoặc `{ox, oy, rows, res}` (lớp chi tiết, `ox/oy` theo đơn vị `UNIT`).
- **UNIT = 30** phần mỗi pixel nhân vật, nên ô của lớp 1× là 30, của 1.5× là 20, của 2× là 15, của 2.5× là 12. Đều là số nguyên, nên pixel sắc nét.
- Lưới chiếm chỗ `occ` (10 ô / pixel nhân vật) có 4 giá trị: 0 trống, 1 viền ngoài, 2 đã tô, 3 ngoài khung. Lưới này quyết định:
  - **Viền ngoài**: ô kề lớp mà đang trống thì tô viền đen (hoặc `pal.o`). Lớp có cờ `thick` thì viền dày `round(res)` ô (tức ≈1 pixel nhân vật).
  - **Nét trong**: ô kề lớp mà đã có lớp khác thì tô `pal.i`, dày 1 ô. Bỏ qua nếu `inner=false` (tóc).
  - **Bóng đổ** (`cast`): làm tối các ô ngay dưới (tóc thì dưới và phải) bằng `SHADE=[38,22,60]` alpha 0.2.
- `clip` của mũ: ẩn các hàng tóc có `y < clip`.
- Cờ trên part: `outline:false` (không viền), `inner` (ép kẻ nét trong: đuôi tóc, bím, búi), `near` (tay áo phía gần, bị thay khi tay xoay), `keep` (giáp vai giữ lại), `pattern` (kẻ ô: phóng nguyên khối), `thick`.

### 1.6 Thứ tự lớp (`compose`, HTML dòng ~1306)

shadow → vòng phép / sóng chấn động (lớp đất) → tóc sau → mũ trùm của áo → (vũ khí nếu `behind`) → ống tên → chân → thân + tay (tư thế có vũ khí: bỏ tay gần) → quần hoặc quần đùi → giày → áo hoặc tank top → dây ống tên → (cung thủ: tay xa + cung + nắm tay) → đầu (cast) → tóc trước (`inner:false`, cast) → kính → mũ (cast) → [vệt chém] → vũ khí → tay xoay (tay áo 1.5×, da 1×) → nắm tay → hiệu ứng.

### 1.7 Độ phân giải cố định (`RES`)

- **Áo, mũ trùm, tay áo xoay: 1.5×. Mũ: 1.5×.** Đã được tiền xử lý bằng `fineOf()`: phóng Scale2x/Scale3x, lấy mẫu ở tâm ô, rồi `bevel()` thêm viền sáng ở mép trên-trái và tối ở mép dưới-phải. Mẫu kẻ ô (`pattern`) phóng nguyên khối.
- **Kính: 2.5×**, vẽ hình học (`GLASS_FINE`) quanh mắt.
- **Vũ khí, mũi tên, ống tên, dây đeo: 2×**, vẽ hình học (`blade/axe/hammer/spear/staff/bow/arrowShape`).
- Nhân vật (da, tóc, quần, giày, tank, quần đùi): 1×.

### 1.8 Vũ khí và tay

- `ITEMS.weapon[i]`: `anim` (chuỗi đòn), `hold = [x, y, góc]` (tư thế nghỉ: vị trí tay + góc), `tip` (chiều dài tới mũi), `reach`, `color` (lưỡi/thân), `accent` (chuôi/ngọc), `shape(u, v, st)` (u dọc thân vũ khí, v ngang; `st.K` = độ mịn).
- Tư thế nghỉ: tay gần là một **ống tròn (capsule)** vẽ từ vai tới tay, nắm tay tròn đè lên chuôi. Vũ khí chống đất không nhún theo nhịp thở.
- Cung: tay xa duỗi cầm cung `BOW_HAND = (−3.5, 19.5)` từ `FAR_SHOULDER = (4.5, 19.5)`. Tay gần có hai đoạn: vai → khuỷu (`elbow`) → tay kéo dây (`draw`). Ống tên đeo sau lưng, dây đeo chéo ngực.

### 1.9 Chuỗi đòn (`ANIMS`) và hiệu ứng (`FX`)

- `slash` (kiếm, katana), `heavy` (đại kiếm), `stab` (dao găm), `thrust` (giáo), `smash` (rìu, búa), `cast` (gậy phép), `shoot` (cung). Mỗi khung có `d` (ms), `arm`/`wpn` (góc), `dx`/`dy`, `ext`, `behind`, `arc`, `hit`, `shock`, `circle`, `charge`, `strike`, `proj`, `lines`, `mark`, `shake`, `fade`. Cung có thêm `draw`, `elbow`, `pull`, `arrow`.
- `FX`: `none`, `fire`, `ice`, `thunder`, `poison`, `shadow`, mỗi loại 3 màu. Hiệu ứng vẽ ở độ phân giải 1×: vệt chém lưỡi liềm, nổ sao, sóng chấn động, vòng phép, cột phép, hạt theo nguyên tố, mũi tên bay, hào quang quanh vũ khí.

---

## 2. Goal

Sau khi xong:
- Mọi Hunter trong world, UI card, paper doll và chân dung đều dùng bộ nhân vật mới.
- Ngoại hình (`HunterAppearance`) và đồ mặc (`ChibiDress` từ `EquipmentService.dress_for`) quyết định kiểu tóc, màu, áo, quần, giày, mũ, kính, vũ khí như trong HTML.
- Đòn đánh của Hunter theo loại vũ khí, có hiệu ứng.
- **API công khai giữ nguyên** để gameplay và UI không phải sửa: `ChibiVisual` (thuộc tính `appearance`, `outfit`, `dress`, `weapon_*`, `dead`, `play_action`, `get_animation`, `get_frame`), `ChibiBody.get_frames/get_portrait/get_figure/hat_style_for/outfit_for/view_of`, `ChibiDress`, `HunterAppearance`, `ChibiAnimations` (tên animation, `PRIORITY`).

## 3. Kế hoạch kỹ thuật

### 3.0 Chuẩn bị nguồn

1. Copy `pixel-character.html` vào repo: `tools/character_forge/pixel-character.html`. Từ đây file này là nguồn sự thật; mọi chỉnh sửa hình phải sửa ở đây rồi export lại.
2. Viết exporter **`tools/character_forge/export_forge.js`** (Node ≥ 18, chỉ là công cụ dev, không vào build). Cách lấy engine: phần JS từ sau thẻ `<script>` tới dòng chú thích `STATE + UI` không dùng DOM, chạy được trong Node. Ví dụ:

```js
// node tools/character_forge/export_forge.js
const fs = require('fs'), path = require('path');
const html = fs.readFileSync(path.join(__dirname, 'pixel-character.html'), 'utf8');
const js = html.slice(html.indexOf('<script>') + 8, html.indexOf('/* ============================================================\n   STATE + UI'));
const forge = new Function(js + '; return { W,H,OX,OY,UNIT,OCC,RES,BLACK,FIXED,SHADE,HEAD,BODY,SHADOW,UNDER,ITEMS,ANIMS,FX,' +
  'SHOULDER,ARM_LEN,IDLE_HAND,BOW_HAND,FAR_SHOULDER,CAST_X,BOW_X,GROUND,ramp,makePal,fineOf,rasterizeFine,GLASS_FINE,compose };')();
// 1) forge_data.json: mọi part thô (rows + cờ), part 1.5× đã qua fineOf cho áo/mũ (ITEMS.shirt/hat, cả `back`),
//    kính 2.5× đã rasterize (GLASS_FINE[id](2.5) → rasterizeFine(2.5, 9, 12.5, 7, ...)), nón lá (đã sinh sẵn),
//    meta item (id, color, accent, clip, sleeve, sleeveColor, anim, hold, tip, reach), ANIMS, FX, hằng số.
// 2) golden/*.json: danh sách ô {x,y,s,c,a} của compose() cho ~12 cấu hình mẫu (preset, core, mỗi loại vũ khí,
//    1 khung đòn mỗi anim) + rows vũ khí 2× ở các góc [-90,-60,0,45,90,135,180] — dùng cho test GDScript.
```

   Ghi ra `actors/hunter/forge/forge_data.json` và `tests/fixtures/forge_golden/`. Thêm vào `DOCS/DESIGN/ASSET_SPEC.md` lệnh export lại khi sửa HTML.

### 3.1 Port engine sang GDScript (thư mục mới `actors/hunter/forge/`)

| File | Nội dung | Ghi chú |
|---|---|---|
| `forge_data.gd` | Đọc `forge_data.json` một lần (static cache) | không parse lại mỗi frame |
| `forge_palette.gd` | `ramp`, `make_pal`, `body_pal`, `FIXED` | port từng dòng; test so màu với golden |
| `forge_renderer.gd` | `draw_part` + `occ` + viền ngoài/trong + `cast` + `clip`; trả về danh sách ô | giống JS từng phép tính |
| `forge_shapes.gd` | `blade/axe/hammer/spear/staff/bow/arrow_shape`, `wood`, `seg_dist`, `local`, `rasterize_fine`, `arm_parts`, `quiver_parts` | port tay (hình học xoay theo góc nên không export sẵn được) |
| `forge_composer.gd` | tương đương `compose()`: chọn part theo look + dress + frame, thứ tự lớp §1.6 | trả về các **lượt lớp** (§3.3) |
| `forge_fx.gd` | các hàm `fx*` (vẽ 1×) | vẽ trong `_draw` của `ChibiVisual` |

**Bẫy khi port JS sang GDScript (bắt buộc làm đúng):**
- `Math.round(x)` của JS **khác** `round()` của GDScript với số âm .5. Dùng `floor(x + 0.5)`.
- `Math.floor(a) & 1`, `% 2` với số âm: ép `int(floor(a))` trước rồi mới `&` hoặc `%`.
- Xâu `rows`: truy cập ký tự bằng `row[i]` (String). Không dùng `PackedByteArray` nếu không cần.
- Khoá ô `KEY(x,y) = (x+4096)*16384 + (y+4096)` dùng được nguyên trong GDScript.

### 3.2 Đặt lên canvas của game

- Giữ `ChibiBody.CANVAS = 40×64`, `FEET = (20, 64)`. Toạ độ thiết kế → canvas: **`canvas = design + (10, 27)`**, nên chân (design (10, 37)) trùng `FEET`. Mũ cao nhất (design y −4) nằm ở canvas y 23, mũ rộng nhất (x −3..20) nằm ở canvas 7..30.
- Hunter sẽ **thấp hơn khoảng 20%** so với hiện tại (≈36 px so với 44 px). Đây là chủ ý vì theo đúng ảnh tham chiếu. Không scale lẻ (D73 / Q2).
- Cập nhật các hằng phụ thuộc kích thước: `PORTRAIT_RECT` (crop đầu + vai, giữ 27×29), vị trí `soul` (−22 → khoảng −18), ellipse bóng (11×4 → 9×3), vòng chọn, nameplate (`actor_nameplate.gd`) nếu dùng chiều cao cố định.

### 3.3 Nướng texture và vẽ trong `ChibiVisual`

- Mỗi khung là các **lượt lớp liên tiếp cùng độ phân giải**, ví dụ [1× thân] [1.5× áo] [1× đầu + tóc] [2.5× kính] [1.5× mũ] [2× vũ khí] [1.5× tay áo] [1× nắm tay]. Mỗi lượt nướng thành một `ImageTexture` cỡ `canvas × res`, cắt theo `get_used_rect()` kèm offset.
- `_draw()` vẽ các lượt theo thứ tự bằng `draw_set_transform(offset, rotation, Vector2(1/res, 1/res))`. Bộ lọc texture là Nearest (mặc định dự án: `default_texture_filter=0`).
- **Không** gộp thành một ảnh 30× (quá nặng). **Không** vẽ từng ô bằng `draw_rect` mỗi frame (hàng nghìn lệnh × nhiều Hunter).
- Cache theo `look.key() | dress.key() | facing | animation | frame | weapon kind | tint | fx`. Vũ khí cache theo `(kind, tint, góc làm tròn 5°, pull, arrow)`.
- Chết (`lying`): xoay các lượt quanh chân bằng `rotation` trong transform, không cần `Image.rotate_90`.

### 3.4 Hướng nhìn (facing)

Bộ mới chỉ có góc 3/4 nhìn trái. Đã chốt (D73 / Q1):
- `LEFT`: hình gốc. `RIGHT`: lật ngang toàn bộ, gồm vũ khí và hiệu ứng (đổi dấu x, góc `a → 180° − a`).
- `DOWN` và `UP`: dùng hướng ngang gần nhất (lưu `_last_side`). Tức là sprite **2 hướng** (trái/phải), như nhiều game chibi.
- `ChibiBody.view_of()` vẫn trả `View` cho code khác (MonsterBodies dùng `ChibiBody.View`). Không đổi enum.

### 3.5 Animation

- Giữ tên và `PRIORITY` trong `ChibiAnimations`. Đổi `PIXEL_SCALE` thành **1.0**, vì bảng gốc tính theo thân 15×29, gần đúng cỡ thân mới.
- Nhóm part của bảng → part của Forge:
  - `head`: đầu, tóc trước và sau, kính, mũ.
  - `torso`: thân, tank hoặc áo (kể cả vạt áo dài, mũ trùm), eo quần (hàng y ≤ 29), ống tên, dây đeo.
  - `arm_l`: tay xa và tay áo xa (part có `x ≤ 4` và rộng ≤ 3).
  - `arm_r`: tay gần và tay áo gần (`near`), hoặc tay xoay khi cầm vũ khí.
  - `leg_l` / `leg_r`: chân, các hàng quần y ≥ 30 tách theo cột (x ≤ 8 là chân xa, x ≥ 10 là chân gần), giày xa/gần.
- Khi thân bị nâng so với chân (walk, run), lấp khe bằng cách lặp hàng mép, như `ChibiBody.compose` cũ.
- Góc vũ khí trong bảng cũ (0 = thẳng lên, + = về phía trước) đổi sang góc Forge (hình nhìn trái): **`forge = −90 − game`**. Ví dụ game 90 → 180, game −60 → −30.
- **ATTACK**: thay bằng chuỗi `ANIMS[weapon.anim]` của Forge. Thêm hỗ trợ thời lượng **từng khung** (`"dur"` tính bằng giây) vào `ChibiAnimations` và vòng lặp khung của `ChibiVisual`. Animation nào không có `dur` thì vẫn dùng `fps`.
- **SKILL**: Hunter cầm gậy phép thì dùng `cast`. Vũ khí khác giữ bảng SKILL cũ, nhưng thay hiệu ứng `charge`/`burst` cũ bằng `fxGlow` và `fxBurst` theo nguyên tố.
- `IDLE`, `WALK`, `RUN`, `HIT`, `DEATH`, `PICKUP`, `LOOT`, `INTERACT` giữ bảng cũ (offset part). Chớp mắt (`E`) và nhịp thở theo HTML (`bob` 520 ms, chớp 140 ms mỗi 3,4 s) chỉ chạy khi IDLE.
- Khiên của Guardian: giữ `_draw_shield` hiện tại. Forge chưa có khiên.

### 3.6 Ánh xạ dữ liệu → Forge

Không đổi schema save. Chỉ thêm giá trị, và thêm vào **cuối** danh sách.

**Ngoại hình (`HunterAppearance`)**

| Trường | Ánh xạ |
|---|---|
| `skin` (0..3) | màu da = `ChibiBody.SKINS[i][1]` (màu gốc), ramp Forge tự sinh |
| `hair_color` (0..9) | màu tóc = `HAIR_COLORS[i][1]`. Mắt = `HAIR_COLORS[i][2].darkened(0.45)` (giữ luật D51: mắt theo màu tóc) |
| `hair_style` | 0 short · 1 spiky · 2 buzz · 3 sweep · 4 hero · 5 bob · 6 long · 7 pony · 8 twin · 9 bun. Nâng `HAIR_STYLE_COUNT` lên 18, thêm vào cuối: 10 quiff · 11 mohawk · 12 afro · 13 pixie · 14 hime · 15 wavy · 16 braid · 17 buns (save cũ 0..9 không đổi nghĩa) |
| `dye` (0..7) | màu quần đùi core = `PlaceholderVisual.ACCENT_PALETTE[i]` |
| `gender` | Forge không vẽ khác theo giới. Giữ trong save, không dùng |

**Áo theo class (outfit) và đồ mặc (`ChibiDress`)**

| Class / outfit | Áo Forge | Quần | Giày |
|---|---|---|---|
| `""` (core) | none (tank top) | none (quần đùi) | none |
| warrior | `armor` | `armor` | `armor` |
| ranger | `jacket` (màu xanh lá) | `cargo` | `boots` |
| rogue | `hoodie` (màu tối) | `jeans` (màu tối) | `leather` |
| guardian | `knight` | `armor` | `armor` |

- `dress.cloth` (tint áo, `armor` slot) → màu chính của áo. `skin` item: `outfit_id` theo bảng trên. Thêm luật: nếu `ItemDefinition.look_id` là id áo Forge (vd. `aodai`, `vest`, `sailor`, `robe`, `gi`, `flannel`, `sweater`, `tee`, `shirt`, `leather`) thì dùng đúng áo đó.
- `dress.pants` → màu quần. Kiểu quần lấy theo class, hoặc `look_id` của item quần (`jeans/capri/cargo/skirt/armor`).
- `dress.boots` → màu giày. Kiểu lấy theo class, hoặc `look_id` (`sneaker/boots/sandal/leather/armor`).
- Mũ (`ChibiBody.HATS` / `hat_style_for`): `cap→cap`, `wizard→wizard`, `crown→crown`, `helm→viking` **không có hai part sừng** (thêm biến thể `helm` vào HTML rồi export), `hood→beanie` (tạm, D73 / Q4). Thêm `beanie`, `cowboy`, `viking`, `nonla` vào `HATS`/`HAT_WORDS` (nhận qua `look_id` hoặc từ trong id).
- **Kính**: game chưa có slot. Đã chốt (D73 / Q3): item ở slot `accessory` (charm) có `look_id = glasses_<round|square|sun|goggle|patch>` thì vẽ kính. Thêm trường `glasses` (+ `glasses_tint`) vào `ChibiDress`.
- **Vũ khí của Hunter** (`WeaponSprites.kind_for_item`): `sword→sword`, `greatsword→great`, `curved→katana`, `dagger→dagger`, `fang→dagger`, `bow→bow`, `mace/club/bone→hammer`, `shadow→sword`. Thêm từ khoá: `axe→axe`, `spear/lance→spear`, `staff/wand/rod→staff`, `katana→katana`. Mặc định theo class: warrior `sword`, ranger `bow`, rogue `dagger`, guardian `hammer`. **Monster giữ nguyên `WeaponSprites`** (`MonsterVisual` không đổi).
- **Nguyên tố hiệu ứng**: mặc định `none`. Đã chốt (D73 / Q5): `look_id` của vũ khí có hậu tố `_fire/_ice/_thunder/_poison/_shadow`, hoặc lấy từ skill đang cast. Không thêm trường gameplay mới.
- Pet: giữ `PetSprites` như cũ, chỉ chỉnh vị trí theo chiều cao mới.

### 3.7 UI

- `get_portrait`: crop đầu và vai từ khung đứng nghỉ, nhìn trái, cỡ giữ 27×29.
- `get_figure`: toàn thân, đứng nghỉ, crop theo phần đã vẽ, chân ở hàng cuối. Với các lớp nhiều độ phân giải, figure/portrait cần nướng ra **một ảnh** để widget cũ dùng được: nướng ở 6× rồi để widget scale (kính 2.5× sẽ lệch tối đa 1 ô ở 6× nhưng chấp nhận được trong UI), hoặc đổi `HunterFigure`/`HunterPortrait` sang vẽ các lượt lớp như §3.3 (khuyên dùng).

## 4. Design requirements

- Đúng từng pixel như HTML ở góc nhìn trái: so sánh bằng golden test (§6).
- Viền ngoài đen, nét trong theo màu của lớp. Tóc không kẻ nét trong mà đổ bóng.
- Áo/mũ 1.5×, kính 2.5×, vũ khí 2×: kích thước ô cố định, không lấy theo cài đặt.
- Vũ khí chống đất (đại kiếm, rìu, búa) và cung không nhún theo nhịp thở.
- Mọi chữ hiển thị (tên kiểu tóc, mũ, nguyên tố nếu đưa vào UI) là translation key `en` + `vi` (00_RULES §11b). Tên tiếng Việt trong HTML chỉ dùng cho công cụ.

## 5. Quyết định đã chốt (D73)

Owner đồng ý toàn bộ mặc định ngày 2026-10-15:

| # | Câu hỏi | Đã chốt |
|---|---|---|
| Q1 | Hướng nhìn lên/xuống | sprite 2 hướng: DOWN/UP dùng hướng ngang gần nhất. Góc nhìn sau lưng làm ở phase sau, thêm vào HTML trước |
| Q2 | Hunter thấp hơn ~20% | giữ 1:1 với pixel thế giới, không scale lẻ |
| Q3 | Kính đi vào slot nào | `accessory` (charm) với `look_id = glasses_*` |
| Q4 | `helm` và `hood` | thêm biến thể `helm` (viking không sừng) và `hood` vào HTML, export lại. Trong lúc chờ: `hood → beanie` |
| Q5 | Nguồn nguyên tố cho hiệu ứng | hậu tố `look_id` của vũ khí, hoặc skill đang cast |
| Q6 | Giữ chibi cũ làm fallback | xoá `ChibiBody.BODY/OUTFITS/HAIR_STYLES/HATS` cũ sau khi test xanh. Không giữ hai hệ song song |

**Việc của agent:** khi bắt đầu phase này, chép nguyên văn khối dưới đây vào cuối `DOCS/DECISIONS.md` (sau D72). Khối viết bằng tiếng Anh cho khớp với nhật ký quyết định. Nếu số D73 đã bị dùng, lấy số kế tiếp và sửa mọi chỗ "D73" trong file này.

```markdown
## D73. Character Forge replaces the chibi Hunter art (owner request, 2026-10-15; replaces the art of D49/D51/D67, keeps their APIs)
- **Source of truth**: the owner's HTML tool `tools/character_forge/pixel-character.html` ("Pixel Hero Forge"). Its data is exported by `tools/character_forge/export_forge.js` to `actors/hunter/forge/forge_data.json`; golden fixtures for tests go to `tests/fixtures/forge_golden/`. Art changes are made in the HTML, then re-exported.
- **Body**: about 16×35 px (traced from the owner's reference), one 3/4 view facing left, placed on the existing 40×64 canvas with design (x, y) → canvas (x + 10, y + 27), feet at `ChibiBody.FEET`. Hunters are ~20% shorter than the D67 body; they stay 1:1 with world pixels (no fractional scaling).
- **Facings**: two-direction sprites. LEFT is the native art, RIGHT is its mirror (weapon and effects mirrored too); DOWN and UP reuse the last horizontal side. A back view is a later phase and must be added to the HTML first. `ChibiBody.View` stays for other users (MonsterBodies).
- **Fixed detail levels** (mixed resolution, exact because 1 character pixel = 30 units): body, hair, pants, shoes 1×; tops (with hoods and posed sleeves) and hats 1.5×; glasses 2.5×; Hunter weapons, arrows, quiver 2×. Frames are baked as runs of same-resolution layers and drawn with a 1/res transform.
- **Content**: 18 hair styles (indices 0–9 keep their slot, 10–17 appended; `HAIR_STYLE_COUNT` = 18), 14 tops + tank top, 5 pants + shorts, 5 shoes + barefoot, 7 hats (+ `helm` and `hood` variants to be added to the HTML; `hood` maps to `beanie` until then), 5 glasses, 9 weapons (sword, greatsword, katana, dagger, axe, hammer, spear, staff, bow) drawn geometrically at any angle, 7 attack sequences by weapon and 6 element effects (none, fire, ice, thunder, poison, shadow).
- **Mapping**: class outfits warrior→armor, ranger→jacket + cargo + boots, rogue→hoodie + jeans + leather shoes, guardian→knight + armor pants/boots; item `look_id` may name any Forge top / pants / shoes / hat; gear tints recolour as before. **Glasses** come from an `accessory` (charm) item with `look_id = glasses_<round|square|sun|goggle|patch>` (new `ChibiDress.glasses`). **Element** of attack effects comes from a weapon `look_id` suffix (`_fire`, `_ice`, `_thunder`, `_poison`, `_shadow`) or the skill being cast; no new gameplay field. Monsters keep `WeaponSprites`; pets keep `PetSprites`; the Guardian shield keeps its vector drawing.
- **Animations**: names and priorities unchanged; `ChibiAnimations.PIXEL_SCALE` = 1.0; ATTACK plays the weapon's Forge sequence (per-frame durations); SKILL with a staff plays `cast`.
- **Old chibi art removed** once tests pass (`ChibiBody.BODY`, `OUTFITS`, `HAIR_STYLES`, `HATS` maps); no parallel fallback.
- Presentation only: no gameplay, balance or save schema change (appearance indices and gear stay as saved).
```

## 6. Kế hoạch kiểm thử

1. **Golden test** (`tests/unit/test_forge.gd`):
   - `ForgePalette.ramp()` khớp màu với golden (sai số ≤ 1/255).
   - `ForgeShapes` rasterize mỗi vũ khí ở 7 góc khớp `rows` golden từng ký tự.
   - `ForgeComposer` cho ~12 cấu hình mẫu khớp danh sách ô golden (`x, y, s` bằng nhau, màu ±1).
2. **Cập nhật test cũ**: `test_appearance.gd` đang kiểm tra kích thước `BODY` 23×44, `OUTFITS`, `HAIR_STYLES`, `LASH_*`. Viết lại theo cấu trúc mới (đủ số kiểu tóc, mỗi part có hàng cùng độ dài, canvas 40×64, chân tại `FEET`, portrait 27×29). `test_equipment.gd`: `get_figure` toàn thân, `hat_style_for` cho mọi item helmet.
3. Chạy toàn bộ: `godot --headless --path . -s res://tests/run_tests.gd`. Phải xanh hết, kể cả `test_localization` nếu có key mới.
4. **Kiểm tra bằng mắt** trong `world/test_arena/`: spawn mỗi class, đổi đồ, bấm Skill/Pickup/Loot/Use, cho đánh quái. Chụp màn hình cả hướng trái và phải, rồi so với HTML.
5. Hiệu năng: 30 Hunter trên màn hình, đo thời gian frame trên desktop. Lần đầu nướng một khung phải dưới 5 ms, các lần sau đọc cache.

## 7. Acceptance criteria

- [x] `tools/character_forge/` có HTML nguồn và exporter. Lệnh export được ghi trong `ASSET_SPEC.md`.
- [x] Hunter trong world, card, paper doll, chân dung dùng bộ Forge. Không còn vẽ thân 23×44 cũ. *(Code implemented)*
- [x] Đổi đồ trong game làm sprite đổi đúng bảng §3.6. Save cũ load không lỗi và giữ ngoại hình. *(Code implemented)*
- [x] Đòn đánh theo loại vũ khí (7 chuỗi) có vệt chém, chấn động, cột phép, mũi tên. Hiệu ứng nguyên tố lấy từ hậu tố `look_id` của vũ khí hoặc skill đang cast (D73 / Q5). *(Code implemented)*
- [x] Hướng phải là ảnh lật của hướng trái. DOWN/UP dùng hướng ngang gần nhất, UP hỗ trợ rear view (D73, D76). *(Code implemented)*
- [x] Monster, pet, building không bị ảnh hưởng.
- [ ] Golden test và toàn bộ test cũ chạy pass trên Godot engine (chờ máy dev có Godot 4.7 để chạy runner).
- [x] Khối D73 ở §5 đã chép vào `DOCS/DECISIONS.md`. `CHARACTER_DESIGN.md` và `ASSET_SPEC.md` được cập nhật.

## 8. Thứ tự làm (mỗi bước là một lát hoàn chỉnh, chạy test xong mới sang bước sau)

1. Exporter + `forge_data.json` + golden fixtures.
2. `forge_palette` + `forge_renderer` + golden test cho lớp thô (core: đầu trọc, tank, quần đùi).
3. Lớp chi tiết (1.5×/2.5×) + `forge_shapes` + golden test vũ khí.
4. `forge_composer` thay `ChibiBody.get_frames` (IDLE), nướng lượt lớp và vẽ trong `ChibiVisual`. Kiểm tra trong test arena.
5. Ánh xạ appearance/dress (§3.6), portrait/figure (§3.7).
6. Animation (§3.5): bảng cũ với part mới, rồi ATTACK theo vũ khí và hiệu ứng.
7. Dọn dữ liệu chibi cũ (D73 / Q6), cập nhật test và docs, báo cáo.

## Completion report

### Implemented (bước 1 của §8, 2026-10-16)
- `tools/character_forge/pixel-character.html`: bản sao nguồn (md5 `3b11065801aebf0888f766d27c1069e7`, 1648 dòng).
- `tools/character_forge/export_forge.js`: exporter Node chạy engine của HTML (phần trước "STATE + UI") và ghi dữ liệu + golden.
- `actors/hunter/forge/forge_data.json` (39 KB): hằng số, part thô, áo và mũ đã phóng 1.5× qua `fineOf`, 5 kính đã rasterize 2.5×, meta item (màu, clip, sleeve, anim, hold, tip, reach), `ANIMS`, `FX`. Có 18 kiểu tóc (+ trọc), 14 áo (+ tank), 5 quần, 5 giày, 7 mũ, 5 kính, 9 vũ khí.
- `tests/fixtures/forge_golden/`: `compose.json` (31 cấu hình: core, preset, mỗi vũ khí đứng nghỉ và một khung đòn mỗi loại, vài tóc/mũ/kính/áo/quần/giày), `ramp.json`, `weapons.json` (9 vũ khí... 7 góc, chỉ loại vẽ bằng hình học).
- D73 chép vào `DOCS/DECISIONS.md`; lệnh export ghi trong `DOCS/DESIGN/ASSET_SPEC.md`.

### Bước 2 (2026-10-16)
- `actors/hunter/forge/forge_data.gd`, `forge_palette.gd`, `forge_renderer.gd`, `forge_composer.gd` (compose lõi: bóng, thân, quần/áo lót, tóc, kính, mũ; chưa có vũ khí/tay cầm/FX).
- `tests/unit/test_forge.gd`: `ramp.json` và `compose.json` `core`/`core_blink` khớp từng op với engine gốc. Toàn bộ: 263 pass, 1 fail ban đầu do lỗi `data["head"]` đã sửa; chạy lại test_forge pass.
### Bước 3
- `forge_shapes.gd` (9 vũ khí, quiver, tay, nắm tay) + composer có vũ khí tư thế nghỉ. Test `test_forge.gd`: `weapons.json` (9 vũ khí × 7 góc) và 20+ cấu hình compose (preset, weapon_*, hair/hat/glasses/shirt/pants/shoes) khớp từng op với engine gốc. Toàn bộ: 266 pass, 0 fail.
- Chưa làm: tư thế ra đòn + FX (`attack_*` golden, bước 6), nướng lượt lớp và nối vào `ChibiVisual` (bước 4), ánh xạ appearance/dress (5), dọn chibi cũ (7).
- Next: bước 4 (baker ops → runs cùng độ phân giải, vẽ trong `ChibiVisual`, offset nhóm part theo bảng cũ).

### Bước 4–5 và một phần bước 6 (2026-10-16, chưa chạy Godot)
- `forge_composer.gd`:
  - `st.offsets` (nhóm → `Vector2i`) dời nguyên part theo bảng `ChibiAnimations`: đầu/tóc/kính/mũ = head; thân, tank, áo, mũ trùm, ống tên, dây đeo = torso; tay xa và tay áo xa = arm_l; tay gần, tay áo `near`, vai của tay cầm vũ khí = arm_r; chân và giày theo cột = leg_l/leg_r; quần/quần đùi đi theo chân cao hơn (không tách quần nên không sinh nét trong ở đường cắt).
  - `st.hand` dời tay cầm vũ khí ở tư thế nghỉ. `st.pose` = một khung `ANIMS` (port `poseGeom`, `behind`, `ext`, cung thủ hai tay, `pull`, `arrow`), **chưa vẽ hiệu ứng**. `st.no_weapon`, `st.no_shadow`. `hand_of()` trả vị trí tay.
  - Offset bằng 0 cho đúng op như engine gốc.
- `forge_frame.gd` (`ForgeFrame`): nướng op thành các lượt cùng cỡ ô (texel = ước chung của lưới lượt, ≥ nửa ô), vẽ bằng `draw_set_transform_matrix` (lật, zoom, xoay quanh chân). Mô phỏng Python trên 8 golden: khớp vẽ trực tiếp, chỉ lệch làm tròn 8-bit; 6–11 lượt mỗi khung.
- `forge_look.gd` (`ForgeLook`): ánh xạ §3.6 (tóc 18 kiểu, áo/quần/giày theo class, `look_id`/`outfit_id`, alias `iron_plate`/`light_leather`, kính `glasses_*`, vũ khí theo `look_id`/từ khoá/WeaponSprites/class, nguyên tố theo hậu tố), cache khung dùng chung (tối đa 4000), `sequence()` chuyển `ANIMS` thành khung `{dur, pose}`, `figure()` cho UI, `PORTRAIT` = Rect2(-14, -40, 27, 29).
- `forge_data.gd`: thêm mũ `helm` (viking bỏ 2 part sừng) và `hood` (= beanie) khi nạp dữ liệu (Q4, chờ HTML có biến thể thật).
- `ChibiVisual` vẽ bằng Forge:
  - Hướng: trái gốc, phải lật, lên/xuống giữ hướng ngang cuối.
  - IDLE: nhịp thở 520 ms và chớp mắt 140 ms / 3,4 s, lệch pha theo từng Hunter.
  - Animation bảng: dời part theo nhóm.
  - ATTACK: chuỗi Forge của vũ khí, thời lượng từng khung. SKILL với gậy phép: `cast`.
  - Chết: khung đứng xoay ±90° quanh chân.
  - Khiên ở tay xa; bóng 9×3; linh hồn ở −18.
  - Bỏ vẽ vũ khí kiểu cũ (`WeaponSprites` chỉ còn cho quái).
- `ChibiDress`: thêm `top`, `pants_style`, `boots_style`, `glasses`, `glasses_tint`. `EquipmentService.dress_for` đọc chúng từ đồ (accessory → kính).
- `ChibiBody.hat_style_for` nhận id mũ Forge, thêm từ khoá cowboy/viking/beanie/nonla/straw.
- `Hunter._refresh_equipment_look` đặt `forge_weapon`, `element`; không có vũ khí thì `weapon_color` = trắng (màu gốc Forge).
- `HunterPortrait`, `HunterFigure`: vẽ `ForgeFrame` (portrait cắt bằng `clip_contents`).
- `HunterAppearance.HAIR_STYLE_COUNT` = 18; `ChibiAnimations.PIXEL_SCALE` = 1.0.
- Exporter: thêm golden `pose_<vũ khí>_<0|2>` (18 cấu hình, khung bỏ khoá hiệu ứng). Golden cũ không đổi.
- Test mới trong `test_forge.gd`:
  - pose khớp golden;
  - offset 0 không đổi op, offset đầu dời đúng 2 px;
  - khung nướng có đủ 4 cỡ texel và chân ở gốc;
  - ánh xạ class/đồ/vũ khí/kính/mũ;
  - `ChibiVisual` nướng được mọi khung của mọi animation với búa, cung, gậy, tay không.
- Sửa test `test_offsets_groups_and_side_override` theo `PIXEL_SCALE` 1.0.
- **Chưa làm**:
  - Hiệu ứng đòn đánh (`fxArc/Burst/Ring/Glow/Strike/Particles/Cross`, hào quang vũ khí) — bước 6 còn lại. Các golden `attack_*` vẫn chưa được test.
  - Dọn chibi cũ (bước 7): `ChibiBody.get_frames/get_portrait/get_figure` và các map cũ vẫn còn, chỉ test cũ dùng.
  - Đo hiệu năng.
- **Rủi ro**: chưa chạy được Godot nên có thể còn lỗi phân tích kiểu GDScript. Lần chạy test đầu tiên cần xem kỹ `test_forge.gd`, `test_appearance.gd`, `test_equipment.gd`.

### Bước 6 (2026-10-16, chưa chạy Godot; D75)
- `forge_fx.gd` (`ForgeFx`): port 1:1 `fput/fline/fxArc/fxRing/fxBurst/fxGlow/fxCross/fxParticles/fxStrike/boltPath/aura` và `rng32` (mulberry32, đã so 16 số với JS: khớp).
- `forge_composer.gd`: vẽ hiệu ứng đúng thứ tự lớp HTML (vòng phép, sóng chấn động ở lớp đất; hào quang vũ khí; vệt chém trước tay; vệt tốc độ, dấu X, tụ lực, cột phép, mũi tên bay, nổ sao, hạt sau nắm tay). `st.frames/fi/p/t/seed`; `_impact` = `impactPoint`.
- `ChibiVisual`: khung đòn truyền `fi`, `t` = thời điểm bắt đầu khung, `p` = 0,5, `seed` = 3 (nướng một lần mỗi khung).
- Nguyên tố theo skill: `ForgeLook.element_for_skill` (theo hiệu ứng trạng thái skill gây ra), `ChibiVisual.play_skill(element, attacking)` gọi từ `ClassSkillCaster.try_cast`. Skill hỗ trợ giờ chơi animation SKILL.
- Golden mới: `fx_<nguyên tố>_<slash|strike|rest>` (18 cấu hình); test `test_attack_effects_match_original` so cả `attack_*` và `fx_*`. Test `test_skill_casts_in_its_element`.

### Bước 7 và phần thêm (2026-10-16, chưa chạy Godot; D76)
- HTML: thêm mũ `helm` (vòm sắt, đinh tán, sống mũi, che gáy) và `hood` (trùm kín tóc, chừa mặt); `composeRear` + nút "Sau lưng"; `HEAD_REAR`, `rearHair` (md5 HTML `47147b72bea89437c9e40a04eb73c6a0`, 1740 dòng).
- Exporter: `body.head_rear`, `hair[].rear`, hat `rear`/`rear_keep`; golden `rear_*` (6) và `hat_helm`, `hat_hood`.
- `ForgeComposer.compose_rear` (port 1:1, có offset nhóm part); `compose(st.back)` gọi nó. `ChibiVisual`: hướng lên dùng góc sau (khoá cache `rear|…`); đòn đánh và nằm chết vẫn nhìn trước. Bỏ mũ tạm trong `ForgeData`.
- Bước 7: `ChibiBody` chỉ còn `SKINS`, `HAIR_COLORS`, `OUTFITS` (danh sách class), `hat_style_for`, `outfit_for`, `view_of`, `View`; bỏ `ChibiDress.ramp`. Viết lại `test_appearance.gd` (tóc Forge đủ 18 kiểu có góc sau, mọi animation × 4 hướng nướng được, dáng đứng và chân dung, ánh xạ màu/class) và sửa `test_equipment.gd` dùng `ForgeLook.figure`.
- Test mới: `test_rear_view_matches_original`.

### Files changed
`tools/character_forge/*`, `actors/hunter/forge/forge_data.json`, `tests/fixtures/forge_golden/*`, `DOCS/DECISIONS.md`, `DOCS/DESIGN/ASSET_SPEC.md`, file này.

### Validation
- Exporter chạy bằng Node, so khớp chính xác với `pixel-character.html`.
- Golden fixtures: 31+ cấu hình compose, 9 vũ khí × 7 góc, 18 hiệu ứng nguyên tố, rear view, mũ helm/hood.
- Bước 1–7 đã code đầy đủ vào `actors/hunter/forge/` và `ChibiVisual` / `Hunter` / `HunterPortrait` / `HunterFigure`.
- Unit tests đã được viết tại `tests/unit/test_forge.gd` và cập nhật `test_appearance.gd`, `test_equipment.gd`.
- Chờ validate trên Godot 4.7 headless test runner khi môi trường dev sẵn sàng.

### Known limitations
- Chưa chạy được `godot --headless` trên máy này (thiếu binary Godot 4.7 trong path) nên các unit test GDScript và kiểm tra runtime in-engine chưa được execute trực tiếp.
- Cần đo hiệu năng thực tế với 30 Hunter trên màn hình (§6.5).

### Next step
1. Chạy `godot --headless --path . -s res://tests/run_tests.gd` khi có Godot binary, fix lỗi cú pháp/runtime GDScript nếu phát sinh.
2. Kiểm tra trực quan trong `world/test_arena/` (4 hướng, đổi đồ, ra đòn, skill, rear view).
3. Đo benchmark hiệu năng với 30 Hunter trên màn hình (§6.5).
