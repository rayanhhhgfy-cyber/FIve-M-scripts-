local QBox = exports['qbx-core']:GetCoreObject()
local lockCooldown = false

RegisterCommand('+vehicleLock', function()
    if lockCooldown then return end

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    -- If inside a vehicle, lock/unlock current vehicle
    if vehicle and vehicle ~= 0 and Config.VehicleLock.AllowIfInside then
        local plate = GetVehicleNumberPlateText(vehicle)
        if not plate or plate == '' then return end
        lockCooldown = true
        QBox.Functions.TriggerCallback('vehiclelock:server:checkOwnership', function(isOwned)
            if isOwned then
                toggleLock(vehicle, plate)
            else
                Wrappers.Notify('This is not your vehicle', 'error')
            end
            Citizen.SetTimeout(1000, function() lockCooldown = false end)
        end, plate)
        return
    end

    -- On foot: find closest owned vehicle
    local closestVehicle = GetClosestVehicle(GetEntityCoords(ped), Config.VehicleLock.MaxDistance, 0, 70)
    if not closestVehicle or closestVehicle == 0 then
        Wrappers.Notify('No vehicle nearby', 'info')
        return
    end

    local plate = GetVehicleNumberPlateText(closestVehicle)
    if not plate or plate == '' then return end

    lockCooldown = true
    QBox.Functions.TriggerCallback('vehiclelock:server:checkOwnership', function(isOwned)
        if isOwned then
            toggleLock(closestVehicle, plate)
        else
            Wrappers.Notify('This is not your vehicle', 'error')
        end
        Citizen.SetTimeout(1000, function() lockCooldown = false end)
    end, plate)
end, false)

RegisterKeyMapping('+vehicleLock', 'Lock/Unlock Vehicle', 'keyboard', 'l')

local function toggleLock(vehicle, plate)
    if not DoesEntityExist(vehicle) then return end
    local currentStatus = GetVehicleDoorLockStatus(vehicle)

    if currentStatus == 1 or currentStatus == 0 then
        -- Currently unlocked → lock
        SetVehicleDoorsLocked(vehicle, 2)
        SetVehicleDoorsLockedForAllPlayers(vehicle, true)
        if Config.VehicleLock.LockHonk then
            StartVehicleHorn(vehicle, 200, 'HELDDOWN', false)
            Citizen.Wait(100)
            StartVehicleHorn(vehicle, 200, 'HELDDOWN', false)
        end
        Wrappers.Notify('Vehicle locked', 'success')
    else
        -- Currently locked → unlock
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        if Config.VehicleLock.UnlockHonk then
            StartVehicleHorn(vehicle, 300, 'HELDDOWN', false)
        end
        Wrappers.Notify('Vehicle unlocked', 'info')
    end
end
