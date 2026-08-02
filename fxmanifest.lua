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
    'server/creator.lua',      -- admin Horse Creator (author horses into a stable catalog)
    'server/admin.lua',        -- admin read aggregates (directory/profile/activity/ledger/employees)
    'server/metabolism.lua',   -- Metabolism.current used by summon.lua
    'server/summon.lua',
    'server/transfer.lua',
    'server/storelink.lua',    -- charters a stable's store in sovereign_stores
}

-- React + Vite NUI (ui/), built to ui/dist and committed (server deploys via
-- FileZilla, no build step). Covers the storefront, customizer and management
-- book. The old vanilla UI is retained under ui_legacy/ as a rollback (not
-- referenced); to revert, point ui_page back at 'ui_legacy/index.html'.
-- Rebuild: cd ui && npm run build.
ui_page 'ui/dist/index.html'
files {
    'ui/dist/index.html',
    'ui/dist/assets/*.js',
    -- Book-UI asset kit (leather/parchment/brass surfaces, seals, icons) + CSS/fonts
    'ui/dist/css/*.css',
    'ui/dist/fonts/*.woff2',
    'ui/dist/assets/textures/*.png',
    'ui/dist/assets/book_furniture/*.png',
    'ui/dist/assets/seals/*.png',
    'ui/dist/assets/cards/*.png',
    'ui/dist/assets/containers/*.png',
    'ui/dist/assets/icons/*.png',
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
