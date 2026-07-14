--[[=====================================================================
  SOVEREIGN STABLES · SERVER CORE
  ---------------------------------------------------------------------
  Boot orchestration + diagnostics. Phase 0 has no gameplay yet: it validates
  config, checks the database & dependencies, starts the module registry, and
  exposes /stables_diag so an owner can confirm a healthy install.
=====================================================================]]--

local booted = false

-- Gather a full health report used by console + /stables_diag.
local function buildReport()
    local report = { problems = {}, deps = {}, schema = { ok = false }, modules = {} }

    report.problems = Validate.run()
    report.deps     = Bridge.checkDependencies()
    report.modules  = Registry.list()

    local ok, err = Db.verifySchema()
    report.schema.ok = ok
    report.schema.err = err
    return report
end

local function printReport(report)
    print('^5==================== Sovereign Stables · Diagnostics ====================^7')
    print('Dependencies:')
    for _, d in ipairs(report.deps) do
        print(('  %s %s (%s)'):format(d.ok and '^2OK^7' or '^1MISSING^7', d.name, d.state))
    end
    print(('Database: %s%s'):format(
        report.schema.ok and '^2OK^7' or '^1FAIL^7',
        report.schema.ok and '' or (' — ' .. tostring(report.schema.err))))
    print(('Modules loaded: %d %s'):format(#report.modules,
        #report.modules > 0 and ('(' .. table.concat(report.modules, ', ') .. ')') or ''))
    if #report.problems == 0 then
        print('Config: ^2no problems found^7')
    else
        print(('Config: ^1%d problem(s)^7'):format(#report.problems))
        for _, p in ipairs(report.problems) do print('  - ' .. p) end
    end
    print('^5========================================================================^7')
end

CreateThread(function()
    -- Give dependencies a moment to start first.
    Wait(1500)
    local report = buildReport()
    printReport(report)
    Registry.start()
    booted = true
end)

-- Player-triggered diagnostics: prints to console + notifies the caller.
RegisterNetEvent(Events.RequestDiag, function()
    local src = source
    local report = buildReport()
    printReport(report)
    if #report.problems == 0 and report.schema.ok then
        Bridge.notifyCard(src, 'complete', 'Stables', Util.L('diag_ok'))
    else
        Bridge.notifyCard(src, 'failed', 'Stables', Util.L('diag_problems', #report.problems))
    end
end)

-- Console command (server console or admin): sovereign_stables diagnostics.
RegisterCommand('stables_diag', function(source)
    local report = buildReport()
    printReport(report)
    if source > 0 then
        if #report.problems == 0 and report.schema.ok then
            Bridge.notifyCard(source, 'complete', 'Stables', Util.L('diag_ok'))
        else
            Bridge.notifyCard(source, 'failed', 'Stables', Util.L('diag_problems', #report.problems))
        end
    end
end, false)

exports('isBooted', function() return booted end)
