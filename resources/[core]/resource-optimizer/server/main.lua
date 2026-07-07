local threadProfileData = {}
local gcRuns = 0
local totalCollectBytes = 0
local lastWarnings = {}

function GetMemoryUsageMB()
    local memInfo = collectgarbage('count')
    return memInfo / 1024
end

local function RunGarbageCollection()
    local before = GetMemoryUsageMB()
    collectgarbage('collect')
    collectgarbage('collect')
    local after = GetMemoryUsageMB()
    local freed = before - after
    gcRuns = gcRuns + 1
    totalCollectBytes = totalCollectBytes + freed
    if freed > 0 then
        print(string.format('^5[optimizer] GC run #%d: freed %.2f MB (%.2f → %.2f MB)^7', gcRuns, freed, before, after))
    end
end

local function SampleThreadUsage()
    if not Config.ThreadProfiling.enabled then return end
    local resources = GetResources()
    for i = 1, #resources do
        local resName = resources[i]
        local cpuTime = GetResourceCpuTime(resName)
        if cpuTime and cpuTime > 0 then
            if not threadProfileData[resName] then
                threadProfileData[resName] = { samples = 0, totalCpu = 0, maxCpu = 0 }
            end
            threadProfileData[resName].samples = threadProfileData[resName].samples + 1
            threadProfileData[resName].totalCpu = threadProfileData[resName].totalCpu + cpuTime
            if cpuTime > threadProfileData[resName].maxCpu then
                threadProfileData[resName].maxCpu = cpuTime
            end
            if Config.ThreadProfiling.logSlowThreads and cpuTime > Config.ThreadProfiling.slowThreshold then
                print(string.format('^3[optimizer] SLOW THREAD: %s = %.2fms^7', resName, cpuTime))
            end
        end
    end
end

local function GenerateProfileReport()
    local report = {}
    table.insert(report, '=== Thread Profile Report ===')
    local sorted = {}
    for resName, data in pairs(threadProfileData) do
        table.insert(sorted, { name = resName, avg = data.totalCpu / data.samples, max = data.maxCpu, samples = data.samples })
    end
    table.sort(sorted, function(a, b) return a.avg > b.avg end)
    for i = 1, math.min(#sorted, 20) do
        table.insert(report, string.format('%s: avg=%.2fms max=%.2fms samples=%d', sorted[i].name, sorted[i].avg, sorted[i].max, sorted[i].samples))
    end
    table.insert(report, string.format('Memory: %.2f MB | GC runs: %d | Total freed: %.2f MB', GetMemoryUsageMB(), gcRuns, totalCollectBytes))
    return table.concat(report, '\n')
end

local function CheckMemoryThresholds()
    local memUsage = GetMemoryUsageMB()
    if memUsage > Config.MemoryThresholds.actionMB then
        if not lastWarnings.action or GetGameTimer() - lastWarnings.action > 60000 then
            print(string.format('^1[optimizer] CRITICAL memory: %.2f MB — forcing deep GC^7', memUsage))
            for i = 1, 5 do
                RunGarbageCollection()
            end
            lastWarnings.action = GetGameTimer()
        end
    elseif memUsage > Config.MemoryThresholds.criticalMB then
        if not lastWarnings.critical or GetGameTimer() - lastWarnings.critical > 120000 then
            print(string.format('^3[optimizer] High memory: %.2f MB^7', memUsage))
            RunGarbageCollection()
            lastWarnings.critical = GetGameTimer()
        end
    elseif memUsage > Config.MemoryThresholds.warningMB then
        if not lastWarnings.warning or GetGameTimer() - lastWarnings.warning > 300000 then
            print(string.format('^5[optimizer] Memory warning: %.2f MB^7', memUsage))
            lastWarnings.warning = GetGameTimer()
        end
    end
end

lib.callback.register('resource-optimizer:server:getProfile', function(source)
    return GenerateProfileReport()
end)

lib.callback.register('resource-optimizer:server:forceGC', function(source)
    RunGarbageCollection()
    return GetMemoryUsageMB()
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[optimizer] Resource optimizer initialized. Targeting 0.00ms idle.^7')
    if not Config.Optimizer.enabled then return end
    SetTimeout(Config.Optimizer.gcInterval, function()
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(Config.Optimizer.gcInterval)
                RunGarbageCollection()
                CheckMemoryThresholds()
            end
        end)
    end)
    SetTimeout(Config.ThreadProfiling.sampleInterval, function()
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(Config.ThreadProfiling.sampleInterval)
                SampleThreadUsage()
            end
        end)
    end)
    SetTimeout(Config.Optimizer.reportInterval, function()
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(Config.Optimizer.reportInterval)
                local report = GenerateProfileReport()
                print('^5' .. report .. '^7')
            end
        end)
    end)
end)

AddEventHandler('playerDropped', function()
    if Config.GarbageCollection.collectOnPlayerDrop then
        RunGarbageCollection()
    end
end)

exports('GetMemoryUsageMB', GetMemoryUsageMB)
exports('ForceGC', RunGarbageCollection)
exports('GetThreadProfile', function() return threadProfileData end)
exports('GetProfileReport', GenerateProfileReport)
