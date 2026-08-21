-- Core rules from Palladium Epic
-- Palladium_Epic_Rulebook_Experiement/00 - Intro/Important Concepts.tex

SET NAMES utf8mb4;

INSERT INTO Rule (RuleName, Description)
SELECT n, d FROM (
    SELECT
        'Pinned' AS n,
        'A base is pinned in an assault if it is engaged by an opponent of the same or a higher class. A pinned base loses its order and cannot move or fire. However, it may be activated during the Movement Phase if it has abilities or psychic powers that can be used.' AS d
) AS src
WHERE NOT EXISTS (
    SELECT 1 FROM Rule r WHERE r.RuleName = src.n
);
