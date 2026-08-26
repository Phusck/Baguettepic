-- Store base figures as BLOBs. Drops the old filename/URL column if present.

SET NAMES utf8mb4;

SET @hasImage := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Base'
      AND COLUMN_NAME = 'Image'
);

SET @sql := IF(
    @hasImage = 0,
    'ALTER TABLE `Base` ADD COLUMN Image MEDIUMBLOB NULL AFTER BaseName',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @hasImagePath := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Base'
      AND COLUMN_NAME = 'ImagePath'
);

SET @sql := IF(
    @hasImagePath = 1,
    'ALTER TABLE `Base` DROP COLUMN ImagePath',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
