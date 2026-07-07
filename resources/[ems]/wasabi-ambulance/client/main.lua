local QBCore = exports['qbx_core']:GetCoreObject()
local isDown = false
local downState = nil
local bleeding = nil
local damageState = {}

RegisterNetEvent('wasabi-ambulance:client:setDownState', function(state)
    downState = state
    isDown = state ~= nil
end)

RegisterNetEvent('wasabi-ambulance:client:setBleeding', function(level)
    bleeding = level
end)

RegisterNetEvent('wasabi-ambulance:client:setDamageState', function(bodyPart, state)
    damageState[bodyPart] = state
end)

RegisterNetEvent('wasabi-ambulance:client:down', function(reason)
    isDown = true
    downState = 'injured'
    SetPedToRagdoll(PlayerPedId(), 999999, 999999, 0, 0, 0, 0)
    Wrappers.Notify({ type = 'error', description = reason or 'You are down!', duration = 5000 })
    if Config.Ambulance.emsCountForAutoRevive > 0 then
        local emsCount = lib.callback.await('wasabi-ambulance:server:getEmsCount', false)
        if emsCount < Config.Ambulance.emsCountForAutoRevive then
            SetTimeout(Config.Ambulance.autoReviveTime, function()
                if isDown then
                    TriggerServerEvent('wasabi-ambulance:server:respawnPlayer')
                end
            end)
        end
    end
end)

RegisterNetEvent('wasabi-ambulance:client:revive', function()
    isDown = false
    downState = nil
    bleeding = nil
    damageState = {}
    ClearPedTasks(PlayerPedId())
    SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
    ResetPedRagdollTimer(PlayerPedId())
end)

RegisterNetEvent('wasabi-ambulance:client:respawn', function(location)
    isDown = false
    downState = nil
    bleeding = nil
    damageState = {}
    DoScreenFadeOut(1000)
    Citizen.Wait(1000)
    SetEntityCoords(PlayerPedId(), location.coords.x, location.coords.y, location.coords.z)
    SetEntityHealth(PlayerPedId(), 150)
    DoScreenFadeIn(1000)
end)

RegisterNetEvent('wasabi-ambulance:client:heal', function()
    SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
    ClearPedTasks(PlayerPedId())
    ResetPedRagdollTimer(PlayerPedId())
end)

RegisterNetEvent('wasabi-ambulance:client:reviveRequest', function(target)
    local alert = lib.alertDialog({
        header = 'Medical Request',
        content = 'A player is requesting revival. Respond?',
        centered = true,
        cancel = true,
        labels = { confirm = 'Respond', cancel = 'Ignore' }
    })
    if alert == 'confirm' then
        TriggerServerEvent('wasabi-ambulance:server:revivePlayer', target, 'defibrillator')
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isDown then
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 75, true)
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[wasabi-ambulance] Client EMS handler ready.^7')
end)

exports('IsDown', function() return isDown end)
exports('GetDownState', function() return downState end)
exports('GetBleeding', function() return bleeding end)
exports('GetDamageState', function() return damageState end)
