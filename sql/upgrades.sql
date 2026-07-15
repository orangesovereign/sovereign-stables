-- =====================================================================
--  SOVEREIGN STABLES · UPGRADES
--  ---------------------------------------------------------------------
--  Run this if you already imported an older sql/install.sql and don't
--  want to drop your tables. A fresh install.sql already includes
--  everything here.
--
--  SAFE TO PASTE WHOLE, AND SAFE TO RUN AGAIN.
--  Every block below checks first and does nothing if it's already done.
--  You should see a row of "already present" / "added" messages and NO
--  errors. If you see an error, something is genuinely wrong — send it.
--
--  (Older versions of this file failed here: the first statement threw
--  "Duplicate column name 'sex'" on a second run, and most MySQL tools
--  stop the whole script at the first error — so everything after it was
--  silently skipped. That's fixed; nothing below can throw that way.)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 2026-07-15 · milestone 1.4 — owned tack [F1/F5]
-- Tack belongs to the PLAYER, not the horse, so it needs its own table.
-- Only ADDS a table; touches nothing you already have.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sovereign_tack` (
  `id`          INT(11) NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(64)  NULL,
  `charid`      INT(11)      NOT NULL,
  `category`    VARCHAR(32)  NOT NULL,
  `item`        VARCHAR(64)  NOT NULL,
  `acquired_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_char_item` (`charid`, `item`),
  KEY `idx_charid` (`charid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

SELECT 'sovereign_tack — table ready' AS `1.4 tack`;

-- ---------------------------------------------------------------------
-- 2026-07-14 · horse gender chosen at purchase [N9]
-- Adds the `sex` column to sovereign_horses, but ONLY if it isn't there.
-- ---------------------------------------------------------------------
SET @has_sex := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'sovereign_horses'
    AND COLUMN_NAME  = 'sex'
);
SET @sql := IF(@has_sex = 0,
  'ALTER TABLE `sovereign_horses` ADD COLUMN `sex` VARCHAR(16) NOT NULL DEFAULT ''Stallion'' AFTER `name`',
  'SELECT ''sovereign_horses.sex — already present, nothing to do'' AS `1.2b gender`'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- =====================================================================
--  VERIFY — the whole point. Read the output of this last query.
--  Both lines must say YES. If either says NO, tell Claude which one.
-- =====================================================================
SELECT
  'sovereign_tack table exists' AS `check`,
  IF((SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sovereign_tack') > 0, 'YES', 'NO') AS `result`
UNION ALL
SELECT
  'sovereign_horses.sex column exists',
  IF((SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sovereign_horses'
        AND COLUMN_NAME = 'sex') > 0, 'YES', 'NO');
