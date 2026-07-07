local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local onMission = false
local currentTarget = nil
local currentDropoff = nil
local missionVehicle = nil
local missionBlip = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBox.Functions.GetPlayerData() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(j) playerData.job = j end)

local function isTow() return playerData.job and playerData.job.name == Config.TowJob.JobName end

Citizen.CreateThread(function()
    if not QBox.Functions.GetPlayerData().citizenid then Citizen.Wait(100) end
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end
    playerData = QBox.Functions.GetPlayerData()

    exports.ox_target:addBoxZone({
        coords = Config.TowJob.Locations.Depot.coords, size = vec3(4.0, 4.0, 3.0), rotation = 0, debug = false,
        options = {{
            name = 'tow_depot', icon = Config.TowJob.TargetOptions.depot.icon,
            label = Config.TowJob.TargetOptions.depot.label, distance = Config.TowJob.TargetOptions.depot.distance,
            canInteract = function() return isTow() and not onMission end,
            onSelect = function() TriggerEvent('tow:startMission') end
        }, {
            name = 'tow_vehicle', icon = 'fas fa-car', label = 'Get Tow Truck', distance = 3.0,
            canInteract = function() return isTow() end,
            onSelect = function() TriggerEvent('tow:spawnVehicle') end
        }}
    })

    exports.ox_target:addBoxZone({
        coords = Config.TowJob.Locations.Dropoff.coords, size = vec3(6.0, 6.0, 3.0), rotation = 0, debug = false,
        options = {{
            name = 'tow_dropoff', icon = Config.TowJob.TargetOptions.dropoff.icon,
            label = Config.TowJob.TargetOptions.dropoff.label, distance = Config.TowJob.TargetOptions.dropoff.distance,
            canInteract = function() return onMission and currentDropoff ~= nil end,
            onSelect = function() TriggerEvent('tow:dropoff') end
        }}
    })
end)

RegisterNetEvent('tow:spawnVehicle', function()
    local model = Config.TowJob.VehicleModels[math.random(#Config.TowJob.VehicleModels)]
    local spawn = Config.TowJob.SpawnPoints[math.random(#Config.TowJob.SpawnPoints)]
    QBox.Functions.SpawnVehicle(model, function(veh)
        SetVehicleNumberPlateText(veh, 'TOW' .. math.random(100, 999))
        SetEntityHeading(veh, spawn.heading)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    end, spawn.coords, true)
end)

RegisterNetEvent('tow:startMission', function()
    if onMission then return end
    TriggerServerEvent('tow:server:getMission')
end)

RegisterNetEvent('tow:client:startMission', function(targetCoords, targetLabel)
    onMission = true
    currentTarget = targetCoords
    currentDropoff = Config.TowJob.Locations.Dropoff.coords
    if missionBlip then RemoveBlip(missionBlip) end
    missionBlip = AddBlipForCoord(targetCoords)
    SetBlipSprite(missionBlip, 68)
    SetBlipColour(missionBlip, 5)
    SetBlipScale(missionBlip, 1.2)
    SetBlipAsShortRange(missionBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(targetLabel)
    EndTextCommandSetBlipName(missionBlip)
    Wrappers.Notify(Locale('logistics.tow_mission', targetLabel), 'info')
    Citizen.Wait(100)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        missionVehicle = GetVehiclePedIsIn(ped, false)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if onMission and currentTarget then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - currentTarget)
            if dist < Config.TowJob.TowDistance then
                if missionBlip then RemoveBlip(missionBlip) end
                missionBlip = AddBlipForCoord(currentDropoff)
                SetBlipSprite(missionBlip, 1)
                SetBlipColour(missionBlip, 2)
                SetBlipScale(missionBlip, 1.2)
                SetBlipAsShortRange(missionBlip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName('Drop-off')
                EndTextCommandSetBlipName(missionBlip)
                Wrappers.Notify(Locale('logistics.tow_reached'), 'success')
                currentTarget = nil
            end
        end
    end
end)

RegisterNetEvent('tow:dropoff', function()
    if not onMission then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then Wrappers.Notify(Locale('logistics.in_vehicle'), 'error') return end
    Wrappers.ProgressBar({ label = Locale('logistics.dropping_off'), duration = 3000, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('tow:server:completeMission')
        onMission = false
        currentTarget = nil
        currentDropoff = nil
        if missionBlip then RemoveBlip(missionBlip) missionBlip = nil end
        Wrappers.Notify(Locale('logistics.mission_complete'), 'success')
    end)
end)
