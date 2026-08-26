-- Spore Pods hit everything within 15 cm via their own rule, not Template (X).

SET NAMES utf8mb4;

DELETE wsa FROM WeaponSpecialAbility wsa
INNER JOIN Weapon w ON w.WeaponId = wsa.WeaponId
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = wsa.SpecialAbilityId
WHERE w.`Name` = 'Spore Pods'
  AND sa.SpecialAbilityName = 'Template (X)';
