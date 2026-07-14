fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Sovereign County RP'
name 'sovereign_stables'
description 'Sovereign County stables, horses & wagons — a from-scratch replacement for vorp_stables (VorpCore).'
repository 'https://github.com/orangesovereign/sovereign-stables'
version '0.0.0'
lua54 'yes'

-- Load order matters: config -> shared libs -> feature modules.
shared_scripts {
    'config/config.lua',
    'config/stables.lua',
    'config/horses.lua',
    'config/wagons.lua',
    'config/tack.lua',
    'config/jobs.lua',
    'config/locales/en.lua',
    'shared/events.lua',
    'shared/util.lua',
    'shared/validate.lua',
    'shared/registry.lua',
    'shared/bridge.lua',
}

client_scripts {
    'client/core.lua',
}

server_scripts {
    'server/db.lua',
    'server/core.lua',
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
