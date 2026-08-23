-- One-time migration: split the overloaded Formation table into
-- Formation (purchasable cards), Detachment, and Base (unit profiles).
-- Purchasable FormationIds are preserved so ArmyFormation stays valid.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `Base` (
    BaseId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    CodexId INT UNSIGNED NOT NULL,
    BaseName VARCHAR(128) NOT NULL,
    DestructionPoints INT NOT NULL DEFAULT 0,
    Morale INT NOT NULL,
    `Class` INT NOT NULL,
    Movement INT NOT NULL,
    `Save` VARCHAR(16) NOT NULL,
    FA INT NOT NULL,
    NumberOfTitanWeapons INT NOT NULL DEFAULT 0,
    PRIMARY KEY (BaseId),
    UNIQUE KEY UQ_Base_Codex_Name (CodexId, BaseName),
    KEY IX_Base_Codex (CodexId),
    CONSTRAINT FK_Base_Codex
        FOREIGN KEY (CodexId) REFERENCES Codex (CodexId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS Detachment (
    DetachmentId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    CodexId INT UNSIGNED NOT NULL,
    DetachmentName VARCHAR(128) NOT NULL,
    CommandPoints INT NOT NULL DEFAULT 0,
    `Class` INT NOT NULL,
    PRIMARY KEY (DetachmentId),
    UNIQUE KEY UQ_Detachment_Codex_Name (CodexId, DetachmentName),
    KEY IX_Detachment_Codex (CodexId),
    CONSTRAINT FK_Detachment_Codex
        FOREIGN KEY (CodexId) REFERENCES Codex (CodexId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS DetachmentComposition (
    DetachmentId INT UNSIGNED NOT NULL,
    BaseId INT UNSIGNED NOT NULL,
    BaseCount INT UNSIGNED NOT NULL,
    PRIMARY KEY (DetachmentId, BaseId),
    KEY IX_DC_Base (BaseId),
    CONSTRAINT FK_DC_Detachment
        FOREIGN KEY (DetachmentId) REFERENCES Detachment (DetachmentId)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_DC_Base
        FOREIGN KEY (BaseId) REFERENCES `Base` (BaseId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS FormationDetachment (
    FormationId INT UNSIGNED NOT NULL,
    DetachmentId INT UNSIGNED NOT NULL,
    Quantity INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (FormationId, DetachmentId),
    KEY IX_FD_Detachment (DetachmentId),
    CONSTRAINT FK_FD_Formation
        FOREIGN KEY (FormationId) REFERENCES Formation (FormationId)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_FD_Detachment
        FOREIGN KEY (DetachmentId) REFERENCES Detachment (DetachmentId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS BaseSpecialAbility (
    BaseId INT UNSIGNED NOT NULL,
    SpecialAbilityId INT UNSIGNED NOT NULL,
    PRIMARY KEY (BaseId, SpecialAbilityId),
    KEY IX_BSA_Ability (SpecialAbilityId),
    CONSTRAINT FK_BSA_Base
        FOREIGN KEY (BaseId) REFERENCES `Base` (BaseId)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_BSA_Ability
        FOREIGN KEY (SpecialAbilityId) REFERENCES SpecialAbility (SpecialAbilityId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @hasMorale := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Formation'
      AND COLUMN_NAME = 'Morale'
);

SET @sql := IF(
    @hasMorale = 0,
    'SELECT 1',
    'INSERT INTO `Base` (BaseId, CodexId, BaseName, DestructionPoints, Morale, `Class`, Movement, `Save`, FA, NumberOfTitanWeapons) SELECT f.FormationId, f.CodexId, f.FormationName, f.DestructionPoints, f.Morale, f.`Class`, f.Movement, f.`Save`, f.FA, f.NumberOfTitanWeapons FROM Formation f WHERE f.PointsCost = 0 AND f.FormationName NOT LIKE ''% Detachment'' ON DUPLICATE KEY UPDATE DestructionPoints = VALUES(DestructionPoints), Morale = VALUES(Morale), `Class` = VALUES(`Class`), Movement = VALUES(Movement), `Save` = VALUES(`Save`), FA = VALUES(FA), NumberOfTitanWeapons = VALUES(NumberOfTitanWeapons)'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
    @hasMorale = 0,
    'SELECT 1',
    'INSERT INTO Detachment (DetachmentId, CodexId, DetachmentName, CommandPoints, `Class`) SELECT f.FormationId, f.CodexId, f.FormationName, f.CommandPoints, f.`Class` FROM Formation f WHERE f.PointsCost > 0 OR f.FormationName LIKE ''% Detachment'' ON DUPLICATE KEY UPDATE CommandPoints = VALUES(CommandPoints), `Class` = VALUES(`Class`)'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

INSERT INTO FormationDetachment (FormationId, DetachmentId, Quantity)
SELECT f.FormationId, f.FormationId, 1
FROM Formation f
WHERE f.PointsCost > 0
   OR f.FormationName LIKE '% Detachment'
ON DUPLICATE KEY UPDATE Quantity = VALUES(Quantity);

SET @hasFc := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'FormationComposition'
);
SET @sql := IF(
    @hasFc = 0,
    'SELECT 1',
    'INSERT INTO DetachmentComposition (DetachmentId, BaseId, BaseCount) SELECT fc.FormationId, fc.UnitFormationId, fc.BaseCount FROM FormationComposition fc INNER JOIN Formation parent ON parent.FormationId = fc.FormationId INNER JOIN Formation unit ON unit.FormationId = fc.UnitFormationId WHERE (parent.PointsCost > 0 OR parent.FormationName LIKE ''% Detachment'') AND unit.PointsCost = 0 AND unit.FormationName NOT LIKE ''% Detachment'' ON DUPLICATE KEY UPDATE BaseCount = VALUES(BaseCount)'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @hasFsa := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'FormationSpecialAbility'
);
SET @sql := IF(
    @hasFsa = 0,
    'SELECT 1',
    'INSERT INTO BaseSpecialAbility (BaseId, SpecialAbilityId) SELECT fsa.FormationId, fsa.SpecialAbilityId FROM FormationSpecialAbility fsa INNER JOIN Formation f ON f.FormationId = fsa.FormationId WHERE f.PointsCost = 0 AND f.FormationName NOT LIKE ''% Detachment'' ON DUPLICATE KEY UPDATE SpecialAbilityId = VALUES(SpecialAbilityId)'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Point weapons at the copied base rows (same ids as the old unit-profile formations).
SET @weaponHasBaseId := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Weapon'
      AND COLUMN_NAME = 'BaseId'
);

SET @sql := IF(
    @weaponHasBaseId = 0,
    'ALTER TABLE Weapon ADD COLUMN BaseId INT UNSIGNED NULL AFTER WeaponId',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @weaponHasFormationId := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Weapon'
      AND COLUMN_NAME = 'FormationId'
);

SET @sql := IF(
    @weaponHasFormationId = 0,
    'SELECT 1',
    'UPDATE Weapon w INNER JOIN Formation f ON f.FormationId = w.FormationId SET w.BaseId = w.FormationId WHERE w.BaseId IS NULL AND f.PointsCost = 0 AND f.FormationName NOT LIKE ''% Detachment'''
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DELETE w
FROM Weapon w
LEFT JOIN `Base` b ON b.BaseId = w.BaseId
WHERE w.BaseId IS NULL OR b.BaseId IS NULL;

SET @fk := (
    SELECT CONSTRAINT_NAME
    FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Weapon'
      AND CONSTRAINT_NAME = 'FK_Weapon_Formation'
    LIMIT 1
);
SET @sql := IF(@fk IS NULL, 'SELECT 1', 'ALTER TABLE Weapon DROP FOREIGN KEY FK_Weapon_Formation');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx := (
    SELECT INDEX_NAME
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Weapon'
      AND INDEX_NAME = 'IX_Weapon_Formation'
    LIMIT 1
);
SET @sql := IF(@idx IS NULL, 'SELECT 1', 'ALTER TABLE Weapon DROP INDEX IX_Weapon_Formation');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col := (
    SELECT COLUMN_NAME
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Weapon'
      AND COLUMN_NAME = 'FormationId'
);
SET @sql := IF(@col IS NULL, 'SELECT 1', 'ALTER TABLE Weapon DROP COLUMN FormationId');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ALTER TABLE Weapon
    MODIFY BaseId INT UNSIGNED NOT NULL;

SET @idx := (
    SELECT INDEX_NAME
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Weapon'
      AND INDEX_NAME = 'IX_Weapon_Base'
    LIMIT 1
);
SET @sql := IF(@idx IS NULL, 'ALTER TABLE Weapon ADD KEY IX_Weapon_Base (BaseId)', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk := (
    SELECT CONSTRAINT_NAME
    FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Weapon'
      AND CONSTRAINT_NAME = 'FK_Weapon_Base'
    LIMIT 1
);
SET @sql := IF(
    @fk IS NULL,
    'ALTER TABLE Weapon ADD CONSTRAINT FK_Weapon_Base FOREIGN KEY (BaseId) REFERENCES `Base` (BaseId) ON UPDATE CASCADE ON DELETE CASCADE',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @hasFsa := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'FormationSpecialAbility'
);
SET @sql := IF(
    @hasFsa = 0,
    'SELECT 1',
    'DELETE FROM FormationSpecialAbility WHERE FormationId IN (SELECT BaseId FROM `Base`)'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @hasFc := (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'FormationComposition'
);
SET @sql := IF(@hasFc = 0, 'SELECT 1', 'DELETE FROM FormationComposition');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DELETE FROM Formation
WHERE PointsCost = 0
  AND FormationName NOT LIKE '% Detachment';

DROP TABLE IF EXISTS FormationComposition;
DROP TABLE IF EXISTS FormationSpecialAbility;

SET @col := (
    SELECT COLUMN_NAME
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Formation'
      AND COLUMN_NAME = 'Morale'
);
SET @sql := IF(
    @col IS NULL,
    'SELECT 1',
    'ALTER TABLE Formation DROP COLUMN Morale, DROP COLUMN `Class`, DROP COLUMN Movement, DROP COLUMN `Save`, DROP COLUMN FA, DROP COLUMN NumberOfTitanWeapons'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @formationHasUnique := (
    SELECT COUNT(*)
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Formation'
      AND INDEX_NAME = 'UQ_Formation_Codex_Name'
);

SET @sql := IF(
    @formationHasUnique = 0,
    'ALTER TABLE Formation ADD UNIQUE KEY UQ_Formation_Codex_Name (CodexId, FormationName)',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;
