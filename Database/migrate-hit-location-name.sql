-- Titan hit location charts and damage tables are unique per codex
-- and must include the faction plus Titan.

SET NAMES utf8mb4;

UPDATE SpecialRule sr
INNER JOIN Codex c ON c.CodexId = sr.CodexId
SET sr.SpecialRuleName = CONCAT(
    CASE c.CodexName
        WHEN 'Tyranids' THEN 'Tyranid'
        ELSE c.CodexName
    END,
    ' Titan Hit Location Chart'
)
WHERE sr.SpecialRuleName IN (
    'Hit Location Chart',
    'Tyranid Hit Location Chart'
);

UPDATE SpecialRule sr
INNER JOIN Codex c ON c.CodexId = sr.CodexId
SET sr.SpecialRuleName = CONCAT(
    CASE c.CodexName
        WHEN 'Tyranids' THEN 'Tyranid'
        ELSE c.CodexName
    END,
    ' Titan Damage Effects'
)
WHERE sr.SpecialRuleName IN (
    'Damage Effects',
    'Tyranid Damage Effects'
);
