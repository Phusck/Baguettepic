-- Remove free-text notes from saved army lists.

SET NAMES utf8mb4;

SET @hasNotes := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Army'
      AND COLUMN_NAME = 'Notes'
);

SET @sql := IF(
    @hasNotes = 0,
    'SELECT 1',
    'ALTER TABLE Army DROP COLUMN Notes'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
