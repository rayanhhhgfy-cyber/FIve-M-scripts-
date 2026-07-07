local QBCore = exports['qbx_core']:GetCoreObject()
local onCrutches = false

RegisterNetEvent('wasabi-crutches:client:startCrutches', function()
    onCrutches = true
    local ped = PlayerPedId()
    RequestClipSet(Config.Animations.walk)
    local attempts = 0
    while not HasClipSetLoaded(Config.Animations.walk) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if HasClipSetLoaded(Config.Animations.walk) then
        SetPedMovementClipset(ped, Config.Animations.walk, Config.Crutches.speedMultiplier)
    end
    SetRunSprintMultiplierForPlayer(PlayerId(), Config.Crutches.speedMultiplier)
    Wrappers.Notify({ type = 'info', description = 'Crutches equipped. Movement restricted.' })
end)

RegisterNetEvent('wasabi-crutches:client:stopCrutches', function()
    onCrutches = false
    local ped = PlayerPedId()
    ResetPedMovementClipset(ped, 1.0)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    Wrappers.Notify({ type = 'success', description = 'Crutches removed.' })
end)

RegisterNetEvent('ox_inventory:itemUsed', function(itemName)
    if itemName == Config.Crutches.itemName then
        local success, msg = lib.callback.await('wasabi-crutches:server:useCrutches', false)
        Wrappers.Notify({ type = success and 'success' or 'error', description = msg })
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        if onCrutches then
            if IsPedSprinting(PlayerPedId()) then
                SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
                TriggerServerEvent('wasabi-crutches:server:autoRemove')
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[wasabi-crutches] Client crutch system ready.^7')
end)

exports('IsOnCrutches', function() return onCrutches end)
