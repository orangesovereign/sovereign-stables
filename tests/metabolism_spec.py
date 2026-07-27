#!/usr/bin/env python3
"""
Sovereign Stables — metabolism drift spec.

    pip install lupa
    python tests/metabolism_spec.py

Loads config/metabolism.lua and the drift/golden/clamp maths from
server/metabolism.lua under a real Lua runtime, stubbing the FiveM/vorp globals
the file references. Exercises the lazy-timestamp drain that can't be tested
in-game without waiting real minutes.
"""
import sys, os
try:
    import lupa
except ImportError:
    sys.exit("needs lupa:  pip install lupa")
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
L = lupa.LuaRuntime(unpack_returned_tuples=True)

# Stub the globals server/metabolism.lua touches at load time, so it loads. We
# only exercise Metabolism.drift, which is pure maths over a blob + config.
L.execute("""
Config = {}
Events = setmetatable({}, { __index = function() return 'stub' end })
promise = { new = function() return {} end }
Citizen = { Await = function() return 0 end }
json = { encode = function() return '' end, decode = function() return nil, nil end }
Db = { awaitQuery = function() return nil end, execute = function() end }
Bridge = { getCharId = function() return 1 end, takeItem = function() return true end,
           notify = function() end, registerUsableItem = function() end, closeInventory = function() end }
Util = { log = function() end, warn = function() end }
function RegisterNetEvent() end
function AddEventHandler() end
function CreateThread() end
function TriggerClientEvent() end
function GetCurrentResourceName() return 'sovereign_stables' end
os = os or {}
""")

L.execute(open(os.path.join(ROOT, "config/metabolism.lua"), encoding="utf-8").read())
L.execute(open(os.path.join(ROOT, "server/metabolism.lua"), encoding="utf-8").read())

drift = L.eval("Metabolism.drift")

def fresh(ts=0):
    b = L.table_from({"hunger":100,"thirst":100,"dirt":0,"golden":False,"goldenTs":0,"ts":ts})
    return b

CHECKS = []
def check(name, cond): CHECKS.append((name, bool(cond)))

# 1) 60 min ACTIVE: hunger -0.7*60=42 -> 58, thirst -1.0*60=60 -> 40, dirt +1.5*60 capped 100
b = fresh(0); drift(b, "active", 3600)
check("active 60m: hunger 100 -> 58", round(b.hunger) == 58)
check("active 60m: thirst 100 -> 40", round(b.thirst) == 40)
check("active 60m: dirt 0 -> 90",     round(b.dirt) == 90)

# 2) STORED time does NOT drain cores (drainWhile='active') and DOES clean.
b = L.table_from({"hunger":50,"thirst":50,"dirt":100,"golden":False,"goldenTs":0,"ts":0})
drift(b, "stored", 3600)   # 60 min stored; auto-clean over 30 min => fully clean
check("stored 60m: hunger held at 50", round(b.hunger) == 50)
check("stored 60m: thirst held at 50", round(b.thirst) == 50)
check("stored 60m: dirt 100 -> 0 (stable groomed it)", round(b.dirt) == 0)

# 3) stored 15m cleans HALF the range (100/30 per min * 15 = 50 removed)
b = L.table_from({"hunger":50,"thirst":50,"dirt":100,"golden":False,"goldenTs":0,"ts":0})
drift(b, "stored", 900)
check("stored 15m: dirt 100 -> 50", round(b.dirt) == 50)

# 4) clamps: never below 0
b = fresh(0); drift(b, "active", 3600*10)   # 10h active
check("clamp: hunger floors at 0", b.hunger == 0)
check("clamp: thirst floors at 0", b.thirst == 0)
check("clamp: dirt ceils at 100",  b.dirt == 100)

# 5-7) GOLDEN IS OFF (owner ruling 2026-07-27): "Do not want it to show golden
# state. Actually remove Golden state altogether or just turn it off."
#
# These used to assert the mechanic worked. They now assert the RULING holds —
# and specifically that switching it off UNDOES the state it created, rather than
# merely stopping new ones. That distinction is the whole reason these three are
# still here: an off-switch that only stops accrual leaves every horse that went
# golden before the change holding a permanent 0.5x drain bonus that nobody else
# on the server can ever get.
golden_on = L.eval("Config.Metabolism.golden.enabled") is True
check("golden is switched OFF in config", golden_on is False)

# A horse that would qualify never becomes golden.
b = L.table_from({"hunger":100,"thirst":100,"dirt":0,"golden":False,"goldenTs":0,"ts":0})
drift(b, "stored", 60 + 40*60)   # twice the old threshold, well above the line
check("no horse turns golden while off", b.golden is False and b.goldenTs == 0)

# An ALREADY-golden horse (a row written before the switch-off) is retired on its
# very next drift, and gets no slow-drain even for that first interval:
# hunger 100 - 0.7*10 = 93, NOT the golden 96.5.
bg = L.table_from({"hunger":100,"thirst":100,"dirt":0,"golden":True,"goldenTs":1,"ts":0})
drift(bg, "active", 600)
check("a pre-existing golden horse is retired", bg.golden is False and bg.goldenTs == 0)
check("and loses the slow drain immediately: 93 not 96", round(bg.hunger) == 93)

# 8) zero elapsed time is a no-op
b = fresh(1000); before = (b.hunger, b.thirst, b.dirt)
drift(b, "active", 1000)
check("no-op on zero elapsed", (b.hunger, b.thirst, b.dirt) == before)

bad = [n for n, ok in CHECKS if not ok]
for n, ok in CHECKS:
    print(("  PASS  " if ok else "  FAIL  ") + n)
print("\n%d/%d passed" % (len(CHECKS) - len(bad), len(CHECKS)))
if bad:
    print("FAILED:\n  - " + "\n  - ".join(bad)); sys.exit(1)
print("drift holds.")
