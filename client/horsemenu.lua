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

local pLead, pStop
local leadGroup = nil     -- the group our prompts are currently attached to
local leading = false

-- ⚠️ GIVE WATER REMOVED (owner 2026-07-28: switched horse needs to bln_hud).
-- bln_hud has no horse-thirst to credit, so a Drink prompt has nowhere to write —
-- watering, feeding and dirt all belong to bln_hud now. The menu keeps only Lead,
-- which is a handling action, not a need. Condition (dirt/cores) shows on
-- bln_hud's HUD; Metabolism.blnMountDirt() is there if we ever want it inline.

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
    if not (pLead and pStop) then return end
    -- Re-asked every pass rather than cached against the entity: the group id
    -- belongs to the game's targeting, not to us, and it is not ours to assume
    -- stays put.
    local g = groupIdFor(ent)
    if not g or g == leadGroup then return end
    leadGroup = g
    UiPromptSetGroup(pLead, g, 0)
    UiPromptSetGroup(pStop, g, 0)
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
                    UiPromptSetEnabled(pLead, canLead);  UiPromptSetVisible(pLead, canLead)
                    UiPromptSetEnabled(pStop, canStop);  UiPromptSetVisible(pStop, canStop)

                    if canLead and UiPromptHasStandardModeCompleted(pLead) then HorseMenu.startLead(a) end
                    if canStop and UiPromptHasStandardModeCompleted(pStop) then HorseMenu.stopLead(a) end
                else
                    UiPromptSetVisible(pLead, false)
                    -- Stop Leading survives the distance check: leading drags the
                    -- horse along with you, so you are never far from it, and a
                    -- state you can enter must stay a state you can leave.
                    UiPromptSetVisible(pStop, leading)
                end
            else
                if pLead then UiPromptSetVisible(pLead, false) end
                if pStop then UiPromptSetVisible(pStop, false) end
                if leading and not (a and a.ent and DoesEntityExist(a.ent)) then leading = false end
            end
        end
        Wait(wait)
    end
end)

