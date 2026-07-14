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
  `name`           VARCHAR(64)  NOT NULL DEFAULT 'Horse',
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
  `health`         INT(11)      NOT NULL DEFAULT 1000, -- persistent health [WG9]
  `tint`           VARCHAR(32)  NULL,                  -- livery/color [WG4]
  `wheels`         LONGTEXT     NULL,                  -- wheel-damage state (JSON) [WG11]
  `components`     LONGTEXT     NULL,
  `inventory`      VARCHAR(96)  NULL,
  `created_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
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

SET FOREIGN_KEY_CHECKS = 1;
