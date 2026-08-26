-- App users own army lists.
-- Run apply_app_users.py to seed Admin and attach Army.UserId.

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS AppUser (
    UserId INT UNSIGNED NOT NULL AUTO_INCREMENT,
    Username VARCHAR(64) NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    IsAdmin TINYINT(1) NOT NULL DEFAULT 0,
    MustChangePassword TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (UserId),
    UNIQUE KEY UQ_AppUser_Username (Username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
