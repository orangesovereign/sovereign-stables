--[[=====================================================================
  SOVEREIGN STABLES · UTILITIES
  ---------------------------------------------------------------------
  Small shared helpers used everywhere. No gameplay logic here.
=====================================================================]]--

Util = Util or {}

local RESOURCE = 'sovereign_stables'

-- Logging that respects Config.Debug (and always prints warnings/errors).
function Util.log(...)
    if Config and Config.Debug then
        print(('[%s]'):format(RESOURCE), ...)
    end
end

function Util.warn(...)
    print(('[%s] ^3WARN^7'):format(RESOURCE), ...)
end

function Util.err(...)
    print(('[%s] ^1ERROR^7'):format(RESOURCE), ...)
end

-- Locale lookup with sprintf-style args. Falls back to the key if missing.
function Util.L(key, ...)
    local loc = Locales and Locales[Config and Config.Locale or 'en']
    local str = loc and loc[key]
    if not str then return key end
    if select('#', ...) > 0 then
        local ok, res = pcall(string.format, str, ...)
        return ok and res or str
    end
    return str
end

-- Shallow-merge `over` onto a copy of `base` (used for defaults + overrides).
function Util.withDefaults(base, over)
    local out = {}
    for k, v in pairs(base or {}) do out[k] = v end
    for k, v in pairs(over or {}) do out[k] = v end
    return out
end

function Util.tableCount(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

function Util.isVec3(t)
    return type(t) == 'table' and type(t[1]) == 'number'
        and type(t[2]) == 'number' and type(t[3]) == 'number'
end

-- RedM control name -> control hash, for rebindable keys. Extend as needed.
Util.Keys = {
    H = 0x24978A28, J = 0x21B45D45, E = 0xCEFD9220,
    SPACE = 0xD9D0E1C0, F = 0xB2F377E8, G = 0x760A9C6F,
    B = 0xF3830D8E, U = 0x3B2CCB90,
}

function Util.keyHash(name)
    return Util.Keys[(name or ''):upper()]
end
