--[[=====================================================================
  SOVEREIGN STABLES · TRAINING  (client-horse boarding business)
  ---------------------------------------------------------------------
  A stable takes in a CLIENT's horse for RAISING or TRAINING, assigns it to a
  trainer, and it moves through phases until it's ready for the owner to collect.
  This file is the tuning surface: the purchase TIERS (how long each takes and
  what it costs), and the phase list. server/training.lua is the logic.

  Each tier's `price` is billed to the client and posted to the society ledger as
  income when the horse is taken in. `days` sets the approximate ready date
  (received + days). `startPhase` is where it begins.
=====================================================================]]--

Config = Config or {}

Config.Training = {
    -- Phases a client horse moves through, in order.
    phases = { 'raising', 'training', 'ready', 'returned' },

    -- Purchase types shown at intake. id is stored; label is shown.
    tiers = {
        { id = 'new',   label = 'New Horse',         days = 7,  price = 150, startPhase = 'raising'  },
        { id = 'tier2', label = 'Training — Tier 2', days = 10, price = 240, startPhase = 'training' },
        { id = 'tier3', label = 'Training — Tier 3', days = 14, price = 420, startPhase = 'training' },
        { id = 'tier4', label = 'Training — Tier 4', days = 21, price = 650, startPhase = 'training' },
    },

    -- A trainer may take in horses to their OWN roster; an owner may take one in
    -- for any trainer. false = only owner/admin may run intake.
    trainersMayIntake = true,
}
