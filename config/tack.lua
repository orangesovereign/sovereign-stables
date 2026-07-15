--[[=====================================================================
  SOVEREIGN STABLES · TACK & COMPONENTS
  ---------------------------------------------------------------------
  Buyable horse equipment/appearance components. Bought tack is stored in the
  player's stable and re-applied from the customizer [F1/F5]. Component hashes
  come from the game; this catalog just names, prices and groups them.

  Phase 0 defines the CATEGORY structure only. The full hash tables are filled
  after the horse-appearance tech-prep spike confirms the apply/persist path.
=====================================================================]]--

Config = Config or {}

-- Categories the customizer will present. `slot` maps to how it is applied.
Config.TackCategories = {
    { id = 'saddle',     label = 'Saddles',     slot = 'saddle'     },
    { id = 'saddlebags', label = 'Saddlebags',  slot = 'saddlebags' },
    { id = 'horn',       label = 'Saddle Horns', slot = 'horn'      },
    { id = 'stirrups',   label = 'Stirrups',    slot = 'stirrups'   },
    { id = 'blanket',    label = 'Blankets',    slot = 'blanket'    },
    { id = 'bedroll',    label = 'Bedrolls',    slot = 'bedroll'    },
    { id = 'lantern',    label = 'Lanterns',    slot = 'lantern'    },
    { id = 'mask',       label = 'Masks',       slot = 'mask'       },
    { id = 'mane',       label = 'Manes',       slot = 'mane'       },
    { id = 'tail',       label = 'Tails',       slot = 'tail'       },
}

--------------------------------------------------------------------------------
-- TACK OWNERSHIP RULES  (owner ruling 2026-07-15)
--------------------------------------------------------------------------------
-- Tack belongs to the PLAYER, not the horse. Buy a saddle once and it goes on
-- whichever horse you ride. When a horse dies, its tack comes back to you (the
-- cargo it was carrying does not).
Config.TackRules = {
    -- You may never be charged twice for a piece you already own. Also enforced
    -- by a UNIQUE key in sql/install.sql, so no code path can get this wrong.
    neverRebuyOwned = true,

    -- ⚠️ NEEDS AN OWNER RULING — see docs/testing/MILESTONE_1.4_CHECKLIST.md.
    -- The ruling said "adjust a tack and you pay only the difference", which
    -- reads as a TRADE-IN: you keep one piece per slot and upgrading costs only
    -- the gap.  true  = trade-in. Buy a $60 saddle while owning a $40 one and
    --                   you pay $20; the $40 saddle is gone. You own ONE saddle.
    --         false = collection. Every piece is bought outright at full price
    --                   and kept, so you can keep a work saddle AND a good one
    --                   for different horses.
    -- Trade-in matches the words; collection matches the RP of owning a stable
    -- of different horses. Defaulting to the literal ruling.
    tradeInWithinSlot = true,

    -- Never refund on a downgrade — the difference floors at zero.
    allowDowngradeRefund = false,
}

--------------------------------------------------------------------------------
-- THE CATALOG
--------------------------------------------------------------------------------
-- Item shape:
--   ['item_id'] = { label = 'Shown to players', price = { cash = 40, gold = 0 },
--                   hash = 0x106961A8, jobs = 'all', stables = 'all' }
--
-- `hash` is the metaped component hash, applied at runtime via the pipeline the
-- Phase 1 spike proved (0xD3A7B003ED343FD9 + UpdatePedVariation 0xCC8CA3E88256E58F).
-- Components are NOT breed-locked (spike result A8: a mane hash that changed the
-- grey Kentucky Saddler also changed the gold Turkoman), so ONE universal list
-- serves every horse — there are no per-breed tables to maintain.
--
-- ⚠️ PRICES ARE PLACEHOLDERS pending the economy pass, same as horses/wagons.
--
-- ⚠️ ONLY THE 11 HASHES BELOW ARE VERIFIED. They are the ones the spike applied
-- to a live horse and watched change. Everything else needs hashes sourced
-- before it can ship — an unverified hash silently does nothing, which is the
-- worst kind of bug to chase. Empty categories are honest; guessed ones are not.
Config.Tack = {

    -- ✅ VERIFIED in the Phase 1 spike.
    mane = {
        ['mane_short']      = { label = 'Short Mane',      price = { cash = 5.0  }, hash = 0x18199F48 },
        ['mane_regular']    = { label = 'Regular Mane',    price = { cash = 5.0  }, hash = 0x130E341A },
        ['mane_long']       = { label = 'Long Mane',       price = { cash = 8.0  }, hash = 0x0235DBF1 },
        ['mane_braid']      = { label = 'Braided Mane',    price = { cash = 12.0 }, hash = 0x25627B98 },
        ['mane_dreadlocks'] = { label = 'Dreadlocked Mane',price = { cash = 12.0 }, hash = 0x1FDC6D0F },
    },

    -- ✅ VERIFIED in the Phase 1 spike.
    tail = {
        ['tail_short']      = { label = 'Short Tail',      price = { cash = 5.0  }, hash = 0x1BB5EAA1 },
        ['tail_regular']    = { label = 'Regular Tail',    price = { cash = 5.0  }, hash = 0x383E86F3 },
        ['tail_long']       = { label = 'Long Tail',       price = { cash = 8.0  }, hash = 0x1F7A99EA },
        ['tail_braid']      = { label = 'Braided Tail',    price = { cash = 12.0 }, hash = 0x17EB79D3 },
        ['tail_dreadlocks'] = { label = 'Dreadlocked Tail',price = { cash = 12.0 }, hash = 0x12DBBBAF },
    },

    -- ✅ ONE verified saddle. The rest of the saddle roster needs hashes.
    saddle = {
        ['saddle_mcclelland'] = { label = 'Lumley McClelland', price = { cash = 40.0 }, hash = 0x106961A8 },
    },

    -- ⬜ Awaiting hashes. Leave empty rather than guess — the storefront simply
    --    shows no items for these categories until they're filled.
    saddlebags = {},
    horn       = {},
    stirrups   = {},
    blanket    = {},
    bedroll    = {},
    lantern    = {},
    mask       = {},
}

-- Horseshoe upgrade track [S12]. maxLevel caps upgrades; each level has a price/effect.
Config.Horseshoes = {
    enabled  = true,
    maxLevel = 3,
    levels   = {
        -- [1] = { label = 'Iron Shoes',  price = { cash = 25 },  speed = 0.02, stamina = 0.03 },
        -- [2] = { label = 'Steel Shoes', price = { cash = 60 },  speed = 0.04, stamina = 0.05 },
    },
    flaming = { enabled = false },   -- [S13] cosmetic flaming shoe, off until the FX spike lands
    cleaning = { enabled = true },   -- hoof/shoe cleaning w/ neglect penalty [H6/J16]
}
