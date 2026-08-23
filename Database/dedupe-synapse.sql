-- One-time cleanup: collapse Synapse to a single SpecialAbility named Synapse (X).
-- Safe to run more than once. Does not recreate other Tyranid data.

SET NAMES utf8mb4;

INSERT INTO SpecialAbility (SpecialAbilityName, Description)
SELECT n, d FROM (
    SELECT 'Synapse (X)' AS n,
     'A base with Synapse (X) is a synapse creature of the Hive Mind.\n\nAllied Tyranid detachments with the Slave ability that have at least one base within X cm of this base are in synapse range.\n\nA Slave detachment in synapse range may be given orders normally. It uses this base''s Morale value if that value is better than its own.\n\nSynapse creatures may always be given orders normally.' AS d
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM SpecialAbility sa WHERE sa.SpecialAbilityName = src.n
);

SET @synapseId := (SELECT SpecialAbilityId FROM SpecialAbility WHERE SpecialAbilityName = 'Synapse (X)');
SET @extraNames := '''Synapse (15 cm)'', ''Synapse (20 cm)'', ''Synapse'', ''Synnapse''';

-- Remap and drop extras on whichever junction tables exist.
SET @hasBaseSA := (
    SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = 'BaseSpecialAbility'
);
SET @sql := IF(@hasBaseSA = 0, 'SELECT 1', CONCAT(
    'UPDATE BaseSpecialAbility bsa ',
    'INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = bsa.SpecialAbilityId ',
    'LEFT JOIN BaseSpecialAbility already ',
    '    ON already.BaseId = bsa.BaseId AND already.SpecialAbilityId = ', @synapseId, ' ',
    'SET bsa.SpecialAbilityId = ', @synapseId, ' ',
    'WHERE sa.SpecialAbilityName IN (', @extraNames, ') ',
    'AND already.BaseId IS NULL'
));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(@hasBaseSA = 0, 'SELECT 1', CONCAT(
    'DELETE bsa FROM BaseSpecialAbility bsa ',
    'INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = bsa.SpecialAbilityId ',
    'WHERE sa.SpecialAbilityName IN (', @extraNames, ')'
));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @hasFormSA := (
    SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = 'FormationSpecialAbility'
);
SET @sql := IF(@hasFormSA = 0, 'SELECT 1', CONCAT(
    'UPDATE FormationSpecialAbility fsa ',
    'INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = fsa.SpecialAbilityId ',
    'LEFT JOIN FormationSpecialAbility already ',
    '    ON already.FormationId = fsa.FormationId AND already.SpecialAbilityId = ', @synapseId, ' ',
    'SET fsa.SpecialAbilityId = ', @synapseId, ' ',
    'WHERE sa.SpecialAbilityName IN (', @extraNames, ') ',
    'AND already.FormationId IS NULL'
));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(@hasFormSA = 0, 'SELECT 1', CONCAT(
    'DELETE fsa FROM FormationSpecialAbility fsa ',
    'INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = fsa.SpecialAbilityId ',
    'WHERE sa.SpecialAbilityName IN (', @extraNames, ')'
));
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

DELETE wsa
FROM WeaponSpecialAbility wsa
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = wsa.SpecialAbilityId
WHERE sa.SpecialAbilityName IN ('Synapse (15 cm)', 'Synapse (20 cm)', 'Synapse', 'Synnapse');

DELETE FROM SpecialAbility
WHERE SpecialAbilityName IN ('Synapse (15 cm)', 'Synapse (20 cm)', 'Synapse', 'Synnapse');

DELETE FROM SpecialRule
WHERE SpecialRuleName IN ('Synapse', 'Synnapse');

DELETE FROM Rule
WHERE RuleName IN ('Synapse', 'Synnapse');

DELETE sr FROM SpecialRule sr
INNER JOIN SpecialRule keep
    ON keep.CodexId = sr.CodexId
   AND keep.SpecialRuleName = sr.SpecialRuleName
   AND keep.SpecialRuleId < sr.SpecialRuleId;

SET @uq := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'SpecialRule'
      AND index_name = 'UQ_SpecialRule_Codex_Name'
);
SET @sql := IF(
    @uq = 0,
    'ALTER TABLE SpecialRule ADD UNIQUE KEY UQ_SpecialRule_Codex_Name (CodexId, SpecialRuleName)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
