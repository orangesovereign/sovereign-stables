--[[=====================================================================
  SOVEREIGN STABLES · TRANSFER  (client)
  ---------------------------------------------------------------------
  Offering a horse or wagon to another player, and answering when someone
  offers you one. The accept/decline gate is a lightweight confirm, so per
  the UI architecture (03-CODING-PLAN) it goes through `sovereign_menus`,
  not the branded NUI — the storefront is for rich screens.

  All the real rules (ownership, distance, caps, expiry) are server-side in
  server/transfer.lua. This file only asks and answers.
=====================================================================]]--

Transfer = Transfer or {}

-- Offer something you own to a server session id ("hat size").
function Transfer.offer(kind, assetId, targetSrc)
    targetSrc = tonumber(targetSrc)
    if not targetSrc then
        Bridge.notify('Give me their hat size.')
        return
    end
    if not assetId then
        Bridge.notify('Pick which one first.')
        return
    end
    TriggerServerEvent(Events.RequestTransfer, kind, assetId, targetSrc)
end

--------------------------------------------------------------------------------
-- Someone is handing you something
--------------------------------------------------------------------------------
RegisterNetEvent(Events.TransferOffer, function(o)
    o = o or {}
    local what = o.name or (o.kind == 'wagon' and 'a wagon' or 'a horse')

    -- Custody reads differently from a gift, and Phase 3's trainer flow will
    -- lean on this — being handed a horse to TRAIN is not the same as being
    -- given one, and the player should be able to tell at a glance.
    local title = (o.reason == 'custody') and 'Taking custody' or 'A hand over'
    local sub   = (o.reason == 'custody')
        and ('%s wants you to take %s for training.'):format(o.from or 'Someone', what)
        or  ('%s wants to give you %s.'):format(o.from or 'Someone', what)

    Bridge.openMenu({
        title    = title,
        subtitle = sub,
        footer   = o.seconds and ('Answer within %ds'):format(o.seconds) or nil,
        items = {
            { id = 'yes', label = 'Take it',   description = 'It becomes yours.' },
            { id = 'no',  label = 'Decline',   description = 'Leave it with them.' },
        },
    }, function(id)
        TriggerServerEvent(Events.RespondTransfer, id == 'yes')
    end, function()
        -- Dismissed without choosing = no. Silence is not consent when it comes
        -- to somebody else's horse ending up in your name.
        TriggerServerEvent(Events.RespondTransfer, false)
    end)
end)

RegisterNetEvent(Events.TransferResult, function(res)
    res = res or {}
    if res.ok then
        Bridge.notifyCard('success', 'Stables', res.message or 'Done.')
    else
        Bridge.notify(res.message or 'It did not go through.')
    end
end)

--------------------------------------------------------------------------------
-- Commands
--   /sovgive <hatsize>          — hand over the horse you have out
--   /sovgivewagon <hatsize>     — hand over the wagon you have out
-- The stable UI offers the same thing from a list; these are for handing over
-- the animal that is standing in front of you, which is the common case.
--------------------------------------------------------------------------------
RegisterCommand('sovgive', function(_, args)
    local a = Horse.active()
    if not a then Bridge.notify('Bring the horse out first.'); return end
    Transfer.offer('horse', a.id, args and args[1])
end, false)

RegisterCommand('sovgivewagon', function(_, args)
    local a = Wagon.active()
    if not a then Bridge.notify('Bring the wagon out first.'); return end
    Transfer.offer('wagon', a.id, args and args[1])
end, false)
