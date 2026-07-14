--[[=====================================================================
  SOVEREIGN STABLES · DATABASE LAYER
  ---------------------------------------------------------------------
  Thin wrapper over oxmysql (VORP's database driver). All SQL lives behind
  this file so schema changes and query tuning stay in one place. Schema is
  created by sql/install.sql; this layer reads/writes it.
=====================================================================]]--

Db = Db or {}

local function hasOx() return GetResourceState('oxmysql') == 'started' end

-- Callback-style helpers -------------------------------------------------------
function Db.query(sql, params, cb)
    if not hasOx() then Util.err('oxmysql not started; DB call ignored'); if cb then cb({}) end return end
    exports.oxmysql:query(sql, params or {}, cb)
end

function Db.execute(sql, params, cb)
    if not hasOx() then Util.err('oxmysql not started; DB call ignored'); if cb then cb(0) end return end
    exports.oxmysql:execute(sql, params or {}, cb)
end

function Db.insert(sql, params, cb)
    if not hasOx() then Util.err('oxmysql not started; DB call ignored'); if cb then cb(nil) end return end
    exports.oxmysql:insert(sql, params or {}, cb)
end

-- Await-style helpers (use inside citizen threads) -----------------------------
function Db.awaitQuery(sql, params)
    local p = promise.new()
    Db.query(sql, params, function(res) p:resolve(res or {}) end)
    return Citizen.Await(p)
end

function Db.awaitInsert(sql, params)
    local p = promise.new()
    Db.insert(sql, params, function(id) p:resolve(id) end)
    return Citizen.Await(p)
end

-- Boot check: confirm the core table exists so we fail loud, not silent.
function Db.verifySchema()
    if not hasOx() then return false, 'oxmysql not started' end
    local res = Db.awaitQuery("SHOW TABLES LIKE 'sovereign_horses'")
    if not res or #res == 0 then
        return false, "table 'sovereign_horses' missing — import sql/install.sql"
    end
    return true
end
