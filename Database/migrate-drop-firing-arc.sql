-- Weapon profiles no longer store firing arc.

SET NAMES utf8mb4;

SET @hasFiringArc := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Weapon'
      AND COLUMN_NAME = 'FiringArc'
);

SET @sql := IF(
    @hasFiringArc = 1,
    'ALTER TABLE Weapon DROP COLUMN FiringArc',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
