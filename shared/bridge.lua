--[[=====================================================================
  SOVEREIGN STABLES · BRIDGE  (dependency abstraction)
  ---------------------------------------------------------------------
  Every external resource is reached ONLY through this file: vorp_core,
  vorp_inventory, sovereign_notify, sovereign_menus. Swapping a dependency
  (or supporting a second framework later) means editing one adapter here and
  nothing else in the codebase.

  Runs on both sides; server-only pieces are guarded by IsDuplicityVersion().
=====================================================================]]--

Bridge = Bridge or {}

local IS_SERVER = IsDuplicityVersion()

--------------------------------------------------------------------------------
-- Dependency health (used by /stables_diag)
--------------------------------------------------------------------------------
Bridge.required = { 'vorp_core', 'vorp_inventory', 'sovereign_notify', 'sovereign_menus' }

function Bridge.checkDependencies()
    local report = {}
    for _, name in ipairs(Bridge.required) do
        local state = GetResourceState(name)
        report[#report + 1] = { name = name, state = state, ok = (state == 'started') }
    end
    return report
end

--------------------------------------------------------------------------------
-- CORE (vorp_core)
--------------------------------------------------------------------------------
local Core
function Bridge.core()
    if Core == nil then
        local ok, c = pcall(function() return exports.vorp_core:GetCore() end)
        Core = ok and c or false
    end
    return Core or nil
end

if IS_SERVER then
    -- Returns the active character for a player source, or nil.
    function Bridge.getCharacter(src)
        local core = Bridge.core(); if not core then return nil end
        local user = core.getUser(src); if not user then return nil end
        return user.getUsedCharacter
    end

    function Bridge.getCharId(src)
        local ch = Bridge.getCharacter(src)
        return ch and ch.charIdentifier
    end

    function Bridge.getIdentifier(src)
        local ch = Bridge.getCharacter(src)
        return ch and ch.identifier
    end

    function Bridge.getJob(src)
        local ch = Bridge.getCharacter(src)
        if not ch then return nil end
        return ch.job, ch.jobGrade
    end

    ----------------------------------------------------------------------------
    -- MONEY  (0 = cash, 1 = gold)
    ----------------------------------------------------------------------------
    function Bridge.getBalance(src)
        local ch = Bridge.getCharacter(src)
        if not ch then return 0, 0 end
        return ch.money or 0, ch.gold or 0
    end

    function Bridge.canAfford(src, cash, gold)
        local haveCash, haveGold = Bridge.getBalance(src)
        return haveCash >= (cash or 0) and haveGold >= (gold or 0)
    end

    function Bridge.charge(src, cash, gold)
        local ch = Bridge.getCharacter(src); if not ch then return false end
        if not Bridge.canAfford(src, cash, gold) then return false end
        if cash and cash > 0 then ch.removeCurrency(0, cash) end
        if gold and gold > 0 then ch.removeCurrency(1, gold) end
        return true
    end

    function Bridge.pay(src, cash, gold)
        local ch = Bridge.getCharacter(src); if not ch then return false end
        if cash and cash > 0 then ch.addCurrency(0, cash) end
        if gold and gold > 0 then ch.addCurrency(1, gold) end
        return true
    end
end

--------------------------------------------------------------------------------
-- NOTIFY (sovereign_notify) — safe on both sides via its export signatures
--------------------------------------------------------------------------------
-- POLICY (owner ruling 2026-07-15): the parchment "Objective" slip is reserved
-- for Storyworks MISSIONS. Sovereign Stables must never send one. Everything
-- routine here is a Tick (slim chip); big moments are a Card.
if IS_SERVER then
    function Bridge.notify(src, text)         exports.sovereign_notify:Tick(src, text) end
    function Bridge.notifyTick(src, text)     exports.sovereign_notify:Tick(src, text) end
    function Bridge.notifyCard(src, variant, title, body)
        exports.sovereign_notify:Card(src, variant, title, body)
    end
else
    function Bridge.notify(text)              exports.sovereign_notify:Tick(text) end
    function Bridge.notifyTick(text)          exports.sovereign_notify:Tick(text) end
    function Bridge.notifyCard(variant, title, body)
        exports.sovereign_notify:Card(variant, title, body)
    end
end

--------------------------------------------------------------------------------
-- MENUS (sovereign_menus) — client only
--------------------------------------------------------------------------------
if not IS_SERVER then
    function Bridge.openMenu(data, onSelect, onClose)
        return exports.sovereign_menus:Open(data, onSelect, onClose)
    end
    function Bridge.closeMenu() return exports.sovereign_menus:Close() end
    function Bridge.menuOpen()  return exports.sovereign_menus:IsOpen() end
end

--------------------------------------------------------------------------------
-- INVENTORY (vorp_inventory) — server only.
--------------------------------------------------------------------------------
if IS_SERVER then
    function Bridge.registerRideInventory(id, name, limit)
        -- TODO(Phase 2+): exports.vorp_inventory:registerInventory(...) — the
        -- horse/wagon cargo hold. Not needed for the care loop.
        Util.log(('inventory registration deferred: %s (%s, limit %s)'):format(id, name, tostring(limit)))
    end

    -- USABLE ITEMS — feed (H3), clean (H5), reviver (H12), etc. Registering an
    -- item makes "use" from the satchel fire `cb(data)`, where data.source is the
    -- player. We ALWAYS close the inventory in the handler or the UI hangs open.
    -- Wrapped in pcall so a missing/renamed export can't stop the resource
    -- booting — a server without the item just can't use it.
    function Bridge.registerUsableItem(item, cb)
        if not item then return end
        local ok = pcall(function()
            exports.vorp_inventory:registerUsableItem(item, cb)
        end)
        if not ok then Util.warn(('could not register usable item "%s" — is vorp_inventory running?'):format(item)) end
    end

    function Bridge.closeInventory(src)
        pcall(function() exports.vorp_inventory:closeInventory(src) end)
    end

    -- How many of `item` does this player hold? Async in vorp, so we bridge it to
    -- a synchronous return via a promise for callers already inside a thread.
    function Bridge.itemCount(src, item)
        local p = promise.new()
        local ok = pcall(function()
            exports.vorp_inventory:getItemCount(src, function(count) p:resolve(count or 0) end, item)
        end)
        if not ok then p:resolve(0) end
        return Citizen.Await(p)
    end

    -- Consume `amount` of `item`. Returns true if it took them.
    function Bridge.takeItem(src, item, amount)
        amount = amount or 1
        if Bridge.itemCount(src, item) < amount then return false end
        pcall(function() exports.vorp_inventory:subItem(src, item, amount) end)
        return true
    end
end
