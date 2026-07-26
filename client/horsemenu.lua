--[[=====================================================================
  SOVEREIGN STABLES · HORSE INTERACTION MENU  (client)
  ---------------------------------------------------------------------
  Look at your horse and the game shows its name, its condition, and what you
  can do with it — lead it, water it, and (later) everything else that belongs
  on a horse rather than in a shop.

  ⚠️ THIS REPLACES client/horseinfo.lua, which drew its own 2D panel and never
  appeared (2.1 R3, I1-I7 all failed). Two lessons in that:

    1. Hand-rolled DrawText panels are fragile in RDR3 and fail SILENTLY. The
       same class of guessing that produced the contorted rider and three wrong
       health natives. When the game already has a way to show something, use it.
    2. The owner asked for the condition to sit "next to the horse's name" —
       which is a description of RDR2's own prompt group. The engine renders the
       group's label beside the entity you're looking at. So the thing they
       described and the thing that actually works are the same thing.

  So this is built on the UiPrompt group pattern already proven at the stable
  door (client/stables.lua), not on custom drawing.

  ALSO DELIBERATELY REUSABLE: Phase 3's courage number was ruled visible to the
  owner exactly this way. Add a line to `conditionLabel()` and it appears. What
  must NEVER appear here is the training repertoire — ruled never-shown.
=====================================================================]]--

HorseMenu = HorseMenu or {}

local function cfg() return (Config.UI and Config.UI.horseMenu) or {} end

-- Controls, chosen so each one's NATIVE meaning matches what we use it for —
-- the key you'd instinctively press is the key that works.
local CTRL_LEAD  = 0x5415BE48   -- INPUT_INTERACT_LOCKON_ANIMAL   (G) "interact with animal"
local CTRL_DRINK = 0x0D55A0F0   -- INPUT_INTERACT_HORSE_FEED      (R) feeding-adjacent
local CTRL_STOP  = 0xF5C4701B   -- INPUT_INTERACT_LOCKON_DETACH_HORSE (E) literally "detach horse"

local group = GetRandomIntInRange(0, 0xFFFFFF)
local pLead, pDrink, pStop
local leading = false
local drinking = false

--------------------------------------------------------------------------------
-- Prompts
--------------------------------------------------------------------------------
local function newPrompt(control, label)
    local p = UiPromptRegisterBegin()
    UiPromptSetControlAction(p, control)
    UiPromptSetText(p, CreateVarString(10, 'LITERAL_STRING', label))
    UiPromptSetStandardMode(p, true)
    UiPromptSetGroup(p, group, 0)
    UiPromptRegisterEnd(p)
    return p
end

CreateThread(function()
    pLead  = newPrompt(CTRL_LEAD,  'Lead Horse')
    pDrink = newPrompt(CTRL_DRINK, 'Let It Drink')
    pStop  = newPrompt(CTRL_STOP,  'Stop Leading')
end)

--------------------------------------------------------------------------------
-- The label beside the horse's name — this IS the info panel the owner asked
-- for. Hunger, thirst and stamina, read straight off the live care card.
--------------------------------------------------------------------------------
-- Live stamina is a CORE, not the trained stat on the storefront card. Index
-- 1 = stamina, the same attribute cores a player carries.
local function staminaPct(ped)
    local ok, v = pcall(function()
        return Citizen.InvokeNative(0x36731AC041289BB1, ped, 1)   -- GET_ATTRIBUTE_CORE_VALUE
    end)
    if ok and type(v) == 'number' then return math.max(0, math.min(100, math.floor(v))) end
    return nil
end

local function conditionLabel(a)
    local name = a.name or 'Your Horse'
    local c = Metabolism and Metabolism.card and Metabolism.card()
    local bits = {}

    if c then
        bits[#bits + 1] = ('Hunger %d%%'):format(c.hunger or 0)
        bits[#bits + 1] = ('Thirst %d%%'):format(c.thirst or 0)
    end
    local st = staminaPct(a.ent)
    if st then bits[#bits + 1] = ('Stamina %d%%'):format(st) end

    if c and c.golden then bits[#bits + 1] = 'GOLDEN' end

    if #bits == 0 then return name end
    return name .. '   ' .. table.concat(bits, '  ·  ')
end

--------------------------------------------------------------------------------
-- Leading
--------------------------------------------------------------------------------
-- ⚠️ HONEST NOTE: RDR2 has native horse leading (there's a PCF_DisablePlayerHorse
-- Leading flag and a HorseLeadingActive blackboard), but no documented native to
-- START it from script. So this is a SIMULATED lead: the horse follows at a
-- close offset at walking pace, which looks and plays like leading. If the real
-- native surfaces, swap it in here and nothing else changes.
function HorseMenu.startLead(a)
    if not (a and a.ent and DoesEntityExist(a.ent)) then return end
    leading = true
    ClearPedTasks(a.ent)
    TaskFollowToOffsetOfEntity(a.ent, PlayerPedId(), 0.8, -1.2, 0.0, 1.0, -1, 0.6, true)
    Bridge.notify(('You take %s by the reins.'):format(a.name or 'the horse'))
end

function HorseMenu.stopLead(a)
    leading = false
    if a and a.ent and DoesEntityExist(a.ent) then ClearPedTasks(a.ent) end
    Bridge.notify('You let the reins go.')
end

function HorseMenu.isLeading() return leading end

--------------------------------------------------------------------------------
-- Drinking — the real scenario, and the server decides what it's worth
--------------------------------------------------------------------------------
-- WORLD_ANIMAL_HORSE_DRINK_GROUND_DOMESTIC is RDR2's own domesticated-horse
-- drinking animation. The thirst itself is credited server-side (ReportDrank),
-- so this is the visible half of something that already worked.
local DRINK_SCENARIO = 'WORLD_ANIMAL_HORSE_DRINK_GROUND_DOMESTIC'

function HorseMenu.drink(a)
    if drinking then return end
    if not (a and a.ent and DoesEntityExist(a.ent)) then return end
    drinking = true

    -- Leading and drinking can't both drive the horse; drop the follow task.
    local wasLeading = leading
    leading = false
    ClearPedTasks(a.ent)

    pcall(function()
        TaskStartScenarioInPlace(a.ent, GetHashKey(DRINK_SCENARIO), -1, true, false, false, false)
    end)
    Bridge.notify(('%s drinks.'):format(a.name or 'Your horse'))

    CreateThread(function()
        local secs = cfg().drinkSeconds or 8
        for _ = 1, secs do
            Wait(1000)
            if not (a.ent and DoesEntityExist(a.ent)) then break end
            TriggerServerEvent(Events.ReportDrank, a.id)   -- server credits the thirst
        end
        if a.ent and DoesEntityExist(a.ent) then ClearPedTasks(a.ent) end
        drinking = false
        -- Put the reins back in your hand if you were leading it to the water.
        if wasLeading then HorseMenu.startLead(a) end
    end)
end

--------------------------------------------------------------------------------
-- The loop
--------------------------------------------------------------------------------
-- Cheap when idle: 400ms until you're actually near your own horse on foot.
local function targetHorse()
    local a = Horse and Horse.active and Horse.active()
    if not (a and a.ent and DoesEntityExist(a.ent)) then return nil end
    local ped = PlayerPedId()
    if IsPedOnMount(ped) then return a, true end     -- mounted: info only, no lead
    local d = #(GetEntityCoords(ped) - GetEntityCoords(a.ent))
    if d <= (cfg().distance or 5.0) then return a, false end
    return nil
end

-- Can the horse reach water right where it stands? Reuses the same test the
-- automatic drinking uses, so the prompt never lies about what's possible.
local function atWater(a)
    if not (Metabolism and Metabolism.atWater) then return false end
    local ok, v = pcall(Metabolism.atWater, a.ent)
    return ok and v or false
end

CreateThread(function()
    while true do
        local wait = 400
        if cfg().enabled == false or not pLead then
            wait = 1000
        else
            local a, mounted = targetHorse()
            if a then
                wait = 0
                -- What's on offer right now.
                local canLead  = (not mounted) and (not leading) and (not drinking)
                local canStop  = (not mounted) and leading and (not drinking)
                local canDrink = (not drinking) and atWater(a)

                UiPromptSetEnabled(pLead,  canLead);  UiPromptSetVisible(pLead,  canLead)
                UiPromptSetEnabled(pStop,  canStop);  UiPromptSetVisible(pStop,  canStop)
                UiPromptSetEnabled(pDrink, canDrink); UiPromptSetVisible(pDrink, canDrink)

                -- The group label is the bit that renders beside the horse —
                -- name + condition, which is exactly what was asked for.
                UiPromptSetActiveGroupThisFrame(group,
                    CreateVarString(10, 'LITERAL_STRING', conditionLabel(a)), 0, 0, 0, 0)

                if canLead  and UiPromptHasStandardModeCompleted(pLead)  then HorseMenu.startLead(a) end
                if canStop  and UiPromptHasStandardModeCompleted(pStop)  then HorseMenu.stopLead(a)  end
                if canDrink and UiPromptHasStandardModeCompleted(pDrink) then HorseMenu.drink(a)     end
            else
                if leading then leading = false end   -- horse gone / too far
            end
        end
        Wait(wait)
    end
end)
