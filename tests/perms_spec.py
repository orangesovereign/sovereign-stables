#!/usr/bin/env python3
"""
Sovereign Stables — permission resolver spec.

    pip install lupa
    python tests/perms_spec.py

Runs config/config.lua, config/jobs.lua and shared/perms.lua under a real Lua
runtime and asserts the owner's rulings still hold. Cheap to run, and it does
not need RedM, a server, or a game client.

WHY THIS EXISTS: the job/grade tables are pure data + one resolver, which makes
them the one part of this resource that CAN be tested off-game — and the part
where a silent mistake is worst, because a wrong answer here means someone can
do a job they were never given. It has already caught three live bugs:

  1. Perms.maxHorses used math.min(global, job), so the Horse Trainer's ruled
     "higher cap" of 8 resolved to 3. A perk that can't exceed the default isn't
     a perk.
  2. Config.JobDefaults duplicated the caps, so the owner's "wagon limit should
     be 5" resolved to 1 for every player on the server.
  3. (Guarded below) grade permissions must NEVER inherit — a Wagon Maker must
     not silently gain horse training.
"""
import sys, os
try:
    import lupa
except ImportError:
    sys.exit("needs lupa:  pip install lupa")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
L = lupa.LuaRuntime(unpack_returned_tuples=True)
L.execute("Config = {}")
for f in ("config/config.lua", "config/jobs.lua", "shared/perms.lua"):
    L.execute(open(os.path.join(ROOT, f), encoding="utf-8").read())

can = L.eval("function(j,g,k) return Perms.can(j,g,k) end")
get = L.eval("function(j,g) return Perms.get(j,g) end")
horses = L.eval("function(j,g) return Perms.maxHorses(j,g) end")
wagons = L.eval("function(j,g) return Perms.maxWagons(j,g) end")
title = L.eval("function(j,g) return Perms.title(j,g) end")

T = "horsetrainer"
CHECKS = [
    # ── Grades are ROLES, not ranks (owner ruling 2026-07-15) ──────────────
    ("Wagon Maker(2) CANNOT train horses",   can(T, 2, "training") is False),
    ("Wagon Maker(2) HAS storefronts",       can(T, 2, "storefronts") is True),
    ("Wagon Maker(2) CAN craft wagons",      can(T, 2, "wagonCrafting") is True),
    ("Wagon Maker(2) CAN customise wagons",  can(T, 2, "wagonCustomizing") is True),
    ("Wagon Maker(2) CAN repair wagons",     can(T, 2, "wagonRepair") is True),
    ("Trainer(0) CAN train",                 can(T, 0, "training") is True),
    ("Trainer(0) has NO storefronts",        can(T, 0, "storefronts") is False),
    ("Trainer(0) CANNOT craft wagons",       can(T, 0, "wagonCrafting") is False),
    ("Senior(1) trains AND storefronts",     can(T, 1, "training") and can(T, 1, "storefronts")),
    ("Senior(1) CANNOT craft wagons",        can(T, 1, "wagonCrafting") is False),
    ("Boss(3) has the lot",                  all(can(T, 3, k) for k in
                                                 ("training", "storefronts", "wagonCrafting", "horseCreator"))),
    # Nothing inherits: if this fails, a Wagon Maker just became a trainer.
    ("grade perms do NOT inherit upward",    can(T, 2, "training") is False and can(T, 1, "training") is True),
    ("the grades table never leaks",         get(T, 2)["grades"] is None),
    ("titles resolve",                       title(T, 2) == "Wagon Maker" and title(T, 3) == "Stable Owner"),

    # ── Wagon repair: floor is free, ceiling is a service (ruled 2026-07-15) ──
    # "Everyone can repair their wagon to the lowest wagon health to get your
    #  wagon going. Wagon makers are the only people who can repair to 100%."
    ("everyone gets field repair",           can(None, None, "wagonRepair") is True),
    ("a plain player CANNOT full-repair",    can(None, None, "wagonFullRepair") is False),
    ("Horse Trainer(0) CANNOT full-repair",  can(T, 0, "wagonFullRepair") is False),
    ("Senior(1) CANNOT full-repair",         can(T, 1, "wagonFullRepair") is False),
    ("Wagon Maker(2) CAN full-repair",       can(T, 2, "wagonFullRepair") is True),
    ("Boss(3) CAN full-repair",              can(T, 3, "wagonFullRepair") is True),
    # The trade only exists because of the gap between these two numbers.
    ("field floor < pro ceiling",            L.eval("Config.WagonDamage.fieldRepairTo") <
                                             L.eval("Config.WagonDamage.proRepairTo")),
    ("field floor > 0 (never stranded)",     L.eval("Config.WagonDamage.fieldRepairTo") > 0),

    # ── Caps: Config.Caps is a BASELINE, a job REPLACES it ─────────────────
    ("trainer's ruled higher cap = 8",       horses(T, 0) == 8),
    ("owner's wagon limit of 5 applies",     wagons(None, None) == 5),
    ("plain player horse cap = 3",           horses(None, None) == 3),
    ("rancher horses 6",                     horses("rancher", 0) == 6),
    ("a job may cap LOWER than global",      wagons("rancher", 0) == 3),
    ("unknown job falls back to defaults",   horses("bartender", 0) == 3 and wagons("bartender", 0) == 5),
    ("no grade -> job-wide values",          horses(T, None) == 8),
]

bad = [n for n, ok in CHECKS if not ok]
for n, ok in CHECKS:
    print(("  \033[32mPASS\033[0m  " if ok else "  \033[31mFAIL\033[0m  ") + n)
print("\n%d/%d passed" % (len(CHECKS) - len(bad), len(CHECKS)))
if bad:
    print("\nFAILED:\n  - " + "\n  - ".join(bad))
    sys.exit(1)
print("rulings hold.")
