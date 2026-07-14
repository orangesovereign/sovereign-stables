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

-- Example item shape (filled per category later):
--   Config.Tack.saddle = {
--     ['saddle_mcclelland'] = { label = 'Lumley McClelland', price = { cash = 40 }, hash = '0x106961A8' },
--   }
Config.Tack = {}

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
