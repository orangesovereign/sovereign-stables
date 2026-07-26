--[[=====================================================================
  SOVEREIGN STABLES · HORSE INFO PANEL  (client)
  ---------------------------------------------------------------------
  Stand near your horse (or sit on it), hold RIGHT-CLICK, and read its
  condition: Hunger, Thirst, Stamina, plus dirt and golden state.

  Owner request 2026-07-25: "When near a horse and right clicking, you should
  be able to see the horses Hunger, Thirst and Stamina information."

  ⚠️ THIS PANEL IS DELIBERATELY REUSABLE. Phase 3 ruled that COURAGE is visible
  to the owner exactly this way — "stand at the horse, right-click, horse info"
  (07-HORSE-TRAINER). So this is built as *the* horse readout, not a care-only
  one-off: add a row to `buildRows()` and it appears. What must NEVER appear
  here is the training repertoire — that one is ruled never-shown, anywhere.

  Two different "stamina" exist and it's worth not confusing them:
    • the LIVE stamina core, 0-100, drains as you gallop  → shown here
    • the horse's stamina STAT, its trained ceiling        → the storefront card
=====================================================================]]--

HorseInfo = HorseInfo or {}

local LOCKON = 0xF8982F00        -- INPUT_INTERACT_LOCKON (right mouse)
local visible = false

local function cfg() return (Config.UI and Config.UI.horseInfo) or {} end

--------------------------------------------------------------------------------
-- Reading the live cores. Index 0 = health, 1 = stamina — the same attribute
-- cores the player has, which horses carry too.
--------------------------------------------------------------------------------
-- Named native (as vorp_core uses it) rather than a hash — less to get wrong.
local function coreValue(ped, idx)
    if not (ped and DoesEntityExist(ped)) then return nil end
    local ok, v = pcall(function()
        return GetAttributeCoreValue(ped, idx, Citizen.ResultAsInteger())
    end)
    if ok and type(v) == 'number' then return v end
    return nil
end

--------------------------------------------------------------------------------
-- Is the player close enough to their own horse to read it?
--------------------------------------------------------------------------------
local function targetHorse()
    local a = Horse and Horse.active and Horse.active()
    if not (a and a.ent and DoesEntityExist(a.ent)) then return nil end
    local ped = PlayerPedId()
    if IsPedOnMount(ped) then return a end          -- riding it counts as near
    local d = #(GetEntityCoords(ped) - GetEntityCoords(a.ent))
    if d <= (cfg().distance or 6.0) then return a end
    return nil
end

--------------------------------------------------------------------------------
-- The rows. ADD TO THIS to extend the panel (courage lands here in Phase 3).
--------------------------------------------------------------------------------
local function buildRows(a)
    local care = Metabolism and Metabolism.card and Metabolism.card() or nil
    local rows = {}

    local function pct(label, v)
        if v == nil then return end
        rows[#rows + 1] = { label = label, value = math.floor(v + 0.5) }
    end

    pct('Hunger',  care and care.hunger)
    pct('Thirst',  care and care.thirst)
    pct('Stamina', coreValue(a.ent, 1))
    pct('Health',  coreValue(a.ent, 0))
    if care and care.dirt then
        rows[#rows + 1] = { label = 'Coat', value = math.floor(care.dirt + 0.5), invert = true }
    end
    return rows, (care and care.golden) or false
end

--------------------------------------------------------------------------------
-- Drawing. Plain native text — deliberately NOT the branded NUI: this is a
-- glance while you're sat in the saddle, not a screen you open. Opening the NUI
-- would take mouse focus and stop you riding.
--------------------------------------------------------------------------------
local function drawText(text, x, y, scale, r, g, b, a)
    SetTextScale(scale, scale)
    SetTextColor(math.floor(r), math.floor(g), math.floor(b), math.floor(a))
    SetTextCentre(false)
    DrawText(CreateVarString(10, 'LITERAL_STRING', text), x, y)
end

local function drawBar(x, y, w, h, fill, r, g, b)
    DrawRect(x + w / 2, y + h / 2, w, h, 0, 0, 0, 160)                      -- track
    local f = math.max(0.0, math.min(1.0, fill))
    if f > 0 then DrawRect(x + (w * f) / 2, y + h / 2, w * f, h, r, g, b, 230) end
end

local function drawPanel(a, rows, golden)
    local x, y = cfg().x or 0.015, cfg().y or 0.42
    local w = cfg().width or 0.105

    -- name + golden marker
    drawText((a.name or 'Your Horse') .. (golden and '  ~*~' or ''), x, y, 0.34, 231, 219, 194, 255)
    y = y + 0.028

    for _, row in ipairs(rows) do
        local v = math.max(0, math.min(100, row.value))
        -- `invert` = a high number is BAD (dirt). Show it as "how clean" so every
        -- bar in the panel reads the same way: fuller is better.
        local shown = row.invert and (100 - v) or v
        local f = shown / 100.0
        local r, g, b = 176, 137, 78                                        -- brass
        if f <= 0.15 then r, g, b = 156, 43, 29                             -- oxblood: critical
        elseif f <= 0.35 then r, g, b = 190, 120, 40 end                    -- amber: low
        drawText(row.label, x, y, 0.28, 166, 146, 111, 255)
        drawBar(x, y + 0.019, w, 0.007, f, r, g, b)
        drawText(tostring(math.floor(shown)) .. '%', x + w + 0.006, y, 0.28, 200, 186, 158, 255)
        y = y + 0.034
    end
end

--------------------------------------------------------------------------------
-- The loop. Cheap when idle: it only wakes every 300ms until you actually hold
-- right-click near your horse.
--------------------------------------------------------------------------------
CreateThread(function()
    while true do
        if cfg().enabled == false then
            Wait(1000)
        else
            local a = targetHorse()
            if a and IsControlPressed(0, LOCKON) then
                local rows, golden = buildRows(a)
                if #rows > 0 then
                    visible = true
                    drawPanel(a, rows, golden)
                end
                Wait(0)
            else
                if visible then visible = false end
                Wait(a and 100 or 300)
            end
        end
    end
end)

function HorseInfo.isVisible() return visible end
