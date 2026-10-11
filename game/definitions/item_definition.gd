class_name ItemDefinition
extends GameDefinition
## Equipment, material or consumable (ITEM_DESIGN.md, INVENTORY_SYSTEM.md).

enum ItemType { WEAPON, ARMOR, ACCESSORY, MATERIAL, CONSUMABLE }
enum Rarity { COMMON, UNCOMMON, RARE }
enum EquipmentSlot { NONE, WEAPON, ARMOR, ACCESSORY }

@export var item_type: ItemType = ItemType.MATERIAL
@export var rarity: Rarity = Rarity.COMMON
@export var stackable: bool = false
@export var max_stack: int = 1
@export var sell_price: int = 0
@export var equipment_slot: EquipmentSlot = EquipmentSlot.NONE
@export var modifiers: Array[StatModifier] = []
@export var icon: Texture2D
## Colour of the item on placeholder characters (weapon blade / armor body).
@export var tint: Color = Color.WHITE
## Armor only: Hunter outfit shown while worn (id in res://data/appearance/wardrobe.json, D47).
## Empty = the wearer's default outfit.
@export var outfit_id: StringName

@export_group("Consumable")
## Food (D40): energy gained per portion. Medicine (D41): share of max HP healed.
## Hunters pay `sell_price` into the treasury for one.
@export var energy: float = 0.0
@export_range(0.0, 1.0) var heal_ratio: float = 0.0
