-- Tyranids 3.0.0 from NetEpicFR300-EnglishTranslation/Tyranids 300
-- Replaces the dummy Tyranid seed. Also deletes all army lists.

SET NAMES utf8mb4;

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

SET @hasTitanWeapons := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'ArmyFormation'
      AND COLUMN_NAME = 'TitanWeapons'
);
SET @sql := IF(
    @hasTitanWeapons = 0,
    'ALTER TABLE ArmyFormation ADD COLUMN TitanWeapons JSON NULL',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

DROP TABLE IF EXISTS ArmyFormationWeapon;

ALTER TABLE `Base`
    MODIFY Morale VARCHAR(16) NOT NULL,
    MODIFY Movement VARCHAR(16) NOT NULL,
    MODIFY FA VARCHAR(16) NOT NULL;
ALTER TABLE Weapon
    MODIFY Dice VARCHAR(32) NOT NULL,
    MODIFY ArmourPenetration VARCHAR(16) NOT NULL;

INSERT INTO FormationKind (FormationKindId, KindName)
SELECT 7, 'Synapse' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 7);
INSERT INTO FormationKind (FormationKindId, KindName)
SELECT 8, 'Slave' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 8);

DELETE FROM ArmyFormation;
DELETE FROM Army;

INSERT INTO Codex (CodexName)
SELECT 'Tyranids'
WHERE NOT EXISTS (SELECT 1 FROM Codex WHERE CodexName = 'Tyranids');

SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Tyranids');

DELETE FROM TitanWeapon WHERE CodexId = @codexId;

DELETE wsa FROM WeaponSpecialAbility wsa
INNER JOIN Weapon w ON w.WeaponId = wsa.WeaponId
INNER JOIN `Base` b ON b.BaseId = w.BaseId
WHERE b.CodexId = @codexId;

DELETE bsa FROM BaseSpecialAbility bsa
INNER JOIN `Base` b ON b.BaseId = bsa.BaseId
WHERE b.CodexId = @codexId;

DELETE bpp FROM BasePsychicPower bpp
INNER JOIN `Base` b ON b.BaseId = bpp.BaseId
WHERE b.CodexId = @codexId;

DELETE fd FROM FormationDetachment fd
INNER JOIN Formation f ON f.FormationId = fd.FormationId
WHERE f.CodexId = @codexId;

DELETE dc FROM DetachmentComposition dc
INNER JOIN Detachment d ON d.DetachmentId = dc.DetachmentId
WHERE d.CodexId = @codexId;

DELETE w FROM Weapon w
INNER JOIN `Base` b ON b.BaseId = w.BaseId
WHERE b.CodexId = @codexId;

DELETE FROM Formation WHERE CodexId = @codexId;
DELETE FROM Detachment WHERE CodexId = @codexId;
DELETE FROM `Base` WHERE CodexId = @codexId;
DELETE FROM SpecialRule WHERE CodexId = @codexId;

INSERT INTO SpecialAbility (SpecialAbilityName, Description)
SELECT n, d FROM (
    SELECT 'Synapse (X)' AS n, 'Detachments with this ability receive orders normally.

They may also control Slave detachments if at least one base from the Slave detachment is within X cm of a Synapse base.

Detachments arriving through the Tunneller or Mycetic Spore rules may receive an order if they are within the Synapse radius of a base when they arrive.

The Synapse radius functions even if the Synapse base or the Slave bases are inside transports.

A Synapse base attached to a detachment grants the Synapse ability to the entire detachment.

A detachment following an Instinct order loses its Synapse ability.' AS d
    UNION ALL SELECT 'Slave (Hunt)' AS n, 'Slave detachments follow their Instinct order if they are outside the Synapse radius of a Synapse base during the Orders step, or if they have failed a Hive Mind Test.

All movement required by an Instinct order is performed normally during the Movement Phase.

Hunt: During the Movement Phase, the detachment moves its normal Movement characteristic towards the closest enemy detachment that is not already engaged in an assault. If it makes contact, it engages that detachment in an assault.

If the detachment is not engaged in an assault, it must shoot at the closest valid enemy detachment during the Combat Phase.

If a detachment following an Instinct order uses a template weapon, centre the template over the closest enemy base.' AS d
    UNION ALL SELECT 'Slave (Devastation)' AS n, 'Slave detachments follow their Instinct order if they are outside the Synapse radius of a Synapse base during the Orders step, or if they have failed a Hive Mind Test.

All movement required by an Instinct order is performed normally during the Movement Phase.

Devastation: During the Movement Phase, the detachment must move twice its normal Movement characteristic towards the closest enemy detachment.

If the closest enemy detachment is already engaged in an assault, the Tyranid detachment may instead move towards the second-closest enemy detachment.

If it makes contact with an enemy, it engages that enemy in an assault. A detachment following the Devastation Instinct never makes ranged attacks.' AS d
    UNION ALL SELECT 'Slave (Nest)' AS n, 'Slave detachments follow their Instinct order if they are outside the Synapse radius of a Synapse base during the Orders step, or if they have failed a Hive Mind Test.

Nest: A detachment with this Instinct does not move. During the Combat Phase, it must shoot at the closest visible enemy detachment.

This is not a First Fire order. The detachment therefore cannot perform Overwatch Fire, reroll results of 1 on its To-Hit rolls, or perform Indirect Fire.

The detachment must shoot at an enemy even if that enemy is engaged in an assault.

If a detachment following an Instinct order uses a template weapon, centre the template over the closest enemy base.' AS d
    UNION ALL SELECT 'Semi-Synaptic' AS n, 'Detachments with this ability may receive orders normally, even while outside a Synapse radius.

If they fail a Hive Mind Test, they act as Slave creatures and follow their listed Instinct.' AS d
    UNION ALL SELECT 'Semi-Synaptic (Hunt)' AS n, 'Detachments with this ability may receive orders normally, even while outside a Synapse radius.

If they fail a Hive Mind Test, they act as Slave creatures and follow the Hunt Instinct.' AS d
    UNION ALL SELECT 'Semi-Synaptic (Devastation)' AS n, 'Detachments with this ability may receive orders normally, even while outside a Synapse radius.

If they fail a Hive Mind Test, they act as Slave creatures and follow the Devastation Instinct.' AS d
    UNION ALL SELECT 'Semi-Synaptic (Nest)' AS n, 'Detachments with this ability may receive orders normally, even while outside a Synapse radius.

If they fail a Hive Mind Test, they act as Slave creatures and follow the Nest Instinct.' AS d
    UNION ALL SELECT 'Synaptic Overload' AS n, 'Once per turn, a base with this ability may cause a detachment within its Synapse radius to automatically pass a Hive Mind Test.

The use of this ability must be declared before making the test.' AS d
    UNION ALL SELECT 'Bio-Toxin' AS n, 'Weapons with this ability cannot inflict damage upon allied Tyranid bases.' AS d
    UNION ALL SELECT 'Subterranean Assault' AS n, 'When a Trygon uses its Deep Strike ability to enter the battlefield, one Hormagaunt swarm may emerge with it.

Place the Hormagaunt detachment within 6 cm of the Trygon''s arrival point. Both detachments are placed on the battlefield simultaneously.' AS d
    UNION ALL SELECT 'Spore Pods' AS n, 'Spore Pods release clouds of toxic particles around the Bio-Titan. A Bio-Titan may purchase no more than one Spore Pod.

During the Combat Phase, every base within 15 cm of the centre of the Bio-Titan is hit:

 • On a 4+ if the Bio-Titan has an Advance or First Fire order.
 • On a 5+ if the Bio-Titan has a Charge or Forced March order.

Spore Pods have AP 0 and possess the Reduces Cover (-3) and Bio-Toxin abilities.

Spore Pods function even if the Bio-Titan is pinned in an assault. In this case, resolve the Spore Pod attacks before resolving the assault. Any damage inflicted counts towards the assault''s combat result.

Spore Pods do not suffer a To-Hit penalty when the Bio-Titan is engaged in an assault.

Spore Pods increase the Bio-Titan''s Close Defences to 4+.' AS d
    UNION ALL SELECT 'Spore-Mine' AS n, 'When an attack is made with a Spore-Mines weapon, it creates a hazardous area in addition to resolving the normal effects of the attack.

Leave the template in the position where the attack was resolved. It remains in play for the turn in which it was fired and for the following turn, after which it is removed.

The area counts as Dangerous Terrain (4+/AP 0) with the Bio-Toxin ability.

The Spore-Mine area may be targeted by shooting attacks. Each successful hit removes one Spore-Mine from the area.' AS d
    UNION ALL SELECT 'Mycetic Spore' AS n, 'Mycetic Spores follow these rules:

 • Spores are divided into groups. Each group consists of one or more detachments that purchased Mycetic Spores.
 • During Off-Table Arrivals, determine the group''s arrival point in the same manner as another off-table arrival. Mycetic Spores are not affected by the Limited Assault rule.
 • The Spores enter during the Movement Phase and may be targeted by Overwatch Fire. For range and line-of-sight purposes, they are considered to be at altitude directly above their arrival point.
 • Make one saving throw for each successful hit and remove destroyed Spores randomly. Troops transported inside Spores destroyed either in flight or on the ground cannot make Emergency Exit Tests.
 • Place all surviving Spores in coherency and within 12 cm of the arrival point. A Spore cannot be placed on an enemy base or within Impassable terrain.
 • The transported troops then disembark according to the normal Transport rules.
 • As soon as a Spore is empty, it is removed and considered destroyed. Empty Spores have no zones of control and cannot contest or secure objectives.
 • Each Mycetic Spore may transport one Class 1 or 2 base.' AS d
    UNION ALL SELECT 'Elite (X)' AS n, 'At the beginning of the battle, your army receives a shared pool of Elite rerolls.

Each detachment containing bases with Elite (X) adds X rerolls to this pool, regardless of how many Elite bases the detachment contains.

During the battle, Elite rerolls may be spent to reroll dice rolled by your Elite bases. Before using them, declare the total number of dice that will be rerolled.

Only one Elite reroll may be used per base for each dice roll. Consequently, only one die from an assault roll may be rerolled.

Used Elite rerolls are removed from the army''s pool.

Elite rerolls may be used for:

 • To-Hit rolls for any type of shooting attack.
 • Armour saving throws.
 • Assault rolls.
 • Dodge rolls.
 • Opportunity attacks made when an enemy disengages.' AS d
    UNION ALL SELECT 'Regeneration (X+)' AS n, 'When a base with Regeneration (X+) would lose one or more Wounds, roll one die for each Wound lost.

For each result equal to or greater than X, the base does not lose that Wound. Regeneration functions against both shooting attacks and assaults.

Regeneration is more difficult during an assault and suffers a -1 modifier.

Only one Regeneration attempt may be made for each Wound lost.

A successful Regeneration roll prevents the loss of the Wound but does not cancel any additional effects caused by the attack, particularly effects applied through a Titan''s hit-location chart.' AS d
    UNION ALL SELECT 'Deep Strike (X)' AS n, 'The controlling player selects a point on the battlefield and places one base from the detachment at that point. The base then scatters X times, moving 3D6 cm for each scatter.

If the final point is outside the battlefield, within Impassable terrain, or within the zone of control of an enemy base of the same or a higher class, the detachment does not arrive. Another attempt may be made during the following turn.

Otherwise, place the first base as close as possible to the final arrival point. Place every other base in the detachment anywhere within 6 cm of the first base.

No base may arrive within Impassable terrain or within the zone of control of an enemy base of the same or a higher class.

A detachment entering the battlefield in this manner cannot receive a First Fire order during the turn in which it arrives. It also loses 5 cm from its total available movement during that turn.

Limited Assault

On the first turn, a Class 3 or higher detachment cannot select an initial arrival point within the opposing player''s half of the battlefield.' AS d
    UNION ALL SELECT 'Damage (+X)' AS n, 'A weapon with this ability inflicts X additional hits against a base successfully hit by the weapon.' AS d
    UNION ALL SELECT 'Damage (+X) in Assault' AS n, 'A weapon with this ability inflicts X additional hits after its base wins a duel, in addition to the normal hit.' AS d
    UNION ALL SELECT 'Reduces Cover (X)' AS n, 'A weapon with this ability worsens the target''s cover save by X.' AS d
    UNION ALL SELECT 'Infiltration' AS n, 'These bases are stealthy and capable of approaching the enemy before the battle begins.

After deployment, bases with this ability may move up to 25 cm. This movement cannot bring a base into an enemy zone of control and cannot be performed while the detachment is being transported.' AS d
    UNION ALL SELECT 'Jump Packs' AS n, 'Bases equipped with Jump Packs may make short flights over terrain, buildings, and enemy troops.

They ignore enemy zones of control except those generated by bases with the Floater, Skimmer, or Jump Packs ability.

They also ignore terrain modifiers during their movement but cannot end their movement on Impassable terrain.

While using this ability to move over an obstacle, the base is considered to be at altitude.' AS d
    UNION ALL SELECT 'Attached Character' AS n, 'At the beginning of the battle, an Attached Character must join a detachment. The character and the detachment are then treated as a single detachment.

The Attached Character must remain in coherency with the detachment, uses its Morale value, and adds its points cost to the detachment''s total cost.

Attached Characters do not occupy space in transports. A single detachment may include up to two Attached Characters.

An Attached Character gains the Movement characteristic of the detachment to which it is attached. It also gains the detachment''s movement-related special abilities, including Infiltration, Free Deployment, Jump Packs, Skimmer, Hard to Hit, Camouflage, and Advanced Camouflage.

An Infantry Attached Character, Class 1, may be attached to an Infantry, Walker, or Cavalry detachment. If attached to a Walker or Cavalry detachment, it gains that detachment''s class. In all other cases, an Attached Character must join a detachment of the same type.' AS d
    UNION ALL SELECT 'HQ' AS n, 'HQ bases represent a small number of important individuals. While they remain close to another base of the same Blocking Class, they receive protection against shooting attacks.

When an HQ base is targeted by a shooting attack, its controlling player may select another base of the same class within 6 cm as the attack''s target instead.

This decision must be made before any saving throws are rolled.

HQ protection does not function during an assault.' AS d
    UNION ALL SELECT 'Advanced Camouflage' AS n, 'Advanced Camouflage functions like Camouflage, with the following addition:

If the terrain occupied by the detachment does not provide a cover save, the detachment receives a 5+ cover save. This becomes a 4+ cover save if the entire detachment has not yet fired and gives up its ability to fire during the current turn.

Camouflage: If a base occupies terrain that provides a cover save, improve that cover save by 1. The cover save may be improved by a further 1 if the entire detachment has not yet fired and gives up its ability to fire during the current turn. Camouflage only functions against enemy bases more than 25 cm away. A base engaged in an assault loses the benefit of Camouflage for the remainder of the turn.' AS d
    UNION ALL SELECT 'Free Deployment' AS n, 'Detachments with this ability may deploy anywhere within their controlling player''s half of the battlefield.

Free Deployment is resolved at the same time as Infiltration movement. Every base deployed in this manner must be placed at least 12 cm from every enemy base.

Once deployed, the detachment may also use its Infiltration ability, if it possesses it.' AS d
    UNION ALL SELECT 'Walker' AS n, 'A base with this ability suffers the same terrain movement penalties as a Walker-class base.' AS d
    UNION ALL SELECT 'Fear' AS n, 'A Class 1-3 detachment that enters base-to-base contact with a base possessing this ability must pass a Morale Test or suffer a -2 AF penalty for the remainder of the turn.

This applies whether the Fear-causing base charges or is itself charged.

Fear has no effect against bases with the Fear or Terror ability.' AS d
    UNION ALL SELECT 'Antigrav' AS n, 'A base with Antigrav may make short flights over terrain, buildings, and enemy troops.

It ignores terrain movement penalties and enemy zones of control except those generated by bases with Floater, Skimmer, Jump Packs, or Antigrav.

While moving over an obstacle it is considered to be at altitude. It cannot end its movement on Impassable terrain.' AS d
    UNION ALL SELECT 'Psychic Save (X+)' AS n, 'A base with Psychic Save (X+) may use this saving throw against psychic powers.' AS d
    UNION ALL SELECT 'Close Defences (X+)' AS n, 'Every Class 1 or 2 base that engages, or is engaged by, a base with Close Defences suffers a hit on X+ with AP 0.

Resolve the attack when the bases make contact. Cover saves may be used against Close Defences.' AS d
    UNION ALL SELECT 'Psychic Attack' AS n, 'A Psychic Attack can only be negated by a Psychic Save.

Wounds lost to a Psychic Attack cannot be recovered using the Regeneration ability. Cover saves cannot be used against this type of power.

If the target has a hit-location chart, the attack always hits its bridge or head location.' AS d
    UNION ALL SELECT 'Anti-Aircraft' AS n, 'These weapons operate independently and may be activated separately from a base''s other weapons.

If the base has a First Fire order, these weapons may perform Overwatch Fire against targets at altitude without suffering the usual To-Hit penalty. They may also perform Overwatch Fire while the base has an Advance order, but suffer the normal -1 To-Hit penalty.

Weapons with this ability always have a 360 degree firing arc and reduce a Flyer''s Protection save by 2.

When firing at targets that are not at altitude, these weapons function normally but suffer a -1 To-Hit penalty.' AS d
    UNION ALL SELECT 'Artillery' AS n, 'Weapons with the Artillery ability fire in a high arc and may shoot without line of sight.

Obstructing terrain crossed by the attack does not provide protection. If the targets are inside the terrain feature, they receive its cover save normally.

Artillery cannot target bases at altitude or perform Overwatch Fire.

Weapons with this ability may perform Indirect Fire against targets the firing base cannot see. To do so, the artillery base must have a First Fire order.

Observed Indirect Fire requires an unpinned allied base with the Forward Observer ability and line of sight to the artillery''s intended target, and suffers a -1 To-Hit penalty.

Unobserved Indirect Fire may be performed without line of sight and without a Forward Observer, but suffers a -2 To-Hit penalty.' AS d
    UNION ALL SELECT 'Battery' AS n, 'Weapons with the Battery ability combine their fire into a single powerful attack.

All bases in the detachment produce a single template. The attack''s To-Hit value depends on the number of bases remaining in the detachment. The To-Hit value shown on the profile applies to the complete detachment.

For each base missing from the detachment, worsen both the attack''s To-Hit value and the AP of its Damages Buildings ability by 1.

Range and line of sight may be measured from any base in the detachment that is able to fire.' AS d
    UNION ALL SELECT 'Template (X)' AS n, 'Templates have an area of effect and may therefore affect more than one target.

Any base whose centre is covered by a template may be hit, depending on the template weapon''s To-Hit roll.

Obstructing terrain crossed by a template attack does not provide protection. However, a target inside such terrain receives its cover save normally.

A template weapon may target bases at altitude if it fulfils the normal requirements. If it does so, it affects only targets at altitude and cannot affect targets at ground level.' AS d
    UNION ALL SELECT 'Bombardment (X)' AS n, 'Flyers and Floating bases at altitude may drop X bombs during their movement. Resolve each attack immediately during the movement, following the normal shooting procedure.

Bombs cannot be dropped while the detachment has a Charge order and cannot affect targets at altitude.

If the weapon uses templates, all its templates must touch one another and are treated as a single template. The templates must be centred on the axis of the bombing base''s movement.' AS d
    UNION ALL SELECT 'Floater' AS n, 'Floaters follow the rules for Heavy Skimmers.

At the beginning of each turn, a Floater may choose to remain at ground level or rise to altitude. It remains at the chosen level for the entire turn.

While at altitude, only bases with Skimmer, Heavy Skimmer, Floater, Flyer, or Jump Packs may engage it in an assault. A Floater may engage other troops without restriction.

If a Floater is at altitude, only bases with Jump Packs or Skimmer may disembark from it. Bases cannot embark while the Floater is at altitude.

Floaters may use their bombs during movement, but only while at altitude.' AS d
    UNION ALL SELECT 'Transport (X)' AS n, 'A base with Transport (X) may transport X Infantry bases.

Entering or leaving a transport costs the transported bases 5 cm of movement. When a base leaves a transport, place it in contact with the transporting base.

A transport with a capacity of 6 or more may transport Walker bases. Each Walker occupies the capacity of two Infantry bases.

Transported bases may disembark even if their transport is engaged in an assault. While a detachment is embarked, Morale Tests use the better Morale value of the transport and transported detachments.' AS d
    UNION ALL SELECT 'Transport (X Termagants)' AS n, 'This transport may only carry Termagant bases. Its capacity is X Termagants. In all other respects it follows the Transport rules.' AS d
    UNION ALL SELECT 'Transport (X Gargoyles)' AS n, 'This transport may only carry Gargoyle bases. Its capacity is X Gargoyles. In all other respects it follows the Transport rules.' AS d
    UNION ALL SELECT 'Transport (Special)' AS n, 'This transport uses special capacity rules instead of a normal Infantry capacity. See the Mycetic Spore ability: each Mycetic Spore may transport one Class 1 or 2 base.' AS d
    UNION ALL SELECT 'Attached Transport' AS n, 'Attached Transports and the bases they transport are treated as a single detachment.

The transports use the Morale value of the detachment to which they are attached.

The transport group and transported group receive separate orders but are activated simultaneously. They have Extended Coherency (25 cm) with one another.

The transported troops may begin the battle either embarked or outside their transports.' AS d
    UNION ALL SELECT 'Leader' AS n, 'All allied detachments with at least one base within 12 cm of a base with this ability receive a +1 bonus to their AF.' AS d
    UNION ALL SELECT 'Dark Presence (-X / Y cm)' AS n, 'Enemy detachments with at least one base within Y cm of a base with this ability suffer a -X modifier to their Morale value.

This effect is not cumulative.' AS d
    UNION ALL SELECT 'Interceptor' AS n, 'A detachment with this ability may perform Aerial Interceptions. See the Flyer rules for further details.' AS d
    UNION ALL SELECT 'Terror' AS n, 'A detachment engaged in an assault by a base with the Terror ability must make a Morale Test with a -1 modifier.

If the test is failed, the detachment immediately receives a Fall Back order but does not make a Fall Back move. Consequently, it cannot perform Overwatch Fire, even if it would otherwise be able to do so.

A detachment attempting to engage a base with Terror must also pass a Morale Test with a -1 modifier. If this test is failed, the attacking bases stop before entering the Terror-causing base''s zone of control.

Bases with the Terror ability are immune to Terror.' AS d
    UNION ALL SELECT 'Wounds (X)' AS n, 'A base with this ability has X Wounds, allowing it to survive multiple injuries.

By default, a base has only one Wound.' AS d
    UNION ALL SELECT 'Character' AS n, 'Characters represent important individuals who distinguish themselves within an army. This ability is relevant in certain scenarios.' AS d
    UNION ALL SELECT 'Psyker' AS n, 'These troops possess special abilities such as sorcery, mutant powers, or technomancy. Details of their powers are provided in the relevant Codex.

During the Combat Phase, a Psyker may use both one psychic power and its conventional weapons.

Powers marked Shooting in their description follow the same rules and restrictions as standard shooting attacks.

A power used during the Movement Phase may be used at any point during the Psyker''s movement activation, even if the Psyker is pinned in an assault.

Unless otherwise stated, psychic powers have a 360 degree firing arc.' AS d
    UNION ALL SELECT 'Forward Observer (FO)' AS n, 'A Forward Observer may observe and direct Indirect Artillery Fire.

Forward Observers are also the only bases capable of calling in Off-Table Artillery attacks.' AS d
    UNION ALL SELECT 'Turret' AS n, 'A weapon with the Turret ability has a 360 degree firing arc.' AS d
    UNION ALL SELECT 'Flame Template' AS n, 'This weapon uses a rangeless flame template.

The template may be placed in any position provided it lies entirely within the weapon''s firing arc. The narrow tip of the template must be placed over the centre of the firing base. The template must also cover at least one valid target.' AS d
    UNION ALL SELECT 'Integral Armour' AS n, 'A base with Integral Armour does not use a hit-location chart. Every hit is resolved against the base as a whole using its armour save.' AS d
    UNION ALL SELECT 'Off-Table Artillery' AS n, 'Off-Table Artillery represents batteries of extremely long-ranged weapons deployed far from the battlefield, including orbital bombardments and naval artillery.

Off-Table Artillery is purchased normally when creating the army list and may only be used once. Different types are listed in the relevant Codex, and the type used is selected when the attack is called.

To call an Off-Table Artillery attack, an unpinned Forward Observer must have line of sight to the targeted point. The attack''s Destruction Points are awarded when it is used.

For the purpose of determining the attack''s direction, Off-Table Artillery is always considered to originate along the axis of the Forward Observer.' AS d
    UNION ALL SELECT 'Agile' AS n, 'A Titan or Praetorian with this ability is not limited to a total of 90 degrees of turning during each turn.' AS d
    UNION ALL SELECT 'Protection (X+)' AS n, 'Protection is a fixed saving throw made before all other saving throws. It may be used in addition to other types of saving throw.

A base cannot benefit from more than one Protection save. If several are available, use the best one.' AS d
    UNION ALL SELECT 'Dodge (X+)' AS n, 'When a base with this ability loses Wounds in an assault, roll one die for each Wound lost. For each result of X+, the base does not lose that Wound.

Dodge may also be used against hits caused by Close Defences.' AS d
    UNION ALL SELECT 'Dread (-X)' AS n, 'When activated during the Combat Phase, a base with this ability may force one enemy detachment with at least one base within 20 cm to make a Morale Test.

The test suffers a modifier of -X. If it is failed, the detachment receives a Fall Back order and immediately makes a Fall Back move.

A detachment cannot be targeted by this ability more than once during the same turn.' AS d
    UNION ALL SELECT 'Psychic Abomination' AS n, 'Any enemy Psyker within 25 cm of a base with this ability may only use a psychic power after rolling 5+ on 1D6.

Daemons within 25 cm are also more unstable and suffer a -1 modifier to their Instability rolls.

Bases with this ability gain a Psychic Save (2+).' AS d
    UNION ALL SELECT 'First Strike (X)' AS n, 'A weapon with this ability may attack a base in contact with it immediately before an assault is resolved.

Resolve the attack after the assault has been selected for activation but before resolving anything else. It is treated as a shooting attack, but its To-Hit roll never suffers penalties and it ignores Shields.

The target may make a normal saving throw. Damage inflicted by First Strike attacks counts towards the final combat result.' AS d
    UNION ALL SELECT 'Damages Buildings (AP -X / Y)' AS n, 'A base with a weapon possessing this ability may attack destructible terrain features.

When using a template weapon, the centre of the template must be positioned over the structure for it to be hit.

The structure must make Y saving throws with an AP modifier of -X. It loses one Wound for each failed save. Saving throws made by structures use the total result of 2D6.' AS d
    UNION ALL SELECT 'Damages Buildings (AP -X / Y) in Assault' AS n, 'A base with a weapon possessing this ability may attack a destructible terrain feature with which it is in contact during the Combat Phase.

If the base is also engaged in an assault against enemy bases, it must choose whether to use the weapon against its opponents or the terrain feature.

In all other respects, this ability functions in the same manner as Damages Buildings.' AS d
    UNION ALL SELECT 'Entangle' AS n, 'When a base with this ability makes contact with an enemy base that has a hit-location chart, it may immobilise one of the enemy base''s weapons. The effects of that weapon are cancelled for the remainder of the turn.

If two opposing bases both possess such weapons, the abilities cancel one another and both weapons become entangled.' AS d
    UNION ALL SELECT 'Fires Twice' AS n, 'A weapon with this ability may fire twice when it shoots.' AS d
    UNION ALL SELECT 'Razor Claws' AS n, 'When using Razor Claws, choose one effect:

 • Shooting with the weapon''s listed profile.
 • Adds 1D6 to AF and Damage (+2) in Assault.
 • Damages Buildings (AP -4 / 3) in Assault.
 • First Strike (1/2+/AP -4) and Damage (+1).' AS d
    UNION ALL SELECT 'Tentacles' AS n, 'When using Tentacles, choose one effect:

 • Shooting: Damage (+1).
 • Entangle and Damage (+1) in Assault.
 • First Strike (1/2+/AP -4) and Damage (+1).' AS d
    UNION ALL SELECT 'Synaptic Beacon' AS n, '[Movement Phase, upon activation]: The Dominatrix extends the range of its Synapse radius to 60 cm for the remainder of the turn. In addition, during the End-of-Turn Effects, detachments acting on Instinct within 60 cm may attempt a Hive Mind Test. If successful, remove their Instinct counters.' AS d
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM SpecialAbility sa WHERE sa.SpecialAbilityName = src.n
);

UPDATE SpecialAbility sa
INNER JOIN (
    SELECT 'Synapse (X)' AS n, 'Detachments with this ability receive orders normally.

They may also control Slave detachments if at least one base from the Slave detachment is within X cm of a Synapse base.

Detachments arriving through the Tunneller or Mycetic Spore rules may receive an order if they are within the Synapse radius of a base when they arrive.

The Synapse radius functions even if the Synapse base or the Slave bases are inside transports.

A Synapse base attached to a detachment grants the Synapse ability to the entire detachment.

A detachment following an Instinct order loses its Synapse ability.' AS d
    UNION ALL SELECT 'Slave (Hunt)' AS n, 'Slave detachments follow their Instinct order if they are outside the Synapse radius of a Synapse base during the Orders step, or if they have failed a Hive Mind Test.

All movement required by an Instinct order is performed normally during the Movement Phase.

Hunt: During the Movement Phase, the detachment moves its normal Movement characteristic towards the closest enemy detachment that is not already engaged in an assault. If it makes contact, it engages that detachment in an assault.

If the detachment is not engaged in an assault, it must shoot at the closest valid enemy detachment during the Combat Phase.

If a detachment following an Instinct order uses a template weapon, centre the template over the closest enemy base.' AS d
    UNION ALL SELECT 'Slave (Devastation)' AS n, 'Slave detachments follow their Instinct order if they are outside the Synapse radius of a Synapse base during the Orders step, or if they have failed a Hive Mind Test.

All movement required by an Instinct order is performed normally during the Movement Phase.

Devastation: During the Movement Phase, the detachment must move twice its normal Movement characteristic towards the closest enemy detachment.

If the closest enemy detachment is already engaged in an assault, the Tyranid detachment may instead move towards the second-closest enemy detachment.

If it makes contact with an enemy, it engages that enemy in an assault. A detachment following the Devastation Instinct never makes ranged attacks.' AS d
    UNION ALL SELECT 'Slave (Nest)' AS n, 'Slave detachments follow their Instinct order if they are outside the Synapse radius of a Synapse base during the Orders step, or if they have failed a Hive Mind Test.

Nest: A detachment with this Instinct does not move. During the Combat Phase, it must shoot at the closest visible enemy detachment.

This is not a First Fire order. The detachment therefore cannot perform Overwatch Fire, reroll results of 1 on its To-Hit rolls, or perform Indirect Fire.

The detachment must shoot at an enemy even if that enemy is engaged in an assault.

If a detachment following an Instinct order uses a template weapon, centre the template over the closest enemy base.' AS d
    UNION ALL SELECT 'Semi-Synaptic' AS n, 'Detachments with this ability may receive orders normally, even while outside a Synapse radius.

If they fail a Hive Mind Test, they act as Slave creatures and follow their listed Instinct.' AS d
    UNION ALL SELECT 'Semi-Synaptic (Hunt)' AS n, 'Detachments with this ability may receive orders normally, even while outside a Synapse radius.

If they fail a Hive Mind Test, they act as Slave creatures and follow the Hunt Instinct.' AS d
    UNION ALL SELECT 'Semi-Synaptic (Devastation)' AS n, 'Detachments with this ability may receive orders normally, even while outside a Synapse radius.

If they fail a Hive Mind Test, they act as Slave creatures and follow the Devastation Instinct.' AS d
    UNION ALL SELECT 'Semi-Synaptic (Nest)' AS n, 'Detachments with this ability may receive orders normally, even while outside a Synapse radius.

If they fail a Hive Mind Test, they act as Slave creatures and follow the Nest Instinct.' AS d
    UNION ALL SELECT 'Synaptic Overload' AS n, 'Once per turn, a base with this ability may cause a detachment within its Synapse radius to automatically pass a Hive Mind Test.

The use of this ability must be declared before making the test.' AS d
    UNION ALL SELECT 'Bio-Toxin' AS n, 'Weapons with this ability cannot inflict damage upon allied Tyranid bases.' AS d
    UNION ALL SELECT 'Subterranean Assault' AS n, 'When a Trygon uses its Deep Strike ability to enter the battlefield, one Hormagaunt swarm may emerge with it.

Place the Hormagaunt detachment within 6 cm of the Trygon''s arrival point. Both detachments are placed on the battlefield simultaneously.' AS d
    UNION ALL SELECT 'Spore Pods' AS n, 'Spore Pods release clouds of toxic particles around the Bio-Titan. A Bio-Titan may purchase no more than one Spore Pod.

During the Combat Phase, every base within 15 cm of the centre of the Bio-Titan is hit:

 • On a 4+ if the Bio-Titan has an Advance or First Fire order.
 • On a 5+ if the Bio-Titan has a Charge or Forced March order.

Spore Pods have AP 0 and possess the Reduces Cover (-3) and Bio-Toxin abilities.

Spore Pods function even if the Bio-Titan is pinned in an assault. In this case, resolve the Spore Pod attacks before resolving the assault. Any damage inflicted counts towards the assault''s combat result.

Spore Pods do not suffer a To-Hit penalty when the Bio-Titan is engaged in an assault.

Spore Pods increase the Bio-Titan''s Close Defences to 4+.' AS d
    UNION ALL SELECT 'Spore-Mine' AS n, 'When an attack is made with a Spore-Mines weapon, it creates a hazardous area in addition to resolving the normal effects of the attack.

Leave the template in the position where the attack was resolved. It remains in play for the turn in which it was fired and for the following turn, after which it is removed.

The area counts as Dangerous Terrain (4+/AP 0) with the Bio-Toxin ability.

The Spore-Mine area may be targeted by shooting attacks. Each successful hit removes one Spore-Mine from the area.' AS d
    UNION ALL SELECT 'Mycetic Spore' AS n, 'Mycetic Spores follow these rules:

 • Spores are divided into groups. Each group consists of one or more detachments that purchased Mycetic Spores.
 • During Off-Table Arrivals, determine the group''s arrival point in the same manner as another off-table arrival. Mycetic Spores are not affected by the Limited Assault rule.
 • The Spores enter during the Movement Phase and may be targeted by Overwatch Fire. For range and line-of-sight purposes, they are considered to be at altitude directly above their arrival point.
 • Make one saving throw for each successful hit and remove destroyed Spores randomly. Troops transported inside Spores destroyed either in flight or on the ground cannot make Emergency Exit Tests.
 • Place all surviving Spores in coherency and within 12 cm of the arrival point. A Spore cannot be placed on an enemy base or within Impassable terrain.
 • The transported troops then disembark according to the normal Transport rules.
 • As soon as a Spore is empty, it is removed and considered destroyed. Empty Spores have no zones of control and cannot contest or secure objectives.
 • Each Mycetic Spore may transport one Class 1 or 2 base.' AS d
    UNION ALL SELECT 'Elite (X)' AS n, 'At the beginning of the battle, your army receives a shared pool of Elite rerolls.

Each detachment containing bases with Elite (X) adds X rerolls to this pool, regardless of how many Elite bases the detachment contains.

During the battle, Elite rerolls may be spent to reroll dice rolled by your Elite bases. Before using them, declare the total number of dice that will be rerolled.

Only one Elite reroll may be used per base for each dice roll. Consequently, only one die from an assault roll may be rerolled.

Used Elite rerolls are removed from the army''s pool.

Elite rerolls may be used for:

 • To-Hit rolls for any type of shooting attack.
 • Armour saving throws.
 • Assault rolls.
 • Dodge rolls.
 • Opportunity attacks made when an enemy disengages.' AS d
    UNION ALL SELECT 'Regeneration (X+)' AS n, 'When a base with Regeneration (X+) would lose one or more Wounds, roll one die for each Wound lost.

For each result equal to or greater than X, the base does not lose that Wound. Regeneration functions against both shooting attacks and assaults.

Regeneration is more difficult during an assault and suffers a -1 modifier.

Only one Regeneration attempt may be made for each Wound lost.

A successful Regeneration roll prevents the loss of the Wound but does not cancel any additional effects caused by the attack, particularly effects applied through a Titan''s hit-location chart.' AS d
    UNION ALL SELECT 'Deep Strike (X)' AS n, 'The controlling player selects a point on the battlefield and places one base from the detachment at that point. The base then scatters X times, moving 3D6 cm for each scatter.

If the final point is outside the battlefield, within Impassable terrain, or within the zone of control of an enemy base of the same or a higher class, the detachment does not arrive. Another attempt may be made during the following turn.

Otherwise, place the first base as close as possible to the final arrival point. Place every other base in the detachment anywhere within 6 cm of the first base.

No base may arrive within Impassable terrain or within the zone of control of an enemy base of the same or a higher class.

A detachment entering the battlefield in this manner cannot receive a First Fire order during the turn in which it arrives. It also loses 5 cm from its total available movement during that turn.

Limited Assault

On the first turn, a Class 3 or higher detachment cannot select an initial arrival point within the opposing player''s half of the battlefield.' AS d
    UNION ALL SELECT 'Damage (+X)' AS n, 'A weapon with this ability inflicts X additional hits against a base successfully hit by the weapon.' AS d
    UNION ALL SELECT 'Damage (+X) in Assault' AS n, 'A weapon with this ability inflicts X additional hits after its base wins a duel, in addition to the normal hit.' AS d
    UNION ALL SELECT 'Reduces Cover (X)' AS n, 'A weapon with this ability worsens the target''s cover save by X.' AS d
    UNION ALL SELECT 'Infiltration' AS n, 'These bases are stealthy and capable of approaching the enemy before the battle begins.

After deployment, bases with this ability may move up to 25 cm. This movement cannot bring a base into an enemy zone of control and cannot be performed while the detachment is being transported.' AS d
    UNION ALL SELECT 'Jump Packs' AS n, 'Bases equipped with Jump Packs may make short flights over terrain, buildings, and enemy troops.

They ignore enemy zones of control except those generated by bases with the Floater, Skimmer, or Jump Packs ability.

They also ignore terrain modifiers during their movement but cannot end their movement on Impassable terrain.

While using this ability to move over an obstacle, the base is considered to be at altitude.' AS d
    UNION ALL SELECT 'Attached Character' AS n, 'At the beginning of the battle, an Attached Character must join a detachment. The character and the detachment are then treated as a single detachment.

The Attached Character must remain in coherency with the detachment, uses its Morale value, and adds its points cost to the detachment''s total cost.

Attached Characters do not occupy space in transports. A single detachment may include up to two Attached Characters.

An Attached Character gains the Movement characteristic of the detachment to which it is attached. It also gains the detachment''s movement-related special abilities, including Infiltration, Free Deployment, Jump Packs, Skimmer, Hard to Hit, Camouflage, and Advanced Camouflage.

An Infantry Attached Character, Class 1, may be attached to an Infantry, Walker, or Cavalry detachment. If attached to a Walker or Cavalry detachment, it gains that detachment''s class. In all other cases, an Attached Character must join a detachment of the same type.' AS d
    UNION ALL SELECT 'HQ' AS n, 'HQ bases represent a small number of important individuals. While they remain close to another base of the same Blocking Class, they receive protection against shooting attacks.

When an HQ base is targeted by a shooting attack, its controlling player may select another base of the same class within 6 cm as the attack''s target instead.

This decision must be made before any saving throws are rolled.

HQ protection does not function during an assault.' AS d
    UNION ALL SELECT 'Advanced Camouflage' AS n, 'Advanced Camouflage functions like Camouflage, with the following addition:

If the terrain occupied by the detachment does not provide a cover save, the detachment receives a 5+ cover save. This becomes a 4+ cover save if the entire detachment has not yet fired and gives up its ability to fire during the current turn.

Camouflage: If a base occupies terrain that provides a cover save, improve that cover save by 1. The cover save may be improved by a further 1 if the entire detachment has not yet fired and gives up its ability to fire during the current turn. Camouflage only functions against enemy bases more than 25 cm away. A base engaged in an assault loses the benefit of Camouflage for the remainder of the turn.' AS d
    UNION ALL SELECT 'Free Deployment' AS n, 'Detachments with this ability may deploy anywhere within their controlling player''s half of the battlefield.

Free Deployment is resolved at the same time as Infiltration movement. Every base deployed in this manner must be placed at least 12 cm from every enemy base.

Once deployed, the detachment may also use its Infiltration ability, if it possesses it.' AS d
    UNION ALL SELECT 'Walker' AS n, 'A base with this ability suffers the same terrain movement penalties as a Walker-class base.' AS d
    UNION ALL SELECT 'Fear' AS n, 'A Class 1-3 detachment that enters base-to-base contact with a base possessing this ability must pass a Morale Test or suffer a -2 AF penalty for the remainder of the turn.

This applies whether the Fear-causing base charges or is itself charged.

Fear has no effect against bases with the Fear or Terror ability.' AS d
    UNION ALL SELECT 'Antigrav' AS n, 'A base with Antigrav may make short flights over terrain, buildings, and enemy troops.

It ignores terrain movement penalties and enemy zones of control except those generated by bases with Floater, Skimmer, Jump Packs, or Antigrav.

While moving over an obstacle it is considered to be at altitude. It cannot end its movement on Impassable terrain.' AS d
    UNION ALL SELECT 'Psychic Save (X+)' AS n, 'A base with Psychic Save (X+) may use this saving throw against psychic powers.' AS d
    UNION ALL SELECT 'Close Defences (X+)' AS n, 'Every Class 1 or 2 base that engages, or is engaged by, a base with Close Defences suffers a hit on X+ with AP 0.

Resolve the attack when the bases make contact. Cover saves may be used against Close Defences.' AS d
    UNION ALL SELECT 'Psychic Attack' AS n, 'A Psychic Attack can only be negated by a Psychic Save.

Wounds lost to a Psychic Attack cannot be recovered using the Regeneration ability. Cover saves cannot be used against this type of power.

If the target has a hit-location chart, the attack always hits its bridge or head location.' AS d
    UNION ALL SELECT 'Anti-Aircraft' AS n, 'These weapons operate independently and may be activated separately from a base''s other weapons.

If the base has a First Fire order, these weapons may perform Overwatch Fire against targets at altitude without suffering the usual To-Hit penalty. They may also perform Overwatch Fire while the base has an Advance order, but suffer the normal -1 To-Hit penalty.

Weapons with this ability always have a 360 degree firing arc and reduce a Flyer''s Protection save by 2.

When firing at targets that are not at altitude, these weapons function normally but suffer a -1 To-Hit penalty.' AS d
    UNION ALL SELECT 'Artillery' AS n, 'Weapons with the Artillery ability fire in a high arc and may shoot without line of sight.

Obstructing terrain crossed by the attack does not provide protection. If the targets are inside the terrain feature, they receive its cover save normally.

Artillery cannot target bases at altitude or perform Overwatch Fire.

Weapons with this ability may perform Indirect Fire against targets the firing base cannot see. To do so, the artillery base must have a First Fire order.

Observed Indirect Fire requires an unpinned allied base with the Forward Observer ability and line of sight to the artillery''s intended target, and suffers a -1 To-Hit penalty.

Unobserved Indirect Fire may be performed without line of sight and without a Forward Observer, but suffers a -2 To-Hit penalty.' AS d
    UNION ALL SELECT 'Battery' AS n, 'Weapons with the Battery ability combine their fire into a single powerful attack.

All bases in the detachment produce a single template. The attack''s To-Hit value depends on the number of bases remaining in the detachment. The To-Hit value shown on the profile applies to the complete detachment.

For each base missing from the detachment, worsen both the attack''s To-Hit value and the AP of its Damages Buildings ability by 1.

Range and line of sight may be measured from any base in the detachment that is able to fire.' AS d
    UNION ALL SELECT 'Template (X)' AS n, 'Templates have an area of effect and may therefore affect more than one target.

Any base whose centre is covered by a template may be hit, depending on the template weapon''s To-Hit roll.

Obstructing terrain crossed by a template attack does not provide protection. However, a target inside such terrain receives its cover save normally.

A template weapon may target bases at altitude if it fulfils the normal requirements. If it does so, it affects only targets at altitude and cannot affect targets at ground level.' AS d
    UNION ALL SELECT 'Bombardment (X)' AS n, 'Flyers and Floating bases at altitude may drop X bombs during their movement. Resolve each attack immediately during the movement, following the normal shooting procedure.

Bombs cannot be dropped while the detachment has a Charge order and cannot affect targets at altitude.

If the weapon uses templates, all its templates must touch one another and are treated as a single template. The templates must be centred on the axis of the bombing base''s movement.' AS d
    UNION ALL SELECT 'Floater' AS n, 'Floaters follow the rules for Heavy Skimmers.

At the beginning of each turn, a Floater may choose to remain at ground level or rise to altitude. It remains at the chosen level for the entire turn.

While at altitude, only bases with Skimmer, Heavy Skimmer, Floater, Flyer, or Jump Packs may engage it in an assault. A Floater may engage other troops without restriction.

If a Floater is at altitude, only bases with Jump Packs or Skimmer may disembark from it. Bases cannot embark while the Floater is at altitude.

Floaters may use their bombs during movement, but only while at altitude.' AS d
    UNION ALL SELECT 'Transport (X)' AS n, 'A base with Transport (X) may transport X Infantry bases.

Entering or leaving a transport costs the transported bases 5 cm of movement. When a base leaves a transport, place it in contact with the transporting base.

A transport with a capacity of 6 or more may transport Walker bases. Each Walker occupies the capacity of two Infantry bases.

Transported bases may disembark even if their transport is engaged in an assault. While a detachment is embarked, Morale Tests use the better Morale value of the transport and transported detachments.' AS d
    UNION ALL SELECT 'Transport (X Termagants)' AS n, 'This transport may only carry Termagant bases. Its capacity is X Termagants. In all other respects it follows the Transport rules.' AS d
    UNION ALL SELECT 'Transport (X Gargoyles)' AS n, 'This transport may only carry Gargoyle bases. Its capacity is X Gargoyles. In all other respects it follows the Transport rules.' AS d
    UNION ALL SELECT 'Transport (Special)' AS n, 'This transport uses special capacity rules instead of a normal Infantry capacity. See the Mycetic Spore ability: each Mycetic Spore may transport one Class 1 or 2 base.' AS d
    UNION ALL SELECT 'Attached Transport' AS n, 'Attached Transports and the bases they transport are treated as a single detachment.

The transports use the Morale value of the detachment to which they are attached.

The transport group and transported group receive separate orders but are activated simultaneously. They have Extended Coherency (25 cm) with one another.

The transported troops may begin the battle either embarked or outside their transports.' AS d
    UNION ALL SELECT 'Leader' AS n, 'All allied detachments with at least one base within 12 cm of a base with this ability receive a +1 bonus to their AF.' AS d
    UNION ALL SELECT 'Dark Presence (-X / Y cm)' AS n, 'Enemy detachments with at least one base within Y cm of a base with this ability suffer a -X modifier to their Morale value.

This effect is not cumulative.' AS d
    UNION ALL SELECT 'Interceptor' AS n, 'A detachment with this ability may perform Aerial Interceptions. See the Flyer rules for further details.' AS d
    UNION ALL SELECT 'Terror' AS n, 'A detachment engaged in an assault by a base with the Terror ability must make a Morale Test with a -1 modifier.

If the test is failed, the detachment immediately receives a Fall Back order but does not make a Fall Back move. Consequently, it cannot perform Overwatch Fire, even if it would otherwise be able to do so.

A detachment attempting to engage a base with Terror must also pass a Morale Test with a -1 modifier. If this test is failed, the attacking bases stop before entering the Terror-causing base''s zone of control.

Bases with the Terror ability are immune to Terror.' AS d
    UNION ALL SELECT 'Wounds (X)' AS n, 'A base with this ability has X Wounds, allowing it to survive multiple injuries.

By default, a base has only one Wound.' AS d
    UNION ALL SELECT 'Character' AS n, 'Characters represent important individuals who distinguish themselves within an army. This ability is relevant in certain scenarios.' AS d
    UNION ALL SELECT 'Psyker' AS n, 'These troops possess special abilities such as sorcery, mutant powers, or technomancy. Details of their powers are provided in the relevant Codex.

During the Combat Phase, a Psyker may use both one psychic power and its conventional weapons.

Powers marked Shooting in their description follow the same rules and restrictions as standard shooting attacks.

A power used during the Movement Phase may be used at any point during the Psyker''s movement activation, even if the Psyker is pinned in an assault.

Unless otherwise stated, psychic powers have a 360 degree firing arc.' AS d
    UNION ALL SELECT 'Forward Observer (FO)' AS n, 'A Forward Observer may observe and direct Indirect Artillery Fire.

Forward Observers are also the only bases capable of calling in Off-Table Artillery attacks.' AS d
    UNION ALL SELECT 'Turret' AS n, 'A weapon with the Turret ability has a 360 degree firing arc.' AS d
    UNION ALL SELECT 'Flame Template' AS n, 'This weapon uses a rangeless flame template.

The template may be placed in any position provided it lies entirely within the weapon''s firing arc. The narrow tip of the template must be placed over the centre of the firing base. The template must also cover at least one valid target.' AS d
    UNION ALL SELECT 'Integral Armour' AS n, 'A base with Integral Armour does not use a hit-location chart. Every hit is resolved against the base as a whole using its armour save.' AS d
    UNION ALL SELECT 'Off-Table Artillery' AS n, 'Off-Table Artillery represents batteries of extremely long-ranged weapons deployed far from the battlefield, including orbital bombardments and naval artillery.

Off-Table Artillery is purchased normally when creating the army list and may only be used once. Different types are listed in the relevant Codex, and the type used is selected when the attack is called.

To call an Off-Table Artillery attack, an unpinned Forward Observer must have line of sight to the targeted point. The attack''s Destruction Points are awarded when it is used.

For the purpose of determining the attack''s direction, Off-Table Artillery is always considered to originate along the axis of the Forward Observer.' AS d
    UNION ALL SELECT 'Agile' AS n, 'A Titan or Praetorian with this ability is not limited to a total of 90 degrees of turning during each turn.' AS d
    UNION ALL SELECT 'Protection (X+)' AS n, 'Protection is a fixed saving throw made before all other saving throws. It may be used in addition to other types of saving throw.

A base cannot benefit from more than one Protection save. If several are available, use the best one.' AS d
    UNION ALL SELECT 'Dodge (X+)' AS n, 'When a base with this ability loses Wounds in an assault, roll one die for each Wound lost. For each result of X+, the base does not lose that Wound.

Dodge may also be used against hits caused by Close Defences.' AS d
    UNION ALL SELECT 'Dread (-X)' AS n, 'When activated during the Combat Phase, a base with this ability may force one enemy detachment with at least one base within 20 cm to make a Morale Test.

The test suffers a modifier of -X. If it is failed, the detachment receives a Fall Back order and immediately makes a Fall Back move.

A detachment cannot be targeted by this ability more than once during the same turn.' AS d
    UNION ALL SELECT 'Psychic Abomination' AS n, 'Any enemy Psyker within 25 cm of a base with this ability may only use a psychic power after rolling 5+ on 1D6.

Daemons within 25 cm are also more unstable and suffer a -1 modifier to their Instability rolls.

Bases with this ability gain a Psychic Save (2+).' AS d
    UNION ALL SELECT 'First Strike (X)' AS n, 'A weapon with this ability may attack a base in contact with it immediately before an assault is resolved.

Resolve the attack after the assault has been selected for activation but before resolving anything else. It is treated as a shooting attack, but its To-Hit roll never suffers penalties and it ignores Shields.

The target may make a normal saving throw. Damage inflicted by First Strike attacks counts towards the final combat result.' AS d
    UNION ALL SELECT 'Damages Buildings (AP -X / Y)' AS n, 'A base with a weapon possessing this ability may attack destructible terrain features.

When using a template weapon, the centre of the template must be positioned over the structure for it to be hit.

The structure must make Y saving throws with an AP modifier of -X. It loses one Wound for each failed save. Saving throws made by structures use the total result of 2D6.' AS d
    UNION ALL SELECT 'Damages Buildings (AP -X / Y) in Assault' AS n, 'A base with a weapon possessing this ability may attack a destructible terrain feature with which it is in contact during the Combat Phase.

If the base is also engaged in an assault against enemy bases, it must choose whether to use the weapon against its opponents or the terrain feature.

In all other respects, this ability functions in the same manner as Damages Buildings.' AS d
    UNION ALL SELECT 'Entangle' AS n, 'When a base with this ability makes contact with an enemy base that has a hit-location chart, it may immobilise one of the enemy base''s weapons. The effects of that weapon are cancelled for the remainder of the turn.

If two opposing bases both possess such weapons, the abilities cancel one another and both weapons become entangled.' AS d
    UNION ALL SELECT 'Fires Twice' AS n, 'A weapon with this ability may fire twice when it shoots.' AS d
    UNION ALL SELECT 'Razor Claws' AS n, 'When using Razor Claws, choose one effect:

 • Shooting with the weapon''s listed profile.
 • Adds 1D6 to AF and Damage (+2) in Assault.
 • Damages Buildings (AP -4 / 3) in Assault.
 • First Strike (1/2+/AP -4) and Damage (+1).' AS d
    UNION ALL SELECT 'Tentacles' AS n, 'When using Tentacles, choose one effect:

 • Shooting: Damage (+1).
 • Entangle and Damage (+1) in Assault.
 • First Strike (1/2+/AP -4) and Damage (+1).' AS d
    UNION ALL SELECT 'Synaptic Beacon' AS n, '[Movement Phase, upon activation]: The Dominatrix extends the range of its Synapse radius to 60 cm for the remainder of the turn. In addition, during the End-of-Turn Effects, detachments acting on Instinct within 60 cm may attempt a Hive Mind Test. If successful, remove their Instinct counters.' AS d
) AS src ON src.n = sa.SpecialAbilityName
SET sa.Description = src.d;

INSERT INTO PsychicPower (PsychicPowerName, Description)
SELECT n, d FROM (
    SELECT 'Bio-Resistance' AS n, '[Movement Phase, upon activation]: The Norn Queen improves its Regeneration by 1 and gains Dodge (5+) for the remainder of the turn.' AS d
    UNION ALL SELECT 'Psychic Scream' AS n, '[Movement Phase, upon activation]: The Norn Queen gains the Dread (-1) and Psychic Abomination abilities for the remainder of the turn.' AS d
    UNION ALL SELECT 'Psychic Projectile' AS n, '[Combat Phase, Shooting]: Choose a target within 45 cm and in the Norn Queen''s Line of Sight. The target is hit on a 4+. This is a Psychic Power.' AS d
    UNION ALL SELECT 'Warp Field' AS n, '[Movement Phase, upon activation]: The Dominatrix gains Protection (4+) for the remainder of the turn.' AS d
    UNION ALL SELECT 'Energy Torrent' AS n, '[Combat Phase, Shooting]: The Dominatrix focuses its psychic energy to destroy the enemy. Choose one of the two firing modes when it is activated.

Energy Torrent -- Focused: 90 cm, 1 die, 3+, AP -4, 1D3 Hits.

Energy Torrent -- Diffuse: 90 cm, Template, 3+, AP -1, Template (7.5 cm), Reduces Cover (-1).' AS d
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM PsychicPower pp WHERE pp.PsychicPowerName = src.n
);

UPDATE PsychicPower pp
INNER JOIN (
    SELECT 'Bio-Resistance' AS n, '[Movement Phase, upon activation]: The Norn Queen improves its Regeneration by 1 and gains Dodge (5+) for the remainder of the turn.' AS d
    UNION ALL SELECT 'Psychic Scream' AS n, '[Movement Phase, upon activation]: The Norn Queen gains the Dread (-1) and Psychic Abomination abilities for the remainder of the turn.' AS d
    UNION ALL SELECT 'Psychic Projectile' AS n, '[Combat Phase, Shooting]: Choose a target within 45 cm and in the Norn Queen''s Line of Sight. The target is hit on a 4+. This is a Psychic Power.' AS d
    UNION ALL SELECT 'Warp Field' AS n, '[Movement Phase, upon activation]: The Dominatrix gains Protection (4+) for the remainder of the turn.' AS d
    UNION ALL SELECT 'Energy Torrent' AS n, '[Combat Phase, Shooting]: The Dominatrix focuses its psychic energy to destroy the enemy. Choose one of the two firing modes when it is activated.

Energy Torrent -- Focused: 90 cm, 1 die, 3+, AP -4, 1D3 Hits.

Energy Torrent -- Diffuse: 90 cm, Template, 3+, AP -1, Template (7.5 cm), Reduces Cover (-1).' AS d
) AS src ON src.n = pp.PsychicPowerName
SET pp.Description = src.d;

INSERT INTO SpecialRule (CodexId, SpecialRuleName, Description)
SELECT @codexId, n, d FROM (
    SELECT 'Army Creation' AS n, 'Tyranids select their troops differently from other armies and do not follow the standard army-building rules. Instead, detachments of Synapse creatures generate Command Points, while other formations consume them.

Before another Synapse Formation may be selected, all Command Points generated by the previously selected Synapse Formations must have been spent.

Tyranid Titans are relatively rare. The army may include no more than one Tyranid Titan for every 5 Command Points generated.' AS d
    UNION ALL SELECT 'Morale' AS n, 'Tyranids are not affected by morale in the same manner as other armies and never make Morale Tests.

Their Morale value instead represents their connection to the Hive Mind. When a Tyranid detachment becomes Broken, it must make a Hive Mind Test. This test is resolved in the same manner as a Morale Test.

If the test is failed, the detachment follows its Instinct, as described by its Slave ability, and receives an Instinct counter. If the test is passed, there are no further consequences.

A detachment activated while it has an Instinct counter automatically removes the counter after completing its activation.

A detachment with an Instinct counter suffers a -1 AF penalty to represent its disorganisation.' AS d
    UNION ALL SELECT 'Adaptations' AS n, 'Tyranids excel at adapting to their opponents. To represent this, after seeing the opposing player''s army list but before the battle begins, the Tyranid player selects adaptations.

Every Tyranid army has 10 points to spend on adaptations from the following list:

Bio-Acid (7 points): For every complete 2,000 points in the army, one attack die from one weapon may gain Damage (+1) and improve its AP by 1. The use of this effect must be declared before making the To-Hit roll.

Bio-Targeting (7 points): Every unit in the army may reroll results of 1 on its ranged To-Hit rolls.

Endless Swarm (7 points): During the End-of-Turn Effects step, each Hormagaunt, Gargoyle, Ripper, Termagant, or Barbgaunt detachment recovers 1D3 previously lost bases. The recovered bases must be placed in coherency with their detachment and outside all enemy zones of control.

Velocity (7 points): Increase the total movement of every base in the army by 5 cm. Apply this bonus after doubling or tripling the base''s movement according to its order.

Camouflage (5 points): Class 1 and 2 bases gain a 10 cm Infiltration move. If they already possess an Infiltration move, increase it by 10 cm.

Carapace (5 points): For every complete 1,000 points in the army, the controlling player may reroll one saving throw per turn. This effect may only be used once per detachment during a given turn.

Assault Expert (5 points): Every base in the army may reroll results of 1 on its assault dice.

Psychic Scream (5 points): Every enemy detachment with at least one base within a Synapse radius suffers a -1 penalty to its Morale value.

Shadow in the Warp (4 points): Before deployment, for every complete 2,000 points in the army, one Synapse creature may be given the Dread (-1) ability.

Acidic Entrails (3 points): If a Tyranid base loses an assault duel after rolling at least one double on its assault dice, it inflicts one AP 0 hit against the base that defeated it.

Overwhelming Swarm (3 points): Each outnumbering bonus adds 1D6+1 to AF instead of 1D6.

Subterranean Surge (2 points): When entering the battlefield, a Trygon may bring two Hormagaunt swarms with it instead of one.

Enhanced Synaptic Link (2 points): Increase the Synapse radius of every Synapse creature by 10 cm.

Synaptic Nodes (2 points): For every complete 3,000 points in the army, the Slave ability of one detachment may be replaced with Synapse (10 cm).

Bio-Synaptic Instinct (1 point): For every complete 2,000 points in the army, the Slave ability of one detachment may be replaced with Semi-Synaptic. The Semi-Synaptic creature retains the same Instinct as the original creature.

Adrenaline Surge (1 point): For every complete 2,000 points in the army, increase the AF of one detachment by 1.' AS d
    UNION ALL SELECT 'Tyranid Titan Hit Location Chart' AS n, '### Alpha Hierodule / Hierophant Titan

| D6 | Front/Rear Location |
| --- | --- |
| 1–2 | Legs |
| 3 | Weapon |
| 4 | Head (front) / Abdomen (rear) |
| 5 | Abdomen |
| 6 | Player''s choice |' AS d
    UNION ALL SELECT 'Tyranid Titan Damage Effects' AS n, '### Body

| Result | Effect |
| --- | --- |
| 1 | 1 additional point of damage |
| 2 | 1 additional point of damage; reduce Regeneration by 1 |
| 3+ | 2 additional points of damage |

### Weapon

| Result | Effect |
| --- | --- |
| 1 | Weapon damaged (Repair on 4+) |
| 2 | Weapon destroyed |
| 3+ | Damage to the Body |

### Leg

| Result | Effect |
| --- | --- |
| 1 | -- |
| 2 | Reduce the Titan''s base Movement by 5 cm (Repair on 4+). From this damage onward, the Titan falls if it is destroyed. |
| 3 | Reduce the Titan''s base Movement by an additional 5 cm (Repair on 4+) |
| 4 | Immobilised; 1 additional point of damage |
| 5+ | Damage to the Body |

### Head

| Result | Effect |
| --- | --- |
| 1 | -1D6 to AF (Repair on 4+) |
| 2 | May only receive an order on a 4+ (Repair on 4+); 1 additional point of damage |
| 3+ | Damage to the Body |

### Abdomen

| Result | Effect |
| --- | --- |
| 1 | -1 AF; lose 1D3 transported bases |
| 2 | -1 AF; 1 additional point of damage; lose 1D3 transported bases |
| 3+ | -1 AF; damage to the Body; reduce Regeneration by 1; lose all transported bases |' AS d
) AS src;

-- Figure PNGs are stored in Base.Image; run upload_base_images.py after this seed.
INSERT INTO `Base` (
    CodexId, BaseName, DestructionPoints,
    Morale, `Class`, Movement, `Save`, FA, NumberOfTitanWeapons
) VALUES
    (@codexId, 'Barbgaunt', 0, '6', 1, '10', '--', '+0', 0),
    (@codexId, 'Hive Guard', 0, '6', 1, '10', '4+', '+2', 0),
    (@codexId, 'Gargoyles', 0, '6', 1, '15', '--', '+1', 0),
    (@codexId, 'Alpha Genestealer', 0, 'Attached', 1, '15', '5+f', '+8', 0),
    (@codexId, 'Genestealers', 0, '5', 1, '15', '--', '+6', 0),
    (@codexId, 'Tyranid Warriors', 0, '--', 1, '10', '4+', '+5', 0),
    (@codexId, 'Hormagaunts', 0, '6', 1, '15', '--', '+2', 0),
    (@codexId, 'Lictor', 0, '5', 1, '15', '5+', '+5', 0),
    (@codexId, 'Termagants', 0, '6', 1, '15', '--', '+1', 0),
    (@codexId, 'Rippers', 0, '6', 1, '10', '--', '-1', 0),
    (@codexId, 'Raveners', 0, '6', 2, '20', '6+f', '+4', 0),
    (@codexId, 'Carnifex', 0, '6', 2, '15', '3+', '+6', 0),
    (@codexId, 'Winged Hive Tyrant', 0, '--', 2, '25', '3+', '+7', 0),
    (@codexId, 'Hive Tyrant', 0, '--', 2, '15', '3+', '+6', 0),
    (@codexId, 'Venomthrope', 0, '6', 2, '15', '4+', '+4', 0),
    (@codexId, 'Zoanthrope', 0, '5', 2, '10', '5+', '+1', 0),
    (@codexId, 'Biovore', 0, '6', 3, '15', '4+', '+0', 0),
    (@codexId, 'Dactylis', 0, '6', 3, '15', '3+', '+1', 0),
    (@codexId, 'Exocrine', 0, '6', 3, '15', '3+', '+1', 0),
    (@codexId, 'Harpy', 0, '5', 3, '25', '3+', '+4', 0),
    (@codexId, 'Haruspex', 0, '6', 3, '20', '2+', '+7', 0),
    (@codexId, 'Malefactor', 0, 'Attached', 3, '20', '2+', '+5', 0),
    (@codexId, 'Neurotyrant', 0, '--', 3, '20', '3+', '+2', 0),
    (@codexId, 'Pyrovore', 0, '6', 3, '15', '4+', '+0', 0),
    (@codexId, 'Mycetic Spore', 0, '--', 3, '0', '3+', '+0', 0),
    (@codexId, 'Tervigon', 0, 'Attached', 3, '20', '2+', '+5', 0),
    (@codexId, 'Toxicrene', 0, '6', 3, '20', '2+', '+5', 0),
    (@codexId, 'Virago', 0, '5', 3, '25', '3+', '+6', 0),
    (@codexId, 'Barbed Hierodule', 0, '5', 4, '20', '2+', '+10', 0),
    (@codexId, 'Scythed Hierodule', 0, '5', 4, '20', '2+', '+12', 0),
    (@codexId, 'Razorfex', 0, '5', 4, '20', '2+', '+9', 0),
    (@codexId, 'Norn Queen', 0, '--', 4, '15', '2+', '+10', 0),
    (@codexId, 'Dominatrix', 0, '--', 4, '15', '2+', '+10', 0),
    (@codexId, 'Harridan', 0, '--', 4, '20', '2+', '+5', 0),
    (@codexId, 'Trygon', 0, '--', 4, '15', '2+', '+7', 0),
    (@codexId, 'Assault Tyrannofex', 0, '7', 4, '20', '2+', '+8', 0),
    (@codexId, 'Support Tyrannofex', 0, '7', 4, '15', '2+', '+5', 0),
    (@codexId, 'Alpha Hierodule', 0, '--', 5, '25', '2+ Chart', '+13', 2),
    (@codexId, 'Hierophant', 0, '--', 6, '25', '2+ Chart', '+17', 3),
    (@codexId, 'Bio-Plasma Shot', 0, '--', 0, '--', '--', '--', 0),
    (@codexId, 'Spore-Mine Shot', 0, '--', 0, '--', '--', '--', 0);

SET @barbgaunt := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Barbgaunt');
SET @hiveGuard := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Hive Guard');
SET @gargoyles := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Gargoyles');
SET @alphaGenestealer := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Alpha Genestealer');
SET @genestealers := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Genestealers');
SET @tyranidWarriors := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Tyranid Warriors');
SET @hormagaunts := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Hormagaunts');
SET @lictor := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Lictor');
SET @termagants := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Termagants');
SET @rippers := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Rippers');
SET @raveners := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Raveners');
SET @carnifex := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Carnifex');
SET @wingedHiveTyrant := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Winged Hive Tyrant');
SET @hiveTyrant := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Hive Tyrant');
SET @venomthrope := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Venomthrope');
SET @zoanthrope := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Zoanthrope');
SET @biovore := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Biovore');
SET @dactylis := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Dactylis');
SET @exocrine := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Exocrine');
SET @harpy := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Harpy');
SET @haruspex := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Haruspex');
SET @malefactor := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Malefactor');
SET @neurotyrant := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Neurotyrant');
SET @pyrovore := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Pyrovore');
SET @myceticSpore := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Mycetic Spore');
SET @tervigon := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Tervigon');
SET @toxicrene := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Toxicrene');
SET @virago := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Virago');
SET @barbedHierodule := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Barbed Hierodule');
SET @scythedHierodule := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Scythed Hierodule');
SET @razorfex := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Razorfex');
SET @nornQueen := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Norn Queen');
SET @dominatrix := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Dominatrix');
SET @harridan := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Harridan');
SET @trygon := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Trygon');
SET @assaultTyrannofex := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Assault Tyrannofex');
SET @supportTyrannofex := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Support Tyrannofex');
SET @alphaHierodule := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Alpha Hierodule');
SET @hierophant := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Hierophant');
SET @bioPlasmaShot := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Bio-Plasma Shot');
SET @sporeMineShot := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Spore-Mine Shot');

INSERT INTO Weapon (
    BaseId, `Name`, `Range`, Dice, ToHit, ArmourPenetration, IsTitanWeapon
) VALUES
    (@barbgaunt, 'Barbed Cannon', '45 cm', '1', '4+', '0', 0),
    (@hiveGuard, 'Impaler Cannon', '45 cm', '1', '4+', '-2', 0),
    (@gargoyles, 'Flame Jet', '20 cm', '1', '5+', '0', 0),
    (@alphaGenestealer, 'Claws and Pincers', '--', '--', '--', '--', 0),
    (@genestealers, 'Claws and Pincers', '--', '--', '--', '--', 0),
    (@tyranidWarriors, 'Deathspitter', '45 cm', '1', '4+', '-1', 0),
    (@hormagaunts, 'Claws', '--', '--', '--', '--', 0),
    (@lictor, 'Hooks', '20 cm', '2', '5+', '0', 0),
    (@termagants, 'Fleshborer', '30 cm', '1', '5+', '0', 0),
    (@rippers, 'Claws', '--', '--', '--', '--', 0),
    (@raveners, 'Devourer', '20 cm', '2', '5+', '-1', 0),
    (@carnifex, 'Bio-Plasma', '30 cm', '1', '4+', '-2', 0),
    (@wingedHiveTyrant, 'Devourer', '20 cm', '2', '5+', '-1', 0),
    (@hiveTyrant, 'Heavy Venom Cannon', '45 cm', '2', '4+', '-1', 0),
    (@venomthrope, 'Spore Nest', '--', '--', '--', '--', 0),
    (@zoanthrope, 'Warp Blast', '60 cm', '1', '4+', 'Psy', 0),
    (@biovore, 'Spore-Mines', '90 cm', 'Template', '4+', '-1', 0),
    (@dactylis, 'Bile Pods -- Spores', '90 cm', '2', '3+', '0', 0),
    (@dactylis, 'Bile Pods -- Bio-Acid', '90 cm', '2', '4+', '-2', 0),
    (@exocrine, 'Bio-Plasma Cannon', '75 cm', '2', '4+', '-3', 0),
    (@harpy, 'Venom Cannon', '30 cm', '2', '4+', '-1', 0),
    (@harpy, 'Spore-Mines', 'Bomb', 'Template', '4+', '0', 0),
    (@haruspex, 'Hooks', '20 cm', '2', '5+', '0', 0),
    (@malefactor, 'Fragmentation Spines', '20 cm', '2', '5+', '0', 0),
    (@neurotyrant, 'Energy Torrent', '20 cm', '2', '4+', '0', 0),
    (@pyrovore, 'Bio-Flame Lance Cannon', '30 cm', '2', '3+', '0', 0),
    (@tervigon, 'Fragmentation Spines', '20 cm', '2', '5+', '0', 0),
    (@toxicrene, 'Spore Nest', '--', '--', '--', '--', 0),
    (@virago, 'Salivary Cannon', '20 cm', '2', '4+', '0', 0),
    (@barbedHierodule, 'Bio-Cannons', '75 cm', '2', '3+', '-3', 0),
    (@barbedHierodule, 'Fragmentation Spines', '20 cm', '5', '5+', '0', 0),
    (@scythedHierodule, 'Pyro-Acid Jet', '0 cm', 'Template', '4+', '-1', 0),
    (@razorfex, 'Bio-Plasma', '30 cm', '1', '3+', '-2', 0),
    (@nornQueen, 'Venom Cannon', '45 cm', '2', '4+', '-2', 0),
    (@dominatrix, 'Bio-Plasma Cannons', '75 cm', '4', '4+', '-3', 0),
    (@dominatrix, 'Energy Torrent -- Focused', '90 cm', '1', '3+', '-4', 0),
    (@dominatrix, 'Energy Torrent -- Diffuse', '90 cm', 'Template', '3+', '-1', 0),
    (@harridan, 'Bio-Cannon', '45 cm', '3', '4+', '-2', 0),
    (@harridan, 'Spore Cloud', 'Bomb', 'Template', '2+', '0', 0),
    (@trygon, 'Bio-Shock', '20 cm', '3', '3+', '-2', 0),
    (@trygon, 'Lightning', 'Assault', '1D3', '3+', '-1', 0),
    (@assaultTyrannofex, 'Spore Cloud', '--', '--', '--', '--', 0),
    (@supportTyrannofex, 'Bio-Plasma Cannon', '60 cm', '2', '4+', '-3', 0),
    (@supportTyrannofex, 'Fragmentation Spines', '20 cm', '5', '5+', '0', 0),
    (@alphaHierodule, 'Fragmentation Spines', '20 cm', '2', '4+', '0', 0),
    (@alphaHierodule, 'Bio-Cannon', '75 cm', '2', '4+', '-3', 1),
    (@alphaHierodule, 'Spore Pods', '0 cm', 'Template', '4+', '0', 1),
    (@alphaHierodule, 'Bile Spitter -- Focused', '60 cm', '3', '3+', '-2', 1),
    (@alphaHierodule, 'Bile Spitter -- Diffuse', '60 cm', 'Template', '4+', '0', 1),
    (@alphaHierodule, 'Spine Clusters', '30 cm', 'Template', '3+', '-2', 1),
    (@alphaHierodule, 'Pyro-Acid Jet', '0 cm', 'Template', '4+', '-1', 1),
    (@alphaHierodule, 'Razor Claws', '45 cm', '5', '4+', '0', 1),
    (@alphaHierodule, 'Dart Salvo', '45 cm', '6', '4+', '-1', 1),
    (@alphaHierodule, 'Tentacles', '20 cm', '1', '2+', '-4', 1),
    (@hierophant, 'Fragmentation Spines', '20 cm', '3', '4+', '0', 0),
    (@hierophant, 'Bio-Cannon', '75 cm', '2', '4+', '-3', 1),
    (@hierophant, 'Spore Pods', '0 cm', 'Template', '4+', '0', 1),
    (@hierophant, 'Bile Spitter -- Focused', '60 cm', '3', '3+', '-2', 1),
    (@hierophant, 'Bile Spitter -- Diffuse', '60 cm', 'Template', '4+', '0', 1),
    (@hierophant, 'Spine Clusters', '30 cm', 'Template', '3+', '-2', 1),
    (@hierophant, 'Pyro-Acid Jet', '0 cm', 'Template', '4+', '-1', 1),
    (@hierophant, 'Razor Claws', '45 cm', '5', '4+', '0', 1),
    (@hierophant, 'Dart Salvo', '45 cm', '6', '4+', '-1', 1),
    (@hierophant, 'Tentacles', '20 cm', '1', '2+', '-4', 1),
    (@bioPlasmaShot, 'Bio-Plasma', '--', 'Template', '3+', '-2', 0),
    (@sporeMineShot, 'Spore-Mines', '--', 'Template', '4+', '-1', 0);

INSERT INTO BaseSpecialAbility (BaseId, SpecialAbilityId, AbilityValue)
SELECT b.BaseId, sa.SpecialAbilityId, b.AbilityValue
FROM (
    SELECT @barbgaunt AS BaseId, 'Slave (Nest)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hiveGuard AS BaseId, 'Slave (Nest)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @gargoyles AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @gargoyles AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @gargoyles AS BaseId, 'Slave (Hunt)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaGenestealer AS BaseId, 'Synapse (X)' AS AbilityName, '15 cm' AS AbilityValue
    UNION ALL SELECT @alphaGenestealer AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaGenestealer AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaGenestealer AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaGenestealer AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @alphaGenestealer AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @genestealers AS BaseId, 'Semi-Synaptic (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @genestealers AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @genestealers AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @tyranidWarriors AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tyranidWarriors AS BaseId, 'Synapse (X)' AS AbilityName, '20 cm' AS AbilityValue
    UNION ALL SELECT @tyranidWarriors AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @tyranidWarriors AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @hormagaunts AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @lictor AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @lictor AS BaseId, 'Semi-Synaptic (Hunt)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @lictor AS BaseId, 'Advanced Camouflage' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @termagants AS BaseId, 'Slave (Hunt)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @rippers AS BaseId, 'Free Deployment' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @rippers AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @raveners AS BaseId, 'Deep Strike (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @raveners AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @raveners AS BaseId, 'Walker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @carnifex AS BaseId, 'Fear' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @carnifex AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @carnifex AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @carnifex AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @wingedHiveTyrant AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @wingedHiveTyrant AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @wingedHiveTyrant AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @wingedHiveTyrant AS BaseId, 'Fear' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @wingedHiveTyrant AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @wingedHiveTyrant AS BaseId, 'Synapse (X)' AS AbilityName, '20 cm' AS AbilityValue
    UNION ALL SELECT @wingedHiveTyrant AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @wingedHiveTyrant AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @hiveTyrant AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hiveTyrant AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @hiveTyrant AS BaseId, 'Fear' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hiveTyrant AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @hiveTyrant AS BaseId, 'Synapse (X)' AS AbilityName, '20 cm' AS AbilityValue
    UNION ALL SELECT @hiveTyrant AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @venomthrope AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @venomthrope AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @zoanthrope AS BaseId, 'Semi-Synaptic (Nest)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @zoanthrope AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @zoanthrope AS BaseId, 'Protection (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @biovore AS BaseId, 'Slave (Nest)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @biovore AS BaseId, 'Walker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dactylis AS BaseId, 'Slave (Nest)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dactylis AS BaseId, 'Walker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @exocrine AS BaseId, 'Slave (Nest)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @exocrine AS BaseId, 'Walker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harpy AS BaseId, 'Floater' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harpy AS BaseId, 'Semi-Synaptic (Hunt)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @haruspex AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @haruspex AS BaseId, 'Walker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @malefactor AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @malefactor AS BaseId, 'Transport (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @malefactor AS BaseId, 'Attached Transport' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @malefactor AS BaseId, 'Walker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @neurotyrant AS BaseId, 'Leader' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @neurotyrant AS BaseId, 'Synapse (X)' AS AbilityName, '30 cm' AS AbilityValue
    UNION ALL SELECT @neurotyrant AS BaseId, 'Dark Presence (-X / Y cm)' AS AbilityName, '1, 12' AS AbilityValue
    UNION ALL SELECT @neurotyrant AS BaseId, 'Walker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pyrovore AS BaseId, 'Slave (Nest)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pyrovore AS BaseId, 'Walker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @myceticSpore AS BaseId, 'Deep Strike (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @myceticSpore AS BaseId, 'Transport (Special)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @myceticSpore AS BaseId, 'Mycetic Spore' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tervigon AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tervigon AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @tervigon AS BaseId, 'Transport (X Termagants)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @tervigon AS BaseId, 'Attached Transport' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tervigon AS BaseId, 'Walker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @toxicrene AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @toxicrene AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @toxicrene AS BaseId, 'Walker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @virago AS BaseId, 'Interceptor' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @virago AS BaseId, 'Floater' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @virago AS BaseId, 'Semi-Synaptic (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @barbedHierodule AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @barbedHierodule AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @barbedHierodule AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @barbedHierodule AS BaseId, 'Wounds (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @barbedHierodule AS BaseId, 'Slave (Nest)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @barbedHierodule AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @scythedHierodule AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @scythedHierodule AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @scythedHierodule AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @scythedHierodule AS BaseId, 'Wounds (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @scythedHierodule AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @scythedHierodule AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @scythedHierodule AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @razorfex AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @razorfex AS BaseId, 'Fear' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @razorfex AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @razorfex AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @razorfex AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Wounds (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Synapse (X)' AS AbilityName, '30 cm' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Synaptic Overload' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Forward Observer (FO)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Wounds (X)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Synapse (X)' AS AbilityName, '45 cm' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Psychic Save (X+)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Synaptic Overload' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Forward Observer (FO)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Synaptic Beacon' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harridan AS BaseId, 'Floater' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harridan AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @harridan AS BaseId, 'Synapse (X)' AS AbilityName, '20 cm' AS AbilityValue
    UNION ALL SELECT @harridan AS BaseId, 'Wounds (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @harridan AS BaseId, 'Transport (X Gargoyles)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @harridan AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @trygon AS BaseId, 'Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @trygon AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @trygon AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @trygon AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @trygon AS BaseId, 'Deep Strike (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @trygon AS BaseId, 'Synapse (X)' AS AbilityName, '15 cm' AS AbilityValue
    UNION ALL SELECT @trygon AS BaseId, 'Subterranean Assault' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @assaultTyrannofex AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @assaultTyrannofex AS BaseId, 'Close Defences (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @assaultTyrannofex AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @assaultTyrannofex AS BaseId, 'Fear' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @assaultTyrannofex AS BaseId, 'Slave (Devastation)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @assaultTyrannofex AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @supportTyrannofex AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @supportTyrannofex AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @supportTyrannofex AS BaseId, 'Regeneration (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @supportTyrannofex AS BaseId, 'Fear' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @supportTyrannofex AS BaseId, 'Slave (Nest)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Wounds (X)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Regeneration (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Agile' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Semi-Synaptic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Wounds (X)' AS AbilityName, '9' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Regeneration (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Agile' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Semi-Synaptic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Transport (X)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @bioPlasmaShot AS BaseId, 'Off-Table Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @sporeMineShot AS BaseId, 'Off-Table Artillery' AS AbilityName, '' AS AbilityValue
) AS b
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = b.AbilityName;

INSERT INTO BasePsychicPower (BaseId, PsychicPowerId, AbilityValue)
SELECT b.BaseId, pp.PsychicPowerId, b.AbilityValue
FROM (
    SELECT @nornQueen AS BaseId, 'Bio-Resistance' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Psychic Scream' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @nornQueen AS BaseId, 'Psychic Projectile' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Warp Field' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Energy Torrent' AS PowerName, '' AS AbilityValue
) AS b
INNER JOIN PsychicPower pp ON pp.PsychicPowerName = b.PowerName;

INSERT INTO WeaponSpecialAbility (WeaponId, SpecialAbilityId, AbilityValue)
SELECT w.WeaponId, sa.SpecialAbilityId, src.AbilityValue
FROM (
    SELECT @gargoyles AS BaseId, 'Flame Jet' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @zoanthrope AS BaseId, 'Warp Blast' AS WeaponName, 'Psychic Attack' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @zoanthrope AS BaseId, 'Warp Blast' AS WeaponName, 'Anti-Aircraft' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @biovore AS BaseId, 'Spore-Mines' AS WeaponName, 'Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @biovore AS BaseId, 'Spore-Mines' AS WeaponName, 'Battery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @biovore AS BaseId, 'Spore-Mines' AS WeaponName, 'Template (X)' AS AbilityName, '12 cm' AS AbilityValue
    UNION ALL SELECT @biovore AS BaseId, 'Spore-Mines' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @biovore AS BaseId, 'Spore-Mines' AS WeaponName, 'Bio-Toxin' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @biovore AS BaseId, 'Spore-Mines' AS WeaponName, 'Spore-Mine' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dactylis AS BaseId, 'Bile Pods -- Spores' AS WeaponName, 'Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dactylis AS BaseId, 'Bile Pods -- Spores' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-2' AS AbilityValue
    UNION ALL SELECT @dactylis AS BaseId, 'Bile Pods -- Bio-Acid' AS WeaponName, 'Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harpy AS BaseId, 'Spore-Mines' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @harpy AS BaseId, 'Spore-Mines' AS WeaponName, 'Bombardment (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @harpy AS BaseId, 'Spore-Mines' AS WeaponName, 'Spore-Mine' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harpy AS BaseId, 'Spore-Mines' AS WeaponName, 'Battery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harpy AS BaseId, 'Spore-Mines' AS WeaponName, 'Bio-Toxin' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @neurotyrant AS BaseId, 'Energy Torrent' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @pyrovore AS BaseId, 'Bio-Flame Lance Cannon' AS WeaponName, 'Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pyrovore AS BaseId, 'Bio-Flame Lance Cannon' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @virago AS BaseId, 'Salivary Cannon' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @barbedHierodule AS BaseId, 'Bio-Cannons' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @scythedHierodule AS BaseId, 'Pyro-Acid Jet' AS WeaponName, 'Flame Template' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @scythedHierodule AS BaseId, 'Pyro-Acid Jet' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Bio-Plasma Cannons' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Energy Torrent -- Focused' AS WeaponName, 'Psychic Attack' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Energy Torrent -- Diffuse' AS WeaponName, 'Psychic Attack' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Energy Torrent -- Diffuse' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @dominatrix AS BaseId, 'Energy Torrent -- Diffuse' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @harridan AS BaseId, 'Spore Cloud' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @harridan AS BaseId, 'Spore Cloud' AS WeaponName, 'Bio-Toxin' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harridan AS BaseId, 'Spore Cloud' AS WeaponName, 'Bombardment (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @trygon AS BaseId, 'Bio-Shock' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @supportTyrannofex AS BaseId, 'Bio-Plasma Cannon' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Bio-Cannon' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Spore Pods' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Spore Pods' AS WeaponName, 'Bio-Toxin' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Spore Pods' AS WeaponName, 'Spore Pods' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Bile Spitter -- Focused' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Bile Spitter -- Diffuse' AS WeaponName, 'Template (X)' AS AbilityName, '12 cm' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Bile Spitter -- Diffuse' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Spine Clusters' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Spine Clusters' AS WeaponName, 'Fires Twice' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Pyro-Acid Jet' AS WeaponName, 'Flame Template' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Pyro-Acid Jet' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Razor Claws' AS WeaponName, 'Razor Claws' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @alphaHierodule AS BaseId, 'Tentacles' AS WeaponName, 'Tentacles' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Bio-Cannon' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Spore Pods' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Spore Pods' AS WeaponName, 'Bio-Toxin' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Spore Pods' AS WeaponName, 'Spore Pods' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Bile Spitter -- Focused' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Bile Spitter -- Diffuse' AS WeaponName, 'Template (X)' AS AbilityName, '12 cm' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Bile Spitter -- Diffuse' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Spine Clusters' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Spine Clusters' AS WeaponName, 'Fires Twice' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Pyro-Acid Jet' AS WeaponName, 'Flame Template' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Pyro-Acid Jet' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Razor Claws' AS WeaponName, 'Razor Claws' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hierophant AS BaseId, 'Tentacles' AS WeaponName, 'Tentacles' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @bioPlasmaShot AS BaseId, 'Bio-Plasma' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @bioPlasmaShot AS BaseId, 'Bio-Plasma' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @sporeMineShot AS BaseId, 'Spore-Mines' AS WeaponName, 'Template (X)' AS AbilityName, '12 cm' AS AbilityValue
    UNION ALL SELECT @sporeMineShot AS BaseId, 'Spore-Mines' AS WeaponName, 'Spore-Mine' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @sporeMineShot AS BaseId, 'Spore-Mines' AS WeaponName, 'Bio-Toxin' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @sporeMineShot AS BaseId, 'Spore-Mines' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
) AS src
INNER JOIN Weapon w ON w.BaseId = src.BaseId AND w.`Name` = src.WeaponName
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = src.AbilityName;

INSERT INTO TitanWeapon (
    CodexId, WeaponName, PointsCost, Notes, IsAssault, LimitPerTitan
) VALUES
    (@codexId, 'Bio-Cannon', 75, 'Damage (+1).', 0, 0),
    (@codexId, 'Spore Pods', 50, 'Limited to one per Bio-Titan. Increases Close Defences to 4+.', 0, 1),
    (@codexId, 'Bile Spitter', 75, 'Choose Focused or Diffuse firing mode.', 0, 0),
    (@codexId, 'Spine Clusters', 75, 'Template (7.5 cm), Fires Twice.', 0, 0),
    (@codexId, 'Pyro-Acid Jet', 50, 'Flame Template, Reduces Cover (-3).', 0, 0),
    (@codexId, 'Razor Claws', 75, 'Assault weapon. Choose one effect.', 1, 0),
    (@codexId, 'Dart Salvo', 75, '', 0, 0),
    (@codexId, 'Tentacles', 50, 'Choose one effect.', 0, 0)
ON DUPLICATE KEY UPDATE
    PointsCost = VALUES(PointsCost),
    Notes = VALUES(Notes),
    IsAssault = VALUES(IsAssault),
    LimitPerTitan = VALUES(LimitPerTitan);

