local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local currentVehicle = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

local function getMyRank()
    if not playerData.job then return 0 end
    return playerData.job.grade.level or 0
end

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do
        Citizen.Wait(100)
    end
    playerData = QBox.Functions.GetPlayerData()

    for locationName, location in pairs(Config.PoliceGarage.Locations) do
        exports.ox_target:addBoxZone({
            coords = location.coords,
            size = vec3(4.0, 4.0, 3.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'garage_' .. locationName:lower(),
                    icon = Config.PoliceGarage.TargetOptions.icon,
                    label = Config.PoliceGarage.TargetOptions.label,
                    group = Config.PoliceGarage.TargetOptions.group,
                    distance = Config.PoliceGarage.TargetOptions.distance,
                    canInteract = function()
                        if Config.PoliceGarage.SpawnSettings.dutyRequired and not isOnDuty() then
                            return false, Locale('police.not_on_duty')
                        end
                        return true
                    end,
                    onSelect = function()
                        TriggerEvent('police:garage:openMenu')
                    end
                },
                {
                    name = 'garage_delete_' .. locationName:lower(),
                    icon = Config.PoliceGarage.TargetOptions.deleteIcon,
                    label = Config.PoliceGarage.TargetOptions.deleteLabel,
                    group = 'police',
                    distance = 3.0,
                    canInteract = function()
                        if not isOnDuty() then return false end
                        return currentVehicle ~= nil and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(currentVehicle)) < 10.0
                    end,
                    onSelect = function()
                        TriggerEvent('police:garage:deleteVehicle')
                    end
                }
            }
        })
    end
end)

RegisterNetEvent('police:garage:openMenu', function()
    if Config.PoliceGarage.SpawnSettings.dutyRequired and not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    local rank = getMyRank()
    local categoryItems = {}
    for catName, catData in pairs(Config.PoliceGarage.Categories) do
        if rank >= catData.rank then
            table.insert(categoryItems, {
                title = catData.label,
                description = Locale('police.rank_required', catData.rank),
                menu = 'cat_' .. catName
            })
        end
    end
    Wrappers.ContextMenu({
        id = 'police_garage_menu',
        title = Locale('police.vehicle_garage'),
        menuItems = categoryItems
    })
end)

for catName, catData in pairs(Config.PoliceGarage.Categories) do
    RegisterNetEvent('police:garage:cat_' .. catName .. ':open', function()
        local rank = getMyRank()
        if rank < catData.rank then
            Wrappers.Notify(Locale('police.rank_too_low'), 'error')
            return
        end
        local vehicleItems = {}
        for _, vData in ipairs(catData.vehicles) do
            table.insert(vehicleItems, {
                title = vData.label,
                description = Locale('police.vehicle_specs', vData.speed, vData.seats),
                onSelect = function()
                    TriggerEvent('police:garage:spawnVehicle', catName, vData.model, vData.label)
                end
            })
        end
        if #vehicleItems > 0 then
            table.insert(vehicleItems, {
                title = Locale('police.liveries'),
                onSelect = function()
                    TriggerEvent('police:garage:liveryMenu', catName, catData.vehicles[1].model)
                end
            })
        end
        Wrappers.ContextMenu({
            id = 'garage_' .. catName,
            title = catData.label,
            menuItems = vehicleItems
        })
    end)
end

RegisterNetEvent('police:garage:liveryMenu', function(catName, model)
    local liveryItems = {}
    for _, lData in ipairs(Config.PoliceGarage.Liveries) do
        table.insert(liveryItems, {
            title = lData.label,
            onSelect = function()
                Wrappers.Notify(Locale('police.livery_applied'), 'success')
                TriggerEvent('police:garage:spawnVehicle', catName, model, nil)
            end
        })
    end
    Wrappers.ContextMenu({
        id = 'livery_menu',
        title = Locale('police.select_livery'),
        menuItems = liveryItems
    })
end)

RegisterNetEvent('police:garage:spawnVehicle', function(category, model, label)
    if Config.PoliceGarage.SpawnSettings.deleteOldVehicle and currentVehicle then
        DeleteVehicle(currentVehicle)
        currentVehicle = nil
    end
    local closestLoc = nil
    local closestDist = math.huge
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    for locName, locData in pairs(Config.PoliceGarage.Locations) do
        for _, spawn in ipairs(locData.spawns) do
            local dist = #(pedCoords - spawn.coords)
            if dist < closestDist then
                closestDist = dist
                closestLoc = locData
            end
        end
    end
    if not closestLoc then
        Wrappers.Notify(Locale('police.no_garage_nearby'), 'error')
        return
    end
    Wrappers.ProgressBar({
        label = Locale('police.spawning_vehicle'),
        duration = 3000,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then return end
        QBox.Functions.SpawnVehicle(model, function(vehicle)
            currentVehicle = vehicle
            local plate = Config.PoliceGarage.SpawnSettings.platePrefix .. tostring(math.random(100, 999))
            SetVehicleNumberPlateText(vehicle, plate)
            SetVehicleBodyHealth(vehicle, Config.PoliceGarage.SpawnSettings.bodyHealth)
            SetVehicleEngineHealth(vehicle, Config.PoliceGarage.SpawnSettings.engineHealth)
            SetVehicleFuelLevel(vehicle, Config.PoliceGarage.SpawnSettings.fuelLevel)
            if Config.PoliceGarage.SpawnSettings.godMode then
                SetVehicleCanBeDamaged(vehicle, false)
            end
            if Config.PoliceGarage.SpawnSettings.spawnInside then
                TaskWarpPedIntoVehicle(ped, vehicle, -1)
            end
            TriggerServerEvent('police:garage:server:vehicleSpawned', model, plate)
            Wrappers.Notify(Locale('police.vehicle_spawned'), 'success')
        end, closestLoc.spawns[1].coords, true)
    end)
end)

RegisterNetEvent('police:garage:deleteVehicle', function()
    if not currentVehicle then
        Wrappers.Notify(Locale('police.no_vehicle'), 'error')
        return
    end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == currentVehicle then
        TaskLeaveVehicle(ped, veh, 16)
        Citizen.Wait(1000)
    end
    Wrappers.ProgressBar({
        label = Locale('police.storing_vehicle'),
        duration = 3000,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then return end
        local plate = GetVehicleNumberPlateText(currentVehicle)
        DeleteVehicle(currentVehicle)
        currentVehicle = nil
        TriggerServerEvent('police:garage:server:vehicleStored', plate)
        Wrappers.Notify(Locale('police.vehicle_stored'), 'success')
    end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) and currentVehicle then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == currentVehicle then
                local plate = GetVehicleNumberPlateText(veh)
                SetVehicleNumberPlateText(veh, plate)
            end
        end
    end
end)

--- Impound, Flip, Delete — targetable on any vehicle
Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end
    playerData = QBox.Functions.GetPlayerData()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'police_impound_vehicle',
            icon = 'fas fa-warehouse',
            label = 'Impound Vehicle',
            group = 'police',
            distance = 3.0,
            canInteract = function()
                return isOnDuty()
            end,
            onSelect = function(data)
                local vehicle = data and data.entity
                if not vehicle or not DoesEntityExist(vehicle) then
                    Wrappers.Notify('No vehicle nearby', 'error')
                    return
                end
                local plate = GetVehicleNumberPlateText(vehicle)
                if not plate or plate == '' then
                    Wrappers.Notify('Invalid plate', 'error')
                    return
                end
                local reasonItems = {}
                for _, r in ipairs(Config.PoliceGarage.ImpoundReasons) do
                    table.insert(reasonItems, { title = r.label, description = '$' .. r.fee, onSelect = function()
                        Wrappers.ProgressBar({ label = 'Impounding vehicle...', duration = 4000, useWhileDead = false, canCancel = true }, function(cancelled)
                            if cancelled then return end
                            TriggerServerEvent('impound:server:policeImpound', plate, r.id, r.fee)
                        end)
                    end })
                end
                Wrappers.ContextMenu({ id = 'impound_reason', title = 'Impound Reason', menuItems = reasonItems })
            end
        },
        {
            name = 'police_flip_vehicle',
            icon = 'fas fa-car',
            label = 'Flip Vehicle',
            group = 'police',
            distance = 3.0,
            canInteract = function()
                return isOnDuty()
            end,
            onSelect = function(data)
                local vehicle = data and data.entity
                if not vehicle or not DoesEntityExist(vehicle) then
                    Wrappers.Notify('No vehicle nearby', 'error')
                    return
                end
                local ped = PlayerPedId()
                Wrappers.ProgressBar({ label = 'Flipping vehicle...', duration = 5000, useWhileDead = false, canCancel = true }, function(cancelled)
                    if cancelled then return end
                    SetVehicleOnGroundProperly(vehicle)
                    SetEntityCoords(vehicle, GetEntityCoords(vehicle))
                    Wrappers.Notify('Vehicle flipped', 'success')
                end)
            end
        },
        {
            name = 'police_delete_vehicle',
            icon = 'fas fa-trash',
            label = 'Delete Vehicle',
            group = 'police',
            distance = 3.0,
            canInteract = function()
                return isOnDuty()
            end,
            onSelect = function(data)
                local vehicle = data and data.entity
                if not vehicle or not DoesEntityExist(vehicle) then
                    Wrappers.Notify('No vehicle nearby', 'error')
                    return
                end
                Wrappers.ProgressBar({ label = 'Removing vehicle...', duration = 3000, useWhileDead = false, canCancel = true }, function(cancelled)
                    if cancelled then return end
                    DeleteVehicle(vehicle)
                    if currentVehicle == vehicle then currentVehicle = nil end
                    Wrappers.Notify('Vehicle deleted', 'success')
                end)
            end
        }
    })
end)
