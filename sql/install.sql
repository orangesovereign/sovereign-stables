-- =====================================================================
--  SOVEREIGN STABLES · DATABASE SCHEMA
--  Greenfield install (no vorp_stables migration). Import once.
--  Tables are prefixed `sovereign_` to avoid collisions with vorp_stables.
-- =====================================================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- Owned horses. `status`, `genetics`, `personality`, `metabolism`, `shoes`
-- are JSON blobs so we can grow feature state without schema churn.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sovereign_horses` (
  `id`             INT(11) NOT NULL AUTO_INCREMENT,
  `identifier`     VARCHAR(64)  NULL,                 -- owning player identifier
  `charid`         INT(11)      NOT NULL,             -- owning character id
  `faction`        VARCHAR(64)  NULL,                 -- job id if faction-owned [S16]
  `name`           VARCHAR(64)  NOT NULL DEFAULT 'Horse',   -- chosen by the buyer at purchase [N8]
  `sex`            VARCHAR(16)  NOT NULL DEFAULT 'Stallion', -- chosen at purchase; feeds breeding [N9]
  `model`          VARCHAR(96)  NOT NULL,             -- model/coat id (stock or community)
  `is_default`     TINYINT(1)   NOT NULL DEFAULT 0,
  `stable_origin`  VARCHAR(64)  NULL,                 -- stable id where stored [S7]
  `xp`             INT(11)      NOT NULL DEFAULT 0,
  `long_term_hp`   INT(11)      NOT NULL DEFAULT 100, -- hard-death pool
  `age`            INT(11)      NOT NULL DEFAULT 0,   -- in-game age units [E6]
  `birth_ts`       BIGINT       NULL,
  `bonding`        INT(11)      NOT NULL DEFAULT 0,   -- [E3]
  `courage`        INT(11)      NOT NULL DEFAULT 0,   -- [E4]
  `status`         LONGTEXT     NULL,                 -- core stat overlay (JSON)
  `metabolism`     LONGTEXT     NULL,                 -- hunger/thirst/clean (JSON) [C]
  `genetics`       LONGTEXT     NULL,                 -- inheritance traits (JSON) [G]
  `personality`    LONGTEXT     NULL,                 -- traits/behavior (JSON) [E5]
  `shoes`          LONGTEXT     NULL,                 -- horseshoe level/state (JSON) [S12]
  `components`     LONGTEXT     NULL,                 -- applied appearance/tack (JSON) [F]
  `inventory`      VARCHAR(96)  NULL,                 -- vorp_inventory id reference
  `created_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_charid` (`charid`),
  KEY `idx_faction` (`faction`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

-- ---------------------------------------------------------------------
-- Owned wagons / carts.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sovereign_wagons` (
  `id`             INT(11) NOT NULL AUTO_INCREMENT,
  `identifier`     VARCHAR(64)  NULL,
  `charid`         INT(11)      NOT NULL,
  `name`           VARCHAR(64)  NOT NULL DEFAULT 'Wagon',
  `model`          VARCHAR(96)  NOT NULL,
  `is_default`     TINYINT(1)   NOT NULL DEFAULT 0,
  `stable_origin`  VARCHAR(64)  NULL,
  `health`         INT(11)      NOT NULL DEFAULT 100,  -- persistent health, 0-100 [WG9]
  `tint`           VARCHAR(32)  NULL,                  -- livery/color [WG4]
  `wheels`         LONGTEXT     NULL,                  -- wheel-damage state (JSON) [WG11]
  `components`     LONGTEXT     NULL,
  `inventory`      VARCHAR(96)  NULL,
  `created_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_charid` (`charid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

-- ---------------------------------------------------------------------
-- Owned TACK. [F1/F5 · owner ruling 2026-07-15]
--   Tack belongs to the PLAYER, not the horse: buy once, use it on any horse
--   you own. So this table keys on `charid` — never on a horse id.
--   `sovereign_horses.components` is the separate question of what is currently
--   APPLIED to a given horse; this is what you OWN and may apply.
--
--   The UNIQUE key enforces the ruling "never re-buy what you own" in the
--   database itself, so no code path can charge twice for the same piece.
--   It is also why a dead horse's tack survives: the horse row goes, this
--   doesn't. (Cargo is lost with the horse — that lives in the inventory.)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sovereign_tack` (
  `id`          INT(11) NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(64)  NULL,
  `charid`      INT(11)      NOT NULL,
  `category`    VARCHAR(32)  NOT NULL,   -- saddle/saddlebags/mane/tail... (Config.TackCategories)
  `item`        VARCHAR(64)  NOT NULL,   -- catalog item id (Config.Tack[category][item])
  `acquired_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_char_item` (`charid`, `item`),
  KEY `idx_charid` (`charid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

-- ---------------------------------------------------------------------
-- Breeding lineage (parentage) for the genetics system. [G]
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sovereign_lineage` (
  `horse_id`  INT(11) NOT NULL,
  `sire_id`   INT(11) NULL,
  `dam_id`    INT(11) NULL,
  PRIMARY KEY (`horse_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- Black-market / wild-sale cooldown timers. [S10/W5]
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sovereign_cooldowns` (
  `charid`     INT(11)     NOT NULL,
  `kind`       VARCHAR(32) NOT NULL,   -- e.g. 'blackmarket'
  `expires_at` BIGINT      NOT NULL,
  PRIMARY KEY (`charid`, `kind`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------
-- Economy audit log / anti-dupe trail. [X2]
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sovereign_ledger` (
  `id`         INT(11) NOT NULL AUTO_INCREMENT,
  `charid`     INT(11)      NOT NULL,
  `action`     VARCHAR(48)  NOT NULL,   -- buy_horse / sell_horse / transfer / blackmarket ...
  `subject`    VARCHAR(96)  NULL,       -- horse/wagon id or model
  `cash`       DECIMAL(12,2) NOT NULL DEFAULT 0,
  `gold`       DECIMAL(12,2) NOT NULL DEFAULT 0,
  `meta`       LONGTEXT     NULL,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_charid` (`charid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

-- ---------------------------------------------------------------------
-- STABLE BUSINESS — native ownership + funds per stable (owner ruling
-- 2026-07-31: the management panel's business layer lives HERE, not in
-- sovereign_stores). One row per OWNED stable; `stable_id` is the
-- config/stables.lua key. Unowned stables (no row) are admin-run.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sovereign_stable_business` (
  `stable_id`    VARCHAR(48)   NOT NULL,   -- config/stables.lua key, e.g. 'valentine'
  `owner_charid` INT(11)       NULL,       -- current owner (NULL = unowned/admin-run)
  `name`         VARCHAR(64)   NULL,       -- business name (defaults to the stable label)
  `status`       VARCHAR(16)   NOT NULL DEFAULT 'open',   -- open / closed / suspended
  `funds_cash`   DECIMAL(12,2) NOT NULL DEFAULT 0,        -- the society funds
  `funds_gold`   DECIMAL(12,2) NOT NULL DEFAULT 0,
  `tax_due`      DECIMAL(12,2) NOT NULL DEFAULT 0,
  `tax_due_at`   BIGINT        NULL,
  `created_at`   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`stable_id`),
  KEY `idx_owner` (`owner_charid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

-- ---------------------------------------------------------------------
-- STABLE EMPLOYEES — roster + role + grade + duty. The owner is on the
-- business row above; this is staff (trainer / stablehand). `role` maps to a
-- permission set in config; `grade` is the rank shown in the panel.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sovereign_stable_employees` (
  `id`          INT(11)     NOT NULL AUTO_INCREMENT,
  `stable_id`   VARCHAR(48) NOT NULL,
  `charid`      INT(11)     NOT NULL,
  `name`        VARCHAR(64) NULL,          -- cached display name
  `role`        VARCHAR(24) NOT NULL DEFAULT 'stablehand',  -- trainer / stablehand
  `grade`       INT(11)     NOT NULL DEFAULT 1,
  `on_duty`     TINYINT(1)  NOT NULL DEFAULT 0,
  `hired_at`    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_active` TIMESTAMP   NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_stable_char` (`stable_id`, `charid`),
  KEY `idx_stable` (`stable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

-- ---------------------------------------------------------------------
-- STABLE LEDGER — the society ledger (income, expenses, tax, deposits).
-- Every money movement in the business writes one row; the panel reads it.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sovereign_stable_ledger` (
  `id`            INT(11)       NOT NULL AUTO_INCREMENT,
  `stable_id`     VARCHAR(48)   NOT NULL,
  `description`   VARCHAR(96)   NOT NULL,
  `category`      VARCHAR(24)   NOT NULL,   -- service/supplies/payroll/breeding/deposit/tax
  `actor_charid`  INT(11)       NULL,       -- who caused it (NULL = system)
  `actor_name`    VARCHAR(64)   NULL,
  `amount_cash`   DECIMAL(12,2) NOT NULL DEFAULT 0,   -- signed (+in / -out)
  `amount_gold`   DECIMAL(12,2) NOT NULL DEFAULT 0,
  `balance_after` DECIMAL(12,2) NULL,
  `created_at`    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_stable_time` (`stable_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

SET FOREIGN_KEY_CHECKS = 1;
