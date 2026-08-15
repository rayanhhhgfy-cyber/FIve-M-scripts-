local QBox = exports['qbx_core']:GetCoreObject()
local activeEvents = {}

local function spawnEvent(eventType)
    local eventData = Config.Events[eventType]
    if not eventData then return end
    local id = #activeEvents + 1
    activeEvents[id] = { id = id, type = eventType, data = eventData, status = 'active' }

    MySQL.insert('INSERT INTO ambient_events (event_type, event_label, status, coords) VALUES (?, ?, ?, ?)', {
        eventType, eventData.label, 'active', json.encode({ x = eventData.coords.x, y = eventData.coords.y, z = eventData.coords.z })
    })

    TriggerEvent('dispatch:clNotify', {
        dispatchCode = '10-99',
        dispatchMessage = eventData.label,
        origin = { x = eventData.coords.x, y = eventData.coords.y, z = eventData.coords.z }
    })

    TriggerClientEvent('ambient-events:client:eventSpawned', -1, activeEvents[id])
end

CreateThread(function()
    while true do
        Wait(Config.SpawnInterval or 300000)
        local types = { 'store_robbery', 'crashed_truck', 'gas_leak' }
        local randomType = types[math.random(1, #types)]
        spawnEvent(randomType)
    end
end)

RegisterNetEvent('ambient-events:server:resolveEvent', function(eventId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    if activeEvents[eventId] and activeEvents[eventId].status == 'active' then
        activeEvents[eventId].status = 'resolved'
        local reward = activeEvents[eventId].data.reward or 500
        player.Functions.AddMoney('bank', reward, 'ambient-event-reward')

        MySQL.update('UPDATE ambient_events SET status = ? WHERE id = ?', { 'resolved', eventId })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Resolved ambient event! Earned $' .. reward })
    end
end)

RegisterNetEvent('ambient-events:server:adminSpawn', function(eventType)
    local src = source
    if exports['god-dashboard'] then
        spawnEvent(eventType)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Force spawned event: ' .. tostring(eventType) })
    end
end)
