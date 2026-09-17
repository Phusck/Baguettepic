"""Generate necrons.sql from Necrons 3.1.0 (Palladium NetEpic 3)."""
from __future__ import annotations

from pathlib import Path

OUT = Path(__file__).resolve().parent


def sql_str(text: str) -> str:
    return text.replace("\\", "\\\\").replace("'", "''").replace("\r\n", "\n")


# Map BaseName → filename under Necrons 310/figures/ (hyphenated PNGs).
IMAGE_ALIASES = {
    "Cryptek": "cryptek.png",
    "Flayed One": "flayed-ones.png",
    "Hexmark Destroyer": "hexmark-destroyer.png",
    "Skorpekh Destroyer": "skorpekh-destroyer.png",
    "Lychguard": "lychguard.png",
    "Necron Warriors": "necron-warriors.png",
    "Immortals": "immortals.png",
    "Overlord": "overlord.png",
    "Pariah": "pariah.png",
    "Triarch Praetorians": "triarch-praetorians.png",
    "Flayed Lord": "flayed-lord.png",
    "Necron Lord": "necron-lord.png",
    "Deathmark": "deathmark.png",
    "Skorpekh Lord": "skorpekh-lord.png",
    "Destroyer": "destroyer.png",
    "Heavy Destroyer": "heavy-destroyer.png",
    "Canoptek Acanthrites": "canoptek-acanthrites.png",
    "Destroyer Lord": "destroyer-lord.png",
    "Canoptek Spyder (Assault)": "canoptek-spyder.png",
    "Canoptek Spyder (Support)": "canoptek-spyder.png",
    "Ophydian Destroyer": "ophydian-destroyer.png",
    "Tomb Blades": "tomb-blades.png",
    "Canoptek Wraiths": "canoptek-wraiths.png",
    "Triarch Stalker": "triarch-stalker.png",
    "Canoptek Doomstalker": "canoptek-doomstalker.png",
    "Canoptek Reanimator": "canoptek-reanimator.png",
    "Doomsday Ark": "doomsday-ark.png",
    "Ghost Ark": "ghost-ark.png",
    "Tesseract Ark": "tesseract-ark.png",
    "Catacomb Command Barge": "catacomb-command-barge.png",
    "Annihilation Barge": "annihilation-barge.png",
    "Doom Scythe": "doom-scythe.png",
    "Night Scythe": "night-scythe.png",
    "Night Shroud": "night-shroud.png",
    "Deceiver": "deceiver.png",
    "Tesseract Vault": "tesseract-vault.png",
    "Nightbringer": "nightbringer.png",
    "Transcendent C'tan": "transcendent-ctan.png",
    "Void Dragon": "void-dragon.png",
    "Tomb Golem": "tomb-golem.png",
    "Canoptek Tomb Sentinel": "canoptek-tomb-sentinel.png",
    "Monolith": "monolith.png",
    "Doomsday Monolith": "doomsday-monolith.png",
    "Seraptek Heavy Construct": "seraptek.png",
    "Pylon": "pylon.png",
    "Obelisk": "obelisk.png",
    "Abattoir": "abattoir.png",
    "War Barge": "war-barge.png",
    "Aeonic Orb": "aeonic-orb.png",
    "Tomb Guardian": "tomb-guardian.png",
    "Scarab Tokens": "",
}


def image_path_for(name: str) -> str:
    if name in IMAGE_ALIASES:
        return IMAGE_ALIASES[name]
    return name.lower().replace(" ", "-").replace("—", "-").replace("--", "-").replace("'", "") + ".png"


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
        "Portal",
        "The Necrons use Portals to cross long distances. Crossing a Portal allows a detachment to enter "
        "the battlefield from Reserve, or to pass from one Portal to another on the battlefield.\n\n"
        "Crossing a Portal costs 5 cm of movement to the detachment that crosses it and nothing to the "
        "base that has the Portal. The same detachment may cross several Portals during its activation. "
        "Portals are limited in the number of detachments that may exit them per turn, as well as the "
        "maximum class of bases that may cross them.\n\n"
        "Bases exiting a Portal follow the rules for exiting a transport. A detachment crossing a Portal "
        "must do so entirely. Only allied Necrons may use a Portal.\n\n"
        "| Troop | Class that may cross | Detachments that may exit |\n"
        "| --- | --- | --- |\n"
        "| Monolith and Doomsday Monolith | Class 1 | 2 detachments per turn |\n"
        "| Abattoir | Classes 1 and 2 | 1 detachment per turn per Portal still active |\n"
        "| War Barge | Classes 1, 2 and 3 | 5 detachments per turn |",
    ),
    (
        "Deathmark",
        "Deathmarks may make Intercept Fire on an off-table arrival as if it were a normal movement.\n\n"
        "If a Deathmark detachment is not yet present on the table, it may make its off-table arrival in "
        "reaction to an enemy off-table arrival. If you decide to do so, wait until the enemy bases have "
        "been placed, then you may place the Deathmark bases directly base-to-base with those of the "
        "targeted detachment; they are considered to have charged. They gain a +2 AF bonus for that turn.",
    ),
    (
        "Invasion Beams",
        "A detachment with this ability may open a Portal during its movement for a single Necron infantry "
        "detachment placed in Reserve, along its path.",
    ),
    (
        "Targeting Relay",
        "If a base with this ability scores a hit on a detachment, place a marker next to it. All bases "
        "from this codex then gain the Reduces Cover (-3) ability if they shoot at a detachment thus "
        "designated. Remove all markers during end-of-turn effects.",
    ),
    (
        "Reanimation Protocols (X+)",
        "If a detachment with bases that have this ability is not at full strength in the End-of-Turn "
        "Effects phase, but still has at least 1 base present on the table, it is possible to attempt to "
        "reanimate the losses. To do so, roll a die for each missing base; on an X+ it is reanimated. "
        "Bases thus returned to play must be in coherency with the detachment and may not be placed in "
        "an enemy base's Control Zone.",
    ),
    (
        "Scarab Generator",
        "The Necron player gains one Scarab token per base with this ability at the moment of activation "
        "in the Movement Phase of the detachment that has Scarab Generator.",
    ),
    (
        "Repair Platform",
        "Any Necron Warrior or Immortal base within 12 cm of a base with this ability gains a bonus of 1 "
        "to its Reanimation Protocols roll.",
    ),
    (
        "Resurrection Orb",
        "Once per battle, a detachment within 12 cm of a base with this ability may increase its "
        "Reanimation Protocols rolls by 1.",
    ),
    (
        "Reanimator",
        "Any detachment within 12 cm improves its Reanimation Protocols rolls by 1.",
    ),
    (
        "Outcasts",
        "Bases with this ability may never use a Portal.",
    ),
    (
        "Soulless",
        "Any detachment within 25 cm of a base with this ability is considered to have a Morale of 7, "
        "unless it is already worse (that is, a higher value). Detachments with no Morale value are not "
        "affected.",
    ),
    (
        "Doomsday Cannon",
        "The Doomsday Cannon has three firing modes; it may use only one per turn. Diffuse mode and "
        "Concentrated mode may be used only if the Ark has not moved this turn, which includes surprise "
        "attacks.",
    ),
    (
        "Anti-Gravitic Matrix",
        "Any enemy base at altitude within 25 cm of a base with this ability is affected as by a shot "
        "hitting on 4+ with AP -2 and the AA ability. If the enemy fails its save, it crashes to the "
        "ground and is automatically destroyed. This ability does not stack if several matrices overlap.",
    ),
    (
        "Containment Failure",
        "If a shard is destroyed, its necrodermis body explodes immediately. All bases within 2D6 cm "
        "suffer a hit on 3+ with AP 0; this does not affect troops in garrison.",
    ),
    (
        "Absorption",
        "Each time the Void Dragon destroys an enemy base of class 3 or more, it regains a lost Wound on "
        "a 4+ (maximum 2 per turn).",
    ),
    (
        "Reinforced Necrodermis",
        "Bases with this ability divide the damage they suffer by 2, rounded down, with a minimum of 1. "
        "That is, an attack with Damage (+3) inflicts 2 damage instead of the usual 4.",
    ),
    (
        "Organic Metal (X)",
        "A base with this ability has X Organic Metal points. Each shot that hits a target with Organic "
        "Metal points hits the Organic Metal rather than the target. Organic Metal tokens have a 1+ save "
        "and are destroyed at the first failed save.\n\n"
        "Organic Metal has no effect in assault.",
    ),
    (
        "Dimensional Translocation",
        "The War Barge is able to widen the rift in reality where it appears. To represent this, place a "
        "Template (12 cm) centred on the War Barge's point of arrival. All bases under the template "
        "(except the War Barge) are hit on 4+ with AP -3; those that survive are placed on the edges of "
        "the template, as close as possible.",
    ),
    (
        "Aeonic Orb",
        "The Aeonic Orb begins the game with three plasma tokens in its Plasma Chamber (the maximum). "
        "The Aeonic Orb regenerates 2 plasma tokens each Final Phase, during end-of-turn effects. These "
        "tokens are used to fire the Solar Flare. Unused plasma tokens may be stored and used in later "
        "turns.\n\n"
        "It is possible to make the following 3 firing modes:\n"
        "• Burst Fire, which costs 1 plasma token\n"
        "• Light Fire, which costs 2 plasma tokens\n"
        "• Powerful Fire, which costs 3 plasma tokens",
    ),
    (
        "My Will Be Done",
        "All allied class 1 detachments activating in the Movement Phase within 12 cm of a base with this "
        "ability receive +5 cm to their total movement even if the base with this ability is in a "
        "transport. Detachments embarked at the start of movement or arriving from a Portal within 12 cm "
        "of the base also benefit from this ability.",
    ),
    (
        "Engine of Destruction",
        "Only one Engine of Destruction is allowed in a Necron army per 5000 points. The Engines of "
        "Destruction are the Abattoir and the Aeonic Orb.",
    ),
    (
        "Harvesters — Assault",
        "Each Harvester used for assault grants the Parry or Entangle ability, +2 AF, and Damage (+1) in "
        "assault. Each also increases the DR by 1.",
    ),
    (
        "Scarab Tokens",
        "Scarab tokens may be used by any Necron base of class 1 or 2. Each token may be used in two ways.\n\n"
        "Assault: A class 1 or 2 base directs the Scarabs that attack the enemy. In addition to its ranged "
        "weapons, the base gains a one-use shot that uses a Template (7.5 cm), hits on 5+, has a range of "
        "20 cm, no AP, and the Reduces Cover (-1) ability. A base may benefit from only one Scarab token "
        "per turn in this way.\n\n"
        "Repair: when a base makes a Reanimation Protocols roll, you may use a Scarab token to improve the "
        "base's chance of success by 2.",
    ),
    (
        "Inorganic",
        "A base with this ability is immune to certain effects. The descriptions of those effects specify "
        "when this immunity applies.",
    ),
    (
        "Elite (X)",
        "At the beginning of the battle, your army receives a shared pool of Elite rerolls.\n\n"
        "Each detachment containing bases with Elite (X) adds X rerolls to this pool, regardless of how "
        "many Elite bases the detachment contains.\n\n"
        "During the battle, Elite rerolls may be spent to reroll dice rolled by your Elite bases. Before "
        "using them, declare the total number of dice that will be rerolled.\n\n"
        "Only one Elite reroll may be used per base for each dice roll. Consequently, only one die from an "
        "assault roll may be rerolled.\n\n"
        "Used Elite rerolls are removed from the army's pool.\n\n"
        "Elite rerolls may be used for To-Hit rolls, armour saving throws, assault rolls, Dodge rolls, "
        "and opportunity attacks made when an enemy disengages.",
    ),
    (
        "Jump Packs",
        "Bases equipped with Jump Packs may make short flights over terrain, buildings, and enemy troops.\n\n"
        "They ignore enemy zones of control except those generated by bases with the Floater, Skimmer, or "
        "Jump Packs ability.\n\n"
        "They also ignore terrain modifiers during their movement but cannot end their movement on "
        "Impassable terrain.\n\n"
        "While using this ability to move over an obstacle, the base is considered to be at altitude.",
    ),
    (
        "Hard to Hit",
        "All ranged attacks targeting a base with this ability suffer a -1 To-Hit penalty.\n\n"
        "This penalty does not apply to template weapons.",
    ),
    (
        "Deep Strike (X)",
        "The controlling player selects a point on the battlefield and places one base from the detachment "
        "at that point. The base then scatters X times, moving 3D6 cm for each scatter.\n\n"
        "If the final point is outside the battlefield, within Impassable terrain, or within the zone of "
        "control of an enemy base of the same or a higher class, the detachment does not arrive. Another "
        "attempt may be made during the following turn.\n\n"
        "Otherwise, place the first base as close as possible to the final arrival point. Place every other "
        "base in the detachment anywhere within 6 cm of the first base.\n\n"
        "A detachment entering the battlefield in this manner cannot receive a First Fire order during the "
        "turn in which it arrives. It also loses 5 cm from its total available movement during that turn.",
    ),
    (
        "HQ",
        "When an HQ base is targeted by a shooting attack, its controlling player may select another base "
        "of the same class within 6 cm as the attack's target instead.\n\n"
        "This decision must be made before any saving throws are rolled. HQ protection does not function "
        "during an assault.",
    ),
    (
        "Attached Character",
        "At the beginning of the battle, an Attached Character must join a detachment. The character and "
        "the detachment are then treated as a single detachment.\n\n"
        "The Attached Character must remain in coherency with the detachment, uses its Morale value, and "
        "adds its points cost to the detachment's total cost.\n\n"
        "Attached Characters do not occupy space in transports. A single detachment may include up to two "
        "Attached Characters.\n\n"
        "An Attached Character gains the Movement characteristic of the detachment to which it is attached, "
        "and its movement-related special abilities.",
    ),
    (
        "Psyker",
        "During the Combat Phase, a Psyker may use both one psychic power and its conventional weapons.\n\n"
        "Unless otherwise specified, a Psyker may use only one psychic power per turn.",
    ),
    (
        "Psychic Save (X+)",
        "A base with Psychic Save (X+) may use this saving throw against psychic powers.",
    ),
    (
        "Psychic Abomination",
        "Enemy Psykers within 25 cm of a base with this ability suffer a -1 penalty when using psychic "
        "powers. Bases with this ability gain a Psychic Save (2+).",
    ),
    (
        "Damage (+X) in Assault",
        "A weapon with this ability inflicts X additional hits after its base wins a duel, in addition to "
        "the normal hit.",
    ),
    (
        "Damage (+X)",
        "A weapon with this ability inflicts X additional hits against a base successfully hit by the "
        "weapon.",
    ),
    (
        "Reflex Fire",
        "A base with this ability does not suffer the normal -1 To-Hit penalty when performing Overwatch "
        "Fire.",
    ),
    (
        "Sniper",
        "When a base with the Sniper ability targets an HQ base, roll 1D6. On a result of 4+, the target "
        "cannot use its HQ ability against the Sniper's attack.",
    ),
    (
        "Infiltration",
        "These bases are stealthy and capable of approaching the enemy before the battle begins.\n\n"
        "After deployment, bases with this ability may move up to 25 cm. This movement cannot bring a base "
        "into an enemy zone of control and cannot be performed while the detachment is being transported.",
    ),
    (
        "Fear",
        "A Class 1–3 detachment that enters base-to-base contact with a base possessing this ability must "
        "pass a Morale Test or suffer a -2 AF penalty for the remainder of the turn.\n\n"
        "This applies whether the Fear-causing base charges or is itself charged.\n\n"
        "Fear has no effect against bases with the Fear or Terror ability.",
    ),
    (
        "Antigrav",
        "A base with Antigrav may make short flights over terrain, buildings, and enemy troops.\n\n"
        "It ignores terrain movement penalties and enemy zones of control except those generated by bases "
        "with Floater, Skimmer, Jump Packs, or Antigrav.\n\n"
        "It cannot end its movement on Impassable terrain. While moving over obstacles it is considered "
        "to be at altitude.",
    ),
    (
        "Heavy Antigrav",
        "Bases with Heavy Antigrav follow the rules for Antigrav / Heavy Skimmer but cannot perform "
        "Pop-up Attacks.",
    ),
    (
        "Integral Armour",
        "A base with Integral Armour does not use a hit-location chart. Every hit is resolved against the "
        "base as a whole.",
    ),
    (
        "Flyer",
        "Flyers may deploy on the battlefield or begin off-table (they cannot enter before Turn 2).\n\n"
        "At altitude, Flyers move in a straight line with unlimited Movement (minimum 45 cm), ignore "
        "terrain and most zones of control, and use special assault and bombing rules. See the Flyer "
        "rules for further details.",
    ),
    (
        "Interceptor",
        "A detachment with this ability may perform Aerial Interceptions. See the Flyer rules for further "
        "details.",
    ),
    (
        "Transport (X)",
        "A base with Transport (X) may transport X Infantry bases.\n\n"
        "Entering or leaving a transport costs the transported bases 5 cm of movement. When a base leaves "
        "a transport, place it in contact with the transporting base.",
    ),
    (
        "Attached Transport",
        "Attached Transports and the bases they transport are treated as a single detachment.",
    ),
    (
        "Anti-Aircraft",
        "These weapons operate independently and may be activated separately from a base's other weapons.\n\n"
        "If the base has a First Fire order, these weapons may perform Overwatch Fire against targets at "
        "altitude without suffering the usual To-Hit penalty. They may also perform Overwatch Fire while "
        "the base has an Advance order, but suffer the normal -1 To-Hit penalty.\n\n"
        "Weapons with this ability always have a 360 degree firing arc and reduce a Flyer's Protection "
        "save by 2.\n\n"
        "When firing at targets that are not at altitude, these weapons function normally but suffer a "
        "-1 To-Hit penalty.",
    ),
    (
        "Turret",
        "A weapon with the Turret ability has a 360 degree firing arc.",
    ),
    (
        "Template (X)",
        "Templates have an area of effect and may therefore affect more than one target.\n\n"
        "Any base whose centre is covered by a template may be hit, depending on the template weapon's "
        "To-Hit roll.",
    ),
    (
        "Close Defences (X+)",
        "Every Class 1 or 2 base that engages, or is engaged by, a base with Close Defences suffers a hit "
        "on X+ with AP 0.\n\n"
        "Resolve the attack when the bases make contact. Cover saves may be used against Close Defences.",
    ),
    (
        "Wounds (X)",
        "A base with this ability has X Wounds, allowing it to survive multiple injuries.\n\n"
        "By default, a base has only one Wound.",
    ),
    (
        "Terror",
        "A detachment engaged in an assault by a base with the Terror ability must make a Morale Test with "
        "a -1 modifier.\n\n"
        "If the test is failed, the detachment immediately receives a Fall Back order but does not make a "
        "Fall Back move.\n\n"
        "A detachment attempting to engage a base with Terror must also pass a Morale Test with a -1 "
        "modifier or stop before entering the Terror-causing base's zone of control.\n\n"
        "Bases with Terror are immune to Terror.",
    ),
    (
        "Bombing (X)",
        "Flyers and Floating bases at altitude may drop X bombs during their movement. Resolve each attack "
        "immediately during the movement, following the normal shooting procedure.\n\n"
        "Bombs cannot be dropped while the detachment has a Charge order and cannot affect targets at "
        "altitude.",
    ),
    (
        "Agile",
        "A Titan or Praetorian with this ability is not limited to a total of 90 degrees of turning during "
        "each turn.",
    ),
    (
        "Dread (-X)",
        "When activated during the Combat Phase, a base with this ability may force one enemy detachment "
        "with at least one base within 20 cm to make a Morale Test with a -X modifier.",
    ),
    (
        "Dark Presence (-X / Y cm)",
        "Enemy detachments with at least one base within Y cm of a base with this ability suffer a -X "
        "penalty to Morale Tests.",
    ),
    (
        "Redeployment (X)",
        "A base with this ability allows its controlling player to redeploy X detachments at the beginning "
        "of the battle.\n\n"
        "After both players have finished deploying their armies, but before resolving Infiltration, the "
        "player may reposition X detachments according to the normal deployment rules.",
    ),
    (
        "Leader",
        "All allied detachments with at least one base within 12 cm of a base with this ability receive a "
        "+1 bonus to their AF.",
    ),
    (
        "Master Strategist",
        "An army containing a base with this ability receives two additional order counters that may be "
        "kept in reserve and assigned after normal orders have been revealed.",
    ),
    (
        "Parry",
        "A base with this ability ignores the first outnumbering die during an assault.\n\n"
        "Consequently, the opposing side only begins receiving outnumbering dice when the base fights its "
        "third opponent.",
    ),
    (
        "Entangle",
        "When a base with this ability makes contact with an enemy base that has a hit-location chart, it "
        "may immobilise one of the enemy base's weapons. The effects of that weapon are cancelled for the "
        "remainder of the turn.\n\n"
        "If two opposing bases both possess such weapons, the abilities cancel one another and both "
        "weapons become entangled.",
    ),
    (
        "Duellist",
        "A base with this ability chooses the order in which its assault duels are resolved.",
    ),
    (
        "Dodge (X+)",
        "When a base with this ability loses Wounds in an assault, roll one die for each Wound lost. For "
        "each result of X+, the base does not lose that Wound.\n\n"
        "Dodge may also be used against hits caused by Close Defences.",
    ),
    (
        "Reduces Cover (X)",
        "A weapon with this ability worsens the target's cover save by X.",
    ),
    (
        "Damages Buildings (AP -X / Y)",
        "A weapon with this ability damages buildings. Buildings hit by the weapon suffer Y damage with "
        "Armour Penetration -X.",
    ),
    (
        "Damages Buildings (AP -X / Y) in Assault",
        "In all other respects, this ability functions in the same manner as Damages Buildings.",
    ),
    (
        "First Strike (X)",
        "A weapon with this ability may attack a base in contact with it immediately before an assault is "
        "resolved.\n\n"
        "Resolve the attack after the assault has been selected for activation but before resolving "
        "anything else. It is treated as a shooting attack, but its To-Hit roll never suffers penalties "
        "and it ignores Shields.\n\n"
        "The target may make a normal saving throw. Damage inflicted by First Strike attacks counts "
        "towards the final combat result.",
    ),
    (
        "Subterranean Fire",
        "Attacks with this ability ignore Energy Shields, Energy Fields, and Deflector Shields.\n\n"
        "They have no effect against Skimmers or bases at altitude.\n\n"
        "Against a base with a hit-location chart, Subterranean Fire always hits its lowest location, "
        "Location 1.",
    ),
    (
        "Reroll Assault Dice",
        "A base with this ability may reroll its assault dice. If it does so, it must reroll all of them.",
    ),
]


PSYCHIC_POWERS: list[tuple[str, str]] = [
    (
        "Harbinger of Despair",
        "[Movement Phase, on activation]: The Cryptek gains the Fear and Dread (-1) abilities for the "
        "rest of the turn.",
    ),
    (
        "Harbinger of Destruction",
        "[Combat Phase, Shooting]: The Cryptek makes an attack with a range of 60 cm, hitting on 3+ with "
        "AP -2.",
    ),
    (
        "Harbinger of Eternity",
        "[Movement Phase, on activation]: The Cryptek gains the Reanimator ability for this turn.",
    ),
    (
        "Meteor",
        "[Combat Phase, Shooting]: Place a Template (7.5 cm) at 45 cm and in Line of Sight. The template "
        "hits on 3+, AP -3, and Damages Buildings (AP -3/3).",
    ),
    (
        "Time's Arrow",
        "[Combat Phase, Shooting]: Choose a target at 45 cm and in Line of Sight. It is hit on 3+ with "
        "AP -4 and Damage (+1).",
    ),
    (
        "Seismic Assault",
        "[Combat Phase, Shooting]: Place a Template (12 cm) at 45 cm and in Line of Sight. This template "
        "hits on 3+ with AP 0; the template has the Reduces Cover (-1) and Subterranean Fire abilities.",
    ),
    (
        "Deadly Gas",
        "[Combat Phase, Shooting]: Place a Template (7.5 cm) at 45 cm and in Line of Sight of the "
        "Nightbringer. The template hits class 1 and 2 bases on 3+, otherwise on 5+. This attack is a "
        "Psychic Power.",
    ),
    (
        "Voltaic Storm",
        "[Combat Phase, Shooting]: Choose an enemy detachment of class 3 or more at 45 cm and in Line of "
        "Sight of the Void Dragon. The detachment suffers 1D3 hits on 2+ with AP -3 that Reduce Cover "
        "(-3).",
    ),
    (
        "World Pain",
        "Passive permanent power. Enemy detachments within 20 cm of the Transcendent C'tan do not benefit "
        "from cover saves. This is a Psychic Power.",
    ),
]


SPECIAL_RULES: list[tuple[str, str]] = [
    (
        "Reserve",
        "The Necrons strike suddenly and vanish without leaving a trace. Their mastery of teleportation "
        "gives them tactical opportunities for redeployment and an optimal distribution of their forces.\n\n"
        "During army deployment, any detachment may be placed in Reserve so long as it has a means of "
        "arriving on the battlefield, such as Portals large enough for it or special rules or abilities "
        "such as Deep Strike. Detachments in Reserve receive orders normally, but may activate only to "
        "join the field during their activation.\n\n"
        "A detachment in Reserve that no longer has a means of entering the battlefield is considered "
        "destroyed.",
    ),
    (
        "Phase Out",
        "Necron commanders follow their own patterns and sometimes vanish without warning. When a Necron "
        "detachment with several bases is Broken, it must make a Phase Out roll. To do so, roll 1D6: on a "
        "2+ nothing happens; otherwise they disappear from the battlefield and are considered destroyed. "
        "If there is a character attached to the detachment, this roll automatically succeeds.",
    ),
    (
        "Engines of Destruction",
        "Only one Engine of Destruction is allowed in a Necron army per 5000 points. The Engines of "
        "Destruction are the Abattoir and the Aeonic Orb.",
    ),
    (
        "Scarabs",
        "Canoptek Scarabs are small beetle-like robots, constantly repairing damaged Necrons.\n\n"
        "Scarab tokens may be used by any Necron base of class 1 or 2. Each token may be used in two ways.\n\n"
        "Assault: A class 1 or 2 base directs the Scarabs that attack the enemy. In addition to its ranged "
        "weapons, the base gains a one-use shot that uses a Template (7.5 cm), hits on 5+, has a range of "
        "20 cm, no AP, and the Reduces Cover (-1) ability. A base may benefit from only one Scarab token "
        "per turn in this way.\n\n"
        "Repair: when a base makes a Reanimation Protocols roll, you may use a Scarab token to improve the "
        "base's chance of success by 2.",
    ),
    (
        "Necrons Titan Hit Location Chart",
        "### Abattoir\n\n"
        "| D6 | Location |\n"
        "| --- | --- |\n"
        "| 1 | Harvesters |\n"
        "| 2–3 | Hull (Abattoir) |\n"
        "| 4 | Portals (Abattoir) |\n"
        "| 5 | Crystal |\n"
        "| 6 | Player's choice |\n\n"
        "### War Barge\n\n"
        "| D6 | Location Front / Rear |\n"
        "| --- | --- |\n"
        "| 1 | Antigrav Generator |\n"
        "| 2–3 | Portal (War Barge) / Hull |\n"
        "| 4 | Hull (front) / Reactor (rear) |\n"
        "| 5 | Bridge |\n"
        "| 6 | Player's choice |\n\n"
        "### Aeonic Orb\n\n"
        "| D6 | Location |\n"
        "| --- | --- |\n"
        "| 1 | Base |\n"
        "| 2 | Hull |\n"
        "| 3 | Weapon |\n"
        "| 4 | Fire Control |\n"
        "| 5 | Power Rings |\n"
        "| 6 | Player's choice |\n\n"
        "### Tomb Guardian\n\n"
        "| D6 | Location Front / Rear |\n"
        "| --- | --- |\n"
        "| 1–2 | Legs |\n"
        "| 3 | Hull |\n"
        "| 4 | Weapon |\n"
        "| 5 | Head (front) / Reactor (rear) |\n"
        "| 6 | Player's choice |",
    ),
    (
        "Necrons Titan Damage Effects",
        "Damage effects are progressive: the first damage to a location applies the first effect, and "
        "further damage applies the following effects on the list.\n\n"
        "### Hull\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | — |\n"
        "| 2–3 | 1 additional damage |\n"
        "| 4+ | 2 additional damage |\n\n"
        "### Weapon\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | Weapon Damaged (Repair on 4+) |\n"
        "| 2 | Weapon Destroyed |\n"
        "| 3+ | Damage to the Hull |\n\n"
        "### Portal (Abattoir)\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | 1 Portal Destroyed |\n"
        "| 2 | 1 Portal Destroyed |\n"
        "| 3 | 1 Portal Destroyed, 1 additional damage |\n"
        "| 4 | 1 Portal Destroyed, 1 additional damage |\n"
        "| 5+ | Damage to the Hull |\n\n"
        "### Harvesters\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | — |\n"
        "| 2–5 | 1 Harvester Damaged (Repair on 4+) |\n"
        "| 6+ | Damage to the Hull |\n\n"
        "### Leg / Antigrav Generator / Base / Fire Control\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | -5 cm of base movement (Repair on 4+) |\n"
        "| 2 | an additional -5 cm of base movement (Repair on 4+) (from this damage, if the titan is "
        "destroyed it falls) |\n"
        "| 3 | Immobilised, 1 additional damage |\n"
        "| 4+ | Damage to the Hull |\n\n"
        "### Hull (Abattoir)\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1–2 | — |\n"
        "| 3–4 | 1 additional damage |\n"
        "| 5+ | 2 additional damage |\n\n"
        "### Head / Bridge\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | -1D6 to AF (Repair on 4+) |\n"
        "| 2 | May receive an order only on a 4+ (Repair on 4+), 1 additional damage |\n"
        "| 3+ | Damage to the Hull |\n\n"
        "### Crystal\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | -2 to AF in assault (Repair on 4+) |\n"
        "| 2 | Total movement reduced by 5 cm (Repair on 4+) |\n"
        "| 3 | Destroyed, total movement reduced by 5 cm |\n"
        "| 4+ | Damage to the Hull |\n\n"
        "### Portal (War Barge)\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | Reduce to 4 the number of detachments that may cross the Portal |\n"
        "| 2 | Reduce to 2 the number of detachments that may cross the Portal |\n"
        "| 3 | Reduce to 1 the number of detachments that may cross the Portal, 1 additional damage |\n"
        "| 4+ | Portal destroyed, Damage to the Hull |\n\n"
        "### Reactor\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | 1 additional damage (from this damage, if the titan is destroyed it explodes) |\n"
        "| 2 | 1 additional damage |\n"
        "| 3+ | Reactor severely damaged, 1D3 additional damage |\n\n"
        "### Power Rings\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | The Solar Flare can no longer fire (Repair on 4+) |\n"
        "| 2 | Gains one fewer plasma token per turn (Repair on 4+) |\n"
        "| 3 | Destroyed, gains one fewer plasma token per turn, 1 additional damage |\n"
        "| 4+ | Damage to the Hull |",
    ),
]


def w(name, rng, dice, tohit, ap, abilities=None, titan=0):
    return {
        "name": name,
        "range": rng,
        "dice": dice,
        "tohit": tohit,
        "ap": ap,
        "titan": titan,
        "abilities": abilities or [],
    }


def melee(name):
    return w(name, "--", "--", "--", "--")


def base(name, cls, mv, save, fa, morale, abilities, weapons, psychic_powers=None, titan=0):
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
        titan=titan,
    )


CTAN_POWERS = [("Meteor", ""), ("Time's Arrow", ""), ("Seismic Assault", "")]
CTAN_CORE = [
    ("Containment Failure", ""),
    ("Integral Armour", ""),
    ("Psychic Save (X+)", "2"),
    ("Psyker", ""),
    ("Antigrav", ""),
    ("Wounds (X)", "4"),
    ("Terror", ""),
    ("Inorganic", ""),
    ("Reinforced Necrodermis", ""),
]


TITAN_WEAPON_PROFILES = [
    w("Gauss Blaster", "75 cm", "5", "4+", "-1", [], titan=1),
    w(
        "Annihilation Crystal — Concentrated",
        "75 cm",
        "1",
        "3+",
        "-3",
        [("Damage (+X)", "1")],
        titan=1,
    ),
    w(
        "Annihilation Crystal — Saturation",
        "75 cm",
        "Template",
        "3+",
        "-1",
        [("Template (X)", "7.5 cm"), ("Reduces Cover (X)", "-1")],
        titan=1,
    ),
    w(
        "Phase Claw — Shooting",
        "30 cm",
        "2",
        "3+",
        "-2",
        [],
        titan=1,
    ),
    w(
        "Phase Claw — Assault",
        "--",
        "--",
        "--",
        "--",
        [
            ("Reroll Assault Dice", ""),
            ("Damage (+X) in Assault", "1"),
            ("Damages Buildings (AP -X / Y) in Assault", "5,3"),
            ("First Strike (X)", "1/2+/AP -5"),
            ("Damage (+X)", "1"),
        ],
        titan=1,
    ),
    w(
        "Hyperphase Blade — Shooting",
        "30 cm",
        "2",
        "3+",
        "-2",
        [],
        titan=1,
    ),
    w(
        "Hyperphase Blade — Assault",
        "--",
        "--",
        "--",
        "--",
        [
            ("Damage (+X) in Assault", "2"),
            ("Damages Buildings (AP -X / Y) in Assault", "4,3"),
            ("First Strike (X)", "1/2+/AP -4"),
            ("Damage (+X)", "1"),
        ],
        titan=1,
    ),
    w("Conversion Beam (0–20 cm)", "0–20 cm", "2", "5+", "-2", [], titan=1),
    w("Conversion Beam (21–44 cm)", "21–44 cm", "2", "4+", "-3", [], titan=1),
    w("Conversion Beam (45–75 cm)", "45–75 cm", "2", "3+", "-4", [], titan=1),
    w(
        "Disintegrator Beam",
        "20 cm",
        "3",
        "3+",
        "-3",
        [("Damage (+X)", "1")],
        titan=1,
    ),
]


BASES = [
    # Infantry
    base(
        "Cryptek",
        1,
        "10",
        "5+/6+f",
        "+2",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Psychic Save (X+)", "4"),
            ("Resurrection Orb", ""),
            ("Inorganic", ""),
            ("Psyker", ""),
        ],
        [
            w("Eldritch Lance", "60 cm", "1", "4+", "-2"),
            w("Staff of Light", "30 cm", "2", "4+", "-2"),
        ],
        [
            ("Harbinger of Despair", ""),
            ("Harbinger of Destruction", ""),
            ("Harbinger of Eternity", ""),
        ],
    ),
    base(
        "Flayed One",
        1,
        "10",
        "5+",
        "+3",
        "--",
        [
            ("Infiltration", ""),
            ("Fear", ""),
            ("Reanimation Protocols (X+)", "6"),
            ("Inorganic", ""),
            ("Outcasts", ""),
        ],
        [melee("Claws")],
    ),
    base(
        "Hexmark Destroyer",
        1,
        "15",
        "5+",
        "+2",
        "--",
        [("Reanimation Protocols (X+)", "6"), ("Inorganic", "")],
        [w("Enmitic Disintegrator", "20 cm", "2", "4+", "0", [("Reduces Cover (X)", "-3")])],
    ),
    base(
        "Skorpekh Destroyer",
        1,
        "15",
        "5+",
        "+6",
        "--",
        [
            ("Reanimation Protocols (X+)", "6"),
            ("Damage (+X) in Assault", "1"),
            ("Inorganic", ""),
        ],
        [melee("Hyperphase Blade")],
    ),
    base(
        "Lychguard",
        1,
        "10",
        "4+",
        "+5",
        "--",
        [
            ("Elite (X)", "2"),
            ("Dodge (X+)", "5"),
            ("Reanimation Protocols (X+)", "6"),
            ("Inorganic", ""),
        ],
        [melee("Hyperphase Blade")],
    ),
    base(
        "Necron Warriors",
        1,
        "10",
        "5+",
        "+1",
        "--",
        [("Reanimation Protocols (X+)", "6"), ("Inorganic", "")],
        [w("Gauss Flayer", "45 cm", "1", "5+", "-1")],
    ),
    base(
        "Immortals",
        1,
        "10",
        "5+",
        "+2",
        "--",
        [("Reanimation Protocols (X+)", "6"), ("Inorganic", "")],
        [w("Gauss Blaster", "60 cm", "2", "5+", "-1")],
    ),
    base(
        "Overlord",
        1,
        "10",
        "4+/5+f",
        "+7",
        "Attached",
        [
            ("Resurrection Orb", ""),
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Inorganic", ""),
            ("My Will Be Done", ""),
            ("Damage (+X) in Assault", "1"),
            ("Master Strategist", ""),
        ],
        [w("Ancient Staff of Light", "45 cm", "2", "4+", "-2")],
    ),
    base(
        "Pariah",
        1,
        "10",
        "5+",
        "+4",
        "--",
        [
            ("Elite (X)", "1"),
            ("Inorganic", ""),
            ("Reanimation Protocols (X+)", "6"),
            ("Psychic Abomination", ""),
            ("Soulless", ""),
        ],
        [w("Warscythes", "45 cm", "1", "5+", "-1")],
    ),
    base(
        "Triarch Praetorians",
        1,
        "15",
        "5+",
        "+4",
        "--",
        [
            ("Elite (X)", "1"),
            ("Inorganic", ""),
            ("Reanimation Protocols (X+)", "6"),
            ("Jump Packs", ""),
        ],
        [w("Rod of Covenant", "20 cm", "1", "4+", "-2")],
    ),
    base(
        "Flayed Lord",
        1,
        "10",
        "4+/5+f",
        "+5",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Outcasts", ""),
            ("Infiltration", ""),
            ("Fear", ""),
            ("Elite (X)", "1"),
            ("Resurrection Orb", ""),
            ("Inorganic", ""),
        ],
        [melee("Claws")],
    ),
    base(
        "Necron Lord",
        1,
        "10",
        "4+/5+f",
        "+5",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Inorganic", ""),
            ("Resurrection Orb", ""),
            ("Leader", ""),
        ],
        [w("Staff of Light", "30 cm", "2", "4+", "-2")],
    ),
    base(
        "Deathmark",
        1,
        "10",
        "5+",
        "+1",
        "--",
        [
            ("Deep Strike (X)", "1"),
            ("Sniper", ""),
            ("Inorganic", ""),
            ("Deathmark", ""),
            ("Reanimation Protocols (X+)", "6"),
        ],
        [w("Synaptic Disintegrator", "45 cm", "1", "4+", "-1")],
    ),
    base(
        "Skorpekh Lord",
        1,
        "15",
        "4+/5+f",
        "+7",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Damage (+X) in Assault", "1"),
            ("Resurrection Orb", ""),
            ("Inorganic", ""),
        ],
        [w("Enmitic Annihilator", "20 cm", "2", "4+", "0")],
    ),
    # Cavalry
    base(
        "Destroyer",
        2,
        "30",
        "5+",
        "+1",
        "--",
        [("Antigrav", ""), ("Reanimation Protocols (X+)", "6"), ("Inorganic", "")],
        [w("Gauss Cannon", "45 cm", "1", "4+", "-1")],
    ),
    base(
        "Heavy Destroyer",
        2,
        "30",
        "5+",
        "+1",
        "--",
        [("Antigrav", ""), ("Reanimation Protocols (X+)", "6"), ("Inorganic", "")],
        [w("Heavy Gauss Cannon", "60 cm", "2", "4+", "-2")],
    ),
    base(
        "Canoptek Acanthrites",
        2,
        "30",
        "5+",
        "+3",
        "--",
        [
            ("Antigrav", ""),
            ("Reanimation Protocols (X+)", "6"),
            ("Hard to Hit", ""),
            ("Inorganic", ""),
        ],
        [w("Cutting Beam", "20 cm", "1", "4+", "-2")],
    ),
    base(
        "Destroyer Lord",
        2,
        "30",
        "4+/5+f",
        "+5",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Inorganic", ""),
            ("Antigrav", ""),
            ("Resurrection Orb", ""),
            ("Leader", ""),
        ],
        [w("Staff of Light", "30 cm", "2", "4+", "-2")],
    ),
    base(
        "Canoptek Spyder (Assault)",
        2,
        "15",
        "4+",
        "+3",
        "--",
        [
            ("Antigrav", ""),
            ("Reanimation Protocols (X+)", "5"),
            ("Scarab Generator", ""),
            ("Inorganic", ""),
        ],
        [melee("Claws")],
    ),
    base(
        "Canoptek Spyder (Support)",
        2,
        "15",
        "4+",
        "+1",
        "--",
        [
            ("Antigrav", ""),
            ("Reanimation Protocols (X+)", "5"),
            ("Scarab Generator", ""),
            ("Inorganic", ""),
        ],
        [w("Twin Particle Beamer", "20 cm", "1", "4+", "-2")],
    ),
    base(
        "Ophydian Destroyer",
        2,
        "20",
        "5+",
        "+4",
        "--",
        [
            ("Jump Packs", ""),
            ("Deep Strike (X)", "2"),
            ("Hard to Hit", ""),
            ("Reanimation Protocols (X+)", "6"),
            ("Inorganic", ""),
        ],
        [melee("Hyperphase Blade")],
    ),
    base(
        "Tomb Blades",
        2,
        "30",
        "5+",
        "+2",
        "--",
        [
            ("Antigrav", ""),
            ("Hard to Hit", ""),
            ("Infiltration", ""),
            ("Reanimation Protocols (X+)", "6"),
            ("Inorganic", ""),
        ],
        [w("Twin Tesla Carbines", "30 cm", "2", "4+", "0")],
    ),
    base(
        "Canoptek Wraiths",
        2,
        "25",
        "4+f",
        "+4",
        "--",
        [("Jump Packs", ""), ("Reanimation Protocols (X+)", "6"), ("Inorganic", "")],
        [melee("Whip Coils")],
    ),
    # Walkers
    base(
        "Triarch Stalker",
        2,
        "20",
        "3+/6+f",
        "+3",
        "--",
        [
            ("Reanimation Protocols (X+)", "6"),
            ("Targeting Relay", ""),
            ("Inorganic", ""),
        ],
        [w("Heat Ray", "45 cm", "1", "4+", "-2", [("Reduces Cover (X)", "-3")])],
    ),
    base(
        "Canoptek Doomstalker",
        2,
        "20",
        "4+/5+f",
        "+2",
        "--",
        [
            ("Reanimation Protocols (X+)", "6"),
            ("Reflex Fire", ""),
            ("Inorganic", ""),
        ],
        [
            w("Doomsday Blaster", "45 cm", "1", "3+", "-2"),
            w("Gauss Blaster", "45 cm", "2", "5+", "0"),
        ],
    ),
    base(
        "Canoptek Reanimator",
        2,
        "20",
        "4+/5+f",
        "+2",
        "--",
        [
            ("Reanimator", ""),
            ("Reanimation Protocols (X+)", "6"),
            ("Reflex Fire", ""),
            ("Inorganic", ""),
        ],
        [w("Gauss Atomiser", "45 cm", "1", "4+", "-1")],
    ),
    # Vehicles
    base(
        "Doomsday Ark",
        3,
        "20",
        "3+/5+f",
        "+0",
        "--",
        [("Inorganic", ""), ("Antigrav", "")],
        [
            w(
                "Doomsday Cannon — Diffuse",
                "90 cm",
                "Template",
                "4+",
                "-2",
                [("Doomsday Cannon", ""), ("Template (X)", "7.5 cm")],
            ),
            w(
                "Doomsday Cannon — Concentrated",
                "90 cm",
                "1",
                "3+",
                "-3",
                [("Doomsday Cannon", ""), ("Damage (+X)", "1")],
            ),
            w(
                "Doomsday Cannon — Advance",
                "75 cm",
                "1",
                "4+",
                "-3",
                [("Doomsday Cannon", "")],
            ),
        ],
    ),
    base(
        "Ghost Ark",
        3,
        "25",
        "3+/5+f",
        "+0",
        "--",
        [
            ("Inorganic", ""),
            ("Antigrav", ""),
            ("Transport (X)", "2"),
            ("Attached Transport", ""),
            ("Repair Platform", ""),
        ],
        [w("Gauss Flayer Array", "30 cm", "1", "4+", "0")],
    ),
    base(
        "Tesseract Ark",
        3,
        "30",
        "3+/5+f",
        "+0",
        "--",
        [("Inorganic", ""), ("Antigrav", "")],
        [
            w("Singularity Chamber — Concentrated", "45 cm", "1", "3+", "-3"),
            w("Singularity Chamber — Diffuse", "45 cm", "3", "4+", "0"),
            w("Tesla Cannon", "45 cm", "1", "5+", "0"),
        ],
    ),
    base(
        "Catacomb Command Barge",
        3,
        "30",
        "3+/5+f",
        "+5",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Leader", ""),
            ("Antigrav", ""),
            ("Resurrection Orb", ""),
            ("Inorganic", ""),
        ],
        [w("Tesla Cannon", "45 cm", "1", "4+", "-1")],
    ),
    base(
        "Annihilation Barge",
        3,
        "30",
        "3+/5+f",
        "+0",
        "--",
        [("Inorganic", ""), ("Antigrav", "")],
        [
            w("Tesla Destructors", "45 cm", "2", "4+", "-1"),
            w("Tesla Cannon", "45 cm", "1", "5+", "0"),
        ],
    ),
    base(
        "Doom Scythe",
        3,
        "--",
        "3+/5+f",
        "+5",
        "--",
        [
            ("Integral Armour", ""),
            ("Dodge (X+)", "5"),
            ("Interceptor", ""),
            ("Inorganic", ""),
            ("Flyer", ""),
        ],
        [
            w("Death Ray", "20 cm", "1", "3+", "-2"),
            w("Twin Tesla Destructor", "30 cm", "2", "4+", "-1"),
        ],
    ),
    base(
        "Night Scythe",
        3,
        "--",
        "3+/5+f",
        "+4",
        "--",
        [
            ("Integral Armour", ""),
            ("Dodge (X+)", "5"),
            ("Inorganic", ""),
            ("Interceptor", ""),
            ("Invasion Beams", ""),
            ("Flyer", ""),
        ],
        [w("Twin Tesla Destructor", "30 cm", "2", "4+", "-1")],
    ),
    base(
        "Night Shroud",
        3,
        "--",
        "3+/5+f",
        "+2",
        "--",
        [("Integral Armour", ""), ("Inorganic", ""), ("Flyer", "")],
        [
            w("Twin Tesla Destructor", "30 cm", "2", "3+", "-1"),
            w(
                "Death Sphere",
                "Bomb",
                "Template",
                "3+",
                "-3",
                [("Bombing (X)", "1"), ("Template (X)", "7.5 cm")],
            ),
        ],
    ),
    # Knights / C'tan
    base(
        "Deceiver",
        4,
        "25",
        "2+/4+f",
        "+11",
        "--",
        CTAN_CORE
        + [
            ("Dark Presence (-X / Y cm)", "2, 20"),
            ("Dread (-X)", "0"),
            ("Redeployment (X)", "1D3"),
            ("Damage (+X) in Assault", "1"),
        ],
        [melee("Star-God Fists")],
        CTAN_POWERS,
    ),
    base(
        "Tesseract Vault",
        4,
        "20",
        "2+/4+f",
        "+5",
        "--",
        CTAN_CORE,
        [w("Tesla Sphere", "45 cm", "6", "4+", "0")],
        CTAN_POWERS,
    ),
    base(
        "Nightbringer",
        4,
        "25",
        "2+/4+f",
        "+11",
        "--",
        CTAN_CORE
        + [
            ("Damage (+X) in Assault", "3"),
            ("Close Defences (X+)", "5"),
        ],
        [melee("Scythe of the Nightbringer")],
        CTAN_POWERS + [("Deadly Gas", "")],
    ),
    base(
        "Transcendent C'tan",
        4,
        "25",
        "2+/4+f",
        "+11",
        "--",
        CTAN_CORE
        + [
            ("Damage (+X) in Assault", "1"),
            ("Duellist", ""),
            ("Close Defences (X+)", "4"),
            ("Parry", ""),
        ],
        [melee("Crackling Tendrils")],
        CTAN_POWERS + [("World Pain", "")],
    ),
    base(
        "Void Dragon",
        4,
        "25",
        "2+/4+f",
        "+11",
        "--",
        CTAN_CORE
        + [
            ("Damage (+X) in Assault", "2"),
            ("Absorption", ""),
        ],
        [melee("Spear of the Void Dragon")],
        CTAN_POWERS + [("Voltaic Storm", "")],
    ),
    base(
        "Tomb Golem",
        4,
        "20",
        "2+/3+f",
        "+5",
        "--",
        [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Inorganic", "")],
        [w("Eldritch Cannon", "45 cm", "2", "4+", "-2")],
    ),
    # Super-heavies
    base(
        "Canoptek Tomb Sentinel",
        4,
        "15",
        "2+/5+f",
        "+7",
        "--",
        [
            ("Inorganic", ""),
            ("Wounds (X)", "2"),
            ("Integral Armour", ""),
            ("Damage (+X) in Assault", "1"),
            ("Deep Strike (X)", "2"),
        ],
        [w("Exile Cannon", "20 cm", "1", "3+", "-3")],
    ),
    base(
        "Monolith",
        4,
        "15",
        "2+/5+f",
        "+4",
        "--",
        [
            ("Inorganic", ""),
            ("Wounds (X)", "2"),
            ("Integral Armour", ""),
            ("Heavy Antigrav", ""),
            ("Portal", "2 class 1 detachments/turn"),
            ("Deep Strike (X)", "1"),
        ],
        [
            w("Particle Whip — Concentrated", "45 cm", "1", "3+", "-3", [("Turret", "")]),
            w("Particle Whip — Diffuse", "45 cm", "3", "4+", "0", [("Turret", "")]),
            w("Gauss Flayer", "20 cm", "5", "5+", "0", [("Turret", "")]),
        ],
    ),
    base(
        "Doomsday Monolith",
        4,
        "15",
        "2+/5+f",
        "+5",
        "--",
        [
            ("Inorganic", ""),
            ("Wounds (X)", "3"),
            ("Integral Armour", ""),
            ("Heavy Antigrav", ""),
            ("Portal", "2 class 1 detachments/turn"),
            ("Deep Strike (X)", "1"),
        ],
        [
            w(
                "Fission Obliterator",
                "75 cm",
                "Template",
                "4+",
                "-1",
                [
                    ("Turret", ""),
                    ("Template (X)", "12 cm"),
                    ("Reduces Cover (X)", "-1"),
                ],
            ),
            w("Gauss Flayer", "20 cm", "5", "5+", "0", [("Turret", "")]),
        ],
    ),
    base(
        "Seraptek Heavy Construct",
        4,
        "20",
        "2+/5+f",
        "+7",
        "--",
        [("Close Defences (X+)", "5"), ("Wounds (X)", "2"), ("Inorganic", "")],
        [
            w("Gauss Obliterator", "75 cm", "2", "3+", "-3", [("Turret", "")]),
            w("Singularity Generator", "30 cm", "6", "4+", "0", [("Turret", "")]),
        ],
    ),
    base(
        "Pylon",
        4,
        "0",
        "3+/5+f",
        "+5",
        "--",
        [
            ("Inorganic", ""),
            ("Wounds (X)", "2"),
            ("Integral Armour", ""),
            ("Deep Strike (X)", "1"),
        ],
        [
            w(
                "Particle Accelerator — AA",
                "100 cm",
                "2",
                "3+",
                "-3",
                [("Anti-Aircraft", ""), ("Damage (+X)", "1")],
            ),
            w(
                "Particle Accelerator — Ground",
                "100 cm",
                "2",
                "3+",
                "-3",
                [("Damage (+X)", "1")],
            ),
        ],
    ),
    base(
        "Obelisk",
        4,
        "15",
        "2+/5+f",
        "+4",
        "--",
        [
            ("Heavy Antigrav", ""),
            ("Integral Armour", ""),
            ("Wounds (X)", "3"),
            ("Inorganic", ""),
            ("Anti-Gravitic Matrix", ""),
            ("Deep Strike (X)", "1"),
        ],
        [w("Tesla Sphere", "45 cm", "6", "4+", "0", [("Turret", "")])],
    ),
    # Praetorians
    base(
        "Abattoir",
        6,
        "15",
        "2+/5+f",
        "+10",
        "Sheet",
        [
            ("Wounds (X)", "9"),
            ("Terror", ""),
            ("Agile", ""),
            ("Inorganic", ""),
            ("Integral Armour", ""),
            ("Reinforced Necrodermis", ""),
            ("Heavy Antigrav", ""),
            ("Engine of Destruction", ""),
            ("Organic Metal (X)", "3"),
            ("Damage (+X) in Assault", "1"),
            ("Psychic Save (X+)", "4"),
            ("Deep Strike (X)", "2"),
            ("Portal", "4× class 1–2, 1 detachment/turn each"),
        ],
        [
            w(
                "4 Harvesters — Shooting",
                "20 cm",
                "4",
                "4+",
                "-1",
                [("Turret", ""), ("Reduces Cover (X)", "-3")],
            ),
            w(
                "4 Harvesters — Assault",
                "--",
                "--",
                "--",
                "--",
                [("Harvesters — Assault", "")],
            ),
            w(
                "4 Scarab Swarms",
                "20 cm",
                "3",
                "5+",
                "0",
                [("Turret", ""), ("Reduces Cover (X)", "-1")],
            ),
        ],
    ),
    base(
        "War Barge",
        5,
        "20",
        "2+/5+f",
        "+10",
        "Sheet",
        [
            ("Wounds (X)", "5"),
            ("Agile", ""),
            ("Close Defences (X+)", "5"),
            ("Inorganic", ""),
            ("Reinforced Necrodermis", ""),
            ("Heavy Antigrav", ""),
            ("Organic Metal (X)", "3"),
            ("Psychic Save (X+)", "4"),
            ("Deep Strike (X)", "1"),
            ("Dimensional Translocation", ""),
            ("Portal", "5 class 1–3 detachments/turn"),
        ],
        [w("Gauss Cannons", "45 cm", "6", "4+", "-1", [("Turret", "")])],
    ),
    base(
        "Aeonic Orb",
        5,
        "20",
        "2+/5+f",
        "+10",
        "Sheet",
        [
            ("Close Defences (X+)", "5"),
            ("Wounds (X)", "6"),
            ("Agile", ""),
            ("Inorganic", ""),
            ("Reinforced Necrodermis", ""),
            ("Integral Armour", ""),
            ("Heavy Antigrav", ""),
            ("Psychic Save (X+)", "4"),
            ("Engine of Destruction", ""),
            ("Aeonic Orb", ""),
            ("Organic Metal (X)", "3"),
        ],
        [
            w("Solar Flare — Burst (1 plasma token)", "75 cm", "2", "3+", "-4"),
            w(
                "Solar Flare — Light (2 plasma tokens)",
                "100 cm",
                "1",
                "2+",
                "-5",
                [
                    ("Damage (+X)", "2"),
                    ("Damages Buildings (AP -X / Y)", "5,3"),
                ],
            ),
            w(
                "Solar Flare — Powerful (3 plasma tokens)",
                "120 cm",
                "2",
                "2+",
                "-5",
                [
                    ("Damage (+X)", "2"),
                    ("Damages Buildings (AP -X / Y)", "5,3"),
                ],
            ),
            w(
                "Solar Burner",
                "45 cm",
                "2",
                "4+",
                "-3",
                [("Reduces Cover (X)", "-3")],
            ),
        ],
    ),
    # Titans
    base(
        "Tomb Guardian",
        5,
        "25",
        "2+/5+f",
        "+12",
        "Sheet",
        [
            ("Close Defences (X+)", "5"),
            ("Wounds (X)", "5"),
            ("Inorganic", ""),
            ("Psychic Save (X+)", "4"),
            ("Damage (+X) in Assault", "1"),
            ("Reinforced Necrodermis", ""),
            ("Agile", ""),
            ("Heavy Antigrav", ""),
            ("Organic Metal (X)", "2"),
        ],
        TITAN_WEAPON_PROFILES,
        titan=2,
    ),
    # Options placeholder
    base(
        "Scarab Tokens",
        0,
        "--",
        "--",
        "--",
        "--",
        [("Scarab Tokens", "")],
        [],
    ),
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
        cp=0,
    )


def company(name, contents):
    return dict(
        kind=2,
        name=name,
        cost=0,
        detachment=None,
        contents=contents,
        cls=0,
        units=[],
        cp=0,
    )


FORMATIONS = [
    # Mandatory
    formation(1, "Overlord (Unique)", 125, "Overlord Detachment", "1 Overlord base", 1, [("Overlord", 1)]),
    # Companies
    company(
        "Flayed Ones Company",
        "1 Flayed Lord (0); 3 Flayed Ones Detachments. "
        "Optional: 0–5 Flayed Ones Detachments; 0–1 Special or Extra Special; 0–1 Extra Special; any Options.",
    ),
    company(
        "Infantry Company",
        "1 Necron Lord (+50); 2 of Necron Warriors or Immortals; 1 of Necron Warriors, Immortals, or Monolith. "
        "Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.",
    ),
    company(
        "Skorpekh Company",
        "1 Skorpekh Lord (+25); 3 of Hexmark Destroyer or Skorpekh Destroyer. "
        "Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.",
    ),
    company(
        "Rapid Intervention Company",
        "1 Destroyer Lord (+50); 2 of Destroyer or Heavy Destroyer; "
        "1 of Destroyer, Heavy Destroyer, Canoptek Wraiths, or Tomb Blades. "
        "Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.",
    ),
    company(
        "Support Company",
        "0–1 Cryptek (+50); 2 Monolith Detachments; 1 of Monolith, Doomsday Monolith, or Canoptek Reanimator. "
        "Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.",
    ),
    # Special — C'tan shard of any type (separate rows so army builder can pick)
    formation(3, "Deceiver Detachment", 400, "Deceiver Detachment", "1 Deceiver base (C'tan Shard)", 4, [("Deceiver", 1)]),
    formation(
        3,
        "Nightbringer Detachment",
        400,
        "Nightbringer Detachment",
        "1 Nightbringer base (C'tan Shard)",
        4,
        [("Nightbringer", 1)],
    ),
    formation(
        3,
        "Void Dragon Detachment",
        400,
        "Void Dragon Detachment",
        "1 Void Dragon base (C'tan Shard)",
        4,
        [("Void Dragon", 1)],
    ),
    formation(
        3,
        "Transcendent C'tan Detachment",
        400,
        "Transcendent C'tan Detachment",
        "1 Transcendent C'tan base (C'tan Shard)",
        4,
        [("Transcendent C'tan", 1)],
    ),
    formation(
        3,
        "Tesseract Vault Detachment",
        400,
        "Tesseract Vault Detachment",
        "1 Tesseract Vault base (C'tan Shard)",
        4,
        [("Tesseract Vault", 1)],
    ),
    formation(3, "Abattoir Detachment", 750, "Abattoir Detachment", "1 Abattoir base", 6, [("Abattoir", 1)]),
    formation(3, "War Barge Detachment", 375, "War Barge Detachment", "1 War Barge base", 5, [("War Barge", 1)]),
    formation(
        3,
        "Tomb Guardian Detachment",
        475,
        "Tomb Guardian Detachment",
        "1 Tomb Guardian base (choose 2 weapons)",
        5,
        [("Tomb Guardian", 1)],
    ),
    formation(3, "Aeonic Orb Detachment", 700, "Aeonic Orb Detachment", "1 Aeonic Orb base", 5, [("Aeonic Orb", 1)]),
    # Extra Special → Option
    formation(
        5,
        "Necron Lord and Retinue Detachment",
        250,
        "Necron Lord and Retinue Detachment",
        "1 Necron Lord base and 4 Lychguard bases",
        1,
        [("Necron Lord", 1), ("Lychguard", 4)],
    ),
    formation(5, "Cryptek", 100, "Cryptek Detachment", "1 Cryptek base", 1, [("Cryptek", 1)]),
    formation(
        5,
        "Necron Lord on Catacomb Command Barge",
        75,
        "Catacomb Command Barge Detachment",
        "1 Catacomb Command Barge base",
        3,
        [("Catacomb Command Barge", 1)],
    ),
    # Support — Infantry
    formation(4, "Flayed Ones Detachment", 150, "Flayed Ones Detachment", "6 Flayed One bases", 1, [("Flayed One", 6)]),
    formation(
        4,
        "Hexmark Destroyer Detachment",
        150,
        "Hexmark Destroyer Detachment",
        "4 Hexmark Destroyer bases",
        1,
        [("Hexmark Destroyer", 4)],
    ),
    formation(
        4,
        "Skorpekh Destroyer Detachment",
        175,
        "Skorpekh Destroyer Detachment",
        "4 Skorpekh Destroyer bases",
        1,
        [("Skorpekh Destroyer", 4)],
    ),
    formation(
        4,
        "Necron Warriors Detachment",
        175,
        "Necron Warriors Detachment",
        "6 Necron Warrior bases",
        1,
        [("Necron Warriors", 6)],
    ),
    formation(4, "Immortals Detachment", 275, "Immortals Detachment", "6 Immortal bases", 1, [("Immortals", 6)]),
    formation(4, "Pariah Detachment", 200, "Pariah Detachment", "4 Pariah bases", 1, [("Pariah", 4)]),
    formation(
        4,
        "Triarch Praetorians Detachment",
        175,
        "Triarch Praetorians Detachment",
        "4 Triarch Praetorian bases",
        1,
        [("Triarch Praetorians", 4)],
    ),
    formation(4, "Deathmark Detachment", 150, "Deathmark Detachment", "4 Deathmark bases", 1, [("Deathmark", 4)]),
    # Support — Cavalry
    formation(
        4,
        "Canoptek Spyder (Assault) Detachment",
        125,
        "Canoptek Spyder (Assault) Detachment",
        "2 Canoptek Spyder (Assault) bases",
        2,
        [("Canoptek Spyder (Assault)", 2)],
    ),
    formation(
        4,
        "Canoptek Spyder (Support) Detachment",
        125,
        "Canoptek Spyder (Support) Detachment",
        "2 Canoptek Spyder (Support) bases",
        2,
        [("Canoptek Spyder (Support)", 2)],
    ),
    formation(
        4,
        "Canoptek Acanthrites Detachment",
        200,
        "Canoptek Acanthrites Detachment",
        "4 Canoptek Acanthrite bases",
        2,
        [("Canoptek Acanthrites", 4)],
    ),
    formation(4, "Destroyer Detachment", 225, "Destroyer Detachment", "5 Destroyer bases", 2, [("Destroyer", 5)]),
    formation(
        4,
        "Heavy Destroyer Detachment",
        275,
        "Heavy Destroyer Detachment",
        "4 Heavy Destroyer bases",
        2,
        [("Heavy Destroyer", 4)],
    ),
    formation(
        4,
        "Ophydian Destroyer Detachment",
        175,
        "Ophydian Destroyer Detachment",
        "4 Ophydian Destroyer bases",
        2,
        [("Ophydian Destroyer", 4)],
    ),
    formation(
        4,
        "Canoptek Wraiths Detachment",
        175,
        "Canoptek Wraiths Detachment",
        "4 Canoptek Wraith bases",
        2,
        [("Canoptek Wraiths", 4)],
    ),
    formation(4, "Tomb Blades Detachment", 225, "Tomb Blades Detachment", "4 Tomb Blades bases", 2, [("Tomb Blades", 4)]),
    # Support — Walkers
    formation(
        4,
        "Canoptek Doomstalker Detachment",
        225,
        "Canoptek Doomstalker Detachment",
        "3 Canoptek Doomstalker bases",
        2,
        [("Canoptek Doomstalker", 3)],
    ),
    formation(
        4,
        "Canoptek Reanimator Detachment",
        125,
        "Canoptek Reanimator Detachment",
        "3 Canoptek Reanimator bases",
        2,
        [("Canoptek Reanimator", 3)],
    ),
    formation(
        4,
        "Triarch Stalker Detachment",
        175,
        "Triarch Stalker Detachment",
        "3 Triarch Stalker bases",
        2,
        [("Triarch Stalker", 3)],
    ),
    # Support — Vehicles
    formation(4, "Doomsday Ark Detachment", 300, "Doomsday Ark Detachment", "3 Doomsday Ark bases", 3, [("Doomsday Ark", 3)]),
    formation(4, "Tesseract Ark Detachment", 225, "Tesseract Ark Detachment", "3 Tesseract Ark bases", 3, [("Tesseract Ark", 3)]),
    formation(
        4,
        "Annihilation Barge Detachment",
        200,
        "Annihilation Barge Detachment",
        "3 Annihilation Barge bases",
        3,
        [("Annihilation Barge", 3)],
    ),
    formation(4, "Doom Scythe Detachment", 300, "Doom Scythe Detachment", "3 Doom Scythe bases", 3, [("Doom Scythe", 3)]),
    formation(4, "Night Scythe Detachment", 250, "Night Scythe Detachment", "3 Night Scythe bases", 3, [("Night Scythe", 3)]),
    formation(4, "Night Shroud Detachment", 300, "Night Shroud Detachment", "2 Night Shroud bases", 3, [("Night Shroud", 2)]),
    # Support — Knights
    formation(4, "Tomb Golem Detachment", 300, "Tomb Golem Detachment", "3 Tomb Golem bases", 4, [("Tomb Golem", 3)]),
    # Support — Super-heavies
    formation(
        4,
        "Canoptek Tomb Sentinel Detachment",
        125,
        "Canoptek Tomb Sentinel Detachment",
        "1 Canoptek Tomb Sentinel base",
        4,
        [("Canoptek Tomb Sentinel", 1)],
    ),
    formation(4, "Monolith Detachment", 175, "Monolith Detachment", "1 Monolith base", 4, [("Monolith", 1)]),
    formation(
        4,
        "Doomsday Monolith Detachment",
        275,
        "Doomsday Monolith Detachment",
        "1 Doomsday Monolith base",
        4,
        [("Doomsday Monolith", 1)],
    ),
    formation(4, "Obelisk Detachment", 225, "Obelisk Detachment", "1 Obelisk base", 4, [("Obelisk", 1)]),
    formation(4, "Pylon Detachment", 225, "Pylon Detachment", "1 Pylon base", 4, [("Pylon", 1)]),
    formation(
        4,
        "Seraptek Heavy Construct Detachment",
        250,
        "Seraptek Heavy Construct Detachment",
        "1 Seraptek Heavy Construct base",
        4,
        [("Seraptek Heavy Construct", 1)],
    ),
    # Options
    formation(5, "Ghost Ark Detachment", 75, "Ghost Ark Detachment", "3 Ghost Ark bases", 3, [("Ghost Ark", 3)]),
    formation(5, "Scarab Detachment", 50, "Scarab Detachment", "3 Scarab tokens", 0, [("Scarab Tokens", 3)]),
]


# Book does not list points for Tomb Guardian weapons — catalog at 0.
TITAN_CATALOG = [
    ("Gauss Blaster", 0, "75 cm, 5 dice, 4+, AP -1.", 0, 0),
    ("Annihilation Crystal", 0, "Choose Concentrated (Damage +1) or Saturation (Template 7.5 cm).", 0, 0),
    (
        "Phase Claw",
        0,
        "Assault weapon: choose shooting, reroll assault + Damage +1, buildings, or First Strike.",
        1,
        0,
    ),
    (
        "Hyperphase Blade",
        0,
        "Assault weapon: choose shooting, +1D6 AF + Damage +2, buildings, or First Strike.",
        1,
        0,
    ),
    ("Conversion Beam", 0, "AP and To-Hit scale with range band (0–20 / 21–44 / 45–75 cm).", 0, 0),
    ("Disintegrator Beam", 0, "20 cm, 3 dice, 3+, AP -3, Damage (+1).", 0, 0),
]


TITAN_TABLES_SQL = """
CREATE TABLE IF NOT EXISTS TitanWeapon (
    TitanWeaponId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    CodexId INT UNSIGNED NOT NULL,
    WeaponName VARCHAR(128) NOT NULL,
    PointsCost INT NOT NULL,
    Notes VARCHAR(256) NOT NULL DEFAULT '',
    IsAssault TINYINT(1) NOT NULL DEFAULT 0,
    LimitPerTitan TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (TitanWeaponId),
    UNIQUE KEY UQ_TitanWeapon_Codex_Name (CodexId, WeaponName),
    KEY IX_TitanWeapon_Codex (CodexId),
    CONSTRAINT FK_TitanWeapon_Codex
        FOREIGN KEY (CodexId) REFERENCES Codex (CodexId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"""


def emit_titan_catalog_sql() -> list[str]:
    catalog_rows = [
        f"    (@codexId, '{sql_str(name)}', {cost}, '{sql_str(notes)}', {assault}, {limit})"
        for name, cost, notes, assault, limit in TITAN_CATALOG
    ]
    return [
        "INSERT INTO TitanWeapon (",
        "    CodexId, WeaponName, PointsCost, Notes, IsAssault, LimitPerTitan",
        ") VALUES",
        ",\n".join(catalog_rows),
        "ON DUPLICATE KEY UPDATE",
        "    PointsCost = VALUES(PointsCost),",
        "    Notes = VALUES(Notes),",
        "    IsAssault = VALUES(IsAssault),",
        "    LimitPerTitan = VALUES(LimitPerTitan);",
        "",
    ]


def emit_formations_body() -> str:
    lines: list[str] = []
    det_rows = []
    seen: set[str] = set()
    for f in FORMATIONS:
        if not f.get("detachment"):
            continue
        dname = f["detachment"]
        if dname in seen:
            continue
        seen.add(dname)
        det_rows.append(f"    (@codexId, '{sql_str(dname)}', {f.get('cp', 0)}, {f['cls']})")
    if det_rows:
        lines.append("INSERT INTO Detachment (")
        lines.append("    CodexId, DetachmentName, CommandPoints, `Class`")
        lines.append(") VALUES")
        lines.append(",\n".join(det_rows))
        lines.append("ON DUPLICATE KEY UPDATE")
        lines.append("    CommandPoints = VALUES(CommandPoints),")
        lines.append("    `Class` = VALUES(`Class`);")
        lines.append("")

    comp_union = []
    first = True
    for f in FORMATIONS:
        if not f.get("units"):
            continue
        for unit, count in f["units"]:
            prefix = "    SELECT" if first else "    UNION ALL SELECT"
            first = False
            comp_union.append(
                f"{prefix} '{sql_str(f['detachment'])}' AS DetachmentName, "
                f"'{sql_str(unit)}' AS UnitName, {count} AS BaseCount"
            )
    if comp_union:
        lines.append("INSERT INTO DetachmentComposition (DetachmentId, BaseId, BaseCount)")
        lines.append("SELECT d.DetachmentId, b.BaseId, src.BaseCount")
        lines.append("FROM (")
        lines.append("\n".join(comp_union))
        lines.append(") AS src")
        lines.append("INNER JOIN Detachment d")
        lines.append("    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName")
        lines.append("INNER JOIN `Base` b")
        lines.append("    ON b.CodexId = @codexId AND b.BaseName = src.UnitName;")
        lines.append("")

    form_rows = []
    for f in FORMATIONS:
        form_rows.append(
            f"    (@codexId, {f['kind']}, '{sql_str(f['name'])}', "
            f"{f['cost']}, {f.get('cp', 0)}, '{sql_str(f['contents'])}', 0)"
        )
    lines.append("INSERT INTO Formation (")
    lines.append("    CodexId, FormationKindId, FormationName, PointsCost, CommandPoints, Contents,")
    lines.append("    DestructionPoints")
    lines.append(") VALUES")
    lines.append(",\n".join(form_rows))
    lines.append("ON DUPLICATE KEY UPDATE")
    lines.append("    FormationKindId = VALUES(FormationKindId),")
    lines.append("    PointsCost = VALUES(PointsCost),")
    lines.append("    CommandPoints = VALUES(CommandPoints),")
    lines.append("    Contents = VALUES(Contents),")
    lines.append("    DestructionPoints = VALUES(DestructionPoints);")
    lines.append("")

    fd_union = []
    first = True
    for f in FORMATIONS:
        if not f.get("detachment"):
            continue
        prefix = "    SELECT" if first else "    UNION ALL SELECT"
        first = False
        fd_union.append(
            f"{prefix} '{sql_str(f['name'])}' AS FormationName, "
            f"'{sql_str(f['detachment'])}' AS DetachmentName"
        )
    if fd_union:
        lines.append("INSERT INTO FormationDetachment (FormationId, DetachmentId, Quantity)")
        lines.append("SELECT f.FormationId, d.DetachmentId, 1")
        lines.append("FROM (")
        lines.append("\n".join(fd_union))
        lines.append(") AS src")
        lines.append("INNER JOIN Formation f")
        lines.append("    ON f.CodexId = @codexId AND f.FormationName = src.FormationName")
        lines.append("INNER JOIN Detachment d")
        lines.append("    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName;")
        lines.append("")

    return "\n".join(lines)


def emit_necrons_sql() -> str:
    lines = [
        "-- Necrons 3.1.0 from C:/Files/NetEpicFR300-EnglishTranslation/Necrons 310",
        "-- Upserts Necrons catalog data. Preserves army lists and Base/Formation ids.",
        "",
        "SET NAMES utf8mb4;",
        "",
        TITAN_TABLES_SQL.strip(),
        "",
        "SET @hasTitanWeapons := (",
        "    SELECT COUNT(*) FROM information_schema.COLUMNS",
        "    WHERE TABLE_SCHEMA = DATABASE()",
        "      AND TABLE_NAME = 'ArmyFormation'",
        "      AND COLUMN_NAME = 'TitanWeapons'",
        ");",
        "SET @sql := IF(",
        "    @hasTitanWeapons = 0,",
        "    'ALTER TABLE ArmyFormation ADD COLUMN TitanWeapons JSON NULL',",
        "    'SELECT 1'",
        ");",
        "PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;",
        "",
        "DROP TABLE IF EXISTS ArmyFormationWeapon;",
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
        "INSERT INTO FormationKind (FormationKindId, KindName)",
        "SELECT 6, 'Limited' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 6);",
        "",
        "INSERT INTO Codex (CodexName)",
        "SELECT 'Necrons'",
        "WHERE NOT EXISTS (SELECT 1 FROM Codex WHERE CodexName = 'Necrons');",
        "",
        "SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Necrons');",
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
        "DELETE d FROM Detachment d",
        "WHERE d.CodexId = @codexId;",
        "",
        "DELETE FROM SpecialRule WHERE CodexId = @codexId;",
        "",
        "-- Preserve Base and Formation rows (and army lists). Upsert catalog fields.",
        "INSERT INTO `Base` (",
        "    CodexId, BaseName, DestructionPoints,",
        "    Morale, `Class`, Movement, `Save`, FA, NumberOfTitanWeapons",
        ") VALUES",
    ]

    base_values = []
    for b in BASES:
        titan = b.get("titan", 0)
        base_values.append(
            f"    (@codexId, '{sql_str(b['name'])}', 0, "
            f"'{sql_str(b['morale'])}', {b['cls']}, '{sql_str(b['mv'])}', "
            f"'{sql_str(b['save'])}', '{sql_str(b['fa'])}', {titan})"
        )
    lines.append(",\n".join(base_values))
    lines.append("ON DUPLICATE KEY UPDATE")
    lines.append("    DestructionPoints = VALUES(DestructionPoints),")
    lines.append("    Morale = VALUES(Morale),")
    lines.append("    `Class` = VALUES(`Class`),")
    lines.append("    Movement = VALUES(Movement),")
    lines.append("    `Save` = VALUES(`Save`),")
    lines.append("    FA = VALUES(FA),")
    lines.append("    NumberOfTitanWeapons = VALUES(NumberOfTitanWeapons);")
    lines.append("")

    lines.extend(
        [
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
            union_rows(ABILITIES),
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
            "-- Figure PNGs are stored in Base.Image; run upload_codex_images.py Necrons for new units.",
        ]
    )

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
                f"'{sql_str(wp['ap'])}', {wp['titan']})"
            )
    if weapon_rows:
        lines.append("INSERT INTO Weapon (")
        lines.append("    BaseId, `Name`, `Range`, Dice, ToHit, ArmourPenetration, IsTitanWeapon")
        lines.append(") VALUES")
        lines.append(",\n".join(weapon_rows) + ";")
        lines.append("")

    ability_rows = []
    for b in BASES:
        bid = var_name(b["name"])
        for aname, aval in b["abilities"]:
            ability_rows.append((bid, aname, aval))
    if ability_rows:
        lines.append("INSERT INTO BaseSpecialAbility (BaseId, SpecialAbilityId, AbilityValue)")
        lines.append("SELECT b.BaseId, sa.SpecialAbilityId, b.AbilityValue")
        lines.append("FROM (")
        union = []
        for i, (bid, aname, aval) in enumerate(ability_rows):
            prefix = "    SELECT" if i == 0 else "    UNION ALL SELECT"
            union.append(
                f"{prefix} {bid} AS BaseId, '{sql_str(aname)}' AS AbilityName, "
                f"'{sql_str(aval)}' AS AbilityValue"
            )
        lines.append("\n".join(union))
        lines.append(") AS b")
        lines.append("INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = b.AbilityName;")
        lines.append("")

    power_rows = []
    for b in BASES:
        bid = var_name(b["name"])
        for pname, pval in b.get("psychic_powers", []):
            power_rows.append((bid, pname, pval))
    if power_rows:
        lines.append("INSERT INTO BasePsychicPower (BaseId, PsychicPowerId, AbilityValue)")
        lines.append("SELECT b.BaseId, pp.PsychicPowerId, b.AbilityValue")
        lines.append("FROM (")
        union = []
        for i, (bid, pname, pval) in enumerate(power_rows):
            prefix = "    SELECT" if i == 0 else "    UNION ALL SELECT"
            union.append(
                f"{prefix} {bid} AS BaseId, '{sql_str(pname)}' AS PowerName, "
                f"'{sql_str(pval)}' AS AbilityValue"
            )
        lines.append("\n".join(union))
        lines.append(") AS b")
        lines.append("INNER JOIN PsychicPower pp ON pp.PsychicPowerName = b.PowerName;")
        lines.append("")

    wsa_rows = []
    for b in BASES:
        bid = var_name(b["name"])
        for wp in b["weapons"]:
            if not wp["abilities"]:
                continue
            wsa_rows.append((bid, wp["name"], wp["abilities"]))
    if wsa_rows:
        lines.append("INSERT INTO WeaponSpecialAbility (WeaponId, SpecialAbilityId, AbilityValue)")
        lines.append("SELECT w.WeaponId, sa.SpecialAbilityId, src.AbilityValue")
        lines.append("FROM (")
        union = []
        for i, (bid, wname, abs_) in enumerate(wsa_rows):
            for j, (aname, aval) in enumerate(abs_):
                prefix = "    SELECT" if i == 0 and j == 0 else "    UNION ALL SELECT"
                union.append(
                    f"{prefix} {bid} AS BaseId, '{sql_str(wname)}' AS WeaponName, "
                    f"'{sql_str(aname)}' AS AbilityName, '{sql_str(aval)}' AS AbilityValue"
                )
        lines.append("\n".join(union))
        lines.append(") AS src")
        lines.append("INNER JOIN Weapon w ON w.BaseId = src.BaseId AND w.`Name` = src.WeaponName")
        lines.append("INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = src.AbilityName;")
        lines.append("")

    lines.extend(emit_titan_catalog_sql())
    lines.append(emit_formations_body())
    return "\n".join(lines) + "\n"


def main() -> None:
    out_path = OUT / "necrons.sql"
    out_path.write_text(emit_necrons_sql(), encoding="utf-8")
    print(f"Wrote {out_path}")
    print(
        f"Counts: BASES={len(BASES)} FORMATIONS={len(FORMATIONS)} "
        f"ABILITIES={len(ABILITIES)} PSYCHIC_POWERS={len(PSYCHIC_POWERS)} "
        f"SPECIAL_RULES={len(SPECIAL_RULES)} TITAN_CATALOG={len(TITAN_CATALOG)}"
    )


if __name__ == "__main__":
    main()
