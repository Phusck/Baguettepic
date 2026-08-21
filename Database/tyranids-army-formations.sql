-- Tyranids 3.0.0 slave formations from
-- Palladium NetEpic 3 English Latex/Tyranids 300/Army Formations.tex
-- FormationKind Support: each card is one detachment.
-- CommandPoints is negative because these consume synapse capacity.
-- DestructionPoints is 0 until listed. Composition is linked when the
-- unit profile exists.

SET NAMES utf8mb4;

SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Tyranids');

DELETE FROM Formation
WHERE CodexId = @codexId
  AND FormationName LIKE '% Detachment';

INSERT INTO Formation (
    CodexId, FormationKindId, FormationName, PointsCost, CommandPoints, Contents,
    DestructionPoints, Morale, `Class`, Movement, `Save`, FA, NumberOfTitanWeapons
)
SELECT
    @codexId,
    4,
    src.FormationName,
    src.PointsCost,
    src.CommandPoints,
    src.Contents,
    0,
    COALESCE(u.Morale, 0),
    src.Class,
    COALESCE(u.Movement, 0),
    COALESCE(u.Save, '--'),
    COALESCE(u.FA, 0),
    0
FROM (
    SELECT 'Barbgaunt Detachment' AS FormationName, '5 Barbgaunt bases' AS Contents, -1 AS CommandPoints, 100 AS PointsCost, 1 AS Class, 'Barbgaunt' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Hive Guard Detachment', '5 Hive Guard bases', -1, 200, 1, 'Hive Guard', 5
    UNION ALL SELECT 'Gargoyle Detachment', '5 Gargoyle bases', -1, 125, 1, 'Gargoyles', 5
    UNION ALL SELECT 'Genestealer Detachment', '5 Genestealer bases', -1, 200, 1, 'Genestealers', 5
    UNION ALL SELECT 'Hormagaunt Detachment', '5 Hormagaunt bases', -1, 100, 1, 'Hormagaunts', 5
    UNION ALL SELECT 'Lictor Detachment', '5 Lictor bases', -1, 225, 1, 'Lictor', 5
    UNION ALL SELECT 'Termagant Detachment', '10 Termagant bases', -1, 150, 1, 'Termagants', 10
    UNION ALL SELECT 'Ripper Detachment', '10 Ripper bases', -1, 100, 1, 'Rippers', 10
    UNION ALL SELECT 'Ravener Detachment', '5 Ravener bases', -1, 200, 2, 'Raveners', 5
    UNION ALL SELECT 'Carnifex Detachment', '3 Carnifex bases', -1, 175, 2, 'Carnifex', 3
    UNION ALL SELECT 'Venomthrope Detachment', '3 Venomthrope bases', -1, 100, 2, 'Venomthrope', 3
    UNION ALL SELECT 'Zoanthrope Detachment', '3 Zoanthrope bases', -1, 175, 2, 'Zoanthrope', 3
    UNION ALL SELECT 'Biovore Detachment', '3 Biovore bases', -1, 225, 3, 'Biovore', 3
    UNION ALL SELECT 'Dactylis Detachment', '3 Dactylis bases', -1, 250, 3, 'Dactylis', 3
    UNION ALL SELECT 'Exocrine Detachment', '3 Exocrine bases', -1, 225, 3, 'Exocrine', 3
    UNION ALL SELECT 'Harpy Detachment', '3 Harpy bases', -1, 225, 3, 'Harpy', 3
    UNION ALL SELECT 'Haruspex Detachment', '3 Haruspex bases', -1, 175, 3, 'Haruspex', 3
    UNION ALL SELECT 'Pyrovore Detachment', '3 Pyrovore bases', -1, 125, 3, 'Pyrovore', 3
    UNION ALL SELECT 'Toxicrene Detachment', '3 Toxicrene bases', -1, 150, 3, 'Toxicrene', 3
    UNION ALL SELECT 'Virago Detachment', '3 Virago bases', -1, 200, 3, 'Virago', 3
) AS src
LEFT JOIN Formation u
    ON u.CodexId = @codexId
   AND u.FormationName = src.UnitName;

INSERT INTO FormationComposition (FormationId, UnitFormationId, BaseCount)
SELECT det.FormationId, u.FormationId, src.BaseCount
FROM (
    SELECT 'Barbgaunt Detachment' AS FormationName, 'Barbgaunt' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Hive Guard Detachment', 'Hive Guard', 5
    UNION ALL SELECT 'Gargoyle Detachment', 'Gargoyles', 5
    UNION ALL SELECT 'Genestealer Detachment', 'Genestealers', 5
    UNION ALL SELECT 'Hormagaunt Detachment', 'Hormagaunts', 5
    UNION ALL SELECT 'Lictor Detachment', 'Lictor', 5
    UNION ALL SELECT 'Termagant Detachment', 'Termagants', 10
    UNION ALL SELECT 'Ripper Detachment', 'Rippers', 10
    UNION ALL SELECT 'Ravener Detachment', 'Raveners', 5
    UNION ALL SELECT 'Carnifex Detachment', 'Carnifex', 3
    UNION ALL SELECT 'Venomthrope Detachment', 'Venomthrope', 3
    UNION ALL SELECT 'Zoanthrope Detachment', 'Zoanthrope', 3
    UNION ALL SELECT 'Biovore Detachment', 'Biovore', 3
    UNION ALL SELECT 'Dactylis Detachment', 'Dactylis', 3
    UNION ALL SELECT 'Exocrine Detachment', 'Exocrine', 3
    UNION ALL SELECT 'Harpy Detachment', 'Harpy', 3
    UNION ALL SELECT 'Haruspex Detachment', 'Haruspex', 3
    UNION ALL SELECT 'Pyrovore Detachment', 'Pyrovore', 3
    UNION ALL SELECT 'Toxicrene Detachment', 'Toxicrene', 3
    UNION ALL SELECT 'Virago Detachment', 'Virago', 3
) AS src
INNER JOIN Formation det
    ON det.CodexId = @codexId AND det.FormationName = src.FormationName
INNER JOIN Formation u
    ON u.CodexId = @codexId AND u.FormationName = src.UnitName;
