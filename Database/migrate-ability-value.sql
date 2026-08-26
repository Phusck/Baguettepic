-- Store concrete parenthetical values on unit/weapon links.
-- Catalog rows stay parameterized (Elite (X), not Elite (2)).

SET NAMES utf8mb4;

SET @hasBsaValue := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'BaseSpecialAbility'
      AND COLUMN_NAME = 'AbilityValue'
);
SET @sql := IF(
    @hasBsaValue = 0,
    'ALTER TABLE BaseSpecialAbility ADD COLUMN AbilityValue VARCHAR(64) NOT NULL DEFAULT '''' AFTER SpecialAbilityId',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @hasWsaValue := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'WeaponSpecialAbility'
      AND COLUMN_NAME = 'AbilityValue'
);
SET @sql := IF(
    @hasWsaValue = 0,
    'ALTER TABLE WeaponSpecialAbility ADD COLUMN AbilityValue VARCHAR(64) NOT NULL DEFAULT '''' AFTER SpecialAbilityId',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

INSERT INTO SpecialAbility (SpecialAbilityName, Description)
SELECT n, d FROM (
    SELECT 'Elite (X)' AS n, 'At the beginning of the battle, your army receives a shared pool of Elite rerolls.\n\nEach detachment containing bases with Elite (X) adds X rerolls to this pool, regardless of how many Elite bases the detachment contains.\n\nDuring the battle, Elite rerolls may be spent to reroll dice rolled by your Elite bases. Before using them, declare the total number of dice that will be rerolled.\n\nOnly one Elite reroll may be used per base for each dice roll. Consequently, only one die from an assault roll may be rerolled.\n\nUsed Elite rerolls are removed from the army''s pool.\n\nElite rerolls may be used for:\n\n • To-Hit rolls for any type of shooting attack.\n • Armour saving throws.\n • Assault rolls.\n • Dodge rolls.\n • Opportunity attacks made when an enemy disengages.' AS d
    UNION ALL SELECT 'Regeneration (X+)', 'When a base with Regeneration (X+) would lose one or more Wounds, roll one die for each Wound lost.\n\nFor each result equal to or greater than X, the base does not lose that Wound. Regeneration functions against both shooting attacks and assaults.\n\nRegeneration is more difficult during an assault and suffers a -1 modifier.\n\nOnly one Regeneration attempt may be made for each Wound lost.\n\nA successful Regeneration roll prevents the loss of the Wound but does not cancel any additional effects caused by the attack, particularly effects applied through a Titan''s hit-location chart.'
    UNION ALL SELECT 'Deep Strike (X)', 'The controlling player selects a point on the battlefield and places one base from the detachment at that point. The base then scatters X times, moving 3D6 cm for each scatter.\n\nIf the final point is outside the battlefield, within Impassable terrain, or within the zone of control of an enemy base of the same or a higher class, the detachment does not arrive. Another attempt may be made during the following turn.\n\nOtherwise, place the first base as close as possible to the final arrival point. Place every other base in the detachment anywhere within 6 cm of the first base.\n\nNo base may arrive within Impassable terrain or within the zone of control of an enemy base of the same or a higher class.\n\nA detachment entering the battlefield in this manner cannot receive a First Fire order during the turn in which it arrives. It also loses 5 cm from its total available movement during that turn.\n\nLimited Assault\n\nOn the first turn, a Class 3 or higher detachment cannot select an initial arrival point within the opposing player''s half of the battlefield.'
    UNION ALL SELECT 'Damage (+X) in Assault', 'A weapon with this ability inflicts X additional hits after its base wins a duel, in addition to the normal hit.'
    UNION ALL SELECT 'Reduces Cover (X)', 'A weapon with this ability worsens the target''s cover save by X.'
    UNION ALL SELECT 'Synapse (X)', 'A base with Synapse (X) is a synapse creature of the Hive Mind.\n\nAllied Tyranid detachments with the Slave ability that have at least one base within X cm of this base are in synapse range.\n\nA Slave detachment in synapse range may be given orders normally. It uses this base''s Morale value if that value is better than its own.\n\nSynapse creatures may always be given orders normally.'
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM SpecialAbility sa WHERE sa.SpecialAbilityName = src.n
);

DROP TEMPORARY TABLE IF EXISTS AbilityFold;
CREATE TEMPORARY TABLE AbilityFold (
    InstanceName VARCHAR(128) PRIMARY KEY,
    TemplateName VARCHAR(128) NOT NULL,
    AbilityValue VARCHAR(64) NOT NULL
);
INSERT INTO AbilityFold (InstanceName, TemplateName, AbilityValue) VALUES
    ('Elite (1)', 'Elite (X)', '1'),
    ('Elite (2)', 'Elite (X)', '2'),
    ('Regeneration (5+)', 'Regeneration (X+)', '5'),
    ('Deep Strike (2)', 'Deep Strike (X)', '2'),
    ('Reduces Cover (-3)', 'Reduces Cover (X)', '-3'),
    ('Damage (+1) in Assault', 'Damage (+X) in Assault', '1'),
    ('Synapse (15 cm)', 'Synapse (X)', '15 cm'),
    ('Synapse (20 cm)', 'Synapse (X)', '20 cm');

UPDATE BaseSpecialAbility keep
INNER JOIN BaseSpecialAbility inst ON inst.BaseId = keep.BaseId
INNER JOIN SpecialAbility instSa ON instSa.SpecialAbilityId = inst.SpecialAbilityId
INNER JOIN AbilityFold fold ON fold.InstanceName = instSa.SpecialAbilityName
INNER JOIN SpecialAbility tmpl ON tmpl.SpecialAbilityName = fold.TemplateName
SET keep.AbilityValue = fold.AbilityValue
WHERE keep.SpecialAbilityId = tmpl.SpecialAbilityId
  AND keep.AbilityValue = '';

UPDATE BaseSpecialAbility bsa
INNER JOIN SpecialAbility instSa ON instSa.SpecialAbilityId = bsa.SpecialAbilityId
INNER JOIN AbilityFold fold ON fold.InstanceName = instSa.SpecialAbilityName
INNER JOIN SpecialAbility tmpl ON tmpl.SpecialAbilityName = fold.TemplateName
LEFT JOIN BaseSpecialAbility already
    ON already.BaseId = bsa.BaseId AND already.SpecialAbilityId = tmpl.SpecialAbilityId
SET bsa.SpecialAbilityId = tmpl.SpecialAbilityId,
    bsa.AbilityValue = fold.AbilityValue
WHERE already.BaseId IS NULL;

DELETE bsa FROM BaseSpecialAbility bsa
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = bsa.SpecialAbilityId
INNER JOIN AbilityFold fold ON fold.InstanceName = sa.SpecialAbilityName;

UPDATE WeaponSpecialAbility keep
INNER JOIN WeaponSpecialAbility inst ON inst.WeaponId = keep.WeaponId
INNER JOIN SpecialAbility instSa ON instSa.SpecialAbilityId = inst.SpecialAbilityId
INNER JOIN AbilityFold fold ON fold.InstanceName = instSa.SpecialAbilityName
INNER JOIN SpecialAbility tmpl ON tmpl.SpecialAbilityName = fold.TemplateName
SET keep.AbilityValue = fold.AbilityValue
WHERE keep.SpecialAbilityId = tmpl.SpecialAbilityId
  AND keep.AbilityValue = '';

UPDATE WeaponSpecialAbility wsa
INNER JOIN SpecialAbility instSa ON instSa.SpecialAbilityId = wsa.SpecialAbilityId
INNER JOIN AbilityFold fold ON fold.InstanceName = instSa.SpecialAbilityName
INNER JOIN SpecialAbility tmpl ON tmpl.SpecialAbilityName = fold.TemplateName
LEFT JOIN WeaponSpecialAbility already
    ON already.WeaponId = wsa.WeaponId AND already.SpecialAbilityId = tmpl.SpecialAbilityId
SET wsa.SpecialAbilityId = tmpl.SpecialAbilityId,
    wsa.AbilityValue = fold.AbilityValue
WHERE already.WeaponId IS NULL;

DELETE wsa FROM WeaponSpecialAbility wsa
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = wsa.SpecialAbilityId
INNER JOIN AbilityFold fold ON fold.InstanceName = sa.SpecialAbilityName;

DELETE sa FROM SpecialAbility sa
INNER JOIN AbilityFold fold ON fold.InstanceName = sa.SpecialAbilityName;

UPDATE BaseSpecialAbility bsa
INNER JOIN `Base` b ON b.BaseId = bsa.BaseId
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = bsa.SpecialAbilityId
SET bsa.AbilityValue = CASE b.BaseName
    WHEN 'Alpha Genestealer' THEN '15 cm'
    WHEN 'Tyranid Warriors' THEN '20 cm'
    ELSE bsa.AbilityValue
END
WHERE sa.SpecialAbilityName = 'Synapse (X)'
  AND bsa.AbilityValue = ''
  AND b.BaseName IN ('Alpha Genestealer', 'Tyranid Warriors');

DROP TEMPORARY TABLE AbilityFold;
