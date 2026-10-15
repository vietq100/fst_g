"""Generates data/active_skills/*.tres (D55): 30 skills per Hunter class + monster skills.
Fields: (id, name, level, cooldown, damage, radius, targets, effect, self_effect, heal, anim, vfx, text)
"""
import os, sys
OUT = sys.argv[1]
HEADER = '''[gd_resource type="Resource" script_class="ActiveSkillDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://game/definitions/active_skill_definition.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
'''

def S(id, name, lvl, cd, dmg, rad, tg, eff, selfeff, heal, anim, vfx, text, stacks=1):
    return dict(id=id, name=name, lvl=lvl, cd=cd, dmg=dmg, rad=rad, tg=tg, eff=eff, selfeff=selfeff,
                heal=heal, anim=anim, vfx=vfx, text=text, stacks=stacks)

# ---------------------------------------------------------------- Warrior: brute force, bleed, burn, self buffs
WARRIOR = [
 S("power_slam","Power Slam",1,8,1.8,36,4,"","",0,"skill_slam","shockwave","Overhead slam that hits nearby foes."),
 S("cleave","Cleave",2,7,1.4,40,3,"","",0,"skill_spin","wind","A wide horizontal cut."),
 S("rending_strike","Rending Strike",3,9,1.5,0,1,"bleed","",0,"skill_thrust","blood","Deep cut that bleeds."),
 S("war_cry","War Cry",4,16,0,0,1,"","strength",0,"skill_cast","shockwave","A roar that sharpens the blade."),
 S("crushing_blow","Crushing Blow",5,10,2.2,0,1,"","",0,"skill_slam","earth","One heavy, bone-breaking hit."),
 S("shield_breaker","Shield Breaker",6,9,1.4,0,1,"armor_break","",0,"skill_thrust","earth","Shatters the target's guard."),
 S("whirlwind","Whirlwind",7,11,1.3,48,6,"","",0,"skill_spin","wind","Spinning steel around the Warrior."),
 S("iron_will","Iron Will",8,18,0,0,1,"","fortify",0,"skill_cast","holy","Braces against the next blows."),
 S("flame_strike","Flame Strike",9,10,1.6,0,1,"burn","",0,"skill_slam","flame","A blade wreathed in fire."),
 S("earthshatter","Earthshatter",10,13,1.7,44,5,"stun","",0,"skill_slam","shockwave","Stuns everything around the impact."),
 S("second_wind","Second Wind",11,22,0,0,1,"","regeneration",0.15,"skill_cast","heal","Catches breath and mends."),
 S("executioner","Executioner",12,12,2.6,0,1,"","",0,"skill_slam","blood","A finishing swing."),
 S("berserk","Berserk",13,20,0,0,1,"","haste",0,"skill_cast","blood","Fury quickens every strike."),
 S("hamstring","Hamstring",14,9,1.3,0,1,"slow","",0,"skill_thrust","blood","Cuts the legs; the foe slows."),
 S("blade_storm","Blade Storm",15,14,1.5,52,6,"bleed","",0,"skill_spin","blood","A storm of cuts that bleed."),
 S("thunder_slam","Thunder Slam",16,13,1.9,40,4,"","",0,"skill_slam","lightning","Lightning cracks from the impact."),
 S("bloodlust","Bloodlust",17,20,0,0,1,"","lifesteal",0,"skill_cast","blood","Wounds dealt feed the Warrior."),
 S("sunder","Sunder",18,11,1.6,30,3,"armor_break","",0,"skill_spin","earth","Breaks armour in an arc."),
 S("inferno_sweep","Inferno Sweep",19,13,1.5,46,5,"burn","",0,"skill_spin","flame","Fire spreads with the sweep."),
 S("unbreakable","Unbreakable",20,30,0,0,1,"","invulnerable",0,"skill_cast","holy","Nothing gets through for a moment."),
 S("mountain_breaker","Mountain Breaker",21,14,2.4,36,3,"","",0,"skill_slam","earth","The ground itself cracks."),
 S("savage_leap","Savage Leap",22,12,1.9,40,4,"","",0,"skill_leap","shockwave","Leaps in and lands hard."),
 S("crippling_blow","Crippling Blow",23,11,1.7,0,1,"weaken","",0,"skill_thrust","earth","Saps the target's strength."),
 S("vengeance","Vengeance",24,22,0,0,1,"","thorns",0,"skill_cast","flame","Every blow taken is repaid."),
 S("titan_swing","Titan Swing",25,15,2.0,56,6,"","",0,"skill_spin","wind","A giant's arc of steel."),
 S("searing_edge","Searing Edge",26,12,2.1,0,1,"burn","",0,"skill_thrust","flame","White-hot steel, burning deep."),
 S("warlord_cry","Warlord's Cry",27,24,0,0,1,"","focus",0,"skill_cast","lightning","Focus for the kill."),
 S("decapitate","Decapitate",28,14,3.0,0,1,"","",0,"skill_slam","blood","A blow meant to end it."),
 S("cataclysm","Cataclysm",29,18,2.2,60,8,"stun","",0,"skill_slam","shockwave","Everything nearby is knocked flat."),
 S("avatar_of_war","Avatar of War",30,30,1.6,48,6,"vulnerable","strength",0.1,"skill_spin","flame","War made flesh."),
]
# ---------------------------------------------------------------- Ranger: arrows, frost, poison, kiting
RANGER = [
 S("arrow_volley","Arrow Volley",1,8,1.1,90,3,"","",0,"skill_volley","arrows","Three arrows at once."),
 S("piercing_shot","Piercing Shot",2,7,1.8,0,1,"","",0,"skill_volley","arrows","An arrow through armour."),
 S("venom_arrow","Venom Arrow",3,9,1.3,0,1,"poison","",0,"skill_volley","poison","Poison on the tip."),
 S("quick_step","Quick Step",4,14,0,0,1,"","haste",0,"skill_leap","wind","Light feet, quick hands."),
 S("frost_arrow","Frost Arrow",5,9,1.4,0,1,"slow","",0,"skill_volley","frost","Chills the target to the bone."),
 S("double_shot","Double Shot",6,7,1.3,60,2,"","",0,"skill_volley","arrows","Two arrows, two targets."),
 S("hunters_mark","Hunter's Mark",7,10,1.0,0,1,"vulnerable","",0,"skill_cast","arrows","Marks the prey for every blow."),
 S("eagle_eye","Eagle Eye",8,18,0,0,1,"","focus",0,"skill_cast","lightning","Every shot finds its gap."),
 S("rain_of_arrows","Rain of Arrows",9,12,1.2,100,5,"","",0,"skill_volley","arrows","Arrows fall across the field."),
 S("snare","Snare",10,11,1.1,0,1,"root","",0,"skill_cast","wind","A trap that holds the foe."),
 S("fire_arrow","Fire Arrow",11,10,1.5,0,1,"burn","",0,"skill_volley","flame","A burning shaft."),
 S("field_dressing","Field Dressing",12,22,0,0,1,"","regeneration",0.12,"skill_cast","heal","Quick bandage work."),
 S("ice_volley","Ice Volley",13,12,1.2,90,3,"slow","",0,"skill_volley","frost","Three frozen arrows."),
 S("headshot","Headshot",14,11,2.4,0,1,"","",0,"skill_volley","arrows","Aim for the head."),
 S("toxic_cloud","Toxic Cloud",15,13,1.0,70,4,"poison","",0,"skill_cast","poison","A cloud of venom."),
 S("storm_arrow","Storm Arrow",16,12,1.7,40,3,"","",0,"skill_volley","lightning","Lightning jumps between foes."),
 S("evasion","Evasion",17,20,0,0,1,"","shield",0,"skill_leap","wind","Reads every strike before it lands."),
 S("crippling_shot","Crippling Shot",18,10,1.4,0,1,"weaken","",0,"skill_volley","arrows","Takes the strength from their arm."),
 S("barrage","Barrage",19,14,1.3,110,6,"","",0,"skill_volley","arrows","A hail of arrows."),
 S("frostbite_volley","Frostbite Volley",20,14,1.4,90,4,"freeze","",0,"skill_volley","frost","Freezes the whole pack."),
 S("deadeye","Deadeye",21,24,0,0,1,"","strength",0,"skill_cast","arrows","Steady aim, heavier draw."),
 S("explosive_arrow","Explosive Arrow",22,13,1.8,50,4,"burn","",0,"skill_volley","flame","It bursts on impact."),
 S("disarming_shot","Disarming Shot",23,12,1.3,0,1,"disarm","",0,"skill_volley","arrows","Knocks the weapon away."),
 S("retreat_roll","Retreat Roll",24,18,0,0,1,"","fortify",0,"skill_leap","wind","Rolls clear and sets again."),
 S("thunder_rain","Thunder Rain",25,15,1.5,100,6,"","",0,"skill_volley","lightning","The sky answers the Ranger."),
 S("plague_arrow","Plague Arrow",26,12,1.6,60,3,"poison","",0,"skill_volley","poison","Venom that spreads."),
 S("perfect_focus","Perfect Focus",27,26,0,0,1,"","focus",0,"skill_cast","holy","Nothing but the target exists."),
 S("widowmaker","Widowmaker",28,14,3.0,0,1,"bleed","",0,"skill_volley","blood","One arrow, one kill."),
 S("blizzard_volley","Blizzard Volley",29,18,1.6,110,7,"freeze","",0,"skill_volley","frost","Winter in a single breath."),
 S("hawk_god_volley","Hawk God's Volley",30,30,2.0,120,8,"vulnerable","haste",0,"skill_volley","lightning","The hawk's judgement."),
]
# ---------------------------------------------------------------- Rogue: burst, bleed, poison, shadows
ROGUE = [
 S("shadow_strike","Shadow Strike",1,7,2.2,0,1,"bleed","",0,"skill_dash","shadow","Dash through the shadows and cut."),
 S("backstab","Backstab",2,8,2.6,0,1,"","",0,"skill_dash","blood","Where the armour is not."),
 S("poison_blade","Poison Blade",3,9,1.6,0,1,"poison","",0,"skill_thrust","poison","Venom on the edge."),
 S("smoke_bomb","Smoke Bomb",4,15,0,0,1,"","shield",0,"skill_cast","shadow","Vanishes in smoke."),
 S("fan_of_knives","Fan of Knives",5,10,1.3,50,5,"","",0,"skill_spin","wind","Knives in every direction."),
 S("crippling_cut","Crippling Cut",6,9,1.5,0,1,"slow","",0,"skill_thrust","blood","Slices the tendon."),
 S("adrenaline","Adrenaline",7,16,0,0,1,"","haste",0,"skill_cast","blood","Blood up, hands fast."),
 S("eviscerate","Eviscerate",8,10,2.8,0,1,"bleed","",0,"skill_dash","blood","A wound that keeps bleeding."),
 S("shadow_dance","Shadow Dance",9,12,1.6,40,3,"","",0,"skill_spin","shadow","Three cuts, one blur."),
 S("venom_cloud","Venom Cloud",10,13,1.1,60,4,"poison","",0,"skill_cast","poison","Poison fills the air."),
 S("expose_weakness","Expose Weakness",11,11,1.4,0,1,"vulnerable","",0,"skill_thrust","shadow","Finds the gap for everyone."),
 S("dirty_fighting","Dirty Fighting",12,10,1.5,0,1,"disarm","",0,"skill_dash","wind","Sand in the eyes, blade on the wrist."),
 S("blood_rush","Blood Rush",13,20,0,0,1,"","lifesteal",0,"skill_cast","blood","Every cut feeds the Rogue."),
 S("garrote","Garrote",14,11,1.8,0,1,"stun","",0,"skill_dash","shadow","Silence, then the fall."),
 S("death_blossom","Death Blossom",15,14,1.7,56,6,"bleed","",0,"skill_spin","blood","A flower of blades."),
 S("night_step","Night Step",16,13,2.4,0,1,"","",0,"skill_dash","shadow","Gone, then behind them."),
 S("toxic_shiv","Toxic Shiv",17,10,2.0,0,1,"poison","",0,"skill_thrust","poison","Poison deep in the wound.",2),
 S("evasive_roll","Evasive Roll",18,18,0,0,1,"","fortify",0,"skill_leap","wind","Rolls under the blow."),
 S("shadow_volley","Shadow Volley",19,13,1.4,70,4,"","",0,"skill_spin","shadow","Throwing knives from the dark."),
 S("hemorrhage","Hemorrhage",20,12,2.2,0,1,"bleed","",0,"skill_dash","blood","The wound will not close.",2),
 S("phantom_strike","Phantom Strike",21,14,3.0,0,1,"","",0,"skill_dash","shadow","Was it even there?"),
 S("paralytic_poison","Paralytic Poison",22,13,1.6,0,1,"stun","",0,"skill_thrust","poison","Numbs the whole body."),
 S("killer_instinct","Killer Instinct",23,24,0,0,1,"","focus",0,"skill_cast","shadow","Sees only the kill."),
 S("whirling_death","Whirling Death",24,15,1.8,60,6,"","",0,"skill_spin","wind","Death in a circle."),
 S("shadowmeld","Shadowmeld",25,30,0,0,1,"","invulnerable",0,"skill_cast","shadow","Part of the dark for a breath."),
 S("mortal_wound","Mortal Wound",26,13,2.6,0,1,"weaken","",0,"skill_dash","blood","They will not swing the same."),
 S("plague_dance","Plague Dance",27,15,1.5,60,5,"poison","",0,"skill_spin","poison","Venom with every turn.",2),
 S("assassinate","Assassinate",28,16,3.5,0,1,"","",0,"skill_dash","shadow","The quiet end."),
 S("night_of_blades","Night of Blades",29,18,2.0,70,8,"bleed","",0,"skill_spin","shadow","A night nobody survives."),
 S("reaper_shadow","Reaper's Shadow",30,30,2.8,50,4,"vulnerable","haste",0.1,"skill_dash","shadow","Death itself walks."),
]
# ---------------------------------------------------------------- Guardian: shield, stun, holy, protection
GUARDIAN = [
 S("shield_bash","Shield Bash",1,8,1.4,30,3,"stun","",0,"skill_bash","bash","Shield first, hard."),
 S("taunting_blow","Taunting Blow",2,8,1.3,0,1,"weaken","",0,"skill_thrust","bash","Draws the foe's fury, dulls its blade."),
 S("bulwark","Bulwark",3,15,0,0,1,"","fortify",0,"skill_cast","holy","Plants the shield and holds."),
 S("holy_strike","Holy Strike",4,9,1.6,0,1,"","",0,"skill_slam","holy","Light along the mace."),
 S("ground_pound","Ground Pound",5,11,1.3,44,4,"slow","",0,"skill_slam","earth","The earth jolts underfoot."),
 S("mending_light","Mending Light",6,20,0,0,1,"","regeneration",0.15,"skill_cast","heal","Warm light closes wounds."),
 S("shield_wall","Shield Wall",7,18,0,0,1,"","shield",0,"skill_cast","bash","A wall of steel."),
 S("hammer_down","Hammer Down",8,10,2.0,0,1,"armor_break","",0,"skill_slam","earth","Armour means nothing."),
 S("judgement","Judgement",9,12,1.8,36,3,"","",0,"skill_slam","holy","Light falls on the wicked."),
 S("iron_bastion","Iron Bastion",10,22,0,0,1,"","thorns",0,"skill_cast","bash","Strike it and bleed."),
 S("concussive_bash","Concussive Bash",11,10,1.5,0,1,"stun","",0,"skill_bash","bash","A ringing blow to the head."),
 S("frost_hammer","Frost Hammer",12,11,1.6,0,1,"freeze","",0,"skill_slam","frost","Cold iron, colder wound."),
 S("rally","Rally",13,20,0,0,1,"","strength",0.05,"skill_cast","holy","Stand and fight!"),
 S("shield_slam","Shield Slam",14,10,1.8,34,3,"","",0,"skill_bash","shockwave","The shield as a hammer."),
 S("consecration","Consecration",15,14,1.3,56,6,"burn","",0,"skill_cast","holy","Holy fire on sacred ground."),
 S("stalwart","Stalwart",16,24,0,0,1,"","regeneration",0.2,"skill_cast","heal","Unmoved, unbroken."),
 S("thunderclap","Thunderclap",17,13,1.5,50,5,"stun","",0,"skill_slam","lightning","A clap that stuns the field."),
 S("breaking_charge","Breaking Charge",18,12,1.9,30,3,"armor_break","",0,"skill_leap","bash","Charges through the line."),
 S("sanctuary","Sanctuary",19,28,0,0,1,"","invulnerable",0,"skill_cast","holy","Untouchable in the light."),
 S("crusader_strike","Crusader Strike",20,11,2.3,0,1,"","",0,"skill_slam","holy","A blow blessed and heavy."),
 S("glacial_wall","Glacial Wall",21,16,1.2,50,5,"slow","shield",0,"skill_cast","frost","Ice on the shield, frost on the foe."),
 S("retribution","Retribution",22,14,2.0,40,4,"","thorns",0,"skill_spin","holy","What is given is returned."),
 S("earthen_grip","Earthen Grip",23,13,1.3,48,5,"root","",0,"skill_slam","earth","Stone hands hold them fast."),
 S("aegis","Aegis",24,24,0,0,1,"","shield",0.1,"skill_cast","bash","The great shield of the Guardian."),
 S("divine_hammer","Divine Hammer",25,14,2.6,0,1,"stun","",0,"skill_slam","holy","Heaven's weight in one blow."),
 S("avalanche","Avalanche",26,16,1.7,60,6,"freeze","",0,"skill_slam","frost","Winter falls all at once."),
 S("last_stand","Last Stand",27,30,0,0,1,"","fortify",0.3,"skill_cast","heal","When all else fails."),
 S("holy_quake","Holy Quake",28,16,2.0,56,6,"vulnerable","",0,"skill_slam","holy","The ground sings with light."),
 S("fortress","Fortress",29,30,0,0,1,"","invulnerable",0.15,"skill_cast","bash","A fortress of one."),
 S("templar_wrath","Templar's Wrath",30,30,2.4,60,8,"stun","strength",0.1,"skill_slam","lightning","The wrath of every oath."),
]
# ---------------------------------------------------------------- Monsters (2 each)
MONSTER = [
 S("acid_splash","Acid Splash",1,10,1.2,24,2,"poison","",0,"skill_cast","poison","Slime acid splashes nearby."),
 S("bounce","Bounce",1,9,1.6,0,1,"","",0,"skill_leap","shockwave","The slime lands hard."),
 S("lunge_bite","Lunge Bite",1,8,1.7,0,1,"bleed","",0,"skill_dash","blood","A bite that tears."),
 S("howl","Howl",1,16,0,0,1,"","haste",0,"skill_cast","wind","The pack's call."),
 S("dirty_trick","Dirty Trick",1,9,1.3,0,1,"vulnerable","",0,"skill_thrust","shadow","A cheap, nasty jab."),
 S("club_smash","Club Smash",1,11,1.8,0,1,"stun","",0,"skill_slam","earth","The club comes down."),
 S("bone_rattle","Bone Rattle",1,16,0,0,1,"","fortify",0,"skill_cast","frost","Bones lock tight."),
 S("grave_chill","Grave Chill",1,10,1.4,30,3,"slow","",0,"skill_spin","frost","Cold from the grave."),
 S("root_grasp","Root Grasp",1,12,1.5,60,4,"root","",0,"skill_slam","earth","Roots burst from the ground."),
 S("quake","Quake",1,16,2.0,80,6,"stun","shield",0,"skill_slam","shockwave","The forest shakes."),
]

def emit(owner, skills):
    for s in skills:
        text = s["text"]
        parts = []
        if s["dmg"] > 0:
            parts.append("%.0f%% damage" % (s["dmg"] * 100))
            if s["rad"] > 0:
                parts.append("up to %d foes within %d px" % (s["tg"], s["rad"]))
        if s["eff"]: parts.append("applies %s" % s["eff"].replace("_", " ").title() + (" ×%d" % s["stacks"] if s["stacks"] > 1 else ""))
        if s["selfeff"]: parts.append("gains %s" % s["selfeff"].replace("_", " ").title())
        if s["heal"] > 0: parts.append("heals %d%% HP" % round(s["heal"] * 100))
        joined = ", ".join(parts)
        desc = text + (" " + joined[0].upper() + joined[1:] + "." if joined else "") + " Cooldown %ds." % s["cd"]
        body = HEADER
        body += 'id = &"%s"\n' % s["id"]
        body += 'display_name = "%s"\n' % s["name"].replace('"', "'")
        body += 'description = "%s"\n' % desc.replace('"', "'")
        body += 'owner_class = &"%s"\n' % owner
        body += 'required_level = %d\n' % s["lvl"]
        body += 'cooldown = %.1f\n' % s["cd"]
        body += 'damage = %.2f\n' % s["dmg"]
        body += 'radius = %.1f\n' % s["rad"]
        body += 'targets = %d\n' % s["tg"]
        body += 'effect_id = &"%s"\n' % s["eff"]
        body += 'effect_stacks = %d\n' % s["stacks"]
        body += 'self_effect_id = &"%s"\n' % s["selfeff"]
        body += 'self_effect_stacks = 1\n'
        body += 'heal_ratio = %.2f\n' % s["heal"]
        body += 'animation = &"%s"\n' % s["anim"]
        body += 'vfx = &"%s"\n' % s["vfx"]
        with open(os.path.join(OUT, owner, s["id"] + ".tres"), "w") as f:
            f.write(body)

for owner, skills in [("warrior", WARRIOR), ("ranger", RANGER), ("rogue", ROGUE), ("guardian", GUARDIAN), ("monster", MONSTER)]:
    os.makedirs(os.path.join(OUT, owner), exist_ok=True)
    assert len(skills) == (30 if owner != "monster" else 10), owner
    ids = [s["id"] for s in skills]
    assert len(set(ids)) == len(ids), owner
    emit(owner, skills)
all_ids = [s["id"] for g in (WARRIOR, RANGER, ROGUE, GUARDIAN, MONSTER) for s in g]
assert len(set(all_ids)) == len(all_ids), "duplicate ids across classes"
print("written", len(all_ids))
