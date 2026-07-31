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

    -- The player's VORP admin group ('admin'/'superadmin'/...), or nil. Tries the
    -- several shapes VORP has used (character.group, user.getGroup()).
    function Bridge.getGroup(src)
        local core = Bridge.core(); if not core then return nil end
        local user = core.getUser(src); if not user then return nil end
        local g
        pcall(function() if user.getGroup then g = user.getGroup() end end)
        if not g then pcall(function() g = user.getUsedCharacter and user.getUsedCharacter.group end) end
        if not g then local ch = Bridge.getCharacter(src); g = ch and (ch.group or ch.Group or ch.userGroup) end
        return g
    end

    -- Is this player a SERVER ADMIN? VORP group → ace → boss-grade horseCreator.
    -- Config.Admin lists the accepted groups/aces (config/config.lua).
    function Bridge.isAdmin(src)
        local cfg = Config.Admin or {}
        -- Guaranteed override: your identifier in Config.Admin.identifiers.
        if cfg.identifiers and next(cfg.identifiers) then
            local id = Bridge.getIdentifier(src)
            if id then
                for _, want in ipairs(cfg.identifiers) do
                    if tostring(want) == tostring(id) then return true end
                end
            end
        end
        local grp = Bridge.getGroup(src)
        if grp then
            grp = tostring(grp):lower()
            for _, g in ipairs(cfg.groups or {}) do if tostring(g):lower() == grp then return true end end
        end
        for _, ace in ipairs(cfg.aces or {}) do
            local ok = false
            pcall(function() ok = IsPlayerAceAllowed(src, ace) end)
            if ok then return true end
        end
        local job, grade = Bridge.getJob(src)
        return (Perms and Perms.can and Perms.can(job, grade, 'horseCreator')) == true
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
    -- Register a custom vorp_inventory stash (a wagon's cargo hold). The
    -- registration is in-memory, so re-register whenever the ride is called out;
    -- it's idempotent (vorp no-ops a duplicate id). Contents auto-persist to the
    -- DB keyed by the id, and `shared = true` means the stash belongs to the RIDE,
    -- not the character — so it travels with a transferred wagon. Uses the table
    -- form (the positional export is deprecated). limit = SLOTS.
    function Bridge.registerRideInventory(id, name, limit)
        if not id then return end
        local ok = pcall(function()
            exports.vorp_inventory:registerInventory({
                id = id, name = name or 'Storage', limit = tonumber(limit) or 30,
                acceptWeapons = false, shared = true, ignoreItemStackLimit = false,
            })
        end)
        if not ok then Util.warn(('could not register inventory "%s" — is vorp_inventory running?'):format(id)) end
    end

    -- Open a registered stash for a player (server-side).
    function Bridge.openRideInventory(src, id)
        if not (src and id) then return end
        pcall(function() exports.vorp_inventory:openInventory(src, id) end)
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


    -- The actual item INSTANCE the player is carrying, with its id and metadata.
    --
    -- Needed because a durable tool's remaining uses live in the metadata of one
    -- specific brush, not in the item type. `itemCount` can tell you a brush
    -- exists; only this can tell you WHICH brush, which is what you must have
    -- before you can decrement it. Without this the horse menu's Brush would
    -- consume the whole tool on first use while the satchel's Use correctly
    -- counted it down — the same action wearing out at two different rates.
    function Bridge.getItem(src, item)
        local p = promise.new()
        local ok = pcall(function()
            exports.vorp_inventory:getItem(src, item, function(found) p:resolve(found) end)
        end)
        if not ok then p:resolve(nil) end
        return Citizen.Await(p)
    end

    -- Remove a specific item INSTANCE by its inventory id (for durable tools that
    -- track state in metadata — we remove the exact one that wore out).
    function Bridge.removeItemById(src, id)
        pcall(function() exports.vorp_inventory:subItemById(src, id) end)
    end

    -- Write metadata onto a specific item instance (durability counters, etc.).
    function Bridge.setItemMetadata(src, id, metadata)
        pcall(function() exports.vorp_inventory:setItemMetadata(src, id, metadata, 1) end)
    end
end
