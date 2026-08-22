# Baguettepic database ER diagram

Entity-relationship diagram for the `baguettepic` schema defined in [`schema.sql`](./schema.sql).

![Schema ER diagram](./schema-erd.png)

Editable Mermaid source (also rendered below on GitHub):

```mermaid
erDiagram
    Codex ||--o{ Formation : contains
    Codex ||--o{ SpecialRule : defines
    Codex ||--o{ Army : has
    FormationKind ||--o{ Formation : classifies
    Formation ||--o{ Weapon : equips
    Formation ||--o{ FormationComposition : "parent of"
    Formation ||--o{ FormationComposition : "unit in"
    Formation ||--o{ FormationSpecialAbility : has
    Formation ||--o{ ArmyFormation : selectedIn
    SpecialAbility ||--o{ FormationSpecialAbility : appliedTo
    SpecialAbility ||--o{ WeaponSpecialAbility : appliedTo
    Weapon ||--o{ WeaponSpecialAbility : has
    Army ||--o{ ArmyFormation : includes

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
        int Morale
        int Class
        int Movement
        varchar Save
        int FA
        int NumberOfTitanWeapons
    }

    FormationComposition {
        int FormationId PK_FK
        int UnitFormationId PK_FK
        int BaseCount
    }

    Weapon {
        int WeaponId PK
        int FormationId FK
        varchar Name
        varchar Range
        int Dice
        varchar ToHit
        int ArmourPenetration
        int FiringArc
        tinyint IsTitanWeapon
    }

    SpecialAbility {
        int SpecialAbilityId PK
        varchar SpecialAbilityName UK
        text Description
    }

    FormationSpecialAbility {
        int FormationId PK_FK
        int SpecialAbilityId PK_FK
    }

    WeaponSpecialAbility {
        int WeaponId PK_FK
        int SpecialAbilityId PK_FK
    }

    SpecialRule {
        int SpecialRuleId PK
        int CodexId FK
        varchar SpecialRuleName
        text Description
    }

    Rule {
        int RuleId PK
        varchar RuleName UK
        text Description
    }

    Army {
        int ArmyId PK
        int CodexId FK
        varchar ArmyName UK
        int PointsLimit
        text Notes
    }

    ArmyFormation {
        int ArmyId PK_FK
        int FormationId PK_FK
        int Quantity
    }
```

## Entity summary

| Table | Role |
| --- | --- |
| `Codex` | Faction / army book (e.g. Tyranids) |
| `FormationKind` | Lookup for formation category (Mandatory, Company, Special, Support, Option, Limited) |
| `Formation` | Unit profile or detachment definition |
| `FormationComposition` | Which unit formations make up a detachment (`BaseCount`) |
| `Weapon` | Weapons belonging to a formation |
| `SpecialAbility` | Shared ability definitions |
| `FormationSpecialAbility` | Many-to-many: formations ↔ abilities |
| `WeaponSpecialAbility` | Many-to-many: weapons ↔ abilities |
| `SpecialRule` | Codex-scoped special rules |
| `Rule` | Standalone rules (no FK relationships yet) |
| `Army` | Player army list under a codex |
| `ArmyFormation` | Many-to-many: army ↔ formations with `Quantity` |

## Cardinality notes

- A **Codex** owns many **Formations**, **SpecialRules**, and **Armies**.
- A **Formation** may contain other formations via **FormationComposition** (self-referencing parent/unit pair).
- **SpecialAbility** is reused by both formations and weapons through junction tables.
- **Rule** is present in the schema but currently unlinked to other tables.
