--[[=====================================================================
  SOVEREIGN STABLES · HORSE MORPH  (server persistence)
  ---------------------------------------------------------------------
  A horse's shape (Config.HorseMorph values) is stored in the SAME
  sovereign_horses.components JSON blob as tack, under a reserved `__morph`
  key (alongside `__tints`). It re-applies on every spawn (client-side), since
  none of the morph state persists on the entity.

  Only the horse's OWNER may save its shape here. Deeper gating (trainer-only,
  or admin breed-creation at Braithwaite) is enforced at the UI entry point;
  this server handler just guards ownership + sanitises the values.
=====================================================================]]--

local function readComponents(id, charid)
    local row = Db.awaitQuery('SELECT components FROM sovereign_horses WHERE id = ? AND charid = ?', { id, charid })
    if not (row and row[1]) then return nil end
    local comps = {}
    if row[1].components and row[1].components ~= '' then
        local ok, decoded = pcall(json.decode, row[1].components)
        if ok and type(decoded) == 'table' then comps = decoded end
    end
    return comps
end

-- Keep only known morph keys, coerced to numbers — never trust the client blob.
local function sanitise(values)
    local known = {}
    for _, a in ipairs(Config.HorseMorph or {}) do known[a.key] = true end
    local clean = {}
    if type(values) == 'table' then
        for k, v in pairs(values) do
            if known[k] then
                local n = tonumber(v)
                if n then clean[k] = n end
            end
        end
    end
    return clean
end

RegisterNetEvent(Events.SaveHorseMorph, function(horseId, values)
    local src = source
    horseId = tonumber(horseId)
    if not horseId then return end
    CreateThread(function()
        local charid = Bridge.getCharId(src); if not charid then return end
        local comps = readComponents(horseId, charid)
        if not comps then
            Bridge.notify(src, 'That is not your horse.'); return
        end
        comps.__morph = sanitise(values)
        Db.execute('UPDATE sovereign_horses SET components = ? WHERE id = ? AND charid = ?',
            { json.encode(comps), horseId, charid })
        Bridge.notify(src, 'Horse shape saved.')
        Util.log(('horse #%s shape saved (%d attrs) by char %s')
            :format(tostring(horseId), (function() local n=0 for _ in pairs(comps.__morph) do n=n+1 end return n end)(), tostring(charid)))
    end)
end)
