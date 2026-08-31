-- Command Points are a per-faction currency. Only Tyranids use them today.

SET NAMES utf8mb4;

SET @hasUsesCp := (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Codex'
      AND COLUMN_NAME = 'UsesCommandPoints'
);

SET @sql := IF(
    @hasUsesCp = 0,
    'ALTER TABLE Codex ADD COLUMN UsesCommandPoints TINYINT(1) NOT NULL DEFAULT 0 AFTER CodexName',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE Codex
SET UsesCommandPoints = 1
WHERE CodexName = 'Tyranids';

UPDATE Codex
SET UsesCommandPoints = 0
WHERE CodexName <> 'Tyranids';
