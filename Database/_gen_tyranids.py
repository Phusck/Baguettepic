"""Generate tyranids.sql and tyranids-army-formations.sql from Tyranids 300."""
from __future__ import annotations

from pathlib import Path

OUT = Path(__file__).resolve().parent


def sql_str(text: str) -> str:
    return text.replace("\\", "\\\\").replace("'", "''").replace("\r\n", "\n")


IMAGE_ALIASES = {
    "Assault Tyrannofex": "tyrannofex.png",
    "Support Tyrannofex": "tyrannofex.png",
    "Bio-Plasma Shot": "",
    "Spore-Mine Shot": "",
}


def image_path_for(name: str) -> str:
    if name in IMAGE_ALIASES:
        return IMAGE_ALIASES[name]
    return name.lower().replace(" ", "_").replace("-", "_") + ".png"


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
        "Synapse (X)",
        "Detachments with this ability receive orders normally.\n\n"
        "They may also control Slave detachments if at least one base from the Slave detachment is within X cm of a Synapse base.\n\n"
        "Detachments arriving through the Tunneller or Mycetic Spore rules may receive an order if they are within the Synapse radius of a base when they arrive.\n\n"
        "The Synapse radius functions even if the Synapse base or the Slave bases are inside transports.\n\n"
        "A Synapse base attached to a detachment grants the Synapse ability to the entire detachment.\n\n"
        "A detachment following an Instinct order loses its Synapse ability.",
    ),
    (
        "Slave (Hunt)",
        "Slave detachments follow their Instinct order if they are outside the Synapse radius of a Synapse base during the Orders step, or if they have failed a Hive Mind Test.\n\n"
        "All movement required by an Instinct order is performed normally during the Movement Phase.\n\n"
        "Hunt: During the Movement Phase, the detachment moves its normal Movement characteristic towards the closest enemy detachment that is not already engaged in an assault. If it makes contact, it engages that detachment in an assault.\n\n"
        "If the detachment is not engaged in an assault, it must shoot at the closest valid enemy detachment during the Combat Phase.\n\n"
        "If a detachment following an Instinct order uses a template weapon, centre the template over the closest enemy base.",
    ),
    (
        "Slave (Devastation)",
        "Slave detachments follow their Instinct order if they are outside the Synapse radius of a Synapse base during the Orders step, or if they have failed a Hive Mind Test.\n\n"
        "All movement required by an Instinct order is performed normally during the Movement Phase.\n\n"
        "Devastation: During the Movement Phase, the detachment must move twice its normal Movement characteristic towards the closest enemy detachment.\n\n"
        "If the closest enemy detachment is already engaged in an assault, the Tyranid detachment may instead move towards the second-closest enemy detachment.\n\n"
        "If it makes contact with an enemy, it engages that enemy in an assault. A detachment following the Devastation Instinct never makes ranged attacks.",
    ),
    (
        "Slave (Nest)",
        "Slave detachments follow their Instinct order if they are outside the Synapse radius of a Synapse base during the Orders step, or if they have failed a Hive Mind Test.\n\n"
        "Nest: A detachment with this Instinct does not move. During the Combat Phase, it must shoot at the closest visible enemy detachment.\n\n"
        "This is not a First Fire order. The detachment therefore cannot perform Overwatch Fire, reroll results of 1 on its To-Hit rolls, or perform Indirect Fire.\n\n"
        "The detachment must shoot at an enemy even if that enemy is engaged in an assault.\n\n"
        "If a detachment following an Instinct order uses a template weapon, centre the template over the closest enemy base.",
    ),
    (
        "Semi-Synaptic",
        "Detachments with this ability may receive orders normally, even while outside a Synapse radius.\n\n"
        "If they fail a Hive Mind Test, they act as Slave creatures and follow their listed Instinct.",
    ),
    (
        "Semi-Synaptic (Hunt)",
        "Detachments with this ability may receive orders normally, even while outside a Synapse radius.\n\n"
        "If they fail a Hive Mind Test, they act as Slave creatures and follow the Hunt Instinct.",
    ),
    (
        "Semi-Synaptic (Devastation)",
        "Detachments with this ability may receive orders normally, even while outside a Synapse radius.\n\n"
        "If they fail a Hive Mind Test, they act as Slave creatures and follow the Devastation Instinct.",
    ),
    (
        "Semi-Synaptic (Nest)",
        "Detachments with this ability may receive orders normally, even while outside a Synapse radius.\n\n"
        "If they fail a Hive Mind Test, they act as Slave creatures and follow the Nest Instinct.",
    ),
    (
        "Synaptic Overload",
        "Once per turn, a base with this ability may cause a detachment within its Synapse radius to automatically pass a Hive Mind Test.\n\n"
        "The use of this ability must be declared before making the test.",
    ),
    (
        "Bio-Toxin",
        "Weapons with this ability cannot inflict damage upon allied Tyranid bases.",
    ),
    (
        "Subterranean Assault",
        "When a Trygon uses its Deep Strike ability to enter the battlefield, one Hormagaunt swarm may emerge with it.\n\n"
        "Place the Hormagaunt detachment within 6 cm of the Trygon's arrival point. Both detachments are placed on the battlefield simultaneously.",
    ),
    (
        "Spore Pods",
        "Spore Pods release clouds of toxic particles around the Bio-Titan. A Bio-Titan may purchase no more than one Spore Pod.\n\n"
        "During the Combat Phase, every base within 15 cm of the centre of the Bio-Titan is hit:\n\n"
        " • On a 4+ if the Bio-Titan has an Advance or First Fire order.\n"
        " • On a 5+ if the Bio-Titan has a Charge or Forced March order.\n\n"
        "Spore Pods have AP 0 and possess the Reduces Cover (-3) and Bio-Toxin abilities.\n\n"
        "Spore Pods function even if the Bio-Titan is pinned in an assault. In this case, resolve the Spore Pod attacks before resolving the assault. Any damage inflicted counts towards the assault's combat result.\n\n"
        "Spore Pods do not suffer a To-Hit penalty when the Bio-Titan is engaged in an assault.\n\n"
        "Spore Pods increase the Bio-Titan's Close Defences to 4+.",
    ),
    (
        "Spore-Mine",
        "When an attack is made with a Spore-Mines weapon, it creates a hazardous area in addition to resolving the normal effects of the attack.\n\n"
        "Leave the template in the position where the attack was resolved. It remains in play for the turn in which it was fired and for the following turn, after which it is removed.\n\n"
        "The area counts as Dangerous Terrain (4+/AP 0) with the Bio-Toxin ability.\n\n"
        "The Spore-Mine area may be targeted by shooting attacks. Each successful hit removes one Spore-Mine from the area.",
    ),
    (
        "Mycetic Spore",
        "Mycetic Spores follow these rules:\n\n"
        " • Spores are divided into groups. Each group consists of one or more detachments that purchased Mycetic Spores.\n"
        " • During Off-Table Arrivals, determine the group's arrival point in the same manner as another off-table arrival. Mycetic Spores are not affected by the Limited Assault rule.\n"
        " • The Spores enter during the Movement Phase and may be targeted by Overwatch Fire. For range and line-of-sight purposes, they are considered to be at altitude directly above their arrival point.\n"
        " • Make one saving throw for each successful hit and remove destroyed Spores randomly. Troops transported inside Spores destroyed either in flight or on the ground cannot make Emergency Exit Tests.\n"
        " • Place all surviving Spores in coherency and within 12 cm of the arrival point. A Spore cannot be placed on an enemy base or within Impassable terrain.\n"
        " • The transported troops then disembark according to the normal Transport rules.\n"
        " • As soon as a Spore is empty, it is removed and considered destroyed. Empty Spores have no zones of control and cannot contest or secure objectives.\n"
        " • Each Mycetic Spore may transport one Class 1 or 2 base.",
    ),
    (
        "Elite (X)",
        "At the beginning of the battle, your army receives a shared pool of Elite rerolls.\n\n"
        "Each detachment containing bases with Elite (X) adds X rerolls to this pool, regardless of how many Elite bases the detachment contains.\n\n"
        "During the battle, Elite rerolls may be spent to reroll dice rolled by your Elite bases. Before using them, declare the total number of dice that will be rerolled.\n\n"
        "Only one Elite reroll may be used per base for each dice roll. Consequently, only one die from an assault roll may be rerolled.\n\n"
        "Used Elite rerolls are removed from the army's pool.\n\n"
        "Elite rerolls may be used for:\n\n"
        " • To-Hit rolls for any type of shooting attack.\n"
        " • Armour saving throws.\n"
        " • Assault rolls.\n"
        " • Dodge rolls.\n"
        " • Opportunity attacks made when an enemy disengages.",
    ),
    (
        "Regeneration (X+)",
        "When a base with Regeneration (X+) would lose one or more Wounds, roll one die for each Wound lost.\n\n"
        "For each result equal to or greater than X, the base does not lose that Wound. Regeneration functions against both shooting attacks and assaults.\n\n"
        "Regeneration is more difficult during an assault and suffers a -1 modifier.\n\n"
        "Only one Regeneration attempt may be made for each Wound lost.\n\n"
        "A successful Regeneration roll prevents the loss of the Wound but does not cancel any additional effects caused by the attack, particularly effects applied through a Titan's hit-location chart.",
    ),
    (
        "Deep Strike (X)",
        "The controlling player selects a point on the battlefield and places one base from the detachment at that point. The base then scatters X times, moving 3D6 cm for each scatter.\n\n"
        "If the final point is outside the battlefield, within Impassable terrain, or within the zone of control of an enemy base of the same or a higher class, the detachment does not arrive. Another attempt may be made during the following turn.\n\n"
        "Otherwise, place the first base as close as possible to the final arrival point. Place every other base in the detachment anywhere within 6 cm of the first base.\n\n"
        "No base may arrive within Impassable terrain or within the zone of control of an enemy base of the same or a higher class.\n\n"
        "A detachment entering the battlefield in this manner cannot receive a First Fire order during the turn in which it arrives. It also loses 5 cm from its total available movement during that turn.\n\n"
        "Limited Assault\n\n"
        "On the first turn, a Class 3 or higher detachment cannot select an initial arrival point within the opposing player's half of the battlefield.",
    ),
    (
        "Damage (+X)",
        "A weapon with this ability inflicts X additional hits against a base successfully hit by the weapon.",
    ),
    (
        "Damage (+X) in Assault",
        "A weapon with this ability inflicts X additional hits after its base wins a duel, in addition to the normal hit.",
    ),
    (
        "Reduces Cover (X)",
        "A weapon with this ability worsens the target's cover save by X.",
    ),
    (
        "Infiltration",
        "These bases are stealthy and capable of approaching the enemy before the battle begins.\n\n"
        "After deployment, bases with this ability may move up to 25 cm. This movement cannot bring a base into an enemy zone of control and cannot be performed while the detachment is being transported.",
    ),
    (
        "Jump Packs",
        "Bases equipped with Jump Packs may make short flights over terrain, buildings, and enemy troops.\n\n"
        "They ignore enemy zones of control except those generated by bases with the Floater, Skimmer, or Jump Packs ability.\n\n"
        "They also ignore terrain modifiers during their movement but cannot end their movement on Impassable terrain.\n\n"
        "While using this ability to move over an obstacle, the base is considered to be at altitude.",
    ),
    (
        "Attached Character",
        "At the beginning of the battle, an Attached Character must join a detachment. The character and the detachment are then treated as a single detachment.\n\n"
        "The Attached Character must remain in coherency with the detachment, uses its Morale value, and adds its points cost to the detachment's total cost.\n\n"
        "Attached Characters do not occupy space in transports. A single detachment may include up to two Attached Characters.\n\n"
        "An Attached Character gains the Movement characteristic of the detachment to which it is attached. It also gains the detachment's movement-related special abilities, including Infiltration, Free Deployment, Jump Packs, Skimmer, Hard to Hit, Camouflage, and Advanced Camouflage.\n\n"
        "An Infantry Attached Character, Class 1, may be attached to an Infantry, Walker, or Cavalry detachment. If attached to a Walker or Cavalry detachment, it gains that detachment's class. In all other cases, an Attached Character must join a detachment of the same type.",
    ),
    (
        "HQ",
        "HQ bases represent a small number of important individuals. While they remain close to another base of the same Blocking Class, they receive protection against shooting attacks.\n\n"
        "When an HQ base is targeted by a shooting attack, its controlling player may select another base of the same class within 6 cm as the attack's target instead.\n\n"
        "This decision must be made before any saving throws are rolled.\n\n"
        "HQ protection does not function during an assault.",
    ),
    (
        "Advanced Camouflage",
        "Advanced Camouflage functions like Camouflage, with the following addition:\n\n"
        "If the terrain occupied by the detachment does not provide a cover save, the detachment receives a 5+ cover save. This becomes a 4+ cover save if the entire detachment has not yet fired and gives up its ability to fire during the current turn.\n\n"
        "Camouflage: If a base occupies terrain that provides a cover save, improve that cover save by 1. The cover save may be improved by a further 1 if the entire detachment has not yet fired and gives up its ability to fire during the current turn. Camouflage only functions against enemy bases more than 25 cm away. A base engaged in an assault loses the benefit of Camouflage for the remainder of the turn.",
    ),
    (
        "Free Deployment",
        "Detachments with this ability may deploy anywhere within their controlling player's half of the battlefield.\n\n"
        "Free Deployment is resolved at the same time as Infiltration movement. Every base deployed in this manner must be placed at least 12 cm from every enemy base.\n\n"
        "Once deployed, the detachment may also use its Infiltration ability, if it possesses it.",
    ),
    (
        "Walker",
        "A base with this ability suffers the same terrain movement penalties as a Walker-class base.",
    ),
    (
        "Fear",
        "A Class 1-3 detachment that enters base-to-base contact with a base possessing this ability must pass a Morale Test or suffer a -2 AF penalty for the remainder of the turn.\n\n"
        "This applies whether the Fear-causing base charges or is itself charged.\n\n"
        "Fear has no effect against bases with the Fear or Terror ability.",
    ),
    (
        "Antigrav",
        "A base with Antigrav may make short flights over terrain, buildings, and enemy troops.\n\n"
        "It ignores terrain movement penalties and enemy zones of control except those generated by bases with Floater, Skimmer, Jump Packs, or Antigrav.\n\n"
        "While moving over an obstacle it is considered to be at altitude. It cannot end its movement on Impassable terrain.",
    ),
    (
        "Psychic Save (X+)",
        "A base with Psychic Save (X+) may use this saving throw against psychic powers.",
    ),
    (
        "Close Defences (X+)",
        "Every Class 1 or 2 base that engages, or is engaged by, a base with Close Defences suffers a hit on X+ with AP 0.\n\n"
        "Resolve the attack when the bases make contact. Cover saves may be used against Close Defences.",
    ),
    (
        "Psychic Attack",
        "A Psychic Attack can only be negated by a Psychic Save.\n\n"
        "Wounds lost to a Psychic Attack cannot be recovered using the Regeneration ability. Cover saves cannot be used against this type of power.\n\n"
        "If the target has a hit-location chart, the attack always hits its bridge or head location.",
    ),
    (
        "Anti-Aircraft",
        "These weapons operate independently and may be activated separately from a base's other weapons.\n\n"
        "If the base has a First Fire order, these weapons may perform Overwatch Fire against targets at altitude without suffering the usual To-Hit penalty. They may also perform Overwatch Fire while the base has an Advance order, but suffer the normal -1 To-Hit penalty.\n\n"
        "Weapons with this ability always have a 360 degree firing arc and reduce a Flyer's Protection save by 2.\n\n"
        "When firing at targets that are not at altitude, these weapons function normally but suffer a -1 To-Hit penalty.",
    ),
    (
        "Artillery",
        "Weapons with the Artillery ability fire in a high arc and may shoot without line of sight.\n\n"
        "Obstructing terrain crossed by the attack does not provide protection. If the targets are inside the terrain feature, they receive its cover save normally.\n\n"
        "Artillery cannot target bases at altitude or perform Overwatch Fire.\n\n"
        "Weapons with this ability may perform Indirect Fire against targets the firing base cannot see. To do so, the artillery base must have a First Fire order.\n\n"
        "Observed Indirect Fire requires an unpinned allied base with the Forward Observer ability and line of sight to the artillery's intended target, and suffers a -1 To-Hit penalty.\n\n"
        "Unobserved Indirect Fire may be performed without line of sight and without a Forward Observer, but suffers a -2 To-Hit penalty.",
    ),
    (
        "Battery",
        "Weapons with the Battery ability combine their fire into a single powerful attack.\n\n"
        "All bases in the detachment produce a single template. The attack's To-Hit value depends on the number of bases remaining in the detachment. The To-Hit value shown on the profile applies to the complete detachment.\n\n"
        "For each base missing from the detachment, worsen both the attack's To-Hit value and the AP of its Damages Buildings ability by 1.\n\n"
        "Range and line of sight may be measured from any base in the detachment that is able to fire.",
    ),
    (
        "Template (X)",
        "Templates have an area of effect and may therefore affect more than one target.\n\n"
        "Any base whose centre is covered by a template may be hit, depending on the template weapon's To-Hit roll.\n\n"
        "Obstructing terrain crossed by a template attack does not provide protection. However, a target inside such terrain receives its cover save normally.\n\n"
        "A template weapon may target bases at altitude if it fulfils the normal requirements. If it does so, it affects only targets at altitude and cannot affect targets at ground level.",
    ),
    (
        "Bombardment (X)",
        "Flyers and Floating bases at altitude may drop X bombs during their movement. Resolve each attack immediately during the movement, following the normal shooting procedure.\n\n"
        "Bombs cannot be dropped while the detachment has a Charge order and cannot affect targets at altitude.\n\n"
        "If the weapon uses templates, all its templates must touch one another and are treated as a single template. The templates must be centred on the axis of the bombing base's movement.",
    ),
    (
        "Floater",
        "Floaters follow the rules for Heavy Skimmers.\n\n"
        "At the beginning of each turn, a Floater may choose to remain at ground level or rise to altitude. It remains at the chosen level for the entire turn.\n\n"
        "While at altitude, only bases with Skimmer, Heavy Skimmer, Floater, Flyer, or Jump Packs may engage it in an assault. A Floater may engage other troops without restriction.\n\n"
        "If a Floater is at altitude, only bases with Jump Packs or Skimmer may disembark from it. Bases cannot embark while the Floater is at altitude.\n\n"
        "Floaters may use their bombs during movement, but only while at altitude.",
    ),
    (
        "Transport (X)",
        "A base with Transport (X) may transport X Infantry bases.\n\n"
        "Entering or leaving a transport costs the transported bases 5 cm of movement. When a base leaves a transport, place it in contact with the transporting base.\n\n"
        "A transport with a capacity of 6 or more may transport Walker bases. Each Walker occupies the capacity of two Infantry bases.\n\n"
        "Transported bases may disembark even if their transport is engaged in an assault. While a detachment is embarked, Morale Tests use the better Morale value of the transport and transported detachments.",
    ),
    (
        "Transport (X Termagants)",
        "This transport may only carry Termagant bases. Its capacity is X Termagants. In all other respects it follows the Transport rules.",
    ),
    (
        "Transport (X Gargoyles)",
        "This transport may only carry Gargoyle bases. Its capacity is X Gargoyles. In all other respects it follows the Transport rules.",
    ),
    (
        "Transport (Special)",
        "This transport uses special capacity rules instead of a normal Infantry capacity. See the Mycetic Spore ability: each Mycetic Spore may transport one Class 1 or 2 base.",
    ),
    (
        "Attached Transport",
        "Attached Transports and the bases they transport are treated as a single detachment.\n\n"
        "The transports use the Morale value of the detachment to which they are attached.\n\n"
        "The transport group and transported group receive separate orders but are activated simultaneously. They have Extended Coherency (25 cm) with one another.\n\n"
        "The transported troops may begin the battle either embarked or outside their transports.",
    ),
    (
        "Leader",
        "All allied detachments with at least one base within 12 cm of a base with this ability receive a +1 bonus to their AF.",
    ),
    (
        "Dark Presence (-X / Y cm)",
        "Enemy detachments with at least one base within Y cm of a base with this ability suffer a -X modifier to their Morale value.\n\n"
        "This effect is not cumulative.",
    ),
    (
        "Interceptor",
        "A detachment with this ability may perform Aerial Interceptions. See the Flyer rules for further details.",
    ),
    (
        "Terror",
        "A detachment engaged in an assault by a base with the Terror ability must make a Morale Test with a -1 modifier.\n\n"
        "If the test is failed, the detachment immediately receives a Fall Back order but does not make a Fall Back move. Consequently, it cannot perform Overwatch Fire, even if it would otherwise be able to do so.\n\n"
        "A detachment attempting to engage a base with Terror must also pass a Morale Test with a -1 modifier. If this test is failed, the attacking bases stop before entering the Terror-causing base's zone of control.\n\n"
        "Bases with the Terror ability are immune to Terror.",
    ),
    (
        "Wounds (X)",
        "A base with this ability has X Wounds, allowing it to survive multiple injuries.\n\n"
        "By default, a base has only one Wound.",
    ),
    (
        "Character",
        "Characters represent important individuals who distinguish themselves within an army. This ability is relevant in certain scenarios.",
    ),
    (
        "Psyker",
        "These troops possess special abilities such as sorcery, mutant powers, or technomancy. Details of their powers are provided in the relevant Codex.\n\n"
        "During the Combat Phase, a Psyker may use both one psychic power and its conventional weapons.\n\n"
        "Powers marked Shooting in their description follow the same rules and restrictions as standard shooting attacks.\n\n"
        "A power used during the Movement Phase may be used at any point during the Psyker's movement activation, even if the Psyker is pinned in an assault.\n\n"
        "Unless otherwise stated, psychic powers have a 360 degree firing arc.",
    ),
    (
        "Forward Observer (FO)",
        "A Forward Observer may observe and direct Indirect Artillery Fire.\n\n"
        "Forward Observers are also the only bases capable of calling in Off-Table Artillery attacks.",
    ),
    (
        "Turret",
        "A weapon with the Turret ability has a 360 degree firing arc.",
    ),
    (
        "Flame Template",
        "This weapon uses a rangeless flame template.\n\n"
        "The template may be placed in any position provided it lies entirely within the weapon's firing arc. The narrow tip of the template must be placed over the centre of the firing base. The template must also cover at least one valid target.",
    ),
    (
        "Integral Armour",
        "A base with Integral Armour does not use a hit-location chart. Every hit is resolved against the base as a whole using its armour save.",
    ),
    (
        "Off-Table Artillery",
        "Off-Table Artillery represents batteries of extremely long-ranged weapons deployed far from the battlefield, including orbital bombardments and naval artillery.\n\n"
        "Off-Table Artillery is purchased normally when creating the army list and may only be used once. Different types are listed in the relevant Codex, and the type used is selected when the attack is called.\n\n"
        "To call an Off-Table Artillery attack, an unpinned Forward Observer must have line of sight to the targeted point. The attack's Destruction Points are awarded when it is used.\n\n"
        "For the purpose of determining the attack's direction, Off-Table Artillery is always considered to originate along the axis of the Forward Observer.",
    ),
    (
        "Agile",
        "A Titan or Praetorian with this ability is not limited to a total of 90 degrees of turning during each turn.",
    ),
    (
        "Protection (X+)",
        "Protection is a fixed saving throw made before all other saving throws. It may be used in addition to other types of saving throw.\n\n"
        "A base cannot benefit from more than one Protection save. If several are available, use the best one.",
    ),
    (
        "Dodge (X+)",
        "When a base with this ability loses Wounds in an assault, roll one die for each Wound lost. For each result of X+, the base does not lose that Wound.\n\n"
        "Dodge may also be used against hits caused by Close Defences.",
    ),
    (
        "Dread (-X)",
        "When activated during the Combat Phase, a base with this ability may force one enemy detachment with at least one base within 20 cm to make a Morale Test.\n\n"
        "The test suffers a modifier of -X. If it is failed, the detachment receives a Fall Back order and immediately makes a Fall Back move.\n\n"
        "A detachment cannot be targeted by this ability more than once during the same turn.",
    ),
    (
        "Psychic Abomination",
        "Any enemy Psyker within 25 cm of a base with this ability may only use a psychic power after rolling 5+ on 1D6.\n\n"
        "Daemons within 25 cm are also more unstable and suffer a -1 modifier to their Instability rolls.\n\n"
        "Bases with this ability gain a Psychic Save (2+).",
    ),
    (
        "First Strike (X)",
        "A weapon with this ability may attack a base in contact with it immediately before an assault is resolved.\n\n"
        "Resolve the attack after the assault has been selected for activation but before resolving anything else. It is treated as a shooting attack, but its To-Hit roll never suffers penalties and it ignores Shields.\n\n"
        "The target may make a normal saving throw. Damage inflicted by First Strike attacks counts towards the final combat result.",
    ),
    (
        "Damages Buildings (AP -X / Y)",
        "A base with a weapon possessing this ability may attack destructible terrain features.\n\n"
        "When using a template weapon, the centre of the template must be positioned over the structure for it to be hit.\n\n"
        "The structure must make Y saving throws with an AP modifier of -X. It loses one Wound for each failed save. Saving throws made by structures use the total result of 2D6.",
    ),
    (
        "Damages Buildings (AP -X / Y) in Assault",
        "A base with a weapon possessing this ability may attack a destructible terrain feature with which it is in contact during the Combat Phase.\n\n"
        "If the base is also engaged in an assault against enemy bases, it must choose whether to use the weapon against its opponents or the terrain feature.\n\n"
        "In all other respects, this ability functions in the same manner as Damages Buildings.",
    ),
    (
        "Entangle",
        "When a base with this ability makes contact with an enemy base that has a hit-location chart, it may immobilise one of the enemy base's weapons. The effects of that weapon are cancelled for the remainder of the turn.\n\n"
        "If two opposing bases both possess such weapons, the abilities cancel one another and both weapons become entangled.",
    ),
    (
        "Fires Twice",
        "A weapon with this ability may fire twice when it shoots.",
    ),
    (
        "Razor Claws",
        "When using Razor Claws, choose one effect:\n\n"
        " • Shooting with the weapon's listed profile.\n"
        " • Adds 1D6 to AF and Damage (+2) in Assault.\n"
        " • Damages Buildings (AP -4 / 3) in Assault.\n"
        " • First Strike (1/2+/AP -4) and Damage (+1).",
    ),
    (
        "Tentacles",
        "When using Tentacles, choose one effect:\n\n"
        " • Shooting: Damage (+1).\n"
        " • Entangle and Damage (+1) in Assault.\n"
        " • First Strike (1/2+/AP -4) and Damage (+1).",
    ),
    (
        "Bio-Resistance",
        "[Movement Phase, upon activation]: The Norn Queen improves its Regeneration by 1 and gains Dodge (5+) for the remainder of the turn.",
    ),
    (
        "Psychic Scream",
        "[Movement Phase, upon activation]: The Norn Queen gains the Dread (-1) and Psychic Abomination abilities for the remainder of the turn.",
    ),
    (
        "Psychic Projectile",
        "[Combat Phase, Shooting]: Choose a target within 45 cm and in the Norn Queen's Line of Sight. The target is hit on a 4+. This is a Psychic Power.",
    ),
    (
        "Warp Field",
        "[Movement Phase, upon activation]: The Dominatrix gains Protection (4+) for the remainder of the turn.",
    ),
    (
        "Energy Torrent",
        "[Combat Phase, Shooting]: The Dominatrix focuses its psychic energy to destroy the enemy. Choose one of the two firing modes when it is activated.\n\n"
        "Energy Torrent -- Focused: 90 cm, 1 die, 3+, AP -4, 1D3 Hits.\n\n"
        "Energy Torrent -- Diffuse: 90 cm, Template, 3+, AP -1, Template (7.5 cm), Reduces Cover (-1).",
    ),
    (
        "Synaptic Beacon",
        "[Movement Phase, upon activation]: The Dominatrix extends the range of its Synapse radius to 60 cm for the remainder of the turn. In addition, during the End-of-Turn Effects, detachments acting on Instinct within 60 cm may attempt a Hive Mind Test. If successful, remove their Instinct counters.",
    ),
]

SPECIAL_RULES: list[tuple[str, str]] = [
    (
        "Army Creation",
        "Tyranids select their troops differently from other armies and do not follow the standard army-building rules. Instead, detachments of Synapse creatures generate Command Points, while other formations consume them.\n\n"
        "Before another Synapse Formation may be selected, all Command Points generated by the previously selected Synapse Formations must have been spent.\n\n"
        "Tyranid Titans are relatively rare. The army may include no more than one Tyranid Titan for every 5 Command Points generated.",
    ),
    (
        "Morale",
        "Tyranids are not affected by morale in the same manner as other armies and never make Morale Tests.\n\n"
        "Their Morale value instead represents their connection to the Hive Mind. When a Tyranid detachment becomes Broken, it must make a Hive Mind Test. This test is resolved in the same manner as a Morale Test.\n\n"
        "If the test is failed, the detachment follows its Instinct, as described by its Slave ability, and receives an Instinct counter. If the test is passed, there are no further consequences.\n\n"
        "A detachment activated while it has an Instinct counter automatically removes the counter after completing its activation.\n\n"
        "A detachment with an Instinct counter suffers a -1 AF penalty to represent its disorganisation.",
    ),
    (
        "Adaptations",
        "Tyranids excel at adapting to their opponents. To represent this, after seeing the opposing player's army list but before the battle begins, the Tyranid player selects adaptations.\n\n"
        "Every Tyranid army has 10 points to spend on adaptations from the following list:\n\n"
        "Bio-Acid (7 points): For every complete 2,000 points in the army, one attack die from one weapon may gain Damage (+1) and improve its AP by 1. The use of this effect must be declared before making the To-Hit roll.\n\n"
        "Bio-Targeting (7 points): Every unit in the army may reroll results of 1 on its ranged To-Hit rolls.\n\n"
        "Endless Swarm (7 points): During the End-of-Turn Effects step, each Hormagaunt, Gargoyle, Ripper, Termagant, or Barbgaunt detachment recovers 1D3 previously lost bases. The recovered bases must be placed in coherency with their detachment and outside all enemy zones of control.\n\n"
        "Velocity (7 points): Increase the total movement of every base in the army by 5 cm. Apply this bonus after doubling or tripling the base's movement according to its order.\n\n"
        "Camouflage (5 points): Class 1 and 2 bases gain a 10 cm Infiltration move. If they already possess an Infiltration move, increase it by 10 cm.\n\n"
        "Carapace (5 points): For every complete 1,000 points in the army, the controlling player may reroll one saving throw per turn. This effect may only be used once per detachment during a given turn.\n\n"
        "Assault Expert (5 points): Every base in the army may reroll results of 1 on its assault dice.\n\n"
        "Psychic Scream (5 points): Every enemy detachment with at least one base within a Synapse radius suffers a -1 penalty to its Morale value.\n\n"
        "Shadow in the Warp (4 points): Before deployment, for every complete 2,000 points in the army, one Synapse creature may be given the Dread (-1) ability.\n\n"
        "Acidic Entrails (3 points): If a Tyranid base loses an assault duel after rolling at least one double on its assault dice, it inflicts one AP 0 hit against the base that defeated it.\n\n"
        "Overwhelming Swarm (3 points): Each outnumbering bonus adds 1D6+1 to AF instead of 1D6.\n\n"
        "Subterranean Surge (2 points): When entering the battlefield, a Trygon may bring two Hormagaunt swarms with it instead of one.\n\n"
        "Enhanced Synaptic Link (2 points): Increase the Synapse radius of every Synapse creature by 10 cm.\n\n"
        "Synaptic Nodes (2 points): For every complete 3,000 points in the army, the Slave ability of one detachment may be replaced with Synapse (10 cm).\n\n"
        "Bio-Synaptic Instinct (1 point): For every complete 2,000 points in the army, the Slave ability of one detachment may be replaced with Semi-Synaptic. The Semi-Synaptic creature retains the same Instinct as the original creature.\n\n"
        "Adrenaline Surge (1 point): For every complete 2,000 points in the army, increase the AF of one detachment by 1.",
    ),
    (
        "Tyranid Titan Hit Location Chart",
        "### Alpha Hierodule / Hierophant Titan\n\n"
        "| D6 | Front/Rear Location |\n"
        "| --- | --- |\n"
        "| 1–2 | Legs |\n"
        "| 3 | Weapon |\n"
        "| 4 | Head (front) / Abdomen (rear) |\n"
        "| 5 | Abdomen |\n"
        "| 6 | Player's choice |",
    ),
    (
        "Tyranid Titan Damage Effects",
        "### Body\n\n"
        "| Result | Effect |\n"
        "| --- | --- |\n"
        "| 1 | 1 additional point of damage |\n"
        "| 2 | 1 additional point of damage; reduce Regeneration by 1 |\n"
        "| 3+ | 2 additional points of damage |\n\n"
        "### Weapon\n\n"
        "| Result | Effect |\n"
        "| --- | --- |\n"
        "| 1 | Weapon damaged (Repair on 4+) |\n"
        "| 2 | Weapon destroyed |\n"
        "| 3+ | Damage to the Body |\n\n"
        "### Leg\n\n"
        "| Result | Effect |\n"
        "| --- | --- |\n"
        "| 1 | -- |\n"
        "| 2 | Reduce the Titan's base Movement by 5 cm (Repair on 4+). From this damage onward, the Titan falls if it is destroyed. |\n"
        "| 3 | Reduce the Titan's base Movement by an additional 5 cm (Repair on 4+) |\n"
        "| 4 | Immobilised; 1 additional point of damage |\n"
        "| 5+ | Damage to the Body |\n\n"
        "### Head\n\n"
        "| Result | Effect |\n"
        "| --- | --- |\n"
        "| 1 | -1D6 to AF (Repair on 4+) |\n"
        "| 2 | May only receive an order on a 4+ (Repair on 4+); 1 additional point of damage |\n"
        "| 3+ | Damage to the Body |\n\n"
        "### Abdomen\n\n"
        "| Result | Effect |\n"
        "| --- | --- |\n"
        "| 1 | -1 AF; lose 1D3 transported bases |\n"
        "| 2 | -1 AF; 1 additional point of damage; lose 1D3 transported bases |\n"
        "| 3+ | -1 AF; damage to the Body; reduce Regeneration by 1; lose all transported bases |",
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


def melee(name="Claws"):
    return w(name, "--", "--", "--", "--")


TITAN_WEAPONS = [
    w("Bio-Cannon", "75 cm", "2", "4+", "-3", [("Damage (+X)", "1")], titan=1),
    w(
        "Spore Pods",
        "0 cm",
        "Template",
        "4+",
        "0",
        [
            ("Reduces Cover (X)", "-3"),
            ("Bio-Toxin", ""),
            ("Spore Pods", ""),
        ],
        titan=1,
    ),
    w(
        "Bile Spitter -- Focused",
        "60 cm",
        "3",
        "3+",
        "-2",
        [("Reduces Cover (X)", "-3")],
        titan=1,
    ),
    w(
        "Bile Spitter -- Diffuse",
        "60 cm",
        "Template",
        "4+",
        "0",
        [("Template (X)", "12 cm"), ("Reduces Cover (X)", "-1")],
        titan=1,
    ),
    w(
        "Spine Clusters",
        "30 cm",
        "Template",
        "3+",
        "-2",
        [("Template (X)", "7.5 cm"), ("Fires Twice", "")],
        titan=1,
    ),
    w(
        "Pyro-Acid Jet",
        "0 cm",
        "Template",
        "4+",
        "-1",
        [("Flame Template", ""), ("Reduces Cover (X)", "-3")],
        titan=1,
    ),
    w("Razor Claws", "45 cm", "5", "4+", "0", [("Razor Claws", "")], titan=1),
    w("Dart Salvo", "45 cm", "6", "4+", "-1", titan=1),
    w(
        "Tentacles",
        "20 cm",
        "1",
        "2+",
        "-4",
        [("Tentacles", "")],
        titan=1,
    ),
]

BASES = [
    dict(
        name="Barbgaunt",
        cls=1,
        mv="10",
        save="--",
        fa="+0",
        morale="6",
        abilities=[("Slave (Nest)", "")],
        weapons=[w("Barbed Cannon", "45 cm", "1", "4+", "0")],
    ),
    dict(
        name="Hive Guard",
        cls=1,
        mv="10",
        save="4+",
        fa="+2",
        morale="6",
        abilities=[("Slave (Nest)", "")],
        weapons=[w("Impaler Cannon", "45 cm", "1", "4+", "-2")],
    ),
    dict(
        name="Gargoyles",
        cls=1,
        mv="15",
        save="--",
        fa="+1",
        morale="6",
        abilities=[("Infiltration", ""), ("Jump Packs", ""), ("Slave (Hunt)", "")],
        weapons=[
            w("Flame Jet", "20 cm", "1", "5+", "0", [("Reduces Cover (X)", "-3")])
        ],
    ),
    dict(
        name="Alpha Genestealer",
        cls=1,
        mv="15",
        save="5+f",
        fa="+8",
        morale="Attached",
        abilities=[
            ("Synapse (X)", "15 cm"),
            ("Attached Character", ""),
            ("HQ", ""),
            ("Infiltration", ""),
            ("Elite (X)", "1"),
            ("Damage (+X) in Assault", "1"),
        ],
        weapons=[melee("Claws and Pincers")],
    ),
    dict(
        name="Genestealers",
        cls=1,
        mv="15",
        save="--",
        fa="+6",
        morale="5",
        abilities=[
            ("Semi-Synaptic (Devastation)", ""),
            ("Infiltration", ""),
            ("Elite (X)", "1"),
        ],
        weapons=[melee("Claws and Pincers")],
    ),
    dict(
        name="Tyranid Warriors",
        cls=1,
        mv="10",
        save="4+",
        fa="+5",
        morale="--",
        abilities=[
            ("HQ", ""),
            ("Synapse (X)", "20 cm"),
            ("Elite (X)", "2"),
            ("Regeneration (X+)", "5"),
        ],
        weapons=[w("Deathspitter", "45 cm", "1", "4+", "-1")],
    ),
    dict(
        name="Hormagaunts",
        cls=1,
        mv="15",
        save="--",
        fa="+2",
        morale="6",
        abilities=[("Slave (Devastation)", "")],
        weapons=[melee("Claws")],
    ),
    dict(
        name="Lictor",
        cls=1,
        mv="15",
        save="5+",
        fa="+5",
        morale="5",
        abilities=[
            ("Infiltration", ""),
            ("Semi-Synaptic (Hunt)", ""),
            ("Advanced Camouflage", ""),
        ],
        weapons=[w("Hooks", "20 cm", "2", "5+", "0")],
    ),
    dict(
        name="Termagants",
        cls=1,
        mv="15",
        save="--",
        fa="+1",
        morale="6",
        abilities=[("Slave (Hunt)", "")],
        weapons=[w("Fleshborer", "30 cm", "1", "5+", "0")],
    ),
    dict(
        name="Rippers",
        cls=1,
        mv="10",
        save="--",
        fa="-1",
        morale="6",
        abilities=[("Free Deployment", ""), ("Slave (Devastation)", "")],
        weapons=[melee("Claws")],
    ),
    dict(
        name="Raveners",
        cls=2,
        mv="20",
        save="6+f",
        fa="+4",
        morale="6",
        abilities=[
            ("Deep Strike (X)", "2"),
            ("Slave (Devastation)", ""),
            ("Walker", ""),
        ],
        weapons=[w("Devourer", "20 cm", "2", "5+", "-1")],
    ),
    dict(
        name="Carnifex",
        cls=2,
        mv="15",
        save="3+",
        fa="+6",
        morale="6",
        abilities=[
            ("Fear", ""),
            ("Slave (Devastation)", ""),
            ("Regeneration (X+)", "5"),
            ("Damage (+X) in Assault", "1"),
        ],
        weapons=[w("Bio-Plasma", "30 cm", "1", "4+", "-2")],
    ),
    dict(
        name="Winged Hive Tyrant",
        cls=2,
        mv="25",
        save="3+",
        fa="+7",
        morale="--",
        abilities=[
            ("HQ", ""),
            ("Elite (X)", "2"),
            ("Antigrav", ""),
            ("Fear", ""),
            ("Psychic Save (X+)", "4"),
            ("Synapse (X)", "20 cm"),
            ("Damage (+X) in Assault", "1"),
            ("Regeneration (X+)", "5"),
        ],
        weapons=[w("Devourer", "20 cm", "2", "5+", "-1")],
    ),
    dict(
        name="Hive Tyrant",
        cls=2,
        mv="15",
        save="3+",
        fa="+6",
        morale="--",
        abilities=[
            ("HQ", ""),
            ("Elite (X)", "2"),
            ("Fear", ""),
            ("Psychic Save (X+)", "4"),
            ("Synapse (X)", "20 cm"),
            ("Regeneration (X+)", "5"),
        ],
        weapons=[w("Heavy Venom Cannon", "45 cm", "2", "4+", "-1")],
    ),
    dict(
        name="Venomthrope",
        cls=2,
        mv="15",
        save="4+",
        fa="+4",
        morale="6",
        abilities=[("Close Defences (X+)", "5"), ("Slave (Devastation)", "")],
        weapons=[melee("Spore Nest")],
    ),
    dict(
        name="Zoanthrope",
        cls=2,
        mv="10",
        save="5+",
        fa="+1",
        morale="5",
        abilities=[
            ("Semi-Synaptic (Nest)", ""),
            ("Psychic Save (X+)", "4"),
            ("Protection (X+)", "4"),
        ],
        weapons=[
            w(
                "Warp Blast",
                "60 cm",
                "1",
                "4+",
                "Psy",
                [("Psychic Attack", ""), ("Anti-Aircraft", "")],
            )
        ],
    ),
    dict(
        name="Biovore",
        cls=3,
        mv="15",
        save="4+",
        fa="+0",
        morale="6",
        abilities=[("Slave (Nest)", ""), ("Walker", "")],
        weapons=[
            w(
                "Spore-Mines",
                "90 cm",
                "Template",
                "4+",
                "-1",
                [
                    ("Artillery", ""),
                    ("Battery", ""),
                    ("Template (X)", "12 cm"),
                    ("Reduces Cover (X)", "-1"),
                    ("Bio-Toxin", ""),
                    ("Spore-Mine", ""),
                ],
            )
        ],
    ),
    dict(
        name="Dactylis",
        cls=3,
        mv="15",
        save="3+",
        fa="+1",
        morale="6",
        abilities=[("Slave (Nest)", ""), ("Walker", "")],
        weapons=[
            w(
                "Bile Pods -- Spores",
                "90 cm",
                "2",
                "3+",
                "0",
                [("Artillery", ""), ("Reduces Cover (X)", "-2")],
            ),
            w(
                "Bile Pods -- Bio-Acid",
                "90 cm",
                "2",
                "4+",
                "-2",
                [("Artillery", "")],
            ),
        ],
    ),
    dict(
        name="Exocrine",
        cls=3,
        mv="15",
        save="3+",
        fa="+1",
        morale="6",
        abilities=[("Slave (Nest)", ""), ("Walker", "")],
        weapons=[w("Bio-Plasma Cannon", "75 cm", "2", "4+", "-3")],
    ),
    dict(
        name="Harpy",
        cls=3,
        mv="25",
        save="3+",
        fa="+4",
        morale="5",
        abilities=[("Floater", ""), ("Semi-Synaptic (Hunt)", "")],
        weapons=[
            w("Venom Cannon", "30 cm", "2", "4+", "-1"),
            w(
                "Spore-Mines",
                "Bomb",
                "Template",
                "4+",
                "0",
                [
                    ("Template (X)", "7.5 cm"),
                    ("Bombardment (X)", "1"),
                    ("Spore-Mine", ""),
                    ("Battery", ""),
                    ("Bio-Toxin", ""),
                ],
            ),
        ],
    ),
    dict(
        name="Haruspex",
        cls=3,
        mv="20",
        save="2+",
        fa="+7",
        morale="6",
        abilities=[("Slave (Devastation)", ""), ("Walker", "")],
        weapons=[w("Hooks", "20 cm", "2", "5+", "0")],
    ),
    dict(
        name="Malefactor",
        cls=3,
        mv="20",
        save="2+",
        fa="+5",
        morale="Attached",
        abilities=[
            ("Slave (Devastation)", ""),
            ("Transport (X)", "2"),
            ("Attached Transport", ""),
            ("Walker", ""),
        ],
        weapons=[w("Fragmentation Spines", "20 cm", "2", "5+", "0")],
    ),
    dict(
        name="Neurotyrant",
        cls=3,
        mv="20",
        save="3+",
        fa="+2",
        morale="--",
        abilities=[
            ("Leader", ""),
            ("Synapse (X)", "30 cm"),
            ("Dark Presence (-X / Y cm)", "1, 12"),
            ("Walker", ""),
        ],
        weapons=[
            w("Energy Torrent", "20 cm", "2", "4+", "0", [("Reduces Cover (X)", "-3")])
        ],
    ),
    dict(
        name="Pyrovore",
        cls=3,
        mv="15",
        save="4+",
        fa="+0",
        morale="6",
        abilities=[("Slave (Nest)", ""), ("Walker", "")],
        weapons=[
            w(
                "Bio-Flame Lance Cannon",
                "30 cm",
                "2",
                "3+",
                "0",
                [("Artillery", ""), ("Reduces Cover (X)", "-3")],
            )
        ],
    ),
    dict(
        name="Mycetic Spore",
        cls=3,
        mv="0",
        save="3+",
        fa="+0",
        morale="--",
        abilities=[
            ("Deep Strike (X)", "2"),
            ("Transport (Special)", ""),
            ("Mycetic Spore", ""),
        ],
        weapons=[],
    ),
    dict(
        name="Tervigon",
        cls=3,
        mv="20",
        save="2+",
        fa="+5",
        morale="Attached",
        abilities=[
            ("Slave (Devastation)", ""),
            ("Regeneration (X+)", "5"),
            ("Transport (X Termagants)", "4"),
            ("Attached Transport", ""),
            ("Walker", ""),
        ],
        weapons=[w("Fragmentation Spines", "20 cm", "2", "5+", "0")],
    ),
    dict(
        name="Toxicrene",
        cls=3,
        mv="20",
        save="2+",
        fa="+5",
        morale="6",
        abilities=[("Slave (Devastation)", ""), ("Close Defences (X+)", "5"), ("Walker", "")],
        weapons=[melee("Spore Nest")],
    ),
    dict(
        name="Virago",
        cls=3,
        mv="25",
        save="3+",
        fa="+6",
        morale="5",
        abilities=[
            ("Interceptor", ""),
            ("Floater", ""),
            ("Semi-Synaptic (Devastation)", ""),
        ],
        weapons=[
            w("Salivary Cannon", "20 cm", "2", "4+", "0", [("Reduces Cover (X)", "-3")])
        ],
    ),
    dict(
        name="Barbed Hierodule",
        cls=4,
        mv="20",
        save="2+",
        fa="+10",
        morale="5",
        abilities=[
            ("Terror", ""),
            ("Close Defences (X+)", "5"),
            ("Regeneration (X+)", "5"),
            ("Wounds (X)", "3"),
            ("Slave (Nest)", ""),
            ("Psychic Save (X+)", "4"),
        ],
        weapons=[
            w("Bio-Cannons", "75 cm", "2", "3+", "-3", [("Damage (+X)", "1")]),
            w("Fragmentation Spines", "20 cm", "5", "5+", "0"),
        ],
    ),
    dict(
        name="Scythed Hierodule",
        cls=4,
        mv="20",
        save="2+",
        fa="+12",
        morale="5",
        abilities=[
            ("Terror", ""),
            ("Close Defences (X+)", "5"),
            ("Regeneration (X+)", "5"),
            ("Wounds (X)", "3"),
            ("Slave (Devastation)", ""),
            ("Psychic Save (X+)", "4"),
            ("Damage (+X) in Assault", "2"),
        ],
        weapons=[
            w(
                "Pyro-Acid Jet",
                "0 cm",
                "Template",
                "4+",
                "-1",
                [("Flame Template", ""), ("Reduces Cover (X)", "-3")],
            )
        ],
    ),
    dict(
        name="Razorfex",
        cls=4,
        mv="20",
        save="2+",
        fa="+9",
        morale="5",
        abilities=[
            ("Wounds (X)", "2"),
            ("Fear", ""),
            ("Regeneration (X+)", "5"),
            ("Slave (Devastation)", ""),
            ("Damage (+X) in Assault", "2"),
        ],
        weapons=[w("Bio-Plasma", "30 cm", "1", "3+", "-2")],
    ),
    dict(
        name="Norn Queen",
        cls=4,
        mv="15",
        save="2+",
        fa="+10",
        morale="--",
        abilities=[
            ("Character", ""),
            ("Terror", ""),
            ("Wounds (X)", "3"),
            ("Regeneration (X+)", "5"),
            ("Psychic Save (X+)", "4"),
            ("Psyker", ""),
            ("Synapse (X)", "30 cm"),
            ("Synaptic Overload", ""),
            ("Damage (+X) in Assault", "1"),
            ("Forward Observer (FO)", ""),
            ("Bio-Resistance", ""),
            ("Psychic Scream", ""),
            ("Psychic Projectile", ""),
        ],
        weapons=[w("Venom Cannon", "45 cm", "2", "4+", "-2")],
    ),
    dict(
        name="Dominatrix",
        cls=4,
        mv="15",
        save="2+",
        fa="+10",
        morale="--",
        abilities=[
            ("Character", ""),
            ("Close Defences (X+)", "6"),
            ("Wounds (X)", "5"),
            ("Synapse (X)", "45 cm"),
            ("Regeneration (X+)", "5"),
            ("Terror", ""),
            ("Psychic Save (X+)", "2"),
            ("Psyker", ""),
            ("Synaptic Overload", ""),
            ("Forward Observer (FO)", ""),
            ("Warp Field", ""),
            ("Energy Torrent", ""),
            ("Synaptic Beacon", ""),
        ],
        weapons=[
            w("Bio-Plasma Cannons", "75 cm", "4", "4+", "-3", [("Turret", "")]),
            w(
                "Energy Torrent -- Focused",
                "90 cm",
                "1",
                "3+",
                "-4",
                [("Psychic Attack", "")],
            ),
            w(
                "Energy Torrent -- Diffuse",
                "90 cm",
                "Template",
                "3+",
                "-1",
                [
                    ("Psychic Attack", ""),
                    ("Template (X)", "7.5 cm"),
                    ("Reduces Cover (X)", "-1"),
                ],
            ),
        ],
    ),
    dict(
        name="Harridan",
        cls=4,
        mv="20",
        save="2+",
        fa="+5",
        morale="--",
        abilities=[
            ("Floater", ""),
            ("Regeneration (X+)", "5"),
            ("Synapse (X)", "20 cm"),
            ("Wounds (X)", "3"),
            ("Transport (X Gargoyles)", "5"),
            ("Infiltration", ""),
        ],
        weapons=[
            w("Bio-Cannon", "45 cm", "3", "4+", "-2"),
            w(
                "Spore Cloud",
                "Bomb",
                "Template",
                "2+",
                "0",
                [
                    ("Template (X)", "7.5 cm"),
                    ("Bio-Toxin", ""),
                    ("Bombardment (X)", "1"),
                ],
            ),
        ],
    ),
    dict(
        name="Trygon",
        cls=4,
        mv="15",
        save="2+",
        fa="+7",
        morale="--",
        abilities=[
            ("Character", ""),
            ("Integral Armour", ""),
            ("Regeneration (X+)", "5"),
            ("Wounds (X)", "2"),
            ("Deep Strike (X)", "2"),
            ("Synapse (X)", "15 cm"),
            ("Subterranean Assault", ""),
        ],
        weapons=[
            w("Bio-Shock", "20 cm", "3", "3+", "-2", [("Reduces Cover (X)", "-1")]),
            w("Lightning", "Assault", "1D3", "3+", "-1"),
        ],
    ),
    dict(
        name="Assault Tyrannofex",
        cls=4,
        mv="20",
        save="2+",
        fa="+8",
        morale="7",
        abilities=[
            ("Wounds (X)", "2"),
            ("Close Defences (X+)", "4"),
            ("Regeneration (X+)", "5"),
            ("Fear", ""),
            ("Slave (Devastation)", ""),
            ("Damage (+X) in Assault", "1"),
        ],
        weapons=[melee("Spore Cloud")],
    ),
    dict(
        name="Support Tyrannofex",
        cls=4,
        mv="15",
        save="2+",
        fa="+5",
        morale="7",
        abilities=[
            ("Wounds (X)", "2"),
            ("Close Defences (X+)", "6"),
            ("Regeneration (X+)", "5"),
            ("Fear", ""),
            ("Slave (Nest)", ""),
        ],
        weapons=[
            w("Bio-Plasma Cannon", "60 cm", "2", "4+", "-3", [("Turret", "")]),
            w("Fragmentation Spines", "20 cm", "5", "5+", "0"),
        ],
    ),
    dict(
        name="Alpha Hierodule",
        cls=5,
        mv="25",
        save="2+ Chart",
        fa="+13",
        morale="--",
        titan=2,
        abilities=[
            ("Psychic Save (X+)", "4"),
            ("Wounds (X)", "6"),
            ("Terror", ""),
            ("Close Defences (X+)", "5"),
            ("Regeneration (X+)", "4"),
            ("Agile", ""),
            ("Semi-Synaptic", ""),
            ("Damage (+X) in Assault", "2"),
        ],
        weapons=[w("Fragmentation Spines", "20 cm", "2", "4+", "0")] + TITAN_WEAPONS,
    ),
    dict(
        name="Hierophant",
        cls=6,
        mv="25",
        save="2+ Chart",
        fa="+17",
        morale="--",
        titan=3,
        abilities=[
            ("Psychic Save (X+)", "4"),
            ("Wounds (X)", "9"),
            ("Terror", ""),
            ("Close Defences (X+)", "5"),
            ("Regeneration (X+)", "4"),
            ("Agile", ""),
            ("Semi-Synaptic", ""),
            ("Transport (X)", "5"),
            ("Damage (+X) in Assault", "2"),
        ],
        weapons=[w("Fragmentation Spines", "20 cm", "3", "4+", "0")] + TITAN_WEAPONS,
    ),
    dict(
        name="Bio-Plasma Shot",
        cls=0,
        mv="--",
        save="--",
        fa="--",
        morale="--",
        abilities=[("Off-Table Artillery", "")],
        weapons=[
            w(
                "Bio-Plasma",
                "--",
                "Template",
                "3+",
                "-2",
                [("Template (X)", "7.5 cm"), ("Reduces Cover (X)", "-3")],
            )
        ],
    ),
    dict(
        name="Spore-Mine Shot",
        cls=0,
        mv="--",
        save="--",
        fa="--",
        morale="--",
        abilities=[("Off-Table Artillery", "")],
        weapons=[
            w(
                "Spore-Mines",
                "--",
                "Template",
                "4+",
                "-1",
                [
                    ("Template (X)", "12 cm"),
                    ("Spore-Mine", ""),
                    ("Bio-Toxin", ""),
                    ("Reduces Cover (X)", "-1"),
                ],
            )
        ],
    ),
]


def formation(kind, name, contents, cp, cost, dets):
    return dict(kind=kind, name=name, contents=contents, cp=cp, cost=cost, dets=dets)


def one(det_name, cp, cls, unit, count):
    return [(det_name, cp, cls, [(unit, count)])]


FORMATIONS = [
    formation(7, "Dominatrix Detachment", "1 Dominatrix base (Limit: one per 3,000 points)", 6, 400, one("Dominatrix Detachment", 6, 4, "Dominatrix", 1)),
    formation(5, "Alpha Genestealer", "1 Alpha Genestealer base (May only be attached to Genestealers)", 1, 50, one("Alpha Genestealer", 1, 1, "Alpha Genestealer", 1)),
    formation(7, "Tyranid Warrior Detachment", "4 Tyranid Warrior bases", 3, 225, one("Tyranid Warrior Detachment", 3, 1, "Tyranid Warriors", 4)),
    formation(7, "Harridan Detachment", "1 Harridan base", 1, 225, one("Harridan Detachment", 1, 4, "Harridan", 1)),
    formation(7, "Neurotyrant Detachment", "3 Neurotyrant bases", 1, 175, one("Neurotyrant Detachment", 1, 3, "Neurotyrant", 3)),
    formation(7, "Winged Hive Tyrant Detachment", "3 Winged Hive Tyrant bases", 3, 250, one("Winged Hive Tyrant Detachment", 3, 2, "Winged Hive Tyrant", 3)),
    formation(7, "Hive Tyrant Detachment", "3 Hive Tyrant bases", 3, 250, one("Hive Tyrant Detachment", 3, 2, "Hive Tyrant", 3)),
    formation(7, "Norn Queen Detachment", "1 Norn Queen base", 3, 275, one("Norn Queen Detachment", 3, 4, "Norn Queen", 1)),
    formation(7, "Trygon Detachment", "1 Trygon base", 1, 200, one("Trygon Detachment", 1, 4, "Trygon", 1)),
    formation(8, "Barbgaunt Detachment", "5 Barbgaunt bases", -1, 100, one("Barbgaunt Detachment", -1, 1, "Barbgaunt", 5)),
    formation(8, "Hive Guard Detachment", "5 Hive Guard bases", -1, 200, one("Hive Guard Detachment", -1, 1, "Hive Guard", 5)),
    formation(8, "Gargoyle Detachment", "5 Gargoyle bases", -1, 125, one("Gargoyle Detachment", -1, 1, "Gargoyles", 5)),
    formation(8, "Genestealer Detachment", "5 Genestealer bases", -1, 200, one("Genestealer Detachment", -1, 1, "Genestealers", 5)),
    formation(8, "Hormagaunt Detachment", "5 Hormagaunt bases", -1, 100, one("Hormagaunt Detachment", -1, 1, "Hormagaunts", 5)),
    formation(8, "Lictor Detachment", "5 Lictor bases", -1, 225, one("Lictor Detachment", -1, 1, "Lictor", 5)),
    formation(8, "Termagant Detachment", "10 Termagant bases", -1, 150, one("Termagant Detachment", -1, 1, "Termagants", 10)),
    formation(8, "Ripper Detachment", "10 Ripper bases", -1, 100, one("Ripper Detachment", -1, 1, "Rippers", 10)),
    formation(8, "Ravener Detachment", "5 Ravener bases", -1, 200, one("Ravener Detachment", -1, 2, "Raveners", 5)),
    formation(8, "Carnifex Detachment", "3 Carnifex bases", -1, 175, one("Carnifex Detachment", -1, 2, "Carnifex", 3)),
    formation(8, "Venomthrope Detachment", "3 Venomthrope bases", -1, 100, one("Venomthrope Detachment", -1, 2, "Venomthrope", 3)),
    formation(8, "Zoanthrope Detachment", "3 Zoanthrope bases", -1, 175, one("Zoanthrope Detachment", -1, 2, "Zoanthrope", 3)),
    formation(8, "Biovore Detachment", "3 Biovore bases", -1, 225, one("Biovore Detachment", -1, 3, "Biovore", 3)),
    formation(8, "Dactylis Detachment", "3 Dactylis bases", -1, 250, one("Dactylis Detachment", -1, 3, "Dactylis", 3)),
    formation(8, "Exocrine Detachment", "3 Exocrine bases", -1, 225, one("Exocrine Detachment", -1, 3, "Exocrine", 3)),
    formation(8, "Harpy Detachment", "3 Harpy bases", -1, 225, one("Harpy Detachment", -1, 3, "Harpy", 3)),
    formation(8, "Haruspex Detachment", "3 Haruspex bases", -1, 175, one("Haruspex Detachment", -1, 3, "Haruspex", 3)),
    formation(8, "Pyrovore Detachment", "3 Pyrovore bases", -1, 125, one("Pyrovore Detachment", -1, 3, "Pyrovore", 3)),
    formation(8, "Toxicrene Detachment", "3 Toxicrene bases", -1, 150, one("Toxicrene Detachment", -1, 3, "Toxicrene", 3)),
    formation(8, "Virago Detachment", "3 Virago bases", -1, 200, one("Virago Detachment", -1, 3, "Virago", 3)),
    formation(8, "Barbed Hierodule Detachment", "1 Barbed Hierodule base", -2, 300, one("Barbed Hierodule Detachment", -2, 4, "Barbed Hierodule", 1)),
    formation(8, "Scythed Hierodule Detachment", "1 Scythed Hierodule base", -2, 250, one("Scythed Hierodule Detachment", -2, 4, "Scythed Hierodule", 1)),
    formation(8, "Razorfex Detachment", "3 Razorfex bases", -1, 300, one("Razorfex Detachment", -1, 4, "Razorfex", 3)),
    formation(8, "Assault Tyrannofex Detachment", "1 Assault Tyrannofex base", -1, 200, one("Assault Tyrannofex Detachment", -1, 4, "Assault Tyrannofex", 1)),
    formation(8, "Support Tyrannofex Detachment", "1 Support Tyrannofex base", -1, 200, one("Support Tyrannofex Detachment", -1, 4, "Support Tyrannofex", 1)),
    formation(8, "Alpha Hierodule Detachment", "1 Alpha Hierodule base (2 weapons must be purchased)", -2, 325, one("Alpha Hierodule Detachment", -2, 5, "Alpha Hierodule", 1)),
    formation(8, "Hierophant Detachment", "1 Hierophant base (3 weapons must be purchased)", -2, 425, one("Hierophant Detachment", -2, 6, "Hierophant", 1)),
    formation(5, "Malefactor Detachment", "3 Malefactor bases", -1, 125, one("Malefactor Detachment", -1, 3, "Malefactor", 3)),
    formation(5, "Mycetic Spore Detachment", "Enough Mycetic Spores to transport one Class 1 or 2 detachment", 0, 50, one("Mycetic Spore Detachment", 0, 3, "Mycetic Spore", 1)),
    formation(5, "Tervigon Detachment", "3 Tervigon bases", -1, 150, one("Tervigon Detachment", -1, 3, "Tervigon", 3)),
    formation(6, "Off-Table Artillery (Bio-Plasma)", "1 Bio-Plasma Shot (Limit: 1 per 2,000 points)", -1, 100, one("Off-Table Artillery (Bio-Plasma)", -1, 0, "Bio-Plasma Shot", 1)),
    formation(6, "Off-Table Artillery (Spore-Mine)", "1 Spore-Mine Shot (Limit: 1 per 2,000 points)", -1, 100, one("Off-Table Artillery (Spore-Mine)", -1, 0, "Spore-Mine Shot", 1)),
]

# Catalog purchases attached to each titan instance. Not army-list Option formations.
TITAN_CATALOG = [
    ("Bio-Cannon", 75, "Damage (+1).", 0, 0),
    ("Spore Pods", 50, "Limited to one per Bio-Titan. Increases Close Defences to 4+.", 0, 1),
    ("Bile Spitter", 75, "Choose Focused or Diffuse firing mode.", 0, 0),
    ("Spine Clusters", 75, "Template (7.5 cm), Fires Twice.", 0, 0),
    ("Pyro-Acid Jet", 50, "Flame Template, Reduces Cover (-3).", 0, 0),
    ("Razor Claws", 75, "Assault weapon. Choose one effect.", 1, 0),
    ("Dart Salvo", 75, "", 0, 0),
    ("Tentacles", 50, "Choose one effect.", 0, 0),
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


def emit_tyranids_sql() -> str:
    lines = [
        "-- Tyranids 3.0.0 from NetEpicFR300-EnglishTranslation/Tyranids 300",
        "-- Replaces the dummy Tyranid seed. Also deletes all army lists.",
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
        "ALTER TABLE `Base`",
        "    MODIFY Morale VARCHAR(16) NOT NULL,",
        "    MODIFY Movement VARCHAR(16) NOT NULL,",
        "    MODIFY FA VARCHAR(16) NOT NULL;",
        "ALTER TABLE Weapon",
        "    MODIFY Dice VARCHAR(32) NOT NULL,",
        "    MODIFY ArmourPenetration VARCHAR(16) NOT NULL;",
        "",
        "INSERT INTO FormationKind (FormationKindId, KindName)",
        "SELECT 7, 'Synapse' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 7);",
        "INSERT INTO FormationKind (FormationKindId, KindName)",
        "SELECT 8, 'Slave' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 8);",
        "",
        "DELETE FROM ArmyFormation;",
        "DELETE FROM Army;",
        "",
        "INSERT INTO Codex (CodexName)",
        "SELECT 'Tyranids'",
        "WHERE NOT EXISTS (SELECT 1 FROM Codex WHERE CodexName = 'Tyranids');",
        "",
        "SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Tyranids');",
        "",
        "DELETE FROM TitanWeapon WHERE CodexId = @codexId;",
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
        "DELETE FROM Formation WHERE CodexId = @codexId;",
        "DELETE FROM Detachment WHERE CodexId = @codexId;",
        "DELETE FROM `Base` WHERE CodexId = @codexId;",
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
        union_rows(ABILITIES),
        ") AS src ON src.n = sa.SpecialAbilityName",
        "SET sa.Description = src.d;",
        "",
        "INSERT INTO SpecialRule (CodexId, SpecialRuleName, Description)",
        "SELECT @codexId, n, d FROM (",
        union_rows(SPECIAL_RULES),
        ") AS src;",
        "",
        "-- Figure PNGs are stored in Base.Image; run upload_base_images.py after this seed.",
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
    lines.append(",\n".join(base_values) + ";")
    lines.append("")
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
    return "\n".join(lines) + "\n"


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


def emit_formations_sql() -> str:
    lines = [
        "-- Tyranids 3.0.0 army formations from",
        "-- NetEpicFR300-EnglishTranslation/Tyranids 300/army-formations.tex",
        "",
        "SET NAMES utf8mb4;",
        "",
        "SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Tyranids');",
        "",
    ]
    det_rows = []
    seen = set()
    for f in FORMATIONS:
        for det in f["dets"]:
            dname, dcp, dcls, _ = det
            if dname in seen:
                continue
            seen.add(dname)
            det_rows.append(
                f"    (@codexId, '{sql_str(dname)}', {dcp}, {dcls})"
            )
    if det_rows:
        lines.append("INSERT INTO Detachment (")
        lines.append("    CodexId, DetachmentName, CommandPoints, `Class`")
        lines.append(") VALUES")
        lines.append(",\n".join(det_rows) + ";")
        lines.append("")

    comp_union = []
    first = True
    for f in FORMATIONS:
        for dname, dcp, dcls, units in f["dets"]:
            for unit, count in units:
                prefix = "    SELECT" if first else "    UNION ALL SELECT"
                first = False
                comp_union.append(
                    f"{prefix} '{sql_str(dname)}' AS DetachmentName, "
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
            f"{f['cost']}, {f['cp']}, '{sql_str(f['contents'])}', 0)"
        )
    lines.append("INSERT INTO Formation (")
    lines.append("    CodexId, FormationKindId, FormationName, PointsCost, CommandPoints, Contents,")
    lines.append("    DestructionPoints")
    lines.append(") VALUES")
    lines.append(",\n".join(form_rows) + ";")
    lines.append("")

    fd_union = []
    first = True
    for f in FORMATIONS:
        for dname, dcp, dcls, units in f["dets"]:
            prefix = "    SELECT" if first else "    UNION ALL SELECT"
            first = False
            fd_union.append(
                f"{prefix} '{sql_str(f['name'])}' AS FormationName, "
                f"'{sql_str(dname)}' AS DetachmentName"
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

    lines.extend(emit_titan_catalog_sql())
    return "\n".join(lines) + "\n"


def main() -> None:
    (OUT / "tyranids.sql").write_text(emit_tyranids_sql(), encoding="utf-8")
    (OUT / "tyranids-army-formations.sql").write_text(emit_formations_sql(), encoding="utf-8")
    print("Wrote tyranids.sql and tyranids-army-formations.sql")


if __name__ == "__main__":
    main()
