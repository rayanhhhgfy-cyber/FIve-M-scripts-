local QBCore = exports['qbx_core']:GetCoreObject()

lib.callback.register('qbox-spawn:server:getSpawnLocations', function(source)
    return Config.Locations
end)

lib.callback.register('qbox-spawn:server:spawnPlayer', function(source, coords)
    if not coords or not coords.x then return false end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    local location = { x = coords.x, y = coords.y, z = coords.z, h = coords.h or 0.0 }
    TriggerClientEvent('qbox-spawn:client:doSpawn', source, location)
    return true
end)

AddEventHandler('playerConnecting', function()
    local source = source
    if not source then return end
    SetTimeout(2000, function()
        TriggerClientEvent('qbox-spawn:client:openSpawnMenu', source)
    end)
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[qbox-spawn] Cinematic spawn system ready.^7')
end)
