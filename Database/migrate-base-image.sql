-- Add a path/URL for base images. Empty until an image is assigned.

SET NAMES utf8mb4;

SET @hasImagePath := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Base'
      AND COLUMN_NAME = 'ImagePath'
);

SET @sql := IF(
    @hasImagePath = 0,
    'ALTER TABLE `Base` ADD COLUMN ImagePath VARCHAR(512) NOT NULL DEFAULT '''' AFTER BaseName',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
