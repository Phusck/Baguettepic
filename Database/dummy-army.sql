-- Dummy Tyranid army buying support formations that already have unit profiles.
-- Synapse cards are not in the Codex yet, so this list cannot generate Command Points.

SET NAMES utf8mb4;

SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Tyranids');

INSERT INTO Army (CodexId, ArmyName, PointsLimit, Notes)
SELECT @codexId, 'Dummy Swarm', 3000,
       'Test list built from every Slave formation that already has a unit profile. Synapse formations are not in the Codex yet, so this swarm spends Command Points and generates none.'
WHERE NOT EXISTS (SELECT 1 FROM Army WHERE ArmyName = 'Dummy Swarm');

SET @armyId := (SELECT ArmyId FROM Army WHERE ArmyName = 'Dummy Swarm');

DELETE FROM ArmyFormation WHERE ArmyId = @armyId;

INSERT INTO ArmyFormation (ArmyId, FormationId, Quantity)
SELECT @armyId, f.FormationId, 1
FROM Formation f
WHERE f.CodexId = @codexId
  AND f.FormationName IN (
    'Barbgaunt Detachment',
    'Hive Guard Detachment',
    'Gargoyle Detachment',
    'Genestealer Detachment',
    'Hormagaunt Detachment',
    'Lictor Detachment',
    'Termagant Detachment',
    'Ripper Detachment',
    'Ravener Detachment'
  );
