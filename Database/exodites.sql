-- Exodites 3.0.0 from C:/Files/NetEpicFR300-EnglishTranslation/Exodites 300
-- Upserts Exodites catalog; preserves army lists and Base/Formation ids.

SET NAMES utf8mb4;

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

INSERT INTO Codex (CodexName)
SELECT 'Exodites'
WHERE NOT EXISTS (SELECT 1 FROM Codex WHERE CodexName = 'Exodites');

SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Exodites');
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

DELETE d FROM Detachment d WHERE d.CodexId = @codexId;

DELETE FROM SpecialRule WHERE CodexId = @codexId;

INSERT INTO SpecialAbility (SpecialAbilityName, Description)
SELECT n, d FROM (
    SELECT 'Holo-Field' AS n, 'A Holo-Field disrupts targeting systems and grants Protection against all shooting according to the protected base''s order.

| Protection | Order |
| --- | --- |
| 5+ | First Fire / Immobilised |
| 4+ | Advance / Fall Back |
| 3+ | Charge / Forced March |' AS d
    UNION ALL SELECT 'Scout' AS n, 'This base counts as a Scout for the Exodite Scout army special rule.' AS d
    UNION ALL SELECT 'Cannot Be Transported' AS n, 'This base cannot be transported.' AS d
    UNION ALL SELECT 'Fire on the Move' AS n, 'A base with Advance may move normally, then replaces its order with unrevealed First Fire. It may perform Overwatch Fire with an additional -1 To-Hit penalty. It does not reroll shooting results of 1.' AS d
    UNION ALL SELECT 'Free Deployment' AS n, 'After deployment, bases with this ability may deploy anywhere in their controlling player''s half of the battlefield, at least 12 cm from every enemy base. This is resolved with Infiltration; the detachment may then also infiltrate if eligible.' AS d
    UNION ALL SELECT 'Sniper' AS n, 'When targeting an HQ base, roll 1D6. On 4+, the target cannot redirect the attack using HQ.' AS d
    UNION ALL SELECT 'Antigrav' AS n, 'A base with Antigrav may make short flights over terrain, buildings, troops, and most enemy zones of control. It ignores terrain movement penalties but cannot end its movement on Impassable terrain.' AS d
    UNION ALL SELECT 'Deep Strike (X)' AS n, 'Choose an arrival point and scatter the first base X times, moving 3D6 cm for each scatter. Place the rest of its detachment within 6 cm. Invalid arrivals are delayed until a later turn. A detachment arriving this way cannot receive First Fire and loses 5 cm of movement that turn.' AS d
    UNION ALL SELECT 'Elite (X)' AS n, 'At the beginning of the battle, each detachment containing this ability adds X Elite rerolls to the army''s shared pool. An Elite base may spend them on To-Hit rolls, armour saves, assault dice, Dodge rolls, or disengagement opportunity attacks; only one reroll may be used per base for each roll.' AS d
    UNION ALL SELECT 'Lance (X+ / Y)' AS n, 'When the base contacts a target during Charge or Consolidation, it makes a shooting attack hitting on X+ with AP Y. It follows normal shooting rules, ignores Holo-Fields and energy/deflector shields, and resolves simultaneously with Close Defences. If the target is destroyed and has lower Blocking Class, the attacker may continue moving but cannot use its Lance again that movement.' AS d
    UNION ALL SELECT 'HQ' AS n, 'When an HQ base is targeted by shooting, its controlling player may redirect the attack to another allied base of the same class within 6 cm. This choice is made before saving throws and does not apply in assault.' AS d
    UNION ALL SELECT 'Leader' AS n, 'All allied detachments with at least one base within 12 cm of a base with this ability receive a +1 bonus to their AF.' AS d
    UNION ALL SELECT 'Attached Character' AS n, 'At the beginning of the battle, this base must join an eligible detachment and is thereafter treated as part of it. It uses that detachment''s Morale and movement characteristics, gains its movement abilities, does not occupy transport capacity, and must remain in coherency.' AS d
    UNION ALL SELECT 'Attached Transport' AS n, 'Attached Transports and their passengers are treated as one detachment. They use the passenger detachment''s Morale, receive separate orders but activate simultaneously, have 25 cm Extended Coherency with one another, and may begin with the troops embarked or disembarked.' AS d
    UNION ALL SELECT 'Transport (X)' AS n, 'This base may transport X Infantry bases. Embarking or disembarking costs 5 cm of movement. A capacity of 6 or more may carry Walkers, each of which occupies two spaces.' AS d
    UNION ALL SELECT 'Open-Topped' AS n, 'Transported bases may shoot from an Open-Topped transport, measuring range and line of sight from the transport. They may be affected by attacks that specifically strike passengers and remain subject to their order.' AS d
    UNION ALL SELECT 'Camouflage' AS n, 'If a base occupies terrain that provides a cover save, improve that save by 1. Improve it by a further 1 if the entire detachment has not fired and gives up firing for the current turn. Camouflage only works against enemies more than 25 cm away and is lost for the turn when the base enters an assault.' AS d
    UNION ALL SELECT 'Infiltration' AS n, 'After deployment, bases with this ability may move up to 25 cm. This move cannot enter an enemy zone of control and cannot be made while the detachment is transported.' AS d
    UNION ALL SELECT 'Artillery' AS n, 'Artillery may fire without line of sight and ignores intervening terrain, although targets inside terrain retain its cover save. It cannot target bases at altitude or make Overwatch Fire. Indirect Fire requires First Fire and suffers -1 To-Hit when observed by a Forward Observer or -2 when unobserved.' AS d
    UNION ALL SELECT 'Anti-Aircraft' AS n, 'This weapon activates independently, has a 360-degree firing arc, and reduces a Flyer''s Protection save by 2. It may make Overwatch Fire against targets at altitude on First Fire without the usual penalty, or on Advance with the normal -1 penalty. It suffers -1 To-Hit against ground targets.' AS d
    UNION ALL SELECT 'Battery' AS n, 'All weapons with this ability in the detachment combine into one template attack. The listed To-Hit value applies to a complete detachment and worsens by 1 for each missing base. Range and line of sight may be measured from any base able to fire.' AS d
    UNION ALL SELECT 'Turret' AS n, 'A weapon with the Turret ability has a 360-degree firing arc.' AS d
    UNION ALL SELECT 'Reduces Cover (X)' AS n, 'A weapon with this ability modifies the target''s cover save by X.' AS d
    UNION ALL SELECT 'Damage (+X)' AS n, 'A weapon with this ability inflicts X additional hits against a base successfully hit by the weapon.' AS d
    UNION ALL SELECT 'Damage (+X) in Assault' AS n, 'After this base wins an assault duel, it inflicts X additional hits in addition to the normal hit.' AS d
    UNION ALL SELECT 'Fear' AS n, 'A Class 1-3 detachment entering contact with this base must pass a Morale Test or suffer -2 AF for the rest of the turn. This applies whether the Fear-causing base charges or is charged, and does not affect bases with Fear or Terror.' AS d
    UNION ALL SELECT 'Integral Armour' AS n, 'A base with Integral Armour does not use a hit-location chart. Every hit is resolved against the base as a whole using its armour save.' AS d
    UNION ALL SELECT 'Wounds (X)' AS n, 'This base has X Wounds and is destroyed only after losing all of them. A base without this ability has one Wound.' AS d
    UNION ALL SELECT 'Close Defences (X+)' AS n, 'Every Class 1 or 2 base that engages, or is engaged by, this base suffers an AP 0 hit on X+. Resolve the attack on contact; cover saves may be used.' AS d
    UNION ALL SELECT 'Protection (X+)' AS n, 'Protection is a fixed saving throw made before all other saving throws and may be used in addition to them. A base cannot benefit from more than one Protection save; use the best available.' AS d
    UNION ALL SELECT 'Psychic Save (X+)' AS n, 'A base with Psychic Save (X+) may use this saving throw to negate a psychic power that affects it.' AS d
    UNION ALL SELECT 'Psyker' AS n, 'During the Combat Phase a Psyker may use one psychic power and its conventional weapons. Powers marked Shooting follow normal shooting restrictions; Movement Phase powers may be used at any point during the Psyker''s movement activation.' AS d
    UNION ALL SELECT 'Medic' AS n, 'Once per turn, when a Class 1 or 2 allied base within 6 cm would be destroyed, a Medic may attempt to save it. On a 5+, the base is not destroyed. A base may receive only one Medic attempt for each injury.' AS d
    UNION ALL SELECT 'Master Strategist' AS n, 'An army containing a base with this ability receives two additional order counters that may be kept in reserve and assigned after normal orders have been revealed.' AS d
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM SpecialAbility sa WHERE sa.SpecialAbilityName = src.n
);

UPDATE SpecialAbility sa
INNER JOIN (
    SELECT 'Holo-Field' AS n, 'A Holo-Field disrupts targeting systems and grants Protection against all shooting according to the protected base''s order.

| Protection | Order |
| --- | --- |
| 5+ | First Fire / Immobilised |
| 4+ | Advance / Fall Back |
| 3+ | Charge / Forced March |' AS d
    UNION ALL SELECT 'Scout' AS n, 'This base counts as a Scout for the Exodite Scout army special rule.' AS d
    UNION ALL SELECT 'Cannot Be Transported' AS n, 'This base cannot be transported.' AS d
    UNION ALL SELECT 'Fire on the Move' AS n, 'A base with Advance may move normally, then replaces its order with unrevealed First Fire. It may perform Overwatch Fire with an additional -1 To-Hit penalty. It does not reroll shooting results of 1.' AS d
    UNION ALL SELECT 'Lance (X+ / Y)' AS n, 'When the base contacts a target during Charge or Consolidation, it makes a shooting attack hitting on X+ with AP Y. It follows normal shooting rules, ignores Holo-Fields and energy/deflector shields, and resolves simultaneously with Close Defences. If the target is destroyed and has lower Blocking Class, the attacker may continue moving but cannot use its Lance again that movement.' AS d
) AS src ON src.n = sa.SpecialAbilityName
SET sa.Description = src.d;

INSERT INTO PsychicPower (PsychicPowerName, Description)
SELECT n, d FROM (
    SELECT 'The Executioner' AS n, '[Combat Phase]: The Visionary projects its mind out of its body and attacks an enemy base within 45 cm and Line of Sight. Immediately resolve an assault against it. This is a Psychic Attack with AF +4. Psychic Saves are made before the assault to cancel the effect. The Visionary receives bonuses for previous attackers and counts as a previous attacker for later opponents of the target. The attack counts as an assault by a Class 2 base.' AS d
    UNION ALL SELECT 'Fortune' AS n, '[Movement Phase, upon activation]: Designate an allied detachment within 12 cm. It gains 3 Fortune counters, which function as Elite counters for this turn.' AS d
    UNION ALL SELECT 'Heal' AS n, '[Movement Phase, upon activation]: The Visionary gains the Medic ability until the end of the turn.' AS d
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM PsychicPower pp WHERE pp.PsychicPowerName = src.n
);

UPDATE PsychicPower pp
INNER JOIN (
    SELECT 'The Executioner' AS n, '[Combat Phase]: The Visionary projects its mind out of its body and attacks an enemy base within 45 cm and Line of Sight. Immediately resolve an assault against it. This is a Psychic Attack with AF +4. Psychic Saves are made before the assault to cancel the effect. The Visionary receives bonuses for previous attackers and counts as a previous attacker for later opponents of the target. The attack counts as an assault by a Class 2 base.' AS d
    UNION ALL SELECT 'Fortune' AS n, '[Movement Phase, upon activation]: Designate an allied detachment within 12 cm. It gains 3 Fortune counters, which function as Elite counters for this turn.' AS d
    UNION ALL SELECT 'Heal' AS n, '[Movement Phase, upon activation]: The Visionary gains the Medic ability until the end of the turn.' AS d
) AS src ON src.n = pp.PsychicPowerName
SET pp.Description = src.d;

INSERT INTO SpecialRule (CodexId, SpecialRuleName, Description)
SELECT @codexId, n, d FROM (
    SELECT 'Scout' AS n, 'If the Exodites form your primary army, choose one of the following abilities at the start of the battle, before objectives are placed.

 • For every complete 3 detachments with the Scout ability, choose one Class 1 to 3 detachment to gain Infiltration; the chosen detachment need not have Scout. In addition, gain 2 orders in reserve as if the army had a detachment with Master Strategist.
 • Exodite Class 1 and 2 bases gain Camouflage for turn 1 only.
 • For every complete 2 detachments with Scout, place one forest, to a maximum of 3, at the same time as fortifications. Each forest may be no larger than 10 × 10 cm and may be placed anywhere except on another terrain feature.
 • For every complete 2 detachments with Scout, choose one enemy Class 1 to 4 detachment; it must receive an Advance order on turn 1.' AS d
    UNION ALL SELECT 'Forester' AS n, 'Exodites suffer no movement penalty when they move through forests.' AS d
) AS src;

INSERT INTO `Base` (
    CodexId, BaseName, DestructionPoints,
    Morale, `Class`, Movement, `Save`, FA, NumberOfTitanWeapons
) VALUES
    (@codexId, 'Fusiliers', 0, '6', 1, '10', '--', '+0', 0),
    (@codexId, 'Exodite Warriors', 0, '6', 1, '10', '--', '+1', 0),
    (@codexId, 'Scouts', 0, '6', 1, '10', '--', '+1', 0),
    (@codexId, 'Travois — Starcannons', 0, '6', 1, '15', '--', '+1', 0),
    (@codexId, 'Travois — Bright Lance', 0, '6', 1, '15', '--', '+1', 0),
    (@codexId, 'Travois — Missile Launcher', 0, '6', 1, '15', '--', '+1', 0),
    (@codexId, 'Baron', 0, 'Attached', 2, '20', '4+/6+f', '+6', 0),
    (@codexId, 'Dragon Knights', 0, '6', 2, '20', '--', '+2', 0),
    (@codexId, 'Lethosaur Knights', 0, '6', 2, '25', '--', '+1', 0),
    (@codexId, 'Pterosaur Knights', 0, '6', 2, '25', '--', '+2', 0),
    (@codexId, 'Raptor Knights', 0, '6', 2, '25', '--', '+3', 0),
    (@codexId, 'Dragoons', 0, '5', 2, '20', '5+', '+4', 0),
    (@codexId, 'Salamander', 0, '6', 2, '15', '--', '+1', 0),
    (@codexId, 'Visionary', 0, 'Attached', 2, '20', '6+f', '+4', 0),
    (@codexId, 'Vyper Transport', 0, 'Attached', 2, '35', '6+', '+1', 0),
    (@codexId, 'Combat Walkers', 0, '6', 2, '25', '5+', '+1', 0),
    (@codexId, 'Reconnaissance Walkers', 0, '6', 2, '25', '5+', '+2', 0),
    (@codexId, 'Pentasaur — Maelstrom Laser', 0, '6', 3, '15', '3+', '+6', 0),
    (@codexId, 'Pentasaur — Missile Launcher', 0, '6', 3, '15', '3+', '+6', 0),
    (@codexId, 'Pentasaur — Thermal Lance', 0, '6', 3, '15', '3+', '+6', 0),
    (@codexId, 'Carnosaur', 0, '5', 4, '20', '2+', '+11', 0),
    (@codexId, 'Bright Stalker', 0, '5', 4, '25', '3+', '+5', 0),
    (@codexId, 'Bright Stallion', 0, '5', 4, '25', '3+', '+7', 0),
    (@codexId, 'Fire Gale', 0, '5', 4, '20', '3+', '+3', 0),
    (@codexId, 'Fire Reaper', 0, '5', 4, '20', '3+', '+3', 0),
    (@codexId, 'Fire Storm', 0, '5', 4, '20', '3+', '+3', 0),
    (@codexId, 'Towering Destroyer', 0, '5', 4, '15', '2+', '+5', 0),
    (@codexId, 'Megadon — Assault', 0, '5', 4, '15', '2+', '+8', 0),
    (@codexId, 'Megadon — Support', 0, '5', 4, '15', '2+', '+7', 0)
ON DUPLICATE KEY UPDATE
    DestructionPoints = VALUES(DestructionPoints),
    Morale = VALUES(Morale),
    `Class` = VALUES(`Class`),
    Movement = VALUES(Movement),
    `Save` = VALUES(`Save`),
    FA = VALUES(FA),
    NumberOfTitanWeapons = VALUES(NumberOfTitanWeapons);

SET @fusiliers := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Fusiliers');
SET @exoditeWarriors := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Exodite Warriors');
SET @scouts := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Scouts');
SET @travoisStarcannons := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Travois — Starcannons');
SET @travoisBrightLance := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Travois — Bright Lance');
SET @travoisMissileLauncher := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Travois — Missile Launcher');
SET @baron := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Baron');
SET @dragonKnights := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Dragon Knights');
SET @lethosaurKnights := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Lethosaur Knights');
SET @pterosaurKnights := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Pterosaur Knights');
SET @raptorKnights := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Raptor Knights');
SET @dragoons := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Dragoons');
SET @salamander := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Salamander');
SET @visionary := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Visionary');
SET @vyperTransport := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Vyper Transport');
SET @combatWalkers := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Combat Walkers');
SET @reconnaissanceWalkers := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Reconnaissance Walkers');
SET @pentasaurMaelstromLaser := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Pentasaur — Maelstrom Laser');
SET @pentasaurMissileLauncher := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Pentasaur — Missile Launcher');
SET @pentasaurThermalLance := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Pentasaur — Thermal Lance');
SET @carnosaur := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Carnosaur');
SET @brightStalker := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Bright Stalker');
SET @brightStallion := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Bright Stallion');
SET @fireGale := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Fire Gale');
SET @fireReaper := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Fire Reaper');
SET @fireStorm := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Fire Storm');
SET @toweringDestroyer := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Towering Destroyer');
SET @megadonAssault := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Megadon — Assault');
SET @megadonSupport := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Megadon — Support');

INSERT INTO Weapon (
    BaseId, `Name`, `Range`, Dice, ToHit, ArmourPenetration, IsTitanWeapon
) VALUES
    (@fusiliers, 'Shard Carbine', '45 cm', '1', '5+', '0', 0),
    (@exoditeWarriors, 'Shuriken Pistol and Sword', '20 cm', '1', '5+', '0', 0),
    (@scouts, 'Long Rifle', '75 cm', '1', '4+', '0', 0),
    (@travoisStarcannons, 'Starcannon Battery', '75 cm', '2', '4+', '-1', 0),
    (@travoisBrightLance, 'Bright Lance', '75 cm', '1', '4+', '-2', 0),
    (@travoisMissileLauncher, 'Missile Launcher', '120 cm', '1', '3+', '0', 0),
    (@baron, 'Shuriken Pistol', '20 cm', '2', '5+', '0', 0),
    (@dragonKnights, 'Shard Carbine and Lance', '45 cm', '1', '5+', '0', 0),
    (@lethosaurKnights, 'Plasma Carbine', '30 cm', '1', '4+', '-1', 0),
    (@pterosaurKnights, 'Shard Carbine', '45 cm', '1', '5+', '0', 0),
    (@raptorKnights, 'Sword and Pistol', '20 cm', '1', '5+', '0', 0),
    (@dragoons, 'Pistol and Lance', '20 cm', '1', '5+', '0', 0),
    (@salamander, 'Fire Breath', '45 cm', '2', '4+', '0', 0),
    (@visionary, 'Shuriken Pistol', '20 cm', '1', '5+', '0', 0),
    (@vyperTransport, 'Shuriken Catapult', '20 cm', '1', '5+', '0', 0),
    (@combatWalkers, 'Bright Lance', '75 cm', '1', '4+', '-2', 0),
    (@combatWalkers, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@reconnaissanceWalkers, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@pentasaurMaelstromLaser, 'Maelstrom Laser', '75 cm', '2', '4+', '-2', 0),
    (@pentasaurMissileLauncher, 'Maelstrom Missile Launcher', '90 cm', 'Template', '3+', '-1', 0),
    (@pentasaurThermalLance, 'Thermal Lance', '20 cm', '1', '3+', '-3', 0),
    (@pentasaurThermalLance, 'Flamer', '20 cm', '2', '4+', '0', 0),
    (@carnosaur, 'Star Laser', '45 cm', '5', '5+', '-1', 0),
    (@brightStalker, 'Pulse Laser', '45 cm', '1', '4+', '-1', 0),
    (@brightStalker, 'Bright Lance', '75 cm', '1', '4+', '-2', 0),
    (@brightStallion, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@fireGale, 'Bright Lances', '75 cm', '2', '4+', '-2', 0),
    (@fireReaper, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@fireReaper, 'Reaper Laser', '45 cm', '4', '4+', '0', 0),
    (@fireStorm, 'Pulse Lances', '45 cm', '2', '4+', '0', 0),
    (@fireStorm, 'Missile Launcher', '90 cm', '2', '4+', '0', 0),
    (@toweringDestroyer, 'Pulse Lances', '45 cm', '2', '4+', '0', 0),
    (@toweringDestroyer, 'Maelstrom Laser', '90 cm', '2', '4+', '-2', 0),
    (@megadonAssault, 'Flamer', '20 cm', '4', '4+', '0', 0),
    (@megadonAssault, 'Heavy Thermal Lance', '30 cm', '2', '3+', '-4', 0),
    (@megadonSupport, 'Maelstrom Laser', '75 cm', '4', '4+', '-2', 0),
    (@megadonSupport, 'Twin Star Lance', '90 cm', '2', '3+', '-3', 0);

INSERT INTO BaseSpecialAbility (BaseId, SpecialAbilityId, AbilityValue)
SELECT src.BaseId, sa.SpecialAbilityId, src.AbilityValue
FROM (
    SELECT @fusiliers AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @scouts AS BaseId, 'Scout' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @scouts AS BaseId, 'Free Deployment' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @scouts AS BaseId, 'Camouflage' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @scouts AS BaseId, 'Sniper' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @travoisStarcannons AS BaseId, 'Fire on the Move' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @travoisStarcannons AS BaseId, 'Cannot Be Transported' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @travoisBrightLance AS BaseId, 'Fire on the Move' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @travoisBrightLance AS BaseId, 'Cannot Be Transported' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @travoisMissileLauncher AS BaseId, 'Fire on the Move' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @travoisMissileLauncher AS BaseId, 'Cannot Be Transported' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @baron AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @baron AS BaseId, 'Leader' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @baron AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @baron AS BaseId, 'Lance (X+ / Y)' AS AbilityName, '5+,-1' AS AbilityValue
    UNION ALL SELECT @baron AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dragonKnights AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @lethosaurKnights AS BaseId, 'Scout' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @lethosaurKnights AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pterosaurKnights AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pterosaurKnights AS BaseId, 'Deep Strike (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @raptorKnights AS BaseId, 'Scout' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @raptorKnights AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dragoons AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @dragoons AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @dragoons AS BaseId, 'Lance (X+ / Y)' AS AbilityName, '5+,0' AS AbilityValue
    UNION ALL SELECT @salamander AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @visionary AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @visionary AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @visionary AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @visionary AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @vyperTransport AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @vyperTransport AS BaseId, 'Transport (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @vyperTransport AS BaseId, 'Open-Topped' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @vyperTransport AS BaseId, 'Attached Transport' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @combatWalkers AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @reconnaissanceWalkers AS BaseId, 'Scout' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @reconnaissanceWalkers AS BaseId, 'Free Deployment' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @carnosaur AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @carnosaur AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @carnosaur AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @carnosaur AS BaseId, 'Fear' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @brightStalker AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @brightStalker AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @brightStalker AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @brightStallion AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @brightStallion AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @brightStallion AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @brightStallion AS BaseId, 'Lance (X+ / Y)' AS AbilityName, '3+,-2' AS AbilityValue
    UNION ALL SELECT @fireGale AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @fireGale AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @fireGale AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @fireReaper AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @fireReaper AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @fireReaper AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @fireStorm AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @fireStorm AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @fireStorm AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @toweringDestroyer AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @toweringDestroyer AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @toweringDestroyer AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @megadonAssault AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @megadonAssault AS BaseId, 'Wounds (X)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @megadonAssault AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @megadonAssault AS BaseId, 'Transport (X)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @megadonAssault AS BaseId, 'Open-Topped' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @megadonSupport AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @megadonSupport AS BaseId, 'Wounds (X)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @megadonSupport AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
) AS src
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = src.AbilityName;

INSERT INTO BasePsychicPower (BaseId, PsychicPowerId, AbilityValue)
SELECT src.BaseId, pp.PsychicPowerId, src.AbilityValue
FROM (
    SELECT @visionary AS BaseId, 'The Executioner' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @visionary AS BaseId, 'Fortune' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @visionary AS BaseId, 'Heal' AS PowerName, '' AS AbilityValue
) AS src
INNER JOIN PsychicPower pp ON pp.PsychicPowerName = src.PowerName;

INSERT INTO WeaponSpecialAbility (WeaponId, SpecialAbilityId, AbilityValue)
SELECT w.WeaponId, sa.SpecialAbilityId, src.AbilityValue
FROM (
    SELECT @travoisStarcannons AS BaseId, 'Starcannon Battery' AS WeaponName, 'Anti-Aircraft' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @travoisMissileLauncher AS BaseId, 'Missile Launcher' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @travoisMissileLauncher AS BaseId, 'Missile Launcher' AS WeaponName, 'Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @salamander AS BaseId, 'Fire Breath' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @pentasaurMaelstromLaser AS BaseId, 'Maelstrom Laser' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pentasaurMissileLauncher AS BaseId, 'Maelstrom Missile Launcher' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pentasaurMissileLauncher AS BaseId, 'Maelstrom Missile Launcher' AS WeaponName, 'Battery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pentasaurMissileLauncher AS BaseId, 'Maelstrom Missile Launcher' AS WeaponName, 'Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pentasaurMissileLauncher AS BaseId, 'Maelstrom Missile Launcher' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @pentasaurThermalLance AS BaseId, 'Thermal Lance' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pentasaurThermalLance AS BaseId, 'Flamer' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @fireStorm AS BaseId, 'Missile Launcher' AS WeaponName, 'Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @megadonAssault AS BaseId, 'Flamer' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @megadonAssault AS BaseId, 'Flamer' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @megadonAssault AS BaseId, 'Heavy Thermal Lance' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @megadonAssault AS BaseId, 'Heavy Thermal Lance' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @megadonSupport AS BaseId, 'Twin Star Lance' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @megadonSupport AS BaseId, 'Twin Star Lance' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
) AS src
INNER JOIN Weapon w ON w.BaseId = src.BaseId AND w.`Name` = src.WeaponName
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = src.AbilityName;

INSERT INTO Detachment (
    CodexId, DetachmentName, CommandPoints, `Class`
) VALUES
    (@codexId, 'Baron Detachment', 0, 2),
    (@codexId, 'Infantry Company', 0, 1),
    (@codexId, 'Pentasaur Company', 0, 3),
    (@codexId, 'Rapid Intervention Company', 0, 2),
    (@codexId, 'Scout Company', 0, 2),
    (@codexId, 'Bright Stalker Detachment', 0, 4),
    (@codexId, 'Bright Stallion Detachment', 0, 4),
    (@codexId, 'Fire Gale Detachment', 0, 4),
    (@codexId, 'Fire Reaper Detachment', 0, 4),
    (@codexId, 'Fire Storm Detachment', 0, 4),
    (@codexId, 'Towering Destroyer Detachment', 0, 4),
    (@codexId, 'Megadon — Assault Detachment', 0, 4),
    (@codexId, 'Megadon — Support Detachment', 0, 4),
    (@codexId, 'Visionary Detachment', 0, 2),
    (@codexId, 'Fusilier Detachment', 0, 1),
    (@codexId, 'Exodite Warrior Detachment', 0, 1),
    (@codexId, 'Scout Detachment', 0, 1),
    (@codexId, 'Travois — Starcannons Detachment', 0, 1),
    (@codexId, 'Travois — Bright Lance Detachment', 0, 1),
    (@codexId, 'Travois — Missile Launcher Detachment', 0, 1),
    (@codexId, 'Dragon Knight Detachment', 0, 2),
    (@codexId, 'Lethosaur Knight Detachment', 0, 2),
    (@codexId, 'Pterosaur Knight Detachment', 0, 2),
    (@codexId, 'Raptor Knight Detachment', 0, 2),
    (@codexId, 'Dragoon Detachment', 0, 2),
    (@codexId, 'Salamander Detachment', 0, 2),
    (@codexId, 'Combat Walker Detachment', 0, 2),
    (@codexId, 'Reconnaissance Walker Detachment', 0, 2),
    (@codexId, 'Pentasaur — Maelstrom Laser Detachment', 0, 3),
    (@codexId, 'Pentasaur — Missile Launcher Detachment', 0, 3),
    (@codexId, 'Pentasaur — Thermal Lance Detachment', 0, 3),
    (@codexId, 'Carnosaur Detachment', 0, 4),
    (@codexId, 'Vyper Detachment', 0, 2)
ON DUPLICATE KEY UPDATE
    CommandPoints = VALUES(CommandPoints),
    `Class` = VALUES(`Class`);

INSERT INTO DetachmentComposition (DetachmentId, BaseId, BaseCount)
SELECT d.DetachmentId, b.BaseId, src.BaseCount
FROM (
    SELECT 'Baron Detachment' AS DetachmentName, 'Baron' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Baron Detachment' AS DetachmentName, 'Dragoons' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Bright Stalker Detachment' AS DetachmentName, 'Bright Stalker' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Bright Stallion Detachment' AS DetachmentName, 'Bright Stallion' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Fire Gale Detachment' AS DetachmentName, 'Fire Gale' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Fire Reaper Detachment' AS DetachmentName, 'Fire Reaper' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Fire Storm Detachment' AS DetachmentName, 'Fire Storm' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Towering Destroyer Detachment' AS DetachmentName, 'Towering Destroyer' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Megadon — Assault Detachment' AS DetachmentName, 'Megadon — Assault' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Megadon — Support Detachment' AS DetachmentName, 'Megadon — Support' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Visionary Detachment' AS DetachmentName, 'Visionary' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Fusilier Detachment' AS DetachmentName, 'Fusiliers' AS UnitName, 6 AS BaseCount
    UNION ALL SELECT 'Exodite Warrior Detachment' AS DetachmentName, 'Exodite Warriors' AS UnitName, 6 AS BaseCount
    UNION ALL SELECT 'Scout Detachment' AS DetachmentName, 'Scouts' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Travois — Starcannons Detachment' AS DetachmentName, 'Travois — Starcannons' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Travois — Bright Lance Detachment' AS DetachmentName, 'Travois — Bright Lance' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Travois — Missile Launcher Detachment' AS DetachmentName, 'Travois — Missile Launcher' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Dragon Knight Detachment' AS DetachmentName, 'Dragon Knights' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Lethosaur Knight Detachment' AS DetachmentName, 'Lethosaur Knights' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Pterosaur Knight Detachment' AS DetachmentName, 'Pterosaur Knights' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Raptor Knight Detachment' AS DetachmentName, 'Raptor Knights' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Dragoon Detachment' AS DetachmentName, 'Dragoons' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Salamander Detachment' AS DetachmentName, 'Salamander' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Combat Walker Detachment' AS DetachmentName, 'Combat Walkers' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Reconnaissance Walker Detachment' AS DetachmentName, 'Reconnaissance Walkers' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Pentasaur — Maelstrom Laser Detachment' AS DetachmentName, 'Pentasaur — Maelstrom Laser' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Pentasaur — Missile Launcher Detachment' AS DetachmentName, 'Pentasaur — Missile Launcher' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Pentasaur — Thermal Lance Detachment' AS DetachmentName, 'Pentasaur — Thermal Lance' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Carnosaur Detachment' AS DetachmentName, 'Carnosaur' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Vyper Detachment' AS DetachmentName, 'Vyper Transport' AS UnitName, 6 AS BaseCount
) AS src
INNER JOIN Detachment d
    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName
INNER JOIN `Base` b
    ON b.CodexId = @codexId AND b.BaseName = src.UnitName;

INSERT INTO Formation (
    CodexId, FormationKindId, FormationName, PointsCost, CommandPoints, Contents,
    DestructionPoints
) VALUES
    (@codexId, 1, 'Baron (Unique)', 125, 0, '1 Baron and 2 Dragoon bases', 0),
    (@codexId, 2, 'Infantry Company', 0, 0, 'Compulsory: Choose 1 (Fusiliers 75 or Warriors 50); Choose 1 (Fusiliers 125 or Warriors 100); Choose 2 from Fusiliers/Warriors/Scouts/Travois. Optional: 0–1 Special or Additional Special, 0–1 Additional Special, 0–5 Support, any Options.', 0),
    (@codexId, 2, 'Pentasaur Company', 0, 0, 'Compulsory: Choose 1 Pentasaur variant (discounted); Choose 2 Pentasaur variants (support prices). Optional: 0–1 Special or Additional Special, 0–1 Additional Special, 0–5 Support, any Options.', 0),
    (@codexId, 2, 'Rapid Intervention Company', 0, 0, 'Compulsory: Choose 1 (Dragon Knights 75 or Combat Walkers 125); Choose 1 (Dragon Knights 125 or Combat Walkers 175); Choose 2 from cavalry/walker list. Optional: 0–1 Special or Additional Special, 0–1 Additional Special, 0–5 Support, any Options.', 0),
    (@codexId, 2, 'Scout Company', 0, 0, 'Compulsory: Choose 1 (Lethosaur 75 or Raptor 100); Choose 2 (Lethosaur 125 or Raptor 150); plus further scout picks per army book. Optional: 0–1 Special or Additional Special, 0–1 Additional Special, 0–5 Support, any Options.', 0),
    (@codexId, 3, 'Bright Stalker', 325, 0, '3 Bright Stalker bases', 0),
    (@codexId, 3, 'Bright Stallion', 300, 0, '3 Bright Stallion bases', 0),
    (@codexId, 3, 'Fire Gale', 325, 0, '3 Fire Gale bases', 0),
    (@codexId, 3, 'Fire Reaper', 325, 0, '3 Fire Reaper bases', 0),
    (@codexId, 3, 'Fire Storm', 325, 0, '3 Fire Storm bases', 0),
    (@codexId, 3, 'Towering Destroyer', 400, 0, '3 Towering Destroyer bases', 0),
    (@codexId, 3, 'Megadon — Assault', 275, 0, '1 Megadon — Assault base', 0),
    (@codexId, 3, 'Megadon — Support', 350, 0, '1 Megadon — Support base', 0),
    (@codexId, 3, 'Visionary', 75, 0, '1 Visionary base', 0),
    (@codexId, 4, 'Fusilier', 125, 0, '6 Fusilier bases', 0),
    (@codexId, 4, 'Exodite Warrior', 100, 0, '6 Exodite Warrior bases', 0),
    (@codexId, 4, 'Scout', 150, 0, '4 Scout bases', 0),
    (@codexId, 4, 'Travois — Starcannons', 200, 0, '3 Travois — Starcannons bases', 0),
    (@codexId, 4, 'Travois — Bright Lance', 150, 0, '3 Travois — Bright Lance bases', 0),
    (@codexId, 4, 'Travois — Missile Launcher', 150, 0, '3 Travois — Missile Launcher bases', 0),
    (@codexId, 4, 'Dragon Knight', 125, 0, '5 Dragon Knight bases', 0),
    (@codexId, 4, 'Lethosaur', 175, 0, '5 Lethosaur Knight bases', 0),
    (@codexId, 4, 'Pterosaur', 175, 0, '5 Pterosaur Knight bases', 0),
    (@codexId, 4, 'Raptor', 150, 0, '5 Raptor Knight bases', 0),
    (@codexId, 4, 'Dragoon', 175, 0, '5 Dragoon bases', 0),
    (@codexId, 4, 'Salamander', 150, 0, '3 Salamander bases', 0),
    (@codexId, 4, 'Combat Walker', 175, 0, '3 Combat Walker bases', 0),
    (@codexId, 4, 'Recon Walker', 125, 0, '3 Reconnaissance Walker bases', 0),
    (@codexId, 4, 'Pentasaur — Maelstrom Laser', 275, 0, '3 Pentasaur — Maelstrom Laser bases', 0),
    (@codexId, 4, 'Pentasaur — Missile', 150, 0, '3 Pentasaur — Missile Launcher bases', 0),
    (@codexId, 4, 'Pentasaur — Thermal', 200, 0, '3 Pentasaur — Thermal Lance bases', 0),
    (@codexId, 4, 'Carnosaur', 150, 0, '1 Carnosaur base', 0),
    (@codexId, 5, 'Vyper Detachment', 150, 0, '6 Vyper Transport bases', 0)
ON DUPLICATE KEY UPDATE
    FormationKindId = VALUES(FormationKindId),
    PointsCost = VALUES(PointsCost),
    CommandPoints = VALUES(CommandPoints),
    Contents = VALUES(Contents),
    DestructionPoints = VALUES(DestructionPoints);

INSERT INTO FormationDetachment (FormationId, DetachmentId, Quantity)
SELECT f.FormationId, d.DetachmentId, 1
FROM (
    SELECT 'Baron (Unique)' AS FormationName, 'Baron Detachment' AS DetachmentName
    UNION ALL SELECT 'Infantry Company' AS FormationName, 'Infantry Company' AS DetachmentName
    UNION ALL SELECT 'Pentasaur Company' AS FormationName, 'Pentasaur Company' AS DetachmentName
    UNION ALL SELECT 'Rapid Intervention Company' AS FormationName, 'Rapid Intervention Company' AS DetachmentName
    UNION ALL SELECT 'Scout Company' AS FormationName, 'Scout Company' AS DetachmentName
    UNION ALL SELECT 'Bright Stalker' AS FormationName, 'Bright Stalker Detachment' AS DetachmentName
    UNION ALL SELECT 'Bright Stallion' AS FormationName, 'Bright Stallion Detachment' AS DetachmentName
    UNION ALL SELECT 'Fire Gale' AS FormationName, 'Fire Gale Detachment' AS DetachmentName
    UNION ALL SELECT 'Fire Reaper' AS FormationName, 'Fire Reaper Detachment' AS DetachmentName
    UNION ALL SELECT 'Fire Storm' AS FormationName, 'Fire Storm Detachment' AS DetachmentName
    UNION ALL SELECT 'Towering Destroyer' AS FormationName, 'Towering Destroyer Detachment' AS DetachmentName
    UNION ALL SELECT 'Megadon — Assault' AS FormationName, 'Megadon — Assault Detachment' AS DetachmentName
    UNION ALL SELECT 'Megadon — Support' AS FormationName, 'Megadon — Support Detachment' AS DetachmentName
    UNION ALL SELECT 'Visionary' AS FormationName, 'Visionary Detachment' AS DetachmentName
    UNION ALL SELECT 'Fusilier' AS FormationName, 'Fusilier Detachment' AS DetachmentName
    UNION ALL SELECT 'Exodite Warrior' AS FormationName, 'Exodite Warrior Detachment' AS DetachmentName
    UNION ALL SELECT 'Scout' AS FormationName, 'Scout Detachment' AS DetachmentName
    UNION ALL SELECT 'Travois — Starcannons' AS FormationName, 'Travois — Starcannons Detachment' AS DetachmentName
    UNION ALL SELECT 'Travois — Bright Lance' AS FormationName, 'Travois — Bright Lance Detachment' AS DetachmentName
    UNION ALL SELECT 'Travois — Missile Launcher' AS FormationName, 'Travois — Missile Launcher Detachment' AS DetachmentName
    UNION ALL SELECT 'Dragon Knight' AS FormationName, 'Dragon Knight Detachment' AS DetachmentName
    UNION ALL SELECT 'Lethosaur' AS FormationName, 'Lethosaur Knight Detachment' AS DetachmentName
    UNION ALL SELECT 'Pterosaur' AS FormationName, 'Pterosaur Knight Detachment' AS DetachmentName
    UNION ALL SELECT 'Raptor' AS FormationName, 'Raptor Knight Detachment' AS DetachmentName
    UNION ALL SELECT 'Dragoon' AS FormationName, 'Dragoon Detachment' AS DetachmentName
    UNION ALL SELECT 'Salamander' AS FormationName, 'Salamander Detachment' AS DetachmentName
    UNION ALL SELECT 'Combat Walker' AS FormationName, 'Combat Walker Detachment' AS DetachmentName
    UNION ALL SELECT 'Recon Walker' AS FormationName, 'Reconnaissance Walker Detachment' AS DetachmentName
    UNION ALL SELECT 'Pentasaur — Maelstrom Laser' AS FormationName, 'Pentasaur — Maelstrom Laser Detachment' AS DetachmentName
    UNION ALL SELECT 'Pentasaur — Missile' AS FormationName, 'Pentasaur — Missile Launcher Detachment' AS DetachmentName
    UNION ALL SELECT 'Pentasaur — Thermal' AS FormationName, 'Pentasaur — Thermal Lance Detachment' AS DetachmentName
    UNION ALL SELECT 'Carnosaur' AS FormationName, 'Carnosaur Detachment' AS DetachmentName
    UNION ALL SELECT 'Vyper Detachment' AS FormationName, 'Vyper Detachment' AS DetachmentName
) AS src
INNER JOIN Formation f
    ON f.CodexId = @codexId AND f.FormationName = src.FormationName
INNER JOIN Detachment d
    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName;

