--[[=====================================================================
  SOVEREIGN STABLES · HORSE CUSTOMIZER  (client)
  ---------------------------------------------------------------------
  Opens the morph panel on your brought-out horse: every Config.HorseMorph
  attribute as a live slider, previewed on the real horse as you drag, then
  saved. Shape re-applies on every spawn (client/horse.lua + client/morph.lua).

  Entry: /sovcustomize (temporary). The final gating — trainer-only, or admin
  breed-creation only at Braithwaite (Config.Stables[id].adminStable) — will
  wrap the open; the panel itself is the same either way. Gated UI is hidden,
  not greyed, so a player who can't customise simply won't get the entry point.
=====================================================================]]--

Customizer = Customizer or {}

local target, targetId = nil, nil   -- the horse entity + its DB id (for saving)

local function open()
    local a = Horse and Horse.active and Horse.active()
    if not (a and a.ent and DoesEntityExist(a.ent)) then
        pcall(function() Bridge.notify('Bring your horse out first, then customise it.') end)
        return
    end
    target, targetId = a.ent, a.id

    -- The attribute list the panel renders (config is the source of truth).
    local attrs = {}
    for _, at in ipairs(Morph.all()) do
        attrs[#attrs + 1] = { key = at.key, label = at.label, group = at.group, kind = at.kind or 'expr' }
    end
    local values = Morph.read(target)              -- current expr/toggle values
    for _, at in ipairs(Morph.all()) do            -- scale can't be read; seed default
        if at.kind == 'scale' and values[at.key] == nil then values[at.key] = 1.0 end
    end

    SetNuiFocus(true, true)
    -- Keep game input alive so LEFT-CLICK still moves the camera around the horse
    -- while the panel has the cursor (owner 2026-07-31). Sliders still work.
    pcall(function() SetNuiFocusKeepInput(true) end)
    SendNUIMessage({
        action = 'custom:open',
        name   = a.name or 'Your Horse',
        attrs  = attrs,
        groups = Config.HorseMorphGroups or {},
        values = values,
    })
end
Customizer.open = open

-- Live preview: apply one slider straight to the horse as it moves.
RegisterNUICallback('morphPreview', function(d, cb)
    if target and DoesEntityExist(target) and d and d.key then
        Morph.set(target, d.key, tonumber(d.value) or 0.0)
    end
    cb('ok')
end)

-- Save the whole set to the owned horse (server persists to sovereign_horses).
RegisterNUICallback('morphSave', function(d, cb)
    if targetId and d and type(d.values) == 'table' then
        TriggerServerEvent(Events.SaveHorseMorph, targetId, d.values)
    end
    cb('ok')
end)

RegisterNUICallback('morphClose', function(_, cb)
    pcall(function() SetNuiFocusKeepInput(false) end)
    SetNuiFocus(false, false)
    target, targetId = nil, nil
    cb('ok')
end)

-- The SERVER decides whether you may shape a horse (admin + at the admin stable).
-- It replies OpenCustomizer only if allowed — so the panel never opens for someone
-- who can't use it, and a denial explains why.
RegisterNetEvent(Events.OpenCustomizer, function() open() end)

RegisterCommand('sovcustomize', function()
    if not (Horse and Horse.active and Horse.active()) then
        pcall(function() Bridge.notify('Bring your horse out first, then customise it.') end)
        return
    end
    TriggerServerEvent(Events.RequestCustomize)
end, false)
