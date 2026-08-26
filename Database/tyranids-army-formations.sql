-- Tyranids 3.0.0 army formations from
-- NetEpicFR300-EnglishTranslation/Tyranids 300/army-formations.tex

SET NAMES utf8mb4;

SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Tyranids');

INSERT INTO Detachment (
    CodexId, DetachmentName, CommandPoints, `Class`
) VALUES
    (@codexId, 'Dominatrix Detachment', 6, 4),
    (@codexId, 'Alpha Genestealer', 1, 1),
    (@codexId, 'Tyranid Warrior Detachment', 3, 1),
    (@codexId, 'Harridan Detachment', 1, 4),
    (@codexId, 'Neurotyrant Detachment', 1, 3),
    (@codexId, 'Winged Hive Tyrant Detachment', 3, 2),
    (@codexId, 'Hive Tyrant Detachment', 3, 2),
    (@codexId, 'Norn Queen Detachment', 3, 4),
    (@codexId, 'Trygon Detachment', 1, 4),
    (@codexId, 'Barbgaunt Detachment', -1, 1),
    (@codexId, 'Hive Guard Detachment', -1, 1),
    (@codexId, 'Gargoyle Detachment', -1, 1),
    (@codexId, 'Genestealer Detachment', -1, 1),
    (@codexId, 'Hormagaunt Detachment', -1, 1),
    (@codexId, 'Lictor Detachment', -1, 1),
    (@codexId, 'Termagant Detachment', -1, 1),
    (@codexId, 'Ripper Detachment', -1, 1),
    (@codexId, 'Ravener Detachment', -1, 2),
    (@codexId, 'Carnifex Detachment', -1, 2),
    (@codexId, 'Venomthrope Detachment', -1, 2),
    (@codexId, 'Zoanthrope Detachment', -1, 2),
    (@codexId, 'Biovore Detachment', -1, 3),
    (@codexId, 'Dactylis Detachment', -1, 3),
    (@codexId, 'Exocrine Detachment', -1, 3),
    (@codexId, 'Harpy Detachment', -1, 3),
    (@codexId, 'Haruspex Detachment', -1, 3),
    (@codexId, 'Pyrovore Detachment', -1, 3),
    (@codexId, 'Toxicrene Detachment', -1, 3),
    (@codexId, 'Virago Detachment', -1, 3),
    (@codexId, 'Barbed Hierodule Detachment', -2, 4),
    (@codexId, 'Scythed Hierodule Detachment', -2, 4),
    (@codexId, 'Razorfex Detachment', -1, 4),
    (@codexId, 'Assault Tyrannofex Detachment', -1, 4),
    (@codexId, 'Support Tyrannofex Detachment', -1, 4),
    (@codexId, 'Alpha Hierodule Detachment', -2, 5),
    (@codexId, 'Hierophant Detachment', -2, 6),
    (@codexId, 'Malefactor Detachment', -1, 3),
    (@codexId, 'Mycetic Spore Detachment', 0, 3),
    (@codexId, 'Tervigon Detachment', -1, 3),
    (@codexId, 'Off-Table Artillery (Bio-Plasma)', -1, 0),
    (@codexId, 'Off-Table Artillery (Spore-Mine)', -1, 0);

INSERT INTO DetachmentComposition (DetachmentId, BaseId, BaseCount)
SELECT d.DetachmentId, b.BaseId, src.BaseCount
FROM (
    SELECT 'Dominatrix Detachment' AS DetachmentName, 'Dominatrix' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Alpha Genestealer' AS DetachmentName, 'Alpha Genestealer' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Tyranid Warrior Detachment' AS DetachmentName, 'Tyranid Warriors' AS UnitName, 4 AS BaseCount
    UNION ALL SELECT 'Harridan Detachment' AS DetachmentName, 'Harridan' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Neurotyrant Detachment' AS DetachmentName, 'Neurotyrant' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Winged Hive Tyrant Detachment' AS DetachmentName, 'Winged Hive Tyrant' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Hive Tyrant Detachment' AS DetachmentName, 'Hive Tyrant' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Norn Queen Detachment' AS DetachmentName, 'Norn Queen' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Trygon Detachment' AS DetachmentName, 'Trygon' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Barbgaunt Detachment' AS DetachmentName, 'Barbgaunt' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Hive Guard Detachment' AS DetachmentName, 'Hive Guard' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Gargoyle Detachment' AS DetachmentName, 'Gargoyles' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Genestealer Detachment' AS DetachmentName, 'Genestealers' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Hormagaunt Detachment' AS DetachmentName, 'Hormagaunts' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Lictor Detachment' AS DetachmentName, 'Lictor' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Termagant Detachment' AS DetachmentName, 'Termagants' AS UnitName, 10 AS BaseCount
    UNION ALL SELECT 'Ripper Detachment' AS DetachmentName, 'Rippers' AS UnitName, 10 AS BaseCount
    UNION ALL SELECT 'Ravener Detachment' AS DetachmentName, 'Raveners' AS UnitName, 5 AS BaseCount
    UNION ALL SELECT 'Carnifex Detachment' AS DetachmentName, 'Carnifex' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Venomthrope Detachment' AS DetachmentName, 'Venomthrope' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Zoanthrope Detachment' AS DetachmentName, 'Zoanthrope' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Biovore Detachment' AS DetachmentName, 'Biovore' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Dactylis Detachment' AS DetachmentName, 'Dactylis' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Exocrine Detachment' AS DetachmentName, 'Exocrine' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Harpy Detachment' AS DetachmentName, 'Harpy' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Haruspex Detachment' AS DetachmentName, 'Haruspex' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Pyrovore Detachment' AS DetachmentName, 'Pyrovore' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Toxicrene Detachment' AS DetachmentName, 'Toxicrene' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Virago Detachment' AS DetachmentName, 'Virago' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Barbed Hierodule Detachment' AS DetachmentName, 'Barbed Hierodule' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Scythed Hierodule Detachment' AS DetachmentName, 'Scythed Hierodule' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Razorfex Detachment' AS DetachmentName, 'Razorfex' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Assault Tyrannofex Detachment' AS DetachmentName, 'Assault Tyrannofex' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Support Tyrannofex Detachment' AS DetachmentName, 'Support Tyrannofex' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Alpha Hierodule Detachment' AS DetachmentName, 'Alpha Hierodule' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Hierophant Detachment' AS DetachmentName, 'Hierophant' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Malefactor Detachment' AS DetachmentName, 'Malefactor' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Mycetic Spore Detachment' AS DetachmentName, 'Mycetic Spore' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Tervigon Detachment' AS DetachmentName, 'Tervigon' AS UnitName, 3 AS BaseCount
    UNION ALL SELECT 'Off-Table Artillery (Bio-Plasma)' AS DetachmentName, 'Bio-Plasma Shot' AS UnitName, 1 AS BaseCount
    UNION ALL SELECT 'Off-Table Artillery (Spore-Mine)' AS DetachmentName, 'Spore-Mine Shot' AS UnitName, 1 AS BaseCount
) AS src
INNER JOIN Detachment d
    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName
INNER JOIN `Base` b
    ON b.CodexId = @codexId AND b.BaseName = src.UnitName;

INSERT INTO Formation (
    CodexId, FormationKindId, FormationName, PointsCost, CommandPoints, Contents,
    DestructionPoints
) VALUES
    (@codexId, 7, 'Dominatrix Detachment', 400, 6, '1 Dominatrix base (Limit: one per 3,000 points)', 0),
    (@codexId, 5, 'Alpha Genestealer', 50, 1, '1 Alpha Genestealer base (May only be attached to Genestealers)', 0),
    (@codexId, 7, 'Tyranid Warrior Detachment', 225, 3, '4 Tyranid Warrior bases', 0),
    (@codexId, 7, 'Harridan Detachment', 225, 1, '1 Harridan base', 0),
    (@codexId, 7, 'Neurotyrant Detachment', 175, 1, '3 Neurotyrant bases', 0),
    (@codexId, 7, 'Winged Hive Tyrant Detachment', 250, 3, '3 Winged Hive Tyrant bases', 0),
    (@codexId, 7, 'Hive Tyrant Detachment', 250, 3, '3 Hive Tyrant bases', 0),
    (@codexId, 7, 'Norn Queen Detachment', 275, 3, '1 Norn Queen base', 0),
    (@codexId, 7, 'Trygon Detachment', 200, 1, '1 Trygon base', 0),
    (@codexId, 8, 'Barbgaunt Detachment', 100, -1, '5 Barbgaunt bases', 0),
    (@codexId, 8, 'Hive Guard Detachment', 200, -1, '5 Hive Guard bases', 0),
    (@codexId, 8, 'Gargoyle Detachment', 125, -1, '5 Gargoyle bases', 0),
    (@codexId, 8, 'Genestealer Detachment', 200, -1, '5 Genestealer bases', 0),
    (@codexId, 8, 'Hormagaunt Detachment', 100, -1, '5 Hormagaunt bases', 0),
    (@codexId, 8, 'Lictor Detachment', 225, -1, '5 Lictor bases', 0),
    (@codexId, 8, 'Termagant Detachment', 150, -1, '10 Termagant bases', 0),
    (@codexId, 8, 'Ripper Detachment', 100, -1, '10 Ripper bases', 0),
    (@codexId, 8, 'Ravener Detachment', 200, -1, '5 Ravener bases', 0),
    (@codexId, 8, 'Carnifex Detachment', 175, -1, '3 Carnifex bases', 0),
    (@codexId, 8, 'Venomthrope Detachment', 100, -1, '3 Venomthrope bases', 0),
    (@codexId, 8, 'Zoanthrope Detachment', 175, -1, '3 Zoanthrope bases', 0),
    (@codexId, 8, 'Biovore Detachment', 225, -1, '3 Biovore bases', 0),
    (@codexId, 8, 'Dactylis Detachment', 250, -1, '3 Dactylis bases', 0),
    (@codexId, 8, 'Exocrine Detachment', 225, -1, '3 Exocrine bases', 0),
    (@codexId, 8, 'Harpy Detachment', 225, -1, '3 Harpy bases', 0),
    (@codexId, 8, 'Haruspex Detachment', 175, -1, '3 Haruspex bases', 0),
    (@codexId, 8, 'Pyrovore Detachment', 125, -1, '3 Pyrovore bases', 0),
    (@codexId, 8, 'Toxicrene Detachment', 150, -1, '3 Toxicrene bases', 0),
    (@codexId, 8, 'Virago Detachment', 200, -1, '3 Virago bases', 0),
    (@codexId, 8, 'Barbed Hierodule Detachment', 300, -2, '1 Barbed Hierodule base', 0),
    (@codexId, 8, 'Scythed Hierodule Detachment', 250, -2, '1 Scythed Hierodule base', 0),
    (@codexId, 8, 'Razorfex Detachment', 300, -1, '3 Razorfex bases', 0),
    (@codexId, 8, 'Assault Tyrannofex Detachment', 200, -1, '1 Assault Tyrannofex base', 0),
    (@codexId, 8, 'Support Tyrannofex Detachment', 200, -1, '1 Support Tyrannofex base', 0),
    (@codexId, 8, 'Alpha Hierodule Detachment', 325, -2, '1 Alpha Hierodule base (2 weapons must be purchased)', 0),
    (@codexId, 8, 'Hierophant Detachment', 425, -2, '1 Hierophant base (3 weapons must be purchased)', 0),
    (@codexId, 5, 'Malefactor Detachment', 125, -1, '3 Malefactor bases', 0),
    (@codexId, 5, 'Mycetic Spore Detachment', 50, 0, 'Enough Mycetic Spores to transport one Class 1 or 2 detachment', 0),
    (@codexId, 5, 'Tervigon Detachment', 150, -1, '3 Tervigon bases', 0),
    (@codexId, 6, 'Off-Table Artillery (Bio-Plasma)', 100, -1, '1 Bio-Plasma Shot (Limit: 1 per 2,000 points)', 0),
    (@codexId, 6, 'Off-Table Artillery (Spore-Mine)', 100, -1, '1 Spore-Mine Shot (Limit: 1 per 2,000 points)', 0);

INSERT INTO FormationDetachment (FormationId, DetachmentId, Quantity)
SELECT f.FormationId, d.DetachmentId, 1
FROM (
    SELECT 'Dominatrix Detachment' AS FormationName, 'Dominatrix Detachment' AS DetachmentName
    UNION ALL SELECT 'Alpha Genestealer' AS FormationName, 'Alpha Genestealer' AS DetachmentName
    UNION ALL SELECT 'Tyranid Warrior Detachment' AS FormationName, 'Tyranid Warrior Detachment' AS DetachmentName
    UNION ALL SELECT 'Harridan Detachment' AS FormationName, 'Harridan Detachment' AS DetachmentName
    UNION ALL SELECT 'Neurotyrant Detachment' AS FormationName, 'Neurotyrant Detachment' AS DetachmentName
    UNION ALL SELECT 'Winged Hive Tyrant Detachment' AS FormationName, 'Winged Hive Tyrant Detachment' AS DetachmentName
    UNION ALL SELECT 'Hive Tyrant Detachment' AS FormationName, 'Hive Tyrant Detachment' AS DetachmentName
    UNION ALL SELECT 'Norn Queen Detachment' AS FormationName, 'Norn Queen Detachment' AS DetachmentName
    UNION ALL SELECT 'Trygon Detachment' AS FormationName, 'Trygon Detachment' AS DetachmentName
    UNION ALL SELECT 'Barbgaunt Detachment' AS FormationName, 'Barbgaunt Detachment' AS DetachmentName
    UNION ALL SELECT 'Hive Guard Detachment' AS FormationName, 'Hive Guard Detachment' AS DetachmentName
    UNION ALL SELECT 'Gargoyle Detachment' AS FormationName, 'Gargoyle Detachment' AS DetachmentName
    UNION ALL SELECT 'Genestealer Detachment' AS FormationName, 'Genestealer Detachment' AS DetachmentName
    UNION ALL SELECT 'Hormagaunt Detachment' AS FormationName, 'Hormagaunt Detachment' AS DetachmentName
    UNION ALL SELECT 'Lictor Detachment' AS FormationName, 'Lictor Detachment' AS DetachmentName
    UNION ALL SELECT 'Termagant Detachment' AS FormationName, 'Termagant Detachment' AS DetachmentName
    UNION ALL SELECT 'Ripper Detachment' AS FormationName, 'Ripper Detachment' AS DetachmentName
    UNION ALL SELECT 'Ravener Detachment' AS FormationName, 'Ravener Detachment' AS DetachmentName
    UNION ALL SELECT 'Carnifex Detachment' AS FormationName, 'Carnifex Detachment' AS DetachmentName
    UNION ALL SELECT 'Venomthrope Detachment' AS FormationName, 'Venomthrope Detachment' AS DetachmentName
    UNION ALL SELECT 'Zoanthrope Detachment' AS FormationName, 'Zoanthrope Detachment' AS DetachmentName
    UNION ALL SELECT 'Biovore Detachment' AS FormationName, 'Biovore Detachment' AS DetachmentName
    UNION ALL SELECT 'Dactylis Detachment' AS FormationName, 'Dactylis Detachment' AS DetachmentName
    UNION ALL SELECT 'Exocrine Detachment' AS FormationName, 'Exocrine Detachment' AS DetachmentName
    UNION ALL SELECT 'Harpy Detachment' AS FormationName, 'Harpy Detachment' AS DetachmentName
    UNION ALL SELECT 'Haruspex Detachment' AS FormationName, 'Haruspex Detachment' AS DetachmentName
    UNION ALL SELECT 'Pyrovore Detachment' AS FormationName, 'Pyrovore Detachment' AS DetachmentName
    UNION ALL SELECT 'Toxicrene Detachment' AS FormationName, 'Toxicrene Detachment' AS DetachmentName
    UNION ALL SELECT 'Virago Detachment' AS FormationName, 'Virago Detachment' AS DetachmentName
    UNION ALL SELECT 'Barbed Hierodule Detachment' AS FormationName, 'Barbed Hierodule Detachment' AS DetachmentName
    UNION ALL SELECT 'Scythed Hierodule Detachment' AS FormationName, 'Scythed Hierodule Detachment' AS DetachmentName
    UNION ALL SELECT 'Razorfex Detachment' AS FormationName, 'Razorfex Detachment' AS DetachmentName
    UNION ALL SELECT 'Assault Tyrannofex Detachment' AS FormationName, 'Assault Tyrannofex Detachment' AS DetachmentName
    UNION ALL SELECT 'Support Tyrannofex Detachment' AS FormationName, 'Support Tyrannofex Detachment' AS DetachmentName
    UNION ALL SELECT 'Alpha Hierodule Detachment' AS FormationName, 'Alpha Hierodule Detachment' AS DetachmentName
    UNION ALL SELECT 'Hierophant Detachment' AS FormationName, 'Hierophant Detachment' AS DetachmentName
    UNION ALL SELECT 'Malefactor Detachment' AS FormationName, 'Malefactor Detachment' AS DetachmentName
    UNION ALL SELECT 'Mycetic Spore Detachment' AS FormationName, 'Mycetic Spore Detachment' AS DetachmentName
    UNION ALL SELECT 'Tervigon Detachment' AS FormationName, 'Tervigon Detachment' AS DetachmentName
    UNION ALL SELECT 'Off-Table Artillery (Bio-Plasma)' AS FormationName, 'Off-Table Artillery (Bio-Plasma)' AS DetachmentName
    UNION ALL SELECT 'Off-Table Artillery (Spore-Mine)' AS FormationName, 'Off-Table Artillery (Spore-Mine)' AS DetachmentName
) AS src
INNER JOIN Formation f
    ON f.CodexId = @codexId AND f.FormationName = src.FormationName
INNER JOIN Detachment d
    ON d.CodexId = @codexId AND d.DetachmentName = src.DetachmentName;

INSERT INTO TitanWeapon (
    CodexId, WeaponName, PointsCost, Notes, IsAssault, LimitPerTitan
) VALUES
    (@codexId, 'Bio-Cannon', 75, 'Damage (+1).', 0, 0),
    (@codexId, 'Spore Pods', 50, 'Limited to one per Bio-Titan. Increases Close Defences to 4+.', 0, 1),
    (@codexId, 'Bile Spitter', 75, 'Choose Focused or Diffuse firing mode.', 0, 0),
    (@codexId, 'Spine Clusters', 75, 'Template (7.5 cm), Fires Twice.', 0, 0),
    (@codexId, 'Pyro-Acid Jet', 50, 'Flame Template, Reduces Cover (-3).', 0, 0),
    (@codexId, 'Razor Claws', 75, 'Assault weapon. Choose one effect.', 1, 0),
    (@codexId, 'Dart Salvo', 75, '', 0, 0),
    (@codexId, 'Tentacles', 50, 'Choose one effect.', 0, 0)
ON DUPLICATE KEY UPDATE
    PointsCost = VALUES(PointsCost),
    Notes = VALUES(Notes),
    IsAssault = VALUES(IsAssault),
    LimitPerTitan = VALUES(LimitPerTitan);

