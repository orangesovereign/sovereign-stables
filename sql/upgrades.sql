-- =====================================================================
--  SOVEREIGN STABLES · UPGRADES
--  Run these ONLY if you already imported an older sql/install.sql and
--  don't want to drop your tables. A fresh install.sql already includes
--  everything here. Each block is dated and safe to run once.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 2026-07-14 · horse gender chosen at purchase [N9]
-- Adds the `sex` column to existing sovereign_horses tables.
-- If it errors with "Duplicate column name 'sex'", you already have it — ignore.
-- ---------------------------------------------------------------------
ALTER TABLE `sovereign_horses`
  ADD COLUMN `sex` VARCHAR(16) NOT NULL DEFAULT 'Stallion' AFTER `name`;

-- ---------------------------------------------------------------------
-- 2026-07-15 · milestone 1.4 — owned tack [F1/F5]
-- Tack belongs to the PLAYER, not the horse, so it needs its own table.
-- Safe to run on an existing database: it only ADDS a table and touches
-- nothing you already have. `IF NOT EXISTS` means running it twice is fine.
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
