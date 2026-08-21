-- Tyranids 3.0.0 unit profiles from
-- Palladium NetEpic 3 English Latex/Tyranids 300/Unit Profiles.tex
-- Formations here are the unit profiles. Army-list detachments are seeded
-- separately in tyranids-army-formations.sql.
-- Morale 0 means "--" or "Attached" on the printed profile.

SET NAMES utf8mb4;

INSERT INTO Codex (CodexName)
SELECT 'Tyranids'
WHERE NOT EXISTS (SELECT 1 FROM Codex WHERE CodexName = 'Tyranids');

SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Tyranids');

DELETE FROM SpecialRule WHERE CodexId = @codexId;

DELETE fc
FROM FormationComposition fc
INNER JOIN Formation u ON u.FormationId = fc.UnitFormationId
WHERE u.CodexId = @codexId
  AND u.FormationName IN (
    'Barbgaunt', 'Hive Guard', 'Gargoyles', 'Alpha Genestealer',
    'Genestealers', 'Tyranid Warriors', 'Hormagaunts', 'Lictor',
    'Termagants', 'Rippers', 'Raveners'
  );

DELETE FROM Formation
WHERE CodexId = @codexId
  AND FormationName IN (
    'Barbgaunt', 'Hive Guard', 'Gargoyles', 'Alpha Genestealer',
    'Genestealers', 'Tyranid Warriors', 'Hormagaunts', 'Lictor',
    'Termagants', 'Rippers', 'Raveners'
  );

INSERT INTO SpecialAbility (SpecialAbilityName, Description)
SELECT n, d FROM (
    SELECT 'Synapse (X)' AS n, 'A base with Synapse (X) is a synapse creature of the Hive Mind.\n\nAllied Tyranid detachments with the Slave ability that have at least one base within X cm of this base are in synapse range.\n\nA Slave detachment in synapse range may be given orders normally. It uses this base''s Morale value if that value is better than its own.\n\nSynapse creatures may always be given orders normally.' AS d
    UNION ALL SELECT 'Synapse (15 cm)', 'A base with Synapse (15 cm) is a synapse creature of the Hive Mind.\n\nAllied Tyranid detachments with the Slave ability that have at least one base within 15 cm of this base are in synapse range.\n\nA Slave detachment in synapse range may be given orders normally. It uses this base''s Morale value if that value is better than its own.\n\nSynapse creatures may always be given orders normally.'
    UNION ALL SELECT 'Synapse (20 cm)', 'A base with Synapse (20 cm) is a synapse creature of the Hive Mind.\n\nAllied Tyranid detachments with the Slave ability that have at least one base within 20 cm of this base are in synapse range.\n\nA Slave detachment in synapse range may be given orders normally. It uses this base''s Morale value if that value is better than its own.\n\nSynapse creatures may always be given orders normally.'
    UNION ALL SELECT 'Slave (Hunt)', 'A detachment with this ability is subject to the Hunt instinct.\n\nIf it is not in synapse range at the start of the Strategy Phase, it must receive an Advance or Charge order and must move towards the nearest enemy detachment. If it is not engaged in an assault after its movement, it must shoot at the nearest visible enemy detachment.'
    UNION ALL SELECT 'Slave (Nest)', 'A detachment with this ability is subject to the Nest instinct.\n\nIf it is not in synapse range at the start of the Strategy Phase, it must receive a First Fire order and may not move. It must shoot at the nearest visible enemy detachment. It cannot perform Overwatch Fire while following this instinct.'
    UNION ALL SELECT 'Slave (Devastation)', 'A detachment with this ability is subject to the Devastation instinct.\n\nIf it is not in synapse range at the start of the Strategy Phase, it must receive a Charge order if it can engage an enemy detachment this turn. Otherwise it must move towards the nearest enemy detachment as far as its Charge movement allows.'
    UNION ALL SELECT 'Semi-Synaptic (Hunt)', 'This base is a limited synapse creature.\n\nAllied Slave (Hunt) detachments that have at least one base within 15 cm of this base are treated as being in synapse range, but only for the purpose of ignoring the Hunt instinct.\n\nSemi-Synaptic bases may always be given orders normally.'
    UNION ALL SELECT 'Semi-Synaptic (Devastation)', 'This base is a limited synapse creature.\n\nAllied Slave (Devastation) detachments that have at least one base within 15 cm of this base are treated as being in synapse range, but only for the purpose of ignoring the Devastation instinct.\n\nSemi-Synaptic bases may always be given orders normally.'
    UNION ALL SELECT 'Elite (1)', 'At the beginning of the battle, your army receives a shared pool of Elite rerolls.\n\nEach detachment containing bases with Elite (1) adds 1 reroll to this pool, regardless of how many Elite bases the detachment contains.\n\nDuring the battle, Elite rerolls may be spent to reroll dice rolled by your Elite bases. Before using them, declare the total number of dice that will be rerolled.\n\nOnly one Elite reroll may be used per base for each dice roll. Consequently, only one die from an assault roll may be rerolled.\n\nUsed Elite rerolls are removed from the army''s pool.\n\nElite rerolls may be used for:\n\n • To-Hit rolls for any type of shooting attack.\n • Armour saving throws.\n • Assault rolls.\n • Dodge rolls.\n • Opportunity attacks made when an enemy disengages.'
    UNION ALL SELECT 'Elite (2)', 'At the beginning of the battle, your army receives a shared pool of Elite rerolls.\n\nEach detachment containing bases with Elite (2) adds 2 rerolls to this pool, regardless of how many Elite bases the detachment contains.\n\nDuring the battle, Elite rerolls may be spent to reroll dice rolled by your Elite bases. Before using them, declare the total number of dice that will be rerolled.\n\nOnly one Elite reroll may be used per base for each dice roll. Consequently, only one die from an assault roll may be rerolled.\n\nUsed Elite rerolls are removed from the army''s pool.\n\nElite rerolls may be used for:\n\n • To-Hit rolls for any type of shooting attack.\n • Armour saving throws.\n • Assault rolls.\n • Dodge rolls.\n • Opportunity attacks made when an enemy disengages.'
    UNION ALL SELECT 'Regeneration (5+)', 'When a base with Regeneration (5+) would lose one or more Wounds, roll one die for each Wound lost.\n\nFor each result of 5+, the base does not lose that Wound. Regeneration functions against both shooting attacks and assaults.\n\nRegeneration is more difficult during an assault and suffers a -1 modifier.\n\nOnly one Regeneration attempt may be made for each Wound lost.\n\nA successful Regeneration roll prevents the loss of the Wound but does not cancel any additional effects caused by the attack, particularly effects applied through a Titan''s hit-location chart.'
    UNION ALL SELECT 'Deep Strike (2)', 'The controlling player selects a point on the battlefield and places one base from the detachment at that point. The base then scatters 2 times, moving 3D6 cm for each scatter.\n\nIf the final point is outside the battlefield, within Impassable terrain, or within the zone of control of an enemy base of the same or a higher class, the detachment does not arrive. Another attempt may be made during the following turn.\n\nOtherwise, place the first base as close as possible to the final arrival point. Place every other base in the detachment anywhere within 6 cm of the first base.\n\nNo base may arrive within Impassable terrain or within the zone of control of an enemy base of the same or a higher class.\n\nA detachment entering the battlefield in this manner cannot receive a First Fire order during the turn in which it arrives. It also loses 5 cm from its total available movement during that turn.\n\nLimited Assault\n\nOn the first turn, a Class 3 or higher detachment cannot select an initial arrival point within the opposing player''s half of the battlefield.'
    UNION ALL SELECT 'Damage (+1) in Assault', 'A weapon with this ability inflicts 1 additional hit after its base wins a duel, in addition to the normal hit.'
    UNION ALL SELECT 'Reduces Cover (-3)', 'A weapon with this ability worsens the target''s cover save by 3.'
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM SpecialAbility sa WHERE sa.SpecialAbilityName = src.n
);

INSERT INTO SpecialRule (CodexId, SpecialRuleName, Description) VALUES
(@codexId, 'Hive Mind',
 'Tyranid armies are directed by the Hive Mind rather than by conventional command structures.\n\nSynapse creatures project a radius listed on their profile. Allied Slave detachments with at least one base inside that radius are in synapse range and may be given orders normally.\n\nA Slave detachment that is not in synapse range must follow the instinct shown in parentheses on its Slave ability.'),
(@codexId, 'Synapse',
 'A base with Synapse (X) is a synapse creature. Allied Slave detachments within X cm may be given orders normally and use the Synapse base''s Morale value if it is better than their own.\n\nSynapse creatures may always be given orders normally.'),
(@codexId, 'Slave',
 'Slave creatures require direction from the Hive Mind.\n\nWhile in synapse range they may be given orders normally. While outside synapse range they must follow their listed instinct:\n\n • Hunt: Move towards the nearest enemy. Shoot the nearest visible enemy if not engaged in an assault.\n • Nest: Remain in place on First Fire orders and shoot the nearest visible enemy. Cannot perform Overwatch Fire.\n • Devastation: Charge if an enemy can be engaged this turn; otherwise move towards the nearest enemy at Charge speed.'),
(@codexId, 'Semi-Synaptic',
 'A Semi-Synaptic base is a limited synapse creature. Allied Slave detachments of the matching instinct within 15 cm are treated as being in synapse range, but only for the purpose of ignoring that instinct.\n\nSemi-Synaptic bases may always be given orders normally.');

INSERT INTO Formation (
    CodexId, FormationKindId, FormationName, PointsCost, DestructionPoints,
    Morale, `Class`, Movement, `Save`, FA, NumberOfTitanWeapons
) VALUES
    (@codexId, 4, 'Barbgaunt', 0, 0, 6, 1, 10, '--', 0, 0),
    (@codexId, 4, 'Hive Guard', 0, 0, 6, 1, 10, '4+', 2, 0),
    (@codexId, 4, 'Gargoyles', 0, 0, 6, 1, 15, '--', 1, 0),
    (@codexId, 4, 'Alpha Genestealer', 0, 0, 0, 1, 15, '5+', 8, 0),
    (@codexId, 4, 'Genestealers', 0, 0, 5, 1, 15, '--', 6, 0),
    (@codexId, 4, 'Tyranid Warriors', 0, 0, 0, 1, 10, '4+', 5, 0),
    (@codexId, 4, 'Hormagaunts', 0, 0, 6, 1, 15, '--', 2, 0),
    (@codexId, 4, 'Lictor', 0, 0, 5, 1, 15, '5+', 5, 0),
    (@codexId, 4, 'Termagants', 0, 0, 6, 1, 15, '--', 1, 0),
    (@codexId, 4, 'Rippers', 0, 0, 6, 1, 10, '--', -1, 0),
    (@codexId, 4, 'Raveners', 0, 0, 6, 2, 20, '6+f', 4, 0);

SET @barbgaunt := (SELECT FormationId FROM Formation WHERE CodexId = @codexId AND FormationName = 'Barbgaunt');
SET @hiveGuard := (SELECT FormationId FROM Formation WHERE CodexId = @codexId AND FormationName = 'Hive Guard');
SET @gargoyles := (SELECT FormationId FROM Formation WHERE CodexId = @codexId AND FormationName = 'Gargoyles');
SET @alpha := (SELECT FormationId FROM Formation WHERE CodexId = @codexId AND FormationName = 'Alpha Genestealer');
SET @stealers := (SELECT FormationId FROM Formation WHERE CodexId = @codexId AND FormationName = 'Genestealers');
SET @warriors := (SELECT FormationId FROM Formation WHERE CodexId = @codexId AND FormationName = 'Tyranid Warriors');
SET @hormagaunts := (SELECT FormationId FROM Formation WHERE CodexId = @codexId AND FormationName = 'Hormagaunts');
SET @lictor := (SELECT FormationId FROM Formation WHERE CodexId = @codexId AND FormationName = 'Lictor');
SET @termagants := (SELECT FormationId FROM Formation WHERE CodexId = @codexId AND FormationName = 'Termagants');
SET @rippers := (SELECT FormationId FROM Formation WHERE CodexId = @codexId AND FormationName = 'Rippers');
SET @raveners := (SELECT FormationId FROM Formation WHERE CodexId = @codexId AND FormationName = 'Raveners');

INSERT INTO Weapon (
    FormationId, `Name`, `Range`, Dice, ToHit, ArmourPenetration, FiringArc, IsTitanWeapon
) VALUES
    (@barbgaunt, 'Barbed Cannon', '45 cm', 1, '4+', 0, 360, 0),
    (@hiveGuard, 'Impaler Cannon', '45 cm', 1, '4+', -2, 360, 0),
    (@gargoyles, 'Flame Jet', '20 cm', 1, '5+', 0, 360, 0),
    (@alpha, 'Claws and Pincers', '--', 0, '--', 0, 0, 0),
    (@stealers, 'Claws and Pincers', '--', 0, '--', 0, 0, 0),
    (@warriors, 'Deathspitter', '45 cm', 1, '4+', -1, 360, 0),
    (@hormagaunts, 'Claws', '--', 0, '--', 0, 0, 0),
    (@lictor, 'Hooks', '20 cm', 2, '5+', 0, 360, 0),
    (@termagants, 'Fleshborers', '30 cm', 1, '5+', 0, 360, 0),
    (@rippers, 'Claws', '--', 0, '--', 0, 0, 0),
    (@raveners, 'Devourer', '20 cm', 2, '5+', -1, 360, 0);

SET @flameJet := (SELECT WeaponId FROM Weapon WHERE FormationId = @gargoyles AND `Name` = 'Flame Jet');
SET @alphaClaws := (SELECT WeaponId FROM Weapon WHERE FormationId = @alpha AND `Name` = 'Claws and Pincers');

INSERT INTO FormationSpecialAbility (FormationId, SpecialAbilityId)
SELECT f.FormationId, sa.SpecialAbilityId
FROM (
    SELECT @barbgaunt AS FormationId, 'Slave (Nest)' AS AbilityName
    UNION ALL SELECT @hiveGuard, 'Slave (Nest)'
    UNION ALL SELECT @gargoyles, 'Infiltration'
    UNION ALL SELECT @gargoyles, 'Jump Packs'
    UNION ALL SELECT @gargoyles, 'Slave (Hunt)'
    UNION ALL SELECT @alpha, 'Synapse (15 cm)'
    UNION ALL SELECT @alpha, 'Attached Character'
    UNION ALL SELECT @alpha, 'HQ'
    UNION ALL SELECT @alpha, 'Infiltration'
    UNION ALL SELECT @alpha, 'Elite (1)'
    UNION ALL SELECT @stealers, 'Semi-Synaptic (Devastation)'
    UNION ALL SELECT @stealers, 'Infiltration'
    UNION ALL SELECT @stealers, 'Elite (1)'
    UNION ALL SELECT @warriors, 'HQ'
    UNION ALL SELECT @warriors, 'Synapse (20 cm)'
    UNION ALL SELECT @warriors, 'Elite (2)'
    UNION ALL SELECT @warriors, 'Regeneration (5+)'
    UNION ALL SELECT @hormagaunts, 'Slave (Devastation)'
    UNION ALL SELECT @lictor, 'Infiltration'
    UNION ALL SELECT @lictor, 'Semi-Synaptic (Hunt)'
    UNION ALL SELECT @lictor, 'Advanced Camouflage'
    UNION ALL SELECT @termagants, 'Slave (Hunt)'
    UNION ALL SELECT @rippers, 'Free Deployment'
    UNION ALL SELECT @rippers, 'Slave (Devastation)'
    UNION ALL SELECT @raveners, 'Deep Strike (2)'
    UNION ALL SELECT @raveners, 'Slave (Devastation)'
    UNION ALL SELECT @raveners, 'Walker'
) AS f
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = f.AbilityName;

INSERT INTO WeaponSpecialAbility (WeaponId, SpecialAbilityId)
SELECT w.WeaponId, sa.SpecialAbilityId
FROM (
    SELECT @flameJet AS WeaponId, 'Reduces Cover (-3)' AS AbilityName
    UNION ALL SELECT @alphaClaws, 'Damage (+1) in Assault'
) AS w
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityName = w.AbilityName;
