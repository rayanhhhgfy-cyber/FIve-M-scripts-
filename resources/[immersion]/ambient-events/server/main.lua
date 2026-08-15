local QBox = exports['qbx_core']:GetCoreObject()
local activeEvents = {}
local eventCounter = 0

local function logEventToDB(eventType, label, coords, status)
    local coordsJson = json.encode({ x = coords.x, y = coords.y, z = coords.z })
    return MySQL.insert.await('INSERT INTO ambient_events (event_type, label, coords, status) VALUES (?, ?, ?, ?)', {
        eventType, label, coordsJson, status or 'active'
    })
end

local function spawnRandomEvent(forcedKey)
    local keys = {}
    for k in pairs(Config.AmbientEvents.Types) do table.insert(keys, k) end
    if #keys == 0 then return end

    local selectedKey = forcedKey or keys[math.random(#keys)]
    local eventConfig = Config.AmbientEvents.Types[selectedKey]
    if not eventConfig then return end

    eventCounter = eventCounter + 1
    local id = eventCounter
    local dbId = logEventToDB(selectedKey, eventConfig.label, eventConfig.coords, 'active')

    local eventData = {
        id = id,
        dbId = dbId,
        type = selectedKey,
        label = eventConfig.label,
        coords = eventConfig.coords,
        reward = eventConfig.reward or Config.AmbientEvents.RewardPayout,
        status = 'active',
        created_at = os.time()
    }
    activeEvents[id] = eventData

    -- Trigger 911 dispatch alert
    TriggerEvent('dispatch:server:call911', '[AMBIENT INCIDENT] ' .. eventConfig.label, 0, eventConfig.coords)
    TriggerClientEvent('ambient-events:client:eventSpawned', -1, eventData)
    print(string.format('^2[ambient-events] Spawned event #%d: %s^7', id, eventConfig.label))
    return eventData
end

function ResolveAmbientEvent(id, resolverSrc)
    local eventData = activeEvents[id]
    if not eventData then return false end

    eventData.status = 'resolved'
    if eventData.dbId then
        MySQL.update('UPDATE ambient_events SET status = ?, resolved_by = ? WHERE id = ?', {
            'resolved', resolverSrc or 'admin', eventData.dbId
        })
    end

    if resolverSrc and resolverSrc > 0 then
        local player = QBox.Functions.GetPlayer(resolverSrc)
        if player then
            player.Functions.AddMoney('bank', eventData.reward)
            TriggerClientEvent('ox_lib:notify', resolverSrc, { type = 'success', description = 'Resolved incident! Earned $' .. eventData.reward })
        end
    end

    TriggerClientEvent('ambient-events:client:eventResolved', -1, id)
    activeEvents[id] = nil
    return true
end

exports('SpawnAmbientEvent', spawnRandomEvent)
exports('ResolveAmbientEvent', ResolveAmbientEvent)

RegisterNetEvent('ambient-events:server:forceSpawn', function(eventType)
    local src = source
    local data = spawnRandomEvent(eventType)
    if data and src > 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Force spawned event: ' .. data.label })
    end
end)

RegisterNetEvent('ambient-events:server:resolveEvent', function(id)
    local src = source
    ResolveAmbientEvent(id, src)
end)

QBox.Functions.CreateCallback('ambient-events:server:getEvents', function(source, cb)
    local list = {}
    for _, ev in pairs(activeEvents) do
        table.insert(list, ev)
    end
    cb(list)
end)

-- Automatic loop thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.AmbientEvents.IntervalMinutes * 60 * 1000)
        local activeCount = 0
        for _ in pairs(activeEvents) do activeCount = activeCount + 1 end
        if activeCount < Config.AmbientEvents.MaxConcurrentEvents then
            spawnRandomEvent()
        end
    end
end)
