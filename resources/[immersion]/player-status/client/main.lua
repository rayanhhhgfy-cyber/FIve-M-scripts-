local QBCore = exports['qbx_core']:GetCoreObject()
local currentStatus = { hunger = 100, thirst = 100, stress = 0, stamina = 100 }

RegisterNetEvent('player-status:client:update', function(status)
    currentStatus = status
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if currentStatus.stress >= Config.CriticalThresholds.stress then
            local intensity = (currentStatus.stress / 100) * Config.Effects.highStress.shakeIntensity
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)
        end
        if currentStatus.stress >= 50 then
            local jitter = (currentStatus.stress / 100) * Config.Effects.highStress.aimJitter
            SetCamCoord(GetFollowCam(), jitter, jitter, 0)
        end
        if currentStatus.hunger <= Config.CriticalThresholds.hunger then
            local speedMult = Config.Effects.lowHunger.speedMalus
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0 - speedMult)
        else
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end
        if currentStatus.thirst <= Config.CriticalThresholds.thirst then
            local speedMult = Config.Effects.lowThirst.speedMalus
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0 - speedMult)
        end
        if currentStatus.stamina <= Config.CriticalThresholds.stamina then
            local speedMult = Config.Effects.lowStamina.speedMalus
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0 - speedMult)
            if IsPedSprinting(PlayerPedId()) then
                SetPedMovementClipset(PlayerPedId(), 'move_m@drunk@verydrunk', 1.0)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle and vehicle > 0 then
            local speed = GetEntitySpeed(vehicle) * 3.6
            if speed > 100 then
                TriggerServerEvent('player-status:server:addStress', Config.StressTriggers.highSpeedDriving)
            end
        end
    end
end)

AddEventHandler('ox_inventory:itemUsed', function(itemName)
    if Config.FoodItems[itemName] then
        local success = lib.callback.await('player-status:server:consumeItem', false, itemName)
        if success then
            Wrappers.Notify({ type = 'success', description = 'Consumed ' .. itemName })
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    local status = lib.callback.await('player-status:server:getStatus', false)
    if status then currentStatus = status end
    print('^2[player-status] Client status tracking active.^7')
end)

exports('GetStatus', function() return currentStatus end)
