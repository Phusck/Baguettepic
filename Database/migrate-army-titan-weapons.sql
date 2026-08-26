-- Store chosen titan weapons on the army list (ArmyFormation),
-- so Guest can add/remove them with existing ArmyFormation UPDATE rights.

SET NAMES utf8mb4;

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

SET @hasAfw := (
    SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'ArmyFormationWeapon'
);
SET @sql := IF(
    @hasAfw > 0,
    'UPDATE ArmyFormation af
     INNER JOIN (
         SELECT ArmyId, FormationId,
                JSON_ARRAYAGG(JSON_OBJECT(
                    ''id'', ArmyFormationWeaponId,
                    ''titanIndex'', TitanIndex,
                    ''titanWeaponId'', TitanWeaponId
                )) AS Weapons
         FROM ArmyFormationWeapon
         GROUP BY ArmyId, FormationId
     ) src ON src.ArmyId = af.ArmyId AND src.FormationId = af.FormationId
     SET af.TitanWeapons = src.Weapons',
    'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

DROP TABLE IF EXISTS ArmyFormationWeapon;
