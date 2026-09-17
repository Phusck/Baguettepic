-- Necrons 3.1.0 from C:/Files/NetEpicFR300-EnglishTranslation/Necrons 310
-- Upserts Necrons catalog data. Preserves army lists and Base/Formation ids.

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

SET @hasUsesCp := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Codex'
      AND COLUMN_NAME = 'UsesCommandPoints'
);
SET @sql := IF(
    @hasUsesCp = 0,
    'ALTER TABLE Codex ADD COLUMN UsesCommandPoints TINYINT(1) NOT NULL DEFAULT 0 AFTER CodexName',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

ALTER TABLE `Base`
    MODIFY Morale VARCHAR(16) NOT NULL,
    MODIFY Movement VARCHAR(16) NOT NULL,
    MODIFY FA VARCHAR(16) NOT NULL;
ALTER TABLE Weapon
    MODIFY Dice VARCHAR(32) NOT NULL,
    MODIFY ArmourPenetration VARCHAR(16) NOT NULL;

INSERT INTO FormationKind (FormationKindId, KindName)
SELECT 1, 'Mandatory' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 1);
INSERT INTO FormationKind (FormationKindId, KindName)
SELECT 2, 'Company' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 2);
INSERT INTO FormationKind (FormationKindId, KindName)
SELECT 3, 'Special' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 3);
INSERT INTO FormationKind (FormationKindId, KindName)
SELECT 4, 'Support' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 4);
INSERT INTO FormationKind (FormationKindId, KindName)
SELECT 5, 'Option' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 5);
INSERT INTO FormationKind (FormationKindId, KindName)
SELECT 6, 'Limited' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM FormationKind WHERE FormationKindId = 6);

INSERT INTO Codex (CodexName)
SELECT 'Necrons'
WHERE NOT EXISTS (SELECT 1 FROM Codex WHERE CodexName = 'Necrons');

SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Necrons');
UPDATE Codex SET UsesCommandPoints = 0 WHERE CodexId = @codexId;

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

DELETE d FROM Detachment d
WHERE d.CodexId = @codexId;

DELETE FROM SpecialRule WHERE CodexId = @codexId;

-- Preserve Base and Formation rows (and army lists). Upsert catalog fields.
INSERT INTO `Base` (
    CodexId, BaseName, DestructionPoints,
    Morale, `Class`, Movement, `Save`, FA, NumberOfTitanWeapons
) VALUES
    (@codexId, 'Cryptek', 0, 'Attached', 1, '10', '5+/6+f', '+2', 0),
    (@codexId, 'Flayed One', 0, '--', 1, '10', '5+', '+3', 0),
    (@codexId, 'Hexmark Destroyer', 0, '--', 1, '15', '5+', '+2', 0),
    (@codexId, 'Skorpekh Destroyer', 0, '--', 1, '15', '5+', '+6', 0),
    (@codexId, 'Lychguard', 0, '--', 1, '10', '4+', '+5', 0),
    (@codexId, 'Necron Warriors', 0, '--', 1, '10', '5+', '+1', 0),
    (@codexId, 'Immortals', 0, '--', 1, '10', '5+', '+2', 0),
    (@codexId, 'Overlord', 0, 'Attached', 1, '10', '4+/5+f', '+7', 0),
    (@codexId, 'Pariah', 0, '--', 1, '10', '5+', '+4', 0),
    (@codexId, 'Triarch Praetorians', 0, '--', 1, '15', '5+', '+4', 0),
    (@codexId, 'Flayed Lord', 0, 'Attached', 1, '10', '4+/5+f', '+5', 0),
    (@codexId, 'Necron Lord', 0, 'Attached', 1, '10', '4+/5+f', '+5', 0),
    (@codexId, 'Deathmark', 0, '--', 1, '10', '5+', '+1', 0),
    (@codexId, 'Skorpekh Lord', 0, 'Attached', 1, '15', '4+/5+f', '+7', 0),
    (@codexId, 'Destroyer', 0, '--', 2, '30', '5+', '+1', 0),
    (@codexId, 'Heavy Destroyer', 0, '--', 2, '30', '5+', '+1', 0),
    (@codexId, 'Canoptek Acanthrites', 0, '--', 2, '30', '5+', '+3', 0),
    (@codexId, 'Destroyer Lord', 0, 'Attached', 2, '30', '4+/5+f', '+5', 0),
    (@codexId, 'Canoptek Spyder (Assault)', 0, '--', 2, '15', '4+', '+3', 0),
    (@codexId, 'Canoptek Spyder (Support)', 0, '--', 2, '15', '4+', '+1', 0),
    (@codexId, 'Ophydian Destroyer', 0, '--', 2, '20', '5+', '+4', 0),
    (@codexId, 'Tomb Blades', 0, '--', 2, '30', '5+', '+2', 0),
    (@codexId, 'Canoptek Wraiths', 0, '--', 2, '25', '4+f', '+4', 0),
    (@codexId, 'Triarch Stalker', 0, '--', 2, '20', '3+/6+f', '+3', 0),
    (@codexId, 'Canoptek Doomstalker', 0, '--', 2, '20', '4+/5+f', '+2', 0),
    (@codexId, 'Canoptek Reanimator', 0, '--', 2, '20', '4+/5+f', '+2', 0),
    (@codexId, 'Doomsday Ark', 0, '--', 3, '20', '3+/5+f', '+0', 0),
    (@codexId, 'Ghost Ark', 0, '--', 3, '25', '3+/5+f', '+0', 0),
    (@codexId, 'Tesseract Ark', 0, '--', 3, '30', '3+/5+f', '+0', 0),
    (@codexId, 'Catacomb Command Barge', 0, 'Attached', 3, '30', '3+/5+f', '+5', 0),
    (@codexId, 'Annihilation Barge', 0, '--', 3, '30', '3+/5+f', '+0', 0),
    (@codexId, 'Doom Scythe', 0, '--', 3, '--', '3+/5+f', '+5', 0),
    (@codexId, 'Night Scythe', 0, '--', 3, '--', '3+/5+f', '+4', 0),
    (@codexId, 'Night Shroud', 0, '--', 3, '--', '3+/5+f', '+2', 0),
    (@codexId, 'Deceiver', 0, '--', 4, '25', '2+/4+f', '+11', 0),
    (@codexId, 'Tesseract Vault', 0, '--', 4, '20', '2+/4+f', '+5', 0),
    (@codexId, 'Nightbringer', 0, '--', 4, '25', '2+/4+f', '+11', 0),
    (@codexId, 'Transcendent C''tan', 0, '--', 4, '25', '2+/4+f', '+11', 0),
    (@codexId, 'Void Dragon', 0, '--', 4, '25', '2+/4+f', '+11', 0),
    (@codexId, 'Tomb Golem', 0, '--', 4, '20', '2+/3+f', '+5', 0),
    (@codexId, 'Canoptek Tomb Sentinel', 0, '--', 4, '15', '2+/5+f', '+7', 0),
    (@codexId, 'Monolith', 0, '--', 4, '15', '2+/5+f', '+4', 0),
    (@codexId, 'Doomsday Monolith', 0, '--', 4, '15', '2+/5+f', '+5', 0),
    (@codexId, 'Seraptek Heavy Construct', 0, '--', 4, '20', '2+/5+f', '+7', 0),
    (@codexId, 'Pylon', 0, '--', 4, '0', '3+/5+f', '+5', 0),
    (@codexId, 'Obelisk', 0, '--', 4, '15', '2+/5+f', '+4', 0),
    (@codexId, 'Abattoir', 0, 'Sheet', 6, '15', '2+/5+f', '+10', 0),
    (@codexId, 'War Barge', 0, 'Sheet', 5, '20', '2+/5+f', '+10', 0),
    (@codexId, 'Aeonic Orb', 0, 'Sheet', 5, '20', '2+/5+f', '+10', 0),
    (@codexId, 'Tomb Guardian', 0, 'Sheet', 5, '25', '2+/5+f', '+12', 2),
    (@codexId, 'Scarab Tokens', 0, '--', 0, '--', '--', '--', 0)
ON DUPLICATE KEY UPDATE
    DestructionPoints = VALUES(DestructionPoints),
    Morale = VALUES(Morale),
    `Class` = VALUES(`Class`),
    Movement = VALUES(Movement),
    `Save` = VALUES(`Save`),
    FA = VALUES(FA),
    NumberOfTitanWeapons = VALUES(NumberOfTitanWeapons);

INSERT INTO SpecialAbility (SpecialAbilityName, Description)
SELECT n, d FROM (
    SELECT 'Portal' AS n, 'The Necrons use Portals to cross long distances. Crossing a Portal allows a detachment to enter the battlefield from Reserve, or to pass from one Portal to another on the battlefield.

Crossing a Portal costs 5 cm of movement to the detachment that crosses it and nothing to the base that has the Portal. The same detachment may cross several Portals during its activation. Portals are limited in the number of detachments that may exit them per turn, as well as the maximum class of bases that may cross them.

Bases exiting a Portal follow the rules for exiting a transport. A detachment crossing a Portal must do so entirely. Only allied Necrons may use a Portal.

| Troop | Class that may cross | Detachments that may exit |
| --- | --- | --- |
| Monolith and Doomsday Monolith | Class 1 | 2 detachments per turn |
| Abattoir | Classes 1 and 2 | 1 detachment per turn per Portal still active |
| War Barge | Classes 1, 2 and 3 | 5 detachments per turn |' AS d
    UNION ALL SELECT 'Deathmark' AS n, 'Deathmarks may make Intercept Fire on an off-table arrival as if it were a normal movement.

If a Deathmark detachment is not yet present on the table, it may make its off-table arrival in reaction to an enemy off-table arrival. If you decide to do so, wait until the enemy bases have been placed, then you may place the Deathmark bases directly base-to-base with those of the targeted detachment; they are considered to have charged. They gain a +2 AF bonus for that turn.' AS d
    UNION ALL SELECT 'Invasion Beams' AS n, 'A detachment with this ability may open a Portal during its movement for a single Necron infantry detachment placed in Reserve, along its path.' AS d
    UNION ALL SELECT 'Targeting Relay' AS n, 'If a base with this ability scores a hit on a detachment, place a marker next to it. All bases from this codex then gain the Reduces Cover (-3) ability if they shoot at a detachment thus designated. Remove all markers during end-of-turn effects.' AS d
    UNION ALL SELECT 'Reanimation Protocols (X+)' AS n, 'If a detachment with bases that have this ability is not at full strength in the End-of-Turn Effects phase, but still has at least 1 base present on the table, it is possible to attempt to reanimate the losses. To do so, roll a die for each missing base; on an X+ it is reanimated. Bases thus returned to play must be in coherency with the detachment and may not be placed in an enemy base''s Control Zone.' AS d
    UNION ALL SELECT 'Scarab Generator' AS n, 'The Necron player gains one Scarab token per base with this ability at the moment of activation in the Movement Phase of the detachment that has Scarab Generator.' AS d
    UNION ALL SELECT 'Repair Platform' AS n, 'Any Necron Warrior or Immortal base within 12 cm of a base with this ability gains a bonus of 1 to its Reanimation Protocols roll.' AS d
    UNION ALL SELECT 'Resurrection Orb' AS n, 'Once per battle, a detachment within 12 cm of a base with this ability may increase its Reanimation Protocols rolls by 1.' AS d
    UNION ALL SELECT 'Reanimator' AS n, 'Any detachment within 12 cm improves its Reanimation Protocols rolls by 1.' AS d
    UNION ALL SELECT 'Outcasts' AS n, 'Bases with this ability may never use a Portal.' AS d
    UNION ALL SELECT 'Soulless' AS n, 'Any detachment within 25 cm of a base with this ability is considered to have a Morale of 7, unless it is already worse (that is, a higher value). Detachments with no Morale value are not affected.' AS d
    UNION ALL SELECT 'Doomsday Cannon' AS n, 'The Doomsday Cannon has three firing modes; it may use only one per turn. Diffuse mode and Concentrated mode may be used only if the Ark has not moved this turn, which includes surprise attacks.' AS d
    UNION ALL SELECT 'Anti-Gravitic Matrix' AS n, 'Any enemy base at altitude within 25 cm of a base with this ability is affected as by a shot hitting on 4+ with AP -2 and the AA ability. If the enemy fails its save, it crashes to the ground and is automatically destroyed. This ability does not stack if several matrices overlap.' AS d
    UNION ALL SELECT 'Containment Failure' AS n, 'If a shard is destroyed, its necrodermis body explodes immediately. All bases within 2D6 cm suffer a hit on 3+ with AP 0; this does not affect troops in garrison.' AS d
    UNION ALL SELECT 'Absorption' AS n, 'Each time the Void Dragon destroys an enemy base of class 3 or more, it regains a lost Wound on a 4+ (maximum 2 per turn).' AS d
    UNION ALL SELECT 'Reinforced Necrodermis' AS n, 'Bases with this ability divide the damage they suffer by 2, rounded down, with a minimum of 1. That is, an attack with Damage (+3) inflicts 2 damage instead of the usual 4.' AS d
    UNION ALL SELECT 'Organic Metal (X)' AS n, 'A base with this ability has X Organic Metal points. Each shot that hits a target with Organic Metal points hits the Organic Metal rather than the target. Organic Metal tokens have a 1+ save and are destroyed at the first failed save.

Organic Metal has no effect in assault.' AS d
    UNION ALL SELECT 'Dimensional Translocation' AS n, 'The War Barge is able to widen the rift in reality where it appears. To represent this, place a Template (12 cm) centred on the War Barge''s point of arrival. All bases under the template (except the War Barge) are hit on 4+ with AP -3; those that survive are placed on the edges of the template, as close as possible.' AS d
    UNION ALL SELECT 'Aeonic Orb' AS n, 'The Aeonic Orb begins the game with three plasma tokens in its Plasma Chamber (the maximum). The Aeonic Orb regenerates 2 plasma tokens each Final Phase, during end-of-turn effects. These tokens are used to fire the Solar Flare. Unused plasma tokens may be stored and used in later turns.

It is possible to make the following 3 firing modes:
• Burst Fire, which costs 1 plasma token
• Light Fire, which costs 2 plasma tokens
• Powerful Fire, which costs 3 plasma tokens' AS d
    UNION ALL SELECT 'My Will Be Done' AS n, 'All allied class 1 detachments activating in the Movement Phase within 12 cm of a base with this ability receive +5 cm to their total movement even if the base with this ability is in a transport. Detachments embarked at the start of movement or arriving from a Portal within 12 cm of the base also benefit from this ability.' AS d
    UNION ALL SELECT 'Engine of Destruction' AS n, 'Only one Engine of Destruction is allowed in a Necron army per 5000 points. The Engines of Destruction are the Abattoir and the Aeonic Orb.' AS d
    UNION ALL SELECT 'Harvesters — Assault' AS n, 'Each Harvester used for assault grants the Parry or Entangle ability, +2 AF, and Damage (+1) in assault. Each also increases the DR by 1.' AS d
    UNION ALL SELECT 'Scarab Tokens' AS n, 'Scarab tokens may be used by any Necron base of class 1 or 2. Each token may be used in two ways.

Assault: A class 1 or 2 base directs the Scarabs that attack the enemy. In addition to its ranged weapons, the base gains a one-use shot that uses a Template (7.5 cm), hits on 5+, has a range of 20 cm, no AP, and the Reduces Cover (-1) ability. A base may benefit from only one Scarab token per turn in this way.

Repair: when a base makes a Reanimation Protocols roll, you may use a Scarab token to improve the base''s chance of success by 2.' AS d
    UNION ALL SELECT 'Inorganic' AS n, 'A base with this ability is immune to certain effects. The descriptions of those effects specify when this immunity applies.' AS d
    UNION ALL SELECT 'Elite (X)' AS n, 'At the beginning of the battle, your army receives a shared pool of Elite rerolls.

Each detachment containing bases with Elite (X) adds X rerolls to this pool, regardless of how many Elite bases the detachment contains.

During the battle, Elite rerolls may be spent to reroll dice rolled by your Elite bases. Before using them, declare the total number of dice that will be rerolled.

Only one Elite reroll may be used per base for each dice roll. Consequently, only one die from an assault roll may be rerolled.

Used Elite rerolls are removed from the army''s pool.

Elite rerolls may be used for To-Hit rolls, armour saving throws, assault rolls, Dodge rolls, and opportunity attacks made when an enemy disengages.' AS d
    UNION ALL SELECT 'Jump Packs' AS n, 'Bases equipped with Jump Packs may make short flights over terrain, buildings, and enemy troops.

They ignore enemy zones of control except those generated by bases with the Floater, Skimmer, or Jump Packs ability.

They also ignore terrain modifiers during their movement but cannot end their movement on Impassable terrain.

While using this ability to move over an obstacle, the base is considered to be at altitude.' AS d
    UNION ALL SELECT 'Hard to Hit' AS n, 'All ranged attacks targeting a base with this ability suffer a -1 To-Hit penalty.

This penalty does not apply to template weapons.' AS d
    UNION ALL SELECT 'Deep Strike (X)' AS n, 'The controlling player selects a point on the battlefield and places one base from the detachment at that point. The base then scatters X times, moving 3D6 cm for each scatter.

If the final point is outside the battlefield, within Impassable terrain, or within the zone of control of an enemy base of the same or a higher class, the detachment does not arrive. Another attempt may be made during the following turn.

Otherwise, place the first base as close as possible to the final arrival point. Place every other base in the detachment anywhere within 6 cm of the first base.

A detachment entering the battlefield in this manner cannot receive a First Fire order during the turn in which it arrives. It also loses 5 cm from its total available movement during that turn.' AS d
    UNION ALL SELECT 'HQ' AS n, 'When an HQ base is targeted by a shooting attack, its controlling player may select another base of the same class within 6 cm as the attack''s target instead.

This decision must be made before any saving throws are rolled. HQ protection does not function during an assault.' AS d
    UNION ALL SELECT 'Attached Character' AS n, 'At the beginning of the battle, an Attached Character must join a detachment. The character and the detachment are then treated as a single detachment.

The Attached Character must remain in coherency with the detachment, uses its Morale value, and adds its points cost to the detachment''s total cost.

Attached Characters do not occupy space in transports. A single detachment may include up to two Attached Characters.

An Attached Character gains the Movement characteristic of the detachment to which it is attached, and its movement-related special abilities.' AS d
    UNION ALL SELECT 'Psyker' AS n, 'During the Combat Phase, a Psyker may use both one psychic power and its conventional weapons.

Unless otherwise specified, a Psyker may use only one psychic power per turn.' AS d
    UNION ALL SELECT 'Psychic Save (X+)' AS n, 'A base with Psychic Save (X+) may use this saving throw against psychic powers.' AS d
    UNION ALL SELECT 'Psychic Abomination' AS n, 'Enemy Psykers within 25 cm of a base with this ability suffer a -1 penalty when using psychic powers. Bases with this ability gain a Psychic Save (2+).' AS d
    UNION ALL SELECT 'Damage (+X) in Assault' AS n, 'A weapon with this ability inflicts X additional hits after its base wins a duel, in addition to the normal hit.' AS d
    UNION ALL SELECT 'Damage (+X)' AS n, 'A weapon with this ability inflicts X additional hits against a base successfully hit by the weapon.' AS d
    UNION ALL SELECT 'Reflex Fire' AS n, 'A base with this ability does not suffer the normal -1 To-Hit penalty when performing Overwatch Fire.' AS d
    UNION ALL SELECT 'Sniper' AS n, 'When a base with the Sniper ability targets an HQ base, roll 1D6. On a result of 4+, the target cannot use its HQ ability against the Sniper''s attack.' AS d
    UNION ALL SELECT 'Infiltration' AS n, 'These bases are stealthy and capable of approaching the enemy before the battle begins.

After deployment, bases with this ability may move up to 25 cm. This movement cannot bring a base into an enemy zone of control and cannot be performed while the detachment is being transported.' AS d
    UNION ALL SELECT 'Fear' AS n, 'A Class 1–3 detachment that enters base-to-base contact with a base possessing this ability must pass a Morale Test or suffer a -2 AF penalty for the remainder of the turn.

This applies whether the Fear-causing base charges or is itself charged.

Fear has no effect against bases with the Fear or Terror ability.' AS d
    UNION ALL SELECT 'Antigrav' AS n, 'A base with Antigrav may make short flights over terrain, buildings, and enemy troops.

It ignores terrain movement penalties and enemy zones of control except those generated by bases with Floater, Skimmer, Jump Packs, or Antigrav.

It cannot end its movement on Impassable terrain. While moving over obstacles it is considered to be at altitude.' AS d
    UNION ALL SELECT 'Heavy Antigrav' AS n, 'Bases with Heavy Antigrav follow the rules for Antigrav / Heavy Skimmer but cannot perform Pop-up Attacks.' AS d
    UNION ALL SELECT 'Integral Armour' AS n, 'A base with Integral Armour does not use a hit-location chart. Every hit is resolved against the base as a whole.' AS d
    UNION ALL SELECT 'Flyer' AS n, 'Flyers may deploy on the battlefield or begin off-table (they cannot enter before Turn 2).

At altitude, Flyers move in a straight line with unlimited Movement (minimum 45 cm), ignore terrain and most zones of control, and use special assault and bombing rules. See the Flyer rules for further details.' AS d
    UNION ALL SELECT 'Interceptor' AS n, 'A detachment with this ability may perform Aerial Interceptions. See the Flyer rules for further details.' AS d
    UNION ALL SELECT 'Transport (X)' AS n, 'A base with Transport (X) may transport X Infantry bases.

Entering or leaving a transport costs the transported bases 5 cm of movement. When a base leaves a transport, place it in contact with the transporting base.' AS d
    UNION ALL SELECT 'Attached Transport' AS n, 'Attached Transports and the bases they transport are treated as a single detachment.' AS d
    UNION ALL SELECT 'Anti-Aircraft' AS n, 'These weapons operate independently and may be activated separately from a base''s other weapons.

If the base has a First Fire order, these weapons may perform Overwatch Fire against targets at altitude without suffering the usual To-Hit penalty. They may also perform Overwatch Fire while the base has an Advance order, but suffer the normal -1 To-Hit penalty.

Weapons with this ability always have a 360 degree firing arc and reduce a Flyer''s Protection save by 2.

When firing at targets that are not at altitude, these weapons function normally but suffer a -1 To-Hit penalty.' AS d
    UNION ALL SELECT 'Turret' AS n, 'A weapon with the Turret ability has a 360 degree firing arc.' AS d
    UNION ALL SELECT 'Template (X)' AS n, 'Templates have an area of effect and may therefore affect more than one target.

Any base whose centre is covered by a template may be hit, depending on the template weapon''s To-Hit roll.' AS d
    UNION ALL SELECT 'Close Defences (X+)' AS n, 'Every Class 1 or 2 base that engages, or is engaged by, a base with Close Defences suffers a hit on X+ with AP 0.

Resolve the attack when the bases make contact. Cover saves may be used against Close Defences.' AS d
    UNION ALL SELECT 'Wounds (X)' AS n, 'A base with this ability has X Wounds, allowing it to survive multiple injuries.

By default, a base has only one Wound.' AS d
    UNION ALL SELECT 'Terror' AS n, 'A detachment engaged in an assault by a base with the Terror ability must make a Morale Test with a -1 modifier.

If the test is failed, the detachment immediately receives a Fall Back order but does not make a Fall Back move.

A detachment attempting to engage a base with Terror must also pass a Morale Test with a -1 modifier or stop before entering the Terror-causing base''s zone of control.

Bases with Terror are immune to Terror.' AS d
    UNION ALL SELECT 'Bombing (X)' AS n, 'Flyers and Floating bases at altitude may drop X bombs during their movement. Resolve each attack immediately during the movement, following the normal shooting procedure.

Bombs cannot be dropped while the detachment has a Charge order and cannot affect targets at altitude.' AS d
    UNION ALL SELECT 'Agile' AS n, 'A Titan or Praetorian with this ability is not limited to a total of 90 degrees of turning during each turn.' AS d
    UNION ALL SELECT 'Dread (-X)' AS n, 'When activated during the Combat Phase, a base with this ability may force one enemy detachment with at least one base within 20 cm to make a Morale Test with a -X modifier.' AS d
    UNION ALL SELECT 'Dark Presence (-X / Y cm)' AS n, 'Enemy detachments with at least one base within Y cm of a base with this ability suffer a -X penalty to Morale Tests.' AS d
    UNION ALL SELECT 'Redeployment (X)' AS n, 'A base with this ability allows its controlling player to redeploy X detachments at the beginning of the battle.

After both players have finished deploying their armies, but before resolving Infiltration, the player may reposition X detachments according to the normal deployment rules.' AS d
    UNION ALL SELECT 'Leader' AS n, 'All allied detachments with at least one base within 12 cm of a base with this ability receive a +1 bonus to their AF.' AS d
    UNION ALL SELECT 'Master Strategist' AS n, 'An army containing a base with this ability receives two additional order counters that may be kept in reserve and assigned after normal orders have been revealed.' AS d
    UNION ALL SELECT 'Parry' AS n, 'A base with this ability ignores the first outnumbering die during an assault.

Consequently, the opposing side only begins receiving outnumbering dice when the base fights its third opponent.' AS d
    UNION ALL SELECT 'Entangle' AS n, 'When a base with this ability makes contact with an enemy base that has a hit-location chart, it may immobilise one of the enemy base''s weapons. The effects of that weapon are cancelled for the remainder of the turn.

If two opposing bases both possess such weapons, the abilities cancel one another and both weapons become entangled.' AS d
    UNION ALL SELECT 'Duellist' AS n, 'A base with this ability chooses the order in which its assault duels are resolved.' AS d
    UNION ALL SELECT 'Dodge (X+)' AS n, 'When a base with this ability loses Wounds in an assault, roll one die for each Wound lost. For each result of X+, the base does not lose that Wound.

Dodge may also be used against hits caused by Close Defences.' AS d
    UNION ALL SELECT 'Reduces Cover (X)' AS n, 'A weapon with this ability worsens the target''s cover save by X.' AS d
    UNION ALL SELECT 'Damages Buildings (AP -X / Y)' AS n, 'A weapon with this ability damages buildings. Buildings hit by the weapon suffer Y damage with Armour Penetration -X.' AS d
    UNION ALL SELECT 'Damages Buildings (AP -X / Y) in Assault' AS n, 'In all other respects, this ability functions in the same manner as Damages Buildings.' AS d
    UNION ALL SELECT 'First Strike (X)' AS n, 'A weapon with this ability may attack a base in contact with it immediately before an assault is resolved.

Resolve the attack after the assault has been selected for activation but before resolving anything else. It is treated as a shooting attack, but its To-Hit roll never suffers penalties and it ignores Shields.

The target may make a normal saving throw. Damage inflicted by First Strike attacks counts towards the final combat result.' AS d
    UNION ALL SELECT 'Subterranean Fire' AS n, 'Attacks with this ability ignore Energy Shields, Energy Fields, and Deflector Shields.

They have no effect against Skimmers or bases at altitude.

Against a base with a hit-location chart, Subterranean Fire always hits its lowest location, Location 1.' AS d
    UNION ALL SELECT 'Reroll Assault Dice' AS n, 'A base with this ability may reroll its assault dice. If it does so, it must reroll all of them.' AS d
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM SpecialAbility sa WHERE sa.SpecialAbilityName = src.n
);

UPDATE SpecialAbility sa
INNER JOIN (
    SELECT 'Portal' AS n, 'The Necrons use Portals to cross long distances. Crossing a Portal allows a detachment to enter the battlefield from Reserve, or to pass from one Portal to another on the battlefield.

Crossing a Portal costs 5 cm of movement to the detachment that crosses it and nothing to the base that has the Portal. The same detachment may cross several Portals during its activation. Portals are limited in the number of detachments that may exit them per turn, as well as the maximum class of bases that may cross them.

Bases exiting a Portal follow the rules for exiting a transport. A detachment crossing a Portal must do so entirely. Only allied Necrons may use a Portal.

| Troop | Class that may cross | Detachments that may exit |
| --- | --- | --- |
| Monolith and Doomsday Monolith | Class 1 | 2 detachments per turn |
| Abattoir | Classes 1 and 2 | 1 detachment per turn per Portal still active |
| War Barge | Classes 1, 2 and 3 | 5 detachments per turn |' AS d
    UNION ALL SELECT 'Deathmark' AS n, 'Deathmarks may make Intercept Fire on an off-table arrival as if it were a normal movement.

If a Deathmark detachment is not yet present on the table, it may make its off-table arrival in reaction to an enemy off-table arrival. If you decide to do so, wait until the enemy bases have been placed, then you may place the Deathmark bases directly base-to-base with those of the targeted detachment; they are considered to have charged. They gain a +2 AF bonus for that turn.' AS d
    UNION ALL SELECT 'Invasion Beams' AS n, 'A detachment with this ability may open a Portal during its movement for a single Necron infantry detachment placed in Reserve, along its path.' AS d
    UNION ALL SELECT 'Targeting Relay' AS n, 'If a base with this ability scores a hit on a detachment, place a marker next to it. All bases from this codex then gain the Reduces Cover (-3) ability if they shoot at a detachment thus designated. Remove all markers during end-of-turn effects.' AS d
    UNION ALL SELECT 'Reanimation Protocols (X+)' AS n, 'If a detachment with bases that have this ability is not at full strength in the End-of-Turn Effects phase, but still has at least 1 base present on the table, it is possible to attempt to reanimate the losses. To do so, roll a die for each missing base; on an X+ it is reanimated. Bases thus returned to play must be in coherency with the detachment and may not be placed in an enemy base''s Control Zone.' AS d
    UNION ALL SELECT 'Scarab Generator' AS n, 'The Necron player gains one Scarab token per base with this ability at the moment of activation in the Movement Phase of the detachment that has Scarab Generator.' AS d
    UNION ALL SELECT 'Repair Platform' AS n, 'Any Necron Warrior or Immortal base within 12 cm of a base with this ability gains a bonus of 1 to its Reanimation Protocols roll.' AS d
    UNION ALL SELECT 'Resurrection Orb' AS n, 'Once per battle, a detachment within 12 cm of a base with this ability may increase its Reanimation Protocols rolls by 1.' AS d
    UNION ALL SELECT 'Reanimator' AS n, 'Any detachment within 12 cm improves its Reanimation Protocols rolls by 1.' AS d
    UNION ALL SELECT 'Outcasts' AS n, 'Bases with this ability may never use a Portal.' AS d
    UNION ALL SELECT 'Soulless' AS n, 'Any detachment within 25 cm of a base with this ability is considered to have a Morale of 7, unless it is already worse (that is, a higher value). Detachments with no Morale value are not affected.' AS d
    UNION ALL SELECT 'Doomsday Cannon' AS n, 'The Doomsday Cannon has three firing modes; it may use only one per turn. Diffuse mode and Concentrated mode may be used only if the Ark has not moved this turn, which includes surprise attacks.' AS d
    UNION ALL SELECT 'Anti-Gravitic Matrix' AS n, 'Any enemy base at altitude within 25 cm of a base with this ability is affected as by a shot hitting on 4+ with AP -2 and the AA ability. If the enemy fails its save, it crashes to the ground and is automatically destroyed. This ability does not stack if several matrices overlap.' AS d
    UNION ALL SELECT 'Containment Failure' AS n, 'If a shard is destroyed, its necrodermis body explodes immediately. All bases within 2D6 cm suffer a hit on 3+ with AP 0; this does not affect troops in garrison.' AS d
    UNION ALL SELECT 'Absorption' AS n, 'Each time the Void Dragon destroys an enemy base of class 3 or more, it regains a lost Wound on a 4+ (maximum 2 per turn).' AS d
    UNION ALL SELECT 'Reinforced Necrodermis' AS n, 'Bases with this ability divide the damage they suffer by 2, rounded down, with a minimum of 1. That is, an attack with Damage (+3) inflicts 2 damage instead of the usual 4.' AS d
    UNION ALL SELECT 'Organic Metal (X)' AS n, 'A base with this ability has X Organic Metal points. Each shot that hits a target with Organic Metal points hits the Organic Metal rather than the target. Organic Metal tokens have a 1+ save and are destroyed at the first failed save.

Organic Metal has no effect in assault.' AS d
    UNION ALL SELECT 'Dimensional Translocation' AS n, 'The War Barge is able to widen the rift in reality where it appears. To represent this, place a Template (12 cm) centred on the War Barge''s point of arrival. All bases under the template (except the War Barge) are hit on 4+ with AP -3; those that survive are placed on the edges of the template, as close as possible.' AS d
    UNION ALL SELECT 'Aeonic Orb' AS n, 'The Aeonic Orb begins the game with three plasma tokens in its Plasma Chamber (the maximum). The Aeonic Orb regenerates 2 plasma tokens each Final Phase, during end-of-turn effects. These tokens are used to fire the Solar Flare. Unused plasma tokens may be stored and used in later turns.

It is possible to make the following 3 firing modes:
• Burst Fire, which costs 1 plasma token
• Light Fire, which costs 2 plasma tokens
• Powerful Fire, which costs 3 plasma tokens' AS d
    UNION ALL SELECT 'My Will Be Done' AS n, 'All allied class 1 detachments activating in the Movement Phase within 12 cm of a base with this ability receive +5 cm to their total movement even if the base with this ability is in a transport. Detachments embarked at the start of movement or arriving from a Portal within 12 cm of the base also benefit from this ability.' AS d
    UNION ALL SELECT 'Engine of Destruction' AS n, 'Only one Engine of Destruction is allowed in a Necron army per 5000 points. The Engines of Destruction are the Abattoir and the Aeonic Orb.' AS d
    UNION ALL SELECT 'Harvesters — Assault' AS n, 'Each Harvester used for assault grants the Parry or Entangle ability, +2 AF, and Damage (+1) in assault. Each also increases the DR by 1.' AS d
    UNION ALL SELECT 'Scarab Tokens' AS n, 'Scarab tokens may be used by any Necron base of class 1 or 2. Each token may be used in two ways.

Assault: A class 1 or 2 base directs the Scarabs that attack the enemy. In addition to its ranged weapons, the base gains a one-use shot that uses a Template (7.5 cm), hits on 5+, has a range of 20 cm, no AP, and the Reduces Cover (-1) ability. A base may benefit from only one Scarab token per turn in this way.

Repair: when a base makes a Reanimation Protocols roll, you may use a Scarab token to improve the base''s chance of success by 2.' AS d
    UNION ALL SELECT 'Inorganic' AS n, 'A base with this ability is immune to certain effects. The descriptions of those effects specify when this immunity applies.' AS d
    UNION ALL SELECT 'Elite (X)' AS n, 'At the beginning of the battle, your army receives a shared pool of Elite rerolls.

Each detachment containing bases with Elite (X) adds X rerolls to this pool, regardless of how many Elite bases the detachment contains.

During the battle, Elite rerolls may be spent to reroll dice rolled by your Elite bases. Before using them, declare the total number of dice that will be rerolled.

Only one Elite reroll may be used per base for each dice roll. Consequently, only one die from an assault roll may be rerolled.

Used Elite rerolls are removed from the army''s pool.

Elite rerolls may be used for To-Hit rolls, armour saving throws, assault rolls, Dodge rolls, and opportunity attacks made when an enemy disengages.' AS d
    UNION ALL SELECT 'Jump Packs' AS n, 'Bases equipped with Jump Packs may make short flights over terrain, buildings, and enemy troops.

They ignore enemy zones of control except those generated by bases with the Floater, Skimmer, or Jump Packs ability.

They also ignore terrain modifiers during their movement but cannot end their movement on Impassable terrain.

While using this ability to move over an obstacle, the base is considered to be at altitude.' AS d
    UNION ALL SELECT 'Hard to Hit' AS n, 'All ranged attacks targeting a base with this ability suffer a -1 To-Hit penalty.

This penalty does not apply to template weapons.' AS d
    UNION ALL SELECT 'Deep Strike (X)' AS n, 'The controlling player selects a point on the battlefield and places one base from the detachment at that point. The base then scatters X times, moving 3D6 cm for each scatter.

If the final point is outside the battlefield, within Impassable terrain, or within the zone of control of an enemy base of the same or a higher class, the detachment does not arrive. Another attempt may be made during the following turn.

Otherwise, place the first base as close as possible to the final arrival point. Place every other base in the detachment anywhere within 6 cm of the first base.

A detachment entering the battlefield in this manner cannot receive a First Fire order during the turn in which it arrives. It also loses 5 cm from its total available movement during that turn.' AS d
    UNION ALL SELECT 'HQ' AS n, 'When an HQ base is targeted by a shooting attack, its controlling player may select another base of the same class within 6 cm as the attack''s target instead.

This decision must be made before any saving throws are rolled. HQ protection does not function during an assault.' AS d
    UNION ALL SELECT 'Attached Character' AS n, 'At the beginning of the battle, an Attached Character must join a detachment. The character and the detachment are then treated as a single detachment.

The Attached Character must remain in coherency with the detachment, uses its Morale value, and adds its points cost to the detachment''s total cost.

Attached Characters do not occupy space in transports. A single detachment may include up to two Attached Characters.

An Attached Character gains the Movement characteristic of the detachment to which it is attached, and its movement-related special abilities.' AS d
    UNION ALL SELECT 'Psyker' AS n, 'During the Combat Phase, a Psyker may use both one psychic power and its conventional weapons.

Unless otherwise specified, a Psyker may use only one psychic power per turn.' AS d
    UNION ALL SELECT 'Psychic Save (X+)' AS n, 'A base with Psychic Save (X+) may use this saving throw against psychic powers.' AS d
    UNION ALL SELECT 'Psychic Abomination' AS n, 'Enemy Psykers within 25 cm of a base with this ability suffer a -1 penalty when using psychic powers. Bases with this ability gain a Psychic Save (2+).' AS d
    UNION ALL SELECT 'Damage (+X) in Assault' AS n, 'A weapon with this ability inflicts X additional hits after its base wins a duel, in addition to the normal hit.' AS d
    UNION ALL SELECT 'Damage (+X)' AS n, 'A weapon with this ability inflicts X additional hits against a base successfully hit by the weapon.' AS d
    UNION ALL SELECT 'Reflex Fire' AS n, 'A base with this ability does not suffer the normal -1 To-Hit penalty when performing Overwatch Fire.' AS d
    UNION ALL SELECT 'Sniper' AS n, 'When a base with the Sniper ability targets an HQ base, roll 1D6. On a result of 4+, the target cannot use its HQ ability against the Sniper''s attack.' AS d
    UNION ALL SELECT 'Infiltration' AS n, 'These bases are stealthy and capable of approaching the enemy before the battle begins.

After deployment, bases with this ability may move up to 25 cm. This movement cannot bring a base into an enemy zone of control and cannot be performed while the detachment is being transported.' AS d
    UNION ALL SELECT 'Fear' AS n, 'A Class 1–3 detachment that enters base-to-base contact with a base possessing this ability must pass a Morale Test or suffer a -2 AF penalty for the remainder of the turn.

This applies whether the Fear-causing base charges or is itself charged.

Fear has no effect against bases with the Fear or Terror ability.' AS d
    UNION ALL SELECT 'Antigrav' AS n, 'A base with Antigrav may make short flights over terrain, buildings, and enemy troops.

It ignores terrain movement penalties and enemy zones of control except those generated by bases with Floater, Skimmer, Jump Packs, or Antigrav.

It cannot end its movement on Impassable terrain. While moving over obstacles it is considered to be at altitude.' AS d
    UNION ALL SELECT 'Heavy Antigrav' AS n, 'Bases with Heavy Antigrav follow the rules for Antigrav / Heavy Skimmer but cannot perform Pop-up Attacks.' AS d
    UNION ALL SELECT 'Integral Armour' AS n, 'A base with Integral Armour does not use a hit-location chart. Every hit is resolved against the base as a whole.' AS d
    UNION ALL SELECT 'Flyer' AS n, 'Flyers may deploy on the battlefield or begin off-table (they cannot enter before Turn 2).

At altitude, Flyers move in a straight line with unlimited Movement (minimum 45 cm), ignore terrain and most zones of control, and use special assault and bombing rules. See the Flyer rules for further details.' AS d
    UNION ALL SELECT 'Interceptor' AS n, 'A detachment with this ability may perform Aerial Interceptions. See the Flyer rules for further details.' AS d
    UNION ALL SELECT 'Transport (X)' AS n, 'A base with Transport (X) may transport X Infantry bases.

Entering or leaving a transport costs the transported bases 5 cm of movement. When a base leaves a transport, place it in contact with the transporting base.' AS d
    UNION ALL SELECT 'Attached Transport' AS n, 'Attached Transports and the bases they transport are treated as a single detachment.' AS d
    UNION ALL SELECT 'Anti-Aircraft' AS n, 'These weapons operate independently and may be activated separately from a base''s other weapons.

If the base has a First Fire order, these weapons may perform Overwatch Fire against targets at altitude without suffering the usual To-Hit penalty. They may also perform Overwatch Fire while the base has an Advance order, but suffer the normal -1 To-Hit penalty.

Weapons with this ability always have a 360 degree firing arc and reduce a Flyer''s Protection save by 2.

When firing at targets that are not at altitude, these weapons function normally but suffer a -1 To-Hit penalty.' AS d
    UNION ALL SELECT 'Turret' AS n, 'A weapon with the Turret ability has a 360 degree firing arc.' AS d
    UNION ALL SELECT 'Template (X)' AS n, 'Templates have an area of effect and may therefore affect more than one target.

Any base whose centre is covered by a template may be hit, depending on the template weapon''s To-Hit roll.' AS d
    UNION ALL SELECT 'Close Defences (X+)' AS n, 'Every Class 1 or 2 base that engages, or is engaged by, a base with Close Defences suffers a hit on X+ with AP 0.

Resolve the attack when the bases make contact. Cover saves may be used against Close Defences.' AS d
    UNION ALL SELECT 'Wounds (X)' AS n, 'A base with this ability has X Wounds, allowing it to survive multiple injuries.

By default, a base has only one Wound.' AS d
    UNION ALL SELECT 'Terror' AS n, 'A detachment engaged in an assault by a base with the Terror ability must make a Morale Test with a -1 modifier.

If the test is failed, the detachment immediately receives a Fall Back order but does not make a Fall Back move.

A detachment attempting to engage a base with Terror must also pass a Morale Test with a -1 modifier or stop before entering the Terror-causing base''s zone of control.

Bases with Terror are immune to Terror.' AS d
    UNION ALL SELECT 'Bombing (X)' AS n, 'Flyers and Floating bases at altitude may drop X bombs during their movement. Resolve each attack immediately during the movement, following the normal shooting procedure.

Bombs cannot be dropped while the detachment has a Charge order and cannot affect targets at altitude.' AS d
    UNION ALL SELECT 'Agile' AS n, 'A Titan or Praetorian with this ability is not limited to a total of 90 degrees of turning during each turn.' AS d
    UNION ALL SELECT 'Dread (-X)' AS n, 'When activated during the Combat Phase, a base with this ability may force one enemy detachment with at least one base within 20 cm to make a Morale Test with a -X modifier.' AS d
    UNION ALL SELECT 'Dark Presence (-X / Y cm)' AS n, 'Enemy detachments with at least one base within Y cm of a base with this ability suffer a -X penalty to Morale Tests.' AS d
    UNION ALL SELECT 'Redeployment (X)' AS n, 'A base with this ability allows its controlling player to redeploy X detachments at the beginning of the battle.

After both players have finished deploying their armies, but before resolving Infiltration, the player may reposition X detachments according to the normal deployment rules.' AS d
    UNION ALL SELECT 'Leader' AS n, 'All allied detachments with at least one base within 12 cm of a base with this ability receive a +1 bonus to their AF.' AS d
    UNION ALL SELECT 'Master Strategist' AS n, 'An army containing a base with this ability receives two additional order counters that may be kept in reserve and assigned after normal orders have been revealed.' AS d
    UNION ALL SELECT 'Parry' AS n, 'A base with this ability ignores the first outnumbering die during an assault.

Consequently, the opposing side only begins receiving outnumbering dice when the base fights its third opponent.' AS d
    UNION ALL SELECT 'Entangle' AS n, 'When a base with this ability makes contact with an enemy base that has a hit-location chart, it may immobilise one of the enemy base''s weapons. The effects of that weapon are cancelled for the remainder of the turn.

If two opposing bases both possess such weapons, the abilities cancel one another and both weapons become entangled.' AS d
    UNION ALL SELECT 'Duellist' AS n, 'A base with this ability chooses the order in which its assault duels are resolved.' AS d
    UNION ALL SELECT 'Dodge (X+)' AS n, 'When a base with this ability loses Wounds in an assault, roll one die for each Wound lost. For each result of X+, the base does not lose that Wound.

Dodge may also be used against hits caused by Close Defences.' AS d
    UNION ALL SELECT 'Reduces Cover (X)' AS n, 'A weapon with this ability worsens the target''s cover save by X.' AS d
    UNION ALL SELECT 'Damages Buildings (AP -X / Y)' AS n, 'A weapon with this ability damages buildings. Buildings hit by the weapon suffer Y damage with Armour Penetration -X.' AS d
    UNION ALL SELECT 'Damages Buildings (AP -X / Y) in Assault' AS n, 'In all other respects, this ability functions in the same manner as Damages Buildings.' AS d
    UNION ALL SELECT 'First Strike (X)' AS n, 'A weapon with this ability may attack a base in contact with it immediately before an assault is resolved.

Resolve the attack after the assault has been selected for activation but before resolving anything else. It is treated as a shooting attack, but its To-Hit roll never suffers penalties and it ignores Shields.

The target may make a normal saving throw. Damage inflicted by First Strike attacks counts towards the final combat result.' AS d
    UNION ALL SELECT 'Subterranean Fire' AS n, 'Attacks with this ability ignore Energy Shields, Energy Fields, and Deflector Shields.

They have no effect against Skimmers or bases at altitude.

Against a base with a hit-location chart, Subterranean Fire always hits its lowest location, Location 1.' AS d
    UNION ALL SELECT 'Reroll Assault Dice' AS n, 'A base with this ability may reroll its assault dice. If it does so, it must reroll all of them.' AS d
) AS src ON src.n = sa.SpecialAbilityName
SET sa.Description = src.d;

INSERT INTO PsychicPower (PsychicPowerName, Description)
SELECT n, d FROM (
    SELECT 'Harbinger of Despair' AS n, '[Movement Phase, on activation]: The Cryptek gains the Fear and Dread (-1) abilities for the rest of the turn.' AS d
    UNION ALL SELECT 'Harbinger of Destruction' AS n, '[Combat Phase, Shooting]: The Cryptek makes an attack with a range of 60 cm, hitting on 3+ with AP -2.' AS d
    UNION ALL SELECT 'Harbinger of Eternity' AS n, '[Movement Phase, on activation]: The Cryptek gains the Reanimator ability for this turn.' AS d
    UNION ALL SELECT 'Meteor' AS n, '[Combat Phase, Shooting]: Place a Template (7.5 cm) at 45 cm and in Line of Sight. The template hits on 3+, AP -3, and Damages Buildings (AP -3/3).' AS d
    UNION ALL SELECT 'Time''s Arrow' AS n, '[Combat Phase, Shooting]: Choose a target at 45 cm and in Line of Sight. It is hit on 3+ with AP -4 and Damage (+1).' AS d
    UNION ALL SELECT 'Seismic Assault' AS n, '[Combat Phase, Shooting]: Place a Template (12 cm) at 45 cm and in Line of Sight. This template hits on 3+ with AP 0; the template has the Reduces Cover (-1) and Subterranean Fire abilities.' AS d
    UNION ALL SELECT 'Deadly Gas' AS n, '[Combat Phase, Shooting]: Place a Template (7.5 cm) at 45 cm and in Line of Sight of the Nightbringer. The template hits class 1 and 2 bases on 3+, otherwise on 5+. This attack is a Psychic Power.' AS d
    UNION ALL SELECT 'Voltaic Storm' AS n, '[Combat Phase, Shooting]: Choose an enemy detachment of class 3 or more at 45 cm and in Line of Sight of the Void Dragon. The detachment suffers 1D3 hits on 2+ with AP -3 that Reduce Cover (-3).' AS d
    UNION ALL SELECT 'World Pain' AS n, 'Passive permanent power. Enemy detachments within 20 cm of the Transcendent C''tan do not benefit from cover saves. This is a Psychic Power.' AS d
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM PsychicPower pp WHERE pp.PsychicPowerName = src.n
);

UPDATE PsychicPower pp
INNER JOIN (
    SELECT 'Harbinger of Despair' AS n, '[Movement Phase, on activation]: The Cryptek gains the Fear and Dread (-1) abilities for the rest of the turn.' AS d
    UNION ALL SELECT 'Harbinger of Destruction' AS n, '[Combat Phase, Shooting]: The Cryptek makes an attack with a range of 60 cm, hitting on 3+ with AP -2.' AS d
    UNION ALL SELECT 'Harbinger of Eternity' AS n, '[Movement Phase, on activation]: The Cryptek gains the Reanimator ability for this turn.' AS d
    UNION ALL SELECT 'Meteor' AS n, '[Combat Phase, Shooting]: Place a Template (7.5 cm) at 45 cm and in Line of Sight. The template hits on 3+, AP -3, and Damages Buildings (AP -3/3).' AS d
    UNION ALL SELECT 'Time''s Arrow' AS n, '[Combat Phase, Shooting]: Choose a target at 45 cm and in Line of Sight. It is hit on 3+ with AP -4 and Damage (+1).' AS d
    UNION ALL SELECT 'Seismic Assault' AS n, '[Combat Phase, Shooting]: Place a Template (12 cm) at 45 cm and in Line of Sight. This template hits on 3+ with AP 0; the template has the Reduces Cover (-1) and Subterranean Fire abilities.' AS d
    UNION ALL SELECT 'Deadly Gas' AS n, '[Combat Phase, Shooting]: Place a Template (7.5 cm) at 45 cm and in Line of Sight of the Nightbringer. The template hits class 1 and 2 bases on 3+, otherwise on 5+. This attack is a Psychic Power.' AS d
    UNION ALL SELECT 'Voltaic Storm' AS n, '[Combat Phase, Shooting]: Choose an enemy detachment of class 3 or more at 45 cm and in Line of Sight of the Void Dragon. The detachment suffers 1D3 hits on 2+ with AP -3 that Reduce Cover (-3).' AS d
    UNION ALL SELECT 'World Pain' AS n, 'Passive permanent power. Enemy detachments within 20 cm of the Transcendent C''tan do not benefit from cover saves. This is a Psychic Power.' AS d
) AS src ON src.n = pp.PsychicPowerName
SET pp.Description = src.d;

INSERT INTO SpecialRule (CodexId, SpecialRuleName, Description)
SELECT @codexId, n, d FROM (
    SELECT 'Reserve' AS n, 'The Necrons strike suddenly and vanish without leaving a trace. Their mastery of teleportation gives them tactical opportunities for redeployment and an optimal distribution of their forces.

During army deployment, any detachment may be placed in Reserve so long as it has a means of arriving on the battlefield, such as Portals large enough for it or special rules or abilities such as Deep Strike. Detachments in Reserve receive orders normally, but may activate only to join the field during their activation.

A detachment in Reserve that no longer has a means of entering the battlefield is considered destroyed.' AS d
    UNION ALL SELECT 'Phase Out' AS n, 'Necron commanders follow their own patterns and sometimes vanish without warning. When a Necron detachment with several bases is Broken, it must make a Phase Out roll. To do so, roll 1D6: on a 2+ nothing happens; otherwise they disappear from the battlefield and are considered destroyed. If there is a character attached to the detachment, this roll automatically succeeds.' AS d
    UNION ALL SELECT 'Engines of Destruction' AS n, 'Only one Engine of Destruction is allowed in a Necron army per 5000 points. The Engines of Destruction are the Abattoir and the Aeonic Orb.' AS d
    UNION ALL SELECT 'Scarabs' AS n, 'Canoptek Scarabs are small beetle-like robots, constantly repairing damaged Necrons.

Scarab tokens may be used by any Necron base of class 1 or 2. Each token may be used in two ways.

Assault: A class 1 or 2 base directs the Scarabs that attack the enemy. In addition to its ranged weapons, the base gains a one-use shot that uses a Template (7.5 cm), hits on 5+, has a range of 20 cm, no AP, and the Reduces Cover (-1) ability. A base may benefit from only one Scarab token per turn in this way.

Repair: when a base makes a Reanimation Protocols roll, you may use a Scarab token to improve the base''s chance of success by 2.' AS d
    UNION ALL SELECT 'Necrons Titan Hit Location Chart' AS n, '### Abattoir

| D6 | Location |
| --- | --- |
| 1 | Harvesters |
| 2–3 | Hull (Abattoir) |
| 4 | Portals (Abattoir) |
| 5 | Crystal |
| 6 | Player''s choice |

### War Barge

| D6 | Location Front / Rear |
| --- | --- |
| 1 | Antigrav Generator |
| 2–3 | Portal (War Barge) / Hull |
| 4 | Hull (front) / Reactor (rear) |
| 5 | Bridge |
| 6 | Player''s choice |

### Aeonic Orb

| D6 | Location |
| --- | --- |
| 1 | Base |
| 2 | Hull |
| 3 | Weapon |
| 4 | Fire Control |
| 5 | Power Rings |
| 6 | Player''s choice |

### Tomb Guardian

| D6 | Location Front / Rear |
| --- | --- |
| 1–2 | Legs |
| 3 | Hull |
| 4 | Weapon |
| 5 | Head (front) / Reactor (rear) |
| 6 | Player''s choice |' AS d
    UNION ALL SELECT 'Necrons Titan Damage Effects' AS n, 'Damage effects are progressive: the first damage to a location applies the first effect, and further damage applies the following effects on the list.

### Hull

| Hits | Effect |
| --- | --- |
| 1 | — |
| 2–3 | 1 additional damage |
| 4+ | 2 additional damage |

### Weapon

| Hits | Effect |
| --- | --- |
| 1 | Weapon Damaged (Repair on 4+) |
| 2 | Weapon Destroyed |
| 3+ | Damage to the Hull |

### Portal (Abattoir)

| Hits | Effect |
| --- | --- |
| 1 | 1 Portal Destroyed |
| 2 | 1 Portal Destroyed |
| 3 | 1 Portal Destroyed, 1 additional damage |
| 4 | 1 Portal Destroyed, 1 additional damage |
| 5+ | Damage to the Hull |

### Harvesters

| Hits | Effect |
| --- | --- |
| 1 | — |
| 2–5 | 1 Harvester Damaged (Repair on 4+) |
| 6+ | Damage to the Hull |

### Leg / Antigrav Generator / Base / Fire Control

| Hits | Effect |
| --- | --- |
| 1 | -5 cm of base movement (Repair on 4+) |
| 2 | an additional -5 cm of base movement (Repair on 4+) (from this damage, if the titan is destroyed it falls) |
| 3 | Immobilised, 1 additional damage |
| 4+ | Damage to the Hull |

### Hull (Abattoir)

| Hits | Effect |
| --- | --- |
| 1–2 | — |
| 3–4 | 1 additional damage |
| 5+ | 2 additional damage |

### Head / Bridge

| Hits | Effect |
| --- | --- |
| 1 | -1D6 to AF (Repair on 4+) |
| 2 | May receive an order only on a 4+ (Repair on 4+), 1 additional damage |
| 3+ | Damage to the Hull |

### Crystal

| Hits | Effect |
| --- | --- |
| 1 | -2 to AF in assault (Repair on 4+) |
| 2 | Total movement reduced by 5 cm (Repair on 4+) |
| 3 | Destroyed, total movement reduced by 5 cm |
| 4+ | Damage to the Hull |

### Portal (War Barge)

| Hits | Effect |
| --- | --- |
| 1 | Reduce to 4 the number of detachments that may cross the Portal |
| 2 | Reduce to 2 the number of detachments that may cross the Portal |
| 3 | Reduce to 1 the number of detachments that may cross the Portal, 1 additional damage |
| 4+ | Portal destroyed, Damage to the Hull |

### Reactor

| Hits | Effect |
| --- | --- |
| 1 | 1 additional damage (from this damage, if the titan is destroyed it explodes) |
| 2 | 1 additional damage |
| 3+ | Reactor severely damaged, 1D3 additional damage |

### Power Rings

| Hits | Effect |
| --- | --- |
| 1 | The Solar Flare can no longer fire (Repair on 4+) |
| 2 | Gains one fewer plasma token per turn (Repair on 4+) |
| 3 | Destroyed, gains one fewer plasma token per turn, 1 additional damage |
| 4+ | Damage to the Hull |' AS d
) AS src;

-- Figure PNGs are stored in Base.Image; run upload_codex_images.py Necrons for new units.
SET @cryptek := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Cryptek');
SET @flayedOne := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Flayed One');
SET @hexmarkDestroyer := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Hexmark Destroyer');
SET @skorpekhDestroyer := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Skorpekh Destroyer');
SET @lychguard := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Lychguard');
SET @necronWarriors := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Necron Warriors');
SET @immortals := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Immortals');
SET @overlord := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Overlord');
SET @pariah := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Pariah');
SET @triarchPraetorians := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Triarch Praetorians');
SET @flayedLord := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Flayed Lord');
SET @necronLord := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Necron Lord');
SET @deathmark := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Deathmark');
SET @skorpekhLord := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Skorpekh Lord');
SET @destroyer := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Destroyer');
SET @heavyDestroyer := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Heavy Destroyer');
SET @canoptekAcanthrites := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Canoptek Acanthrites');
SET @destroyerLord := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Destroyer Lord');
SET @canoptekSpyderAssault := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Canoptek Spyder (Assault)');
SET @canoptekSpyderSupport := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Canoptek Spyder (Support)');
SET @ophydianDestroyer := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Ophydian Destroyer');
SET @tombBlades := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Tomb Blades');
SET @canoptekWraiths := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Canoptek Wraiths');
SET @triarchStalker := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Triarch Stalker');
SET @canoptekDoomstalker := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Canoptek Doomstalker');
SET @canoptekReanimator := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Canoptek Reanimator');
SET @doomsdayArk := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Doomsday Ark');
SET @ghostArk := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Ghost Ark');
SET @tesseractArk := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Tesseract Ark');
SET @catacombCommandBarge := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Catacomb Command Barge');
SET @annihilationBarge := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Annihilation Barge');
SET @doomScythe := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Doom Scythe');
SET @nightScythe := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Night Scythe');
SET @nightShroud := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Night Shroud');
SET @deceiver := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Deceiver');
SET @tesseractVault := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Tesseract Vault');
SET @nightbringer := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Nightbringer');
SET @transcendentCTan := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Transcendent C''tan');
SET @voidDragon := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Void Dragon');
SET @tombGolem := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Tomb Golem');
SET @canoptekTombSentinel := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Canoptek Tomb Sentinel');
SET @monolith := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Monolith');
SET @doomsdayMonolith := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Doomsday Monolith');
SET @seraptekHeavyConstruct := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Seraptek Heavy Construct');
SET @pylon := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Pylon');
SET @obelisk := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Obelisk');
SET @abattoir := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Abattoir');
SET @warBarge := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'War Barge');
SET @aeonicOrb := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Aeonic Orb');
SET @tombGuardian := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Tomb Guardian');
SET @scarabTokens := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Scarab Tokens');

INSERT INTO Weapon (
    BaseId, `Name`, `Range`, Dice, ToHit, ArmourPenetration, IsTitanWeapon
) VALUES
    (@cryptek, 'Eldritch Lance', '60 cm', '1', '4+', '-2', 0),
    (@cryptek, 'Staff of Light', '30 cm', '2', '4+', '-2', 0),
    (@flayedOne, 'Claws', '--', '--', '--', '--', 0),
    (@hexmarkDestroyer, 'Enmitic Disintegrator', '20 cm', '2', '4+', '0', 0),
    (@skorpekhDestroyer, 'Hyperphase Blade', '--', '--', '--', '--', 0),
    (@lychguard, 'Hyperphase Blade', '--', '--', '--', '--', 0),
    (@necronWarriors, 'Gauss Flayer', '45 cm', '1', '5+', '-1', 0),
    (@immortals, 'Gauss Blaster', '60 cm', '2', '5+', '-1', 0),
    (@overlord, 'Ancient Staff of Light', '45 cm', '2', '4+', '-2', 0),
    (@pariah, 'Warscythes', '45 cm', '1', '5+', '-1', 0),
    (@triarchPraetorians, 'Rod of Covenant', '20 cm', '1', '4+', '-2', 0),
    (@flayedLord, 'Claws', '--', '--', '--', '--', 0),
    (@necronLord, 'Staff of Light', '30 cm', '2', '4+', '-2', 0),
    (@deathmark, 'Synaptic Disintegrator', '45 cm', '1', '4+', '-1', 0),
    (@skorpekhLord, 'Enmitic Annihilator', '20 cm', '2', '4+', '0', 0),
    (@destroyer, 'Gauss Cannon', '45 cm', '1', '4+', '-1', 0),
    (@heavyDestroyer, 'Heavy Gauss Cannon', '60 cm', '2', '4+', '-2', 0),
    (@canoptekAcanthrites, 'Cutting Beam', '20 cm', '1', '4+', '-2', 0),
    (@destroyerLord, 'Staff of Light', '30 cm', '2', '4+', '-2', 0),
    (@canoptekSpyderAssault, 'Claws', '--', '--', '--', '--', 0),
    (@canoptekSpyderSupport, 'Twin Particle Beamer', '20 cm', '1', '4+', '-2', 0),
    (@ophydianDestroyer, 'Hyperphase Blade', '--', '--', '--', '--', 0),
    (@tombBlades, 'Twin Tesla Carbines', '30 cm', '2', '4+', '0', 0),
    (@canoptekWraiths, 'Whip Coils', '--', '--', '--', '--', 0),
    (@triarchStalker, 'Heat Ray', '45 cm', '1', '4+', '-2', 0),
    (@canoptekDoomstalker, 'Doomsday Blaster', '45 cm', '1', '3+', '-2', 0),
    (@canoptekDoomstalker, 'Gauss Blaster', '45 cm', '2', '5+', '0', 0),
    (@canoptekReanimator, 'Gauss Atomiser', '45 cm', '1', '4+', '-1', 0),
    (@doomsdayArk, 'Doomsday Cannon — Diffuse', '90 cm', 'Template', '4+', '-2', 0),
    (@doomsdayArk, 'Doomsday Cannon — Concentrated', '90 cm', '1', '3+', '-3', 0),
    (@doomsdayArk, 'Doomsday Cannon — Advance', '75 cm', '1', '4+', '-3', 0),
    (@ghostArk, 'Gauss Flayer Array', '30 cm', '1', '4+', '0', 0),
    (@tesseractArk, 'Singularity Chamber — Concentrated', '45 cm', '1', '3+', '-3', 0),
    (@tesseractArk, 'Singularity Chamber — Diffuse', '45 cm', '3', '4+', '0', 0),
    (@tesseractArk, 'Tesla Cannon', '45 cm', '1', '5+', '0', 0),
    (@catacombCommandBarge, 'Tesla Cannon', '45 cm', '1', '4+', '-1', 0),
    (@annihilationBarge, 'Tesla Destructors', '45 cm', '2', '4+', '-1', 0),
    (@annihilationBarge, 'Tesla Cannon', '45 cm', '1', '5+', '0', 0),
    (@doomScythe, 'Death Ray', '20 cm', '1', '3+', '-2', 0),
    (@doomScythe, 'Twin Tesla Destructor', '30 cm', '2', '4+', '-1', 0),
    (@nightScythe, 'Twin Tesla Destructor', '30 cm', '2', '4+', '-1', 0),
    (@nightShroud, 'Twin Tesla Destructor', '30 cm', '2', '3+', '-1', 0),
    (@nightShroud, 'Death Sphere', 'Bomb', 'Template', '3+', '-3', 0),
    (@deceiver, 'Star-God Fists', '--', '--', '--', '--', 0),
    (@tesseractVault, 'Tesla Sphere', '45 cm', '6', '4+', '0', 0),
    (@nightbringer, 'Scythe of the Nightbringer', '--', '--', '--', '--', 0),
    (@transcendentCTan, 'Crackling Tendrils', '--', '--', '--', '--', 0),
    (@voidDragon, 'Spear of the Void Dragon', '--', '--', '--', '--', 0),
    (@tombGolem, 'Eldritch Cannon', '45 cm', '2', '4+', '-2', 0),
    (@canoptekTombSentinel, 'Exile Cannon', '20 cm', '1', '3+', '-3', 0),
    (@monolith, 'Particle Whip — Concentrated', '45 cm', '1', '3+', '-3', 0),
    (@monolith, 'Particle Whip — Diffuse', '45 cm', '3', '4+', '0', 0),
    (@monolith, 'Gauss Flayer', '20 cm', '5', '5+', '0', 0),
    (@doomsdayMonolith, 'Fission Obliterator', '75 cm', 'Template', '4+', '-1', 0),
    (@doomsdayMonolith, 'Gauss Flayer', '20 cm', '5', '5+', '0', 0),
    (@seraptekHeavyConstruct, 'Gauss Obliterator', '75 cm', '2', '3+', '-3', 0),
    (@seraptekHeavyConstruct, 'Singularity Generator', '30 cm', '6', '4+', '0', 0),
    (@pylon, 'Particle Accelerator — AA', '100 cm', '2', '3+', '-3', 0),
    (@pylon, 'Particle Accelerator — Ground', '100 cm', '2', '3+', '-3', 0),
    (@obelisk, 'Tesla Sphere', '45 cm', '6', '4+', '0', 0),
    (@abattoir, '4 Harvesters — Shooting', '20 cm', '4', '4+', '-1', 0),
    (@abattoir, '4 Harvesters — Assault', '--', '--', '--', '--', 0),
    (@abattoir, '4 Scarab Swarms', '20 cm', '3', '5+', '0', 0),
    (@warBarge, 'Gauss Cannons', '45 cm', '6', '4+', '-1', 0),
    (@aeonicOrb, 'Solar Flare — Burst (1 plasma token)', '75 cm', '2', '3+', '-4', 0),
    (@aeonicOrb, 'Solar Flare — Light (2 plasma tokens)', '100 cm', '1', '2+', '-5', 0),
    (@aeonicOrb, 'Solar Flare — Powerful (3 plasma tokens)', '120 cm', '2', '2+', '-5', 0),
    (@aeonicOrb, 'Solar Burner', '45 cm', '2', '4+', '-3', 0),
    (@tombGuardian, 'Gauss Blaster', '75 cm', '5', '4+', '-1', 1),
    (@tombGuardian, 'Annihilation Crystal — Concentrated', '75 cm', '1', '3+', '-3', 1),
    (@tombGuardian, 'Annihilation Crystal — Saturation', '75 cm', 'Template', '3+', '-1', 1),
    (@tombGuardian, 'Phase Claw — Shooting', '30 cm', '2', '3+', '-2', 1),
    (@tombGuardian, 'Phase Claw — Assault', '--', '--', '--', '--', 1),
    (@tombGuardian, 'Hyperphase Blade — Shooting', '30 cm', '2', '3+', '-2', 1),
    (@tombGuardian, 'Hyperphase Blade — Assault', '--', '--', '--', '--', 1),
    (@tombGuardian, 'Conversion Beam (0–20 cm)', '0–20 cm', '2', '5+', '-2', 1),
    (@tombGuardian, 'Conversion Beam (21–44 cm)', '21–44 cm', '2', '4+', '-3', 1),
    (@tombGuardian, 'Conversion Beam (45–75 cm)', '45–75 cm', '2', '3+', '-4', 1),
    (@tombGuardian, 'Disintegrator Beam', '20 cm', '3', '3+', '-3', 1);

INSERT INTO BaseSpecialAbility (BaseId, SpecialAbilityId, AbilityValue)
SELECT b.BaseId, sa.SpecialAbilityId, b.AbilityValue
FROM (
    SELECT @cryptek AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @cryptek AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @cryptek AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @cryptek AS BaseId, 'Resurrection Orb' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @cryptek AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @cryptek AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @flayedOne AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @flayedOne AS BaseId, 'Fear' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @flayedOne AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @flayedOne AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @flayedOne AS BaseId, 'Outcasts' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hexmarkDestroyer AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @hexmarkDestroyer AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @skorpekhDestroyer AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @skorpekhDestroyer AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @skorpekhDestroyer AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @lychguard AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @lychguard AS BaseId, 'Dodge (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @lychguard AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @lychguard AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @necronWarriors AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @necronWarriors AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @immortals AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @immortals AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @overlord AS BaseId, 'Resurrection Orb' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @overlord AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @overlord AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @overlord AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @overlord AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @overlord AS BaseId, 'My Will Be Done' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @overlord AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @overlord AS BaseId, 'Master Strategist' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pariah AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @pariah AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pariah AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @pariah AS BaseId, 'Psychic Abomination' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pariah AS BaseId, 'Soulless' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @triarchPraetorians AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @triarchPraetorians AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @triarchPraetorians AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @triarchPraetorians AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @flayedLord AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @flayedLord AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @flayedLord AS BaseId, 'Outcasts' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @flayedLord AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @flayedLord AS BaseId, 'Fear' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @flayedLord AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @flayedLord AS BaseId, 'Resurrection Orb' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @flayedLord AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @necronLord AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @necronLord AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @necronLord AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @necronLord AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @necronLord AS BaseId, 'Resurrection Orb' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @necronLord AS BaseId, 'Leader' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deathmark AS BaseId, 'Deep Strike (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @deathmark AS BaseId, 'Sniper' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deathmark AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deathmark AS BaseId, 'Deathmark' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deathmark AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @skorpekhLord AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @skorpekhLord AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @skorpekhLord AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @skorpekhLord AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @skorpekhLord AS BaseId, 'Resurrection Orb' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @skorpekhLord AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @destroyer AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @destroyer AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @destroyer AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @heavyDestroyer AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @heavyDestroyer AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @heavyDestroyer AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekAcanthrites AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekAcanthrites AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @canoptekAcanthrites AS BaseId, 'Hard to Hit' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekAcanthrites AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @destroyerLord AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @destroyerLord AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @destroyerLord AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @destroyerLord AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @destroyerLord AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @destroyerLord AS BaseId, 'Resurrection Orb' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @destroyerLord AS BaseId, 'Leader' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekSpyderAssault AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekSpyderAssault AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @canoptekSpyderAssault AS BaseId, 'Scarab Generator' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekSpyderAssault AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekSpyderSupport AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekSpyderSupport AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @canoptekSpyderSupport AS BaseId, 'Scarab Generator' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekSpyderSupport AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @ophydianDestroyer AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @ophydianDestroyer AS BaseId, 'Deep Strike (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @ophydianDestroyer AS BaseId, 'Hard to Hit' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @ophydianDestroyer AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @ophydianDestroyer AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tombBlades AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tombBlades AS BaseId, 'Hard to Hit' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tombBlades AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tombBlades AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @tombBlades AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekWraiths AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekWraiths AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @canoptekWraiths AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @triarchStalker AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @triarchStalker AS BaseId, 'Targeting Relay' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @triarchStalker AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekDoomstalker AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @canoptekDoomstalker AS BaseId, 'Reflex Fire' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekDoomstalker AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekReanimator AS BaseId, 'Reanimator' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekReanimator AS BaseId, 'Reanimation Protocols (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @canoptekReanimator AS BaseId, 'Reflex Fire' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekReanimator AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomsdayArk AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomsdayArk AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @ghostArk AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @ghostArk AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @ghostArk AS BaseId, 'Transport (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @ghostArk AS BaseId, 'Attached Transport' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @ghostArk AS BaseId, 'Repair Platform' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tesseractArk AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tesseractArk AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @catacombCommandBarge AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @catacombCommandBarge AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @catacombCommandBarge AS BaseId, 'Leader' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @catacombCommandBarge AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @catacombCommandBarge AS BaseId, 'Resurrection Orb' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @catacombCommandBarge AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @annihilationBarge AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @annihilationBarge AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomScythe AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomScythe AS BaseId, 'Dodge (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @doomScythe AS BaseId, 'Interceptor' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomScythe AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomScythe AS BaseId, 'Flyer' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightScythe AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightScythe AS BaseId, 'Dodge (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @nightScythe AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightScythe AS BaseId, 'Interceptor' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightScythe AS BaseId, 'Invasion Beams' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightScythe AS BaseId, 'Flyer' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightShroud AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightShroud AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightShroud AS BaseId, 'Flyer' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Containment Failure' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Psychic Save (X+)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Wounds (X)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Reinforced Necrodermis' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Dark Presence (-X / Y cm)' AS AbilityName, '2, 20' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Dread (-X)' AS AbilityName, '0' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Redeployment (X)' AS AbilityName, '1D3' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Containment Failure' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Psychic Save (X+)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Wounds (X)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Reinforced Necrodermis' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Containment Failure' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Psychic Save (X+)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Wounds (X)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Reinforced Necrodermis' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Containment Failure' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Psychic Save (X+)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Wounds (X)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Reinforced Necrodermis' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Duellist' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Close Defences (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Parry' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Containment Failure' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Psychic Save (X+)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Wounds (X)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Reinforced Necrodermis' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Absorption' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tombGolem AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @tombGolem AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @tombGolem AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekTombSentinel AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekTombSentinel AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @canoptekTombSentinel AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @canoptekTombSentinel AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @canoptekTombSentinel AS BaseId, 'Deep Strike (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @monolith AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @monolith AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @monolith AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @monolith AS BaseId, 'Heavy Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @monolith AS BaseId, 'Portal' AS AbilityName, '2 class 1 detachments/turn' AS AbilityValue
    UNION ALL SELECT @monolith AS BaseId, 'Deep Strike (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @doomsdayMonolith AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomsdayMonolith AS BaseId, 'Wounds (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @doomsdayMonolith AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomsdayMonolith AS BaseId, 'Heavy Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomsdayMonolith AS BaseId, 'Portal' AS AbilityName, '2 class 1 detachments/turn' AS AbilityValue
    UNION ALL SELECT @doomsdayMonolith AS BaseId, 'Deep Strike (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @seraptekHeavyConstruct AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @seraptekHeavyConstruct AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @seraptekHeavyConstruct AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pylon AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pylon AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @pylon AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pylon AS BaseId, 'Deep Strike (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @obelisk AS BaseId, 'Heavy Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @obelisk AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @obelisk AS BaseId, 'Wounds (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @obelisk AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @obelisk AS BaseId, 'Anti-Gravitic Matrix' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @obelisk AS BaseId, 'Deep Strike (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Wounds (X)' AS AbilityName, '9' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Agile' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Reinforced Necrodermis' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Heavy Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Engine of Destruction' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Organic Metal (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Deep Strike (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, 'Portal' AS AbilityName, '4× class 1–2, 1 detachment/turn each' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Wounds (X)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Agile' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Reinforced Necrodermis' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Heavy Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Organic Metal (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Deep Strike (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Dimensional Translocation' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Portal' AS AbilityName, '5 class 1–3 detachments/turn' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Wounds (X)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Agile' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Reinforced Necrodermis' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Heavy Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Engine of Destruction' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Aeonic Orb' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Organic Metal (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Wounds (X)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Inorganic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Reinforced Necrodermis' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Agile' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Heavy Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Organic Metal (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @scarabTokens AS BaseId, 'Scarab Tokens' AS AbilityName, '' AS AbilityValue
) AS b
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = b.AbilityName;

INSERT INTO BasePsychicPower (BaseId, PsychicPowerId, AbilityValue)
SELECT b.BaseId, pp.PsychicPowerId, b.AbilityValue
FROM (
    SELECT @cryptek AS BaseId, 'Harbinger of Despair' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @cryptek AS BaseId, 'Harbinger of Destruction' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @cryptek AS BaseId, 'Harbinger of Eternity' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Meteor' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Time''s Arrow' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @deceiver AS BaseId, 'Seismic Assault' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Meteor' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Time''s Arrow' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @tesseractVault AS BaseId, 'Seismic Assault' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Meteor' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Time''s Arrow' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Seismic Assault' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @nightbringer AS BaseId, 'Deadly Gas' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Meteor' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Time''s Arrow' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'Seismic Assault' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @transcendentCTan AS BaseId, 'World Pain' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Meteor' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Time''s Arrow' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Seismic Assault' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @voidDragon AS BaseId, 'Voltaic Storm' AS PowerName, '' AS AbilityValue
) AS b
INNER JOIN PsychicPower pp ON pp.PsychicPowerName = b.PowerName;

INSERT INTO WeaponSpecialAbility (WeaponId, SpecialAbilityId, AbilityValue)
SELECT w.WeaponId, sa.SpecialAbilityId, src.AbilityValue
FROM (
    SELECT @hexmarkDestroyer AS BaseId, 'Enmitic Disintegrator' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @triarchStalker AS BaseId, 'Heat Ray' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @doomsdayArk AS BaseId, 'Doomsday Cannon — Diffuse' AS WeaponName, 'Doomsday Cannon' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomsdayArk AS BaseId, 'Doomsday Cannon — Diffuse' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @doomsdayArk AS BaseId, 'Doomsday Cannon — Concentrated' AS WeaponName, 'Doomsday Cannon' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomsdayArk AS BaseId, 'Doomsday Cannon — Concentrated' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @doomsdayArk AS BaseId, 'Doomsday Cannon — Advance' AS WeaponName, 'Doomsday Cannon' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightShroud AS BaseId, 'Death Sphere' AS WeaponName, 'Bombing (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @nightShroud AS BaseId, 'Death Sphere' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @monolith AS BaseId, 'Particle Whip — Concentrated' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @monolith AS BaseId, 'Particle Whip — Diffuse' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @monolith AS BaseId, 'Gauss Flayer' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomsdayMonolith AS BaseId, 'Fission Obliterator' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @doomsdayMonolith AS BaseId, 'Fission Obliterator' AS WeaponName, 'Template (X)' AS AbilityName, '12 cm' AS AbilityValue
    UNION ALL SELECT @doomsdayMonolith AS BaseId, 'Fission Obliterator' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @doomsdayMonolith AS BaseId, 'Gauss Flayer' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @seraptekHeavyConstruct AS BaseId, 'Gauss Obliterator' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @seraptekHeavyConstruct AS BaseId, 'Singularity Generator' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pylon AS BaseId, 'Particle Accelerator — AA' AS WeaponName, 'Anti-Aircraft' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pylon AS BaseId, 'Particle Accelerator — AA' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @pylon AS BaseId, 'Particle Accelerator — Ground' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @obelisk AS BaseId, 'Tesla Sphere' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, '4 Harvesters — Shooting' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, '4 Harvesters — Shooting' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, '4 Harvesters — Assault' AS WeaponName, 'Harvesters — Assault' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, '4 Scarab Swarms' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @abattoir AS BaseId, '4 Scarab Swarms' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @warBarge AS BaseId, 'Gauss Cannons' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Solar Flare — Light (2 plasma tokens)' AS WeaponName, 'Damage (+X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Solar Flare — Light (2 plasma tokens)' AS WeaponName, 'Damages Buildings (AP -X / Y)' AS AbilityName, '5,3' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Solar Flare — Powerful (3 plasma tokens)' AS WeaponName, 'Damage (+X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Solar Flare — Powerful (3 plasma tokens)' AS WeaponName, 'Damages Buildings (AP -X / Y)' AS AbilityName, '5,3' AS AbilityValue
    UNION ALL SELECT @aeonicOrb AS BaseId, 'Solar Burner' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Annihilation Crystal — Concentrated' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Annihilation Crystal — Saturation' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Annihilation Crystal — Saturation' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Phase Claw — Assault' AS WeaponName, 'Reroll Assault Dice' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Phase Claw — Assault' AS WeaponName, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Phase Claw — Assault' AS WeaponName, 'Damages Buildings (AP -X / Y) in Assault' AS AbilityName, '5,3' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Phase Claw — Assault' AS WeaponName, 'First Strike (X)' AS AbilityName, '1/2+/AP -5' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Phase Claw — Assault' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Hyperphase Blade — Assault' AS WeaponName, 'Damage (+X) in Assault' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Hyperphase Blade — Assault' AS WeaponName, 'Damages Buildings (AP -X / Y) in Assault' AS AbilityName, '4,3' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Hyperphase Blade — Assault' AS WeaponName, 'First Strike (X)' AS AbilityName, '1/2+/AP -4' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Hyperphase Blade — Assault' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @tombGuardian AS BaseId, 'Disintegrator Beam' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
) AS src
INNER JOIN Weapon w ON w.BaseId = src.BaseId AND w.`Name` = src.WeaponName
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = src.AbilityName;

INSERT INTO TitanWeapon (
    CodexId, WeaponName, PointsCost, Notes, IsAssault, LimitPerTitan
) VALUES
    (@codexId, 'Gauss Blaster', 0, '75 cm, 5 dice, 4+, AP -1.', 0, 0),
    (@codexId, 'Annihilation Crystal', 0, 'Choose Concentrated (Damage +1) or Saturation (Template 7.5 cm).', 0, 0),
    (@codexId, 'Phase Claw', 0, 'Assault weapon: choose shooting, reroll assault + Damage +1, buildings, or First Strike.', 1, 0),
    (@codexId, 'Hyperphase Blade', 0, 'Assault weapon: choose shooting, +1D6 AF + Damage +2, buildings, or First Strike.', 1, 0),
    (@codexId, 'Conversion Beam', 0, 'AP and To-Hit scale with range band (0–20 / 21–44 / 45–75 cm).', 0, 0),
    (@codexId, 'Disintegrator Beam', 0, '20 cm, 3 dice, 3+, AP -3, Damage (+1).', 0, 0)
ON DUPLICATE KEY UPDATE
    PointsCost = VALUES(PointsCost),
    Notes = VALUES(Notes),
    IsAssault = VALUES(IsAssault),
    LimitPerTitan = VALUES(LimitPerTitan);

INSERT INTO Detachment (
    CodexId, DetachmentName, CommandPoints, `Class`
) VALUES
    (@codexId, 'Overlord Detachment', 0, 1),
    (@codexId, 'Deceiver Detachment', 0, 4),
    (@codexId, 'Nightbringer Detachment', 0, 4),
    (@codexId, 'Void Dragon Detachment', 0, 4),
    (@codexId, 'Transcendent C''tan Detachment', 0, 4),
    (@codexId, 'Tesseract Vault Detachment', 0, 4),
    (@codexId, 'Abattoir Detachment', 0, 6),
    (@codexId, 'War Barge Detachment', 0, 5),
    (@codexId, 'Tomb Guardian Detachment', 0, 5),
    (@codexId, 'Aeonic Orb Detachment', 0, 5),
    (@codexId, 'Necron Lord and Retinue Detachment', 0, 1),
    (@codexId, 'Cryptek Detachment', 0, 1),
    (@codexId, 'Catacomb Command Barge Detachment', 0, 3),
    (@codexId, 'Flayed Ones Detachment', 0, 1),
    (@codexId, 'Hexmark Destroyer Detachment', 0, 1),
    (@codexId, 'Skorpekh Destroyer Detachment', 0, 1),
    (@codexId, 'Necron Warriors Detachment', 0, 1),
    (@codexId, 'Immortals Detachment', 0, 1),
    (@codexId, 'Pariah Detachment', 0, 1),
    (@codexId, 'Triarch Praetorians Detachment', 0, 1),
    (@codexId, 'Deathmark Detachment', 0, 1),
    (@codexId, 'Canoptek Spyder (Assault) Detachment', 0, 2),
    (@codexId, 'Canoptek Spyder (Support) Detachment', 0, 2),
    (@codexId, 'Canoptek Acanthrites Detachment', 0, 2),
    (@codexId, 'Destroyer Detachment', 0, 2),
    (@codexId, 'Heavy Destroyer Detachment', 0, 2),
    (@codexId, 'Ophydian Destroyer Detachment', 0, 2),
    (@codexId, 'Canoptek Wraiths Detachment', 0, 2),
    (@codexId, 'Tomb Blades Detachment', 0, 2),
    (@codexId, 'Canoptek Doomstalker Detachment', 0, 2),
    (@codexId, 'Canoptek Reanimator Detachment', 0, 2),
    (@codexId, 'Triarch Stalker Detachment', 0, 2),
    (@codexId, 'Doomsday Ark Detachment', 0, 3),
    (@codexId, 'Tesseract Ark Detachment', 0, 3),
    (@codexId, 'Annihilation Barge Detachment', 0, 3),
    (@codexId, 'Doom Scythe Detachment', 0, 3),
    (@codexId, 'Night Scythe Detachment', 0, 3),
    (@codexId, 'Night Shroud Detachment', 0, 3),
    (@codexId, 'Tomb Golem Detachment', 0, 4),
    (@codexId, 'Canoptek Tomb Sentinel Detachment', 0, 4),
    (@codexId, 'Monolith Detachment', 0, 4),
    (@codexId, 'Doomsday Monolith Detachment', 0, 4),
    (@codexId, 'Obelisk Detachment', 0, 4),
    (@codexId, 'Pylon Detachment', 0, 4),
    (@codexId, 'Seraptek Heavy Construct Detachment', 0, 4),
    (@codexId, 'Ghost Ark Detachment', 0, 3),
    (@codexId, 'Scarab Detachment', 0, 0)
ON DUPLICATE KEY UPDATE
    CommandPoints = VALUES(CommandPoints),
    `Class` = VALUES(`Class`);

INSERT INTO DetachmentComposition (DetachmentId, BaseId, BaseCount)
SELECT d.DetachmentId, b.BaseId, src.BaseCount
FROM (
    SELECT 'Overlord Detachment' AS DetachmentName, 'Overlord' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Deceiver Detachment' AS DetachmentName, 'Deceiver' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Nightbringer Detachment' AS DetachmentName, 'Nightbringer' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Void Dragon Detachment' AS DetachmentName, 'Void Dragon' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Transcendent C''tan Detachment' AS DetachmentName, 'Transcendent C''tan' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Tesseract Vault Detachment' AS DetachmentName, 'Tesseract Vault' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Abattoir Detachment' AS DetachmentName, 'Abattoir' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'War Barge Detachment' AS DetachmentName, 'War Barge' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Tomb Guardian Detachment' AS DetachmentName, 'Tomb Guardian' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Aeonic Orb Detachment' AS DetachmentName, 'Aeonic Orb' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Necron Lord and Retinue Detachment' AS DetachmentName, 'Necron Lord' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Necron Lord and Retinue Detachment' AS DetachmentName, 'Lychguard' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Cryptek Detachment' AS DetachmentName, 'Cryptek' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Catacomb Command Barge Detachment' AS DetachmentName, 'Catacomb Command Barge' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Flayed Ones Detachment' AS DetachmentName, 'Flayed One' AS UnitName, 6 AS BaseCount
    UNION ALL SELECT 'Hexmark Destroyer Detachment' AS DetachmentName, 'Hexmark Destroyer' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Skorpekh Destroyer Detachment' AS DetachmentName, 'Skorpekh Destroyer' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Necron Warriors Detachment' AS DetachmentName, 'Necron Warriors' AS UnitName, 6 AS BaseCount
    UNION ALL SELECT 'Immortals Detachment' AS DetachmentName, 'Immortals' AS UnitName, 6 AS BaseCount
    UNION ALL SELECT 'Pariah Detachment' AS DetachmentName, 'Pariah' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Triarch Praetorians Detachment' AS DetachmentName, 'Triarch Praetorians' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Deathmark Detachment' AS DetachmentName, 'Deathmark' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Canoptek Spyder (Assault) Detachment' AS DetachmentName, 'Canoptek Spyder (Assault)' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Canoptek Spyder (Support) Detachment' AS DetachmentName, 'Canoptek Spyder (Support)' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Canoptek Acanthrites Detachment' AS DetachmentName, 'Canoptek Acanthrites' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Destroyer Detachment' AS DetachmentName, 'Destroyer' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Heavy Destroyer Detachment' AS DetachmentName, 'Heavy Destroyer' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Ophydian Destroyer Detachment' AS DetachmentName, 'Ophydian Destroyer' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Canoptek Wraiths Detachment' AS DetachmentName, 'Canoptek Wraiths' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Tomb Blades Detachment' AS DetachmentName, 'Tomb Blades' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Canoptek Doomstalker Detachment' AS DetachmentName, 'Canoptek Doomstalker' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Canoptek Reanimator Detachment' AS DetachmentName, 'Canoptek Reanimator' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Triarch Stalker Detachment' AS DetachmentName, 'Triarch Stalker' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Doomsday Ark Detachment' AS DetachmentName, 'Doomsday Ark' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Tesseract Ark Detachment' AS DetachmentName, 'Tesseract Ark' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Annihilation Barge Detachment' AS DetachmentName, 'Annihilation Barge' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Doom Scythe Detachment' AS DetachmentName, 'Doom Scythe' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Night Scythe Detachment' AS DetachmentName, 'Night Scythe' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Night Shroud Detachment' AS DetachmentName, 'Night Shroud' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Tomb Golem Detachment' AS DetachmentName, 'Tomb Golem' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Canoptek Tomb Sentinel Detachment' AS DetachmentName, 'Canoptek Tomb Sentinel' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Monolith Detachment' AS DetachmentName, 'Monolith' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Doomsday Monolith Detachment' AS DetachmentName, 'Doomsday Monolith' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Obelisk Detachment' AS DetachmentName, 'Obelisk' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Pylon Detachment' AS DetachmentName, 'Pylon' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Seraptek Heavy Construct Detachment' AS DetachmentName, 'Seraptek Heavy Construct' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Ghost Ark Detachment' AS DetachmentName, 'Ghost Ark' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Scarab Detachment' AS DetachmentName, 'Scarab Tokens' AS UnitName, 3 AS BaseCount
) AS src
INNER JOIN Detachment d
    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName
INNER JOIN `Base` b
    ON b.CodexId = @codexId AND b.BaseName = src.UnitName;

INSERT INTO Formation (
    CodexId, FormationKindId, FormationName, PointsCost, CommandPoints, Contents,
    DestructionPoints
) VALUES
    (@codexId, 1, 'Overlord (Unique)', 125, 0, '1 Overlord base', 0),
    (@codexId, 2, 'Flayed Ones Company', 0, 0, '1 Flayed Lord (0); 3 Flayed Ones Detachments. Optional: 0–5 Flayed Ones Detachments; 0–1 Special or Extra Special; 0–1 Extra Special; any Options.', 0),
    (@codexId, 2, 'Infantry Company', 0, 0, '1 Necron Lord (+50); 2 of Necron Warriors or Immortals; 1 of Necron Warriors, Immortals, or Monolith. Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.', 0),
    (@codexId, 2, 'Skorpekh Company', 0, 0, '1 Skorpekh Lord (+25); 3 of Hexmark Destroyer or Skorpekh Destroyer. Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.', 0),
    (@codexId, 2, 'Rapid Intervention Company', 0, 0, '1 Destroyer Lord (+50); 2 of Destroyer or Heavy Destroyer; 1 of Destroyer, Heavy Destroyer, Canoptek Wraiths, or Tomb Blades. Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.', 0),
    (@codexId, 2, 'Support Company', 0, 0, '0–1 Cryptek (+50); 2 Monolith Detachments; 1 of Monolith, Doomsday Monolith, or Canoptek Reanimator. Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.', 0),
    (@codexId, 3, 'Deceiver Detachment', 400, 0, '1 Deceiver base (C''tan Shard)', 0),
    (@codexId, 3, 'Nightbringer Detachment', 400, 0, '1 Nightbringer base (C''tan Shard)', 0),
    (@codexId, 3, 'Void Dragon Detachment', 400, 0, '1 Void Dragon base (C''tan Shard)', 0),
    (@codexId, 3, 'Transcendent C''tan Detachment', 400, 0, '1 Transcendent C''tan base (C''tan Shard)', 0),
    (@codexId, 3, 'Tesseract Vault Detachment', 400, 0, '1 Tesseract Vault base (C''tan Shard)', 0),
    (@codexId, 3, 'Abattoir Detachment', 750, 0, '1 Abattoir base', 0),
    (@codexId, 3, 'War Barge Detachment', 375, 0, '1 War Barge base', 0),
    (@codexId, 3, 'Tomb Guardian Detachment', 475, 0, '1 Tomb Guardian base (choose 2 weapons)', 0),
    (@codexId, 3, 'Aeonic Orb Detachment', 700, 0, '1 Aeonic Orb base', 0),
    (@codexId, 5, 'Necron Lord and Retinue Detachment', 250, 0, '1 Necron Lord base and 4 Lychguard bases', 0),
    (@codexId, 5, 'Cryptek', 100, 0, '1 Cryptek base', 0),
    (@codexId, 5, 'Necron Lord on Catacomb Command Barge', 75, 0, '1 Catacomb Command Barge base', 0),
    (@codexId, 4, 'Flayed Ones Detachment', 150, 0, '6 Flayed One bases', 0),
    (@codexId, 4, 'Hexmark Destroyer Detachment', 150, 0, '4 Hexmark Destroyer bases', 0),
    (@codexId, 4, 'Skorpekh Destroyer Detachment', 175, 0, '4 Skorpekh Destroyer bases', 0),
    (@codexId, 4, 'Necron Warriors Detachment', 175, 0, '6 Necron Warrior bases', 0),
    (@codexId, 4, 'Immortals Detachment', 275, 0, '6 Immortal bases', 0),
    (@codexId, 4, 'Pariah Detachment', 200, 0, '4 Pariah bases', 0),
    (@codexId, 4, 'Triarch Praetorians Detachment', 175, 0, '4 Triarch Praetorian bases', 0),
    (@codexId, 4, 'Deathmark Detachment', 150, 0, '4 Deathmark bases', 0),
    (@codexId, 4, 'Canoptek Spyder (Assault) Detachment', 125, 0, '2 Canoptek Spyder (Assault) bases', 0),
    (@codexId, 4, 'Canoptek Spyder (Support) Detachment', 125, 0, '2 Canoptek Spyder (Support) bases', 0),
    (@codexId, 4, 'Canoptek Acanthrites Detachment', 200, 0, '4 Canoptek Acanthrite bases', 0),
    (@codexId, 4, 'Destroyer Detachment', 225, 0, '5 Destroyer bases', 0),
    (@codexId, 4, 'Heavy Destroyer Detachment', 275, 0, '4 Heavy Destroyer bases', 0),
    (@codexId, 4, 'Ophydian Destroyer Detachment', 175, 0, '4 Ophydian Destroyer bases', 0),
    (@codexId, 4, 'Canoptek Wraiths Detachment', 175, 0, '4 Canoptek Wraith bases', 0),
    (@codexId, 4, 'Tomb Blades Detachment', 225, 0, '4 Tomb Blades bases', 0),
    (@codexId, 4, 'Canoptek Doomstalker Detachment', 225, 0, '3 Canoptek Doomstalker bases', 0),
    (@codexId, 4, 'Canoptek Reanimator Detachment', 125, 0, '3 Canoptek Reanimator bases', 0),
    (@codexId, 4, 'Triarch Stalker Detachment', 175, 0, '3 Triarch Stalker bases', 0),
    (@codexId, 4, 'Doomsday Ark Detachment', 300, 0, '3 Doomsday Ark bases', 0),
    (@codexId, 4, 'Tesseract Ark Detachment', 225, 0, '3 Tesseract Ark bases', 0),
    (@codexId, 4, 'Annihilation Barge Detachment', 200, 0, '3 Annihilation Barge bases', 0),
    (@codexId, 4, 'Doom Scythe Detachment', 300, 0, '3 Doom Scythe bases', 0),
    (@codexId, 4, 'Night Scythe Detachment', 250, 0, '3 Night Scythe bases', 0),
    (@codexId, 4, 'Night Shroud Detachment', 300, 0, '2 Night Shroud bases', 0),
    (@codexId, 4, 'Tomb Golem Detachment', 300, 0, '3 Tomb Golem bases', 0),
    (@codexId, 4, 'Canoptek Tomb Sentinel Detachment', 125, 0, '1 Canoptek Tomb Sentinel base', 0),
    (@codexId, 4, 'Monolith Detachment', 175, 0, '1 Monolith base', 0),
    (@codexId, 4, 'Doomsday Monolith Detachment', 275, 0, '1 Doomsday Monolith base', 0),
    (@codexId, 4, 'Obelisk Detachment', 225, 0, '1 Obelisk base', 0),
    (@codexId, 4, 'Pylon Detachment', 225, 0, '1 Pylon base', 0),
    (@codexId, 4, 'Seraptek Heavy Construct Detachment', 250, 0, '1 Seraptek Heavy Construct base', 0),
    (@codexId, 5, 'Ghost Ark Detachment', 75, 0, '3 Ghost Ark bases', 0),
    (@codexId, 5, 'Scarab Detachment', 50, 0, '3 Scarab tokens', 0)
ON DUPLICATE KEY UPDATE
    FormationKindId = VALUES(FormationKindId),
    PointsCost = VALUES(PointsCost),
    CommandPoints = VALUES(CommandPoints),
    Contents = VALUES(Contents),
    DestructionPoints = VALUES(DestructionPoints);

INSERT INTO FormationDetachment (FormationId, DetachmentId, Quantity)
SELECT f.FormationId, d.DetachmentId, 1
FROM (
    SELECT 'Overlord (Unique)' AS FormationName, 'Overlord Detachment' AS DetachmentName
    UNION ALL SELECT 'Deceiver Detachment' AS FormationName, 'Deceiver Detachment' AS DetachmentName
    UNION ALL SELECT 'Nightbringer Detachment' AS FormationName, 'Nightbringer Detachment' AS DetachmentName
    UNION ALL SELECT 'Void Dragon Detachment' AS FormationName, 'Void Dragon Detachment' AS DetachmentName
    UNION ALL SELECT 'Transcendent C''tan Detachment' AS FormationName, 'Transcendent C''tan Detachment' AS DetachmentName
    UNION ALL SELECT 'Tesseract Vault Detachment' AS FormationName, 'Tesseract Vault Detachment' AS DetachmentName
    UNION ALL SELECT 'Abattoir Detachment' AS FormationName, 'Abattoir Detachment' AS DetachmentName
    UNION ALL SELECT 'War Barge Detachment' AS FormationName, 'War Barge Detachment' AS DetachmentName
    UNION ALL SELECT 'Tomb Guardian Detachment' AS FormationName, 'Tomb Guardian Detachment' AS DetachmentName
    UNION ALL SELECT 'Aeonic Orb Detachment' AS FormationName, 'Aeonic Orb Detachment' AS DetachmentName
    UNION ALL SELECT 'Necron Lord and Retinue Detachment' AS FormationName, 'Necron Lord and Retinue Detachment' AS DetachmentName
    UNION ALL SELECT 'Cryptek' AS FormationName, 'Cryptek Detachment' AS DetachmentName
    UNION ALL SELECT 'Necron Lord on Catacomb Command Barge' AS FormationName, 'Catacomb Command Barge Detachment' AS DetachmentName
    UNION ALL SELECT 'Flayed Ones Detachment' AS FormationName, 'Flayed Ones Detachment' AS DetachmentName
    UNION ALL SELECT 'Hexmark Destroyer Detachment' AS FormationName, 'Hexmark Destroyer Detachment' AS DetachmentName
    UNION ALL SELECT 'Skorpekh Destroyer Detachment' AS FormationName, 'Skorpekh Destroyer Detachment' AS DetachmentName
    UNION ALL SELECT 'Necron Warriors Detachment' AS FormationName, 'Necron Warriors Detachment' AS DetachmentName
    UNION ALL SELECT 'Immortals Detachment' AS FormationName, 'Immortals Detachment' AS DetachmentName
    UNION ALL SELECT 'Pariah Detachment' AS FormationName, 'Pariah Detachment' AS DetachmentName
    UNION ALL SELECT 'Triarch Praetorians Detachment' AS FormationName, 'Triarch Praetorians Detachment' AS DetachmentName
    UNION ALL SELECT 'Deathmark Detachment' AS FormationName, 'Deathmark Detachment' AS DetachmentName
    UNION ALL SELECT 'Canoptek Spyder (Assault) Detachment' AS FormationName, 'Canoptek Spyder (Assault) Detachment' AS DetachmentName
    UNION ALL SELECT 'Canoptek Spyder (Support) Detachment' AS FormationName, 'Canoptek Spyder (Support) Detachment' AS DetachmentName
    UNION ALL SELECT 'Canoptek Acanthrites Detachment' AS FormationName, 'Canoptek Acanthrites Detachment' AS DetachmentName
    UNION ALL SELECT 'Destroyer Detachment' AS FormationName, 'Destroyer Detachment' AS DetachmentName
    UNION ALL SELECT 'Heavy Destroyer Detachment' AS FormationName, 'Heavy Destroyer Detachment' AS DetachmentName
    UNION ALL SELECT 'Ophydian Destroyer Detachment' AS FormationName, 'Ophydian Destroyer Detachment' AS DetachmentName
    UNION ALL SELECT 'Canoptek Wraiths Detachment' AS FormationName, 'Canoptek Wraiths Detachment' AS DetachmentName
    UNION ALL SELECT 'Tomb Blades Detachment' AS FormationName, 'Tomb Blades Detachment' AS DetachmentName
    UNION ALL SELECT 'Canoptek Doomstalker Detachment' AS FormationName, 'Canoptek Doomstalker Detachment' AS DetachmentName
    UNION ALL SELECT 'Canoptek Reanimator Detachment' AS FormationName, 'Canoptek Reanimator Detachment' AS DetachmentName
    UNION ALL SELECT 'Triarch Stalker Detachment' AS FormationName, 'Triarch Stalker Detachment' AS DetachmentName
    UNION ALL SELECT 'Doomsday Ark Detachment' AS FormationName, 'Doomsday Ark Detachment' AS DetachmentName
    UNION ALL SELECT 'Tesseract Ark Detachment' AS FormationName, 'Tesseract Ark Detachment' AS DetachmentName
    UNION ALL SELECT 'Annihilation Barge Detachment' AS FormationName, 'Annihilation Barge Detachment' AS DetachmentName
    UNION ALL SELECT 'Doom Scythe Detachment' AS FormationName, 'Doom Scythe Detachment' AS DetachmentName
    UNION ALL SELECT 'Night Scythe Detachment' AS FormationName, 'Night Scythe Detachment' AS DetachmentName
    UNION ALL SELECT 'Night Shroud Detachment' AS FormationName, 'Night Shroud Detachment' AS DetachmentName
    UNION ALL SELECT 'Tomb Golem Detachment' AS FormationName, 'Tomb Golem Detachment' AS DetachmentName
    UNION ALL SELECT 'Canoptek Tomb Sentinel Detachment' AS FormationName, 'Canoptek Tomb Sentinel Detachment' AS DetachmentName
    UNION ALL SELECT 'Monolith Detachment' AS FormationName, 'Monolith Detachment' AS DetachmentName
    UNION ALL SELECT 'Doomsday Monolith Detachment' AS FormationName, 'Doomsday Monolith Detachment' AS DetachmentName
    UNION ALL SELECT 'Obelisk Detachment' AS FormationName, 'Obelisk Detachment' AS DetachmentName
    UNION ALL SELECT 'Pylon Detachment' AS FormationName, 'Pylon Detachment' AS DetachmentName
    UNION ALL SELECT 'Seraptek Heavy Construct Detachment' AS FormationName, 'Seraptek Heavy Construct Detachment' AS DetachmentName
    UNION ALL SELECT 'Ghost Ark Detachment' AS FormationName, 'Ghost Ark Detachment' AS DetachmentName
    UNION ALL SELECT 'Scarab Detachment' AS FormationName, 'Scarab Detachment' AS DetachmentName
) AS src
INNER JOIN Formation f
    ON f.CodexId = @codexId AND f.FormationName = src.FormationName
INNER JOIN Detachment d
    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName;

