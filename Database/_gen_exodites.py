"""Generate exodites.sql from the Palladium NetEpic 3 Exodites army book.

Source: C:/Files/NetEpicFR300-EnglishTranslation/Exodites 300
"""
from __future__ import annotations

from pathlib import Path

OUT = Path(__file__).resolve().parent


def sql_str(text: str) -> str:
    return text.replace("\\", "\\\\").replace("'", "''").replace("\r\n", "\n")


IMAGE_ALIASES = {
    "Bright Stalker": "bright-knights.png",
    "Bright Stallion": "bright-knights.png",
    "Fire Gale": "fire-knights.png",
    "Fire Reaper": "fire-knights.png",
    "Fire Storm": "fire-knights.png",
    "Megadon — Assault": "megadon.png",
    "Megadon — Support": "megadon.png",
    "Pentasaur — Maelstrom Laser": "pentasaur.png",
    "Pentasaur — Missile Launcher": "pentasaur.png",
    "Pentasaur — Thermal Lance": "pentasaur.png",
    "Travois — Starcannons": "travois.png",
    "Travois — Bright Lance": "travois.png",
    "Travois — Missile Launcher": "travois.png",
    "Combat Walkers": "combat-walkers.png",
    "Reconnaissance Walkers": "reconnaissance-walkers.png",
    "Dragon Knights": "dragon-knights.png",
    "Lethosaur Knights": "lethosaur-knights.png",
    "Pterosaur Knights": "pterosaur-knights.png",
    "Raptor Knights": "raptor-knights.png",
    "Exodite Warriors": "exodite-warriors.png",
    "Vyper Transport": "vyper-transport.png",
    "Towering Destroyer": "towering-destroyer.png",
}


def image_path_for(name: str) -> str:
    if name in IMAGE_ALIASES:
        return IMAGE_ALIASES[name]
    return name.lower().replace(" ", "-").replace("—", "").replace("--", "-") + ".png"


def union_rows(rows: list[tuple[str, str]]) -> str:
    parts = []
    for i, (name, desc) in enumerate(rows):
        prefix = "    SELECT" if i == 0 else "    UNION ALL SELECT"
        parts.append(f"{prefix} '{sql_str(name)}' AS n, '{sql_str(desc)}' AS d")
    return "\n".join(parts)


def var_name(name: str) -> str:
    out = ["@"]
    cap = False
    for ch in name:
        if ch.isalnum():
            if cap:
                out.append(ch.upper())
                cap = False
            else:
                out.append(ch)
        else:
            cap = True
    ident = "".join(out)
    return ident[0] + ident[1].lower() + ident[2:] if len(ident) > 2 else ident


ABILITIES: list[tuple[str, str]] = [
    (
        "Holo-Field",
        "A Holo-Field disrupts targeting systems and grants Protection against all shooting according to the protected base's order.\n\n"
        "| Protection | Order |\n"
        "| --- | --- |\n"
        "| 5+ | First Fire / Immobilised |\n"
        "| 4+ | Advance / Fall Back |\n"
        "| 3+ | Charge / Forced March |",
    ),
    (
        "Scout",
        "This base counts as a Scout for the Exodite Scout army special rule.",
    ),
    ("Cannot Be Transported", "This base cannot be transported."),
    (
        "Fire on the Move",
        "A base with Advance may move normally, then replaces its order with unrevealed First Fire. It may perform Overwatch Fire with an additional -1 To-Hit penalty. It does not reroll shooting results of 1.",
    ),
    (
        "Free Deployment",
        "After deployment, bases with this ability may deploy anywhere in their controlling player's half of the battlefield, at least 12 cm from every enemy base. This is resolved with Infiltration; the detachment may then also infiltrate if eligible.",
    ),
    (
        "Sniper",
        "When targeting an HQ base, roll 1D6. On 4+, the target cannot redirect the attack using HQ.",
    ),
    (
        "Antigrav",
        "A base with Antigrav may make short flights over terrain, buildings, troops, and most enemy zones of control. It ignores terrain movement penalties but cannot end its movement on Impassable terrain.",
    ),
    (
        "Deep Strike (X)",
        "Choose an arrival point and scatter the first base X times, moving 3D6 cm for each scatter. Place the rest of its detachment within 6 cm. Invalid arrivals are delayed until a later turn. A detachment arriving this way cannot receive First Fire and loses 5 cm of movement that turn.",
    ),
    (
        "Elite (X)",
        "At the beginning of the battle, each detachment containing this ability adds X Elite rerolls to the army's shared pool. An Elite base may spend them on To-Hit rolls, armour saves, assault dice, Dodge rolls, or disengagement opportunity attacks; only one reroll may be used per base for each roll.",
    ),
    (
        "Lance (X+ / Y)",
        "When the base contacts a target during Charge or Consolidation, it makes a shooting attack hitting on X+ with AP Y. It follows normal shooting rules, ignores Holo-Fields and energy/deflector shields, and resolves simultaneously with Close Defences. If the target is destroyed and has lower Blocking Class, the attacker may continue moving but cannot use its Lance again that movement.",
    ),
    (
        "HQ",
        "When an HQ base is targeted by shooting, its controlling player may redirect the attack to another allied base of the same class within 6 cm. This choice is made before saving throws and does not apply in assault.",
    ),
    (
        "Leader",
        "All allied detachments with at least one base within 12 cm of a base with this ability receive a +1 bonus to their AF.",
    ),
    (
        "Attached Character",
        "At the beginning of the battle, this base must join an eligible detachment and is thereafter treated as part of it. It uses that detachment's Morale and movement characteristics, gains its movement abilities, does not occupy transport capacity, and must remain in coherency.",
    ),
    (
        "Attached Transport",
        "Attached Transports and their passengers are treated as one detachment. They use the passenger detachment's Morale, receive separate orders but activate simultaneously, have 25 cm Extended Coherency with one another, and may begin with the troops embarked or disembarked.",
    ),
    (
        "Transport (X)",
        "This base may transport X Infantry bases. Embarking or disembarking costs 5 cm of movement. A capacity of 6 or more may carry Walkers, each of which occupies two spaces.",
    ),
    (
        "Open-Topped",
        "Transported bases may shoot from an Open-Topped transport, measuring range and line of sight from the transport. They may be affected by attacks that specifically strike passengers and remain subject to their order.",
    ),
    (
        "Camouflage",
        "If a base occupies terrain that provides a cover save, improve that save by 1. Improve it by a further 1 if the entire detachment has not fired and gives up firing for the current turn. Camouflage only works against enemies more than 25 cm away and is lost for the turn when the base enters an assault.",
    ),
    (
        "Infiltration",
        "After deployment, bases with this ability may move up to 25 cm. This move cannot enter an enemy zone of control and cannot be made while the detachment is transported.",
    ),
    (
        "Artillery",
        "Artillery may fire without line of sight and ignores intervening terrain, although targets inside terrain retain its cover save. It cannot target bases at altitude or make Overwatch Fire. Indirect Fire requires First Fire and suffers -1 To-Hit when observed by a Forward Observer or -2 when unobserved.",
    ),
    (
        "Anti-Aircraft",
        "This weapon activates independently, has a 360-degree firing arc, and reduces a Flyer's Protection save by 2. It may make Overwatch Fire against targets at altitude on First Fire without the usual penalty, or on Advance with the normal -1 penalty. It suffers -1 To-Hit against ground targets.",
    ),
    (
        "Battery",
        "All weapons with this ability in the detachment combine into one template attack. The listed To-Hit value applies to a complete detachment and worsens by 1 for each missing base. Range and line of sight may be measured from any base able to fire.",
    ),
    ("Turret", "A weapon with the Turret ability has a 360-degree firing arc."),
    (
        "Reduces Cover (X)",
        "A weapon with this ability modifies the target's cover save by X.",
    ),
    (
        "Damage (+X)",
        "A weapon with this ability inflicts X additional hits against a base successfully hit by the weapon.",
    ),
    (
        "Damage (+X) in Assault",
        "After this base wins an assault duel, it inflicts X additional hits in addition to the normal hit.",
    ),
    (
        "Fear",
        "A Class 1-3 detachment entering contact with this base must pass a Morale Test or suffer -2 AF for the rest of the turn. This applies whether the Fear-causing base charges or is charged, and does not affect bases with Fear or Terror.",
    ),
    (
        "Integral Armour",
        "A base with Integral Armour does not use a hit-location chart. Every hit is resolved against the base as a whole using its armour save.",
    ),
    (
        "Wounds (X)",
        "This base has X Wounds and is destroyed only after losing all of them. A base without this ability has one Wound.",
    ),
    (
        "Close Defences (X+)",
        "Every Class 1 or 2 base that engages, or is engaged by, this base suffers an AP 0 hit on X+. Resolve the attack on contact; cover saves may be used.",
    ),
    (
        "Protection (X+)",
        "Protection is a fixed saving throw made before all other saving throws and may be used in addition to them. A base cannot benefit from more than one Protection save; use the best available.",
    ),
    (
        "Psychic Save (X+)",
        "A base with Psychic Save (X+) may use this saving throw to negate a psychic power that affects it.",
    ),
    (
        "Psyker",
        "During the Combat Phase a Psyker may use one psychic power and its conventional weapons. Powers marked Shooting follow normal shooting restrictions; Movement Phase powers may be used at any point during the Psyker's movement activation.",
    ),
    (
        "Medic",
        "Once per turn, when a Class 1 or 2 allied base within 6 cm would be destroyed, a Medic may attempt to save it. On a 5+, the base is not destroyed. A base may receive only one Medic attempt for each injury.",
    ),
    (
        "Master Strategist",
        "An army containing a base with this ability receives two additional order counters that may be kept in reserve and assigned after normal orders have been revealed.",
    ),
]


PSYCHIC_POWERS: list[tuple[str, str]] = [
    (
        "The Executioner",
        "[Combat Phase]: The Visionary projects its mind out of its body and attacks an enemy base within 45 cm and Line of Sight. Immediately resolve an assault against it. This is a Psychic Attack with AF +4. Psychic Saves are made before the assault to cancel the effect. The Visionary receives bonuses for previous attackers and counts as a previous attacker for later opponents of the target. The attack counts as an assault by a Class 2 base.",
    ),
    (
        "Fortune",
        "[Movement Phase, upon activation]: Designate an allied detachment within 12 cm. It gains 3 Fortune counters, which function as Elite counters for this turn.",
    ),
    (
        "Heal",
        "[Movement Phase, upon activation]: The Visionary gains the Medic ability until the end of the turn.",
    ),
]


SPECIAL_RULES: list[tuple[str, str]] = [
    (
        "Scout",
        "If the Exodites form your primary army, choose one of the following abilities at the start of the battle, before objectives are placed.\n\n"
        " • For every complete 3 detachments with the Scout ability, choose one Class 1 to 3 detachment to gain Infiltration; the chosen detachment need not have Scout. In addition, gain 2 orders in reserve as if the army had a detachment with Master Strategist.\n"
        " • Exodite Class 1 and 2 bases gain Camouflage for turn 1 only.\n"
        " • For every complete 2 detachments with Scout, place one forest, to a maximum of 3, at the same time as fortifications. Each forest may be no larger than 10 × 10 cm and may be placed anywhere except on another terrain feature.\n"
        " • For every complete 2 detachments with Scout, choose one enemy Class 1 to 4 detachment; it must receive an Advance order on turn 1.",
    ),
    (
        "Forester",
        "Exodites suffer no movement penalty when they move through forests.",
    ),
]


def w(name, rng, dice, tohit, ap, abilities=None):
    return {
        "name": name,
        "range": rng,
        "dice": dice,
        "tohit": tohit,
        "ap": ap,
        "abilities": abilities or [],
    }


def base(name, cls, mv, save, fa, morale, abilities, weapons, psychic_powers=None):
    return dict(
        name=name,
        cls=cls,
        mv=mv,
        save=save,
        fa=fa,
        morale=morale,
        abilities=abilities,
        weapons=weapons,
        psychic_powers=psychic_powers or [],
    )


BASES = [
    base("Fusiliers", 1, "10", "--", "+0", "6", [("Infiltration", "")],
         [w("Shard Carbine", "45 cm", "1", "5+", "0")]),
    base("Exodite Warriors", 1, "10", "--", "+1", "6", [],
         [w("Shuriken Pistol and Sword", "20 cm", "1", "5+", "0")]),
    base("Scouts", 1, "10", "--", "+1", "6",
         [("Scout", ""), ("Free Deployment", ""), ("Camouflage", ""), ("Sniper", "")],
         [w("Long Rifle", "75 cm", "1", "4+", "0")]),
    base("Travois — Starcannons", 1, "15", "--", "+1", "6",
         [("Fire on the Move", ""), ("Cannot Be Transported", "")],
         [w("Starcannon Battery", "75 cm", "2", "4+", "-1", [("Anti-Aircraft", "")])]),
    base("Travois — Bright Lance", 1, "15", "--", "+1", "6",
         [("Fire on the Move", ""), ("Cannot Be Transported", "")],
         [w("Bright Lance", "75 cm", "1", "4+", "-2")]),
    base("Travois — Missile Launcher", 1, "15", "--", "+1", "6",
         [("Fire on the Move", ""), ("Cannot Be Transported", "")],
         [w("Missile Launcher", "120 cm", "1", "3+", "0",
            [("Reduces Cover (X)", "-1"), ("Artillery", "")])]),
    base("Baron", 2, "20", "4+/6+f", "+6", "Attached",
         [("HQ", ""), ("Leader", ""), ("Elite (X)", "1"),
          ("Lance (X+ / Y)", "5+,-1"), ("Attached Character", "")],
         [w("Shuriken Pistol", "20 cm", "2", "5+", "0")]),
    base("Dragon Knights", 2, "20", "--", "+2", "6", [("Infiltration", "")],
         [w("Shard Carbine and Lance", "45 cm", "1", "5+", "0")]),
    base("Lethosaur Knights", 2, "25", "--", "+1", "6",
         [("Scout", ""), ("Infiltration", "")],
         [w("Plasma Carbine", "30 cm", "1", "4+", "-1")]),
    base("Pterosaur Knights", 2, "25", "--", "+2", "6",
         [("Antigrav", ""), ("Deep Strike (X)", "2")],
         [w("Shard Carbine", "45 cm", "1", "5+", "0")]),
    base("Raptor Knights", 2, "25", "--", "+3", "6",
         [("Scout", ""), ("Infiltration", "")],
         [w("Sword and Pistol", "20 cm", "1", "5+", "0")]),
    base("Dragoons", 2, "20", "5+", "+4", "5",
         [("Infiltration", ""), ("Elite (X)", "1"), ("Lance (X+ / Y)", "5+,0")],
         [w("Pistol and Lance", "20 cm", "1", "5+", "0")]),
    base("Salamander", 2, "15", "--", "+1", "6", [("Infiltration", "")],
         [w("Fire Breath", "45 cm", "2", "4+", "0", [("Reduces Cover (X)", "-3")])]),
    base("Visionary", 2, "20", "6+f", "+4", "Attached",
         [("Psychic Save (X+)", "4"), ("HQ", ""), ("Psyker", ""), ("Attached Character", "")],
         [w("Shuriken Pistol", "20 cm", "1", "5+", "0")],
         [("The Executioner", ""), ("Fortune", ""), ("Heal", "")]),
    base("Vyper Transport", 2, "35", "6+", "+1", "Attached",
         [("Antigrav", ""), ("Transport (X)", "1"), ("Open-Topped", ""), ("Attached Transport", "")],
         [w("Shuriken Catapult", "20 cm", "1", "5+", "0")]),
    base("Combat Walkers", 2, "25", "5+", "+1", "6", [("Infiltration", "")],
         [w("Bright Lance", "75 cm", "1", "4+", "-2"),
          w("Scatter Laser", "20 cm", "3", "5+", "0")]),
    base("Reconnaissance Walkers", 2, "25", "5+", "+2", "6",
         [("Scout", ""), ("Free Deployment", "")],
         [w("Scatter Laser", "20 cm", "3", "5+", "0")]),
    base("Pentasaur — Maelstrom Laser", 3, "15", "3+", "+6", "6", [],
         [w("Maelstrom Laser", "75 cm", "2", "4+", "-2", [("Turret", "")])]),
    base("Pentasaur — Missile Launcher", 3, "15", "3+", "+6", "6", [],
         [w("Maelstrom Missile Launcher", "90 cm", "Template", "3+", "-1",
            [("Turret", ""), ("Battery", ""), ("Artillery", ""), ("Reduces Cover (X)", "-1")])]),
    base("Pentasaur — Thermal Lance", 3, "15", "3+", "+6", "6", [],
         [w("Thermal Lance", "20 cm", "1", "3+", "-3", [("Turret", "")]),
          w("Flamer", "20 cm", "2", "4+", "0", [("Reduces Cover (X)", "-3")])]),
    base("Carnosaur", 4, "20", "2+", "+11", "5",
         [("Integral Armour", ""), ("Wounds (X)", "2"),
          ("Damage (+X) in Assault", "1"), ("Fear", "")],
         [w("Star Laser", "45 cm", "5", "5+", "-1")]),
    base("Bright Stalker", 4, "25", "3+", "+5", "5",
         [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Holo-Field", "")],
         [w("Pulse Laser", "45 cm", "1", "4+", "-1"),
          w("Bright Lance", "75 cm", "1", "4+", "-2")]),
    base("Bright Stallion", 4, "25", "3+", "+7", "5",
         [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Holo-Field", ""),
          ("Lance (X+ / Y)", "3+,-2")],
         [w("Scatter Laser", "20 cm", "3", "5+", "0")]),
    base("Fire Gale", 4, "20", "3+", "+3", "5",
         [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Holo-Field", "")],
         [w("Bright Lances", "75 cm", "2", "4+", "-2")]),
    base("Fire Reaper", 4, "20", "3+", "+3", "5",
         [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Holo-Field", "")],
         [w("Scatter Laser", "20 cm", "3", "5+", "0"),
          w("Reaper Laser", "45 cm", "4", "4+", "0")]),
    base("Fire Storm", 4, "20", "3+", "+3", "5",
         [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Holo-Field", "")],
         [w("Pulse Lances", "45 cm", "2", "4+", "0"),
          w("Missile Launcher", "90 cm", "2", "4+", "0", [("Artillery", "")])]),
    base("Towering Destroyer", 4, "15", "2+", "+5", "5",
         [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Holo-Field", "")],
         [w("Pulse Lances", "45 cm", "2", "4+", "0"),
          w("Maelstrom Laser", "90 cm", "2", "4+", "-2")]),
    base("Megadon — Assault", 4, "15", "2+", "+8", "5",
         [("Integral Armour", ""), ("Wounds (X)", "4"), ("Close Defences (X+)", "5"),
          ("Transport (X)", "6"), ("Open-Topped", "")],
         [w("Flamer", "20 cm", "4", "4+", "0",
            [("Turret", ""), ("Reduces Cover (X)", "-3")]),
          w("Heavy Thermal Lance", "30 cm", "2", "3+", "-4",
            [("Turret", ""), ("Damage (+X)", "1")])]),
    base("Megadon — Support", 4, "15", "2+", "+7", "5",
         [("Integral Armour", ""), ("Wounds (X)", "4"), ("Close Defences (X+)", "5")],
         [w("Maelstrom Laser", "75 cm", "4", "4+", "-2"),
          w("Twin Star Lance", "90 cm", "2", "3+", "-3",
            [("Turret", ""), ("Damage (+X)", "1")])]),
]


def formation(kind, name, cost, detachment_name, contents, cls, units):
    return dict(
        kind=kind,
        name=name,
        cost=cost,
        detachment=detachment_name,
        contents=contents,
        cls=cls,
        units=units,
    )


FORMATIONS = [
    formation(1, "Baron (Unique)", 125, "Baron Detachment",
              "1 Baron and 2 Dragoon bases", 2, [("Baron", 1), ("Dragoons", 2)]),
    formation(
        2, "Infantry Company", 0, "Infantry Company",
        "Compulsory: Choose 1 (Fusiliers 75 or Warriors 50); Choose 1 (Fusiliers 125 or Warriors 100); "
        "Choose 2 from Fusiliers/Warriors/Scouts/Travois. Optional: 0–1 Special or Additional Special, "
        "0–1 Additional Special, 0–5 Support, any Options.",
        1, [],
    ),
    formation(
        2, "Pentasaur Company", 0, "Pentasaur Company",
        "Compulsory: Choose 1 Pentasaur variant (discounted); Choose 2 Pentasaur variants (support prices). "
        "Optional: 0–1 Special or Additional Special, 0–1 Additional Special, 0–5 Support, any Options.",
        3, [],
    ),
    formation(
        2, "Rapid Intervention Company", 0, "Rapid Intervention Company",
        "Compulsory: Choose 1 (Dragon Knights 75 or Combat Walkers 125); Choose 1 (Dragon Knights 125 or "
        "Combat Walkers 175); Choose 2 from cavalry/walker list. Optional: 0–1 Special or Additional Special, "
        "0–1 Additional Special, 0–5 Support, any Options.",
        2, [],
    ),
    formation(
        2, "Scout Company", 0, "Scout Company",
        "Compulsory: Choose 1 (Lethosaur 75 or Raptor 100); Choose 2 (Lethosaur 125 or Raptor 150); "
        "plus further scout picks per army book. Optional: 0–1 Special or Additional Special, "
        "0–1 Additional Special, 0–5 Support, any Options.",
        2, [],
    ),
    formation(3, "Bright Stalker", 325, "Bright Stalker Detachment",
              "3 Bright Stalker bases", 4, [("Bright Stalker", 3)]),
    formation(3, "Bright Stallion", 300, "Bright Stallion Detachment",
              "3 Bright Stallion bases", 4, [("Bright Stallion", 3)]),
    formation(3, "Fire Gale", 325, "Fire Gale Detachment",
              "3 Fire Gale bases", 4, [("Fire Gale", 3)]),
    formation(3, "Fire Reaper", 325, "Fire Reaper Detachment",
              "3 Fire Reaper bases", 4, [("Fire Reaper", 3)]),
    formation(3, "Fire Storm", 325, "Fire Storm Detachment",
              "3 Fire Storm bases", 4, [("Fire Storm", 3)]),
    formation(3, "Towering Destroyer", 400, "Towering Destroyer Detachment",
              "3 Towering Destroyer bases", 4, [("Towering Destroyer", 3)]),
    formation(3, "Megadon — Assault", 275, "Megadon — Assault Detachment",
              "1 Megadon — Assault base", 4, [("Megadon — Assault", 1)]),
    formation(3, "Megadon — Support", 350, "Megadon — Support Detachment",
              "1 Megadon — Support base", 4, [("Megadon — Support", 1)]),
    formation(3, "Visionary", 75, "Visionary Detachment",
              "1 Visionary base", 2, [("Visionary", 1)]),
    formation(4, "Fusilier", 125, "Fusilier Detachment",
              "6 Fusilier bases", 1, [("Fusiliers", 6)]),
    formation(4, "Exodite Warrior", 100, "Exodite Warrior Detachment",
              "6 Exodite Warrior bases", 1, [("Exodite Warriors", 6)]),
    formation(4, "Scout", 150, "Scout Detachment",
              "4 Scout bases", 1, [("Scouts", 4)]),
    formation(4, "Travois — Starcannons", 200, "Travois — Starcannons Detachment",
              "3 Travois — Starcannons bases", 1, [("Travois — Starcannons", 3)]),
    formation(4, "Travois — Bright Lance", 150, "Travois — Bright Lance Detachment",
              "3 Travois — Bright Lance bases", 1, [("Travois — Bright Lance", 3)]),
    formation(4, "Travois — Missile Launcher", 150, "Travois — Missile Launcher Detachment",
              "3 Travois — Missile Launcher bases", 1, [("Travois — Missile Launcher", 3)]),
    formation(4, "Dragon Knight", 125, "Dragon Knight Detachment",
              "5 Dragon Knight bases", 2, [("Dragon Knights", 5)]),
    formation(4, "Lethosaur", 175, "Lethosaur Knight Detachment",
              "5 Lethosaur Knight bases", 2, [("Lethosaur Knights", 5)]),
    formation(4, "Pterosaur", 175, "Pterosaur Knight Detachment",
              "5 Pterosaur Knight bases", 2, [("Pterosaur Knights", 5)]),
    formation(4, "Raptor", 150, "Raptor Knight Detachment",
              "5 Raptor Knight bases", 2, [("Raptor Knights", 5)]),
    formation(4, "Dragoon", 175, "Dragoon Detachment",
              "5 Dragoon bases", 2, [("Dragoons", 5)]),
    formation(4, "Salamander", 150, "Salamander Detachment",
              "3 Salamander bases", 2, [("Salamander", 3)]),
    formation(4, "Combat Walker", 175, "Combat Walker Detachment",
              "3 Combat Walker bases", 2, [("Combat Walkers", 3)]),
    formation(4, "Recon Walker", 125, "Reconnaissance Walker Detachment",
              "3 Reconnaissance Walker bases", 2, [("Reconnaissance Walkers", 3)]),
    formation(4, "Pentasaur — Maelstrom Laser", 275, "Pentasaur — Maelstrom Laser Detachment",
              "3 Pentasaur — Maelstrom Laser bases", 3, [("Pentasaur — Maelstrom Laser", 3)]),
    formation(4, "Pentasaur — Missile", 150, "Pentasaur — Missile Launcher Detachment",
              "3 Pentasaur — Missile Launcher bases", 3, [("Pentasaur — Missile Launcher", 3)]),
    formation(4, "Pentasaur — Thermal", 200, "Pentasaur — Thermal Lance Detachment",
              "3 Pentasaur — Thermal Lance bases", 3, [("Pentasaur — Thermal Lance", 3)]),
    formation(4, "Carnosaur", 150, "Carnosaur Detachment",
              "1 Carnosaur base", 4, [("Carnosaur", 1)]),
    formation(5, "Vyper Detachment", 150, "Vyper Detachment",
              "6 Vyper Transport bases", 2, [("Vyper Transport", 6)]),
]


def emit_exodites_sql() -> str:
    lines = [
        "-- Exodites 3.0.0 from C:/Files/NetEpicFR300-EnglishTranslation/Exodites 300",
        "-- Upserts Exodites catalog; preserves army lists and Base/Formation ids.",
        "",
        "SET NAMES utf8mb4;",
        "",
        "SET @hasUsesCp := (",
        "    SELECT COUNT(*) FROM information_schema.COLUMNS",
        "    WHERE TABLE_SCHEMA = DATABASE()",
        "      AND TABLE_NAME = 'Codex'",
        "      AND COLUMN_NAME = 'UsesCommandPoints'",
        ");",
        "SET @sql := IF(",
        "    @hasUsesCp = 0,",
        "    'ALTER TABLE Codex ADD COLUMN UsesCommandPoints TINYINT(1) NOT NULL DEFAULT 0 AFTER CodexName',",
        "    'SELECT 1'",
        ");",
        "PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;",
        "",
        "ALTER TABLE `Base`",
        "    MODIFY Morale VARCHAR(16) NOT NULL,",
        "    MODIFY Movement VARCHAR(16) NOT NULL,",
        "    MODIFY FA VARCHAR(16) NOT NULL;",
        "ALTER TABLE Weapon",
        "    MODIFY Dice VARCHAR(32) NOT NULL,",
        "    MODIFY ArmourPenetration VARCHAR(16) NOT NULL;",
        "",
        "INSERT INTO FormationKind (FormationKindId, KindName)",
        "SELECT 1, 'Mandatory' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 1);",
        "INSERT INTO FormationKind (FormationKindId, KindName)",
        "SELECT 2, 'Company' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 2);",
        "INSERT INTO FormationKind (FormationKindId, KindName)",
        "SELECT 3, 'Special' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 3);",
        "INSERT INTO FormationKind (FormationKindId, KindName)",
        "SELECT 4, 'Support' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 4);",
        "INSERT INTO FormationKind (FormationKindId, KindName)",
        "SELECT 5, 'Option' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 5);",
        "",
        "INSERT INTO Codex (CodexName)",
        "SELECT 'Exodites'",
        "WHERE NOT EXISTS (SELECT 1 FROM Codex WHERE CodexName = 'Exodites');",
        "",
        "SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Exodites');",
        "UPDATE Codex SET UsesCommandPoints = 0 WHERE CodexId = @codexId;",
        "",
        "DELETE wsa FROM WeaponSpecialAbility wsa",
        "INNER JOIN Weapon w ON w.WeaponId = wsa.WeaponId",
        "INNER JOIN `Base` b ON b.BaseId = w.BaseId",
        "WHERE b.CodexId = @codexId;",
        "",
        "DELETE bsa FROM BaseSpecialAbility bsa",
        "INNER JOIN `Base` b ON b.BaseId = bsa.BaseId",
        "WHERE b.CodexId = @codexId;",
        "",
        "DELETE bpp FROM BasePsychicPower bpp",
        "INNER JOIN `Base` b ON b.BaseId = bpp.BaseId",
        "WHERE b.CodexId = @codexId;",
        "",
        "DELETE fd FROM FormationDetachment fd",
        "INNER JOIN Formation f ON f.FormationId = fd.FormationId",
        "WHERE f.CodexId = @codexId;",
        "",
        "DELETE dc FROM DetachmentComposition dc",
        "INNER JOIN Detachment d ON d.DetachmentId = dc.DetachmentId",
        "WHERE d.CodexId = @codexId;",
        "",
        "DELETE w FROM Weapon w",
        "INNER JOIN `Base` b ON b.BaseId = w.BaseId",
        "WHERE b.CodexId = @codexId;",
        "",
        "DELETE d FROM Detachment d WHERE d.CodexId = @codexId;",
        "",
        "DELETE FROM SpecialRule WHERE CodexId = @codexId;",
        "",
        "INSERT INTO SpecialAbility (SpecialAbilityName, Description)",
        "SELECT n, d FROM (",
        union_rows(ABILITIES),
        ") AS src",
        "WHERE NOT EXISTS (",
        "    SELECT 1 FROM SpecialAbility sa WHERE sa.SpecialAbilityName = src.n",
        ");",
        "",
        "UPDATE SpecialAbility sa",
        "INNER JOIN (",
        union_rows(
            [
                row
                for row in ABILITIES
                if row[0]
                in {
                    "Holo-Field",
                    "Scout",
                    "Cannot Be Transported",
                    "Fire on the Move",
                    "Lance (X+ / Y)",
                }
            ]
        ),
        ") AS src ON src.n = sa.SpecialAbilityName",
        "SET sa.Description = src.d;",
        "",
        "INSERT INTO PsychicPower (PsychicPowerName, Description)",
        "SELECT n, d FROM (",
        union_rows(PSYCHIC_POWERS),
        ") AS src",
        "WHERE NOT EXISTS (",
        "    SELECT 1 FROM PsychicPower pp WHERE pp.PsychicPowerName = src.n",
        ");",
        "",
        "UPDATE PsychicPower pp",
        "INNER JOIN (",
        union_rows(PSYCHIC_POWERS),
        ") AS src ON src.n = pp.PsychicPowerName",
        "SET pp.Description = src.d;",
        "",
        "INSERT INTO SpecialRule (CodexId, SpecialRuleName, Description)",
        "SELECT @codexId, n, d FROM (",
        union_rows(SPECIAL_RULES),
        ") AS src;",
        "",
        "INSERT INTO `Base` (",
        "    CodexId, BaseName, DestructionPoints,",
        "    Morale, `Class`, Movement, `Save`, FA, NumberOfTitanWeapons",
        ") VALUES",
    ]

    base_values = []
    for b in BASES:
        base_values.append(
            f"    (@codexId, '{sql_str(b['name'])}', 0, "
            f"'{sql_str(b['morale'])}', {b['cls']}, '{sql_str(b['mv'])}', "
            f"'{sql_str(b['save'])}', '{sql_str(b['fa'])}', 0)"
        )
    lines.append(",\n".join(base_values))
    lines.extend([
        "ON DUPLICATE KEY UPDATE",
        "    DestructionPoints = VALUES(DestructionPoints),",
        "    Morale = VALUES(Morale),",
        "    `Class` = VALUES(`Class`),",
        "    Movement = VALUES(Movement),",
        "    `Save` = VALUES(`Save`),",
        "    FA = VALUES(FA),",
        "    NumberOfTitanWeapons = VALUES(NumberOfTitanWeapons);",
        "",
    ])

    for b in BASES:
        lines.append(
            f"SET {var_name(b['name'])} := (SELECT BaseId FROM `Base` "
            f"WHERE CodexId = @codexId AND BaseName = '{sql_str(b['name'])}');"
        )
    lines.append("")

    weapon_rows = []
    for b in BASES:
        bid = var_name(b["name"])
        for wp in b["weapons"]:
            weapon_rows.append(
                f"    ({bid}, '{sql_str(wp['name'])}', '{sql_str(wp['range'])}', "
                f"'{sql_str(wp['dice'])}', '{sql_str(wp['tohit'])}', "
                f"'{sql_str(wp['ap'])}', 0)"
            )
    lines.extend([
        "INSERT INTO Weapon (",
        "    BaseId, `Name`, `Range`, Dice, ToHit, ArmourPenetration, IsTitanWeapon",
        ") VALUES",
        ",\n".join(weapon_rows) + ";",
        "",
    ])

    ability_rows = []
    for b in BASES:
        for aname, aval in b["abilities"]:
            ability_rows.append((var_name(b["name"]), aname, aval))
    lines.extend([
        "INSERT INTO BaseSpecialAbility (BaseId, SpecialAbilityId, AbilityValue)",
        "SELECT src.BaseId, sa.SpecialAbilityId, src.AbilityValue",
        "FROM (",
    ])
    union = []
    for i, (bid, aname, aval) in enumerate(ability_rows):
        prefix = "    SELECT" if i == 0 else "    UNION ALL SELECT"
        union.append(
            f"{prefix} {bid} AS BaseId, '{sql_str(aname)}' AS AbilityName, "
            f"'{sql_str(aval)}' AS AbilityValue"
        )
    lines.extend([
        "\n".join(union),
        ") AS src",
        "INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = src.AbilityName;",
        "",
    ])

    power_rows = []
    for b in BASES:
        for pname, pval in b["psychic_powers"]:
            power_rows.append((var_name(b["name"]), pname, pval))
    if power_rows:
        lines.extend([
            "INSERT INTO BasePsychicPower (BaseId, PsychicPowerId, AbilityValue)",
            "SELECT src.BaseId, pp.PsychicPowerId, src.AbilityValue",
            "FROM (",
        ])
        union = []
        for i, (bid, pname, pval) in enumerate(power_rows):
            prefix = "    SELECT" if i == 0 else "    UNION ALL SELECT"
            union.append(
                f"{prefix} {bid} AS BaseId, '{sql_str(pname)}' AS PowerName, "
                f"'{sql_str(pval)}' AS AbilityValue"
            )
        lines.extend([
            "\n".join(union),
            ") AS src",
            "INNER JOIN PsychicPower pp ON pp.PsychicPowerName = src.PowerName;",
            "",
        ])

    wsa_rows = []
    for b in BASES:
        bid = var_name(b["name"])
        for wp in b["weapons"]:
            for aname, aval in wp["abilities"]:
                wsa_rows.append((bid, wp["name"], aname, aval))
    if wsa_rows:
        lines.extend([
            "INSERT INTO WeaponSpecialAbility (WeaponId, SpecialAbilityId, AbilityValue)",
            "SELECT w.WeaponId, sa.SpecialAbilityId, src.AbilityValue",
            "FROM (",
        ])
        union = []
        for i, (bid, wname, aname, aval) in enumerate(wsa_rows):
            prefix = "    SELECT" if i == 0 else "    UNION ALL SELECT"
            union.append(
                f"{prefix} {bid} AS BaseId, '{sql_str(wname)}' AS WeaponName, "
                f"'{sql_str(aname)}' AS AbilityName, '{sql_str(aval)}' AS AbilityValue"
            )
        lines.extend([
            "\n".join(union),
            ") AS src",
            "INNER JOIN Weapon w ON w.BaseId = src.BaseId AND w.`Name` = src.WeaponName",
            "INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = src.AbilityName;",
            "",
        ])

    det_rows = [
        f"    (@codexId, '{sql_str(f['detachment'])}', 0, {f['cls']})"
        for f in FORMATIONS
    ]
    lines.extend([
        "INSERT INTO Detachment (",
        "    CodexId, DetachmentName, CommandPoints, `Class`",
        ") VALUES",
        ",\n".join(det_rows),
        "ON DUPLICATE KEY UPDATE",
        "    CommandPoints = VALUES(CommandPoints),",
        "    `Class` = VALUES(`Class`);",
        "",
    ])

    comp_union = []
    for f in FORMATIONS:
        for unit, count in f["units"]:
            prefix = "    SELECT" if not comp_union else "    UNION ALL SELECT"
            comp_union.append(
                f"{prefix} '{sql_str(f['detachment'])}' AS DetachmentName, "
                f"'{sql_str(unit)}' AS UnitName, {count} AS BaseCount"
            )
    if comp_union:
        lines.extend([
            "INSERT INTO DetachmentComposition (DetachmentId, BaseId, BaseCount)",
            "SELECT d.DetachmentId, b.BaseId, src.BaseCount",
            "FROM (",
            "\n".join(comp_union),
            ") AS src",
            "INNER JOIN Detachment d",
            "    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName",
            "INNER JOIN `Base` b",
            "    ON b.CodexId = @codexId AND b.BaseName = src.UnitName;",
            "",
        ])

    form_rows = [
        f"    (@codexId, {f['kind']}, '{sql_str(f['name'])}', {f['cost']}, 0, "
        f"'{sql_str(f['contents'])}', 0)"
        for f in FORMATIONS
    ]
    lines.extend([
        "INSERT INTO Formation (",
        "    CodexId, FormationKindId, FormationName, PointsCost, CommandPoints, Contents,",
        "    DestructionPoints",
        ") VALUES",
        ",\n".join(form_rows),
        "ON DUPLICATE KEY UPDATE",
        "    FormationKindId = VALUES(FormationKindId),",
        "    PointsCost = VALUES(PointsCost),",
        "    CommandPoints = VALUES(CommandPoints),",
        "    Contents = VALUES(Contents),",
        "    DestructionPoints = VALUES(DestructionPoints);",
        "",
        "INSERT INTO FormationDetachment (FormationId, DetachmentId, Quantity)",
        "SELECT f.FormationId, d.DetachmentId, 1",
        "FROM (",
    ])
    fd_union = []
    for f in FORMATIONS:
        prefix = "    SELECT" if not fd_union else "    UNION ALL SELECT"
        fd_union.append(
            f"{prefix} '{sql_str(f['name'])}' AS FormationName, "
            f"'{sql_str(f['detachment'])}' AS DetachmentName"
        )
    lines.extend([
        "\n".join(fd_union),
        ") AS src",
        "INNER JOIN Formation f",
        "    ON f.CodexId = @codexId AND f.FormationName = src.FormationName",
        "INNER JOIN Detachment d",
        "    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName;",
        "",
    ])
    return "\n".join(lines) + "\n"


def main() -> None:
    (OUT / "exodites.sql").write_text(emit_exodites_sql(), encoding="utf-8")
    print("Wrote exodites.sql")


if __name__ == "__main__":
    main()
