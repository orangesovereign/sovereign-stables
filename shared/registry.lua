--[[=====================================================================
  SOVEREIGN STABLES · MODULE REGISTRY  (expansion backbone)
  ---------------------------------------------------------------------
  Features register themselves as MODULES with optional lifecycle hooks.
  The core never needs to know a module exists — it just broadcasts events
  and each module reacts. This is what makes future feature packs drop-in.

  A module is a table:
    Registry.register({
      name = 'metabolism',
      deps = { 'persistence' },        -- optional; warns if missing
      onInit = function() end,          -- resource start
      onPlayerLoaded = function(src) end,
      onHorseSpawned = function(ctx) end,
      -- any custom hook name works; call it with Registry.emit('hookName', ...)
    })
=====================================================================]]--

Registry = Registry or {}

local modules = {}
local order   = {}   -- registration order = call order
local started = false

function Registry.register(mod)
    assert(type(mod) == 'table' and mod.name, 'Registry.register needs a table with a .name')
    if modules[mod.name] then
        Util.warn(('module "%s" registered twice; keeping the first'):format(mod.name))
        return
    end
    modules[mod.name] = mod
    order[#order + 1] = mod.name
    if started and mod.onInit then mod.onInit() end   -- late registration still inits
    Util.log(('module registered: %s'):format(mod.name))
end

function Registry.get(name) return modules[name] end
function Registry.has(name) return modules[name] ~= nil end

-- Fire a hook on every module that implements it. Errors are isolated so one
-- bad module can't take down the rest.
function Registry.emit(hook, ...)
    for i = 1, #order do
        local mod = modules[order[i]]
        local fn = mod[hook]
        if type(fn) == 'function' then
            local ok, err = pcall(fn, ...)
            if not ok then
                Util.err(('module "%s" hook "%s" failed: %s'):format(mod.name, hook, err))
            end
        end
    end
end

-- Called once by core after config validation. Checks declared deps, then inits.
function Registry.start()
    if started then return end
    for i = 1, #order do
        local mod = modules[order[i]]
        for _, dep in ipairs(mod.deps or {}) do
            if not modules[dep] then
                Util.warn(('module "%s" wants missing module "%s"'):format(mod.name, dep))
            end
        end
    end
    started = true
    Registry.emit('onInit')
    Util.log(('registry started with %d module(s)'):format(#order))
end

function Registry.list()
    local names = {}
    for i = 1, #order do names[i] = order[i] end
    return names
end
