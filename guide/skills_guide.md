# Hunter Skill Guide (class skill)

Bản markdown song song với `skills_guide.html`. Số liệu khớp với dữ liệu trong game (`data/class_skills`). Luật hệ thống: `DOCS/SYSTEMS/CLASS_SKILL_SYSTEM.md`, quyết định D69 và D70.

## Luật chính

| Luật | Giá trị |
|---|---|
| Skill mỗi class | 30 (18 thi triển, 12 nội tại) |
| Skill tối đa mỗi Hunter | 7, mở ngẫu nhiên |
| Điểm skill | 1 điểm mỗi 10 cấp Hunter (10, 20 … 100) |
| Dùng 1 điểm | mở 1 skill ngẫu nhiên chưa có (cấp 1) hoặc nâng 1 skill lên 1 cấp |
| Cấp skill | 1 đến 6; sức mạnh = 1 + 0.15 × (cấp − 1), cấp 6 = ×1.75 |
| Thời lượng hiệu ứng từ skill | buff × sức mạnh; debuff nhận một nửa phần tăng (cấp 6: buff ×1.75, debuff ×1.375) |
| Mana | tối đa 100 + 2 mỗi cấp Hunter; hồi 5/giây, ×3 khi không đánh nhau |
| Giá mana skill thi triển | 8 + 1.5 × hồi chiêu ở cấp 1, +6% mỗi cấp skill |
| Nội tại tự kích hoạt | có hồi chiêu, không tốn mana |
| Chuyển sinh | cấp 100, về cấp 1, giữ nguyên skill và cấp skill, +1 điểm đổi skill (lưu theo từng Hunter) |
| Đổi skill | 1 điểm đổi: thay 1 skill bằng 1 skill ngẫu nhiên chưa có, giữ nguyên ô và cấp |
| Boss | Choáng, Đóng Băng, Trói, Tước Vũ Khí thành Loạng Choạng (+10% sát thương nhận, 2 giây); debuff mềm còn nửa thời gian; Chảy Máu ×0.25; ngưỡng kết liễu 15% |
| Trần chỉ số | né tránh 40%, kháng khống chế 70% |

> **Chưa đạt được cấp 100:** Town Hall hiện tối đa cấp 5 nên Hunter chỉ lên tới cấp 50. Cần thêm Town Hall cấp 6–10 để chuyển sinh.

## Cách đọc bảng

- **Loại:** Thi triển tốn mana; Nội tại luôn có tác dụng; Nội tại (tự kích) có hồi chiêu và không tốn mana.
- **Sao** theo thứ tự 🐺 Quái · ⚔️ Người · 👑 Boss, từ 1 đến 3.
- **Cấp 1 / Cấp 6:** số liệu thực tế trong game ở cấp skill 1 và 6, kèm thời lượng hiệu ứng (giây).
- **Ghi chú cài đặt:** chỗ bản cài đặt đơn giản hoá so với thiết kế ban đầu.

## 🗡️ Warrior · Chiến Binh

| # | Skill | Loại | Scale | Hồi chiêu · Mana (cấp 1→6) | Cấp 1 | Cấp 6 | Sao | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| 1 | **Chém Mạnh** (Heavy Slash)<br>Một nhát chém nặng vào mục tiêu. | Thi triển | ATK | 6s · 17→22 | ST 160% ATK | ST 280% ATK | 2·2·3 | Một hit lớn nên ít bị DEF boss ăn mòn. |
| 2 | **Xoáy Kiếm** (Whirlwind)<br>Xoay kiếm đánh mọi kẻ địch xung quanh. | Thi triển | ATK | 10s · 23→30 | ST 110% ATK; AoE quanh mình 40px | ST 192.5% ATK; AoE quanh mình 40px | 3·1·1 | Công cụ dọn bầy quái chính của Warrior. |
| 3 | **Tiếng Gầm Chiến Trận** (Battle Cry)<br>Bản thân và đồng đội gần đó nhận Cường Lực. | Thi triển | LV | 20s · 38→49 | đồng đội quanh mình: Cường Lực 8s | đồng đội quanh mình: Cường Lực 14s | 2·2·2 |  |
| 4 | **Đâm Xuyên** (Pierce)<br>Đâm xuyên, phá giáp các mục tiêu trúng đòn. | Thi triển | ATK | 10s · 23→30 | ST 140% ATK; AoE quanh mục tiêu 24px; gây Phá Giáp 6s | ST 245% ATK; AoE quanh mục tiêu 24px; gây Phá Giáp 8.2s | 2·2·3 | Boss: Phá Giáp còn nửa thời gian. Skill mở boss tốt nhất của Warrior. |
| 5 | **Vai Húc** (Shoulder Bash)<br>Húc vai làm choáng mục tiêu, mạnh theo thể lực. | Thi triển | HP | 12s · 26→34 | ST 50% ATK + 6% HP tối đa; gây Choáng 1.5s | ST 87.5% ATK + 10.5% HP tối đa; gây Choáng 2.1s | 2·3·1 | Boss: Stagger thay choáng. Đấu Trường (thiết kế): choáng 0.6s. |
| 6 | **Phản Đòn** (Riposte)<br>Vào thế thủ, phản lại sát thương nhận vào. | Thi triển | ATK | 14s · 29→38 | bản thân: Phản Đòn 8s | bản thân: Phản Đòn 14s | 2·2·2 | Phản đòn = hiệu ứng Phản Đòn. |
| 7 | **Vết Chém Chảy Máu** (Rend)<br>Chém gây chảy máu. | Thi triển | ATK | 8s · 20→26 | ST 80% ATK; gây Chảy Máu ×2 5s | ST 140% ATK; gây Chảy Máu ×2 6.9s | 2·2·2 | Boss: Chảy Máu chỉ gây 25% sát thương. |
| 8 | **Nhảy Chém** (Leap Strike)<br>Nhảy tới mục tiêu ở xa, càng nhanh càng đau. | Thi triển | MSPD | 11s · 24→31 | ST (140% ATK) × Tốc chạy/gốc; tầm thi triển 80px | ST (245% ATK) × Tốc chạy/gốc; tầm thi triển 80px | 2·3·1 | Không di chuyển Hunter, chỉ giữ sát thương. Áp sát Ranger hoặc pháp sư ở Đấu Trường. |
| 9 | **Cuồng Nộ** (Berserk)<br>Đánh nhanh và mạnh hơn trong một lúc. | Thi triển | ASPD | 25s · 46→60 | bản thân: Tăng Tốc 6s, Cường Lực 8s | bản thân: Tăng Tốc 10.5s, Cường Lực 14s | 3·2·3 |  |
| 10 | **Kiếm Khí** (Sword Wave)<br>Phóng sóng kiếm bay xa, trúng cả nhóm quanh mục tiêu. | Thi triển | RANGE | 7s · 18→23 | ST 120% ATK; AoE quanh mục tiêu 20px; tầm thi triển 60px | ST 210% ATK; AoE quanh mục tiêu 20px; tầm thi triển 60px | 2·2·1 |  |
| 11 | **Tử Chiến** (Last Stand)<br>Khi máu dưới 30%: hồi máu và cứng cáp lại. | Thi triển | HP | 60s · 98→127 | hồi 20% HP tối đa (bản thân); bản thân: Kiên Cố 8s; kích hoạt khi HP dưới 30% | hồi 35% HP tối đa (bản thân); bản thân: Kiên Cố 14s; kích hoạt khi HP dưới 30% | 2·3·3 | Đấu Trường (thiết kế): hồi ×0.7. |
| 12 | **Chém Liên Hoàn** (Triple Slash)<br>Ba nhát chém liên tiếp, mỗi nhát chí mạng riêng. | Thi triển | CRIT | 8s · 20→26 | ST 3 × 65% ATK; +15% chí mạng | ST 3 × 113.8% ATK; +15% chí mạng | 2·2·1 | 3 hit nhỏ, yếu khi gặp DEF cao. |
| 13 | **Đòn Kết Liễu** (Execute)<br>Đòn kết liễu, cực mạnh với mục tiêu yếu máu. | Thi triển | CRITDMG | 15s · 30→39 | ST 180% ATK; +30% ST chí mạng; mục tiêu dưới 25% HP: ×1.5 (boss 15%) | ST 315% ATK; +30% ST chí mạng; mục tiêu dưới 25% HP: ×1.5 (boss 15%) | 3·3·2 | Boss: ngưỡng 15% HP. |
| 14 | **Thế Thép** (Iron Stance)<br>Trụ vững, tăng mạnh phòng thủ. | Thi triển | DEF | 18s · 35→46 | bản thân: Kiên Cố 8s | bản thân: Kiên Cố 14s | 2·2·3 |  |
| 15 | **Đập Đất** (Ground Slam)<br>Đập kiếm xuống đất, làm chậm kẻ địch xung quanh. | Thi triển | DEF | 12s · 26→34 | ST 70% ATK + 60% DEF; AoE quanh mình 40px; gây Làm Chậm 4s | ST 122.5% ATK + 105% DEF; AoE quanh mình 40px; gây Làm Chậm 5.5s | 3·2·1 |  |
| 16 | **Khiêu Khích** (Taunt)<br>Ép kẻ địch gần đó đánh mình và cứng cáp lại. | Thi triển | HP | 16s · 32→42 | khiêu khích địch trong 80px; bản thân: Kiên Cố 8s | khiêu khích địch trong 80px; bản thân: Kiên Cố 14s | 3·2·2 | Khiêu khích + Kiên Cố. Kẻ địch đổi mục tiêu sang Hunter và giữ đến khi tự đổi. Đấu Trường (thiết kế): ×0.5. |
| 17 | **Hồi Sức** (Second Wind)<br>Lấy lại hơi thở khi máu dưới 60%. | Thi triển | HP | 30s · 53→69 | hồi 5% HP tối đa (bản thân); bản thân: Hồi Máu 8s; kích hoạt khi HP dưới 60% | hồi 8.8% HP tối đa (bản thân); bản thân: Hồi Máu 14s; kích hoạt khi HP dưới 60% | 2·2·3 |  |
| 18 | **Bão Kiếm** (Blade Storm)<br>Múa kiếm đánh liên tục mọi kẻ địch quanh mình. | Thi triển | ASPD | 20s · 38→49 | ST 5 × 55% ATK (+1 hit mỗi 0.25 Tốc đánh trên 1.0, tối đa 9); AoE quanh mình 40px | ST 5 × 96.3% ATK (+1 hit mỗi 0.25 Tốc đánh trên 1.0, tối đa 9); AoE quanh mình 40px | 3·1·1 | Nhiều hit nhỏ: rất mạnh với bầy, yếu với boss. |
| 19 | **Da Thép** (Thick Skin)<br>Thân thể dày dạn. | Nội tại | DEF | — | +8% DEF; +5% HP tối đa | +14% DEF; +8.8% HP tối đa | 2·2·2 |  |
| 20 | **Khát Máu** (Bloodlust)<br>Hăng máu khi xông trận. | Nội tại | ATK | — | +6% ATK | +10.5% ATK | 3·1·1 | Cộng phẳng, không đếm số địch. |
| 21 | **Ý Chí Sắt** (Iron Will)<br>Khó bị khống chế, càng già dặn càng vững. | Nội tại | LV | — | +30% kháng khống chế; +0.5% kháng khống chế mỗi 1 cấp Hunter (tối đa 40 lần) | +52.5% kháng khống chế; +0.9% kháng khống chế mỗi 1 cấp Hunter (tối đa 40 lần) | 1·3·2 |  |
| 22 | **Kiếm Thuật** (Swordsmanship)<br>Thành thạo kiếm. | Nội tại | ATK | — | +8% ATK | +14% ATK | 2·2·2 |  |
| 23 | **Dày Dạn** (Veteran)<br>Kinh nghiệm chiến trường theo cấp. | Nội tại | LV | — | +1% sát thương mỗi 3 cấp Hunter (tối đa 15 lần) | +1.8% sát thương mỗi 3 cấp Hunter (tối đa 15 lần) | 2·2·2 |  |
| 24 | **Hồi Phục Chiến Trường** (Battle Regen)<br>Hạ địch thì hồi máu. | Nội tại | HP | — | hồi 3% HP tối đa mỗi lần hạ địch | hồi 5.2% HP tối đa mỗi lần hạ địch | 3·1·1 | Vô dụng khi chỉ có một boss. |
| 25 | **Phản Kích** (Retaliation)<br>Bị dồn ép thì đánh mạnh hơn. | Nội tại | ATK | — | +10% sát thương khi HP dưới 50% | +17.5% sát thương khi HP dưới 50% | 2·2·2 | Mạnh hơn khi HP dưới 50%. |
| 26 | **Kẻ Diệt Khổng Lồ** (Giant Slayer)<br>Càng to càng dễ trúng chỗ hiểm. | Nội tại | ATK | — | +12% sát thương với boss | +21% sát thương với boss | 1·2·3 | Thay Steadfast (trùng Iron Will). Trong PvP có tác dụng với Guardian. |
| 27 | **Đòn Nặng** (Heavy Crit)<br>Chí mạng nặng tay. | Nội tại | CRITDMG | — | +3% Chí mạng; +30% ST chí mạng | +5.2% Chí mạng; +52.5% ST chí mạng | 2·2·2 | Warrior chỉ có 5% CRIT gốc nên cần thêm tỷ lệ. |
| 28 | **Bất Khuất** (Unyielding)<br>Khi sắp gục: bất tử chốc lát và hồi máu. | Nội tại (tự kích) | HP | 90s | hồi 10% HP tối đa (bản thân); bản thân: Bất Tử 2s; kích hoạt khi HP dưới 15% | hồi 17.5% HP tối đa (bản thân); bản thân: Bất Tử 3.5s; kích hoạt khi HP dưới 15% | 2·3·3 |  |
| 29 | **Máu Nóng** (Hot Blood)<br>Càng mất máu càng mạnh. | Nội tại | ATK | — | +15% ATK khi HP dưới 50% | +26.2% ATK khi HP dưới 50% | 2·2·3 |  |
| 30 | **Đấu Sĩ** (Gladiator)<br>Sinh ra để đấu với người. | Nội tại | ATK | — | +12% sát thương với người; -10% sát thương nhận với người | +21% sát thương với người; -17.5% sát thương nhận với người | 1·3·1 | Thay Vanguard để Warrior có lựa chọn PvP. |

## 🏹 Ranger · Cung Thủ

| # | Skill | Loại | Scale | Hồi chiêu · Mana (cấp 1→6) | Cấp 1 | Cấp 6 | Sao | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| 1 | **Mũi Tên Xuyên** (Piercing Arrow)<br>Mũi tên xuyên qua nhóm kẻ địch. | Thi triển | ATK | 8s · 20→26 | ST 170% ATK; AoE quanh mục tiêu 24px | ST 297.5% ATK; AoE quanh mục tiêu 24px | 3·2·2 |  |
| 2 | **Mưa Tên** (Arrow Rain)<br>Tên rơi như mưa xuống vùng mục tiêu. | Thi triển | ASPD | 14s · 29→38 | ST 6 × 45% ATK (+1 hit mỗi 0.25 Tốc đánh trên 1.0, tối đa 10); AoE quanh mục tiêu 36px | ST 6 × 78.8% ATK (+1 hit mỗi 0.25 Tốc đánh trên 1.0, tối đa 10); AoE quanh mục tiêu 36px | 3·1·1 | Mỗi mũi trừ DEF riêng, yếu với boss tuần. |
| 3 | **Bắn Nhanh** (Rapid Fire)<br>Bắn liên tiếp nhiều mũi tên. | Thi triển | ASPD | 10s · 23→30 | ST 5 × 55% ATK (+1 hit mỗi 0.25 Tốc đánh trên 1.0, tối đa 7) | ST 5 × 96.3% ATK (+1 hit mỗi 0.25 Tốc đánh trên 1.0, tối đa 7) | 2·2·1 |  |
| 4 | **Tên Độc** (Poison Arrow)<br>Mũi tên tẩm độc. | Thi triển | ATK | 9s · 22→29 | ST 100% ATK; gây Trúng Độc ×3 6s | ST 175% ATK; gây Trúng Độc ×3 8.2s | 2·2·3 | Poison bỏ qua DEF nên hợp đánh boss. |
| 5 | **Tên Lửa** (Fire Arrow)<br>Mũi tên thiêu đốt mục tiêu. | Thi triển | ATK | 9s · 22→29 | ST 110% ATK; gây Bỏng 4s | ST 192.5% ATK; gây Bỏng 5.5s | 2·2·3 | Bỏng giảm 10% DEF; với boss còn nửa thời gian. |
| 6 | **Tên Băng** (Frost Arrow)<br>Làm chậm, có thể đóng băng mục tiêu. | Thi triển | RANGE | 11s · 24→31 | ST 100% ATK; gây Làm Chậm 4s, Đóng Băng 2s (30%) | ST 175% ATK; gây Làm Chậm 5.5s, Đóng Băng 2.8s (30%) | 2·3·1 | Đóng băng là xác suất 30%. Boss: Frozen thành Stagger. |
| 7 | **Lùi Bước** (Disengage)<br>Lộn ra sau, tăng tốc chạy. | Thi triển | MSPD | 12s · 26→34 | bản thân: Tăng Tốc 6s | bản thân: Tăng Tốc 10.5s | 1·3·1 | Không lùi người, chỉ tăng tốc. Skill thả diều cốt lõi ở Đấu Trường. |
| 8 | **Bẫy Gấu** (Snare Trap)<br>Bẫy trói chân mục tiêu. | Thi triển | LV | 15s · 30→39 | ST 80% ATK; gây Trói Chân 3s | ST 140% ATK; gây Trói Chân 4.1s | 2·3·1 | Boss: Stagger. |
| 9 | **Bắn Tỉa** (Snipe)<br>Phát bắn tầm cực xa, rất dễ chí mạng. | Thi triển | CRIT | 16s · 32→42 | ST 260% ATK; tầm thi triển 220px; +40% chí mạng | ST 455% ATK; tầm thi triển 220px; +40% chí mạng | 1·3·3 | Một hit rất lớn, xuyên DEF boss tốt. |
| 10 | **Tên Tách** (Split Shot)<br>Mũi tên tách ra trúng cả nhóm. | Thi triển | ATK | 8s · 20→26 | ST 85% ATK; AoE quanh mục tiêu 40px | ST 148.8% ATK; AoE quanh mục tiêu 40px | 3·1·1 |  |
| 11 | **Mắt Diều Hâu** (Hawk Eye)<br>Tập trung cao độ. | Thi triển | CRIT | 20s · 38→49 | bản thân: Tập Trung 8s | bản thân: Tập Trung 14s | 2·2·3 |  |
| 12 | **Tên Nổ** (Explosive Arrow)<br>Mũi tên nổ tung, mạnh hơn khi tầm xa hơn. | Thi triển | RANGE | 13s · 28→36 | ST (120% ATK) × Tầm đánh/gốc; AoE quanh mục tiêu 30px | ST (210% ATK) × Tầm đánh/gốc; AoE quanh mục tiêu 30px | 3·1·1 |  |
| 13 | **Tên Truy Đuổi** (Homing Arrow)<br>Không thể né. | Thi triển | RANGE | 10s · 23→30 | ST 130% ATK; không thể né | ST 227.5% ATK; không thể né | 2·3·2 | Khắc chế Rogue né tránh ở Đấu Trường. |
| 14 | **Tên Hút Máu** (Leeching Arrow)<br>Mũi tên rút sinh lực. | Thi triển | HP | 12s · 26→34 | ST 110% ATK; hồi 4% HP tối đa (bản thân) | ST 192.5% ATK; hồi 7% HP tối đa (bản thân) | 2·2·2 | Đấu Trường (thiết kế): hồi ×0.7. |
| 15 | **Gọi Thú Săn** (Hunting Companion)<br>Sói săn cắn xé mục tiêu. | Thi triển | HP | 30s · 53→69 | ST 3 × 40% ATK + 2% HP tối đa; gây Chảy Máu ×2 5s | ST 3 × 70% ATK + 3.5% HP tối đa; gây Chảy Máu ×2 6.9s | 3·2·2 | Không triệu hồi sói: 3 vết cắn + Chảy Máu. Chảy Máu giữ quái mất máu liên tục. |
| 16 | **Ngắm Kỹ** (Take Aim)<br>Phát bắn chắc chắn chí mạng. | Thi triển | CRITDMG | 14s · 29→38 | ST 150% ATK; +100% chí mạng; +40% ST chí mạng | ST 262.5% ATK; +100% chí mạng; +40% ST chí mạng | 1·3·3 |  |
| 17 | **Đóng Đinh** (Pinning Shot)<br>Ghim tay kẻ địch, không thể tấn công. | Thi triển | ATK | 12s · 26→34 | ST 100% ATK; gây Tước Vũ Khí 2.5s | ST 175% ATK; gây Tước Vũ Khí 3.4s | 2·3·1 | Boss: Stagger. Đấu Trường (thiết kế): Disarmed 1.2s. |
| 18 | **Nhảy Lùi Bắn** (Backflip Shot)<br>Nhảy lùi rồi bắn, càng nhanh càng đau. | Thi triển | MSPD | 9s · 22→29 | ST (130% ATK) × Tốc chạy/gốc | ST (227.5% ATK) × Tốc chạy/gốc | 2·3·1 | Không nhảy lùi, chỉ giữ sát thương. |
| 19 | **Mắt Sắc** (Keen Sight)<br>Nhìn xa, bắn xa. | Nội tại | RANGE | — | +15% tầm đánh | +26.2% tầm đánh | 2·2·2 |  |
| 20 | **Ống Tên Nhẹ** (Quiver Mastery)<br>Rút tên nhanh. | Nội tại | ASPD | — | +8% Tốc đánh | +14% Tốc đánh | 2·2·2 |  |
| 21 | **Điểm Yếu** (Weak Spot)<br>Nhắm vào chỗ hiểm. | Nội tại | CRIT | — | +5% Chí mạng | +8.8% Chí mạng | 2·2·2 |  |
| 22 | **Bắn Xa** (Long Shot)<br>Khoảng cách là bạn. | Nội tại | RANGE | — | +8% sát thương | +14% sát thương | 2·2·2 | Cộng phẳng, không tính khoảng cách. |
| 23 | **Chân Nhẹ** (Light Feet)<br>Chạy nhanh, bắn khi chạy. | Nội tại | MSPD | — | +10% Tốc chạy; +3% sát thương | +17.5% Tốc chạy; +5.2% sát thương | 2·2·1 |  |
| 24 | **Hai Mũi Tên** (Double Nock)<br>Lắp hai mũi tên một lúc. | Nội tại | ASPD | — | +10% Tốc đánh | +17.5% Tốc đánh | 3·2·1 | Thành tốc đánh, không bắn thêm mũi. |
| 25 | **Thợ Săn Thú** (Beast Tracker)<br>Khắc tinh thú rừng. | Nội tại | ATK | — | +15% sát thương với thú | +26.2% sát thương với thú | 3·1·1 |  |
| 26 | **Bình Tĩnh** (Composure)<br>Đầu lạnh khi còn khoẻ. | Nội tại | CRITDMG | — | +25% ST chí mạng khi HP trên 70% | +43.8% ST chí mạng khi HP trên 70% | 2·1·2 | Đấu Trường (thiết kế): Ranger hay bị áp sát nên khó giữ trên 70%. |
| 27 | **Né Tránh** (Evasion)<br>Né đòn. | Nội tại | MSPD | — | +6% né tránh | +10.5% né tránh | 2·3·2 |  |
| 28 | **Người Hái Lượm** (Forager)<br>Nhặt được nhiều vàng hơn. | Nội tại | GOLD | — | +10% Tìm vàng | +17.5% Tìm vàng | 3·1·1 | Đấu Trường (thiết kế): không tác dụng. |
| 29 | **Tên Tẩm** (Coated Arrows)<br>Đòn thường đôi khi gây độc. | Nội tại | ATK | — | đòn thường: Trúng Độc (12%) | đòn thường: Trúng Độc (21%) | 2·2·3 |  |
| 30 | **Dấu Thợ Săn** (Hunter's Mark)<br>Đánh dấu con mồi, cả đội đánh đau hơn. | Nội tại | CRIT | — | đòn thường: Dễ Tổn Thương (20%) | đòn thường: Dễ Tổn Thương (35%) | 1·2·3 | Passive boss chính của Ranger, có lợi cho cả đội. |

## 🔪 Rogue · Đạo Tặc

| # | Skill | Loại | Scale | Hồi chiêu · Mana (cấp 1→6) | Cấp 1 | Cấp 6 | Sao | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| 1 | **Đâm Lén** (Backstab)<br>Đâm vào chỗ hiểm, rất dễ chí mạng. | Thi triển | CRIT | 8s · 20→26 | ST 140% ATK; +50% chí mạng | ST 245% ATK; +50% chí mạng | 2·3·2 | Không kiểm tra sau lưng; hợp với Kẻ Rình Rập. Boss thường nhắm tank nên Rogue gần như luôn đâm lén được. |
| 2 | **Tàng Hình** (Vanish)<br>Biến mất trong chốc lát rồi ra đòn chí tử. | Thi triển | CRITDMG | 22s · 41→53 | bản thân: Bất Tử 2s, Tập Trung 8s | bản thân: Bất Tử 3.5s, Tập Trung 14s | 1·3·2 | Tàng hình = Bất Tử + Tập Trung. Đấu Trường (thiết kế): tàng hình 1.5s. |
| 3 | **Mưa Dao** (Fan of Knives)<br>Ném dao ra mọi hướng. | Thi triển | ASPD | 10s · 23→30 | ST 70% ATK (+1 hit mỗi 0.25 Tốc đánh trên 1.0, tối đa 3); AoE quanh mình 45px; gây Chảy Máu 5s | ST 122.5% ATK (+1 hit mỗi 0.25 Tốc đánh trên 1.0, tối đa 3); AoE quanh mình 45px; gây Chảy Máu 6.9s | 3·1·1 |  |
| 4 | **Lưỡi Độc** (Envenom)<br>Dao tẩm độc nặng. | Thi triển | ATK | 18s · 35→46 | ST 60% ATK; gây Trúng Độc ×3 6s | ST 105% ATK; gây Trúng Độc ×3 8.2s | 2·2·3 | Một phát độc 3 stack, không tẩm độc đòn thường. Bỏ qua DEF, rất bền khi đánh boss. |
| 5 | **Bước Bóng** (Shadow Step)<br>Lướt tới mục tiêu và đâm, càng nhanh càng đau. | Thi triển | MSPD | 9s · 22→29 | ST (120% ATK) × Tốc chạy/gốc; tầm thi triển 90px | ST (210% ATK) × Tốc chạy/gốc; tầm thi triển 90px | 2·3·1 | Không dịch chuyển, chỉ giữ sát thương. |
| 6 | **Cắt Gân** (Hamstring)<br>Chém gân làm chậm. | Thi triển | ATK | 10s · 23→30 | ST 90% ATK; gây Làm Chậm 4s | ST 157.5% ATK; gây Làm Chậm 5.5s | 2·3·1 |  |
| 7 | **Moi Ruột** (Eviscerate)<br>Đòn kết thúc, mạnh theo vết chảy máu. | Thi triển | CRITDMG | 12s · 26→34 | ST 120% ATK; +30% ST chí mạng; +30% ATK mỗi stack Chảy Máu | ST 210% ATK; +30% ST chí mạng; +52.5% ATK mỗi stack Chảy Máu | 2·3·3 |  |
| 8 | **Bom Khói** (Smoke Bomb)<br>Khói làm kẻ địch xung quanh không thể tấn công. | Thi triển | LV | 20s · 38→49 | AoE quanh mình 60px; gây Tước Vũ Khí 2.5s | AoE quanh mình 60px; gây Tước Vũ Khí 3.4s | 2·3·1 | Boss: Stagger. |
| 9 | **Kết Liễu Bóng Tối** (Shadow Execute)<br>Kết liễu mục tiêu yếu máu; hạ được thì hồi chiêu. | Thi triển | CRIT | 14s · 29→38 | ST 100% ATK; mục tiêu dưới 30% HP: ×2.2 (boss 15%); hạ được thì hồi chiêu (trừ boss) | ST 175% ATK; mục tiêu dưới 30% HP: ×2.2 (boss 15%); hạ được thì hồi chiêu (trừ boss) | 3·3·1 | Boss: ngưỡng 15%, không hồi CD. Đấu Trường (thiết kế): hạ được chỉ giảm 50% CD. |
| 10 | **Vũ Điệu Dao** (Blade Dance)<br>Chuỗi đâm liên tục. | Thi triển | ASPD | 11s · 24→31 | ST 4 × 55% ATK (+1 hit mỗi 0.25 Tốc đánh trên 1.0, tối đa 7) | ST 4 × 96.3% ATK (+1 hit mỗi 0.25 Tốc đánh trên 1.0, tối đa 7) | 3·1·1 |  |
| 11 | **Đánh Lạc Hướng** (Distract)<br>Làm mục tiêu suy yếu. | Thi triển | LV | 15s · 30→39 | gây Suy Yếu 6s | gây Suy Yếu 8.2s | 2·2·2 | Boss: Suy Yếu còn nửa thời gian. |
| 12 | **Phi Dao** (Throwing Knife)<br>Ném dao tầm xa, làm chậm. | Thi triển | RANGE | 6s · 17→22 | ST 110% ATK; tầm thi triển 72px; gây Làm Chậm 4s | ST 192.5% ATK; tầm thi triển 72px; gây Làm Chậm 5.5s | 2·2·1 |  |
| 13 | **Cướp Sức** (Steal Vigor)<br>Đánh cắp sức mạnh kẻ địch. | Thi triển | ATK | 13s · 28→36 | ST 100% ATK; gây Suy Yếu 6s; bản thân: Cường Lực 8s | ST 175% ATK; gây Suy Yếu 8.2s; bản thân: Cường Lực 14s | 2·3·2 |  |
| 14 | **Nhịp Độ** (Tempo)<br>Tăng tốc toàn thân. | Thi triển | ASPD | 18s · 35→46 | bản thân: Tăng Tốc 6s | bản thân: Tăng Tốc 10.5s | 2·2·2 |  |
| 15 | **Song Đao** (Twin Strike)<br>Hai nhát liên tiếp. | Thi triển | CRIT | 7s · 18→23 | ST 2 × 80% ATK; +10% chí mạng | ST 2 × 140% ATK; +10% chí mạng | 2·2·2 |  |
| 16 | **Hút Máu Bóng Đêm** (Night Leech)<br>Mỗi đòn hồi máu trong một lúc. | Thi triển | HP | 20s · 38→49 | bản thân: Hút Máu 8s | bản thân: Hút Máu 14s | 2·2·2 | Đấu Trường (thiết kế): trần hút máu 20%. |
| 17 | **Kích Nổ Độc** (Detonate Poison)<br>Kích nổ toàn bộ độc trên mục tiêu. | Thi triển | ATK | 12s · 26→34 | ST 20% ATK; +35% ATK mỗi stack Trúng Độc, xoá stack | ST 35% ATK; +61.2% ATK mỗi stack Trúng Độc, xoá stack | 2·2·3 |  |
| 18 | **Phản Xạ** (Reflex)<br>Lách người và đâm trả. | Thi triển | MSPD | 16s · 32→42 | bản thân: Phản Đòn 8s, Tăng Tốc 6s | bản thân: Phản Đòn 14s, Tăng Tốc 10.5s | 2·3·2 | Né mọi đòn = Phản Đòn + Tăng Tốc. |
| 19 | **Nhanh Tay** (Nimble)<br>Tay nhanh hơn mắt. | Nội tại | ASPD | — | +8% Tốc đánh | +14% Tốc đánh | 2·2·2 |  |
| 20 | **Mưu Sát** (Assassinate)<br>Đòn đầu là đòn chí tử. | Nội tại | CRITDMG | — | +40% ST chí mạng với mục tiêu trên 90% HP | +70% ST chí mạng với mục tiêu trên 90% HP | 2·3·1 |  |
| 21 | **Dao Sắc** (Honed Blades)<br>Lưỡi dao luôn sắc. | Nội tại | CRIT | — | +4% Chí mạng | +7% Chí mạng | 2·2·2 |  |
| 22 | **Bước Chân Mèo** (Catwalk)<br>Đi không tiếng động. | Nội tại | MSPD | — | +10% Tốc chạy | +17.5% Tốc chạy | 2·2·1 |  |
| 23 | **Đòn Mở Màn** (Opener)<br>Rất dễ chí mạng lên mục tiêu còn đầy máu. | Nội tại | CRIT | — | +50% Chí mạng với mục tiêu trên 90% HP | +87.5% Chí mạng với mục tiêu trên 90% HP | 3·3·1 | Chí mạng với mục tiêu trên 90% HP. |
| 24 | **Chuyên Gia Độc** (Toxicologist)<br>Đòn thường đôi khi gây độc. | Nội tại | ATK | — | đòn thường: Trúng Độc (15%) | đòn thường: Trúng Độc (26.2%) | 2·2·3 | Đòn thường gây độc thay vì tăng sát thương độc. |
| 25 | **Thoát Hiểm** (Escape Artist)<br>Nguy kịch thì tăng tốc và cứng cáp. | Nội tại (tự kích) | HP | 90s | bản thân: Tăng Tốc 6s, Kiên Cố 8s; kích hoạt khi HP dưới 25% | bản thân: Tăng Tốc 10.5s, Kiên Cố 14s; kích hoạt khi HP dưới 25% | 2·3·2 |  |
| 26 | **Kẻ Móc Túi** (Pickpocket)<br>Vàng rơi nhiều hơn. | Nội tại | GOLD | — | +15% Tìm vàng | +26.2% Tìm vàng | 3·1·1 | Đấu Trường (thiết kế): không tác dụng. |
| 27 | **Né Cao Cấp** (Advanced Evasion)<br>Rất khó bị đánh trúng. | Nội tại | MSPD | — | +8% né tránh | +14% né tránh | 2·3·2 |  |
| 28 | **Lưỡi Răng Cưa** (Serrated)<br>Đòn thường đôi khi gây chảy máu. | Nội tại | CRIT | — | đòn thường: Chảy Máu (20%) | đòn thường: Chảy Máu (35%) | 2·2·2 |  |
| 29 | **Kẻ Rình Rập** (Lurker)<br>Đau hơn khi mục tiêu không để ý mình. | Nội tại | ATK | — | +15% sát thương khi không bị nhắm | +26.2% sát thương khi không bị nhắm | 2·2·3 | Boss nhắm tank nên Rogue gần như luôn hưởng. |
| 30 | **Săn Người** (Manhunter)<br>Chuyên săn người. | Nội tại | CRIT | — | +8% Chí mạng với người; +20% ST chí mạng với người | +14% Chí mạng với người; +35% ST chí mạng với người | 1·3·1 | Thay Golden Ratio (CRIT trên 100% gần như không đạt được). |

## 🛡️ Guardian · Hộ Vệ

| # | Skill | Loại | Scale | Hồi chiêu · Mana (cấp 1→6) | Cấp 1 | Cấp 6 | Sao | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| 1 | **Đập Khiên** (Shield Bash)<br>Đập khiên làm choáng, mạnh theo phòng thủ. | Thi triển | DEF | 8s · 20→26 | ST 50% ATK + 80% DEF; gây Choáng 1.5s | ST 87.5% ATK + 140% DEF; gây Choáng 2.1s | 2·3·1 | Boss: Stagger. Đấu Trường (thiết kế): choáng 0.6s. |
| 2 | **Tường Khiên** (Shield Wall)<br>Che chắn cả đội. | Thi triển | DEF | 20s · 38→49 | đồng đội quanh mình: Kiên Cố 8s | đồng đội quanh mình: Kiên Cố 14s | 2·2·3 |  |
| 3 | **Khiêu Khích Toàn Thể** (Mass Taunt)<br>Mọi kẻ địch gần đó đánh mình, giáp mọc gai. | Thi triển | HP | 16s · 32→42 | khiêu khích địch trong 100px; bản thân: Phản Đòn 8s | khiêu khích địch trong 100px; bản thân: Phản Đòn 14s | 3·2·3 | Kẻ địch đổi mục tiêu sang Guardian và giữ đến khi tự đổi. |
| 4 | **Búa Thánh** (Holy Hammer)<br>Giáng chuỳ thần thánh, mạnh với Undead. | Thi triển | ATK | 9s · 22→29 | ST 150% ATK; +50% với undead | ST 262.5% ATK; +50% với undead | 2·2·2 | Rất mạnh ở Ancient Ruins. |
| 5 | **Ánh Sáng Chữa Lành** (Healing Light)<br>Hồi máu đồng đội thấp máu nhất. | Thi triển | HP | 12s · 26→34 | hồi 10% HP tối đa (đồng đội yếu máu nhất) | hồi 17.5% HP tối đa (đồng đội yếu máu nhất) | 2·2·3 | Đấu Trường (thiết kế): ×0.7. |
| 6 | **Thánh Hộ** (Divine Shield)<br>Bất tử chốc lát khi máu dưới 35%. | Thi triển | LV | 45s · 76→99 | bản thân: Bất Tử 2s; kích hoạt khi HP dưới 35% | bản thân: Bất Tử 3.5s; kích hoạt khi HP dưới 35% | 2·2·3 | Đấu Trường (thiết kế): 1 lần mỗi trận. |
| 7 | **Giáp Gai** (Spiked Armor)<br>Gai mọc trên giáp, phản sát thương. | Thi triển | DEF | 15s · 30→39 | bản thân: Phản Đòn 8s | bản thân: Phản Đòn 14s | 3·2·2 | Đấu Trường (thiết kế): trần phản 30%. |
| 8 | **Phán Xét** (Judgment)<br>Đánh mạnh hơn khi địch đã mất nửa máu. | Thi triển | ATK | 11s · 24→31 | ST 100% ATK; mục tiêu dưới 50% HP: ×1.4 (boss 15%) | ST 175% ATK; mục tiêu dưới 50% HP: ×1.4 (boss 15%) | 2·2·3 | Mạnh hơn khi mục tiêu dưới 50% HP. |
| 9 | **Chắn Đòn** (Intercept)<br>Che khiên cho đồng đội yếu nhất. | Thi triển | MSPD | 14s · 29→38 | khiên 15% HP tối đa (đồng đội yếu máu nhất) | khiên 26.2% HP tối đa (đồng đội yếu máu nhất) | 2·3·2 | Không lao tới, chỉ che khiên. |
| 10 | **Lời Thề Bảo Hộ** (Oath)<br>Thề bảo vệ đồng đội yếu nhất. | Thi triển | HP | 20s · 38→49 | đồng đội yếu máu nhất: Kiên Cố 8s | đồng đội yếu máu nhất: Kiên Cố 14s | 1·3·3 | Không chia sát thương, cho Kiên Cố. |
| 11 | **Chấn Động** (Shockwave)<br>Đập chuỳ làm rung chuyển mặt đất. | Thi triển | DEF | 12s · 26→34 | ST 60% ATK + 50% DEF; AoE quanh mình 45px; gây Làm Chậm 4s | ST 105% ATK + 87.5% DEF; AoE quanh mình 45px; gây Làm Chậm 5.5s | 3·1·1 |  |
| 12 | **Thánh Địa** (Consecrate)<br>Thánh hoá mặt đất, đồng đội hồi máu. | Thi triển | HP | 22s · 41→53 | đồng đội quanh mình: Hồi Máu 8s | đồng đội quanh mình: Hồi Máu 14s | 2·2·3 | Đấu Trường (thiết kế): hồi ×0.7. |
| 13 | **Đập Nát** (Crushing Blow)<br>Đập vỡ giáp mục tiêu. | Thi triển | ATK | 10s · 23→30 | ST 160% ATK; gây Phá Giáp 6s | ST 280% ATK; gây Phá Giáp 8.2s | 2·2·3 | Boss: Phá Giáp còn nửa thời gian. |
| 14 | **Khiên Phản Xạ** (Reflective Guard)<br>Chặn và phản đòn. | Thi triển | DEF | 20s · 38→49 | bản thân: Phản Đòn 8s, Kiên Cố 8s | bản thân: Phản Đòn 14s, Kiên Cố 14s | 2·2·3 |  |
| 15 | **Hào Quang Sức Mạnh** (Aura of Might)<br>Tăng sức mạnh đồng đội. | Thi triển | LV | 24s · 44→57 | đồng đội quanh mình: Cường Lực 8s | đồng đội quanh mình: Cường Lực 14s | 2·2·3 |  |
| 16 | **Thanh Tẩy** (Cleanse)<br>Xoá hiệu ứng xấu khỏi đồng đội. | Thi triển | LV | 18s · 35→46 | xoá hiệu ứng xấu (đồng đội quanh mình) | xoá hiệu ứng xấu (đồng đội quanh mình) | 2·3·3 | Khắc chế đội khống chế ở Đấu Trường. |
| 17 | **Trừng Phạt** (Smite)<br>Đòn trừng phạt bằng sức nặng của giáp. | Thi triển | DEF | 9s · 22→29 | ST 90% ATK + 70% DEF; gây Choáng 1.5s (40%) | ST 157.5% ATK + 122.5% DEF; gây Choáng 2.1s (40%) | 2·2·2 | Choáng là xác suất 40%. Boss: Loạng Choạng thay choáng. |
| 18 | **Điểm Tựa** (Bulwark)<br>Tạo khiên hấp thụ sát thương. | Thi triển | HP | 16s · 32→42 | khiên 15% HP tối đa (bản thân) | khiên 26.2% HP tối đa (bản thân) | 2·2·3 | Đấu Trường (thiết kế): ×0.7. |
| 19 | **Thể Chất Thép** (Iron Constitution)<br>Thân thể bền bỉ. | Nội tại | HP | — | +10% HP tối đa | +17.5% HP tối đa | 2·2·2 |  |
| 20 | **Thuẫn Thuật** (Shield Mastery)<br>Chặn đòn bằng khiên. | Nội tại | DEF | — | -8% sát thương nhận | -14% sát thương nhận | 2·2·3 | Giảm sát thương nhận thay vì chặn đòn. |
| 21 | **Bất Động** (Unshakable)<br>Chân như cắm rễ. | Nội tại | DEF | — | +40% kháng khống chế | +70% kháng khống chế | 1·3·2 | Gộp hai passive kháng khống chế của v1. |
| 22 | **Kiên Trì** (Perseverance)<br>Máu dưới 50% thì tự hồi phục. | Nội tại (tự kích) | HP | 20s | bản thân: Hồi Máu 8s; kích hoạt khi HP dưới 50% | bản thân: Hồi Máu 14s; kích hoạt khi HP dưới 50% | 2·2·3 |  |
| 23 | **Hào Quang Bảo Hộ** (Protective Aura)<br>Định kỳ che chở đồng đội gần đó. | Nội tại (tự kích) | DEF | 20s | đồng đội quanh mình: Kiên Cố 8s | đồng đội quanh mình: Kiên Cố 14s | 2·2·2 | Hào quang = định kỳ cho Kiên Cố. |
| 24 | **Trả Đũa** (Vengeance)<br>Giáp cũng là vũ khí. | Nội tại | DEF | — | +8% ATK | +14% ATK | 2·2·2 | Cộng % ATK, không theo DEF. |
| 25 | **Người Gác Cửa** (Gatekeeper)<br>Đứng vững trước đám đông. | Nội tại | HP | — | +6% DEF; +3% HP tối đa | +10.5% DEF; +5.2% HP tối đa | 3·1·1 | Cộng phẳng, không cần bị vây. |
| 26 | **Tín Niệm** (Faith)<br>Hồi máu mạnh hơn theo cấp. | Nội tại | LV | — | +15% hồi máu; +0.3% hồi máu mỗi 1 cấp Hunter (tối đa 66 lần) | +26.2% hồi máu; +0.5% hồi máu mỗi 1 cấp Hunter (tối đa 66 lần) | 2·2·3 |  |
| 27 | **Kẻ Thách Thức** (Boss Challenger)<br>Đứng trước boss không lùi bước. | Nội tại | HP | — | -12% sát thương nhận với boss | -21% sát thương nhận với boss | 1·1·3 | Thay Immovable (trùng Unshakable). |
| 28 | **Người Che Chắn** (Bodyguard)<br>Định kỳ che khiên cho đồng đội yếu nhất. | Nội tại (tự kích) | HP | 15s | khiên 6% HP tối đa (đồng đội yếu máu nhất) | khiên 10.5% HP tối đa (đồng đội yếu máu nhất) | 2·3·3 | Không gánh đòn, định kỳ che khiên. |
| 29 | **Dày Dạn Trận Mạc** (Battle-Hardened)<br>Giáp dày theo năm tháng. | Nội tại | LV | — | +1.0 DEF mỗi 3 cấp Hunter (tối đa 33 lần) | +1.8 DEF mỗi 3 cấp Hunter (tối đa 33 lần) | 2·2·2 |  |
| 30 | **Tâm Kiên** (Resolve)<br>Máu dưới 60% thì cứng cáp lại. | Nội tại (tự kích) | HP | 10s | bản thân: Kiên Cố 8s; kích hoạt khi HP dưới 60% | bản thân: Kiên Cố 14s; kích hoạt khi HP dưới 60% | 1·2·3 | Boss đánh chậm và nặng nên kích hoạt liên tục. |

## Chỉnh số

Mọi số nằm trong `data/class_skills/*.tres` và `data/config/game_config.tres` (nhóm Class skills). Không có số nào nằm trong code.
