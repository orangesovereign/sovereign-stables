--[[=====================================================================
  SOVEREIGN STABLES · HORSE MORPH ENGINE  (client)
  ---------------------------------------------------------------------
  Applies a set of morph values to a horse, driven entirely by
  Config.HorseMorph (config/horsemorph.lua). One place that knows how to shape
  a horse — used by the customiser preview, the breed creator, and (re-applied)
  on every spawn, since none of this state persists on the entity.

  Values are keyed by the config `key`:  { [key] = number }
    expr   attributes: -1.0 .. 1.0
    scale  attribute : ~0.5 .. 2.0 (1.0 = default)
    toggle attribute : 0 or 1

  Natives (RDR3-verified, confirmed in-game 2026-07-31):
    _SET_CHAR_EXPRESSION 0x5653AB26C82938CF, _GET_CHAR_EXPRESSION 0xFD1BA1EEF7985BB8,
    _SET_PED_SCALE 0x25ACFC650B65C538, _UPDATE_PED_VARIATION 0xCC8CA3E88256E58F.
=====================================================================]]--

Morph = Morph or {}

local EXPR_SET = 0x5653AB26C82938CF
local EXPR_GET = 0xFD1BA1EEF7985BB8
local COMMIT   = 0xCC8CA3E88256E58F
local SCALE    = 0x25ACFC650B65C538

-- Index the config by key once (config loads before client scripts).
local byKey = {}
for _, a in ipairs(Config.HorseMorph or {}) do byKey[a.key] = a end

Morph.attr = function(key) return byKey[key] end
Morph.all  = function() return Config.HorseMorph or {} end

local function commit(ped)
    pcall(function() Citizen.InvokeNative(COMMIT, ped, false, true, true, true, false) end)
end

-- Apply ONE attribute value (no commit — caller commits once at the end).
local function applyAttr(ped, a, v)
    if a.kind == 'scale' then
        local s = tonumber(v); if not s then return end
        s = math.max(0.5, math.min(2.0, s))
        pcall(function() Citizen.InvokeNative(SCALE, ped, s + 0.0) end)
        return
    end
    local val = tonumber(v) or 0.0
    if a.kind == 'toggle' then
        val = (val >= 0.5) and 1.0 or 0.0
    else
        val = math.max(-1.0, math.min(1.0, val))
    end
    for _, idx in ipairs(a.indices or {}) do
        pcall(function() Citizen.InvokeNative(EXPR_SET, ped, idx, val + 0.0) end)
    end
end

-- Apply a whole { key = value } set to a ped, then commit once.
function Morph.apply(ped, values)
    if not (ped and DoesEntityExist(ped)) or type(values) ~= 'table' then return false end
    local touched = false
    for key, v in pairs(values) do
        local a = byKey[key]
        if a then applyAttr(ped, a, v); touched = true end
    end
    if touched then commit(ped) end
    return touched
end

-- Apply a single named attribute (used by the live-preview slider).
function Morph.set(ped, key, value)
    local a = byKey[key]
    if not (a and ped and DoesEntityExist(ped)) then return false end
    applyAttr(ped, a, value)
    commit(ped)
    return true
end

-- Read the current values off a horse (for "start from this breed"). Scale can't
-- be read back, so it's omitted; expr/toggle come from the FIRST index of each.
function Morph.read(ped)
    local out = {}
    if not (ped and DoesEntityExist(ped)) then return out end
    for _, a in ipairs(Config.HorseMorph or {}) do
        if a.kind ~= 'scale' and a.indices and a.indices[1] then
            local v = 0.0
            pcall(function() v = Citizen.InvokeNative(EXPR_GET, ped, a.indices[1], Citizen.ResultAsFloat()) end)
            out[a.key] = tonumber(v) or 0.0
        end
    end
    return out
end
