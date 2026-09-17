-- Biel-Tan 3.1.0 from C:/Files/NetEpicFR300-EnglishTranslation/Biel-Tan 310
-- Upserts Biel-Tan catalog data. Preserves army lists and Base/Formation ids.

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
SELECT 'Biel-Tan'
WHERE NOT EXISTS (SELECT 1 FROM Codex WHERE CodexName = 'Biel-Tan');

SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Biel-Tan');
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
    (@codexId, 'Warlock', 0, 'Attached', 1, '10', '6+f', '+2', 0),
    (@codexId, 'Swooping Hawks', 0, '5', 1, '20', '6+', '+2', 0),
    (@codexId, 'Warp Spiders', 0, '5', 1, '15', '5+f', '+2', 0),
    (@codexId, 'Harlequins', 0, '5', 1, '15', '6+f', '+6', 0),
    (@codexId, 'Autarch', 0, '4', 1, '15', '5+f', '+8', 0),
    (@codexId, 'Howling Banshees', 0, '5', 1, '15', '6+', '+6', 0),
    (@codexId, 'Bonesinger', 0, 'Attached', 1, '10', '--', '+1', 0),
    (@codexId, 'Fire Dragons', 0, '5', 1, '10', '5+', '+3', 0),
    (@codexId, 'Swooping Hawks Exarch', 0, 'Attached', 1, '20', '6+', '+5', 0),
    (@codexId, 'Warp Spiders Exarch', 0, 'Attached', 1, '15', '5+f', '+5', 0),
    (@codexId, 'Howling Banshees Exarch', 0, 'Attached', 1, '15', '6+', '+8', 0),
    (@codexId, 'Fire Dragons Exarch', 0, 'Attached', 1, '10', '5+', '+5', 0),
    (@codexId, 'Dark Reapers Exarch', 0, 'Attached', 1, '10', '5+', '+3', 0),
    (@codexId, 'Striking Scorpions Exarch', 0, 'Attached', 1, '10', '6+', '+6', 0),
    (@codexId, 'Shadow Spectres Exarch', 0, 'Attached', 1, '15', '6+', '+2', 0),
    (@codexId, 'Dire Avengers Exarch', 0, 'Attached', 1, '10', '6+', '+4', 0),
    (@codexId, 'Dark Reapers', 0, '5', 1, '10', '5+', '+1', 0),
    (@codexId, 'Wraithguard', 0, '--', 1, '10', '5+', '+2', 0),
    (@codexId, 'Guardians', 0, '6', 1, '10', '--', '+0', 0),
    (@codexId, 'Farseer', 0, 'Attached', 1, '10', '6+f', '+3', 0),
    (@codexId, 'Wraithblades', 0, '--', 1, '10', '5+/6+f', '+4', 0),
    (@codexId, 'Striking Scorpions', 0, '5', 1, '10', '6+', '+4', 0),
    (@codexId, 'Rangers', 0, '6', 1, '10', '--', '+0', 0),
    (@codexId, 'Shadow Spectres', 0, '5', 1, '15', '6+', '+0', 0),
    (@codexId, 'Dire Avengers', 0, '5', 1, '10', '6+', '+2', 0),
    (@codexId, 'Forward Observer', 0, 'Attached', 1, '10', '--', '+0', 0),
    (@codexId, 'Bright Lance', 0, '6', 1, '10', '--', '+0', 0),
    (@codexId, 'Vibro Cannon', 0, '6', 1, '10', '--', '+0', 0),
    (@codexId, 'Master Mime', 0, '--', 1, '--', '--', '--', 0),
    (@codexId, 'Shining Spears', 0, '5', 2, '35', '6+', '+5', 0),
    (@codexId, 'Jetbikes', 0, '6', 2, '35', '--', '+3', 0),
    (@codexId, 'Vyper', 0, '6', 2, '35', '6+', '+2', 0),
    (@codexId, 'Shining Spears Exarch', 0, 'Attached', 2, '35', '6+', '+8', 0),
    (@codexId, 'War Walkers', 0, '6', 2, '25', '5+', '+1', 0),
    (@codexId, 'Wasp Assault Walkers', 0, '6', 2, '25', '6+', '+2', 0),
    (@codexId, 'Wraithlord — Assault', 0, '--', 2, '15', '3+/5+f', '+6', 0),
    (@codexId, 'Wraithlord — Support', 0, '--', 2, '15', '4+', '+4', 0),
    (@codexId, 'Crimson Hunter', 0, '6', 3, '--', '4+', '+6', 0),
    (@codexId, 'Falcon', 0, '6', 3, '25', '3+', '+1', 0),
    (@codexId, 'Firestorm', 0, '6', 3, '25', '3+', '+0', 0),
    (@codexId, 'Hornet', 0, '6', 3, '35', '6+', '+2', 0),
    (@codexId, 'Lynx', 0, '6', 3, '25', '2+', '+1', 0),
    (@codexId, 'Night Spinner', 0, '6', 3, '25', '3+', '+1', 0),
    (@codexId, 'Nightwing', 0, '6', 3, '--', '4+', '+4', 0),
    (@codexId, 'Fire Prism', 0, '6', 3, '25', '3+', '+1', 0),
    (@codexId, 'Unicorn', 0, '6', 3, '25', '3+', '+1', 0),
    (@codexId, 'Warp Hunter', 0, '6', 3, '25', '3+', '+1', 0),
    (@codexId, 'Wave Serpent', 0, 'Attached', 3, '25', '3+', '+1', 0),
    (@codexId, 'Avatar', 0, '--', 4, '15', '2+/3+f', '+10', 0),
    (@codexId, 'Baron Fire', 0, 'Attached', 4, '20', '3+', '+8', 0),
    (@codexId, 'Baron Stallion', 0, 'Attached', 4, '25', '3+', '+9', 0),
    (@codexId, 'Bright Stallion', 0, '5', 4, '25', '3+', '+7', 0),
    (@codexId, 'Wraithknight — Assault', 0, '--', 4, '20', '2+/4+f', '+8', 0),
    (@codexId, 'Wraithknight — Support', 0, '--', 4, '15', '3+/5+f', '+4', 0),
    (@codexId, 'Fire Gale', 0, '5', 4, '20', '3+', '+3', 0),
    (@codexId, 'Fire Reaper', 0, '5', 4, '20', '3+', '+3', 0),
    (@codexId, 'Fire Storm', 0, '5', 4, '20', '3+', '+3', 0),
    (@codexId, 'Towering Destroyer', 0, '5', 4, '15', '2+', '+5', 0),
    (@codexId, 'Bright Stalker', 0, '5', 4, '25', '3+', '+5', 0),
    (@codexId, 'Cobra', 0, '5', 4, '25', '2+', '+4', 0),
    (@codexId, 'Storm Serpent', 0, '5', 4, '25', '2+', '+4', 0),
    (@codexId, 'Tempest', 0, '5', 4, '25', '2+', '+4', 0),
    (@codexId, 'Void Spinner', 0, '5', 4, '25', '2+', '+4', 0),
    (@codexId, 'Vampire Raider', 0, '5', 4, '30', '3+', '+1', 0),
    (@codexId, 'Scorpion', 0, '5', 4, '25', '2+', '+4', 0),
    (@codexId, 'Phoenix', 0, '5', 4, '--', '3+', '+1', 0),
    (@codexId, 'Revenant Titan', 0, 'Sheet', 5, '30', '2+ Chart', '+8', 0),
    (@codexId, 'Warlock Titan', 0, 'Sheet', 6, '20', '2+ Chart', '+13', 4),
    (@codexId, 'Phantom Titan', 0, 'Sheet', 6, '20', '2+ Chart', '+13', 4),
    (@codexId, 'Pulsar Barrage', 0, '--', 0, '--', '--', '--', 0),
    (@codexId, 'Web Barrage', 0, '--', 0, '--', '--', '--', 0)
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
    SELECT 'Web' AS n, 'When a detachment with a weapon that has the Web ability shoots at bases in a terrain feature (or at bases occupying one) that grants a cover save, the webs may render it impassable.

Roll 1D6 and consult the following table, counting the number of attack dice with the Web ability firing at the terrain feature.

| To-Hit | Number of dice |
| --- | --- |
| 6+ | 1 |
| 5+ | 2 |
| 4+ | 3 |
| 3+ | 4+ |

If the terrain becomes impassable, it also becomes Dangerous Terrain, with the same effects and To-Hit / AP as the weapon firing the web. The terrain remains impassable for 2 turns, the web disappearing at the end of the turn after it was fired.' AS d
    UNION ALL SELECT 'Spirit Stone' AS n, 'A base with the Spirit Stone rule has the Inorganic and Fearless abilities.

A detachment with the Spirit Stone ability must always remain within 12 cm of an allied living Aeldari detachment (one that does not have Spirit Stone), and duplicates that detachment''s orders. If there are several such detachments, choose which living detachment''s orders to duplicate.

Detachments with Spirit Stone within range of an allied Psychic Node receive orders freely.

If at the start of the Orders Phase the detachment is more than 12 cm from any allied living Aeldari detachment and outside any Psychic Node, it receives a Charge order and moves toward the nearest allied living Aeldari detachment without engaging enemy detachments (it goes around them by the shortest path). It may only engage an enemy detachment that is itself engaged against the nearest allied Aeldari detachment. If there is no living Aeldari on the table, Spirit Stone detachments are considered to have No Orders.' AS d
    UNION ALL SELECT 'Cannot Be Blocked' AS n, 'Bases with this ability may always disengage from an assault with no opportunity attack possible, and ignore terrain and enemy control zones during their movement.' AS d
    UNION ALL SELECT 'Holo-Field' AS n, 'A Holo-Field grants Protection against all shooting according to the protected base''s order.

| Protection | Order |
| --- | --- |
| 5+ | First Fire / Immobilised |
| 4+ | Advance / Fall Back |
| 3+ | Charge / Forced March |' AS d
    UNION ALL SELECT 'Vibro Cannon (-X)' AS n, 'When a detachment or a weapon with the Vibro Cannon ability fires, trace a single imaginary line per detachment from one of the bases to its target. All bases crossed by this line are hit with an AP equal to -X times the number of weapons firing at the same time.

The shot has the Reduces Cover (-1), Subterranean Fire, and Damages Buildings (2/-X) abilities, with an AP equal to -X times the number of weapons firing at the same time.

Vibro Cannons cannot make Intercept Fire. For a structure, half of the bases present in garrison are hit. Due to its nature, it stops at the first structure it encounters, which it may damage.' AS d
    UNION ALL SELECT 'Psychic Node (X)' AS n, 'All Spirit Stone detachments within X cm may receive orders normally.' AS d
    UNION ALL SELECT 'Prescience (X)' AS n, 'All Aeldari detachments within X cm of the base with this ability do not need to receive orders during the Orders Phase. Instead they receive an order during the Movement Phase when they are activated, by placing an order in front of them. This power does not function on troops that follow the Spirit Stone rule.' AS d
    UNION ALL SELECT 'Banshee Cry (X+)' AS n, 'The cry of the Howling Banshees acts as a Lance (X+/psi), being Psychic Attacks. This lance functions only against Classes 1 and 2. In addition, a Class 1 or 2 detachment charged by Howling Banshees cannot make Intercept Fire.' AS d
    UNION ALL SELECT 'Fire Prism' AS n, 'These cannons may fire at another Fire Prism, using it as a relay for their shot. A Fire Prism may target a second Fire Prism if it is in range and in Line of Sight. This redirection is automatic. The second Fire Prism is then immediately activated to shoot, and may also use its own shots if it wishes. There is no limit to the number of possible redirections.' AS d
    UNION ALL SELECT 'Ghost Portal' AS n, 'A Storm Serpent may open a Ghost Portal at any point of its movement in Line of Sight and within 60 cm. Place a marker to record the portal''s location; bases enter or leave the portal within a radius of 6 cm. The portal cannot be placed on an enemy troop or in a structure.

Once the portal is open, Aeldari Infantry, Cavalry, or Walker bases may enter either the Ghost Portal or the Storm Serpent, normally losing 5 cm of movement as when boarding a transport. The base in transit reappears at the other end of the Storm Serpent–Portal link and cannot exit into an enemy control zone of equal or higher class. The Storm Serpent may move without breaking the link that binds it to the portal.' AS d
    UNION ALL SELECT '3D6 in Assault against Classes 1 and 2' AS n, 'A base with this ability rolls 3D6 instead of 2D6 in assault against Class 1 and 2 bases.' AS d
    UNION ALL SELECT 'Master Mime' AS n, 'The Master Mime is not deployed on the battlefield. Instead, the Formation is used once per game and is then no longer usable. As the Master Mime cannot be destroyed, it is considered Broken as soon as it is played.

Play the Master Mime on an enemy detachment during the Initial Phase, just after all orders have been given. The targeted detachment automatically loses its order and may no longer receive another until it has unmasked the Master Mime (it then acts as a detachment with no order). To do so, the detachment takes a Morale test during each End Phase. As soon as it succeeds, the Master Mime is discovered and the detachment may receive orders again on the following turn.

The Master Mime cannot be played against a detachment with no Morale value, or against Daemonic, Robotic, Flyer, Floating, or Tyranid detachments.' AS d
    UNION ALL SELECT 'Harlequins' AS n, 'Harlequins are immune to Morale and to all morale-based powers if they are fighting a Chaos army.' AS d
    UNION ALL SELECT 'Inorganic' AS n, 'A base with this ability is immune to certain effects. The descriptions of those effects specify when this immunity applies.' AS d
    UNION ALL SELECT 'Fearless' AS n, 'A detachment with this ability automatically passes all Morale Tests.' AS d
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
    UNION ALL SELECT 'Fire on the Move' AS n, 'A base with this ability and an Advance order may move normally.

At the end of its movement, replace its Advance order with an unrevealed First Fire order. It may subsequently perform Overwatch Fire, but doing so imposes an additional -1 To-Hit penalty.

Regardless of whether it performs Overwatch Fire, it does not reroll results of 1 when shooting.' AS d
    UNION ALL SELECT 'Lightning Attack' AS n, 'A base with this ability may make a 10 cm Take Position move instead of a 5 cm move when resolving an assault.' AS d
    UNION ALL SELECT 'Reroll Assault Dice' AS n, 'A base with this ability may reroll its assault dice. If it does so, it must reroll all of them.' AS d
    UNION ALL SELECT 'HQ' AS n, 'When an HQ base is targeted by a shooting attack, its controlling player may select another base of the same class within 6 cm as the attack''s target instead.

This decision must be made before any saving throws are rolled. HQ protection does not function during an assault.' AS d
    UNION ALL SELECT 'Attached Character' AS n, 'At the beginning of the battle, an Attached Character must join a detachment. The character and the detachment are then treated as a single detachment.

The Attached Character must remain in coherency with the detachment, uses its Morale value, and adds its points cost to the detachment''s total cost.

Attached Characters do not occupy space in transports. A single detachment may include up to two Attached Characters.

An Attached Character gains the Movement characteristic of the detachment to which it is attached, and its movement-related special abilities.' AS d
    UNION ALL SELECT 'Character' AS n, 'Characters represent important individuals who distinguish themselves within an army. This ability is relevant in certain scenarios.' AS d
    UNION ALL SELECT 'Psyker' AS n, 'During the Combat Phase, a Psyker may use both one psychic power and its conventional weapons.

Powers marked Shooting follow the same rules and restrictions as standard shooting attacks.

A power used during the Movement Phase may be used at any point during the Psyker''s movement activation. Unless otherwise stated, psychic powers have a 360 degree firing arc.' AS d
    UNION ALL SELECT 'Psychic Save (X+)' AS n, 'A base with Psychic Save (X+) may use this saving throw against psychic powers.' AS d
    UNION ALL SELECT 'Charismatic (X)' AS n, 'All allied detachments with at least one base within X cm of a base with this ability receive a +1 bonus to their Morale value.

During Rally Tests in the End Phase, a Rally Test may also be attempted for a detachment within X cm of the Charismatic base.' AS d
    UNION ALL SELECT 'Mechanic' AS n, 'Any Walker or Vehicle detachment with at least one base within 6 cm of a base with this ability gains Regeneration (5+).

If the affected base already has Regeneration, improve its Regeneration value by 1.

This ability does not function while the Mechanic is inside a transport.' AS d
    UNION ALL SELECT 'Urban Combat' AS n, 'When resolving an assault, opponents of a base with this ability receive no AF bonuses from terrain features.' AS d
    UNION ALL SELECT 'Damage (+X) in Assault' AS n, 'A weapon with this ability inflicts X additional hits after its base wins a duel, in addition to the normal hit.' AS d
    UNION ALL SELECT 'Damage (+X)' AS n, 'A weapon with this ability inflicts X additional hits against a base successfully hit by the weapon.' AS d
    UNION ALL SELECT 'Reduces Cover (X)' AS n, 'A weapon with this ability worsens the target''s cover save by X.' AS d
    UNION ALL SELECT 'Reflex Fire' AS n, 'A base with this ability does not suffer the normal -1 To-Hit penalty when performing Overwatch Fire.' AS d
    UNION ALL SELECT 'Infiltration' AS n, 'After deployment, bases with this ability may move up to 25 cm. This movement cannot bring a base into an enemy zone of control and cannot be performed while the detachment is being transported.' AS d
    UNION ALL SELECT 'Camouflage' AS n, 'If a base occupies terrain that provides a cover save, improve that cover save by 1. Improve it by a further 1 if the entire detachment has not yet fired and gives up its ability to fire during the current turn. Camouflage only functions against enemy bases more than 25 cm away. A base engaged in an assault loses Camouflage for the remainder of the turn.' AS d
    UNION ALL SELECT 'Sniper' AS n, 'When a base with the Sniper ability targets an HQ base, roll 1D6. On a result of 4+, the target cannot use its HQ ability against the Sniper''s attack.' AS d
    UNION ALL SELECT 'Forward Observer (FO)' AS n, 'A Forward Observer may observe and direct Indirect Artillery Fire.

Forward Observers are also the only bases capable of calling in Off-Table Artillery attacks.' AS d
    UNION ALL SELECT 'Antigrav' AS n, 'A base with Antigrav may make short flights over terrain, buildings, and enemy troops.

It ignores terrain movement penalties and enemy zones of control except those generated by bases with Floater, Skimmer, Jump Packs, or Antigrav.

While moving over an obstacle it is considered to be at altitude. It cannot end its movement on Impassable terrain.' AS d
    UNION ALL SELECT 'Lance (X+ / Y)' AS n, 'When a base with the Lance ability engages a target in an assault, it may make a shooting attack against that target on contact during Charge or Consolidation.

The target is hit on X+ with AP Y. Lances ignore Holo-Fields and energy/deflector shields, and resolve simultaneously with Close Defences.

If the target is destroyed and has lower Blocking Class, the attacker may continue moving but cannot use its Lance again that movement.' AS d
    UNION ALL SELECT 'Dodge (X+)' AS n, 'When a base with this ability loses Wounds in an assault, roll one die for each Wound lost. For each result of X+, the base does not lose that Wound.

Dodge may also be used against hits caused by Close Defences.' AS d
    UNION ALL SELECT 'Integral Armour' AS n, 'A base with Integral Armour does not use a hit-location chart. Every hit is resolved against the base as a whole using its armour save.' AS d
    UNION ALL SELECT 'Flyer' AS n, 'Flyers may deploy on the battlefield or begin off-table (they cannot enter before Turn 2).

Advance: ground-attack mission; Protection (4+). Charge: Aerial Interception (if Interceptor) or charge altitude targets; Protection (3+). Forced March: evasive manoeuvres with Snap Fire, may land; Protection (3+).

At altitude, Flyers move in a straight line with unlimited Movement (minimum 45 cm), ignore terrain and zones of control, and are never pinned. They may leave the table and must remain off-table for one complete turn before returning.' AS d
    UNION ALL SELECT 'Interceptor' AS n, 'A detachment with this ability may perform Aerial Interceptions. See the Flyer rules for further details.' AS d
    UNION ALL SELECT 'Transport (X)' AS n, 'A base with Transport (X) may transport X Infantry bases.

Entering or leaving a transport costs the transported bases 5 cm of movement. A transport with a capacity of 6 or more may transport Walker bases (each Walker occupies two Infantry spaces).' AS d
    UNION ALL SELECT 'Attached Transport' AS n, 'Attached Transports and the bases they transport are treated as a single detachment.

The transports use the Morale value of the detachment to which they are attached. The transport group and transported group receive separate orders but are activated simultaneously. They have Extended Coherency (25 cm) with one another.

The transported troops may begin the battle either embarked or outside their transports.' AS d
    UNION ALL SELECT 'Protection (X+)' AS n, 'Protection is a fixed saving throw made before all other saving throws. It may be used in addition to other types of saving throw.

A base cannot benefit from more than one Protection save. If several are available, use the best one.' AS d
    UNION ALL SELECT 'Protection (X+) to the Front' AS n, 'This base has Protection (X+) against attacks originating within its front arc only.' AS d
    UNION ALL SELECT 'Anti-Aircraft' AS n, 'These weapons operate independently and may be activated separately from a base''s other weapons.

If the base has a First Fire order, these weapons may perform Overwatch Fire against targets at altitude without suffering the usual To-Hit penalty. They may also perform Overwatch Fire while the base has an Advance order, but suffer the normal -1 To-Hit penalty.

Weapons with this ability always have a 360 degree firing arc and reduce a Flyer''s Protection save by 2.

When firing at targets that are not at altitude, these weapons function normally but suffer a -1 To-Hit penalty.' AS d
    UNION ALL SELECT 'Turret' AS n, 'A weapon with the Turret ability has a 360 degree firing arc.' AS d
    UNION ALL SELECT 'Artillery' AS n, 'Weapons with the Artillery ability fire in a high arc and may shoot without line of sight.

Obstructing terrain crossed by the attack does not provide protection. If the targets are inside the terrain feature, they receive its cover save normally.

Artillery cannot target bases at altitude or perform Overwatch Fire.

Weapons with this ability may perform Indirect Fire against targets the firing base cannot see. To do so, the artillery base must have a First Fire order. Observed Indirect Fire requires a Forward Observer and suffers -1 To-Hit; unobserved Indirect Fire suffers -2 To-Hit.' AS d
    UNION ALL SELECT 'Template (X)' AS n, 'Templates have an area of effect and may therefore affect more than one target.

Any base whose centre is covered by a template may be hit, depending on the template weapon''s To-Hit roll.

Obstructing terrain crossed by a template attack does not provide protection. However, a target inside such terrain receives its cover save normally.' AS d
    UNION ALL SELECT 'Psychic Attack' AS n, 'A Psychic Attack can only be negated by a Psychic Save.

Wounds lost to a Psychic Attack cannot be recovered using Regeneration. Cover saves cannot be used against this type of power.

If the target has a hit-location chart, the attack always hits its bridge or head location.' AS d
    UNION ALL SELECT 'Damages Buildings (AP -X / Y)' AS n, 'A base with a weapon possessing this ability may attack destructible terrain features.

When using a template weapon, the centre of the template must be positioned over the structure for it to be hit.

The structure must make Y saving throws with an AP modifier of -X. It loses one Wound for each failed save. Saving throws made by structures use the total result of 2D6.' AS d
    UNION ALL SELECT 'Wounds (X)' AS n, 'A base with this ability has X Wounds, allowing it to survive multiple injuries.

By default, a base has only one Wound.' AS d
    UNION ALL SELECT 'Close Defences (X+)' AS n, 'Every Class 1 or 2 base that engages, or is engaged by, a base with Close Defences suffers a hit on X+ with AP 0.

Resolve the attack when the bases make contact. Cover saves may be used against Close Defences.' AS d
    UNION ALL SELECT 'Terror' AS n, 'A detachment engaged in an assault by a base with the Terror ability must make a Morale Test with a -1 modifier. If failed, it immediately receives a Fall Back order but does not make a Fall Back move.

A detachment attempting to engage a base with Terror must also pass a Morale Test with a -1 modifier or stop before entering the Terror-causing base''s zone of control.

Bases with Terror are immune to Terror.' AS d
    UNION ALL SELECT 'Multiple Hits (X)' AS n, 'When this weapon successfully hits a target, it inflicts X hits instead of one.' AS d
    UNION ALL SELECT 'Bombing (X)' AS n, 'Flyers and Floating bases at altitude may drop X bombs during their movement. Resolve each attack immediately during the movement, following the normal shooting procedure.

Bombs cannot be dropped while the detachment has a Charge order and cannot affect targets at altitude.

If the weapon uses templates, all its templates must touch one another and are treated as a single template. The templates must be centred on the axis of the bombing base''s movement.' AS d
    UNION ALL SELECT 'Agile' AS n, 'A Titan or Praetorian with this ability is not limited to a total of 90 degrees of turning during each turn.' AS d
    UNION ALL SELECT 'Extended Coherency (X)' AS n, 'The coherency distance of bases with this ability is X cm instead of 6 cm.

A detachment engaging a detachment with Extended Coherency does not need to engage all its bases before engaging another detachment.' AS d
    UNION ALL SELECT 'Off-Table Artillery' AS n, 'Off-Table Artillery represents batteries of extremely long-ranged weapons deployed far from the battlefield, including orbital bombardments and naval artillery.

Off-Table Artillery is purchased normally when creating the army list and may only be used once. Different types are listed in the relevant Codex, and the type used is selected when the attack is called.

To call an Off-Table Artillery attack, an unpinned Forward Observer must have line of sight to the targeted point.' AS d
    UNION ALL SELECT 'Confusion (-X)' AS n, 'A base with this ability may attempt to change the order assigned to an enemy detachment that has at least one base within 25 cm and has not yet been activated during the Movement Phase.

The affected detachment must make a Morale Test with a modifier of -X. If the test is failed, its order is changed according to a 1D6 roll.' AS d
    UNION ALL SELECT 'Dread (-X)' AS n, 'When activated during the Combat Phase, a base with this ability may force one enemy detachment with at least one base within 20 cm to make a Morale Test.

The test suffers a modifier of -X. If it is failed, the detachment receives a Fall Back order and immediately makes a Fall Back move.

A detachment cannot be targeted by this ability more than once during the same turn.' AS d
    UNION ALL SELECT 'Subterranean Fire' AS n, 'Attacks with this ability ignore Energy Shields, Energy Fields, and Deflector Shields.

They have no effect against Skimmers or bases at altitude.

Against a base with a hit-location chart, Subterranean Fire always hits its lowest location, Location 1.' AS d
    UNION ALL SELECT 'Titan Blade' AS n, 'When using a Titan Blade, choose one effect:

 • Shooting with the weapon''s listed profile.
 • Reroll Assault Dice with Damage (+2).
 • First Strike (1 / 2+ / AP -5), Damage (+1).
 • Damages Buildings (AP -5 / 3) in Assault.' AS d
    UNION ALL SELECT 'Combat Fist' AS n, 'When using a Combat Fist, choose one effect:

 • Shooting with the weapon''s listed profile.
 • Adds 1D6 to AF with Damage (+2).
 • First Strike (1 / 2+ / AP -4), Damage (+1).
 • Damages Buildings (AP -4 / 3) in Assault.' AS d
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM SpecialAbility sa WHERE sa.SpecialAbilityName = src.n
);

UPDATE SpecialAbility sa
INNER JOIN (
    SELECT 'Web' AS n, 'When a detachment with a weapon that has the Web ability shoots at bases in a terrain feature (or at bases occupying one) that grants a cover save, the webs may render it impassable.

Roll 1D6 and consult the following table, counting the number of attack dice with the Web ability firing at the terrain feature.

| To-Hit | Number of dice |
| --- | --- |
| 6+ | 1 |
| 5+ | 2 |
| 4+ | 3 |
| 3+ | 4+ |

If the terrain becomes impassable, it also becomes Dangerous Terrain, with the same effects and To-Hit / AP as the weapon firing the web. The terrain remains impassable for 2 turns, the web disappearing at the end of the turn after it was fired.' AS d
    UNION ALL SELECT 'Spirit Stone' AS n, 'A base with the Spirit Stone rule has the Inorganic and Fearless abilities.

A detachment with the Spirit Stone ability must always remain within 12 cm of an allied living Aeldari detachment (one that does not have Spirit Stone), and duplicates that detachment''s orders. If there are several such detachments, choose which living detachment''s orders to duplicate.

Detachments with Spirit Stone within range of an allied Psychic Node receive orders freely.

If at the start of the Orders Phase the detachment is more than 12 cm from any allied living Aeldari detachment and outside any Psychic Node, it receives a Charge order and moves toward the nearest allied living Aeldari detachment without engaging enemy detachments (it goes around them by the shortest path). It may only engage an enemy detachment that is itself engaged against the nearest allied Aeldari detachment. If there is no living Aeldari on the table, Spirit Stone detachments are considered to have No Orders.' AS d
    UNION ALL SELECT 'Cannot Be Blocked' AS n, 'Bases with this ability may always disengage from an assault with no opportunity attack possible, and ignore terrain and enemy control zones during their movement.' AS d
    UNION ALL SELECT 'Holo-Field' AS n, 'A Holo-Field grants Protection against all shooting according to the protected base''s order.

| Protection | Order |
| --- | --- |
| 5+ | First Fire / Immobilised |
| 4+ | Advance / Fall Back |
| 3+ | Charge / Forced March |' AS d
    UNION ALL SELECT 'Vibro Cannon (-X)' AS n, 'When a detachment or a weapon with the Vibro Cannon ability fires, trace a single imaginary line per detachment from one of the bases to its target. All bases crossed by this line are hit with an AP equal to -X times the number of weapons firing at the same time.

The shot has the Reduces Cover (-1), Subterranean Fire, and Damages Buildings (2/-X) abilities, with an AP equal to -X times the number of weapons firing at the same time.

Vibro Cannons cannot make Intercept Fire. For a structure, half of the bases present in garrison are hit. Due to its nature, it stops at the first structure it encounters, which it may damage.' AS d
    UNION ALL SELECT 'Psychic Node (X)' AS n, 'All Spirit Stone detachments within X cm may receive orders normally.' AS d
    UNION ALL SELECT 'Prescience (X)' AS n, 'All Aeldari detachments within X cm of the base with this ability do not need to receive orders during the Orders Phase. Instead they receive an order during the Movement Phase when they are activated, by placing an order in front of them. This power does not function on troops that follow the Spirit Stone rule.' AS d
    UNION ALL SELECT 'Banshee Cry (X+)' AS n, 'The cry of the Howling Banshees acts as a Lance (X+/psi), being Psychic Attacks. This lance functions only against Classes 1 and 2. In addition, a Class 1 or 2 detachment charged by Howling Banshees cannot make Intercept Fire.' AS d
    UNION ALL SELECT 'Fire Prism' AS n, 'These cannons may fire at another Fire Prism, using it as a relay for their shot. A Fire Prism may target a second Fire Prism if it is in range and in Line of Sight. This redirection is automatic. The second Fire Prism is then immediately activated to shoot, and may also use its own shots if it wishes. There is no limit to the number of possible redirections.' AS d
    UNION ALL SELECT 'Ghost Portal' AS n, 'A Storm Serpent may open a Ghost Portal at any point of its movement in Line of Sight and within 60 cm. Place a marker to record the portal''s location; bases enter or leave the portal within a radius of 6 cm. The portal cannot be placed on an enemy troop or in a structure.

Once the portal is open, Aeldari Infantry, Cavalry, or Walker bases may enter either the Ghost Portal or the Storm Serpent, normally losing 5 cm of movement as when boarding a transport. The base in transit reappears at the other end of the Storm Serpent–Portal link and cannot exit into an enemy control zone of equal or higher class. The Storm Serpent may move without breaking the link that binds it to the portal.' AS d
    UNION ALL SELECT '3D6 in Assault against Classes 1 and 2' AS n, 'A base with this ability rolls 3D6 instead of 2D6 in assault against Class 1 and 2 bases.' AS d
    UNION ALL SELECT 'Master Mime' AS n, 'The Master Mime is not deployed on the battlefield. Instead, the Formation is used once per game and is then no longer usable. As the Master Mime cannot be destroyed, it is considered Broken as soon as it is played.

Play the Master Mime on an enemy detachment during the Initial Phase, just after all orders have been given. The targeted detachment automatically loses its order and may no longer receive another until it has unmasked the Master Mime (it then acts as a detachment with no order). To do so, the detachment takes a Morale test during each End Phase. As soon as it succeeds, the Master Mime is discovered and the detachment may receive orders again on the following turn.

The Master Mime cannot be played against a detachment with no Morale value, or against Daemonic, Robotic, Flyer, Floating, or Tyranid detachments.' AS d
    UNION ALL SELECT 'Harlequins' AS n, 'Harlequins are immune to Morale and to all morale-based powers if they are fighting a Chaos army.' AS d
    UNION ALL SELECT 'Inorganic' AS n, 'A base with this ability is immune to certain effects. The descriptions of those effects specify when this immunity applies.' AS d
    UNION ALL SELECT 'Fearless' AS n, 'A detachment with this ability automatically passes all Morale Tests.' AS d
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
    UNION ALL SELECT 'Fire on the Move' AS n, 'A base with this ability and an Advance order may move normally.

At the end of its movement, replace its Advance order with an unrevealed First Fire order. It may subsequently perform Overwatch Fire, but doing so imposes an additional -1 To-Hit penalty.

Regardless of whether it performs Overwatch Fire, it does not reroll results of 1 when shooting.' AS d
    UNION ALL SELECT 'Lightning Attack' AS n, 'A base with this ability may make a 10 cm Take Position move instead of a 5 cm move when resolving an assault.' AS d
    UNION ALL SELECT 'Reroll Assault Dice' AS n, 'A base with this ability may reroll its assault dice. If it does so, it must reroll all of them.' AS d
    UNION ALL SELECT 'HQ' AS n, 'When an HQ base is targeted by a shooting attack, its controlling player may select another base of the same class within 6 cm as the attack''s target instead.

This decision must be made before any saving throws are rolled. HQ protection does not function during an assault.' AS d
    UNION ALL SELECT 'Attached Character' AS n, 'At the beginning of the battle, an Attached Character must join a detachment. The character and the detachment are then treated as a single detachment.

The Attached Character must remain in coherency with the detachment, uses its Morale value, and adds its points cost to the detachment''s total cost.

Attached Characters do not occupy space in transports. A single detachment may include up to two Attached Characters.

An Attached Character gains the Movement characteristic of the detachment to which it is attached, and its movement-related special abilities.' AS d
    UNION ALL SELECT 'Character' AS n, 'Characters represent important individuals who distinguish themselves within an army. This ability is relevant in certain scenarios.' AS d
    UNION ALL SELECT 'Psyker' AS n, 'During the Combat Phase, a Psyker may use both one psychic power and its conventional weapons.

Powers marked Shooting follow the same rules and restrictions as standard shooting attacks.

A power used during the Movement Phase may be used at any point during the Psyker''s movement activation. Unless otherwise stated, psychic powers have a 360 degree firing arc.' AS d
    UNION ALL SELECT 'Psychic Save (X+)' AS n, 'A base with Psychic Save (X+) may use this saving throw against psychic powers.' AS d
    UNION ALL SELECT 'Charismatic (X)' AS n, 'All allied detachments with at least one base within X cm of a base with this ability receive a +1 bonus to their Morale value.

During Rally Tests in the End Phase, a Rally Test may also be attempted for a detachment within X cm of the Charismatic base.' AS d
    UNION ALL SELECT 'Mechanic' AS n, 'Any Walker or Vehicle detachment with at least one base within 6 cm of a base with this ability gains Regeneration (5+).

If the affected base already has Regeneration, improve its Regeneration value by 1.

This ability does not function while the Mechanic is inside a transport.' AS d
    UNION ALL SELECT 'Urban Combat' AS n, 'When resolving an assault, opponents of a base with this ability receive no AF bonuses from terrain features.' AS d
    UNION ALL SELECT 'Damage (+X) in Assault' AS n, 'A weapon with this ability inflicts X additional hits after its base wins a duel, in addition to the normal hit.' AS d
    UNION ALL SELECT 'Damage (+X)' AS n, 'A weapon with this ability inflicts X additional hits against a base successfully hit by the weapon.' AS d
    UNION ALL SELECT 'Reduces Cover (X)' AS n, 'A weapon with this ability worsens the target''s cover save by X.' AS d
    UNION ALL SELECT 'Reflex Fire' AS n, 'A base with this ability does not suffer the normal -1 To-Hit penalty when performing Overwatch Fire.' AS d
    UNION ALL SELECT 'Infiltration' AS n, 'After deployment, bases with this ability may move up to 25 cm. This movement cannot bring a base into an enemy zone of control and cannot be performed while the detachment is being transported.' AS d
    UNION ALL SELECT 'Camouflage' AS n, 'If a base occupies terrain that provides a cover save, improve that cover save by 1. Improve it by a further 1 if the entire detachment has not yet fired and gives up its ability to fire during the current turn. Camouflage only functions against enemy bases more than 25 cm away. A base engaged in an assault loses Camouflage for the remainder of the turn.' AS d
    UNION ALL SELECT 'Sniper' AS n, 'When a base with the Sniper ability targets an HQ base, roll 1D6. On a result of 4+, the target cannot use its HQ ability against the Sniper''s attack.' AS d
    UNION ALL SELECT 'Forward Observer (FO)' AS n, 'A Forward Observer may observe and direct Indirect Artillery Fire.

Forward Observers are also the only bases capable of calling in Off-Table Artillery attacks.' AS d
    UNION ALL SELECT 'Antigrav' AS n, 'A base with Antigrav may make short flights over terrain, buildings, and enemy troops.

It ignores terrain movement penalties and enemy zones of control except those generated by bases with Floater, Skimmer, Jump Packs, or Antigrav.

While moving over an obstacle it is considered to be at altitude. It cannot end its movement on Impassable terrain.' AS d
    UNION ALL SELECT 'Lance (X+ / Y)' AS n, 'When a base with the Lance ability engages a target in an assault, it may make a shooting attack against that target on contact during Charge or Consolidation.

The target is hit on X+ with AP Y. Lances ignore Holo-Fields and energy/deflector shields, and resolve simultaneously with Close Defences.

If the target is destroyed and has lower Blocking Class, the attacker may continue moving but cannot use its Lance again that movement.' AS d
    UNION ALL SELECT 'Dodge (X+)' AS n, 'When a base with this ability loses Wounds in an assault, roll one die for each Wound lost. For each result of X+, the base does not lose that Wound.

Dodge may also be used against hits caused by Close Defences.' AS d
    UNION ALL SELECT 'Integral Armour' AS n, 'A base with Integral Armour does not use a hit-location chart. Every hit is resolved against the base as a whole using its armour save.' AS d
    UNION ALL SELECT 'Flyer' AS n, 'Flyers may deploy on the battlefield or begin off-table (they cannot enter before Turn 2).

Advance: ground-attack mission; Protection (4+). Charge: Aerial Interception (if Interceptor) or charge altitude targets; Protection (3+). Forced March: evasive manoeuvres with Snap Fire, may land; Protection (3+).

At altitude, Flyers move in a straight line with unlimited Movement (minimum 45 cm), ignore terrain and zones of control, and are never pinned. They may leave the table and must remain off-table for one complete turn before returning.' AS d
    UNION ALL SELECT 'Interceptor' AS n, 'A detachment with this ability may perform Aerial Interceptions. See the Flyer rules for further details.' AS d
    UNION ALL SELECT 'Transport (X)' AS n, 'A base with Transport (X) may transport X Infantry bases.

Entering or leaving a transport costs the transported bases 5 cm of movement. A transport with a capacity of 6 or more may transport Walker bases (each Walker occupies two Infantry spaces).' AS d
    UNION ALL SELECT 'Attached Transport' AS n, 'Attached Transports and the bases they transport are treated as a single detachment.

The transports use the Morale value of the detachment to which they are attached. The transport group and transported group receive separate orders but are activated simultaneously. They have Extended Coherency (25 cm) with one another.

The transported troops may begin the battle either embarked or outside their transports.' AS d
    UNION ALL SELECT 'Protection (X+)' AS n, 'Protection is a fixed saving throw made before all other saving throws. It may be used in addition to other types of saving throw.

A base cannot benefit from more than one Protection save. If several are available, use the best one.' AS d
    UNION ALL SELECT 'Protection (X+) to the Front' AS n, 'This base has Protection (X+) against attacks originating within its front arc only.' AS d
    UNION ALL SELECT 'Anti-Aircraft' AS n, 'These weapons operate independently and may be activated separately from a base''s other weapons.

If the base has a First Fire order, these weapons may perform Overwatch Fire against targets at altitude without suffering the usual To-Hit penalty. They may also perform Overwatch Fire while the base has an Advance order, but suffer the normal -1 To-Hit penalty.

Weapons with this ability always have a 360 degree firing arc and reduce a Flyer''s Protection save by 2.

When firing at targets that are not at altitude, these weapons function normally but suffer a -1 To-Hit penalty.' AS d
    UNION ALL SELECT 'Turret' AS n, 'A weapon with the Turret ability has a 360 degree firing arc.' AS d
    UNION ALL SELECT 'Artillery' AS n, 'Weapons with the Artillery ability fire in a high arc and may shoot without line of sight.

Obstructing terrain crossed by the attack does not provide protection. If the targets are inside the terrain feature, they receive its cover save normally.

Artillery cannot target bases at altitude or perform Overwatch Fire.

Weapons with this ability may perform Indirect Fire against targets the firing base cannot see. To do so, the artillery base must have a First Fire order. Observed Indirect Fire requires a Forward Observer and suffers -1 To-Hit; unobserved Indirect Fire suffers -2 To-Hit.' AS d
    UNION ALL SELECT 'Template (X)' AS n, 'Templates have an area of effect and may therefore affect more than one target.

Any base whose centre is covered by a template may be hit, depending on the template weapon''s To-Hit roll.

Obstructing terrain crossed by a template attack does not provide protection. However, a target inside such terrain receives its cover save normally.' AS d
    UNION ALL SELECT 'Psychic Attack' AS n, 'A Psychic Attack can only be negated by a Psychic Save.

Wounds lost to a Psychic Attack cannot be recovered using Regeneration. Cover saves cannot be used against this type of power.

If the target has a hit-location chart, the attack always hits its bridge or head location.' AS d
    UNION ALL SELECT 'Damages Buildings (AP -X / Y)' AS n, 'A base with a weapon possessing this ability may attack destructible terrain features.

When using a template weapon, the centre of the template must be positioned over the structure for it to be hit.

The structure must make Y saving throws with an AP modifier of -X. It loses one Wound for each failed save. Saving throws made by structures use the total result of 2D6.' AS d
    UNION ALL SELECT 'Wounds (X)' AS n, 'A base with this ability has X Wounds, allowing it to survive multiple injuries.

By default, a base has only one Wound.' AS d
    UNION ALL SELECT 'Close Defences (X+)' AS n, 'Every Class 1 or 2 base that engages, or is engaged by, a base with Close Defences suffers a hit on X+ with AP 0.

Resolve the attack when the bases make contact. Cover saves may be used against Close Defences.' AS d
    UNION ALL SELECT 'Terror' AS n, 'A detachment engaged in an assault by a base with the Terror ability must make a Morale Test with a -1 modifier. If failed, it immediately receives a Fall Back order but does not make a Fall Back move.

A detachment attempting to engage a base with Terror must also pass a Morale Test with a -1 modifier or stop before entering the Terror-causing base''s zone of control.

Bases with Terror are immune to Terror.' AS d
    UNION ALL SELECT 'Multiple Hits (X)' AS n, 'When this weapon successfully hits a target, it inflicts X hits instead of one.' AS d
    UNION ALL SELECT 'Bombing (X)' AS n, 'Flyers and Floating bases at altitude may drop X bombs during their movement. Resolve each attack immediately during the movement, following the normal shooting procedure.

Bombs cannot be dropped while the detachment has a Charge order and cannot affect targets at altitude.

If the weapon uses templates, all its templates must touch one another and are treated as a single template. The templates must be centred on the axis of the bombing base''s movement.' AS d
    UNION ALL SELECT 'Agile' AS n, 'A Titan or Praetorian with this ability is not limited to a total of 90 degrees of turning during each turn.' AS d
    UNION ALL SELECT 'Extended Coherency (X)' AS n, 'The coherency distance of bases with this ability is X cm instead of 6 cm.

A detachment engaging a detachment with Extended Coherency does not need to engage all its bases before engaging another detachment.' AS d
    UNION ALL SELECT 'Off-Table Artillery' AS n, 'Off-Table Artillery represents batteries of extremely long-ranged weapons deployed far from the battlefield, including orbital bombardments and naval artillery.

Off-Table Artillery is purchased normally when creating the army list and may only be used once. Different types are listed in the relevant Codex, and the type used is selected when the attack is called.

To call an Off-Table Artillery attack, an unpinned Forward Observer must have line of sight to the targeted point.' AS d
    UNION ALL SELECT 'Confusion (-X)' AS n, 'A base with this ability may attempt to change the order assigned to an enemy detachment that has at least one base within 25 cm and has not yet been activated during the Movement Phase.

The affected detachment must make a Morale Test with a modifier of -X. If the test is failed, its order is changed according to a 1D6 roll.' AS d
    UNION ALL SELECT 'Dread (-X)' AS n, 'When activated during the Combat Phase, a base with this ability may force one enemy detachment with at least one base within 20 cm to make a Morale Test.

The test suffers a modifier of -X. If it is failed, the detachment receives a Fall Back order and immediately makes a Fall Back move.

A detachment cannot be targeted by this ability more than once during the same turn.' AS d
    UNION ALL SELECT 'Subterranean Fire' AS n, 'Attacks with this ability ignore Energy Shields, Energy Fields, and Deflector Shields.

They have no effect against Skimmers or bases at altitude.

Against a base with a hit-location chart, Subterranean Fire always hits its lowest location, Location 1.' AS d
    UNION ALL SELECT 'Titan Blade' AS n, 'When using a Titan Blade, choose one effect:

 • Shooting with the weapon''s listed profile.
 • Reroll Assault Dice with Damage (+2).
 • First Strike (1 / 2+ / AP -5), Damage (+1).
 • Damages Buildings (AP -5 / 3) in Assault.' AS d
    UNION ALL SELECT 'Combat Fist' AS n, 'When using a Combat Fist, choose one effect:

 • Shooting with the weapon''s listed profile.
 • Adds 1D6 to AF with Damage (+2).
 • First Strike (1 / 2+ / AP -4), Damage (+1).
 • Damages Buildings (AP -4 / 3) in Assault.' AS d
) AS src ON src.n = sa.SpecialAbilityName
SET sa.Description = src.d;

INSERT INTO PsychicPower (PsychicPowerName, Description)
SELECT n, d FROM (
    SELECT 'Psychic Barrage' AS n, '[Combat Phase, Shooting]: The Psyker projects a burst of pure psychic energy. Choose a target within 45 cm and in Line of Sight. It suffers a hit on 4+. This is a Psychic Power.' AS d
    UNION ALL SELECT 'Mind Block' AS n, '[Movement Phase, upon activation]: The Warlock sends a flash of psychic energy that surrounds the target and immobilises it during its activation. Choose a Class 4 or lower base within 45 cm and in Line of Sight. On 4+, it is Immobilised for this turn. The power remains active only if the Warlock keeps the base in Line of Sight. This is a Psychic Power.' AS d
    UNION ALL SELECT 'Storm' AS n, '[Combat Phase, Shooting]: The Warlock summons a storm of psychic energy. Place a Template (7.5 cm) within 60 cm and in Line of Sight. All bases under the template are pushed onto one of its edges, chosen by the player who owns the base. If the storm has its centre in a structure, all bases in garrison are pushed out and placed in contact with it. The storm is impassable terrain and is considered Class 4 Blocking terrain. The storm disappears in the End Phase.' AS d
    UNION ALL SELECT 'Confusion' AS n, '[Movement Phase, upon activation]: The Farseer gains the Confusion (-2) ability for this turn.' AS d
    UNION ALL SELECT 'Precognition' AS n, '[Movement Phase, upon activation of the targeted detachment]: An allied Class 1, 2, or 3 detachment within 12 cm of the Farseer may make a Forced March while still being able to shoot normally (without the -1 To-Hit penalty).' AS d
    UNION ALL SELECT 'Doom' AS n, '[Movement Phase, upon activation]: Choose a target within 45 cm and in Line of Sight. All shots against that target gain a +1 To-Hit bonus (with a minimum of 2+). In assault, the target''s AF is halved. This is a Psychic Power, and the effects dissipate at the end of the turn.' AS d
    UNION ALL SELECT 'Future Sight' AS n, '[Orders Phase]: The Warlock Titan does not need an order for this turn. Instead, it chooses its order at the moment of its activation. You may choose to give it a First Fire order during the Movement Phase in order to make Intercept Fire.' AS d
    UNION ALL SELECT 'Mind Scream' AS n, '[Movement Phase, upon activation]: The Warlock Titan gains the Charismatic (45 cm) and Dread (-2) abilities for the turn.' AS d
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM PsychicPower pp WHERE pp.PsychicPowerName = src.n
);

UPDATE PsychicPower pp
INNER JOIN (
    SELECT 'Psychic Barrage' AS n, '[Combat Phase, Shooting]: The Psyker projects a burst of pure psychic energy. Choose a target within 45 cm and in Line of Sight. It suffers a hit on 4+. This is a Psychic Power.' AS d
    UNION ALL SELECT 'Mind Block' AS n, '[Movement Phase, upon activation]: The Warlock sends a flash of psychic energy that surrounds the target and immobilises it during its activation. Choose a Class 4 or lower base within 45 cm and in Line of Sight. On 4+, it is Immobilised for this turn. The power remains active only if the Warlock keeps the base in Line of Sight. This is a Psychic Power.' AS d
    UNION ALL SELECT 'Storm' AS n, '[Combat Phase, Shooting]: The Warlock summons a storm of psychic energy. Place a Template (7.5 cm) within 60 cm and in Line of Sight. All bases under the template are pushed onto one of its edges, chosen by the player who owns the base. If the storm has its centre in a structure, all bases in garrison are pushed out and placed in contact with it. The storm is impassable terrain and is considered Class 4 Blocking terrain. The storm disappears in the End Phase.' AS d
    UNION ALL SELECT 'Confusion' AS n, '[Movement Phase, upon activation]: The Farseer gains the Confusion (-2) ability for this turn.' AS d
    UNION ALL SELECT 'Precognition' AS n, '[Movement Phase, upon activation of the targeted detachment]: An allied Class 1, 2, or 3 detachment within 12 cm of the Farseer may make a Forced March while still being able to shoot normally (without the -1 To-Hit penalty).' AS d
    UNION ALL SELECT 'Doom' AS n, '[Movement Phase, upon activation]: Choose a target within 45 cm and in Line of Sight. All shots against that target gain a +1 To-Hit bonus (with a minimum of 2+). In assault, the target''s AF is halved. This is a Psychic Power, and the effects dissipate at the end of the turn.' AS d
    UNION ALL SELECT 'Future Sight' AS n, '[Orders Phase]: The Warlock Titan does not need an order for this turn. Instead, it chooses its order at the moment of its activation. You may choose to give it a First Fire order during the Movement Phase in order to make Intercept Fire.' AS d
    UNION ALL SELECT 'Mind Scream' AS n, '[Movement Phase, upon activation]: The Warlock Titan gains the Charismatic (45 cm) and Dread (-2) abilities for the turn.' AS d
) AS src ON src.n = pp.PsychicPowerName
SET pp.Description = src.d;

INSERT INTO SpecialRule (CodexId, SpecialRuleName, Description)
SELECT @codexId, n, d FROM (
    SELECT 'Allies' AS n, 'You may spend 25% of your points on allies from the Harlequins Codex.' AS d
    UNION ALL SELECT 'Harlequins' AS n, 'Harlequins are immune to Morale and to all morale-based powers if they are fighting a Chaos army.' AS d
    UNION ALL SELECT 'Master Mime' AS n, 'The Master Mime is a Special Formation but is not deployed on the battlefield. Instead, the Formation is used once per game, fulfilling its role, and is then no longer usable. As the Master Mime cannot be destroyed, it is considered Broken as soon as it is played.

Play the Master Mime on an enemy detachment during the Initial Phase, just after all orders have been given. The targeted detachment automatically loses its order and may no longer receive another in subsequent turns until it has unmasked the Master Mime (it then acts as a detachment with no order). To do so, the detachment takes a Morale test during each End Phase. As soon as it succeeds, the Master Mime is discovered and the detachment may receive orders again on the following turn.

The Master Mime cannot be played against a detachment with no Morale value, or against Daemonic, Robotic, Flyer, Floating, or Tyranid detachments.' AS d
    UNION ALL SELECT 'Biel-Tan Titan Hit Location Chart' AS n, '### Revenant / Phantom / Warlock Titan

| D6 | Location Front / Rear |
| --- | --- |
| 1 | Legs |
| 2 | Hull |
| 3 | Weapon |
| 4 | Head (front) / Reactor (rear) |
| 5 | Wing |
| 6 | Player''s choice |' AS d
    UNION ALL SELECT 'Biel-Tan Titan Damage Effects' AS n, 'Damage effects are progressive: the first damage to a location applies the first effect, and further damage applies the following effects on the list.

### Hull

| Hits | Effect |
| --- | --- |
| 1 | — |
| 2 | 1 additional damage |
| 3+ | 2 additional damage |

### Weapon

| Hits | Effect |
| --- | --- |
| 1 | Weapon Damaged (Repair on 4+) |
| 2 | Weapon Destroyed |
| 3+ | Damage to the Hull |

### Leg

| Hits | Effect |
| --- | --- |
| 1 | -5 cm of base movement (Repair on 4+) |
| 2 | an additional -5 cm of base movement (Repair on 4+) (from this damage, if the titan is destroyed it falls) |
| 3 | Immobilised, 1 additional damage |
| 4+ | Damage to the Hull |

### Head

| Hits | Effect |
| --- | --- |
| 1 | -1D6 to AF (Repair on 4+) |
| 2 | May receive an order only on a 4+ (Repair on 4+), 1 additional damage |
| 3+ | Damage to the Hull |

### Wing

| Hits | Effect |
| --- | --- |
| 1 | Wing Damaged, the Holo-Field is disabled (Repair on 4+) |
| 2 | Wing Destroyed, the Holo-Field is disabled |
| 3+ | Damage to the Hull |

### Reactor

| Hits | Effect |
| --- | --- |
| 1 | 1 additional damage (from this damage, if the titan is destroyed it explodes) |
| 2 | Holo-Field disabled: 1 additional damage |
| 3+ | Reactor severely damaged, 1D3 additional damage |' AS d
) AS src;

-- Figure PNGs are stored in Base.Image; run upload_base_images.py for new units.
SET @warlock := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Warlock');
SET @swoopingHawks := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Swooping Hawks');
SET @warpSpiders := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Warp Spiders');
SET @harlequins := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Harlequins');
SET @autarch := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Autarch');
SET @howlingBanshees := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Howling Banshees');
SET @bonesinger := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Bonesinger');
SET @fireDragons := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Fire Dragons');
SET @swoopingHawksExarch := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Swooping Hawks Exarch');
SET @warpSpidersExarch := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Warp Spiders Exarch');
SET @howlingBansheesExarch := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Howling Banshees Exarch');
SET @fireDragonsExarch := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Fire Dragons Exarch');
SET @darkReapersExarch := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Dark Reapers Exarch');
SET @strikingScorpionsExarch := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Striking Scorpions Exarch');
SET @shadowSpectresExarch := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Shadow Spectres Exarch');
SET @direAvengersExarch := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Dire Avengers Exarch');
SET @darkReapers := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Dark Reapers');
SET @wraithguard := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Wraithguard');
SET @guardians := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Guardians');
SET @farseer := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Farseer');
SET @wraithblades := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Wraithblades');
SET @strikingScorpions := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Striking Scorpions');
SET @rangers := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Rangers');
SET @shadowSpectres := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Shadow Spectres');
SET @direAvengers := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Dire Avengers');
SET @forwardObserver := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Forward Observer');
SET @brightLance := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Bright Lance');
SET @vibroCannon := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Vibro Cannon');
SET @masterMime := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Master Mime');
SET @shiningSpears := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Shining Spears');
SET @jetbikes := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Jetbikes');
SET @vyper := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Vyper');
SET @shiningSpearsExarch := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Shining Spears Exarch');
SET @warWalkers := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'War Walkers');
SET @waspAssaultWalkers := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Wasp Assault Walkers');
SET @wraithlordAssault := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Wraithlord — Assault');
SET @wraithlordSupport := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Wraithlord — Support');
SET @crimsonHunter := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Crimson Hunter');
SET @falcon := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Falcon');
SET @firestorm := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Firestorm');
SET @hornet := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Hornet');
SET @lynx := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Lynx');
SET @nightSpinner := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Night Spinner');
SET @nightwing := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Nightwing');
SET @firePrism := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Fire Prism');
SET @unicorn := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Unicorn');
SET @warpHunter := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Warp Hunter');
SET @waveSerpent := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Wave Serpent');
SET @avatar := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Avatar');
SET @baronFire := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Baron Fire');
SET @baronStallion := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Baron Stallion');
SET @brightStallion := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Bright Stallion');
SET @wraithknightAssault := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Wraithknight — Assault');
SET @wraithknightSupport := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Wraithknight — Support');
SET @fireGale := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Fire Gale');
SET @fireReaper := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Fire Reaper');
SET @fireStorm := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Fire Storm');
SET @toweringDestroyer := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Towering Destroyer');
SET @brightStalker := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Bright Stalker');
SET @cobra := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Cobra');
SET @stormSerpent := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Storm Serpent');
SET @tempest := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Tempest');
SET @voidSpinner := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Void Spinner');
SET @vampireRaider := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Vampire Raider');
SET @scorpion := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Scorpion');
SET @phoenix := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Phoenix');
SET @revenantTitan := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Revenant Titan');
SET @warlockTitan := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Warlock Titan');
SET @phantomTitan := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Phantom Titan');
SET @pulsarBarrage := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Pulsar Barrage');
SET @webBarrage := (SELECT BaseId FROM `Base` WHERE CodexId = @codexId AND BaseName = 'Web Barrage');

INSERT INTO Weapon (
    BaseId, `Name`, `Range`, Dice, ToHit, ArmourPenetration, IsTitanWeapon
) VALUES
    (@warlock, 'Shuriken Pistol', '20 cm', '1', '5+', '0', 0),
    (@swoopingHawks, 'Lasblaster', '20 cm', '1', '4+', '0', 0),
    (@warpSpiders, 'Death Spinner', '20 cm', '2', '3+', '0', 0),
    (@harlequins, 'Shuriken Pistol', '20 cm', '1', '5+', '0', 0),
    (@autarch, 'Sacred Artefacts', '60 cm', '2', '4+', '-2', 0),
    (@howlingBanshees, 'Power Sword', '--', '--', '--', '--', 0),
    (@bonesinger, 'Shuriken Pistol', '20 cm', '1', '5+', '0', 0),
    (@fireDragons, 'Fusion Gun', '20 cm', '1', '4+', '-2', 0),
    (@swoopingHawksExarch, 'Lasblaster', '20 cm', '1', '4+', '0', 0),
    (@warpSpidersExarch, 'Death Spinner', '20 cm', '3', '3+', '0', 0),
    (@howlingBansheesExarch, 'Power Sword', '--', '--', '--', '--', 0),
    (@fireDragonsExarch, 'Fusion Gun', '20 cm', '1', '3+', '-2', 0),
    (@darkReapersExarch, 'Reaper Launcher', '60 cm', '2', '3+', '-1', 0),
    (@strikingScorpionsExarch, 'Mandiblaster', '20 cm', '1', '5+', '0', 0),
    (@shadowSpectresExarch, 'Prism Rifle', '30 cm', '1', '3+', '-2', 0),
    (@direAvengersExarch, 'Avenger Shuriken Catapult', '45 cm', '3', '4+', '0', 0),
    (@darkReapers, 'Reaper Launcher', '60 cm', '2', '4+', '-1', 0),
    (@wraithguard, 'Wraithcannon', '45 cm', '1', '5+', '-2', 0),
    (@guardians, 'Shuriken Catapult', '45 cm', '1', '5+', '0', 0),
    (@farseer, 'Shuriken Pistol', '20 cm', '1', '5+', '0', 0),
    (@wraithblades, 'Ghostswords', '--', '--', '--', '--', 0),
    (@strikingScorpions, 'Mandiblaster', '20 cm', '1', '5+', '0', 0),
    (@rangers, 'Long Rifle', '75 cm', '1', '4+', '0', 0),
    (@shadowSpectres, 'Prism Rifle', '30 cm', '1', '4+', '-2', 0),
    (@direAvengers, 'Avenger Shuriken Catapult', '45 cm', '3', '5+', '0', 0),
    (@forwardObserver, 'Shuriken Catapult', '45 cm', '1', '5+', '0', 0),
    (@brightLance, 'Bright Lance', '75 cm', '1', '4+', '-2', 0),
    (@vibroCannon, 'Vibro Cannon', '60 cm', '1', '5+', '-1', 0),
    (@shiningSpears, 'Laser Lance', '--', '--', '--', '--', 0),
    (@jetbikes, 'Shuriken Catapult', '45 cm', '1', '5+', '0', 0),
    (@vyper, 'Twin Shuriken Cannon', '45 cm', '1', '4+', '-1', 0),
    (@shiningSpearsExarch, 'Laser Lance', '--', '--', '--', '--', 0),
    (@warWalkers, 'Bright Lance', '75 cm', '1', '4+', '-2', 0),
    (@warWalkers, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@waspAssaultWalkers, 'Shuriken Cannon', '20 cm', '4', '5+', '-1', 0),
    (@wraithlordAssault, 'Ghostglaive', '--', '--', '--', '--', 0),
    (@wraithlordSupport, 'Bright Lance', '75 cm', '1', '4+', '-2', 0),
    (@wraithlordSupport, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@crimsonHunter, 'Twin Bright Lance', '45 cm', '2', '4+', '-2', 0),
    (@falcon, 'Bright Lance', '75 cm', '1', '4+', '-2', 0),
    (@firestorm, 'Laser Battery', '75 cm', '3', '4+', '-2', 0),
    (@hornet, 'Pulse Laser', '45 cm', '2', '4+', '-1', 0),
    (@hornet, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@lynx, 'Sonic Lance', '60 cm', '3', '4+', '-1', 0),
    (@nightSpinner, 'Doomweaver', '90 cm', '2', '4+', '-2', 0),
    (@nightwing, 'Bright Lance', '45 cm', '2', '4+', '-2', 0),
    (@nightwing, 'Twin Shuriken Catapult', '30 cm', '2', '4+', '0', 0),
    (@firePrism, 'Prism Cannon', '75 cm', '1', '3+', '-2', 0),
    (@unicorn, 'Vibro Cannon', '75 cm', '1', '5+', '-2', 0),
    (@warpHunter, 'D-Cannon', '75 cm', '1', '4+', 'Psi', 0),
    (@waveSerpent, 'Pulse Laser', '45 cm', '1', '4+', '-1', 0),
    (@avatar, 'The Wailing Doom', '20 cm', '1', '3+', '-2', 0),
    (@baronFire, 'Bright Lances', '75 cm', '2', '4+', '-2', 0),
    (@baronFire, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@baronStallion, 'Pulse Laser', '20 cm', '3', '5+', '0', 0),
    (@brightStallion, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@wraithknightAssault, 'Ghostglaive', '--', '--', '--', '--', 0),
    (@wraithknightSupport, 'Heavy Wraithcannons', '75 cm', '2', '4+', '-3', 0),
    (@wraithknightSupport, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@fireGale, 'Bright Lances', '75 cm', '2', '4+', '-2', 0),
    (@fireReaper, 'Reaper Laser', '45 cm', '4', '4+', '0', 0),
    (@fireReaper, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@fireStorm, 'Pulse Lances', '45 cm', '2', '4+', '0', 0),
    (@fireStorm, 'Missile Launcher', '90 cm', '2', '4+', '0', 0),
    (@toweringDestroyer, 'Pulse Lances', '45 cm', '2', '4+', '0', 0),
    (@toweringDestroyer, 'Maelstrom Laser', '90 cm', '2', '4+', '-2', 0),
    (@brightStalker, 'Pulse Laser', '45 cm', '1', '4+', '-1', 0),
    (@brightStalker, 'Bright Lance', '75 cm', '1', '4+', '-2', 0),
    (@cobra, 'Pulse Laser', '45 cm', '2', '4+', '-1', 0),
    (@cobra, 'D-Cannon', '75 cm', 'Template', '3+', 'Psi', 0),
    (@stormSerpent, 'Pulse Laser', '45 cm', '2', '4+', '-1', 0),
    (@tempest, 'Pulse Laser', '45 cm', '2', '4+', '-1', 0),
    (@tempest, 'Tempest Pulse Laser', '90 cm', '2', '3+', '-3', 0),
    (@voidSpinner, 'Pulse Laser', '45 cm', '2', '4+', '-1', 0),
    (@voidSpinner, 'Void Spinner Cannon', '90 cm', '3', '3+', '-3', 0),
    (@vampireRaider, 'Bright Lance', '45 cm', '2', '4+', '-2', 0),
    (@vampireRaider, 'Shuriken Cannon', '20 cm', '3', '5+', '-1', 0),
    (@scorpion, 'Pulse Laser', '45 cm', '2', '4+', '-1', 0),
    (@scorpion, 'Pulsar — Concentrated Fire', '75 cm', '1', '3+', '-2', 0),
    (@scorpion, 'Pulsar — Diffuse Fire', '75 cm', '3', '3+', '0', 0),
    (@phoenix, 'Bright Lance', '45 cm', '2', '4+', '-2', 0),
    (@phoenix, 'Shuriken Catapult', '30 cm', '4', '5+', '0', 0),
    (@phoenix, 'Plasma Bombs', 'Bomb', 'Template', '3+', '-1', 0),
    (@phoenix, 'Krak Bombs', 'Bomb', '1', '3+', '-3', 0),
    (@revenantTitan, 'Missile Launcher', '100 cm', '3', '5+', '0', 0),
    (@revenantTitan, 'Scatter Laser', '20 cm', '3', '5+', '0', 0),
    (@revenantTitan, 'Pulsar — Concentrated Fire', '75 cm', '1', '3+', '-2', 0),
    (@revenantTitan, 'Pulsar — Diffuse Fire', '75 cm', '3', '3+', '0', 0),
    (@warlockTitan, 'Shuriken Catapult', '45 cm', '3', '5+', '0', 0),
    (@warlockTitan, 'D-Cannon', '75 cm', 'Template', '3+', 'Psi', 1),
    (@warlockTitan, 'Pulsar — Concentrated Fire', '90 cm', '1', '2+', '-2', 1),
    (@warlockTitan, 'Pulsar — Diffuse Fire', '90 cm', '4', '2+', '0', 1),
    (@warlockTitan, 'Tremor Cannon', '90 cm', 'Template', '3+', '-2', 1),
    (@warlockTitan, 'Titan Blade', '45 cm', '4', '4+', '-1', 1),
    (@warlockTitan, 'Psychic Lance', '45 cm', 'Template', '5+/4+', '--', 1),
    (@warlockTitan, 'Thermal Lance (0–20 cm)', '0–20 cm', '1', '3+', '-4', 1),
    (@warlockTitan, 'Thermal Lance (21–30 cm)', '21–30 cm', '1', '4+', '-3', 1),
    (@warlockTitan, 'Thermal Lance (31–45 cm)', '31–45 cm', '1', '5+', '-2', 1),
    (@warlockTitan, 'Combat Fist', '45 cm', '4', '4+', '-1', 1),
    (@warlockTitan, 'Laser Cannon Wing', '75 cm', '2', '3+', '-1', 1),
    (@warlockTitan, 'Missile Launcher Wing', '100 cm', '3', '5+', '0', 1),
    (@warlockTitan, 'Firestorm Wing', '75 cm', '2', '4+', '-2', 1),
    (@phantomTitan, 'Shuriken Catapult', '45 cm', '3', '5+', '0', 0),
    (@phantomTitan, 'D-Cannon', '75 cm', 'Template', '3+', 'Psi', 1),
    (@phantomTitan, 'Pulsar — Concentrated Fire', '90 cm', '1', '2+', '-2', 1),
    (@phantomTitan, 'Pulsar — Diffuse Fire', '90 cm', '4', '2+', '0', 1),
    (@phantomTitan, 'Tremor Cannon', '90 cm', 'Template', '3+', '-2', 1),
    (@phantomTitan, 'Titan Blade', '45 cm', '4', '4+', '-1', 1),
    (@phantomTitan, 'Psychic Lance', '45 cm', 'Template', '5+/4+', '--', 1),
    (@phantomTitan, 'Thermal Lance (0–20 cm)', '0–20 cm', '1', '3+', '-4', 1),
    (@phantomTitan, 'Thermal Lance (21–30 cm)', '21–30 cm', '1', '4+', '-3', 1),
    (@phantomTitan, 'Thermal Lance (31–45 cm)', '31–45 cm', '1', '5+', '-2', 1),
    (@phantomTitan, 'Combat Fist', '45 cm', '4', '4+', '-1', 1),
    (@phantomTitan, 'Laser Cannon Wing', '75 cm', '2', '3+', '-1', 1),
    (@phantomTitan, 'Missile Launcher Wing', '100 cm', '3', '5+', '0', 1),
    (@phantomTitan, 'Firestorm Wing', '75 cm', '2', '4+', '-2', 1),
    (@pulsarBarrage, 'Pulsar', '--', '1', '3+', '-2', 0),
    (@webBarrage, 'Web Barrage', '--', '5', '4+', '-3', 0);

INSERT INTO BaseSpecialAbility (BaseId, SpecialAbilityId, AbilityValue)
SELECT b.BaseId, sa.SpecialAbilityId, b.AbilityValue
FROM (
    SELECT @warlock AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warlock AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warlock AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warlock AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @warlock AS BaseId, 'Prescience (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @warlock AS BaseId, 'Charismatic (X)' AS AbilityName, '12 cm' AS AbilityValue
    UNION ALL SELECT @swoopingHawks AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @swoopingHawks AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @swoopingHawks AS BaseId, 'Hard to Hit' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @swoopingHawks AS BaseId, 'Deep Strike (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @warpSpiders AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @warpSpiders AS BaseId, 'Fire on the Move' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warpSpiders AS BaseId, 'Lightning Attack' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warpSpiders AS BaseId, 'Cannot Be Blocked' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harlequins AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @harlequins AS BaseId, 'Hard to Hit' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harlequins AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harlequins AS BaseId, 'Reroll Assault Dice' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @harlequins AS BaseId, 'Harlequins' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @autarch AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @autarch AS BaseId, 'Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @autarch AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @autarch AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @autarch AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @howlingBanshees AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @howlingBanshees AS BaseId, 'Banshee Cry (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @bonesinger AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @bonesinger AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @bonesinger AS BaseId, 'Mechanic' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @fireDragons AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @fireDragons AS BaseId, 'Urban Combat' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @fireDragons AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @swoopingHawksExarch AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @swoopingHawksExarch AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @swoopingHawksExarch AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @swoopingHawksExarch AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @swoopingHawksExarch AS BaseId, 'Hard to Hit' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @swoopingHawksExarch AS BaseId, 'Deep Strike (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @warpSpidersExarch AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warpSpidersExarch AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warpSpidersExarch AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @warpSpidersExarch AS BaseId, 'Fire on the Move' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warpSpidersExarch AS BaseId, 'Lightning Attack' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warpSpidersExarch AS BaseId, 'Cannot Be Blocked' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @howlingBansheesExarch AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @howlingBansheesExarch AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @howlingBansheesExarch AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @howlingBansheesExarch AS BaseId, 'Banshee Cry (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @fireDragonsExarch AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @fireDragonsExarch AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @fireDragonsExarch AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @fireDragonsExarch AS BaseId, 'Urban Combat' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @fireDragonsExarch AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @darkReapersExarch AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @darkReapersExarch AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @darkReapersExarch AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @darkReapersExarch AS BaseId, 'Reflex Fire' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @strikingScorpionsExarch AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @strikingScorpionsExarch AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @strikingScorpionsExarch AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @strikingScorpionsExarch AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @strikingScorpionsExarch AS BaseId, 'Camouflage' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shadowSpectresExarch AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shadowSpectresExarch AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shadowSpectresExarch AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @shadowSpectresExarch AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shadowSpectresExarch AS BaseId, 'Hard to Hit' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shadowSpectresExarch AS BaseId, 'Deep Strike (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @direAvengersExarch AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @direAvengersExarch AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @direAvengersExarch AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @darkReapers AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @darkReapers AS BaseId, 'Reflex Fire' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @wraithguard AS BaseId, 'Spirit Stone' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @farseer AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @farseer AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @farseer AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @farseer AS BaseId, 'Psychic Save (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @farseer AS BaseId, 'Psychic Node (X)' AS AbilityName, '30 cm' AS AbilityValue
    UNION ALL SELECT @wraithblades AS BaseId, 'Spirit Stone' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @wraithblades AS BaseId, 'Dodge (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @strikingScorpions AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @strikingScorpions AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @strikingScorpions AS BaseId, 'Camouflage' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @rangers AS BaseId, 'Infiltration' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @rangers AS BaseId, 'Camouflage' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @rangers AS BaseId, 'Sniper' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shadowSpectres AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @shadowSpectres AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shadowSpectres AS BaseId, 'Hard to Hit' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shadowSpectres AS BaseId, 'Deep Strike (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @direAvengers AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @forwardObserver AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @forwardObserver AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @forwardObserver AS BaseId, 'Forward Observer (FO)' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @masterMime AS BaseId, 'Master Mime' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shiningSpears AS BaseId, 'Elite (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @shiningSpears AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shiningSpears AS BaseId, 'Lance (X+ / Y)' AS AbilityName, '4+,-1' AS AbilityValue
    UNION ALL SELECT @jetbikes AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @vyper AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shiningSpearsExarch AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shiningSpearsExarch AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shiningSpearsExarch AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @shiningSpearsExarch AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @shiningSpearsExarch AS BaseId, 'Lance (X+ / Y)' AS AbilityName, '4+,-1' AS AbilityValue
    UNION ALL SELECT @waspAssaultWalkers AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @wraithlordAssault AS BaseId, 'Dodge (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @wraithlordAssault AS BaseId, 'Spirit Stone' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @wraithlordSupport AS BaseId, 'Spirit Stone' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @crimsonHunter AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @crimsonHunter AS BaseId, 'Dodge (X+)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @crimsonHunter AS BaseId, 'Flyer' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @crimsonHunter AS BaseId, 'Interceptor' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @falcon AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @falcon AS BaseId, 'Transport (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @firestorm AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @hornet AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @lynx AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightSpinner AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightwing AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightwing AS BaseId, 'Dodge (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @nightwing AS BaseId, 'Flyer' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightwing AS BaseId, 'Interceptor' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @firePrism AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @unicorn AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warpHunter AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @waveSerpent AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @waveSerpent AS BaseId, 'Transport (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @waveSerpent AS BaseId, 'Protection (X+) to the Front' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @waveSerpent AS BaseId, 'Attached Transport' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @avatar AS BaseId, 'Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @avatar AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @avatar AS BaseId, 'Dodge (X+)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @avatar AS BaseId, 'Terror' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @avatar AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @baronFire AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @baronFire AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @baronFire AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @baronFire AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @baronFire AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @baronFire AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @baronStallion AS BaseId, 'HQ' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @baronStallion AS BaseId, 'Attached Character' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @baronStallion AS BaseId, 'Elite (X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @baronStallion AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @baronStallion AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @baronStallion AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @baronStallion AS BaseId, 'Lance (X+ / Y)' AS AbilityName, '3+,-2' AS AbilityValue
    UNION ALL SELECT @brightStallion AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @brightStallion AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @brightStallion AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @brightStallion AS BaseId, 'Lance (X+ / Y)' AS AbilityName, '3+,-2' AS AbilityValue
    UNION ALL SELECT @wraithknightAssault AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @wraithknightAssault AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @wraithknightAssault AS BaseId, 'Dodge (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @wraithknightAssault AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @wraithknightSupport AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @wraithknightSupport AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
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
    UNION ALL SELECT @brightStalker AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @brightStalker AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @brightStalker AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @cobra AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @cobra AS BaseId, 'Wounds (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @cobra AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @stormSerpent AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @stormSerpent AS BaseId, 'Wounds (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @stormSerpent AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @stormSerpent AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @stormSerpent AS BaseId, 'Ghost Portal' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tempest AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tempest AS BaseId, 'Wounds (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @tempest AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @voidSpinner AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @voidSpinner AS BaseId, 'Wounds (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @voidSpinner AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @vampireRaider AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @vampireRaider AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @vampireRaider AS BaseId, 'Flyer' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @vampireRaider AS BaseId, 'Transport (X)' AS AbilityName, '8' AS AbilityValue
    UNION ALL SELECT @scorpion AS BaseId, 'Antigrav' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @scorpion AS BaseId, 'Wounds (X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @scorpion AS BaseId, 'Close Defences (X+)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @phoenix AS BaseId, 'Integral Armour' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @phoenix AS BaseId, 'Flyer' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @phoenix AS BaseId, 'Wounds (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @revenantTitan AS BaseId, 'Wounds (X)' AS AbilityName, '4' AS AbilityValue
    UNION ALL SELECT @revenantTitan AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @revenantTitan AS BaseId, 'Agile' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @revenantTitan AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @revenantTitan AS BaseId, 'Jump Packs' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @revenantTitan AS BaseId, 'Extended Coherency (X)' AS AbilityName, '25 cm' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Wounds (X)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Agile' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Psyker' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Psychic Save (X+)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Prescience (X)' AS AbilityName, '12 cm' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Wounds (X)' AS AbilityName, '6' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Close Defences (X+)' AS AbilityName, '5' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Agile' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Holo-Field' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Damage (+X) in Assault' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @pulsarBarrage AS BaseId, 'Off-Table Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @webBarrage AS BaseId, 'Off-Table Artillery' AS AbilityName, '' AS AbilityValue
) AS b
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = b.AbilityName;

INSERT INTO BasePsychicPower (BaseId, PsychicPowerId, AbilityValue)
SELECT b.BaseId, pp.PsychicPowerId, b.AbilityValue
FROM (
    SELECT @warlock AS BaseId, 'Psychic Barrage' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @warlock AS BaseId, 'Mind Block' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @warlock AS BaseId, 'Storm' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @farseer AS BaseId, 'Psychic Barrage' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @farseer AS BaseId, 'Confusion' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @farseer AS BaseId, 'Precognition' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Doom' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Future Sight' AS PowerName, '' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Mind Scream' AS PowerName, '' AS AbilityValue
) AS b
INNER JOIN PsychicPower pp ON pp.PsychicPowerName = b.PowerName;

INSERT INTO WeaponSpecialAbility (WeaponId, SpecialAbilityId, AbilityValue)
SELECT w.WeaponId, sa.SpecialAbilityId, src.AbilityValue
FROM (
    SELECT @fireDragons AS BaseId, 'Fusion Gun' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @fireDragonsExarch AS BaseId, 'Fusion Gun' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @strikingScorpionsExarch AS BaseId, 'Mandiblaster' AS WeaponName, '3D6 in Assault against Classes 1 and 2' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @strikingScorpions AS BaseId, 'Mandiblaster' AS WeaponName, '3D6 in Assault against Classes 1 and 2' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @vibroCannon AS BaseId, 'Vibro Cannon' AS WeaponName, 'Vibro Cannon (-X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @falcon AS BaseId, 'Bright Lance' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @firestorm AS BaseId, 'Laser Battery' AS WeaponName, 'Anti-Aircraft' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightSpinner AS BaseId, 'Doomweaver' AS WeaponName, 'Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightSpinner AS BaseId, 'Doomweaver' AS WeaponName, 'Web' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @nightSpinner AS BaseId, 'Doomweaver' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-1' AS AbilityValue
    UNION ALL SELECT @firePrism AS BaseId, 'Prism Cannon' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @firePrism AS BaseId, 'Prism Cannon' AS WeaponName, 'Fire Prism' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @unicorn AS BaseId, 'Vibro Cannon' AS WeaponName, 'Vibro Cannon (-X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @warpHunter AS BaseId, 'D-Cannon' AS WeaponName, 'Damages Buildings (AP -X / Y)' AS AbilityName, '3,2' AS AbilityValue
    UNION ALL SELECT @warpHunter AS BaseId, 'D-Cannon' AS WeaponName, 'Psychic Attack' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @fireStorm AS BaseId, 'Missile Launcher' AS WeaponName, 'Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @fireStorm AS BaseId, 'Missile Launcher' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-2' AS AbilityValue
    UNION ALL SELECT @cobra AS BaseId, 'D-Cannon' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @cobra AS BaseId, 'D-Cannon' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @cobra AS BaseId, 'D-Cannon' AS WeaponName, 'Damages Buildings (AP -X / Y)' AS AbilityName, '4,2' AS AbilityValue
    UNION ALL SELECT @cobra AS BaseId, 'D-Cannon' AS WeaponName, 'Psychic Attack' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tempest AS BaseId, 'Tempest Pulse Laser' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @tempest AS BaseId, 'Tempest Pulse Laser' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @voidSpinner AS BaseId, 'Void Spinner Cannon' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @voidSpinner AS BaseId, 'Void Spinner Cannon' AS WeaponName, 'Web' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @voidSpinner AS BaseId, 'Void Spinner Cannon' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @voidSpinner AS BaseId, 'Void Spinner Cannon' AS WeaponName, 'Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @vampireRaider AS BaseId, 'Shuriken Cannon' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @scorpion AS BaseId, 'Pulsar — Concentrated Fire' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @scorpion AS BaseId, 'Pulsar — Concentrated Fire' AS WeaponName, 'Multiple Hits (X)' AS AbilityName, '1D3' AS AbilityValue
    UNION ALL SELECT @scorpion AS BaseId, 'Pulsar — Diffuse Fire' AS WeaponName, 'Turret' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @phoenix AS BaseId, 'Plasma Bombs' AS WeaponName, 'Bombing (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @phoenix AS BaseId, 'Plasma Bombs' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @phoenix AS BaseId, 'Plasma Bombs' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @phoenix AS BaseId, 'Krak Bombs' AS WeaponName, 'Bombing (X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @revenantTitan AS BaseId, 'Pulsar — Concentrated Fire' AS WeaponName, 'Multiple Hits (X)' AS AbilityName, '1D3' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'D-Cannon' AS WeaponName, 'Damages Buildings (AP -X / Y)' AS AbilityName, '4,2' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'D-Cannon' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'D-Cannon' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'D-Cannon' AS WeaponName, 'Psychic Attack' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Pulsar — Concentrated Fire' AS WeaponName, 'Multiple Hits (X)' AS AbilityName, '2D3' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Tremor Cannon' AS WeaponName, 'Vibro Cannon (-X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Titan Blade' AS WeaponName, 'Titan Blade' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Psychic Lance' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Psychic Lance' AS WeaponName, 'Psychic Attack' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Thermal Lance (0–20 cm)' AS WeaponName, 'Damage (+X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Thermal Lance (21–30 cm)' AS WeaponName, 'Damage (+X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Thermal Lance (31–45 cm)' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Combat Fist' AS WeaponName, 'Combat Fist' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @warlockTitan AS BaseId, 'Firestorm Wing' AS WeaponName, 'Anti-Aircraft' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'D-Cannon' AS WeaponName, 'Damages Buildings (AP -X / Y)' AS AbilityName, '4,2' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'D-Cannon' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'D-Cannon' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'D-Cannon' AS WeaponName, 'Psychic Attack' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Pulsar — Concentrated Fire' AS WeaponName, 'Multiple Hits (X)' AS AbilityName, '2D3' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Tremor Cannon' AS WeaponName, 'Vibro Cannon (-X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Titan Blade' AS WeaponName, 'Titan Blade' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Psychic Lance' AS WeaponName, 'Template (X)' AS AbilityName, '7.5 cm' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Psychic Lance' AS WeaponName, 'Psychic Attack' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Thermal Lance (0–20 cm)' AS WeaponName, 'Damage (+X)' AS AbilityName, '3' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Thermal Lance (21–30 cm)' AS WeaponName, 'Damage (+X)' AS AbilityName, '2' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Thermal Lance (31–45 cm)' AS WeaponName, 'Damage (+X)' AS AbilityName, '1' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Combat Fist' AS WeaponName, 'Combat Fist' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @phantomTitan AS BaseId, 'Firestorm Wing' AS WeaponName, 'Anti-Aircraft' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @pulsarBarrage AS BaseId, 'Pulsar' AS WeaponName, 'Multiple Hits (X)' AS AbilityName, '2D3' AS AbilityValue
    UNION ALL SELECT @pulsarBarrage AS BaseId, 'Pulsar' AS WeaponName, 'Off-Table Artillery' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @webBarrage AS BaseId, 'Web Barrage' AS WeaponName, 'Web' AS AbilityName, '' AS AbilityValue
    UNION ALL SELECT @webBarrage AS BaseId, 'Web Barrage' AS WeaponName, 'Reduces Cover (X)' AS AbilityName, '-3' AS AbilityValue
    UNION ALL SELECT @webBarrage AS BaseId, 'Web Barrage' AS WeaponName, 'Off-Table Artillery' AS AbilityName, '' AS AbilityValue
) AS src
INNER JOIN Weapon w ON w.BaseId = src.BaseId AND w.`Name` = src.WeaponName
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = src.AbilityName;

INSERT INTO TitanWeapon (
    CodexId, WeaponName, PointsCost, Notes, IsAssault, LimitPerTitan
) VALUES
    (@codexId, 'D-Cannon', 125, 'Template (7.5 cm), Damage (+1), Damages Buildings (AP -4/2), Psychic Attack.', 0, 0),
    (@codexId, 'Pulsar', 125, 'Choose Concentrated (Multiple Hits 2D3) or Diffuse firing mode.', 0, 0),
    (@codexId, 'Tremor Cannon', 100, 'Vibro Cannon (-2); AP -5 against Buildings; Buildings reroll successful saves.', 0, 0),
    (@codexId, 'Titan Blade', 75, 'Choose an effect (shooting, assault, First Strike, or buildings).', 1, 0),
    (@codexId, 'Psychic Lance', 50, 'Template (7.5 cm), Psychic Attack. Warlock hits on 4+; Phantom on 5+.', 0, 0),
    (@codexId, 'Thermal Lance', 50, 'Damage and AP scale with range band (0–20 / 21–30 / 31–45 cm).', 0, 0),
    (@codexId, 'Combat Fist', 75, 'Choose an effect (shooting, assault, First Strike, or buildings).', 1, 0),
    (@codexId, 'Laser Cannon Wing', 50, 'Wing weapon.', 0, 0),
    (@codexId, 'Missile Launcher Wing', 25, 'Wing weapon.', 0, 0),
    (@codexId, 'Firestorm Wing', 50, 'Wing weapon with Anti-Aircraft.', 0, 0)
ON DUPLICATE KEY UPDATE
    PointsCost = VALUES(PointsCost),
    Notes = VALUES(Notes),
    IsAssault = VALUES(IsAssault),
    LimitPerTitan = VALUES(LimitPerTitan);

INSERT INTO Detachment (
    CodexId, DetachmentName, CommandPoints, `Class`
) VALUES
    (@codexId, 'Avatar Detachment', 0, 4),
    (@codexId, 'Autarch Detachment', 0, 1),
    (@codexId, 'Harlequin Detachment', 0, 1),
    (@codexId, 'Revenant Titan Detachment', 0, 5),
    (@codexId, 'Warlock Titan Detachment', 0, 6),
    (@codexId, 'Phantom Titan Detachment', 0, 6),
    (@codexId, 'Master Mime Detachment', 0, 1),
    (@codexId, 'Warlock Detachment', 0, 1),
    (@codexId, 'Bonesinger Detachment', 0, 1),
    (@codexId, 'Farseer Detachment', 0, 1),
    (@codexId, 'Forward Observer Detachment', 0, 1),
    (@codexId, 'Swooping Hawks Detachment', 0, 1),
    (@codexId, 'Swooping Hawks with Exarchs Detachment', 0, 1),
    (@codexId, 'Warp Spiders Detachment', 0, 1),
    (@codexId, 'Warp Spiders with Exarchs Detachment', 0, 1),
    (@codexId, 'Howling Banshees Detachment', 0, 1),
    (@codexId, 'Howling Banshees with Exarchs Detachment', 0, 1),
    (@codexId, 'Fire Dragons Detachment', 0, 1),
    (@codexId, 'Fire Dragons with Exarchs Detachment', 0, 1),
    (@codexId, 'Dark Reapers Detachment', 0, 1),
    (@codexId, 'Dark Reapers with Exarchs Detachment', 0, 1),
    (@codexId, 'Wraithguard Detachment', 0, 1),
    (@codexId, 'Guardian Detachment', 0, 1),
    (@codexId, 'Wraithblades Detachment', 0, 1),
    (@codexId, 'Bright Lance Detachment', 0, 1),
    (@codexId, 'Striking Scorpions Detachment', 0, 1),
    (@codexId, 'Striking Scorpions with Exarchs Detachment', 0, 1),
    (@codexId, 'Ranger Detachment', 0, 1),
    (@codexId, 'Shadow Spectres Detachment', 0, 1),
    (@codexId, 'Shadow Spectres with Exarchs Detachment', 0, 1),
    (@codexId, 'Dire Avengers Detachment', 0, 1),
    (@codexId, 'Dire Avengers with Exarchs Detachment', 0, 1),
    (@codexId, 'Vibro Cannon Detachment', 0, 1),
    (@codexId, 'Shining Spears Detachment', 0, 2),
    (@codexId, 'Jetbike Detachment', 0, 2),
    (@codexId, 'Vyper Detachment', 0, 2),
    (@codexId, 'War Walker Detachment', 0, 2),
    (@codexId, 'Wasp Assault Walker Detachment', 0, 2),
    (@codexId, 'Wraithlord — Assault Detachment', 0, 2),
    (@codexId, 'Wraithlord — Support Detachment', 0, 2),
    (@codexId, 'Crimson Hunter Detachment', 0, 3),
    (@codexId, 'Falcon Detachment', 0, 3),
    (@codexId, 'Firestorm Detachment', 0, 3),
    (@codexId, 'Hornet Detachment', 0, 3),
    (@codexId, 'Lynx Detachment', 0, 3),
    (@codexId, 'Night Spinner Detachment', 0, 3),
    (@codexId, 'Nightwing Detachment', 0, 3),
    (@codexId, 'Fire Prism Detachment', 0, 3),
    (@codexId, 'Unicorn Detachment', 0, 3),
    (@codexId, 'Warp Hunter Detachment', 0, 3),
    (@codexId, 'Bright Stalker Detachment', 0, 4),
    (@codexId, 'Bright Stallion Detachment', 0, 4),
    (@codexId, 'Wraithknight — Assault Detachment', 0, 4),
    (@codexId, 'Wraithknight — Support Detachment', 0, 4),
    (@codexId, 'Fire Gale Detachment', 0, 4),
    (@codexId, 'Fire Reaper Detachment', 0, 4),
    (@codexId, 'Fire Storm Detachment', 0, 4),
    (@codexId, 'Towering Destroyer Detachment', 0, 4),
    (@codexId, 'Cobra Detachment', 0, 4),
    (@codexId, 'Phoenix Detachment', 0, 4),
    (@codexId, 'Scorpion Detachment', 0, 4),
    (@codexId, 'Storm Serpent Detachment', 0, 4),
    (@codexId, 'Tempest Detachment', 0, 4),
    (@codexId, 'Void Spinner Detachment', 0, 4),
    (@codexId, 'Wave Serpent Detachment', 0, 3),
    (@codexId, 'Vampire Raider Detachment', 0, 4),
    (@codexId, 'Baron Fire Detachment', 0, 4),
    (@codexId, 'Baron Stallion Detachment', 0, 4),
    (@codexId, 'Shining Spears with Exarchs Detachment', 0, 2),
    (@codexId, 'Off-Table Artillery (Pulsar Barrage)', 0, 0),
    (@codexId, 'Off-Table Artillery (Web Barrage)', 0, 0)
ON DUPLICATE KEY UPDATE
    CommandPoints = VALUES(CommandPoints),
    `Class` = VALUES(`Class`);

INSERT INTO DetachmentComposition (DetachmentId, BaseId, BaseCount)
SELECT d.DetachmentId, b.BaseId, src.BaseCount
FROM (
    SELECT 'Avatar Detachment' AS DetachmentName, 'Avatar' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Autarch Detachment' AS DetachmentName, 'Autarch' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Harlequin Detachment' AS DetachmentName, 'Harlequins' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Revenant Titan Detachment' AS DetachmentName, 'Revenant Titan' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Warlock Titan Detachment' AS DetachmentName, 'Warlock Titan' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Phantom Titan Detachment' AS DetachmentName, 'Phantom Titan' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Master Mime Detachment' AS DetachmentName, 'Master Mime' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Warlock Detachment' AS DetachmentName, 'Warlock' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Bonesinger Detachment' AS DetachmentName, 'Bonesinger' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Farseer Detachment' AS DetachmentName, 'Farseer' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Forward Observer Detachment' AS DetachmentName, 'Forward Observer' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Swooping Hawks Detachment' AS DetachmentName, 'Swooping Hawks' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Swooping Hawks with Exarchs Detachment' AS DetachmentName, 'Swooping Hawks' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Swooping Hawks with Exarchs Detachment' AS DetachmentName, 'Swooping Hawks Exarch' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Warp Spiders Detachment' AS DetachmentName, 'Warp Spiders' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Warp Spiders with Exarchs Detachment' AS DetachmentName, 'Warp Spiders' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Warp Spiders with Exarchs Detachment' AS DetachmentName, 'Warp Spiders Exarch' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Howling Banshees Detachment' AS DetachmentName, 'Howling Banshees' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Howling Banshees with Exarchs Detachment' AS DetachmentName, 'Howling Banshees' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Howling Banshees with Exarchs Detachment' AS DetachmentName, 'Howling Banshees Exarch' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Fire Dragons Detachment' AS DetachmentName, 'Fire Dragons' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Fire Dragons with Exarchs Detachment' AS DetachmentName, 'Fire Dragons' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Fire Dragons with Exarchs Detachment' AS DetachmentName, 'Fire Dragons Exarch' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Dark Reapers Detachment' AS DetachmentName, 'Dark Reapers' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Dark Reapers with Exarchs Detachment' AS DetachmentName, 'Dark Reapers' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Dark Reapers with Exarchs Detachment' AS DetachmentName, 'Dark Reapers Exarch' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Wraithguard Detachment' AS DetachmentName, 'Wraithguard' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Guardian Detachment' AS DetachmentName, 'Guardians' AS UnitName, 6 AS BaseCount
    UNION ALL SELECT 'Wraithblades Detachment' AS DetachmentName, 'Wraithblades' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Bright Lance Detachment' AS DetachmentName, 'Bright Lance' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Striking Scorpions Detachment' AS DetachmentName, 'Striking Scorpions' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Striking Scorpions with Exarchs Detachment' AS DetachmentName, 'Striking Scorpions' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Striking Scorpions with Exarchs Detachment' AS DetachmentName, 'Striking Scorpions Exarch' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Ranger Detachment' AS DetachmentName, 'Rangers' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Shadow Spectres Detachment' AS DetachmentName, 'Shadow Spectres' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Shadow Spectres with Exarchs Detachment' AS DetachmentName, 'Shadow Spectres' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Shadow Spectres with Exarchs Detachment' AS DetachmentName, 'Shadow Spectres Exarch' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Dire Avengers Detachment' AS DetachmentName, 'Dire Avengers' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Dire Avengers with Exarchs Detachment' AS DetachmentName, 'Dire Avengers' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Dire Avengers with Exarchs Detachment' AS DetachmentName, 'Dire Avengers Exarch' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Vibro Cannon Detachment' AS DetachmentName, 'Vibro Cannon' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Shining Spears Detachment' AS DetachmentName, 'Shining Spears' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Jetbike Detachment' AS DetachmentName, 'Jetbikes' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Vyper Detachment' AS DetachmentName, 'Vyper' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'War Walker Detachment' AS DetachmentName, 'War Walkers' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Wasp Assault Walker Detachment' AS DetachmentName, 'Wasp Assault Walkers' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Wraithlord — Assault Detachment' AS DetachmentName, 'Wraithlord — Assault' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Wraithlord — Support Detachment' AS DetachmentName, 'Wraithlord — Support' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Crimson Hunter Detachment' AS DetachmentName, 'Crimson Hunter' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Falcon Detachment' AS DetachmentName, 'Falcon' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Firestorm Detachment' AS DetachmentName, 'Firestorm' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Hornet Detachment' AS DetachmentName, 'Hornet' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Lynx Detachment' AS DetachmentName, 'Lynx' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Night Spinner Detachment' AS DetachmentName, 'Night Spinner' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Nightwing Detachment' AS DetachmentName, 'Nightwing' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Fire Prism Detachment' AS DetachmentName, 'Fire Prism' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Unicorn Detachment' AS DetachmentName, 'Unicorn' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Warp Hunter Detachment' AS DetachmentName, 'Warp Hunter' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Bright Stalker Detachment' AS DetachmentName, 'Bright Stalker' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Bright Stallion Detachment' AS DetachmentName, 'Bright Stallion' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Wraithknight — Assault Detachment' AS DetachmentName, 'Wraithknight — Assault' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Wraithknight — Support Detachment' AS DetachmentName, 'Wraithknight — Support' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Fire Gale Detachment' AS DetachmentName, 'Fire Gale' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Fire Reaper Detachment' AS DetachmentName, 'Fire Reaper' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Fire Storm Detachment' AS DetachmentName, 'Fire Storm' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Towering Destroyer Detachment' AS DetachmentName, 'Towering Destroyer' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Cobra Detachment' AS DetachmentName, 'Cobra' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Phoenix Detachment' AS DetachmentName, 'Phoenix' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Scorpion Detachment' AS DetachmentName, 'Scorpion' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Storm Serpent Detachment' AS DetachmentName, 'Storm Serpent' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Tempest Detachment' AS DetachmentName, 'Tempest' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Void Spinner Detachment' AS DetachmentName, 'Void Spinner' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Wave Serpent Detachment' AS DetachmentName, 'Wave Serpent' AS UnitName, 2 AS BaseCount
    UNION ALL SELECT 'Vampire Raider Detachment' AS DetachmentName, 'Vampire Raider' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Baron Fire Detachment' AS DetachmentName, 'Baron Fire' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Baron Stallion Detachment' AS DetachmentName, 'Baron Stallion' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Shining Spears with Exarchs Detachment' AS DetachmentName, 'Shining Spears' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Shining Spears with Exarchs Detachment' AS DetachmentName, 'Shining Spears Exarch' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Off-Table Artillery (Pulsar Barrage)' AS DetachmentName, 'Pulsar Barrage' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Off-Table Artillery (Web Barrage)' AS DetachmentName, 'Web Barrage' AS UnitName, 1 AS BaseCount
) AS src
INNER JOIN Detachment d
    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName
INNER JOIN `Base` b
    ON b.CodexId = @codexId AND b.BaseName = src.UnitName;

INSERT INTO Formation (
    CodexId, FormationKindId, FormationName, PointsCost, CommandPoints, Contents,
    DestructionPoints
) VALUES
    (@codexId, 1, 'Avatar (Unique)', 150, 0, '1 Avatar base', 0),
    (@codexId, 2, 'Ghost Company', 0, 0, '1 Farseer (+25); 2 of Wraithguard or Wraithblades; 2 of Wraithlord — Assault or Support. Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.', 0),
    (@codexId, 2, 'Reconnaissance Company', 0, 0, '2 Ranger Detachments; 2 of Ranger or War Walker. Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.', 0),
    (@codexId, 2, 'Rapid Intervention Company', 0, 0, '0–1 Warlock (+50); 1 of Jetbike, Vyper, or Shining Spears; 2 of Jetbike, Vyper, War Walker, Wasp Assault Walker, or Hornet (max 1 Hornet). Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.', 0),
    (@codexId, 2, 'Knight Company', 0, 0, '1 of Baron Fire or Baron Stallion (+75); 1 of Fire Gale, Fire Reaper, or Fire Storm; 1 of Bright Stalker or Bright Stallion; 1 Towering Destroyer Detachment. Optional: 0–1 Special or Extra Special; 0–1 Extra Special; 0–5 Support; any Options.', 0),
    (@codexId, 2, 'Phoenix Company', 0, 0, '0–1 Autarch Detachment (4 Autarchs @ 300); 3 Aspect-with-Exarchs detachments (Shining Spears with Exarchs Limited). Support: 1–5 Aspect support or Crimson Hunters. Optional: 0–1 Special (Warlock/Farseer OK); any Options.', 0),
    (@codexId, 3, 'Autarch Detachment', 350, 0, '4 Autarch bases', 0),
    (@codexId, 3, 'Harlequin Detachment', 200, 0, '4 Harlequin bases', 0),
    (@codexId, 3, 'Revenant Titan Detachment', 650, 0, '2 Revenant Titan bases', 0),
    (@codexId, 3, 'Warlock Titan Detachment', 375, 0, '1 Warlock Titan base (weapons to purchase)', 0),
    (@codexId, 3, 'Phantom Titan Detachment', 300, 0, '1 Phantom Titan base (weapons to purchase)', 0),
    (@codexId, 3, 'Master Mime (1/5000 points)', 50, 0, '1 Master Mime', 0),
    (@codexId, 5, 'Warlock', 100, 0, '1 Warlock base', 0),
    (@codexId, 5, 'Bonesinger', 50, 0, '1 Bonesinger base', 0),
    (@codexId, 5, 'Farseer', 75, 0, '1 Farseer base', 0),
    (@codexId, 5, 'Forward Observer', 50, 0, '1 Forward Observer base', 0),
    (@codexId, 4, 'Swooping Hawks Detachment', 175, 0, '4 Swooping Hawks bases', 0),
    (@codexId, 4, 'Swooping Hawks with Exarchs Detachment', 225, 0, '4 Swooping Hawks bases and 1 Swooping Hawks Exarch base', 0),
    (@codexId, 4, 'Warp Spiders Detachment', 200, 0, '4 Warp Spiders bases', 0),
    (@codexId, 4, 'Warp Spiders with Exarchs Detachment', 250, 0, '4 Warp Spiders bases and 1 Warp Spiders Exarch base', 0),
    (@codexId, 4, 'Howling Banshees Detachment', 175, 0, '4 Howling Banshees bases', 0),
    (@codexId, 4, 'Howling Banshees with Exarchs Detachment', 225, 0, '4 Howling Banshees bases and 1 Howling Banshees Exarch base', 0),
    (@codexId, 4, 'Fire Dragons Detachment', 175, 0, '4 Fire Dragons bases', 0),
    (@codexId, 4, 'Fire Dragons with Exarchs Detachment', 225, 0, '4 Fire Dragons bases and 1 Fire Dragons Exarch base', 0),
    (@codexId, 4, 'Dark Reapers Detachment', 275, 0, '4 Dark Reapers bases', 0),
    (@codexId, 4, 'Dark Reapers with Exarchs Detachment', 350, 0, '4 Dark Reapers bases and 1 Dark Reapers Exarch base', 0),
    (@codexId, 4, 'Wraithguard Detachment', 125, 0, '4 Wraithguard bases', 0),
    (@codexId, 4, 'Guardian Detachment', 100, 0, '6 Guardian bases', 0),
    (@codexId, 4, 'Wraithblades Detachment', 125, 0, '4 Wraithblades bases', 0),
    (@codexId, 4, 'Bright Lance Detachment', 125, 0, '3 Bright Lance bases', 0),
    (@codexId, 4, 'Striking Scorpions Detachment', 200, 0, '4 Striking Scorpions bases', 0),
    (@codexId, 4, 'Striking Scorpions with Exarchs Detachment', 250, 0, '4 Striking Scorpions bases and 1 Striking Scorpions Exarch base', 0),
    (@codexId, 4, 'Ranger Detachment', 150, 0, '4 Ranger bases', 0),
    (@codexId, 4, 'Shadow Spectres Detachment', 200, 0, '4 Shadow Spectres bases', 0),
    (@codexId, 4, 'Shadow Spectres with Exarchs Detachment', 250, 0, '4 Shadow Spectres bases and 1 Shadow Spectres Exarch base', 0),
    (@codexId, 4, 'Dire Avengers Detachment', 150, 0, '4 Dire Avengers bases', 0),
    (@codexId, 4, 'Dire Avengers with Exarchs Detachment', 200, 0, '4 Dire Avengers bases and 1 Dire Avengers Exarch base', 0),
    (@codexId, 4, 'Vibro Cannon Detachment', 100, 0, '3 Vibro Cannon bases', 0),
    (@codexId, 4, 'Shining Spears Detachment', 225, 0, '4 Shining Spears bases', 0),
    (@codexId, 4, 'Jetbike Detachment', 200, 0, '5 Jetbike bases', 0),
    (@codexId, 4, 'Vyper Detachment', 225, 0, '5 Vyper bases', 0),
    (@codexId, 4, 'War Walker Detachment', 175, 0, '3 War Walker bases', 0),
    (@codexId, 4, 'Wasp Assault Walker Detachment', 150, 0, '3 Wasp Assault Walker bases', 0),
    (@codexId, 4, 'Wraithlord — Assault Detachment', 125, 0, '3 Wraithlord — Assault bases', 0),
    (@codexId, 4, 'Wraithlord — Support Detachment', 175, 0, '3 Wraithlord — Support bases', 0),
    (@codexId, 4, 'Crimson Hunter Detachment', 300, 0, '3 Crimson Hunter bases', 0),
    (@codexId, 4, 'Falcon Detachment', 175, 0, '3 Falcon bases', 0),
    (@codexId, 4, 'Firestorm Detachment', 250, 0, '2 Firestorm bases', 0),
    (@codexId, 4, 'Hornet Detachment', 150, 0, '2 Hornet bases', 0),
    (@codexId, 4, 'Lynx Detachment', 175, 0, '2 Lynx bases', 0),
    (@codexId, 4, 'Night Spinner Detachment', 225, 0, '2 Night Spinner bases', 0),
    (@codexId, 4, 'Nightwing Detachment', 300, 0, '3 Nightwing bases', 0),
    (@codexId, 4, 'Fire Prism Detachment', 150, 0, '2 Fire Prism bases', 0),
    (@codexId, 4, 'Unicorn Detachment', 150, 0, '2 Unicorn bases', 0),
    (@codexId, 4, 'Warp Hunter Detachment', 175, 0, '2 Warp Hunter bases', 0),
    (@codexId, 4, 'Bright Stalker Detachment', 325, 0, '3 Bright Stalker bases', 0),
    (@codexId, 4, 'Bright Stallion Detachment', 300, 0, '3 Bright Stallion bases', 0),
    (@codexId, 4, 'Wraithknight — Assault Detachment', 275, 0, '3 Wraithknight — Assault bases', 0),
    (@codexId, 4, 'Wraithknight — Support Detachment', 325, 0, '3 Wraithknight — Support bases', 0),
    (@codexId, 4, 'Fire Gale Detachment', 325, 0, '3 Fire Gale bases', 0),
    (@codexId, 4, 'Fire Reaper Detachment', 325, 0, '3 Fire Reaper bases', 0),
    (@codexId, 4, 'Fire Storm Detachment', 325, 0, '3 Fire Storm bases', 0),
    (@codexId, 4, 'Towering Destroyer Detachment', 400, 0, '3 Towering Destroyer bases', 0),
    (@codexId, 4, 'Cobra Detachment', 300, 0, '1 Cobra base', 0),
    (@codexId, 4, 'Phoenix Detachment', 275, 0, '1 Phoenix base', 0),
    (@codexId, 4, 'Scorpion Detachment', 275, 0, '1 Scorpion base', 0),
    (@codexId, 4, 'Storm Serpent Detachment', 175, 0, '1 Storm Serpent base', 0),
    (@codexId, 4, 'Tempest Detachment', 275, 0, '1 Tempest base', 0),
    (@codexId, 4, 'Void Spinner Detachment', 275, 0, '1 Void Spinner base', 0),
    (@codexId, 5, 'Wave Serpent Detachment', 100, 0, '2 Wave Serpent bases', 0),
    (@codexId, 5, 'Vampire Raider Detachment', 175, 0, '1 Vampire Raider base', 0),
    (@codexId, 5, 'Baron Fire', 75, 0, '1 Baron Fire base', 0),
    (@codexId, 5, 'Baron Stallion', 75, 0, '1 Baron Stallion base', 0),
    (@codexId, 6, 'Shining Spears with Exarchs Detachment (Limited)', 275, 0, '4 Shining Spears bases and 1 Shining Spears Exarch base', 0),
    (@codexId, 6, 'Off-Table Artillery (Pulsar Barrage)', 100, 0, '1 Pulsar Barrage shot (Limit: 1 per 2,000 points)', 0),
    (@codexId, 6, 'Off-Table Artillery (Web Barrage)', 100, 0, '1 Web Barrage shot (Limit: 1 per 2,000 points)', 0)
ON DUPLICATE KEY UPDATE
    FormationKindId = VALUES(FormationKindId),
    PointsCost = VALUES(PointsCost),
    CommandPoints = VALUES(CommandPoints),
    Contents = VALUES(Contents),
    DestructionPoints = VALUES(DestructionPoints);

INSERT INTO FormationDetachment (FormationId, DetachmentId, Quantity)
SELECT f.FormationId, d.DetachmentId, 1
FROM (
    SELECT 'Avatar (Unique)' AS FormationName, 'Avatar Detachment' AS DetachmentName
    UNION ALL SELECT 'Autarch Detachment' AS FormationName, 'Autarch Detachment' AS DetachmentName
    UNION ALL SELECT 'Harlequin Detachment' AS FormationName, 'Harlequin Detachment' AS DetachmentName
    UNION ALL SELECT 'Revenant Titan Detachment' AS FormationName, 'Revenant Titan Detachment' AS DetachmentName
    UNION ALL SELECT 'Warlock Titan Detachment' AS FormationName, 'Warlock Titan Detachment' AS DetachmentName
    UNION ALL SELECT 'Phantom Titan Detachment' AS FormationName, 'Phantom Titan Detachment' AS DetachmentName
    UNION ALL SELECT 'Master Mime (1/5000 points)' AS FormationName, 'Master Mime Detachment' AS DetachmentName
    UNION ALL SELECT 'Warlock' AS FormationName, 'Warlock Detachment' AS DetachmentName
    UNION ALL SELECT 'Bonesinger' AS FormationName, 'Bonesinger Detachment' AS DetachmentName
    UNION ALL SELECT 'Farseer' AS FormationName, 'Farseer Detachment' AS DetachmentName
    UNION ALL SELECT 'Forward Observer' AS FormationName, 'Forward Observer Detachment' AS DetachmentName
    UNION ALL SELECT 'Swooping Hawks Detachment' AS FormationName, 'Swooping Hawks Detachment' AS DetachmentName
    UNION ALL SELECT 'Swooping Hawks with Exarchs Detachment' AS FormationName, 'Swooping Hawks with Exarchs Detachment' AS DetachmentName
    UNION ALL SELECT 'Warp Spiders Detachment' AS FormationName, 'Warp Spiders Detachment' AS DetachmentName
    UNION ALL SELECT 'Warp Spiders with Exarchs Detachment' AS FormationName, 'Warp Spiders with Exarchs Detachment' AS DetachmentName
    UNION ALL SELECT 'Howling Banshees Detachment' AS FormationName, 'Howling Banshees Detachment' AS DetachmentName
    UNION ALL SELECT 'Howling Banshees with Exarchs Detachment' AS FormationName, 'Howling Banshees with Exarchs Detachment' AS DetachmentName
    UNION ALL SELECT 'Fire Dragons Detachment' AS FormationName, 'Fire Dragons Detachment' AS DetachmentName
    UNION ALL SELECT 'Fire Dragons with Exarchs Detachment' AS FormationName, 'Fire Dragons with Exarchs Detachment' AS DetachmentName
    UNION ALL SELECT 'Dark Reapers Detachment' AS FormationName, 'Dark Reapers Detachment' AS DetachmentName
    UNION ALL SELECT 'Dark Reapers with Exarchs Detachment' AS FormationName, 'Dark Reapers with Exarchs Detachment' AS DetachmentName
    UNION ALL SELECT 'Wraithguard Detachment' AS FormationName, 'Wraithguard Detachment' AS DetachmentName
    UNION ALL SELECT 'Guardian Detachment' AS FormationName, 'Guardian Detachment' AS DetachmentName
    UNION ALL SELECT 'Wraithblades Detachment' AS FormationName, 'Wraithblades Detachment' AS DetachmentName
    UNION ALL SELECT 'Bright Lance Detachment' AS FormationName, 'Bright Lance Detachment' AS DetachmentName
    UNION ALL SELECT 'Striking Scorpions Detachment' AS FormationName, 'Striking Scorpions Detachment' AS DetachmentName
    UNION ALL SELECT 'Striking Scorpions with Exarchs Detachment' AS FormationName, 'Striking Scorpions with Exarchs Detachment' AS DetachmentName
    UNION ALL SELECT 'Ranger Detachment' AS FormationName, 'Ranger Detachment' AS DetachmentName
    UNION ALL SELECT 'Shadow Spectres Detachment' AS FormationName, 'Shadow Spectres Detachment' AS DetachmentName
    UNION ALL SELECT 'Shadow Spectres with Exarchs Detachment' AS FormationName, 'Shadow Spectres with Exarchs Detachment' AS DetachmentName
    UNION ALL SELECT 'Dire Avengers Detachment' AS FormationName, 'Dire Avengers Detachment' AS DetachmentName
    UNION ALL SELECT 'Dire Avengers with Exarchs Detachment' AS FormationName, 'Dire Avengers with Exarchs Detachment' AS DetachmentName
    UNION ALL SELECT 'Vibro Cannon Detachment' AS FormationName, 'Vibro Cannon Detachment' AS DetachmentName
    UNION ALL SELECT 'Shining Spears Detachment' AS FormationName, 'Shining Spears Detachment' AS DetachmentName
    UNION ALL SELECT 'Jetbike Detachment' AS FormationName, 'Jetbike Detachment' AS DetachmentName
    UNION ALL SELECT 'Vyper Detachment' AS FormationName, 'Vyper Detachment' AS DetachmentName
    UNION ALL SELECT 'War Walker Detachment' AS FormationName, 'War Walker Detachment' AS DetachmentName
    UNION ALL SELECT 'Wasp Assault Walker Detachment' AS FormationName, 'Wasp Assault Walker Detachment' AS DetachmentName
    UNION ALL SELECT 'Wraithlord — Assault Detachment' AS FormationName, 'Wraithlord — Assault Detachment' AS DetachmentName
    UNION ALL SELECT 'Wraithlord — Support Detachment' AS FormationName, 'Wraithlord — Support Detachment' AS DetachmentName
    UNION ALL SELECT 'Crimson Hunter Detachment' AS FormationName, 'Crimson Hunter Detachment' AS DetachmentName
    UNION ALL SELECT 'Falcon Detachment' AS FormationName, 'Falcon Detachment' AS DetachmentName
    UNION ALL SELECT 'Firestorm Detachment' AS FormationName, 'Firestorm Detachment' AS DetachmentName
    UNION ALL SELECT 'Hornet Detachment' AS FormationName, 'Hornet Detachment' AS DetachmentName
    UNION ALL SELECT 'Lynx Detachment' AS FormationName, 'Lynx Detachment' AS DetachmentName
    UNION ALL SELECT 'Night Spinner Detachment' AS FormationName, 'Night Spinner Detachment' AS DetachmentName
    UNION ALL SELECT 'Nightwing Detachment' AS FormationName, 'Nightwing Detachment' AS DetachmentName
    UNION ALL SELECT 'Fire Prism Detachment' AS FormationName, 'Fire Prism Detachment' AS DetachmentName
    UNION ALL SELECT 'Unicorn Detachment' AS FormationName, 'Unicorn Detachment' AS DetachmentName
    UNION ALL SELECT 'Warp Hunter Detachment' AS FormationName, 'Warp Hunter Detachment' AS DetachmentName
    UNION ALL SELECT 'Bright Stalker Detachment' AS FormationName, 'Bright Stalker Detachment' AS DetachmentName
    UNION ALL SELECT 'Bright Stallion Detachment' AS FormationName, 'Bright Stallion Detachment' AS DetachmentName
    UNION ALL SELECT 'Wraithknight — Assault Detachment' AS FormationName, 'Wraithknight — Assault Detachment' AS DetachmentName
    UNION ALL SELECT 'Wraithknight — Support Detachment' AS FormationName, 'Wraithknight — Support Detachment' AS DetachmentName
    UNION ALL SELECT 'Fire Gale Detachment' AS FormationName, 'Fire Gale Detachment' AS DetachmentName
    UNION ALL SELECT 'Fire Reaper Detachment' AS FormationName, 'Fire Reaper Detachment' AS DetachmentName
    UNION ALL SELECT 'Fire Storm Detachment' AS FormationName, 'Fire Storm Detachment' AS DetachmentName
    UNION ALL SELECT 'Towering Destroyer Detachment' AS FormationName, 'Towering Destroyer Detachment' AS DetachmentName
    UNION ALL SELECT 'Cobra Detachment' AS FormationName, 'Cobra Detachment' AS DetachmentName
    UNION ALL SELECT 'Phoenix Detachment' AS FormationName, 'Phoenix Detachment' AS DetachmentName
    UNION ALL SELECT 'Scorpion Detachment' AS FormationName, 'Scorpion Detachment' AS DetachmentName
    UNION ALL SELECT 'Storm Serpent Detachment' AS FormationName, 'Storm Serpent Detachment' AS DetachmentName
    UNION ALL SELECT 'Tempest Detachment' AS FormationName, 'Tempest Detachment' AS DetachmentName
    UNION ALL SELECT 'Void Spinner Detachment' AS FormationName, 'Void Spinner Detachment' AS DetachmentName
    UNION ALL SELECT 'Wave Serpent Detachment' AS FormationName, 'Wave Serpent Detachment' AS DetachmentName
    UNION ALL SELECT 'Vampire Raider Detachment' AS FormationName, 'Vampire Raider Detachment' AS DetachmentName
    UNION ALL SELECT 'Baron Fire' AS FormationName, 'Baron Fire Detachment' AS DetachmentName
    UNION ALL SELECT 'Baron Stallion' AS FormationName, 'Baron Stallion Detachment' AS DetachmentName
    UNION ALL SELECT 'Shining Spears with Exarchs Detachment (Limited)' AS FormationName, 'Shining Spears with Exarchs Detachment' AS DetachmentName
    UNION ALL SELECT 'Off-Table Artillery (Pulsar Barrage)' AS FormationName, 'Off-Table Artillery (Pulsar Barrage)' AS DetachmentName
    UNION ALL SELECT 'Off-Table Artillery (Web Barrage)' AS FormationName, 'Off-Table Artillery (Web Barrage)' AS DetachmentName
) AS src
INNER JOIN Formation f
    ON f.CodexId = @codexId AND f.FormationName = src.FormationName
INNER JOIN Detachment d
    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName;

