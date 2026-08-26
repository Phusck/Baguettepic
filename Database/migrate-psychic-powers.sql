-- Move unit psychic powers out of SpecialAbility into their own catalog.
-- Powers: Bio-Resistance, Psychic Scream, Psychic Projectile, Warp Field, Energy Torrent.
-- Psyker / Psychic Save / Psychic Attack / Psychic Abomination stay as SpecialAbility.

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS PsychicPower (
    PsychicPowerId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    PsychicPowerName VARCHAR(128) NOT NULL,
    Description TEXT NOT NULL,
    PRIMARY KEY (PsychicPowerId),
    UNIQUE KEY UQ_PsychicPower_Name (PsychicPowerName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS BasePsychicPower (
    BaseId INT UNSIGNED NOT NULL,
    PsychicPowerId INT UNSIGNED NOT NULL,
    AbilityValue VARCHAR(64) NOT NULL DEFAULT '',
    PRIMARY KEY (BaseId, PsychicPowerId),
    KEY IX_BPP_Power (PsychicPowerId),
    CONSTRAINT FK_BPP_Base
        FOREIGN KEY (BaseId) REFERENCES `Base` (BaseId)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_BPP_Power
        FOREIGN KEY (PsychicPowerId) REFERENCES PsychicPower (PsychicPowerId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO PsychicPower (PsychicPowerName, Description)
SELECT sa.SpecialAbilityName, sa.Description
FROM SpecialAbility sa
WHERE sa.SpecialAbilityName IN (
    'Bio-Resistance',
    'Psychic Scream',
    'Psychic Projectile',
    'Warp Field',
    'Energy Torrent'
)
AND NOT EXISTS (
    SELECT 1 FROM PsychicPower pp WHERE pp.PsychicPowerName = sa.SpecialAbilityName
);

INSERT INTO BasePsychicPower (BaseId, PsychicPowerId, AbilityValue)
SELECT bsa.BaseId, pp.PsychicPowerId, bsa.AbilityValue
FROM BaseSpecialAbility bsa
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = bsa.SpecialAbilityId
INNER JOIN PsychicPower pp ON pp.PsychicPowerName = sa.SpecialAbilityName
WHERE sa.SpecialAbilityName IN (
    'Bio-Resistance',
    'Psychic Scream',
    'Psychic Projectile',
    'Warp Field',
    'Energy Torrent'
)
ON DUPLICATE KEY UPDATE AbilityValue = VALUES(AbilityValue);

DELETE bsa FROM BaseSpecialAbility bsa
INNER JOIN SpecialAbility sa ON sa.SpecialAbilityId = bsa.SpecialAbilityId
WHERE sa.SpecialAbilityName IN (
    'Bio-Resistance',
    'Psychic Scream',
    'Psychic Projectile',
    'Warp Field',
    'Energy Torrent'
);

DELETE FROM SpecialAbility
WHERE SpecialAbilityName IN (
    'Bio-Resistance',
    'Psychic Scream',
    'Psychic Projectile',
    'Warp Field',
    'Energy Torrent'
);
