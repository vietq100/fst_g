class_name ItemDefinition
extends GameDefinition
## Equipment, material or consumable (ITEM_DESIGN.md, INVENTORY_SYSTEM.md).

## New values are appended so saved .tres numbers stay valid (D59).
enum ItemType { WEAPON, ARMOR, ACCESSORY, MATERIAL, CONSUMABLE, SKIN, PET }
## ARMOR = the top (tunic, plate). ACCESSORY = a charm. HELMET / PANTS / BOOTS show on the
## Hunter; NECKLACE / RING are jewelry; SKIN replaces the outfit's look; PET follows the Hunter.
enum EquipmentSlot { NONE, WEAPON, ARMOR, ACCESSORY, HELMET, PANTS, BOOTS, NECKLACE, RING, SKIN, PET }

@export var item_type: ItemType = ItemType.MATERIAL
## Tier (D60): C, U, R, SR, SSR, UR are craftable / droppable; LR and Mythic are fixed.
@export var rarity: Tier.Level = Tier.Level.C
@export var stackable: bool = false
@export var max_stack: int = 1
@export var sell_price: int = 0
@export var equipment_slot: EquipmentSlot = EquipmentSlot.NONE
@export var modifiers: Array[StatModifier] = []
@export var icon: Texture2D
## Colour of the item on placeholder characters (weapon blade / armor body).
@export var tint: Color = Color.WHITE
## Skin: class outfit pattern worn (warrior / ranger / rogue / guardian, D59); the cloth takes `tint`.
## Skin or top: a Forge top (D73: tee, hoodie, armor, robe... or the aliases iron_plate, light_leather).
## Empty or unknown = the wearer's class pattern.
@export var outfit_id: StringName
## Helmet: hat style (helm, cap, hood, wizard, crown, beanie, cowboy, viking, nonla). Pet: PetSprites kind
## (pup, chick, slime, teddy, wisp). Top / pants / boots: Forge style (D73). Accessory: glasses_<round|square|
## sun|goggle|patch>. Weapon: Forge weapon, optionally with an effect element suffix (sword_fire). Empty =
## picked from words in the id.
@export var look_id: StringName

@export_group("Consumable")
## Food (D40): energy gained per portion. Medicine (D41): share of max HP healed.
## Hunters pay `sell_price` into the treasury for one.
@export var energy: float = 0.0
@export_range(0.0, 1.0) var heal_ratio: float = 0.0
