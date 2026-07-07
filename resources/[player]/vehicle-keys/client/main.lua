local QBox = exports['qbx_core']:GetCoreObject()
local PlayerData = QBox.Functions.GetPlayerData()
local playerKeys = {}
local lockpickActive = false
local currentVehicle = nil

local function getNearestVeh()
    local pos = GetEntityCoords(PlayerPedId())
    local entityWorld = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, Config.VehicleKeys.lockRange, 0.0)
    local rayHandle = StartShapeTestCapsule(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, Config.VehicleKeys.lockRange, 10, PlayerPedId(), 4)
    local _, _, _, _, vehicleHandle = GetShapeTestResult(rayHandle)
    if vehicleHandle and DoesEntityExist(vehicleHandle) and GetEntityType(vehicleHandle) == 2 then
        return vehicleHandle
    end
    return 0
end

local function getVehiclePlate(vehicle)
    return string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
end

local function getVehicleClass(vehicle)
    return GetVehicleClass(vehicle)
end

local function getVehicleModel(vehicle)
    return GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
end

local function hasKeyForVehicle(vehicle)
    local plate = getVehiclePlate(vehicle)
    if not plate or plate == '' then return false end
    local result = lib.callback.await('vehicle-keys:checkKey', false, plate)
    return result
end

local function toggleVehicleLock(vehicle)
    local locked = GetVehicleDoorLockStatus(vehicle)
    if locked == 2 then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        TriggerEvent('qb-vehiclekeys:client:SetLock', GetVehicleNumberPlateText(vehicle), false)
        exports.ox_lib:notify({ type = 'success', description = 'Vehicle unlocked' })
    else
        SetVehicleDoorsLocked(vehicle, 2)
        SetVehicleDoorsLockedForAllPlayers(vehicle, true)
        TriggerEvent('qb-vehiclekeys:client:SetLock', GetVehicleNumberPlateText(vehicle), true)
        exports.ox_lib:notify({ type = 'info', description = 'Vehicle locked' })
    end
end

local function startLockpick(vehicle)
    if lockpickActive then return end
    lockpickActive = true
    currentVehicle = vehicle

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local class = getVehicleClass(vehicle)
    local sweetSpotSize = Config.VehicleKeys.lockpickDifficulty[class] or 0.40

    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, 'PROP_HUMAN_BUM_BIN', 0, true)
    Wait(500)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'startLockpick',
        data = {
            netId = netId,
            sweetSpotSize = sweetSpotSize,
            needleSpeed = Config.VehicleKeys.needleSpeed,
            rounds = Config.VehicleKeys.lockpickRounds,
            maxFails = Config.VehicleKeys.maxLockpickFails,
            minSweetSpot = Config.VehicleKeys.minSweetSpot,
            maxSweetSpot = Config.VehicleKeys.maxSweetSpot,
        }
    })
end

local function stopLockpick(cleanup)
    lockpickActive = false
    currentVehicle = nil
    SetNuiFocus(false, false)

    local ped = PlayerPedId()
    ClearPedTasks(ped)

    if cleanup then
        SendNUIMessage({ action = 'closeLockpick' })
    end
end

RegisterNUICallback('lockpickResult', function(data, cb)
    cb('ok')
    local success = data.success
    local netId = data.netId
    local vehicle = NetworkGetEntityFromNetworkId(netId)

    stopLockpick(true)

    if not DoesEntityExist(vehicle) then
        exports.ox_lib:notify({ type = 'error', description = 'Vehicle no longer nearby' })
        return
    end

    if success then
        TriggerServerEvent('vehicle-keys:server:lockPickSuccess', netId)
    else
        if math.random() < Config.VehicleKeys.lockpickAlarmChance then
            TriggerServerEvent('vehicle-keys:server:lockPickAlarm', netId)
        else
            TriggerServerEvent('vehicle-keys:server:lockPickFail', netId)
        end
    end
end)

RegisterNUICallback('cancelLockpick', function(_, cb)
    cb('ok')
    if currentVehicle and DoesEntityExist(currentVehicle) then
        local netId = NetworkGetNetworkIdFromEntity(currentVehicle)
        TriggerServerEvent('vehicle-keys:server:lockPickFail', netId)
    end
    stopLockpick(true)
end)

RegisterNUICallback('closeLockpick', function(_, cb)
    cb('ok')
    stopLockpick(true)
end)

--- RADIAL MENU INTEGRATION

-- Vehicle lock/unlock
local function vehicleLockAction()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped)
    if vehicle == 0 then
        vehicle = getNearestVeh()
    end
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        exports.ox_lib:notify({ type = 'error', description = 'No vehicle nearby' })
        return
    end
    if not hasKeyForVehicle(vehicle) then
        exports.ox_lib:notify({ type = 'error', description = 'You do not have keys for this vehicle' })
        return
    end
    toggleVehicleLock(vehicle)
end

-- Lockpick vehicle
local function lockpickAction()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped)
    if vehicle == 0 then
        vehicle = getNearestVeh()
    end
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        exports.ox_lib:notify({ type = 'error', description = 'No vehicle nearby' })
        return
    end

    if IsPedInAnyVehicle(ped, false) then
        exports.ox_lib:notify({ type = 'error', description = 'Get out of the vehicle first' })
        return
    end

    local hasLockpick = exports.ox_inventory:Search('count', 'lockpick') > 0
    if not hasLockpick then
        exports.ox_lib:notify({ type = 'error', description = 'You need a lockpick' })
        return
    end

    if hasKeyForVehicle(vehicle) then
        exports.ox_lib:notify({ type = 'info', description = 'You already have keys for this vehicle' })
        return
    end

    startLockpick(vehicle)
end

-- Give vehicle key to nearest player
local function giveKeyAction()
    local keys = lib.callback.await('vehicle-keys:getKeyList', false)
    if not keys or #keys == 0 then
        exports.ox_lib:notify({ type = 'error', description = 'You have no vehicle keys to give' })
        return
    end

    local closestPlayers = QBox.Functions.GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), Config.VehicleKeys.giveKeyRange)
    local target = nil
    for _, p in ipairs(closestPlayers) do
        if p ~= cache.serverId then
            target = p
            break
        end
    end
    if not target then
        exports.ox_lib:notify({ type = 'error', description = 'No players nearby' })
        return
    end

    local options = {}
    for _, k in ipairs(keys) do
        table.insert(options, { value = k.plate .. '|' .. k.model, label = k.label })
    end
    local selected = lib.inputDialog('Give Vehicle Key', {
        { type = 'select', label = 'Select Key', options = options, required = true },
    })
    if not selected then return end

    local plate, model = selected[1]:match('(.-)|(.*)')
    if plate then
        TriggerServerEvent('vehicle-keys:giveKey', plate, model, target)
    end
end

-- Create key for current vehicle (admin or owned)
local function createKeyAction()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped)
    if vehicle == 0 then
        vehicle = getNearestVeh()
    end
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        exports.ox_lib:notify({ type = 'error', description = 'No vehicle nearby' })
        return
    end
    local plate = getVehiclePlate(vehicle)
    local model = getVehicleModel(vehicle)
    TriggerServerEvent('vehicle-keys:server:createKey', plate, model)
end

EnsureRadialMenuItems = function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped)
    if vehicle == 0 then
        vehicle = getNearestVeh()
    end

    local items = {}

    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        local hasKey = hasKeyForVehicle(vehicle)
        if hasKey then
            table.insert(items, {
                id = 'vehicle_lock',
                title = 'Vehicle Lock/Unlock',
                icon = 'car',
                type = 'client',
                event = 'vehicle-keys:radial:Lock',
                shouldClose = true,
            })
        end
        if not IsPedInAnyVehicle(ped, false) then
            table.insert(items, {
                id = 'vehicle_lockpick',
                title = 'Lockpick Vehicle',
                icon = 'lock-open',
                type = 'client',
                event = 'vehicle-keys:radial:Lockpick',
                shouldClose = true,
            })
        end
    end

    table.insert(items, {
        id = 'vehicle_givekey',
        title = 'Give Vehicle Key',
        icon = 'key',
        type = 'client',
        event = 'vehicle-keys:radial:GiveKey',
        shouldClose = true,
    })

    return items
end

AddEventHandler('vehicle-keys:radial:Lock', vehicleLockAction)
AddEventHandler('vehicle-keys:radial:Lockpick', lockpickAction)
AddEventHandler('vehicle-keys:radial:GiveKey', giveKeyAction)
AddEventHandler('vehicle-keys:radial:CreateKey', createKeyAction)

-- Keybind for quick lock/unlock
RegisterCommand('vehiclelock', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped)
    if vehicle == 0 then
        vehicle = getNearestVeh()
    end
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        exports.ox_lib:notify({ type = 'error', description = 'No vehicle nearby' })
        return
    end
    if not hasKeyForVehicle(vehicle) then
        exports.ox_lib:notify({ type = 'error', description = 'You do not have keys for this vehicle' })
        return
    end
    toggleVehicleLock(vehicle)
end, false)

RegisterKeyMapping('vehiclelock', 'Lock/Unlock Vehicle (requires keys)', 'keyboard', 'l')

-- Player loaded event
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key ~= 'all' then return end
    PlayerData = val
end)

-- Exports for other resources
exports('HasKeyForVehicle', hasKeyForVehicle)
exports('ToggleVehicleLock', toggleVehicleLock)
exports('CreateKeyForVehicle', function(plate, model)
    TriggerServerEvent('vehicle-keys:server:createKey', plate, model)
end)

-- Clean up on resource stop
AddEventHandler('onClientResourceStop', function(res)
    if res == GetCurrentResourceName() then
        if lockpickActive then
            stopLockpick(false)
        end
    end
end)
