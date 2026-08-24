-- Tyranids 3.0.0 slave formations from
-- https://github.com/Phusck/NetEpicFR300-EnglishTranslation
-- Tyranids 300/Army Formations.tex (branch Development)
-- FormationKind Support: each card is one formation containing one detachment.
-- CommandPoints is negative because these consume synapse capacity.
-- DestructionPoints is 0 until listed. Composition is linked when the
-- unit profile exists.

SET NAMES utf8mb4;

SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Tyranids');

DELETE FROM Formation
WHERE CodexId = @codexId
  AND FormationName LIKE '% Detachment';

DELETE FROM Detachment
WHERE CodexId = @codexId
  AND DetachmentName LIKE '% Detachment';

INSERT INTO Detachment (
    CodexId, DetachmentName, CommandPoints, `Class`
)
SELECT
    @codexId,
    src.DetachmentName,
    src.CommandPoints,
    src.Class
FROM (
    SELECT 'Barbgaunt Detachment' AS DetachmentName, -1 AS CommandPoints, 1 AS Class, 'Barbgaunt' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Hive Guard Detachment', -1, 1, 'Hive Guard', 5
    UNION ALL SELECT 'Gargoyle Detachment', -1, 1, 'Gargoyles', 5
    UNION ALL SELECT 'Genestealer Detachment', -1, 1, 'Genestealers', 5
    UNION ALL SELECT 'Hormagaunt Detachment', -1, 1, 'Hormagaunts', 5
    UNION ALL SELECT 'Lictor Detachment', -1, 1, 'Lictor', 5
    UNION ALL SELECT 'Termagant Detachment', -1, 1, 'Termagants', 10
    UNION ALL SELECT 'Ripper Detachment', -1, 1, 'Rippers', 10
    UNION ALL SELECT 'Ravener Detachment', -1, 2, 'Raveners', 5
    UNION ALL SELECT 'Carnifex Detachment', -1, 2, 'Carnifex', 3
    UNION ALL SELECT 'Venomthrope Detachment', -1, 2, 'Venomthrope', 3
    UNION ALL SELECT 'Zoanthrope Detachment', -1, 2, 'Zoanthrope', 3
    UNION ALL SELECT 'Biovore Detachment', -1, 3, 'Biovore', 3
    UNION ALL SELECT 'Dactylis Detachment', -1, 3, 'Dactylis', 3
    UNION ALL SELECT 'Exocrine Detachment', -1, 3, 'Exocrine', 3
    UNION ALL SELECT 'Harpy Detachment', -1, 3, 'Harpy', 3
    UNION ALL SELECT 'Haruspex Detachment', -1, 3, 'Haruspex', 3
    UNION ALL SELECT 'Pyrovore Detachment', -1, 3, 'Pyrovore', 3
    UNION ALL SELECT 'Toxicrene Detachment', -1, 3, 'Toxicrene', 3
    UNION ALL SELECT 'Virago Detachment', -1, 3, 'Virago', 3
) AS src;

INSERT INTO DetachmentComposition (DetachmentId, BaseId, BaseCount)
SELECT d.DetachmentId, b.BaseId, src.BaseCount
FROM (
    SELECT 'Barbgaunt Detachment' AS DetachmentName, 'Barbgaunt' AS UnitName, 5 AS BaseCount
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
INNER JOIN Detachment d
    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName
INNER JOIN `Base` b
    ON b.CodexId = @codexId AND b.BaseName = src.UnitName;

INSERT INTO Formation (
    CodexId, FormationKindId, FormationName, PointsCost, CommandPoints, Contents,
    DestructionPoints
)
SELECT
    @codexId,
    4,
    src.FormationName,
    src.PointsCost,
    src.CommandPoints,
    src.Contents,
    0
FROM (
    SELECT 'Barbgaunt Detachment' AS FormationName, '5 Barbgaunt bases' AS Contents, -1 AS CommandPoints, 100 AS PointsCost
    UNION ALL SELECT 'Hive Guard Detachment', '5 Hive Guard bases', -1, 200
    UNION ALL SELECT 'Gargoyle Detachment', '5 Gargoyle bases', -1, 125
    UNION ALL SELECT 'Genestealer Detachment', '5 Genestealer bases', -1, 200
    UNION ALL SELECT 'Hormagaunt Detachment', '5 Hormagaunt bases', -1, 100
    UNION ALL SELECT 'Lictor Detachment', '5 Lictor bases', -1, 225
    UNION ALL SELECT 'Termagant Detachment', '10 Termagant bases', -1, 150
    UNION ALL SELECT 'Ripper Detachment', '10 Ripper bases', -1, 100
    UNION ALL SELECT 'Ravener Detachment', '5 Ravener bases', -1, 200
    UNION ALL SELECT 'Carnifex Detachment', '3 Carnifex bases', -1, 175
    UNION ALL SELECT 'Venomthrope Detachment', '3 Venomthrope bases', -1, 100
    UNION ALL SELECT 'Zoanthrope Detachment', '3 Zoanthrope bases', -1, 175
    UNION ALL SELECT 'Biovore Detachment', '3 Biovore bases', -1, 225
    UNION ALL SELECT 'Dactylis Detachment', '3 Dactylis bases', -1, 250
    UNION ALL SELECT 'Exocrine Detachment', '3 Exocrine bases', -1, 225
    UNION ALL SELECT 'Harpy Detachment', '3 Harpy bases', -1, 225
    UNION ALL SELECT 'Haruspex Detachment', '3 Haruspex bases', -1, 175
    UNION ALL SELECT 'Pyrovore Detachment', '3 Pyrovore bases', -1, 125
    UNION ALL SELECT 'Toxicrene Detachment', '3 Toxicrene bases', -1, 150
    UNION ALL SELECT 'Virago Detachment', '3 Virago bases', -1, 200
) AS src;

INSERT INTO FormationDetachment (FormationId, DetachmentId, Quantity)
SELECT f.FormationId, d.DetachmentId, 1
FROM Formation f
INNER JOIN Detachment d
    ON d.CodexId = f.CodexId
   AND d.DetachmentName = f.FormationName
WHERE f.CodexId = @codexId
  AND f.FormationName LIKE '% Detachment';
