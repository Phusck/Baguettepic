-- Move Synaptic Beacon from SpecialAbility onto Dominatrix psychic powers.

SET NAMES utf8mb4;

INSERT INTO PsychicPower (PsychicPowerName, Description)
SELECT sa.SpecialAbilityName, sa.Description
FROM SpecialAbility sa
WHERE sa.SpecialAbilityName = 'Synaptic Beacon'
AND NOT EXISTS (
    SELECT 1 FROM PsychicPower pp WHERE pp.PsychicPowerName = 'Synaptic Beacon'
);

INSERT INTO PsychicPower (PsychicPowerName, Description)
SELECT
    'Synaptic Beacon',
    '[Movement Phase, upon activation]: The Dominatrix extends the range of its Synapse radius to 60 cm for the remainder of the turn. In addition, during the End-of-Turn Effects, detachments acting on Instinct within 60 cm may attempt a Hive Mind Test. If successful, remove their Instinct counters.'
WHERE NOT EXISTS (
    SELECT 1 FROM PsychicPower WHERE PsychicPowerName = 'Synaptic Beacon'
);

INSERT INTO BasePsychicPower (BaseId, PsychicPowerId, AbilityValue)
SELECT b.BaseId, pp.PsychicPowerId, COALESCE(bsa.AbilityValue, '')
FROM `Base` b
CROSS JOIN PsychicPower pp
LEFT JOIN SpecialAbility sa ON sa.SpecialAbilityName = 'Synaptic Beacon'
LEFT JOIN BaseSpecialAbility bsa
    ON bsa.BaseId = b.BaseId AND bsa.SpecialAbilityId = sa.SpecialAbilityId
WHERE b.BaseName = 'Dominatrix'
  AND pp.PsychicPowerName = 'Synaptic Beacon'
ON DUPLICATE KEY UPDATE AbilityValue = VALUES(AbilityValue);

DELETE bsa FROM BaseSpecialAbility bsa
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = bsa.SpecialAbilityId
WHERE sa.SpecialAbilityName = 'Synaptic Beacon';

DELETE FROM SpecialAbility
WHERE SpecialAbilityName = 'Synaptic Beacon';
