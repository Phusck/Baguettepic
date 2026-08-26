-- Titan weapons are catalog purchases attached to each titan instance,
-- not standalone Option formations.

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS TitanWeapon (
    TitanWeaponId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    CodexId INT UNSIGNED NOT NULL,
    WeaponName VARCHAR(128) NOT NULL,
    PointsCost INT NOT NULL,
    Notes VARCHAR(256) NOT NULL DEFAULT '',
    IsAssault TINYINT(1) NOT NULL DEFAULT 0,
    LimitPerTitan TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (TitanWeaponId),
    UNIQUE KEY UQ_TitanWeapon_Codex_Name (CodexId, WeaponName),
    KEY IX_TitanWeapon_Codex (CodexId),
    CONSTRAINT FK_TitanWeapon_Codex
        FOREIGN KEY (CodexId) REFERENCES Codex (CodexId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @codexId := (SELECT CodexId FROM Codex WHERE CodexName = 'Tyranids');

DELETE af FROM ArmyFormation af
INNER JOIN Formation f ON f.FormationId = af.FormationId
WHERE f.CodexId = @codexId
  AND f.FormationName IN (
      'Bio-Cannon', 'Spore Pods', 'Bile Spitter', 'Spine Clusters',
      'Pyro-Acid Jet', 'Razor Claws', 'Dart Salvo', 'Tentacles'
  );

DELETE FROM Formation
WHERE CodexId = @codexId
  AND FormationName IN (
      'Bio-Cannon', 'Spore Pods', 'Bile Spitter', 'Spine Clusters',
      'Pyro-Acid Jet', 'Razor Claws', 'Dart Salvo', 'Tentacles'
  )
  AND NOT EXISTS (
      SELECT 1 FROM FormationDetachment fd WHERE fd.FormationId = Formation.FormationId
  );

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
