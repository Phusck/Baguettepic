"""Generate biel_tan.sql from Biel-Tan 3.1.0 (Palladium NetEpic 3)."""
from __future__ import annotations

from pathlib import Path

OUT = Path(__file__).resolve().parent


def sql_str(text: str) -> str:
    return text.replace("\\", "\\\\").replace("'", "''").replace("\r\n", "\n")


# Map BaseName → filename under Biel-Tan 310/figures/ (hyphenated PNGs).
IMAGE_ALIASES = {
    "Warlock": "warlock.png",
    "Swooping Hawks": "swooping-hawks.png",
    "Warp Spiders": "warp-spiders.png",
    "Harlequins": "harlequins.png",
    "Autarch": "autarch.png",
    "Howling Banshees": "howling-banshees.png",
    "Bonesinger": "bonesinger.png",
    "Fire Dragons": "fire-dragons.png",
    "Swooping Hawks Exarch": "exarchs.png",
    "Warp Spiders Exarch": "exarchs.png",
    "Howling Banshees Exarch": "exarchs.png",
    "Fire Dragons Exarch": "exarchs.png",
    "Dark Reapers Exarch": "exarchs.png",
    "Striking Scorpions Exarch": "exarchs.png",
    "Shadow Spectres Exarch": "exarchs.png",
    "Dire Avengers Exarch": "exarchs.png",
    "Dark Reapers": "dark-reapers.png",
    "Wraithguard": "wraithguard.png",
    "Guardians": "guardians.png",
    "Farseer": "farseer.png",
    "Wraithblades": "wraithblades.png",
    "Striking Scorpions": "striking-scorpions.png",
    "Rangers": "rangers.png",
    "Shadow Spectres": "shadow-spectres.png",
    "Dire Avengers": "dire-avengers.png",
    "Forward Observer": "forward-observer.png",
    "Bright Lance": "bright-lance.png",
    "Vibro Cannon": "vibro-cannon.png",
    "Shining Spears": "shining-spears.png",
    "Jetbikes": "jetbikes.png",
    "Vyper": "vyper.png",
    "Shining Spears Exarch": "exarchs.png",
    "War Walkers": "war-walkers.png",
    "Wasp Assault Walkers": "wasp-assault-walkers.png",
    "Wraithlord — Assault": "wraithlord.png",
    "Wraithlord — Support": "wraithlord.png",
    "Crimson Hunter": "crimson-hunter.png",
    "Falcon": "falcon.png",
    "Firestorm": "firestorm.png",
    "Hornet": "hornet.png",
    "Lynx": "lynx.png",
    "Night Spinner": "night-spinner.png",
    "Nightwing": "nightwing.png",
    "Fire Prism": "fire-prism.png",
    "Unicorn": "unicorn.png",
    "Warp Hunter": "warp-hunter.png",
    "Wave Serpent": "wave-serpent.png",
    "Avatar": "avatar.png",
    "Baron Fire": "baron.png",
    "Baron Stallion": "baron.png",
    "Bright Stallion": "bright-knights.png",
    "Bright Stalker": "bright-knights.png",
    "Wraithknight — Assault": "wraithknight.png",
    "Wraithknight — Support": "wraithknight.png",
    "Fire Gale": "fire-knights.png",
    "Fire Reaper": "fire-knights.png",
    "Fire Storm": "fire-knights.png",
    "Towering Destroyer": "towering-destroyer.png",
    "Cobra": "cobra.png",
    "Storm Serpent": "storm-serpent.png",
    "Tempest": "tempest.png",
    "Void Spinner": "void-spinner.png",
    "Vampire Raider": "vampire.png",
    "Scorpion": "scorpion.png",
    "Phoenix": "phoenix.png",
    "Revenant Titan": "revenant-titan.png",
    "Warlock Titan": "warlock-titan.png",
    "Phantom Titan": "phantom-titan.png",
    "Master Mime": "master-mime.png",
    "Pulsar Barrage": "",
    "Web Barrage": "",
}


def image_path_for(name: str) -> str:
    if name in IMAGE_ALIASES:
        return IMAGE_ALIASES[name]
    return name.lower().replace(" ", "-").replace("—", "-").replace("--", "-") + ".png"


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
        "Web",
        "When a detachment with a weapon that has the Web ability shoots at bases in a terrain feature "
        "(or at bases occupying one) that grants a cover save, the webs may render it impassable.\n\n"
        "Roll 1D6 and consult the following table, counting the number of attack dice with the Web ability "
        "firing at the terrain feature.\n\n"
        "| To-Hit | Number of dice |\n"
        "| --- | --- |\n"
        "| 6+ | 1 |\n"
        "| 5+ | 2 |\n"
        "| 4+ | 3 |\n"
        "| 3+ | 4+ |\n\n"
        "If the terrain becomes impassable, it also becomes Dangerous Terrain, with the same effects and "
        "To-Hit / AP as the weapon firing the web. The terrain remains impassable for 2 turns, the web "
        "disappearing at the end of the turn after it was fired.",
    ),
    (
        "Spirit Stone",
        "A base with the Spirit Stone rule has the Inorganic and Fearless abilities.\n\n"
        "A detachment with the Spirit Stone ability must always remain within 12 cm of an allied living "
        "Aeldari detachment (one that does not have Spirit Stone), and duplicates that detachment's orders. "
        "If there are several such detachments, choose which living detachment's orders to duplicate.\n\n"
        "Detachments with Spirit Stone within range of an allied Psychic Node receive orders freely.\n\n"
        "If at the start of the Orders Phase the detachment is more than 12 cm from any allied living Aeldari "
        "detachment and outside any Psychic Node, it receives a Charge order and moves toward the nearest "
        "allied living Aeldari detachment without engaging enemy detachments (it goes around them by the "
        "shortest path). It may only engage an enemy detachment that is itself engaged against the nearest "
        "allied Aeldari detachment. If there is no living Aeldari on the table, Spirit Stone detachments are "
        "considered to have No Orders.",
    ),
    (
        "Cannot Be Blocked",
        "Bases with this ability may always disengage from an assault with no opportunity attack possible, "
        "and ignore terrain and enemy control zones during their movement.",
    ),
    (
        "Holo-Field",
        "A Holo-Field grants Protection against all shooting according to the protected base's order.\n\n"
        "| Protection | Order |\n"
        "| --- | --- |\n"
        "| 5+ | First Fire / Immobilised |\n"
        "| 4+ | Advance / Fall Back |\n"
        "| 3+ | Charge / Forced March |",
    ),
    (
        "Vibro Cannon (-X)",
        "When a detachment or a weapon with the Vibro Cannon ability fires, trace a single imaginary line "
        "per detachment from one of the bases to its target. All bases crossed by this line are hit with an "
        "AP equal to -X times the number of weapons firing at the same time.\n\n"
        "The shot has the Reduces Cover (-1), Subterranean Fire, and Damages Buildings (2/-X) abilities, "
        "with an AP equal to -X times the number of weapons firing at the same time.\n\n"
        "Vibro Cannons cannot make Intercept Fire. For a structure, half of the bases present in garrison "
        "are hit. Due to its nature, it stops at the first structure it encounters, which it may damage.",
    ),
    (
        "Psychic Node (X)",
        "All Spirit Stone detachments within X cm may receive orders normally.",
    ),
    (
        "Prescience (X)",
        "All Aeldari detachments within X cm of the base with this ability do not need to receive orders "
        "during the Orders Phase. Instead they receive an order during the Movement Phase when they are "
        "activated, by placing an order in front of them. This power does not function on troops that "
        "follow the Spirit Stone rule.",
    ),
    (
        "Banshee Cry (X+)",
        "The cry of the Howling Banshees acts as a Lance (X+/psi), being Psychic Attacks. This lance "
        "functions only against Classes 1 and 2. In addition, a Class 1 or 2 detachment charged by "
        "Howling Banshees cannot make Intercept Fire.",
    ),
    (
        "Fire Prism",
        "These cannons may fire at another Fire Prism, using it as a relay for their shot. A Fire Prism "
        "may target a second Fire Prism if it is in range and in Line of Sight. This redirection is "
        "automatic. The second Fire Prism is then immediately activated to shoot, and may also use its "
        "own shots if it wishes. There is no limit to the number of possible redirections.",
    ),
    (
        "Ghost Portal",
        "A Storm Serpent may open a Ghost Portal at any point of its movement in Line of Sight and within "
        "60 cm. Place a marker to record the portal's location; bases enter or leave the portal within a "
        "radius of 6 cm. The portal cannot be placed on an enemy troop or in a structure.\n\n"
        "Once the portal is open, Aeldari Infantry, Cavalry, or Walker bases may enter either the Ghost "
        "Portal or the Storm Serpent, normally losing 5 cm of movement as when boarding a transport. The "
        "base in transit reappears at the other end of the Storm Serpent–Portal link and cannot exit into "
        "an enemy control zone of equal or higher class. The Storm Serpent may move without breaking the "
        "link that binds it to the portal.",
    ),
    (
        "3D6 in Assault against Classes 1 and 2",
        "A base with this ability rolls 3D6 instead of 2D6 in assault against Class 1 and 2 bases.",
    ),
    (
        "Master Mime",
        "The Master Mime is not deployed on the battlefield. Instead, the Formation is used once per game "
        "and is then no longer usable. As the Master Mime cannot be destroyed, it is considered Broken as "
        "soon as it is played.\n\n"
        "Play the Master Mime on an enemy detachment during the Initial Phase, just after all orders have "
        "been given. The targeted detachment automatically loses its order and may no longer receive another "
        "until it has unmasked the Master Mime (it then acts as a detachment with no order). To do so, the "
        "detachment takes a Morale test during each End Phase. As soon as it succeeds, the Master Mime is "
        "discovered and the detachment may receive orders again on the following turn.\n\n"
        "The Master Mime cannot be played against a detachment with no Morale value, or against Daemonic, "
        "Robotic, Flyer, Floating, or Tyranid detachments.",
    ),
    (
        "Harlequins",
        "Harlequins are immune to Morale and to all morale-based powers if they are fighting a Chaos army.",
    ),
    (
        "Inorganic",
        "A base with this ability is immune to certain effects. The descriptions of those effects specify "
        "when this immunity applies.",
    ),
    (
        "Fearless",
        "A detachment with this ability automatically passes all Morale Tests.",
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
        "Fire on the Move",
        "A base with this ability and an Advance order may move normally.\n\n"
        "At the end of its movement, replace its Advance order with an unrevealed First Fire order. It may "
        "subsequently perform Overwatch Fire, but doing so imposes an additional -1 To-Hit penalty.\n\n"
        "Regardless of whether it performs Overwatch Fire, it does not reroll results of 1 when shooting.",
    ),
    (
        "Lightning Attack",
        "A base with this ability may make a 10 cm Take Position move instead of a 5 cm move when resolving "
        "an assault.",
    ),
    (
        "Reroll Assault Dice",
        "A base with this ability may reroll its assault dice. If it does so, it must reroll all of them.",
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
        "Character",
        "Characters represent important individuals who distinguish themselves within an army. This ability "
        "is relevant in certain scenarios.",
    ),
    (
        "Psyker",
        "During the Combat Phase, a Psyker may use both one psychic power and its conventional weapons.\n\n"
        "Powers marked Shooting follow the same rules and restrictions as standard shooting attacks.\n\n"
        "A power used during the Movement Phase may be used at any point during the Psyker's movement "
        "activation. Unless otherwise stated, psychic powers have a 360 degree firing arc.",
    ),
    (
        "Psychic Save (X+)",
        "A base with Psychic Save (X+) may use this saving throw against psychic powers.",
    ),
    (
        "Charismatic (X)",
        "All allied detachments with at least one base within X cm of a base with this ability receive a "
        "+1 bonus to their Morale value.\n\n"
        "During Rally Tests in the End Phase, a Rally Test may also be attempted for a detachment within "
        "X cm of the Charismatic base.",
    ),
    (
        "Mechanic",
        "Any Walker or Vehicle detachment with at least one base within 6 cm of a base with this ability "
        "gains Regeneration (5+).\n\n"
        "If the affected base already has Regeneration, improve its Regeneration value by 1.\n\n"
        "This ability does not function while the Mechanic is inside a transport.",
    ),
    (
        "Urban Combat",
        "When resolving an assault, opponents of a base with this ability receive no AF bonuses from "
        "terrain features.",
    ),
    (
        "Damage (+X) in Assault",
        "A weapon with this ability inflicts X additional hits after its base wins a duel, in addition to "
        "the normal hit.",
    ),
    (
        "Damage (+X)",
        "A weapon with this ability inflicts X additional hits against a base successfully hit by the weapon.",
    ),
    (
        "Reduces Cover (X)",
        "A weapon with this ability worsens the target's cover save by X.",
    ),
    (
        "Reflex Fire",
        "A base with this ability does not suffer the normal -1 To-Hit penalty when performing Overwatch Fire.",
    ),
    (
        "Infiltration",
        "After deployment, bases with this ability may move up to 25 cm. This movement cannot bring a base "
        "into an enemy zone of control and cannot be performed while the detachment is being transported.",
    ),
    (
        "Camouflage",
        "If a base occupies terrain that provides a cover save, improve that cover save by 1. Improve it by "
        "a further 1 if the entire detachment has not yet fired and gives up its ability to fire during the "
        "current turn. Camouflage only functions against enemy bases more than 25 cm away. A base engaged in "
        "an assault loses Camouflage for the remainder of the turn.",
    ),
    (
        "Sniper",
        "When a base with the Sniper ability targets an HQ base, roll 1D6. On a result of 4+, the target "
        "cannot use its HQ ability against the Sniper's attack.",
    ),
    (
        "Forward Observer (FO)",
        "A Forward Observer may observe and direct Indirect Artillery Fire.\n\n"
        "Forward Observers are also the only bases capable of calling in Off-Table Artillery attacks.",
    ),
    (
        "Antigrav",
        "A base with Antigrav may make short flights over terrain, buildings, and enemy troops.\n\n"
        "It ignores terrain movement penalties and enemy zones of control except those generated by bases "
        "with Floater, Skimmer, Jump Packs, or Antigrav.\n\n"
        "While moving over an obstacle it is considered to be at altitude. It cannot end its movement on "
        "Impassable terrain.",
    ),
    (
        "Lance (X+ / Y)",
        "When a base with the Lance ability engages a target in an assault, it may make a shooting attack "
        "against that target on contact during Charge or Consolidation.\n\n"
        "The target is hit on X+ with AP Y. Lances ignore Holo-Fields and energy/deflector shields, and "
        "resolve simultaneously with Close Defences.\n\n"
        "If the target is destroyed and has lower Blocking Class, the attacker may continue moving but "
        "cannot use its Lance again that movement.",
    ),
    (
        "Dodge (X+)",
        "When a base with this ability loses Wounds in an assault, roll one die for each Wound lost. For "
        "each result of X+, the base does not lose that Wound.\n\n"
        "Dodge may also be used against hits caused by Close Defences.",
    ),
    (
        "Integral Armour",
        "A base with Integral Armour does not use a hit-location chart. Every hit is resolved against the "
        "base as a whole using its armour save.",
    ),
    (
        "Flyer",
        "Flyers may deploy on the battlefield or begin off-table (they cannot enter before Turn 2).\n\n"
        "Advance: ground-attack mission; Protection (4+). Charge: Aerial Interception (if Interceptor) or "
        "charge altitude targets; Protection (3+). Forced March: evasive manoeuvres with Snap Fire, may "
        "land; Protection (3+).\n\n"
        "At altitude, Flyers move in a straight line with unlimited Movement (minimum 45 cm), ignore "
        "terrain and zones of control, and are never pinned. They may leave the table and must remain "
        "off-table for one complete turn before returning.",
    ),
    (
        "Interceptor",
        "A detachment with this ability may perform Aerial Interceptions. See the Flyer rules for further "
        "details.",
    ),
    (
        "Transport (X)",
        "A base with Transport (X) may transport X Infantry bases.\n\n"
        "Entering or leaving a transport costs the transported bases 5 cm of movement. A transport with a "
        "capacity of 6 or more may transport Walker bases (each Walker occupies two Infantry spaces).",
    ),
    (
        "Attached Transport",
        "Attached Transports and the bases they transport are treated as a single detachment.\n\n"
        "The transports use the Morale value of the detachment to which they are attached. The transport "
        "group and transported group receive separate orders but are activated simultaneously. They have "
        "Extended Coherency (25 cm) with one another.\n\n"
        "The transported troops may begin the battle either embarked or outside their transports.",
    ),
    (
        "Protection (X+)",
        "Protection is a fixed saving throw made before all other saving throws. It may be used in addition "
        "to other types of saving throw.\n\n"
        "A base cannot benefit from more than one Protection save. If several are available, use the best one.",
    ),
    (
        "Protection (X+) to the Front",
        "This base has Protection (X+) against attacks originating within its front arc only.",
    ),
    (
        "Anti-Aircraft",
        "These weapons operate independently and may be activated separately from a base's other weapons.\n\n"
        "If the base has a First Fire order, these weapons may perform Overwatch Fire against targets at "
        "altitude without suffering the usual To-Hit penalty. They may also perform Overwatch Fire while "
        "the base has an Advance order, but suffer the normal -1 To-Hit penalty.\n\n"
        "Weapons with this ability always have a 360 degree firing arc and reduce a Flyer's Protection save "
        "by 2.\n\n"
        "When firing at targets that are not at altitude, these weapons function normally but suffer a "
        "-1 To-Hit penalty.",
    ),
    (
        "Turret",
        "A weapon with the Turret ability has a 360 degree firing arc.",
    ),
    (
        "Artillery",
        "Weapons with the Artillery ability fire in a high arc and may shoot without line of sight.\n\n"
        "Obstructing terrain crossed by the attack does not provide protection. If the targets are inside "
        "the terrain feature, they receive its cover save normally.\n\n"
        "Artillery cannot target bases at altitude or perform Overwatch Fire.\n\n"
        "Weapons with this ability may perform Indirect Fire against targets the firing base cannot see. "
        "To do so, the artillery base must have a First Fire order. Observed Indirect Fire requires a "
        "Forward Observer and suffers -1 To-Hit; unobserved Indirect Fire suffers -2 To-Hit.",
    ),
    (
        "Template (X)",
        "Templates have an area of effect and may therefore affect more than one target.\n\n"
        "Any base whose centre is covered by a template may be hit, depending on the template weapon's "
        "To-Hit roll.\n\n"
        "Obstructing terrain crossed by a template attack does not provide protection. However, a target "
        "inside such terrain receives its cover save normally.",
    ),
    (
        "Psychic Attack",
        "A Psychic Attack can only be negated by a Psychic Save.\n\n"
        "Wounds lost to a Psychic Attack cannot be recovered using Regeneration. Cover saves cannot be used "
        "against this type of power.\n\n"
        "If the target has a hit-location chart, the attack always hits its bridge or head location.",
    ),
    (
        "Damages Buildings (AP -X / Y)",
        "A base with a weapon possessing this ability may attack destructible terrain features.\n\n"
        "When using a template weapon, the centre of the template must be positioned over the structure for "
        "it to be hit.\n\n"
        "The structure must make Y saving throws with an AP modifier of -X. It loses one Wound for each "
        "failed save. Saving throws made by structures use the total result of 2D6.",
    ),
    (
        "Wounds (X)",
        "A base with this ability has X Wounds, allowing it to survive multiple injuries.\n\n"
        "By default, a base has only one Wound.",
    ),
    (
        "Close Defences (X+)",
        "Every Class 1 or 2 base that engages, or is engaged by, a base with Close Defences suffers a hit "
        "on X+ with AP 0.\n\n"
        "Resolve the attack when the bases make contact. Cover saves may be used against Close Defences.",
    ),
    (
        "Terror",
        "A detachment engaged in an assault by a base with the Terror ability must make a Morale Test with "
        "a -1 modifier. If failed, it immediately receives a Fall Back order but does not make a Fall Back "
        "move.\n\n"
        "A detachment attempting to engage a base with Terror must also pass a Morale Test with a -1 "
        "modifier or stop before entering the Terror-causing base's zone of control.\n\n"
        "Bases with Terror are immune to Terror.",
    ),
    (
        "Multiple Hits (X)",
        "When this weapon successfully hits a target, it inflicts X hits instead of one.",
    ),
    (
        "Bombing (X)",
        "Flyers and Floating bases at altitude may drop X bombs during their movement. Resolve each attack "
        "immediately during the movement, following the normal shooting procedure.\n\n"
        "Bombs cannot be dropped while the detachment has a Charge order and cannot affect targets at "
        "altitude.\n\n"
        "If the weapon uses templates, all its templates must touch one another and are treated as a single "
        "template. The templates must be centred on the axis of the bombing base's movement.",
    ),
    (
        "Agile",
        "A Titan or Praetorian with this ability is not limited to a total of 90 degrees of turning during "
        "each turn.",
    ),
    (
        "Extended Coherency (X)",
        "The coherency distance of bases with this ability is X cm instead of 6 cm.\n\n"
        "A detachment engaging a detachment with Extended Coherency does not need to engage all its bases "
        "before engaging another detachment.",
    ),
    (
        "Off-Table Artillery",
        "Off-Table Artillery represents batteries of extremely long-ranged weapons deployed far from the "
        "battlefield, including orbital bombardments and naval artillery.\n\n"
        "Off-Table Artillery is purchased normally when creating the army list and may only be used once. "
        "Different types are listed in the relevant Codex, and the type used is selected when the attack is "
        "called.\n\n"
        "To call an Off-Table Artillery attack, an unpinned Forward Observer must have line of sight to the "
        "targeted point.",
    ),
    (
        "Confusion (-X)",
        "A base with this ability may attempt to change the order assigned to an enemy detachment that has "
        "at least one base within 25 cm and has not yet been activated during the Movement Phase.\n\n"
        "The affected detachment must make a Morale Test with a modifier of -X. If the test is failed, its "
        "order is changed according to a 1D6 roll.",
    ),
    (
        "Dread (-X)",
        "When activated during the Combat Phase, a base with this ability may force one enemy detachment "
        "with at least one base within 20 cm to make a Morale Test.\n\n"
        "The test suffers a modifier of -X. If it is failed, the detachment receives a Fall Back order and "
        "immediately makes a Fall Back move.\n\n"
        "A detachment cannot be targeted by this ability more than once during the same turn.",
    ),
    (
        "Subterranean Fire",
        "Attacks with this ability ignore Energy Shields, Energy Fields, and Deflector Shields.\n\n"
        "They have no effect against Skimmers or bases at altitude.\n\n"
        "Against a base with a hit-location chart, Subterranean Fire always hits its lowest location, "
        "Location 1.",
    ),
    (
        "Titan Blade",
        "When using a Titan Blade, choose one effect:\n\n"
        " • Shooting with the weapon's listed profile.\n"
        " • Reroll Assault Dice with Damage (+2).\n"
        " • First Strike (1 / 2+ / AP -5), Damage (+1).\n"
        " • Damages Buildings (AP -5 / 3) in Assault.",
    ),
    (
        "Combat Fist",
        "When using a Combat Fist, choose one effect:\n\n"
        " • Shooting with the weapon's listed profile.\n"
        " • Adds 1D6 to AF with Damage (+2).\n"
        " • First Strike (1 / 2+ / AP -4), Damage (+1).\n"
        " • Damages Buildings (AP -4 / 3) in Assault.",
    ),
]


PSYCHIC_POWERS: list[tuple[str, str]] = [
    (
        "Psychic Barrage",
        "[Combat Phase, Shooting]: The Psyker projects a burst of pure psychic energy. Choose a target "
        "within 45 cm and in Line of Sight. It suffers a hit on 4+. This is a Psychic Power.",
    ),
    (
        "Mind Block",
        "[Movement Phase, upon activation]: The Warlock sends a flash of psychic energy that surrounds "
        "the target and immobilises it during its activation. Choose a Class 4 or lower base within 45 cm "
        "and in Line of Sight. On 4+, it is Immobilised for this turn. The power remains active only if the "
        "Warlock keeps the base in Line of Sight. This is a Psychic Power.",
    ),
    (
        "Storm",
        "[Combat Phase, Shooting]: The Warlock summons a storm of psychic energy. Place a Template "
        "(7.5 cm) within 60 cm and in Line of Sight. All bases under the template are pushed onto one of "
        "its edges, chosen by the player who owns the base. If the storm has its centre in a structure, "
        "all bases in garrison are pushed out and placed in contact with it. The storm is impassable "
        "terrain and is considered Class 4 Blocking terrain. The storm disappears in the End Phase.",
    ),
    (
        "Confusion",
        "[Movement Phase, upon activation]: The Farseer gains the Confusion (-2) ability for this turn.",
    ),
    (
        "Precognition",
        "[Movement Phase, upon activation of the targeted detachment]: An allied Class 1, 2, or 3 "
        "detachment within 12 cm of the Farseer may make a Forced March while still being able to shoot "
        "normally (without the -1 To-Hit penalty).",
    ),
    (
        "Doom",
        "[Movement Phase, upon activation]: Choose a target within 45 cm and in Line of Sight. All shots "
        "against that target gain a +1 To-Hit bonus (with a minimum of 2+). In assault, the target's AF is "
        "halved. This is a Psychic Power, and the effects dissipate at the end of the turn.",
    ),
    (
        "Future Sight",
        "[Orders Phase]: The Warlock Titan does not need an order for this turn. Instead, it chooses its "
        "order at the moment of its activation. You may choose to give it a First Fire order during the "
        "Movement Phase in order to make Intercept Fire.",
    ),
    (
        "Mind Scream",
        "[Movement Phase, upon activation]: The Warlock Titan gains the Charismatic (45 cm) and Dread (-2) "
        "abilities for the turn.",
    ),
]


SPECIAL_RULES: list[tuple[str, str]] = [
    (
        "Allies",
        "You may spend 25% of your points on allies from the Harlequins Codex.",
    ),
    (
        "Harlequins",
        "Harlequins are immune to Morale and to all morale-based powers if they are fighting a Chaos army.",
    ),
    (
        "Master Mime",
        "The Master Mime is a Special Formation but is not deployed on the battlefield. Instead, the "
        "Formation is used once per game, fulfilling its role, and is then no longer usable. As the Master "
        "Mime cannot be destroyed, it is considered Broken as soon as it is played.\n\n"
        "Play the Master Mime on an enemy detachment during the Initial Phase, just after all orders have "
        "been given. The targeted detachment automatically loses its order and may no longer receive another "
        "in subsequent turns until it has unmasked the Master Mime (it then acts as a detachment with no "
        "order). To do so, the detachment takes a Morale test during each End Phase. As soon as it succeeds, "
        "the Master Mime is discovered and the detachment may receive orders again on the following turn.\n\n"
        "The Master Mime cannot be played against a detachment with no Morale value, or against Daemonic, "
        "Robotic, Flyer, Floating, or Tyranid detachments.",
    ),
    (
        "Biel-Tan Titan Hit Location Chart",
        "### Revenant / Phantom / Warlock Titan\n\n"
        "| D6 | Location Front / Rear |\n"
        "| --- | --- |\n"
        "| 1 | Legs |\n"
        "| 2 | Hull |\n"
        "| 3 | Weapon |\n"
        "| 4 | Head (front) / Reactor (rear) |\n"
        "| 5 | Wing |\n"
        "| 6 | Player's choice |",
    ),
    (
        "Biel-Tan Titan Damage Effects",
        "Damage effects are progressive: the first damage to a location applies the first effect, and "
        "further damage applies the following effects on the list.\n\n"
        "### Hull\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | — |\n"
        "| 2 | 1 additional damage |\n"
        "| 3+ | 2 additional damage |\n\n"
        "### Weapon\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | Weapon Damaged (Repair on 4+) |\n"
        "| 2 | Weapon Destroyed |\n"
        "| 3+ | Damage to the Hull |\n\n"
        "### Leg\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | -5 cm of base movement (Repair on 4+) |\n"
        "| 2 | an additional -5 cm of base movement (Repair on 4+) (from this damage, if the titan is destroyed it falls) |\n"
        "| 3 | Immobilised, 1 additional damage |\n"
        "| 4+ | Damage to the Hull |\n\n"
        "### Head\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | -1D6 to AF (Repair on 4+) |\n"
        "| 2 | May receive an order only on a 4+ (Repair on 4+), 1 additional damage |\n"
        "| 3+ | Damage to the Hull |\n\n"
        "### Wing\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | Wing Damaged, the Holo-Field is disabled (Repair on 4+) |\n"
        "| 2 | Wing Destroyed, the Holo-Field is disabled |\n"
        "| 3+ | Damage to the Hull |\n\n"
        "### Reactor\n\n"
        "| Hits | Effect |\n"
        "| --- | --- |\n"
        "| 1 | 1 additional damage (from this damage, if the titan is destroyed it explodes) |\n"
        "| 2 | Holo-Field disabled: 1 additional damage |\n"
        "| 3+ | Reactor severely damaged, 1D3 additional damage |",
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


TITAN_WEAPON_PROFILES = [
    w(
        "D-Cannon",
        "75 cm",
        "Template",
        "3+",
        "Psi",
        [
            ("Damages Buildings (AP -X / Y)", "4,2"),
            ("Damage (+X)", "1"),
            ("Template (X)", "7.5 cm"),
            ("Psychic Attack", ""),
        ],
        titan=1,
    ),
    w(
        "Pulsar — Concentrated Fire",
        "90 cm",
        "1",
        "2+",
        "-2",
        [("Multiple Hits (X)", "2D3")],
        titan=1,
    ),
    w(
        "Pulsar — Diffuse Fire",
        "90 cm",
        "4",
        "2+",
        "0",
        [],
        titan=1,
    ),
    w(
        "Tremor Cannon",
        "90 cm",
        "Template",
        "3+",
        "-2",
        [("Vibro Cannon (-X)", "2")],
        titan=1,
    ),
    w(
        "Titan Blade",
        "45 cm",
        "4",
        "4+",
        "-1",
        [("Titan Blade", "")],
        titan=1,
    ),
    w(
        "Psychic Lance",
        "45 cm",
        "Template",
        "5+/4+",
        "--",
        [("Template (X)", "7.5 cm"), ("Psychic Attack", "")],
        titan=1,
    ),
    w(
        "Thermal Lance (0–20 cm)",
        "0–20 cm",
        "1",
        "3+",
        "-4",
        [("Damage (+X)", "3")],
        titan=1,
    ),
    w(
        "Thermal Lance (21–30 cm)",
        "21–30 cm",
        "1",
        "4+",
        "-3",
        [("Damage (+X)", "2")],
        titan=1,
    ),
    w(
        "Thermal Lance (31–45 cm)",
        "31–45 cm",
        "1",
        "5+",
        "-2",
        [("Damage (+X)", "1")],
        titan=1,
    ),
    w(
        "Combat Fist",
        "45 cm",
        "4",
        "4+",
        "-1",
        [("Combat Fist", "")],
        titan=1,
    ),
    w("Laser Cannon Wing", "75 cm", "2", "3+", "-1", [], titan=1),
    w("Missile Launcher Wing", "100 cm", "3", "5+", "0", [], titan=1),
    w(
        "Firestorm Wing",
        "75 cm",
        "2",
        "4+",
        "-2",
        [("Anti-Aircraft", "")],
        titan=1,
    ),
]


BASES = [
    # Infantry
    base(
        "Warlock",
        1,
        "10",
        "6+f",
        "+2",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Psyker", ""),
            ("Psychic Save (X+)", "4"),
            ("Prescience (X)", "7.5 cm"),
            ("Charismatic (X)", "12 cm"),
        ],
        [w("Shuriken Pistol", "20 cm", "1", "5+", "0")],
        [("Psychic Barrage", ""), ("Mind Block", ""), ("Storm", "")],
    ),
    base(
        "Swooping Hawks",
        1,
        "20",
        "6+",
        "+2",
        "5",
        [
            ("Elite (X)", "2"),
            ("Jump Packs", ""),
            ("Hard to Hit", ""),
            ("Deep Strike (X)", "2"),
        ],
        [w("Lasblaster", "20 cm", "1", "4+", "0")],
    ),
    base(
        "Warp Spiders",
        1,
        "15",
        "5+f",
        "+2",
        "5",
        [
            ("Elite (X)", "2"),
            ("Fire on the Move", ""),
            ("Lightning Attack", ""),
            ("Cannot Be Blocked", ""),
        ],
        [w("Death Spinner", "20 cm", "2", "3+", "0")],
    ),
    base(
        "Harlequins",
        1,
        "15",
        "6+f",
        "+6",
        "5",
        [
            ("Elite (X)", "2"),
            ("Hard to Hit", ""),
            ("Jump Packs", ""),
            ("Reroll Assault Dice", ""),
            ("Harlequins", ""),
        ],
        [w("Shuriken Pistol", "20 cm", "1", "5+", "0")],
    ),
    base(
        "Autarch",
        1,
        "15",
        "5+f",
        "+8",
        "4",
        [
            ("HQ", ""),
            ("Character", ""),
            ("Jump Packs", ""),
            ("Elite (X)", "2"),
            ("Damage (+X) in Assault", "1"),
        ],
        [w("Sacred Artefacts", "60 cm", "2", "4+", "-2")],
    ),
    base(
        "Howling Banshees",
        1,
        "15",
        "6+",
        "+6",
        "5",
        [("Elite (X)", "2"), ("Banshee Cry (X+)", "5")],
        [melee("Power Sword")],
    ),
    base(
        "Bonesinger",
        1,
        "10",
        "--",
        "+1",
        "Attached",
        [("HQ", ""), ("Attached Character", ""), ("Mechanic", "")],
        [w("Shuriken Pistol", "20 cm", "1", "5+", "0")],
    ),
    base(
        "Fire Dragons",
        1,
        "10",
        "5+",
        "+3",
        "5",
        [
            ("Elite (X)", "2"),
            ("Urban Combat", ""),
            ("Damage (+X) in Assault", "1"),
        ],
        [w("Fusion Gun", "20 cm", "1", "4+", "-2", [("Reduces Cover (X)", "-1")])],
    ),
    base(
        "Swooping Hawks Exarch",
        1,
        "20",
        "6+",
        "+5",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Jump Packs", ""),
            ("Hard to Hit", ""),
            ("Deep Strike (X)", "2"),
        ],
        [w("Lasblaster", "20 cm", "1", "4+", "0")],
    ),
    base(
        "Warp Spiders Exarch",
        1,
        "15",
        "5+f",
        "+5",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Fire on the Move", ""),
            ("Lightning Attack", ""),
            ("Cannot Be Blocked", ""),
        ],
        [w("Death Spinner", "20 cm", "3", "3+", "0")],
    ),
    base(
        "Howling Banshees Exarch",
        1,
        "15",
        "6+",
        "+8",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Banshee Cry (X+)", "4"),
        ],
        [melee("Power Sword")],
    ),
    base(
        "Fire Dragons Exarch",
        1,
        "10",
        "5+",
        "+5",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Urban Combat", ""),
            ("Damage (+X) in Assault", "1"),
        ],
        [w("Fusion Gun", "20 cm", "1", "3+", "-2", [("Reduces Cover (X)", "-1")])],
    ),
    base(
        "Dark Reapers Exarch",
        1,
        "10",
        "5+",
        "+3",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Reflex Fire", ""),
        ],
        [w("Reaper Launcher", "60 cm", "2", "3+", "-1")],
    ),
    base(
        "Striking Scorpions Exarch",
        1,
        "10",
        "6+",
        "+6",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Infiltration", ""),
            ("Camouflage", ""),
        ],
        [
            w(
                "Mandiblaster",
                "20 cm",
                "1",
                "5+",
                "0",
                [("3D6 in Assault against Classes 1 and 2", "")],
            )
        ],
    ),
    base(
        "Shadow Spectres Exarch",
        1,
        "15",
        "6+",
        "+2",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Jump Packs", ""),
            ("Hard to Hit", ""),
            ("Deep Strike (X)", "2"),
        ],
        [w("Prism Rifle", "30 cm", "1", "3+", "-2")],
    ),
    base(
        "Dire Avengers Exarch",
        1,
        "10",
        "6+",
        "+4",
        "Attached",
        [("HQ", ""), ("Attached Character", ""), ("Elite (X)", "1")],
        [w("Avenger Shuriken Catapult", "45 cm", "3", "4+", "0")],
    ),
    base(
        "Dark Reapers",
        1,
        "10",
        "5+",
        "+1",
        "5",
        [("Elite (X)", "2"), ("Reflex Fire", "")],
        [w("Reaper Launcher", "60 cm", "2", "4+", "-1")],
    ),
    base(
        "Wraithguard",
        1,
        "10",
        "5+",
        "+2",
        "--",
        [("Spirit Stone", "")],
        [w("Wraithcannon", "45 cm", "1", "5+", "-2")],
    ),
    base("Guardians", 1, "10", "--", "+0", "6", [], [w("Shuriken Catapult", "45 cm", "1", "5+", "0")]),
    base(
        "Farseer",
        1,
        "10",
        "6+f",
        "+3",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Psyker", ""),
            ("Psychic Save (X+)", "4"),
            ("Psychic Node (X)", "30 cm"),
        ],
        [w("Shuriken Pistol", "20 cm", "1", "5+", "0")],
        [("Psychic Barrage", ""), ("Confusion", ""), ("Precognition", "")],
    ),
    base(
        "Wraithblades",
        1,
        "10",
        "5+/6+f",
        "+4",
        "--",
        [("Spirit Stone", ""), ("Dodge (X+)", "5")],
        [melee("Ghostswords")],
    ),
    base(
        "Striking Scorpions",
        1,
        "10",
        "6+",
        "+4",
        "5",
        [("Elite (X)", "2"), ("Infiltration", ""), ("Camouflage", "")],
        [
            w(
                "Mandiblaster",
                "20 cm",
                "1",
                "5+",
                "0",
                [("3D6 in Assault against Classes 1 and 2", "")],
            )
        ],
    ),
    base(
        "Rangers",
        1,
        "10",
        "--",
        "+0",
        "6",
        [("Infiltration", ""), ("Camouflage", ""), ("Sniper", "")],
        [w("Long Rifle", "75 cm", "1", "4+", "0")],
    ),
    base(
        "Shadow Spectres",
        1,
        "15",
        "6+",
        "+0",
        "5",
        [
            ("Elite (X)", "2"),
            ("Jump Packs", ""),
            ("Hard to Hit", ""),
            ("Deep Strike (X)", "2"),
        ],
        [w("Prism Rifle", "30 cm", "1", "4+", "-2")],
    ),
    base(
        "Dire Avengers",
        1,
        "10",
        "6+",
        "+2",
        "5",
        [("Elite (X)", "2")],
        [w("Avenger Shuriken Catapult", "45 cm", "3", "5+", "0")],
    ),
    base(
        "Forward Observer",
        1,
        "10",
        "--",
        "+0",
        "Attached",
        [("HQ", ""), ("Attached Character", ""), ("Forward Observer (FO)", "")],
        [w("Shuriken Catapult", "45 cm", "1", "5+", "0")],
    ),
    base("Bright Lance", 1, "10", "--", "+0", "6", [], [w("Bright Lance", "75 cm", "1", "4+", "-2")]),
    base(
        "Vibro Cannon",
        1,
        "10",
        "--",
        "+0",
        "6",
        [],
        [w("Vibro Cannon", "60 cm", "1", "5+", "-1", [("Vibro Cannon (-X)", "1")])],
    ),
    base(
        "Master Mime",
        1,
        "--",
        "--",
        "--",
        "--",
        [("Master Mime", "")],
        [],
    ),
    # Cavalry
    base(
        "Shining Spears",
        2,
        "35",
        "6+",
        "+5",
        "5",
        [
            ("Elite (X)", "2"),
            ("Antigrav", ""),
            ("Lance (X+ / Y)", "4+,-1"),
        ],
        [melee("Laser Lance")],
    ),
    base(
        "Jetbikes",
        2,
        "35",
        "--",
        "+3",
        "6",
        [("Antigrav", "")],
        [w("Shuriken Catapult", "45 cm", "1", "5+", "0")],
    ),
    base(
        "Vyper",
        2,
        "35",
        "6+",
        "+2",
        "6",
        [("Antigrav", "")],
        [w("Twin Shuriken Cannon", "45 cm", "1", "4+", "-1")],
    ),
    base(
        "Shining Spears Exarch",
        2,
        "35",
        "6+",
        "+8",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Antigrav", ""),
            ("Lance (X+ / Y)", "4+,-1"),
        ],
        [melee("Laser Lance")],
    ),
    # Walkers
    base(
        "War Walkers",
        2,
        "25",
        "5+",
        "+1",
        "6",
        [],
        [
            w("Bright Lance", "75 cm", "1", "4+", "-2"),
            w("Scatter Laser", "20 cm", "3", "5+", "0"),
        ],
    ),
    base(
        "Wasp Assault Walkers",
        2,
        "25",
        "6+",
        "+2",
        "6",
        [("Jump Packs", "")],
        [w("Shuriken Cannon", "20 cm", "4", "5+", "-1")],
    ),
    base(
        "Wraithlord — Assault",
        2,
        "15",
        "3+/5+f",
        "+6",
        "--",
        [("Dodge (X+)", "5"), ("Spirit Stone", "")],
        [melee("Ghostglaive")],
    ),
    base(
        "Wraithlord — Support",
        2,
        "15",
        "4+",
        "+4",
        "--",
        [("Spirit Stone", "")],
        [
            w("Bright Lance", "75 cm", "1", "4+", "-2"),
            w("Scatter Laser", "20 cm", "3", "5+", "0"),
        ],
    ),
    # Vehicles
    base(
        "Crimson Hunter",
        3,
        "--",
        "4+",
        "+6",
        "6",
        [
            ("Integral Armour", ""),
            ("Dodge (X+)", "4"),
            ("Flyer", ""),
            ("Interceptor", ""),
        ],
        [w("Twin Bright Lance", "45 cm", "2", "4+", "-2")],
    ),
    base(
        "Falcon",
        3,
        "25",
        "3+",
        "+1",
        "6",
        [("Antigrav", ""), ("Transport (X)", "2")],
        [w("Bright Lance", "75 cm", "1", "4+", "-2", [("Turret", "")])],
    ),
    base(
        "Firestorm",
        3,
        "25",
        "3+",
        "+0",
        "6",
        [("Antigrav", "")],
        [w("Laser Battery", "75 cm", "3", "4+", "-2", [("Anti-Aircraft", "")])],
    ),
    base(
        "Hornet",
        3,
        "35",
        "6+",
        "+2",
        "6",
        [("Antigrav", "")],
        [
            w("Pulse Laser", "45 cm", "2", "4+", "-1"),
            w("Scatter Laser", "20 cm", "3", "5+", "0"),
        ],
    ),
    base(
        "Lynx",
        3,
        "25",
        "2+",
        "+1",
        "6",
        [("Antigrav", "")],
        [w("Sonic Lance", "60 cm", "3", "4+", "-1")],
    ),
    base(
        "Night Spinner",
        3,
        "25",
        "3+",
        "+1",
        "6",
        [("Antigrav", "")],
        [
            w(
                "Doomweaver",
                "90 cm",
                "2",
                "4+",
                "-2",
                [("Artillery", ""), ("Web", ""), ("Reduces Cover (X)", "-1")],
            )
        ],
    ),
    base(
        "Nightwing",
        3,
        "--",
        "4+",
        "+4",
        "6",
        [
            ("Integral Armour", ""),
            ("Dodge (X+)", "5"),
            ("Flyer", ""),
            ("Interceptor", ""),
        ],
        [
            w("Bright Lance", "45 cm", "2", "4+", "-2"),
            w("Twin Shuriken Catapult", "30 cm", "2", "4+", "0"),
        ],
    ),
    base(
        "Fire Prism",
        3,
        "25",
        "3+",
        "+1",
        "6",
        [("Antigrav", "")],
        [
            w(
                "Prism Cannon",
                "75 cm",
                "1",
                "3+",
                "-2",
                [("Damage (+X)", "1"), ("Fire Prism", "")],
            )
        ],
    ),
    base(
        "Unicorn",
        3,
        "25",
        "3+",
        "+1",
        "6",
        [("Antigrav", "")],
        [w("Vibro Cannon", "75 cm", "1", "5+", "-2", [("Vibro Cannon (-X)", "2")])],
    ),
    base(
        "Warp Hunter",
        3,
        "25",
        "3+",
        "+1",
        "6",
        [("Antigrav", "")],
        [
            w(
                "D-Cannon",
                "75 cm",
                "1",
                "4+",
                "Psi",
                [("Damages Buildings (AP -X / Y)", "3,2"), ("Psychic Attack", "")],
            )
        ],
    ),
    base(
        "Wave Serpent",
        3,
        "25",
        "3+",
        "+1",
        "Attached",
        [
            ("Antigrav", ""),
            ("Transport (X)", "2"),
            ("Protection (X+) to the Front", "4"),
            ("Attached Transport", ""),
        ],
        [w("Pulse Laser", "45 cm", "1", "4+", "-1")],
    ),
    # Knights
    base(
        "Avatar",
        4,
        "15",
        "2+/3+f",
        "+10",
        "--",
        [
            ("Character", ""),
            ("Wounds (X)", "2"),
            ("Dodge (X+)", "3"),
            ("Terror", ""),
            ("Damage (+X) in Assault", "1"),
        ],
        [w("The Wailing Doom", "20 cm", "1", "3+", "-2")],
    ),
    base(
        "Baron Fire",
        4,
        "20",
        "3+",
        "+8",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Wounds (X)", "2"),
            ("Close Defences (X+)", "6"),
            ("Holo-Field", ""),
        ],
        [
            w("Bright Lances", "75 cm", "2", "4+", "-2"),
            w("Scatter Laser", "20 cm", "3", "5+", "0"),
        ],
    ),
    base(
        "Baron Stallion",
        4,
        "25",
        "3+",
        "+9",
        "Attached",
        [
            ("HQ", ""),
            ("Attached Character", ""),
            ("Elite (X)", "1"),
            ("Wounds (X)", "2"),
            ("Close Defences (X+)", "6"),
            ("Holo-Field", ""),
            ("Lance (X+ / Y)", "3+,-2"),
        ],
        [w("Pulse Laser", "20 cm", "3", "5+", "0")],
    ),
    base(
        "Bright Stallion",
        4,
        "25",
        "3+",
        "+7",
        "5",
        [
            ("Wounds (X)", "2"),
            ("Close Defences (X+)", "6"),
            ("Holo-Field", ""),
            ("Lance (X+ / Y)", "3+,-2"),
        ],
        [w("Scatter Laser", "20 cm", "3", "5+", "0")],
    ),
    base(
        "Wraithknight — Assault",
        4,
        "20",
        "2+/4+f",
        "+8",
        "--",
        [
            ("Wounds (X)", "2"),
            ("Close Defences (X+)", "6"),
            ("Dodge (X+)", "5"),
            ("Damage (+X) in Assault", "1"),
        ],
        [melee("Ghostglaive")],
    ),
    base(
        "Wraithknight — Support",
        4,
        "15",
        "3+/5+f",
        "+4",
        "--",
        [("Wounds (X)", "2"), ("Close Defences (X+)", "6")],
        [
            w("Heavy Wraithcannons", "75 cm", "2", "4+", "-3"),
            w("Scatter Laser", "20 cm", "3", "5+", "0"),
        ],
    ),
    base(
        "Fire Gale",
        4,
        "20",
        "3+",
        "+3",
        "5",
        [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Holo-Field", "")],
        [w("Bright Lances", "75 cm", "2", "4+", "-2")],
    ),
    base(
        "Fire Reaper",
        4,
        "20",
        "3+",
        "+3",
        "5",
        [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Holo-Field", "")],
        [
            w("Reaper Laser", "45 cm", "4", "4+", "0"),
            w("Scatter Laser", "20 cm", "3", "5+", "0"),
        ],
    ),
    base(
        "Fire Storm",
        4,
        "20",
        "3+",
        "+3",
        "5",
        [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Holo-Field", "")],
        [
            w("Pulse Lances", "45 cm", "2", "4+", "0"),
            w(
                "Missile Launcher",
                "90 cm",
                "2",
                "4+",
                "0",
                [("Artillery", ""), ("Reduces Cover (X)", "-2")],
            ),
        ],
    ),
    base(
        "Towering Destroyer",
        4,
        "15",
        "2+",
        "+5",
        "5",
        [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Holo-Field", "")],
        [
            w("Pulse Lances", "45 cm", "2", "4+", "0"),
            w("Maelstrom Laser", "90 cm", "2", "4+", "-2"),
        ],
    ),
    base(
        "Bright Stalker",
        4,
        "25",
        "3+",
        "+5",
        "5",
        [("Wounds (X)", "2"), ("Close Defences (X+)", "6"), ("Holo-Field", "")],
        [
            w("Pulse Laser", "45 cm", "1", "4+", "-1"),
            w("Bright Lance", "75 cm", "1", "4+", "-2"),
        ],
    ),
    # Super-heavies
    base(
        "Cobra",
        4,
        "25",
        "2+",
        "+4",
        "5",
        [("Antigrav", ""), ("Wounds (X)", "3"), ("Close Defences (X+)", "6")],
        [
            w("Pulse Laser", "45 cm", "2", "4+", "-1"),
            w(
                "D-Cannon",
                "75 cm",
                "Template",
                "3+",
                "Psi",
                [
                    ("Template (X)", "7.5 cm"),
                    ("Damage (+X)", "1"),
                    ("Damages Buildings (AP -X / Y)", "4,2"),
                    ("Psychic Attack", ""),
                ],
            ),
        ],
    ),
    base(
        "Storm Serpent",
        4,
        "25",
        "2+",
        "+4",
        "5",
        [
            ("Antigrav", ""),
            ("Wounds (X)", "3"),
            ("Close Defences (X+)", "6"),
            ("Holo-Field", ""),
            ("Ghost Portal", ""),
        ],
        [w("Pulse Laser", "45 cm", "2", "4+", "-1")],
    ),
    base(
        "Tempest",
        4,
        "25",
        "2+",
        "+4",
        "5",
        [("Antigrav", ""), ("Wounds (X)", "3"), ("Close Defences (X+)", "6")],
        [
            w("Pulse Laser", "45 cm", "2", "4+", "-1"),
            w(
                "Tempest Pulse Laser",
                "90 cm",
                "2",
                "3+",
                "-3",
                [("Turret", ""), ("Damage (+X)", "1")],
            ),
        ],
    ),
    base(
        "Void Spinner",
        4,
        "25",
        "2+",
        "+4",
        "5",
        [("Antigrav", ""), ("Wounds (X)", "3"), ("Close Defences (X+)", "6")],
        [
            w("Pulse Laser", "45 cm", "2", "4+", "-1"),
            w(
                "Void Spinner Cannon",
                "90 cm",
                "3",
                "3+",
                "-3",
                [
                    ("Turret", ""),
                    ("Web", ""),
                    ("Reduces Cover (X)", "-3"),
                    ("Artillery", ""),
                ],
            ),
        ],
    ),
    base(
        "Vampire Raider",
        4,
        "30",
        "3+",
        "+1",
        "5",
        [
            ("Integral Armour", ""),
            ("Wounds (X)", "2"),
            ("Flyer", ""),
            ("Transport (X)", "8"),
        ],
        [
            w("Bright Lance", "45 cm", "2", "4+", "-2"),
            w("Shuriken Cannon", "20 cm", "3", "5+", "-1", [("Turret", "")]),
        ],
    ),
    base(
        "Scorpion",
        4,
        "25",
        "2+",
        "+4",
        "5",
        [("Antigrav", ""), ("Wounds (X)", "3"), ("Close Defences (X+)", "6")],
        [
            w("Pulse Laser", "45 cm", "2", "4+", "-1"),
            w(
                "Pulsar — Concentrated Fire",
                "75 cm",
                "1",
                "3+",
                "-2",
                [("Turret", ""), ("Multiple Hits (X)", "1D3")],
            ),
            w(
                "Pulsar — Diffuse Fire",
                "75 cm",
                "3",
                "3+",
                "0",
                [("Turret", "")],
            ),
        ],
    ),
    base(
        "Phoenix",
        4,
        "--",
        "3+",
        "+1",
        "5",
        [("Integral Armour", ""), ("Flyer", ""), ("Wounds (X)", "2")],
        [
            w("Bright Lance", "45 cm", "2", "4+", "-2"),
            w("Shuriken Catapult", "30 cm", "4", "5+", "0"),
            w(
                "Plasma Bombs",
                "Bomb",
                "Template",
                "3+",
                "-1",
                [
                    ("Bombing (X)", "2"),
                    ("Template (X)", "7.5 cm"),
                    ("Reduces Cover (X)", "-3"),
                ],
            ),
            w("Krak Bombs", "Bomb", "1", "3+", "-3", [("Bombing (X)", "2")]),
        ],
    ),
    # Titans
    base(
        "Revenant Titan",
        5,
        "30",
        "2+ Chart",
        "+8",
        "Sheet",
        [
            ("Wounds (X)", "4"),
            ("Close Defences (X+)", "5"),
            ("Agile", ""),
            ("Holo-Field", ""),
            ("Jump Packs", ""),
            ("Extended Coherency (X)", "25 cm"),
        ],
        [
            w("Missile Launcher", "100 cm", "3", "5+", "0"),
            w("Scatter Laser", "20 cm", "3", "5+", "0"),
            w(
                "Pulsar — Concentrated Fire",
                "75 cm",
                "1",
                "3+",
                "-2",
                [("Multiple Hits (X)", "1D3")],
            ),
            w("Pulsar — Diffuse Fire", "75 cm", "3", "3+", "0"),
        ],
        titan=0,
    ),
    base(
        "Warlock Titan",
        6,
        "20",
        "2+ Chart",
        "+13",
        "Sheet",
        [
            ("Wounds (X)", "6"),
            ("Close Defences (X+)", "5"),
            ("Agile", ""),
            ("Holo-Field", ""),
            ("Psyker", ""),
            ("Psychic Save (X+)", "3"),
            ("Prescience (X)", "12 cm"),
            ("Damage (+X) in Assault", "1"),
        ],
        [w("Shuriken Catapult", "45 cm", "3", "5+", "0")] + TITAN_WEAPON_PROFILES,
        [("Doom", ""), ("Future Sight", ""), ("Mind Scream", "")],
        titan=4,
    ),
    base(
        "Phantom Titan",
        6,
        "20",
        "2+ Chart",
        "+13",
        "Sheet",
        [
            ("Wounds (X)", "6"),
            ("Close Defences (X+)", "5"),
            ("Agile", ""),
            ("Holo-Field", ""),
            ("Damage (+X) in Assault", "1"),
        ],
        [w("Shuriken Catapult", "45 cm", "3", "5+", "0")] + TITAN_WEAPON_PROFILES,
        titan=4,
    ),
    # Off-table
    base(
        "Pulsar Barrage",
        0,
        "--",
        "--",
        "--",
        "--",
        [("Off-Table Artillery", "")],
        [
            w(
                "Pulsar",
                "--",
                "1",
                "3+",
                "-2",
                [("Multiple Hits (X)", "2D3"), ("Off-Table Artillery", "")],
            )
        ],
    ),
    base(
        "Web Barrage",
        0,
        "--",
        "--",
        "--",
        "--",
        [("Off-Table Artillery", "")],
        [
            w(
                "Web Barrage",
                "--",
                "5",
                "4+",
                "-3",
                [
                    ("Web", ""),
                    ("Reduces Cover (X)", "-3"),
                    ("Off-Table Artillery", ""),
                ],
            )
        ],
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
    formation(1, "Avatar (Unique)", 150, "Avatar Detachment", "1 Avatar base", 4, [("Avatar", 1)]),
    # Companies (cost 0; compulsory summary only)
    company(
        "Ghost Company",
        "1 Farseer (+25); 2 of Wraithguard or Wraithblades; 2 of Wraithlord — Assault or Support. "
        "Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.",
    ),
    company(
        "Reconnaissance Company",
        "2 Ranger Detachments; 2 of Ranger or War Walker. "
        "Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.",
    ),
    company(
        "Rapid Intervention Company",
        "0–1 Warlock (+50); 1 of Jetbike, Vyper, or Shining Spears; "
        "2 of Jetbike, Vyper, War Walker, Wasp Assault Walker, or Hornet (max 1 Hornet). "
        "Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.",
    ),
    company(
        "Knight Company",
        "1 of Baron Fire or Baron Stallion (+75); 1 of Fire Gale, Fire Reaper, or Fire Storm; "
        "1 of Bright Stalker or Bright Stallion; 1 Towering Destroyer Detachment. "
        "Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.",
    ),
    company(
        "Phoenix Company",
        "0–1 Autarch Detachment (4 Autarchs @ 300); 3 Aspect-with-Exarchs detachments "
        "(Shining Spears with Exarchs Limited). Support: 1–5 Aspect support or Crimson Hunters. "
        "Optional: 0–1 Special (Warlock/Farseer OK); any Options.",
    ),
    # Special
    formation(3, "Autarch Detachment", 350, "Autarch Detachment", "4 Autarch bases", 1, [("Autarch", 4)]),
    formation(3, "Harlequin Detachment", 200, "Harlequin Detachment", "4 Harlequin bases", 1, [("Harlequins", 4)]),
    formation(3, "Revenant Titan Detachment", 650, "Revenant Titan Detachment", "2 Revenant Titan bases", 5, [("Revenant Titan", 2)]),
    formation(
        3,
        "Warlock Titan Detachment",
        375,
        "Warlock Titan Detachment",
        "1 Warlock Titan base (weapons to purchase)",
        6,
        [("Warlock Titan", 1)],
    ),
    formation(
        3,
        "Phantom Titan Detachment",
        300,
        "Phantom Titan Detachment",
        "1 Phantom Titan base (weapons to purchase)",
        6,
        [("Phantom Titan", 1)],
    ),
    formation(
        3,
        "Master Mime (1/5000 points)",
        50,
        "Master Mime Detachment",
        "1 Master Mime",
        1,
        [("Master Mime", 1)],
    ),
    # Extra Special → Option
    formation(5, "Warlock", 100, "Warlock Detachment", "1 Warlock base", 1, [("Warlock", 1)]),
    formation(5, "Bonesinger", 50, "Bonesinger Detachment", "1 Bonesinger base", 1, [("Bonesinger", 1)]),
    formation(5, "Farseer", 75, "Farseer Detachment", "1 Farseer base", 1, [("Farseer", 1)]),
    formation(5, "Forward Observer", 50, "Forward Observer Detachment", "1 Forward Observer base", 1, [("Forward Observer", 1)]),
    # Support — Infantry
    formation(4, "Swooping Hawks Detachment", 175, "Swooping Hawks Detachment", "4 Swooping Hawks bases", 1, [("Swooping Hawks", 4)]),
    formation(
        4,
        "Swooping Hawks with Exarchs Detachment",
        225,
        "Swooping Hawks with Exarchs Detachment",
        "4 Swooping Hawks bases and 1 Swooping Hawks Exarch base",
        1,
        [("Swooping Hawks", 4), ("Swooping Hawks Exarch", 1)],
    ),
    formation(4, "Warp Spiders Detachment", 200, "Warp Spiders Detachment", "4 Warp Spiders bases", 1, [("Warp Spiders", 4)]),
    formation(
        4,
        "Warp Spiders with Exarchs Detachment",
        250,
        "Warp Spiders with Exarchs Detachment",
        "4 Warp Spiders bases and 1 Warp Spiders Exarch base",
        1,
        [("Warp Spiders", 4), ("Warp Spiders Exarch", 1)],
    ),
    formation(4, "Howling Banshees Detachment", 175, "Howling Banshees Detachment", "4 Howling Banshees bases", 1, [("Howling Banshees", 4)]),
    formation(
        4,
        "Howling Banshees with Exarchs Detachment",
        225,
        "Howling Banshees with Exarchs Detachment",
        "4 Howling Banshees bases and 1 Howling Banshees Exarch base",
        1,
        [("Howling Banshees", 4), ("Howling Banshees Exarch", 1)],
    ),
    formation(4, "Fire Dragons Detachment", 175, "Fire Dragons Detachment", "4 Fire Dragons bases", 1, [("Fire Dragons", 4)]),
    formation(
        4,
        "Fire Dragons with Exarchs Detachment",
        225,
        "Fire Dragons with Exarchs Detachment",
        "4 Fire Dragons bases and 1 Fire Dragons Exarch base",
        1,
        [("Fire Dragons", 4), ("Fire Dragons Exarch", 1)],
    ),
    formation(4, "Dark Reapers Detachment", 275, "Dark Reapers Detachment", "4 Dark Reapers bases", 1, [("Dark Reapers", 4)]),
    formation(
        4,
        "Dark Reapers with Exarchs Detachment",
        350,
        "Dark Reapers with Exarchs Detachment",
        "4 Dark Reapers bases and 1 Dark Reapers Exarch base",
        1,
        [("Dark Reapers", 4), ("Dark Reapers Exarch", 1)],
    ),
    formation(4, "Wraithguard Detachment", 125, "Wraithguard Detachment", "4 Wraithguard bases", 1, [("Wraithguard", 4)]),
    formation(4, "Guardian Detachment", 100, "Guardian Detachment", "6 Guardian bases", 1, [("Guardians", 6)]),
    formation(4, "Wraithblades Detachment", 125, "Wraithblades Detachment", "4 Wraithblades bases", 1, [("Wraithblades", 4)]),
    formation(4, "Bright Lance Detachment", 125, "Bright Lance Detachment", "3 Bright Lance bases", 1, [("Bright Lance", 3)]),
    formation(4, "Striking Scorpions Detachment", 200, "Striking Scorpions Detachment", "4 Striking Scorpions bases", 1, [("Striking Scorpions", 4)]),
    formation(
        4,
        "Striking Scorpions with Exarchs Detachment",
        250,
        "Striking Scorpions with Exarchs Detachment",
        "4 Striking Scorpions bases and 1 Striking Scorpions Exarch base",
        1,
        [("Striking Scorpions", 4), ("Striking Scorpions Exarch", 1)],
    ),
    formation(4, "Ranger Detachment", 150, "Ranger Detachment", "4 Ranger bases", 1, [("Rangers", 4)]),
    formation(4, "Shadow Spectres Detachment", 200, "Shadow Spectres Detachment", "4 Shadow Spectres bases", 1, [("Shadow Spectres", 4)]),
    formation(
        4,
        "Shadow Spectres with Exarchs Detachment",
        250,
        "Shadow Spectres with Exarchs Detachment",
        "4 Shadow Spectres bases and 1 Shadow Spectres Exarch base",
        1,
        [("Shadow Spectres", 4), ("Shadow Spectres Exarch", 1)],
    ),
    formation(4, "Dire Avengers Detachment", 150, "Dire Avengers Detachment", "4 Dire Avengers bases", 1, [("Dire Avengers", 4)]),
    formation(
        4,
        "Dire Avengers with Exarchs Detachment",
        200,
        "Dire Avengers with Exarchs Detachment",
        "4 Dire Avengers bases and 1 Dire Avengers Exarch base",
        1,
        [("Dire Avengers", 4), ("Dire Avengers Exarch", 1)],
    ),
    formation(4, "Vibro Cannon Detachment", 100, "Vibro Cannon Detachment", "3 Vibro Cannon bases", 1, [("Vibro Cannon", 3)]),
    # Support — Cavalry
    formation(4, "Shining Spears Detachment", 225, "Shining Spears Detachment", "4 Shining Spears bases", 2, [("Shining Spears", 4)]),
    formation(4, "Jetbike Detachment", 200, "Jetbike Detachment", "5 Jetbike bases", 2, [("Jetbikes", 5)]),
    formation(4, "Vyper Detachment", 225, "Vyper Detachment", "5 Vyper bases", 2, [("Vyper", 5)]),
    # Support — Walkers
    formation(4, "War Walker Detachment", 175, "War Walker Detachment", "3 War Walker bases", 2, [("War Walkers", 3)]),
    formation(4, "Wasp Assault Walker Detachment", 150, "Wasp Assault Walker Detachment", "3 Wasp Assault Walker bases", 2, [("Wasp Assault Walkers", 3)]),
    formation(4, "Wraithlord — Assault Detachment", 125, "Wraithlord — Assault Detachment", "3 Wraithlord — Assault bases", 2, [("Wraithlord — Assault", 3)]),
    formation(4, "Wraithlord — Support Detachment", 175, "Wraithlord — Support Detachment", "3 Wraithlord — Support bases", 2, [("Wraithlord — Support", 3)]),
    # Support — Vehicles
    formation(4, "Crimson Hunter Detachment", 300, "Crimson Hunter Detachment", "3 Crimson Hunter bases", 3, [("Crimson Hunter", 3)]),
    formation(4, "Falcon Detachment", 175, "Falcon Detachment", "3 Falcon bases", 3, [("Falcon", 3)]),
    formation(4, "Firestorm Detachment", 250, "Firestorm Detachment", "2 Firestorm bases", 3, [("Firestorm", 2)]),
    formation(4, "Hornet Detachment", 150, "Hornet Detachment", "2 Hornet bases", 3, [("Hornet", 2)]),
    formation(4, "Lynx Detachment", 175, "Lynx Detachment", "2 Lynx bases", 3, [("Lynx", 2)]),
    formation(4, "Night Spinner Detachment", 225, "Night Spinner Detachment", "2 Night Spinner bases", 3, [("Night Spinner", 2)]),
    formation(4, "Nightwing Detachment", 300, "Nightwing Detachment", "3 Nightwing bases", 3, [("Nightwing", 3)]),
    formation(4, "Fire Prism Detachment", 150, "Fire Prism Detachment", "2 Fire Prism bases", 3, [("Fire Prism", 2)]),
    formation(4, "Unicorn Detachment", 150, "Unicorn Detachment", "2 Unicorn bases", 3, [("Unicorn", 2)]),
    formation(4, "Warp Hunter Detachment", 175, "Warp Hunter Detachment", "2 Warp Hunter bases", 3, [("Warp Hunter", 2)]),
    # Support — Knights
    formation(4, "Bright Stalker Detachment", 325, "Bright Stalker Detachment", "3 Bright Stalker bases", 4, [("Bright Stalker", 3)]),
    formation(4, "Bright Stallion Detachment", 300, "Bright Stallion Detachment", "3 Bright Stallion bases", 4, [("Bright Stallion", 3)]),
    formation(4, "Wraithknight — Assault Detachment", 275, "Wraithknight — Assault Detachment", "3 Wraithknight — Assault bases", 4, [("Wraithknight — Assault", 3)]),
    formation(4, "Wraithknight — Support Detachment", 325, "Wraithknight — Support Detachment", "3 Wraithknight — Support bases", 4, [("Wraithknight — Support", 3)]),
    formation(4, "Fire Gale Detachment", 325, "Fire Gale Detachment", "3 Fire Gale bases", 4, [("Fire Gale", 3)]),
    formation(4, "Fire Reaper Detachment", 325, "Fire Reaper Detachment", "3 Fire Reaper bases", 4, [("Fire Reaper", 3)]),
    formation(4, "Fire Storm Detachment", 325, "Fire Storm Detachment", "3 Fire Storm bases", 4, [("Fire Storm", 3)]),
    formation(4, "Towering Destroyer Detachment", 400, "Towering Destroyer Detachment", "3 Towering Destroyer bases", 4, [("Towering Destroyer", 3)]),
    # Support — Super-heavies
    formation(4, "Cobra Detachment", 300, "Cobra Detachment", "1 Cobra base", 4, [("Cobra", 1)]),
    formation(4, "Phoenix Detachment", 275, "Phoenix Detachment", "1 Phoenix base", 4, [("Phoenix", 1)]),
    formation(4, "Scorpion Detachment", 275, "Scorpion Detachment", "1 Scorpion base", 4, [("Scorpion", 1)]),
    formation(4, "Storm Serpent Detachment", 175, "Storm Serpent Detachment", "1 Storm Serpent base", 4, [("Storm Serpent", 1)]),
    formation(4, "Tempest Detachment", 275, "Tempest Detachment", "1 Tempest base", 4, [("Tempest", 1)]),
    formation(4, "Void Spinner Detachment", 275, "Void Spinner Detachment", "1 Void Spinner base", 4, [("Void Spinner", 1)]),
    # Options
    formation(5, "Wave Serpent Detachment", 100, "Wave Serpent Detachment", "2 Wave Serpent bases", 3, [("Wave Serpent", 2)]),
    formation(5, "Vampire Raider Detachment", 175, "Vampire Raider Detachment", "1 Vampire Raider base", 4, [("Vampire Raider", 1)]),
    formation(5, "Baron Fire", 75, "Baron Fire Detachment", "1 Baron Fire base", 4, [("Baron Fire", 1)]),
    formation(5, "Baron Stallion", 75, "Baron Stallion Detachment", "1 Baron Stallion base", 4, [("Baron Stallion", 1)]),
    # Limited
    formation(
        6,
        "Shining Spears with Exarchs Detachment (Limited)",
        275,
        "Shining Spears with Exarchs Detachment",
        "4 Shining Spears bases and 1 Shining Spears Exarch base",
        2,
        [("Shining Spears", 4), ("Shining Spears Exarch", 1)],
    ),
    formation(
        6,
        "Off-Table Artillery (Pulsar Barrage)",
        100,
        "Off-Table Artillery (Pulsar Barrage)",
        "1 Pulsar Barrage shot (Limit: 1 per 2,000 points)",
        0,
        [("Pulsar Barrage", 1)],
    ),
    formation(
        6,
        "Off-Table Artillery (Web Barrage)",
        100,
        "Off-Table Artillery (Web Barrage)",
        "1 Web Barrage shot (Limit: 1 per 2,000 points)",
        0,
        [("Web Barrage", 1)],
    ),
]


TITAN_CATALOG = [
    ("D-Cannon", 125, "Template (7.5 cm), Damage (+1), Damages Buildings (AP -4/2), Psychic Attack.", 0, 0),
    ("Pulsar", 125, "Choose Concentrated (Multiple Hits 2D3) or Diffuse firing mode.", 0, 0),
    ("Tremor Cannon", 100, "Vibro Cannon (-2); AP -5 against Buildings; Buildings reroll successful saves.", 0, 0),
    ("Titan Blade", 75, "Choose an effect (shooting, assault, First Strike, or buildings).", 1, 0),
    ("Psychic Lance", 50, "Template (7.5 cm), Psychic Attack. Warlock hits on 4+; Phantom on 5+.", 0, 0),
    ("Thermal Lance", 50, "Damage and AP scale with range band (0–20 / 21–30 / 31–45 cm).", 0, 0),
    ("Combat Fist", 75, "Choose an effect (shooting, assault, First Strike, or buildings).", 1, 0),
    ("Laser Cannon Wing", 50, "Wing weapon.", 0, 0),
    ("Missile Launcher Wing", 25, "Wing weapon.", 0, 0),
    ("Firestorm Wing", 50, "Wing weapon with Anti-Aircraft.", 0, 0),
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


def emit_biel_tan_sql() -> str:
    lines = [
        "-- Biel-Tan 3.1.0 from C:/Files/NetEpicFR300-EnglishTranslation/Biel-Tan 310",
        "-- Upserts Biel-Tan catalog data. Preserves army lists and Base/Formation ids.",
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
        "SELECT 'Biel-Tan'",
        "WHERE NOT EXISTS (SELECT 1 FROM Codex WHERE CodexName = 'Biel-Tan');",
        "",
        "SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Biel-Tan');",
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
            "-- Figure PNGs are stored in Base.Image; run upload_base_images.py for new units.",
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
    out_path = OUT / "biel_tan.sql"
    out_path.write_text(emit_biel_tan_sql(), encoding="utf-8")
    print(f"Wrote {out_path}")
    print(
        f"Counts: BASES={len(BASES)} FORMATIONS={len(FORMATIONS)} "
        f"ABILITIES={len(ABILITIES)} PSYCHIC_POWERS={len(PSYCHIC_POWERS)} "
        f"SPECIAL_RULES={len(SPECIAL_RULES)} TITAN_CATALOG={len(TITAN_CATALOG)}"
    )


if __name__ == "__main__":
    main()
