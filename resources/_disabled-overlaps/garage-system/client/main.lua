local QBCore = exports['qbx_core']:GetCoreObject()
local PlayerData = {}
local currentGarage = nil
local menuOpen = false

local function getAllGarages()
    local all = {}
    for _, garages in pairs(Config.Garages) do
        for _, g in ipairs(garages) do
            table.insert(all, g)
        end
    end
    return all
end

local function getGarageByName(name)
    for _, garages in pairs(Config.Garages) do
        for _, g in ipairs(garages) do
            if g.name == name then return g end
        end
    end
    return nil
end

local function openGarageMenu(garageData)
    if menuOpen then return end
    menuOpen = true
    currentGarage = garageData
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openGarage',
        data = {
            garageName = garageData.name,
            garageType = garageData.type,
            slots = garageData.slots
        }
    })
end

local function closeGarageMenu()
    if not menuOpen then return end
    menuOpen = false
    currentGarage = nil
    SetNuiFocus(false, false)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

RegisterNUICallback('garageGetVehicles', function(_, cb)
    local vehicles = lib.callback.await('garage:server:getPlayerVehicles', false, currentGarage and currentGarage.name)
    cb(vehicles or {})
end)

RegisterNUICallback('garageSpawnVehicle', function(data, cb)
    local result = lib.callback.await('garage:server:spawnVehicle', false, data.plate, currentGarage and currentGarage.name)
    if result.success then
        Wrappers.Notify('Garage', 'Vehicle spawned: ' .. data.plate, 'success')
    else
        Wrappers.Notify('Garage', result.error or 'Failed to spawn vehicle', 'error')
    end
    cb(result)
end)

RegisterNUICallback('garageStoreVehicle', function(_, cb)
    local result = lib.callback.await('garage:server:storeVehicle', false, currentGarage and currentGarage.name)
    if result.success then
        Wrappers.Notify('Garage', 'Vehicle stored', 'success')
    else
        Wrappers.Notify('Garage', result.error or 'Failed to store vehicle', 'error')
    end
    cb(result)
end)

RegisterNUICallback('garageRetrieveImpound', function(data, cb)
    local result = lib.callback.await('garage:server:retrieveImpound', false, data.plate, currentGarage and currentGarage.name)
    if result.success then
        Wrappers.Notify('Garage', 'Vehicle retrieved for $' .. result.fee, 'success')
    else
        Wrappers.Notify('Garage', result.error or 'Failed to retrieve', 'error')
    end
    cb(result)
end)

RegisterNUICallback('garageClose', function(_, cb)
    closeGarageMenu()
    cb({})
end)

RegisterNUICallback('garageTrackVehicle', function(data, cb)
    local vehicles = lib.callback.await('garage:server:getPlayerVehicles', false, nil)
    for _, v in ipairs(vehicles or {}) do
        if v.plate == data.plate then
            if v.state == 'out' and v.location then
                SetNewWaypoint(v.location.x, v.location.y)
                Wrappers.Notify('Garage', 'Vehicle tracked - waypoint set', 'info')
            else
                Wrappers.Notify('Garage', 'Vehicle is stored, cannot track', 'error')
            end
            break
        end
    end
    cb({})
end)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    for _, garage in ipairs(getAllGarages()) do
        local blip = AddBlipForCoord(garage.coords.x, garage.coords.y, garage.coords.z)
        SetBlipSprite(blip, garage.blip.sprite)
        SetBlipColour(blip, garage.blip.color)
        SetBlipScale(blip, garage.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(garage.blip.label)
        EndTextCommandSetBlipName(blip)

        local options = {}
        if garage.type == 'impound' then
            table.insert(options, {
                name = 'garage_open_impound_' .. garage.name,
                label = 'Open Impound',
                icon = 'fas fa-truck-impound',
                onSelect = function() openGarageMenu(garage) end
            })
        end
        if garage.type == 'personal' or garage.type == 'apartment' then
            table.insert(options, {
                name = 'garage_open_personal_' .. garage.name,
                label = 'Open Garage',
                icon = 'fas fa-warehouse',
                onSelect = function() openGarageMenu(garage) end
            })
        end
        if garage.type == 'public' then
            table.insert(options, {
                name = 'garage_open_public_' .. garage.name,
                label = 'Open Parking',
                icon = 'fas fa-parking',
                onSelect = function() openGarageMenu(garage) end
            })
        end
        table.insert(options, {
            name = 'garage_store_' .. garage.name,
            label = 'Store Current Vehicle',
            icon = 'fas fa-arrow-down',
            onSelect = function()
                local result = lib.callback.await('garage:server:storeVehicle', false, garage.name)
                if result.success then
                    Wrappers.Notify('Garage', 'Vehicle stored', 'success')
                else
                    Wrappers.Notify('Garage', result.error or 'No vehicle nearby', 'error')
                end
            end
        })

        exports['ox_target']:addBoxZone({
            coords = garage.coords,
            size = vec3(5.0, 5.0, 3.0),
            rotation = 0,
            debug = false,
            options = options
        })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    closeGarageMenu()
end)
