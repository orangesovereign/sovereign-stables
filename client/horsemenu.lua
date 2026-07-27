--[[=====================================================================
  SOVEREIGN STABLES · LEAD HORSE  (client)
  ---------------------------------------------------------------------
  Adds ONE thing to RDR2's own horse lock-on menu: Lead Horse.

  ⚠️ THIS FILE USED TO BE A WHOLE MENU, AND THAT WAS THE MISTAKE.
  (Rewritten 2026-07-27 after the R5 ledger went 18 pass / 17 fail.)

  I read "in the same menu as Brush, Feed, Pat, Flee" as "build a menu with
  those in it". The owner meant the opposite, and said so plainly on M10:

      "The native menu is what needs to be altered to fit our things,
       not create a new one."

  They were right, and the evidence was already in their own notes — M7:
  "G is already set as pat/calm and plays. Its native." The vanilla lock-on
  menu (Show Info / Brush / Feed / Pat) is LIVE on this server, not the dead
  greyed menu I'd assumed. So I spent a round building parallel prompts for
  things the game already does, then tried to suppress the originals. Both
  halves of that were wrong.

  What's left is the actual gap: RDR2 has no Lead entry. So we add one, to
  THEIR group, and touch nothing else.

  REMOVED, and why:
    • Brush / Feed — owner: "should only be done by double clicking on the
      item in the inventory. Not with a key toggle. Remove it from the menu."
      The item path already works (R5 Art. IV passed 5/5).
    • Pat — native, already plays on G.
    • Flee — native, already works on F.
    • Check Condition — native Show Info already does this.
=====================================================================]]--

HorseMenu = HorseMenu or {}

local function cfg() return (Config.UI and Config.UI.horseMenu) or {} end

-- ⚠️ NOT G. G is the native pat/calm and it works — binding Lead to it would
-- fight a vanilla interaction the owner explicitly wants kept. E's native
-- meaning ("detach horse") is the closest thing to letting go of one, and Lead
-- and Stop Leading share it because they are never available at the same time.
local function ctrlLead() return cfg().leadControl or 0xF5C4701B end  -- INPUT_INTERACT_LOCKON_DETACH_HORSE (E)

local pLead, pStop, pDrink
local leadGroup = nil     -- the group our prompts are currently attached to
local leading = false

-- ⚠️ R7 A1/A2: Give Water never appeared. The cause was a CONTROL COLLISION.
-- Our Drink prompt used INPUT_INTERACT_HORSE_FEED (0x0D55A0F0), which is the
-- EXACT control the vanilla "Feed" entry already holds in this same lock-on
-- group. Two prompts, one control, one group: the native one wins and ours never
-- draws. Lead works precisely because its control isn't a visible native entry.
--
-- So Drink moves to INPUT_INTERACT_OPTION2 (0x84543902), which no native horse
-- entry uses. Its key is H; while you're locked on to a horse standing right
-- next to you, the whistle that key normally does is moot. If it still clashes
-- with anything on your setup, this is one config line — Config.UI.horseMenu
-- .drinkControl — and I'll rebind it.
local function ctrlDrink() return cfg().drinkControl or 0x84543902 end  -- INPUT_INTERACT_OPTION2

--------------------------------------------------------------------------------
-- Prompts, attached to the HORSE rather than to a group of our own
--------------------------------------------------------------------------------
-- Using the horse's own entity handle as the prompt group is what puts our entry
-- inside the game's lock-on list instead of beside it. A group of our own is
-- what produced the second floating menu in R5.
--
-- R5 said "Lead is still not in the native list... That and Pat are on the
-- outside", and my own note in this file predicted the cause: the prompt was
-- held on the ENTITY HANDLE rather than on the entity's real group id. See
-- attachTo below — that is now looked up properly.
--
-- If Lead STILL renders outside after this, the next lever is
-- SetPedConfigFlag(horse, 297, true) — "enable leading" — which makes the game
-- draw its OWN lead prompt instead of ours. That would be strictly better, and
-- our prompt would then be deleted rather than kept alongside it.
local function newPrompt(control, label)
    local p = UiPromptRegisterBegin()
    UiPromptSetControlAction(p, control)
    UiPromptSetText(p, CreateVarString(10, 'LITERAL_STRING', label))
    UiPromptSetStandardMode(p, true)
    UiPromptRegisterEnd(p)
    return p
end

CreateThread(function()
    pLead  = newPrompt(ctrlLead(),  'Lead Horse')
    pStop  = newPrompt(ctrlLead(),  'Stop Leading')
    pDrink = newPrompt(ctrlDrink(), 'Give Water')
end)

-- ⚠️ THE ENTITY HANDLE IS NOT THE GROUP ID. This is what R5 got wrong.
--
-- I passed the horse's entity handle straight to UiPromptSetGroup and reasoned
-- that "attached to the entity" meant "in the entity's list". It doesn't: an
-- entity's prompt group has its own id, and there is a native whose entire job
-- is to hand it to you. Passing the handle instead quietly creates a group that
-- happens to be numbered after the entity — which is exactly what a second
-- floating menu beside the real one looks like.
--
-- _UI_PROMPT_GET_GROUP_ID_FOR_TARGET_ENTITY is the missing step. With the real
-- id, our entry goes in the vanilla lock-on list next to Show Info / Brush /
-- Feed / Pat, which is what was asked for both times.
local GET_GROUP_FOR_ENTITY = 0xB796970BD125FCE8

local function groupIdFor(ent)
    local ok, g = pcall(function()
        return Citizen.InvokeNative(GET_GROUP_FOR_ENTITY, ent, Citizen.ResultAsInteger())
    end)
    if ok and g and g ~= 0 then return g end
    return nil
end

local function attachTo(ent)
    if not (pLead and pStop and pDrink) then return end
    -- Re-asked every pass rather than cached against the entity: the group id
    -- belongs to the game's targeting, not to us, and it is not ours to assume
    -- stays put.
    local g = groupIdFor(ent)
    if not g or g == leadGroup then return end
    leadGroup = g
    UiPromptSetGroup(pLead,  g, 0)
    UiPromptSetGroup(pStop,  g, 0)
    UiPromptSetGroup(pDrink, g, 0)
end

-- Does the horse have water right where it stands? Reuses the exact test the old
-- automatic drinking used, so Give Water only appears when a drink is possible.
local function atWater(ent)
    if not (Metabolism and Metabolism.atWater) then return false end
    local ok, v = pcall(Metabolism.atWater, ent)
    return ok and v or false
end

--------------------------------------------------------------------------------
-- Leading
--------------------------------------------------------------------------------
-- TASK_LEAD_HORSE(ped, horse) — tasked on the PLAYER, not the horse, which is
-- why searching horse tasks never turned it up. Confirmed working in R4 (L1-L6
-- all passed once it was wired): rope in hand, visible to everyone around you.
local LEAD_NATIVE = 0x9A7A4A54596FE09D

function HorseMenu.startLead(a)
    if not (a and a.ent and DoesEntityExist(a.ent)) then return end
    leading = true
    ClearPedTasks(a.ent)
    Citizen.InvokeNative(LEAD_NATIVE, PlayerPedId(), a.ent)
    Bridge.notify(('You take %s by the reins.'):format(a.name or 'the horse'))
end

-- Leading is a task on the PLAYER, so that's what has to be cleared. R6 M5:
-- "Stop Leading should immediately stop the lead. Period." So the release is
-- unconditional and instant — the flag drops first, then every task that could
-- be holding the rope is cleared on both the player and the horse, so nothing
-- can re-drive it a frame later. No chip: stopping is its own feedback.
function HorseMenu.stopLead(a)
    leading = false
    local ped = PlayerPedId()
    pcall(function() ClearPedSecondaryTask(ped) end)
    pcall(function() ClearPedTasks(ped) end)
    if a and a.ent and DoesEntityExist(a.ent) then ClearPedTasks(a.ent) end
end

function HorseMenu.isLeading() return leading end

--------------------------------------------------------------------------------
-- The loop
--------------------------------------------------------------------------------
CreateThread(function()
    while true do
        local wait = 400
        if cfg().enabled == false or not pLead then
            wait = 1000
        else
            local a = Horse and Horse.active and Horse.active()
            local ped = PlayerPedId()
            if a and a.ent and DoesEntityExist(a.ent) and not IsPedOnMount(ped) then
                local d = #(GetEntityCoords(ped) - GetEntityCoords(a.ent))
                if d <= (cfg().distance or 5.0) then
                    wait = 0
                    attachTo(a.ent)

                    local canLead  = not leading
                    local canStop  = leading
                    -- Give Water is ALWAYS shown when you're locked on, not gated
                    -- on being at water. R7 hid the whole feature behind an
                    -- atWater check that could silently say "no"; a prompt that
                    -- vanishes teaches the player nothing. Now the check moves to
                    -- the PRESS: no water, and it says so.
                    local canDrink = not leading
                    UiPromptSetEnabled(pLead,  canLead);  UiPromptSetVisible(pLead,  canLead)
                    UiPromptSetEnabled(pStop,  canStop);  UiPromptSetVisible(pStop,  canStop)
                    UiPromptSetEnabled(pDrink, canDrink); UiPromptSetVisible(pDrink, canDrink)

                    if canLead and UiPromptHasStandardModeCompleted(pLead) then HorseMenu.startLead(a) end
                    if canStop and UiPromptHasStandardModeCompleted(pStop) then HorseMenu.stopLead(a) end
                    if canDrink and UiPromptHasStandardModeCompleted(pDrink) then
                        if atWater(a.ent) then
                            -- The server decides the rest: a full drink, or the
                            -- "not thirsty" chip. Name goes along for the chip.
                            TriggerServerEvent(Events.RequestDrink, a.id, a.name)
                        else
                            Bridge.notify(('There is no water here for %s.'):format(a.name or 'your horse'))
                        end
                    end
                else
                    UiPromptSetVisible(pLead,  false)
                    UiPromptSetVisible(pDrink, false)   -- too far to water it
                    -- Stop Leading survives the distance check: leading drags the
                    -- horse along with you, so you are never far from it, and a
                    -- state you can enter must stay a state you can leave.
                    UiPromptSetVisible(pStop, leading)
                end
            else
                if pLead  then UiPromptSetVisible(pLead,  false) end
                if pStop  then UiPromptSetVisible(pStop,  false) end
                if pDrink then UiPromptSetVisible(pDrink, false) end
                if leading and not (a and a.ent and DoesEntityExist(a.ent)) then leading = false end
            end
        end
        Wait(wait)
    end
end)

--------------------------------------------------------------------------------
-- ⚠️ TEMPORARY: FIND WHICH PROMPT TYPES ARE VANILLA BRUSH / FEED
--------------------------------------------------------------------------------
-- R6 M1/F1: "Feed and Brush should be removed from this list." Those are the
-- game's OWN lock-on prompts, and the only lever we have is
-- UiPromptDisablePromptTypeThisFrame(type) — 0xFC094EF26DD153FA — which must be
-- called EVERY FRAME to suppress a prompt type. Type 12 is the mount prompt; the
-- brush and feed type numbers are not documented anywhere I can find.
--
-- ⚠️ FINDING (R7 P2): a per-frame sweep of types 0-40 removed NOTHING from the
-- horse lock-on list. So UiPromptDisablePromptTypeThisFrame does not govern the
-- vanilla Brush/Feed/Pat entries — they aren't "prompt types" in the sense this
-- native disables. Removing them needs a different lever (a ped config flag, most
-- likely) which I haven't found a confirmed number for. Left in for now, but this
-- route is ruled out. The native Brush/Feed do no harm; they're just redundant
-- next to item-based care, so this is cosmetic, not a blocker.
--
--   /sovpromptprobe 1 2 3 ...   disable these type numbers each frame
--   /sovpromptprobe sweep       walk 0-40 automatically, ~2s each, printing each
--   /sovpromptprobe off         stop
local DISABLE_PROMPT_TYPE = 0xFC094EF26DD153FA
local probeTypes = {}
local sweeping = false

CreateThread(function()
    while true do
        if next(probeTypes) then
            for t in pairs(probeTypes) do
                Citizen.InvokeNative(DISABLE_PROMPT_TYPE, t)
            end
            Wait(0)
        else
            Wait(300)
        end
    end
end)

RegisterCommand('sovpromptprobe', function(_, args)
    args = args or {}
    local first = args[1]
    if not first or first == 'off' then
        probeTypes, sweeping = {}, false
        Bridge.notify('Prompt probe off.')
        return
    end
    if first == 'sweep' then
        if sweeping then return end
        sweeping = true
        Bridge.notify('Sweeping prompt types 0-40. Lock on to your horse and watch Brush/Feed.')
        CreateThread(function()
            for t = 0, 40 do
                if not sweeping then break end
                probeTypes = { [t] = true }
                print(('^3[sov_prompt]^7 now disabling type %d — is Brush or Feed gone?'):format(t))
                Wait(2000)
            end
            probeTypes, sweeping = {}, false
            print('^3[sov_prompt]^7 sweep done.')
        end)
        return
    end
    -- explicit list of numbers
    probeTypes, sweeping = {}, false
    local list = {}
    for _, s in ipairs(args) do
        local n = tonumber(s)
        if n then probeTypes[n] = true; list[#list + 1] = n end
    end
    print(('^3[sov_prompt]^7 disabling types: %s (per frame)'):format(table.concat(list, ', ')))
    Bridge.notify('See F8. Lock on to your horse.')
end, false)
