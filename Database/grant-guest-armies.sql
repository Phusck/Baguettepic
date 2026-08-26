-- Allow Guest to save army lists. Codex/rules remain read-only.
-- Catalog SELECT is listed for table-scoped Guest accounts. App logins
-- live in AppUser; Guest cannot read that table, so user admin work uses
-- the Admin MySQL account. A user with GRANT privilege must apply this
-- file; Admin cannot.
GRANT SELECT ON baguettepic.`Base` TO 'Guest'@'%';
GRANT SELECT ON baguettepic.Detachment TO 'Guest'@'%';
GRANT SELECT ON baguettepic.DetachmentComposition TO 'Guest'@'%';
GRANT SELECT ON baguettepic.Formation TO 'Guest'@'%';
GRANT SELECT ON baguettepic.FormationDetachment TO 'Guest'@'%';
GRANT SELECT ON baguettepic.FormationKind TO 'Guest'@'%';
GRANT SELECT ON baguettepic.BaseSpecialAbility TO 'Guest'@'%';
GRANT SELECT ON baguettepic.TitanWeapon TO 'Guest'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON baguettepic.Army TO 'Guest'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON baguettepic.ArmyFormation TO 'Guest'@'%';
FLUSH PRIVILEGES;
