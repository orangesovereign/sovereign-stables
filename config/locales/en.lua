--[[=====================================================================
  SOVEREIGN STABLES · LOCALE (English)
  ---------------------------------------------------------------------
  Copy this file, rename it (e.g. fr.lua), translate the right-hand strings,
  add it to fxmanifest shared_scripts, and set Config.Locale in config.lua.
=====================================================================]]--

Locales = Locales or {}

Locales['en'] = {
    -- generic
    ['open_stable']      = 'Press ~o~%s~q~ to speak with the stablehand',
    ['no_permission']    = "You aren't permitted to do that here.",
    ['not_enough_cash']  = "You can't afford that.",
    ['not_enough_gold']  = "You don't have enough gold.",
    ['cap_reached']      = 'You already own as many as you can keep.',

    -- purchase
    ['bought_horse']     = 'You bought %s.',
    ['bought_wagon']     = 'You bought %s.',
    ['sold_horse']       = 'You sold %s for %s.',

    -- summon
    ['horse_too_far']    = 'Your horse is too far to answer the whistle.',
    ['recall_cooldown']  = 'Give it a moment before calling again.',
    ['horse_following']  = 'Your horse will follow you.',
    ['horse_staying']    = 'Your horse holds its ground.',

    -- diagnostics
    ['diag_ok']          = 'Sovereign Stables: all checks passed.',
    ['diag_problems']    = 'Sovereign Stables: %d problem(s) found — see console.',
}
