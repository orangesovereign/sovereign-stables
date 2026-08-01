--[[=====================================================================
  SOVEREIGN STABLES · BREEDING  (the stud register)
  ---------------------------------------------------------------------
  A stable pairs a sire and dam; after a gestation the pairing produces a foal,
  then the parents enter a restoration cooldown before they can breed again.
  This file tunes the timings, the stud fee, and who may run breedings by role.
  server/breeding.lua is the logic; stud fees post to the society ledger.
=====================================================================]]--

Config = Config or {}

Config.Breeding = {
    gestationDays   = 5,     -- in-progress → result ready
    restorationDays = 3,     -- cooldown after a result before the parents can breed again
    fee             = 500,   -- stud fee, billed to the client + posted to the ledger at pairing
    results         = { 'Filly', 'Colt' },   -- foal outcomes (chosen at random on completion)

    -- Who may do what, by stable role (gated server-side).
    perms = {
        owner      = { create = true,  cancel = true,  review = true },
        trainer    = { create = true,  cancel = false, review = true },
        stablehand = { create = false, cancel = false, review = false },
    },
}
