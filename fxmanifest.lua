fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Sovereign County RP'
name 'sovereign_stables'
description 'Sovereign County stables, horses & wagons — a from-scratch replacement for vorp_stables (VorpCore).'
repository 'https://github.com/orangesovereign/sovereign-stables'
version '0.1.0'
lua54 'yes'

-- Load order matters: config -> shared libs -> feature modules.
shared_scripts {
    'config/config.lua',
    'config/stables.lua',
    'config/horses.lua',
    'config/wagons.lua',
    'config/tack.lua',
    'config/jobs.lua',
    'config/metabolism.lua',
    'config/horsemorph.lua',
    'config/training.lua',
    'config/breeding.lua',
    'config/locales/en.lua',
    'shared/events.lua',
    'shared/util.lua',
    'shared/validate.lua',
    'shared/registry.lua',
    'shared/bridge.lua',
    'shared/catalog.lua',
    'shared/perms.lua',
}

client_scripts {
    'client/preview.lua',
    'client/camera.lua',
    'client/components.lua',   -- tack apply pipeline; horse.lua + preview.lua use it
    'client/metabolism.lua',   -- care state; horse.lua + preview.lua call into it
    'client/horse.lua',
    'client/morph.lua',        -- horse morph apply engine (drives Config.HorseMorph)
    'client/coat.lua',         -- horse coat/morph probe (Horse Customiser groundwork)
    'client/customizer.lua',   -- horse morph customiser panel (live preview + save)
    'client/management.lua',   -- role-scoped stable management panel
    'client/horsemenu.lua',    -- horse interaction menu: name + condition, lead, drink
    'client/wagon.lua',
    'client/transfer.lua',
    'client/storefront.lua',
    'client/stables.lua',
    'client/core.lua',
}

-- Load order matters here: transfer.lua calls Horses.countOwned and
-- Wagons.countOwned, so both must be defined before it.
server_scripts {
    'server/db.lua',
    'server/core.lua',
    'server/horses.lua',
    'server/wagons.lua',
    'server/tack.lua',
    'server/morph.lua',        -- persist a horse's shape (Config.HorseMorph values)
    'server/management.lua',   -- role-scoped stable management panel (business layer)
    'server/business.lua',     -- employees / society ledger / funds (uses management helpers)
    'server/training.lua',     -- client-horse boarding/training (posts income to the ledger)
    'server/breeding.lua',     -- stud register (gestation + cooldown; stud fees to the ledger)
    'server/metabolism.lua',   -- Metabolism.current used by summon.lua
    'server/summon.lua',
    'server/transfer.lua',
    'server/storelink.lua',    -- charters a stable's store in sovereign_stores
}

-- Custom branded NUI shell (storefront / customizer / codex / horse creator).
-- Phase 0 ships a plain HTML/CSS/JS shell; a bundler is introduced when the
-- storefront gains real screens.
ui_page 'ui/index.html'
files {
    'ui/index.html',
    'ui/app.css',
    'ui/app.js',
}

-- Resources this script talks to (all reached through shared/bridge.lua).
-- Listed for load-order + operator clarity. vorp_core / vorp_inventory are the
-- framework; the two sovereign_* are our county UI system.
dependencies {
    'vorp_core',
    'vorp_inventory',
    'sovereign_notify',
    'sovereign_menus',
}
