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
