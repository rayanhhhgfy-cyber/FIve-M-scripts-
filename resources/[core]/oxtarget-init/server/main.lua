local QBCore = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('oxtarget-init:server:lockVehicle', function(netId)
    local source = source
    if not source or not netId then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then return end
    local playerPed = GetPlayerPed(source)
    local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(entity))
    if distance > 10.0 then return end
    local plate = QBCore.Functions.GetPlate(entity)
    local isLocked = GetVehicleDoorLockStatus(entity) >= 2
    if isLocked then
        SetVehicleDoorsLocked(entity, 1)
        SetVehicleDoorsLockedForAllPlayers(entity, false)
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Vehicle unlocked' })
    else
        SetVehicleDoorsLocked(entity, 2)
        SetVehicleDoorsLockedForAllPlayers(entity, true)
        TriggerClientEvent('ox_lib:notify', source, { type = 'info', description = 'Vehicle locked' })
    end
end)

RegisterNetEvent('oxtarget-init:server:inspectPlayer', function(target)
    local source = source
    if not source or not target then return end
    local player = QBCore.Functions.GetPlayer(target)
    if not player then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Player not found' })
        return
    end
    TriggerClientEvent('chat:addMessage', source, {
        args = {
            'Player Info',
            string.format('Name: %s %s | CitizenID: %s | Phone: %s',
                player.PlayerData.charinfo.firstname,
                player.PlayerData.charinfo.lastname,
                player.PlayerData.citizenid,
                player.PlayerData.charinfo.phone)
        }
    })
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[oxtarget-init] Global target registry active.^7')
end)
