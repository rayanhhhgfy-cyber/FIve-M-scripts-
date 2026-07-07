local QBox = exports['qbx_core']:GetCoreObject()
local jobProgress = {}
local towCalls = {}
local callCounter = 0

local function isOnJob(src, jobName)
    local p = QBox.Functions.GetPlayer(src)
    return p and p.PlayerData.job.name == jobName and p.PlayerData.job.onduty
end

--- Bus Driver
RegisterNetEvent('civilianjobs:busCompleteStop', function(routeId, stopIndex)
    local src = source
    if not isOnJob(src, Config.CivilianJobs.busDriver.jobName) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local route = nil
    for _, r in ipairs(Config.CivilianJobs.busDriver.routes) do
        if r.id == routeId then route = r; break end
    end
    if not route then return end
    local cid = p.PlayerData.citizenid
    if not jobProgress[cid] then jobProgress[cid] = { bus = { route = routeId, stops = 0 } } end
    if not jobProgress[cid].bus then jobProgress[cid].bus = { route = routeId, stops = 0 } end
    jobProgress[cid].bus.stops = stopIndex
    if stopIndex >= #route.stops then
        -- route complete
        p.Functions.AddMoney('cash', route.pay)
        jobProgress[cid].bus = nil
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Route complete! Earned $' .. route.pay })
        TriggerClientEvent('civilianjobs:routeDone', src)
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Stop ' .. stopIndex .. '/' .. #route.stops .. ' - continue to next' })
    end
end)

--- Garbage Collector
RegisterNetEvent('civilianjobs:garbageCollect', function(stopIndex)
    local src = source
    if not isOnJob(src, Config.CivilianJobs.garbageCollector.jobName) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    p.Functions.AddMoney('cash', Config.CivilianJobs.garbageCollector.payPerStop)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Garbage collected! +$' .. Config.CivilianJobs.garbageCollector.payPerStop })
    local cid = p.PlayerData.citizenid
    if not jobProgress[cid] then jobProgress[cid] = {} end
    jobProgress[cid].garbage = (jobProgress[cid].garbage or 0) + 1
    if stopIndex >= #Config.CivilianJobs.garbageCollector.stops then
        local bonus = 200
        p.Functions.AddMoney('cash', bonus)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'All stops done! Bonus: +$' .. bonus })
        jobProgress[cid].garbage = 0
        TriggerClientEvent('civilianjobs:routeDone', src)
    end
end)

--- Mail Carrier
RegisterNetEvent('civilianjobs:mailDeliver', function(routeId, deliveryIndex)
    local src = source
    if not isOnJob(src, Config.CivilianJobs.mailCarrier.jobName) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local route = nil
    for _, r in ipairs(Config.CivilianJobs.mailCarrier.routes) do
        if r.id == routeId then route = r; break end
    end
    if not route then return end
    p.Functions.AddMoney('cash', Config.CivilianJobs.mailCarrier.payPerDelivery)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Mail delivered! +$' .. Config.CivilianJobs.mailCarrier.payPerDelivery })
    local cid = p.PlayerData.citizenid
    if not jobProgress[cid] then jobProgress[cid] = {} end
    jobProgress[cid].mail = (jobProgress[cid].mail or 0) + 1
    if deliveryIndex >= #route.deliveries then
        local bonus = 300
        p.Functions.AddMoney('cash', bonus)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Route complete! Bonus: +$' .. bonus })
        jobProgress[cid].mail = 0
        TriggerClientEvent('civilianjobs:routeDone', src)
    end
end)

--- Tow Truck
RegisterNetEvent('civilianjobs:requestTow', function(location)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    callCounter = callCounter + 1
    local callId = 'TOW-' .. callCounter
    if p.Functions.RemoveMoney('cash', Config.CivilianJobs.towTruck.callPrice) then
        towCalls[callId] = { caller = src, callerCid = p.PlayerData.citizenid, callerName = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname, location = location, status = 'pending' }
        -- notify nearby tow drivers
        local players = QBox.Functions.GetPlayers()
        for _, s in ipairs(players) do
            local pl = QBox.Functions.GetPlayer(s)
            if pl and pl.PlayerData.job.name == Config.CivilianJobs.towTruck.jobName and pl.PlayerData.job.onduty then
                TriggerClientEvent('civilianjobs:towCallNotification', s, callId, location, p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname)
            end
        end
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Tow requested ($' .. Config.CivilianJobs.towTruck.callPrice .. ')' })
    end
end)

RegisterNetEvent('civilianjobs:acceptTow', function(callId)
    local src = source
    if not isOnJob(src, Config.CivilianJobs.towTruck.jobName) then return end
    local call = towCalls[callId]
    if not call or call.status ~= 'pending' then return end
    call.status = 'accepted'
    call.driver = src
    TriggerClientEvent('civilianjobs:towGPS', src, call.location)
    TriggerClientEvent('ox_lib:notify', call.caller, { type = 'info', description = 'Tow driver is on the way' })
end)

RegisterNetEvent('civilianjobs:completeTow', function(callId)
    local src = source
    if not isOnJob(src, Config.CivilianJobs.towTruck.jobName) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local call = towCalls[callId]
    if not call then return end
    p.Functions.AddMoney('cash', Config.CivilianJobs.towTruck.payPerTow)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Tow complete! +$' .. Config.CivilianJobs.towTruck.payPerTow })
    towCalls[callId] = nil
end)

QBox.Functions.CreateCallback('civilianjobs:getJobProgress', function(source, cb)
    local p = QBox.Functions.GetPlayer(source)
    if not p then cb({}) return end
    cb(jobProgress[p.PlayerData.citizenid] or {})
end)
