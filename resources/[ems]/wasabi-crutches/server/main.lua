local QBCore = exports['qbx_core']:GetCoreObject()
local activeCrutchUsers = {}

lib.callback.register('wasabi-crutches:server:useCrutches', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'No player' end
    local hasItem = exports['ox_inventory']:Search(source, 'count', Config.Crutches.itemName)
    if not hasItem or hasItem < 1 then
        return false, 'No crutches'
    end
    if activeCrutchUsers[source] then
        return false, 'Already using crutches'
    end
    activeCrutchUsers[source] = GetGameTimer()
    TriggerClientEvent('wasabi-crutches:client:startCrutches', source)
    return true, 'Crutches equipped'
end)

lib.callback.register('wasabi-crutches:server:removeCrutches', function(source)
    if not activeCrutchUsers[source] then return false end
    activeCrutchUsers[source] = nil
    TriggerClientEvent('wasabi-crutches:client:stopCrutches', source)
    return true
end)

RegisterNetEvent('wasabi-crutches:server:autoRemove', function()
    local source = source
    if not source then return end
    activeCrutchUsers[source] = nil
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[wasabi-crutches] Crutch system active.^7')
end)

exports('IsOnCrutches', function(source) return activeCrutchUsers[source] ~= nil end)
