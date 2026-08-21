-- Allow Guest to save army lists. Codex/rules remain read-only.
GRANT SELECT, INSERT, UPDATE, DELETE ON baguettepic.Army TO 'Guest'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON baguettepic.ArmyFormation TO 'Guest'@'%';
FLUSH PRIVILEGES;
