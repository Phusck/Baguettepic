-- Baguettepic schema from Palladium Epic class-diagram.md
-- Database: baguettepic
--
-- Hierarchy: Army buys Formations. A Formation holds Detachments.
-- A Detachment holds Bases (unit profiles).

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS ArmyFormation;
DROP TABLE IF EXISTS FormationDetachment;
DROP TABLE IF EXISTS DetachmentComposition;
DROP TABLE IF EXISTS WeaponSpecialAbility;
DROP TABLE IF EXISTS BaseSpecialAbility;
DROP TABLE IF EXISTS Weapon;
DROP TABLE IF EXISTS SpecialRule;
DROP TABLE IF EXISTS Army;
DROP TABLE IF EXISTS Formation;
DROP TABLE IF EXISTS Detachment;
DROP TABLE IF EXISTS `Base`;
DROP TABLE IF EXISTS SpecialAbility;
DROP TABLE IF EXISTS Rule;
DROP TABLE IF EXISTS FormationKind;
DROP TABLE IF EXISTS Codex;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Codex (
    CodexId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    CodexName VARCHAR(128) NOT NULL,
    PRIMARY KEY (CodexId),
    UNIQUE KEY UQ_Codex_Name (CodexName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE FormationKind (
    FormationKindId TINYINT UNSIGNED NOT NULL,
    KindName VARCHAR(32) NOT NULL,
    PRIMARY KEY (FormationKindId),
    UNIQUE KEY UQ_FormationKind_Name (KindName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO FormationKind (FormationKindId, KindName) VALUES
    (1, 'Mandatory'),
    (2, 'Company'),
    (3, 'Special'),
    (4, 'Support'),
    (5, 'Option'),
    (6, 'Limited');

CREATE TABLE `Base` (
    BaseId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    CodexId INT UNSIGNED NOT NULL,
    BaseName VARCHAR(128) NOT NULL,
    ImagePath VARCHAR(512) NOT NULL DEFAULT '',
    DestructionPoints INT NOT NULL DEFAULT 0,
    Morale INT NOT NULL,
    `Class` INT NOT NULL,
    Movement INT NOT NULL,
    `Save` VARCHAR(16) NOT NULL,
    FA INT NOT NULL,
    NumberOfTitanWeapons INT NOT NULL DEFAULT 0,
    PRIMARY KEY (BaseId),
    UNIQUE KEY UQ_Base_Codex_Name (CodexId, BaseName),
    KEY IX_Base_Codex (CodexId),
    CONSTRAINT FK_Base_Codex
        FOREIGN KEY (CodexId) REFERENCES Codex (CodexId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Detachment (
    DetachmentId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    CodexId INT UNSIGNED NOT NULL,
    DetachmentName VARCHAR(128) NOT NULL,
    CommandPoints INT NOT NULL DEFAULT 0,
    `Class` INT NOT NULL,
    PRIMARY KEY (DetachmentId),
    UNIQUE KEY UQ_Detachment_Codex_Name (CodexId, DetachmentName),
    KEY IX_Detachment_Codex (CodexId),
    CONSTRAINT FK_Detachment_Codex
        FOREIGN KEY (CodexId) REFERENCES Codex (CodexId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE DetachmentComposition (
    DetachmentId INT UNSIGNED NOT NULL,
    BaseId INT UNSIGNED NOT NULL,
    BaseCount INT UNSIGNED NOT NULL,
    PRIMARY KEY (DetachmentId, BaseId),
    KEY IX_DC_Base (BaseId),
    CONSTRAINT FK_DC_Detachment
        FOREIGN KEY (DetachmentId) REFERENCES Detachment (DetachmentId)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_DC_Base
        FOREIGN KEY (BaseId) REFERENCES `Base` (BaseId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Formation (
    FormationId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    CodexId INT UNSIGNED NOT NULL,
    FormationKindId TINYINT UNSIGNED NOT NULL,
    FormationName VARCHAR(128) NOT NULL,
    PointsCost INT NOT NULL,
    CommandPoints INT NOT NULL DEFAULT 0,
    Contents VARCHAR(256) NOT NULL DEFAULT '',
    DestructionPoints INT NOT NULL DEFAULT 0,
    PRIMARY KEY (FormationId),
    UNIQUE KEY UQ_Formation_Codex_Name (CodexId, FormationName),
    KEY IX_Formation_Codex (CodexId),
    KEY IX_Formation_Kind (FormationKindId),
    CONSTRAINT FK_Formation_Codex
        FOREIGN KEY (CodexId) REFERENCES Codex (CodexId)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_Formation_Kind
        FOREIGN KEY (FormationKindId) REFERENCES FormationKind (FormationKindId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE FormationDetachment (
    FormationId INT UNSIGNED NOT NULL,
    DetachmentId INT UNSIGNED NOT NULL,
    Quantity INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (FormationId, DetachmentId),
    KEY IX_FD_Detachment (DetachmentId),
    CONSTRAINT FK_FD_Formation
        FOREIGN KEY (FormationId) REFERENCES Formation (FormationId)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_FD_Detachment
        FOREIGN KEY (DetachmentId) REFERENCES Detachment (DetachmentId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Weapon (
    WeaponId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    BaseId INT UNSIGNED NOT NULL,
    `Name` VARCHAR(128) NOT NULL,
    `Range` VARCHAR(32) NOT NULL,
    Dice INT NOT NULL,
    ToHit VARCHAR(16) NOT NULL,
    ArmourPenetration INT NOT NULL,
    FiringArc INT NOT NULL,
    IsTitanWeapon TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (WeaponId),
    KEY IX_Weapon_Base (BaseId),
    CONSTRAINT FK_Weapon_Base
        FOREIGN KEY (BaseId) REFERENCES `Base` (BaseId)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE SpecialAbility (
    SpecialAbilityId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    SpecialAbilityName VARCHAR(128) NOT NULL,
    Description TEXT NOT NULL,
    PRIMARY KEY (SpecialAbilityId),
    UNIQUE KEY UQ_SpecialAbility_Name (SpecialAbilityName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE BaseSpecialAbility (
    BaseId INT UNSIGNED NOT NULL,
    SpecialAbilityId INT UNSIGNED NOT NULL,
    PRIMARY KEY (BaseId, SpecialAbilityId),
    KEY IX_BSA_Ability (SpecialAbilityId),
    CONSTRAINT FK_BSA_Base
        FOREIGN KEY (BaseId) REFERENCES `Base` (BaseId)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_BSA_Ability
        FOREIGN KEY (SpecialAbilityId) REFERENCES SpecialAbility (SpecialAbilityId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE WeaponSpecialAbility (
    WeaponId INT UNSIGNED NOT NULL,
    SpecialAbilityId INT UNSIGNED NOT NULL,
    PRIMARY KEY (WeaponId, SpecialAbilityId),
    KEY IX_WSA_Ability (SpecialAbilityId),
    CONSTRAINT FK_WSA_Weapon
        FOREIGN KEY (WeaponId) REFERENCES Weapon (WeaponId)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_WSA_Ability
        FOREIGN KEY (SpecialAbilityId) REFERENCES SpecialAbility (SpecialAbilityId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE SpecialRule (
    SpecialRuleId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    CodexId INT UNSIGNED NOT NULL,
    SpecialRuleName VARCHAR(128) NOT NULL,
    Description TEXT NOT NULL,
    PRIMARY KEY (SpecialRuleId),
    UNIQUE KEY UQ_SpecialRule_Codex_Name (CodexId, SpecialRuleName),
    KEY IX_SpecialRule_Codex (CodexId),
    CONSTRAINT FK_SpecialRule_Codex
        FOREIGN KEY (CodexId) REFERENCES Codex (CodexId)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Present on the class diagram with no relationships yet.
CREATE TABLE Rule (
    RuleId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    RuleName VARCHAR(128) NOT NULL,
    Description TEXT NOT NULL,
    PRIMARY KEY (RuleId),
    UNIQUE KEY UQ_Rule_Name (RuleName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Army (
    ArmyId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    CodexId INT UNSIGNED NOT NULL,
    ArmyName VARCHAR(128) NOT NULL,
    PointsLimit INT NOT NULL DEFAULT 4000,
    Notes TEXT NOT NULL,
    PRIMARY KEY (ArmyId),
    UNIQUE KEY UQ_Army_Name (ArmyName),
    KEY IX_Army_Codex (CodexId),
    CONSTRAINT FK_Army_Codex
        FOREIGN KEY (CodexId) REFERENCES Codex (CodexId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE ArmyFormation (
    ArmyId INT UNSIGNED NOT NULL,
    FormationId INT UNSIGNED NOT NULL,
    Quantity INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (ArmyId, FormationId),
    KEY IX_AF_Formation (FormationId),
    CONSTRAINT FK_AF_Army
        FOREIGN KEY (ArmyId) REFERENCES Army (ArmyId)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_AF_Formation
        FOREIGN KEY (FormationId) REFERENCES Formation (FormationId)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
