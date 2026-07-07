local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local spotlightActive = false
local spotlightHandle = nil
local batteryLevel = Config.Spotlight.BatteryMax

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

RegisterCommand('+spotlight', function()
    TriggerEvent('spotlight:toggle')
end, false)

RegisterKeyMapping('+spotlight', 'Toggle Spotlight', 'keyboard', 'u')

RegisterNetEvent('spotlight:toggle', function()
    if not isOnDuty() and Config.Spotlight.RequireDuty then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if Config.Spotlight.VehicleOnly and veh == 0 then
        Wrappers.Notify(Locale('police.need_vehicle_spotlight'), 'error')
        return
    end
    if Config.Spotlight.HelicopterOnly then
        local model = GetEntityModel(veh)
        if model ~= GetHashKey('polmav') and model ~= GetHashKey('buzzard') and model ~= GetHashKey('frogger') and model ~= GetHashKey('maverick') then
            Wrappers.Notify(Locale('police.helicopter_only_spotlight'), 'error')
            return
        end
    end
    if batteryLevel <= 0 then
        Wrappers.Notify(Locale('police.spotlight_battery_dead'), 'error')
        return
    end
    spotlightActive = not spotlightActive
    if spotlightActive then
        spotlightHandle = CreateSpotlight(veh)
        Wrappers.Notify(Locale('police.spotlight_on'), 'success')
    else
        if spotlightHandle then
            DeleteEntity(spotlightHandle)
            spotlightHandle = nil
        end
        Wrappers.Notify(Locale('police.spotlight_off'), 'info')
    end
end)

local function CreateSpotlight(vehicle)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local lightHandle = CreateLight(GetHashKey('gr_heli_light_01'), coords.x, coords.y, coords.z + 3.0, true)
    if lightHandle then
        SetEntityCollision(lightHandle, false, false)
        SetEntityAlpha(lightHandle, 0, false)
        AttachEntityToEntity(lightHandle, vehicle, 0, 0.0, 0.0, 1.5, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    end
    return lightHandle
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if spotlightActive and spotlightHandle then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == 0 then
                TriggerEvent('spotlight:toggle')
                Citizen.Wait(100)
            end
            local camCoords = GetGameplayCamCoord()
            local camDir = GetCamForwardVector()
            local targetCoords = camCoords + camDir * Config.Spotlight.MaxRange
            local hit, hitCoords = GetShapeTestResult(StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetCoords.x, targetCoords.y, targetCoords.z, -1, ped, 0))
            local lightTarget = hit == 1 and hitCoords or targetCoords
            SetEntityCoords(spotlightHandle, lightTarget.x, lightTarget.y, lightTarget.z)
            DrawLightWithRange(lightTarget.x, lightTarget.y, lightTarget.z, Config.Spotlight.LightColor.r, Config.Spotlight.LightColor.g, Config.Spotlight.LightColor.b, Config.Spotlight.LightRadius, Config.Spotlight.LightIntensity)
            batteryLevel = math.max(0, batteryLevel - Config.Spotlight.BatteryDrainRate / 60)
            if batteryLevel <= 0 then
                TriggerEvent('spotlight:toggle')
                Wrappers.Notify(Locale('police.spotlight_battery_dead'), 'error')
            end
        else
            Citizen.Wait(500)
        end
        Citizen.Wait(0)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if spotlightHandle then
            DeleteEntity(spotlightHandle)
        end
    end
end)
