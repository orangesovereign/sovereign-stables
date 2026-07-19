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

# 5) golden: both cores stay >=80 for >=20 min -> golden becomes true
b = L.table_from({"hunger":100,"thirst":100,"dirt":0,"golden":False,"goldenTs":0,"ts":0})
drift(b, "stored", 60)          # t=60: above line, goldenTs set, not yet golden
check("golden: not yet at 1 min", b.golden is False and b.goldenTs > 0)
drift(b, "stored", 60 + 20*60)  # +20 min above line
check("golden: turns golden after 20m above line", b.golden is True)

# 6) golden lost when a core drops below the line. NOTE the golden 0.5 drain
# mult: thirst falls 0.5/min, so it takes 45 min (not 25) to cross 100 -> <80.
# 45 min: thirst 100 - 0.5*45 = 77.5 < 80 -> golden lost.
b = L.table_from({"hunger":100,"thirst":100,"dirt":0,"golden":True,"goldenTs":1,"ts":0})
drift(b, "active", 45*60)
check("golden: lost when a core dips below the line", b.golden is False and b.goldenTs == 0)

# 7) golden drains slower: a golden horse loses half the cores over the same time
bg = L.table_from({"hunger":100,"thirst":100,"dirt":0,"golden":True,"goldenTs":1,"ts":0})
drift(bg, "active", 600)   # 10 min; golden mult 0.5 -> hunger -0.7*0.5*10 = 3.5 -> 96.5
check("golden drains slower: ~96/97 not 93", round(bg.hunger) in (96, 97))

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
