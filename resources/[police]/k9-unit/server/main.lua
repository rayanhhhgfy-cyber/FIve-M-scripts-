local activeDogPeds = {}

RegisterNetEvent('k9:server:syncDogPosition', function(unitId, coords)
    local src = source
    activeDogPeds[unitId] = { coords = coords, serverId = src, lastUpdate = os.time() }
    TriggerClientEvent('k9:client:syncDogPosition', -1, unitId, coords)
end)

RegisterNetEvent('k9:server:dogBark', function(unitId)
    local src = source
    TriggerClientEvent('k9:client:distantBark', -1, unitId)
end)

RegisterNetEvent('k9:server:searchResult', function(unitId, found, resultType)
    local src = source
    local players = QBox.Functions.GetPlayers()
    for _, p in ipairs(players) do
        local player = QBox.Functions.GetPlayer(p)
        if player and player.PlayerData.job.name == 'police' then
            if found then
                TriggerClientEvent('ox_lib:notify', p, { type = 'success', description = 'K9 alert: ' .. resultType .. ' detected' })
            end
        end
    end
end)

RegisterNetEvent('k9:server:reportApprehension', function(unitId, targetSrc)
    local src = source
    local targetPlayer = QBox.Functions.GetPlayer(targetSrc)
    if targetPlayer then
        TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'error', description = 'You have been bitten by a K-9 unit! Stay still!' })
        TriggerClientEvent('k9:client:heldByDog', targetSrc)
    end
end)

RegisterNetEvent('k9:server:dogDespawned', function(unitId)
    activeDogPeds[unitId] = nil
end)
