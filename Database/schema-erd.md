# Baguettepic database ER diagram

Entity-relationship diagram for the `baguettepic` schema defined in [`schema.sql`](./schema.sql).

![Schema ER diagram](./schema-erd.png)

Editable Mermaid source (also rendered below on GitHub):

```mermaid
erDiagram
    Codex ||--o{ Formation : contains
    Codex ||--o{ Detachment : contains
    Codex ||--o{ Base : contains
    Codex ||--o{ SpecialRule : defines
    Codex ||--o{ Army : has
    AppUser ||--o{ Army : owns
    FormationKind ||--o{ Formation : classifies
    Formation ||--o{ FormationDetachment : includes
    Detachment ||--o{ FormationDetachment : usedIn
    Detachment ||--o{ DetachmentComposition : contains
    Base ||--o{ DetachmentComposition : "base in"
    Base ||--o{ Weapon : equips
    Base ||--o{ BaseSpecialAbility : has
    SpecialAbility ||--o{ BaseSpecialAbility : appliedTo
    SpecialAbility ||--o{ WeaponSpecialAbility : appliedTo
    Weapon ||--o{ WeaponSpecialAbility : has
    Base ||--o{ BasePsychicPower : has
    PsychicPower ||--o{ BasePsychicPower : appliedTo
    Army ||--o{ ArmyFormation : includes
    Formation ||--o{ ArmyFormation : selectedIn
    Codex ||--o{ TitanWeapon : catalogs

    Codex {
        int CodexId PK
        varchar CodexName UK
    }

    FormationKind {
        tinyint FormationKindId PK
        varchar KindName UK
    }

    Formation {
        int FormationId PK
        int CodexId FK
        tinyint FormationKindId FK
        varchar FormationName
        int PointsCost
        int CommandPoints
        varchar Contents
        int DestructionPoints
    }

    Detachment {
        int DetachmentId PK
        int CodexId FK
        varchar DetachmentName
        int CommandPoints
        int Class
    }

    FormationDetachment {
        int FormationId PK_FK
        int DetachmentId PK_FK
        int Quantity
    }

    Base {
        int BaseId PK
        int CodexId FK
        varchar BaseName
        blob Image
        int DestructionPoints
        int Morale
        int Class
        int Movement
        varchar Save
        int FA
        int NumberOfTitanWeapons
    }

    DetachmentComposition {
        int DetachmentId PK_FK
        int BaseId PK_FK
        int BaseCount
    }

    Weapon {
        int WeaponId PK
        int BaseId FK
        varchar Name
        varchar Range
        int Dice
        varchar ToHit
        int ArmourPenetration
        tinyint IsTitanWeapon
    }

    SpecialAbility {
        int SpecialAbilityId PK
        varchar SpecialAbilityName UK
        text Description
    }

    BaseSpecialAbility {
        int BaseId PK_FK
        int SpecialAbilityId PK_FK
    }

    WeaponSpecialAbility {
        int WeaponId PK_FK
        int SpecialAbilityId PK_FK
    }

    PsychicPower {
        int PsychicPowerId PK
        varchar PsychicPowerName UK
        text Description
    }

    BasePsychicPower {
        int BaseId PK_FK
        int PsychicPowerId PK_FK
        varchar AbilityValue
    }

    SpecialRule {
        int SpecialRuleId PK
        int CodexId FK
        varchar SpecialRuleName UK
        text Description
    }

    Rule {
        int RuleId PK
        varchar RuleName UK
        text Description
    }

    AppUser {
        int UserId PK
        varchar Username UK
        varchar PasswordHash
        tinyint IsAdmin
        tinyint MustChangePassword
    }

    Army {
        int ArmyId PK
        int UserId FK
        int CodexId FK
        varchar ArmyName
        int PointsLimit
    }

    ArmyFormation {
        int ArmyId PK_FK
        int FormationId PK_FK
        int Quantity
        json TitanWeapons
    }

    TitanWeapon {
        int TitanWeaponId PK
        int CodexId FK
        varchar WeaponName UK
        int PointsCost
        varchar Notes
        tinyint IsAssault
        tinyint LimitPerTitan
    }
```

## Entity summary

| Table | Role |
| --- | --- |
| `Codex` | Faction / army book (e.g. Tyranids) |
| `FormationKind` | Lookup for formation category (Mandatory, Company, Special, Support, Option, Limited) |
| `Formation` | Purchasable army-list card. The army builder buys these. |
| `FormationDetachment` | Which detachments a formation contains (`Quantity`) |
| `Detachment` | Table-top group of bases |
| `DetachmentComposition` | Which bases make up a detachment (`BaseCount`) |
| `Base` | Unit profile (stats, weapons, abilities, optional image path) |
| `Weapon` | Weapons belonging to a base |
| `SpecialAbility` | Shared ability definitions |
| `BaseSpecialAbility` | Many-to-many: bases ↔ abilities |
| `WeaponSpecialAbility` | Many-to-many: weapons ↔ abilities |
| `PsychicPower` | Shared psychic power definitions |
| `BasePsychicPower` | Many-to-many: bases ↔ psychic powers |
| `SpecialRule` | Codex-scoped special rules |
| `Rule` | Standalone rules (no FK relationships yet) |
| `AppUser` | App login account. Owns army lists. |
| `Army` | Player army list under a user and a codex |
| `ArmyFormation` | Many-to-many: army ↔ formations with `Quantity` and chosen titan weapons |
| `TitanWeapon` | Codex catalog of purchasable titan weapons |

## Cardinality notes

- A **Codex** owns many **Formations**, **Detachments**, **Bases**, **SpecialRules**, and **Armies**.
- An **AppUser** owns many **Armies**. An **Army** buys **Formations**. A **Formation** holds one or more **Detachments**. A **Detachment** holds one or more **Bases**.
- **TitanWeapon** is a shared catalog. Chosen weapons for a titan are stored on that army list’s `ArmyFormation.TitanWeapons` JSON.
- **SpecialAbility** is reused by both bases and weapons through junction tables.
- **PsychicPower** is linked only to bases through `BasePsychicPower` (shown on unit detail).
- **Rule** is present in the schema but currently unlinked to other tables.
