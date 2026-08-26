-- DR (X+) was a made-up extra save. It is Close Defences (X+) from the rulebook.

SET NAMES utf8mb4;

INSERT INTO SpecialAbility (SpecialAbilityName, Description)
SELECT 'Close Defences (X+)',
       'Every Class 1 or 2 base that engages, or is engaged by, a base with Close Defences suffers a hit on X+ with AP 0.\n\nResolve the attack when the bases make contact. Cover saves may be used against Close Defences.'
WHERE NOT EXISTS (
    SELECT 1 FROM SpecialAbility WHERE SpecialAbilityName = 'Close Defences (X+)'
);

UPDATE SpecialAbility
SET Description = 'Every Class 1 or 2 base that engages, or is engaged by, a base with Close Defences suffers a hit on X+ with AP 0.\n\nResolve the attack when the bases make contact. Cover saves may be used against Close Defences.'
WHERE SpecialAbilityName = 'Close Defences (X+)';

UPDATE SpecialAbility
SET Description = REPLACE(Description, 'the Bio-Titan''s DR to 4+', 'the Bio-Titan''s Close Defences to 4+')
WHERE SpecialAbilityName = 'Spore Pods';

UPDATE TitanWeapon
SET Notes = REPLACE(Notes, 'Increases DR to 4+', 'Increases Close Defences to 4+')
WHERE Notes LIKE '%DR%';

DROP TEMPORARY TABLE IF EXISTS DrFold;
CREATE TEMPORARY TABLE DrFold (
    OldName VARCHAR(128) PRIMARY KEY,
    AbilityValue VARCHAR(64) NOT NULL
);
INSERT INTO DrFold (OldName, AbilityValue) VALUES
    ('DR (4+)', '4'),
    ('DR (5+)', '5'),
    ('DR (6+)', '6');

DELETE bsa FROM BaseSpecialAbility bsa
INNER JOIN SpecialAbility old ON old.SpecialAbilityId = bsa.SpecialAbilityId
INNER JOIN SpecialAbility cd ON cd.SpecialAbilityName = 'Close Defences (X+)'
LEFT JOIN DrFold fold ON fold.OldName = old.SpecialAbilityName
INNER JOIN BaseSpecialAbility already
    ON already.BaseId = bsa.BaseId AND already.SpecialAbilityId = cd.SpecialAbilityId
WHERE old.SpecialAbilityName = 'DR (X+)' OR fold.OldName IS NOT NULL;

UPDATE BaseSpecialAbility bsa
INNER JOIN SpecialAbility old ON old.SpecialAbilityId = bsa.SpecialAbilityId
INNER JOIN SpecialAbility cd ON cd.SpecialAbilityName = 'Close Defences (X+)'
LEFT JOIN DrFold fold ON fold.OldName = old.SpecialAbilityName
SET bsa.SpecialAbilityId = cd.SpecialAbilityId,
    bsa.AbilityValue = CASE
        WHEN fold.OldName IS NOT NULL THEN fold.AbilityValue
        ELSE bsa.AbilityValue
    END
WHERE old.SpecialAbilityName = 'DR (X+)' OR fold.OldName IS NOT NULL;

DELETE wsa FROM WeaponSpecialAbility wsa
INNER JOIN SpecialAbility old ON old.SpecialAbilityId = wsa.SpecialAbilityId
INNER JOIN SpecialAbility cd ON cd.SpecialAbilityName = 'Close Defences (X+)'
LEFT JOIN DrFold fold ON fold.OldName = old.SpecialAbilityName
INNER JOIN WeaponSpecialAbility already
    ON already.WeaponId = wsa.WeaponId AND already.SpecialAbilityId = cd.SpecialAbilityId
WHERE old.SpecialAbilityName = 'DR (X+)' OR fold.OldName IS NOT NULL;

UPDATE WeaponSpecialAbility wsa
INNER JOIN SpecialAbility old ON old.SpecialAbilityId = wsa.SpecialAbilityId
INNER JOIN SpecialAbility cd ON cd.SpecialAbilityName = 'Close Defences (X+)'
LEFT JOIN DrFold fold ON fold.OldName = old.SpecialAbilityName
SET wsa.SpecialAbilityId = cd.SpecialAbilityId,
    wsa.AbilityValue = CASE
        WHEN fold.OldName IS NOT NULL THEN fold.AbilityValue
        ELSE wsa.AbilityValue
    END
WHERE old.SpecialAbilityName = 'DR (X+)' OR fold.OldName IS NOT NULL;

DELETE FROM SpecialAbility
WHERE SpecialAbilityName = 'DR (X+)'
   OR SpecialAbilityName IN ('DR (4+)', 'DR (5+)', 'DR (6+)');
