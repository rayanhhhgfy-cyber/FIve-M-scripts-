local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local currentVehicle = nil
local pendingSpawn = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.name == 'cid' and playerData.job.onduty
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

    for locationName, location in pairs(Config.CIDGarage.Locations) do
        exports.ox_target:addBoxZone({
            coords = location.coords,
            size = vec3(4.0, 4.0, 3.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'cid_garage_' .. locationName:lower(),
                    icon = Config.CIDGarage.TargetOptions.icon,
                    label = Config.CIDGarage.TargetOptions.label,
                    group = Config.CIDGarage.TargetOptions.group,
                    distance = Config.CIDGarage.TargetOptions.distance,
                    canInteract = function()
                        if Config.CIDGarage.SpawnSettings.dutyRequired and not isOnDuty() then
                            return false, 'Not on duty'
                        end
                        return true
                    end,
                    onSelect = function()
                        TriggerEvent('cid:garage:openMenu')
                    end
                },
                {
                    name = 'cid_garage_delete_' .. locationName:lower(),
                    icon = Config.CIDGarage.TargetOptions.deleteIcon,
                    label = Config.CIDGarage.TargetOptions.deleteLabel,
                    group = 'cid',
                    distance = 3.0,
                    canInteract = function()
                        if not isOnDuty() then return false end
                        return currentVehicle ~= nil and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(currentVehicle)) < 10.0
                    end,
                    onSelect = function()
                        TriggerEvent('cid:garage:deleteVehicle')
                    end
                }
            }
        })
    end
end)

RegisterNetEvent('cid:garage:openMenu', function()
    if Config.CIDGarage.SpawnSettings.dutyRequired and not isOnDuty() then
        Wrappers.Notify('Not on duty', 'error')
        return
    end
    local rank = getMyRank()
    local categoryItems = {}
    for catName, catData in pairs(Config.CIDGarage.Categories) do
        if rank >= catData.rank then
            table.insert(categoryItems, {
                title = catData.label,
                description = 'Rank required: ' .. catData.rank,
                menu = 'cid_cat_' .. catName
            })
        end
    end
    Wrappers.ContextMenu({
        id = 'cid_garage_menu',
        title = 'CID Vehicle Garage',
        menuItems = categoryItems
    })
end)

for catName, catData in pairs(Config.CIDGarage.Categories) do
    RegisterNetEvent('cid:garage:cat_' .. catName .. ':open', function()
        local rank = getMyRank()
        if rank < catData.rank then
            Wrappers.Notify('Rank too low', 'error')
            return
        end
        local vehicleItems = {}
        for _, vData in ipairs(catData.vehicles) do
            table.insert(vehicleItems, {
                title = vData.label,
                description = vData.speed .. 'mph | ' .. vData.seats .. ' seats',
                onSelect = function()
                    pendingSpawn = { category = catName, model = vData.model, label = vData.label }
                    Wrappers.ContextMenu({
                        id = 'cid_livery_choice',
                        title = 'Livery: ' .. vData.label,
                        menuItems = {
                            { title = 'Marked (CID Livery)', description = 'Full CID livery with lightbar', onSelect = function()
                                TriggerEvent('cid:garage:spawnVehicle', pendingSpawn.category, pendingSpawn.model, pendingSpawn.label, true)
                            end},
                            { title = 'Unmarked (All Black)', description = 'Stealth black, no livery', onSelect = function()
                                TriggerEvent('cid:garage:spawnVehicle', pendingSpawn.category, pendingSpawn.model, pendingSpawn.label, false)
                            end},
                        }
                    })
                end
            })
        end
        Wrappers.ContextMenu({
            id = 'cid_garage_' .. catName,
            title = catData.label,
            menuItems = vehicleItems
        })
    end)
end

RegisterNetEvent('cid:garage:spawnVehicle', function(category, model, label, useLivery)
    useLivery = (useLivery == nil) and true or useLivery
    if Config.CIDGarage.SpawnSettings.deleteOldVehicle and currentVehicle then
        DeleteVehicle(currentVehicle)
        currentVehicle = nil
    end
    local closestLoc = nil
    local closestDist = math.huge
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    for locName, locData in pairs(Config.CIDGarage.Locations) do
        for _, spawn in ipairs(locData.spawns) do
            local dist = #(pedCoords - spawn.coords)
            if dist < closestDist then
                closestDist = dist
                closestLoc = locData
            end
        end
    end
    if not closestLoc then
        Wrappers.Notify('No garage nearby', 'error')
        return
    end
    Wrappers.ProgressBar({
        label = 'Spawning vehicle...',
        duration = 3000,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then return end
        QBox.Functions.SpawnVehicle(model, function(vehicle)
            currentVehicle = vehicle
            local plate = Config.CIDGarage.SpawnSettings.platePrefix .. tostring(math.random(100, 999))
            SetVehicleNumberPlateText(vehicle, plate)
            SetVehicleBodyHealth(vehicle, Config.CIDGarage.SpawnSettings.bodyHealth)
            SetVehicleEngineHealth(vehicle, Config.CIDGarage.SpawnSettings.engineHealth)
            SetVehicleFuelLevel(vehicle, Config.CIDGarage.SpawnSettings.fuelLevel)

            if useLivery then
                SetVehicleColours(vehicle, 0, 0)
                SetVehicleExtraColours(vehicle, 0, 0)
                SetVehicleModKit(vehicle, 0)
                SetVehicleLivery(vehicle, 1)
                SetVehicleMod(vehicle, 14, 0, false)
                SetVehicleTyresCanBurst(vehicle, false)
            else
                SetVehicleColours(vehicle, 0, 0)
                SetVehicleExtraColours(vehicle, 0, 0)
                SetVehicleModKit(vehicle, 0)
                SetVehicleLivery(vehicle, 0)
                SetVehicleMod(vehicle, 14, -1, false)
                SetVehicleTyresCanBurst(vehicle, true)
            end

            if Config.CIDGarage.SpawnSettings.godMode then
                SetVehicleCanBeDamaged(vehicle, false)
            end
            if Config.CIDGarage.SpawnSettings.spawnInside then
                TaskWarpPedIntoVehicle(ped, vehicle, -1)
            end
            TriggerServerEvent('cid:garage:server:vehicleSpawned', model, plate)
            Wrappers.Notify('Vehicle spawned ' .. (useLivery and '(Marked)' or '(Unmarked)'), 'success')
        end, closestLoc.spawns[1].coords, true)
    end)
end)

RegisterNetEvent('cid:garage:deleteVehicle', function()
    if not currentVehicle then
        Wrappers.Notify('No vehicle', 'error')
        return
    end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == currentVehicle then
        TaskLeaveVehicle(ped, veh, 16)
        Citizen.Wait(1000)
    end
    Wrappers.ProgressBar({
        label = 'Storing vehicle...',
        duration = 3000,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then return end
        local plate = GetVehicleNumberPlateText(currentVehicle)
        DeleteVehicle(currentVehicle)
        currentVehicle = nil
        TriggerServerEvent('cid:garage:server:vehicleStored', plate)
        Wrappers.Notify('Vehicle stored', 'success')
    end)
end)
