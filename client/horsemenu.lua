--[[=====================================================================
  SOVEREIGN STABLES · HORSE INTERACTION MENU  (client)
  ---------------------------------------------------------------------
  Stand at your horse and RIGHT-CLICK, and the game shows its condition and what
  you can do with it — lead it, water it, and (later) everything else that
  belongs on a horse rather than in a shop.

  ⚠️ THE MENU IS GATED, NOT AMBIENT (ruled 2026-07-27). Walking past your horse
  shows its NAME and nothing else. The stats and every optional action live
  behind right-click at close range, because a prompt that hangs in the air every
  time you pass your own horse stops being information and becomes furniture.
  Right-click-to-lock-on is the gesture vanilla RDR2 already uses on animals, so
  it costs the player nothing to learn.

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
local CTRL_LEAD   = 0x5415BE48   -- INPUT_INTERACT_LOCKON_ANIMAL       (G) "interact with animal"
local CTRL_STOP   = 0xF5C4701B   -- INPUT_INTERACT_LOCKON_DETACH_HORSE (E) literally "detach horse"
local CTRL_REVEAL = 0xF8982F00   -- INPUT_INTERACT_LOCKON       (RIGHT MOUSE) vanilla lock-on

-- ⚠️ CTRL_DRINK was 0x0D55A0F0 (INPUT_INTERACT_HORSE_FEED) until 2026-07-27. That
-- input is real, and feeding-adjacent, and it has NO DEFAULT KEYBOARD BINDING —
-- so the Drink prompt would have rendered with a blank key that nothing pressed.
-- The comment said "(R)" because that's what it SHOULD have been; the hash never
-- delivered it. Verified against the RDR3 control table, not from memory.

-- The rest of the menu (R4 L1). Owner: "In the same menu as Brush, Feed, Pat,
-- Flee." Those four are RDR2's OWN lock-on prompts, and on a RedM server they
-- are permanently greyed out because the vanilla horse-care system isn't there
-- to satisfy them. So we replace them rather than sit beside them: our versions
-- go in OUR group, driven by our items, and the dead native ones are suppressed.
-- ⚠️ TWO CONSTRAINTS THE KEY LIST HAD TO BEND AROUND, both verified against the
-- RDR3 control table rather than assumed:
--
--   1. THERE IS NO "PAT" INPUT. INPUT_INTERACT_HORSE_BRUSH and _FEED exist;
--      nothing named pat, calm or soothe does. So Pat borrows a context input.
--   2. INPUT_INTERACT_HORSE_FEED (0x0D55A0F0) IS REAL BUT UNBOUND — no default
--      keyboard key. A prompt on it renders with a blank key that nothing
--      presses. That exact trap already cost us the Drink prompt once, so Feed
--      gets a key that actually exists instead of the one with the right name.
--
-- Pat and Stop Leading share E on purpose: Pat is hidden while you're leading
-- and Stop only exists while you are, so the two are never on screen together.
local CTRL_BRUSH = 0x63A38F2C   -- INPUT_INTERACT_HORSE_BRUSH        (H)
local CTRL_FEED  = 0x71F89BBC   -- INPUT_INTERACT_LOCKON_CALL_ANIMAL (R)
local CTRL_PAT   = 0xD51B784F   -- INPUT_CONTEXT_Y                   (E)
local CTRL_FLEE  = 0x4216AF06   -- INPUT_HORSE_COMMAND_FLEE          (F) as client/horse.lua

local group = GetRandomIntInRange(0, 0xFFFFFF)
-- pGive is ONE prompt on R that reads the situation: at water it offers a free
-- drink, away from water it offers food. Two prompts fighting over the same key
-- would be worse, and so would a Feed that quietly burns an apple while the
-- horse is stood in a river.
local pLead, pGive, pStop, pReveal, pBrush, pPat, pFlee
local leading = false
local drinking = false
local revealUntil = 0   -- GetGameTimer() ms; a tap latches the readout briefly

-- What the server says we can actually do, refreshed when the menu opens. The
-- prompt is only offered when it will work, so nothing is ever shown greyed out
-- for a reason the player can't see — which was the complaint about the native
-- menu in the first place.
local options = { brush = nil, feed = nil }
local optionsAskedAt = 0

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

-- The label can change between frames (Feed It / Let It Drink), so it's settable.
local function setLabel(p, text)
    UiPromptSetText(p, CreateVarString(10, 'LITERAL_STRING', text))
end

CreateThread(function()
    pLead   = newPrompt(CTRL_LEAD,   'Lead Horse')
    pGive   = newPrompt(CTRL_FEED,   'Feed It')
    pBrush  = newPrompt(CTRL_BRUSH,  'Brush It')
    pPat    = newPrompt(CTRL_PAT,    'Pat It')
    pFlee   = newPrompt(CTRL_FLEE,   'Send It Home')
    pStop   = newPrompt(CTRL_STOP,   'Stop Leading')
    pReveal = newPrompt(CTRL_REVEAL, 'Check Condition')
end)

--------------------------------------------------------------------------------
-- Suppressing RDR2's own horse prompts
--------------------------------------------------------------------------------
-- The native lock-on menu shows Brush / Feed / Pat / Flee permanently GREYED on
-- a RedM server, because the vanilla horse-care system that would satisfy them
-- isn't running. That's what the owner was looking at in R4 L1: a dead menu next
-- to our live one. Ours replaces it.
--
-- ⚠️ HONEST NOTE: flag 442 (remove the Flee prompt) is confirmed by shipping
-- resources. The rest is NOT well documented — UiPromptDisablePromptTypeThisFrame
-- takes a prompt-type number nobody has published a table for. So rather than
-- guess and claim it works, `/sovpromptprobe <n>` below lets us find the right
-- number empirically, the same way your health probe settled the wagon natives.
local function suppressNativePrompts(ent)
    if not (ent and DoesEntityExist(ent)) then return end
    pcall(function()
        Citizen.InvokeNative(0x1913FE4CBF41C463, ent, 442, true)   -- SetPedConfigFlag: no Flee prompt
    end)
    for _, t in ipairs(cfg().suppressPromptTypes or {}) do
        pcall(function() UiPromptDisablePromptTypeThisFrame(t) end)
    end
end

-- Probe: turn one prompt type off and see what disappears. `/sovpromptprobe 12`
-- then walk up to your horse. Testing aid; goes when the number is known.
local probeType = nil
RegisterCommand('sovpromptprobe', function(_, args)
    probeType = tonumber(args and args[1])
    print(('^3[sov_prompts]^7 disabling prompt type %s each frame — lock on to your horse and report what vanished.')
        :format(tostring(probeType)))
end, false)

--------------------------------------------------------------------------------
-- The label beside the horse's name — this IS the info panel the owner asked
-- for. Hunger, thirst and stamina, read straight off the live care card.
--------------------------------------------------------------------------------
-- ⚠️ THE READOUT IS NOT AMBIENT. Ruled 2026-07-27: "I shouldn't see the horse's
-- stats unless I right click near the horse, 2m." So by default the label is the
-- horse's NAME and nothing else; the numbers appear only while you're stood
-- close and holding right-click — which is exactly how vanilla RDR2 lock-on
-- works, so it's a habit players already have.
--
-- This is also the shape Phase 3's courage number needs: courage was ruled
-- "visible to the OWNER when standing at the horse and right clicking" — the
-- same gesture, the same gate. Add the line inside the `revealed` branch.
-- ⚠️ WHAT THIS DELIBERATELY DOESN'T SAY (ruled 2026-07-27):
--   • STAMINA — cut. The game already draws the horse's stamina core on screen
--     while you ride; repeating it here was duplicate information dressed up as
--     a feature.
--   • GOLDEN — cut, and switched off in config/metabolism.lua besides.
--   • The TRAINING REPERTOIRE — never shown, ruled long before either of these.
-- Courage joins this in Phase 3, behind the same gesture.
local function conditionLabel(a, revealed)
    local name = a.name or 'Your Horse'
    if not revealed then return name end

    local c = Metabolism and Metabolism.card and Metabolism.card()
    if not c then return name end

    return ('%s   Hunger %d%%  ·  Thirst %d%%'):format(name, c.hunger or 0, c.thirst or 0)
end

--------------------------------------------------------------------------------
-- Leading
--------------------------------------------------------------------------------
-- ✅ CORRECTION (2026-07-27). The first version of this was a SIMULATED lead —
-- TaskFollowToOffsetOfEntity at walking pace — because I looked for a "start
-- leading" native, didn't find one, and settled. The owner caught what that
-- actually looks like: "Unable to see when someone is leading a horse. It just
-- shows their horse following them." Which is precisely what it was.
--
-- The native exists: TASK_LEAD_HORSE(ped, horse). It is tasked on the PLAYER,
-- not the horse — which is why I never found it looking through horse tasks —
-- and it gives the real thing: rope in hand, horse at your shoulder, visible to
-- everyone around you.
--
-- Found by reading a shipping resource (cryptos_horses) rather than guessing,
-- then confirmed against the RDR3 native DB before wiring it. ⚠️ That resource
-- is GPL-3.0, which the owner has ruled out: NOTHING was copied from it. A
-- native hash is a fact about the game, not authorship — the code below is ours.
local LEAD_NATIVE = 0x9A7A4A54596FE09D   -- TASK_LEAD_HORSE(Ped ped, Ped horse)

function HorseMenu.startLead(a)
    if not (a and a.ent and DoesEntityExist(a.ent)) then return end
    local ped = PlayerPedId()
    leading = true
    ClearPedTasks(a.ent)          -- drop any wander/follow the horse was doing
    Citizen.InvokeNative(LEAD_NATIVE, ped, a.ent)
    Bridge.notify(('You take %s by the reins.'):format(a.name or 'the horse'))
end

-- Leading is a task on the PLAYER, so that's what has to be cleared. Secondary
-- first — it's the gentler cancel and leaves you walking — then the horse's own
-- tasks so it doesn't keep trailing you afterwards.
function HorseMenu.stopLead(a)
    leading = false
    local ped = PlayerPedId()
    pcall(function() ClearPedSecondaryTask(ped) end)
    pcall(function() ClearPedTasks(ped) end)
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
-- Brush · Feed · Pat  (R4 L1 — "should do what they are intended")
--------------------------------------------------------------------------------
-- Brush and Feed ask the server by KIND, not by item name. The client has no
-- business knowing what's in the satchel, and the player has no interest in
-- choosing between oats and an apple while stood at a horse. The server picks,
-- spends it through the same routine the satchel's Use goes through — so a brush
-- wears down identically either way — and the animation comes back on the reply.
function HorseMenu.brush(a)
    if not a then return end
    TriggerServerEvent(Events.RequestCareKind, a.id, 'brush')
end

function HorseMenu.feed(a)
    if not a then return end
    TriggerServerEvent(Events.RequestCareKind, a.id, 'feed')
end

-- PAT. Pure flavour — no item, no cost, no stat. It exists because the owner
-- listed it and because a horse you can only ever consume resources at is a
-- worse horse.
--
-- ⚠️ THE ONE UNVERIFIED NAME IN THIS FILE. Interaction_Brush and Interaction_Food
-- are confirmed working (they're what the care animations use). A patting
-- interaction is NOT in any table I could check, so `Interaction_Calming` is an
-- educated guess and may simply do nothing. It's wrapped so a miss is silent
-- rather than an error, and the calming EFFECT below is applied regardless — so
-- even if the animation never plays, patting still settles the horse.
local PAT_INTERACTION = 'Interaction_Calming'

function HorseMenu.pat(a)
    if not (a and a.ent and DoesEntityExist(a.ent)) then return end
    pcall(function()
        Citizen.InvokeNative(0xCD181A959CFDD7F4,          -- TASK_ANIMAL_INTERACTION
            PlayerPedId(), a.ent, GetHashKey(PAT_INTERACTION), 0, 1)
    end)
    -- Settle it, the same way the showroom horses are settled (client/preview).
    pcall(function()
        Citizen.InvokeNative(0x9FF1E042FA597187, a.ent, GetHashKey('SPOOK'), false)
    end)
    Bridge.notify(('You pat %s.'):format(a.name or 'your horse'))
end

--------------------------------------------------------------------------------
-- The loop
--------------------------------------------------------------------------------
-- Cheap when idle: 400ms until you're actually near your own horse on foot.
local function targetHorse()
    local a = Horse and Horse.active and Horse.active()
    if not (a and a.ent and DoesEntityExist(a.ent)) then return nil end
    local ped = PlayerPedId()
    if IsPedOnMount(ped) then return a, true, 0.0 end   -- mounted: no lead, no readout
    local d = #(GetEntityCoords(ped) - GetEntityCoords(a.ent))
    if d <= (cfg().distance or 5.0) then return a, false, d end
    return nil
end

-- Right-click held OR tapped. Checked disabled-side too, because aiming is often
-- suppressed near a horse and a suppressed control still reports as disabled.
local function revealPressed()
    return IsControlPressed(0, CTRL_REVEAL) or IsDisabledControlPressed(0, CTRL_REVEAL)
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
            local a, mounted, dist = targetHorse()
            if a then
                wait = 0

                -- THE GATE: on foot, inside the close radius, right-click. Holding
                -- keeps the menu open; a tap latches it for a few seconds so you
                -- can read and act without keeping the button down.
                local closeEnough = (not mounted) and dist <= (cfg().revealDistance or 2.0)
                if closeEnough and revealPressed() then
                    revealUntil = GetGameTimer() + ((cfg().revealSeconds or 5) * 1000)
                elseif not closeEnough then
                    revealUntil = 0        -- step away and it closes immediately
                end
                local revealed = GetGameTimer() < revealUntil

                -- Ask the server what's actually in the satchel the moment the
                -- menu opens (and no more than once a second while it's up), so
                -- Brush and Feed are offered only when they'd work.
                if revealed and (GetGameTimer() - optionsAskedAt) > 1000 then
                    optionsAskedAt = GetGameTimer()
                    TriggerServerEvent(Events.RequestCareOptions)
                elseif not revealed then
                    optionsAskedAt = 0
                end

                -- RDR2's own Brush/Feed/Pat/Flee prompts are dead weight on a
                -- RedM server — permanently greyed, because nothing implements
                -- them. Ours replace them.
                suppressNativePrompts(a.ent)
                if probeType then pcall(function() UiPromptDisablePromptTypeThisFrame(probeType) end) end

                -- Everything optional lives BEHIND the right-click (ruled
                -- 2026-07-27). Walk past your horse and you get its name, nothing
                -- more — no prompts hanging in the air every time you pass it.
                local busy     = drinking
                local atWet    = atWater(a)
                local canLead  = revealed and (not leading) and (not busy)
                local canBrush = revealed and (not busy) and options.brush ~= nil
                local canPat   = revealed and (not busy) and (not leading)
                local canFlee  = revealed and (not busy)
                -- ONE key, two meanings: free water beats spending an item, so at
                -- water R drinks and away from it R feeds. It never burns an
                -- apple while the horse is stood in a river.
                local canGive  = revealed and (not busy) and (atWet or options.feed ~= nil)

                -- ⚠️ THE ONE EXCEPTION. Stop Leading stays visible whenever you
                -- ARE leading, gate or no gate. It isn't ambient clutter — it's
                -- the way out of a state you're already in, and burying it would
                -- mean a player who can't put the reins down. States you can
                -- enter must always be states you can leave.
                local canStop  = (not mounted) and leading and (not busy)

                setLabel(pGive, atWet and 'Let It Drink'
                                      or ('Feed It (%s)'):format((options.feed and options.feed.label) or '—'))
                if options.brush then setLabel(pBrush, ('Brush It (%s)'):format(options.brush.label)) end

                UiPromptSetEnabled(pLead,   canLead);   UiPromptSetVisible(pLead,   canLead)
                UiPromptSetEnabled(pStop,   canStop);   UiPromptSetVisible(pStop,   canStop)
                UiPromptSetEnabled(pGive,   canGive);   UiPromptSetVisible(pGive,   canGive)
                UiPromptSetEnabled(pBrush,  canBrush);  UiPromptSetVisible(pBrush,  canBrush)
                UiPromptSetEnabled(pPat,    canPat);    UiPromptSetVisible(pPat,    canPat)
                UiPromptSetEnabled(pFlee,   canFlee);   UiPromptSetVisible(pFlee,   canFlee)
                -- The hint only exists when it would do something, and gets out
                -- of the way once the menu is up.
                local showHint = closeEnough and (not revealed)
                UiPromptSetEnabled(pReveal, showHint);  UiPromptSetVisible(pReveal, showHint)

                -- The group label is the bit that renders beside the horse: its
                -- name, and — only once revealed — its condition.
                UiPromptSetActiveGroupThisFrame(group,
                    CreateVarString(10, 'LITERAL_STRING', conditionLabel(a, revealed)), 0, 0, 0, 0)

                -- Using the menu keeps the menu open — the latch should never
                -- expire out from under someone who's actively working the horse.
                local function used()
                    revealUntil = GetGameTimer() + ((cfg().revealSeconds or 5) * 1000)
                end

                if canLead  and UiPromptHasStandardModeCompleted(pLead)  then used(); HorseMenu.startLead(a) end
                if canStop  and UiPromptHasStandardModeCompleted(pStop)  then          HorseMenu.stopLead(a)  end
                if canBrush and UiPromptHasStandardModeCompleted(pBrush) then used(); HorseMenu.brush(a)     end
                if canPat   and UiPromptHasStandardModeCompleted(pPat)   then used(); HorseMenu.pat(a)       end
                if canFlee  and UiPromptHasStandardModeCompleted(pFlee)  then          Horse.dismiss()        end
                if canGive  and UiPromptHasStandardModeCompleted(pGive)  then
                    used()
                    if atWet then HorseMenu.drink(a) else HorseMenu.feed(a) end
                end
            else
                revealUntil = 0
                if leading then leading = false end   -- horse gone / too far
            end
        end
        Wait(wait)
    end
end)

--------------------------------------------------------------------------------
-- Server → client: what the menu may offer
--------------------------------------------------------------------------------
-- The server answers RequestCareOptions with what's actually in the satchel.
-- Nil means "you have none", which is what hides the prompt — so a Brush that
-- isn't offered is a Brush you genuinely can't do, not a greyed-out mystery.
RegisterNetEvent(Events.CareOptions, function(o)
    o = o or {}
    options.brush = o.brush
    options.feed  = o.feed
end)
