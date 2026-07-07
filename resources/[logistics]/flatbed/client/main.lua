local QBox = exports['qbx-core']:GetCoreObject()
local isLoaded = false
local loadedVehicle = nil

local function isFlatbed(model) return model == GetHashKey(Config.Flatbed.VehicleModel) end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and isFlatbed(GetEntityModel(veh)) then
            if IsControlJustPressed(0, 38) then
                if isLoaded then TriggerEvent('flatbed:unload') else TriggerEvent('flatbed:load') end
            end
        end
        Citizen.Wait(0)
    end
end)

exports.ox_target:addGlobalVehicle({ options = {{
    name = 'flatbed_load',
    icon = Config.Flatbed.TargetOptions.load.icon,
    label = Config.Flatbed.TargetOptions.load.label,
    distance = Config.Flatbed.TargetOptions.load.distance,
    canInteract = function(entity)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        return veh ~= 0 and isFlatbed(GetEntityModel(veh)) and not isLoaded
    end,
    onSelect = function() TriggerEvent('flatbed:load') end
}, {
    name = 'flatbed_unload',
    icon = Config.Flatbed.TargetOptions.unload.icon,
    label = Config.Flatbed.TargetOptions.unload.label,
    distance = Config.Flatbed.TargetOptions.unload.distance,
    canInteract = function() return isLoaded end,
    onSelect = function() TriggerEvent('flatbed:unload') end
}}})

RegisterNetEvent('flatbed:load', function()
    if isLoaded then return end
    local ped = PlayerPedId()
    local flatbed = GetVehiclePedIsIn(ped, false)
    if flatbed == 0 or not isFlatbed(GetEntityModel(flatbed)) then return end
    local target = QBox.Functions.GetClosestVehicle()
    if target == 0 or target == flatbed then Wrappers.Notify(Locale('logistics.no_vehicle_near'), 'error') return end
    local dist = #(GetEntityCoords(flatbed) - GetEntityCoords(target))
    if dist > Config.Flatbed.LoadRange then Wrappers.Notify(Locale('logistics.too_far'), 'error') return end
    Wrappers.ProgressBar({ label = Locale('logistics.loading'), duration = Config.Flatbed.LoadTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        loadedVehicle = target
        isLoaded = true
        AttachEntityToEntity(loadedVehicle, flatbed, 0, Config.Flatbed.Offsets.Position.x, Config.Flatbed.Offsets.Position.y, Config.Flatbed.Offsets.Position.z, Config.Flatbed.Offsets.Rotation.x, Config.Flatbed.Offsets.Rotation.y, Config.Flatbed.Offsets.Rotation.z, false, false, false, false, 2, true)
        SetEntityCollision(loadedVehicle, false, false)
        FreezeEntityPosition(loadedVehicle, true)
        SetVehicleEngineOn(loadedVehicle, false, true, false)
        Wrappers.Notify(Locale('logistics.loaded'), 'success')
        TriggerServerEvent('flatbed:server:loaded', GetVehicleNumberPlateText(loadedVehicle))
    end)
end)

RegisterNetEvent('flatbed:unload', function()
    if not isLoaded or not loadedVehicle then return end
    Wrappers.ProgressBar({ label = Locale('logistics.unloading'), duration = Config.Flatbed.UnloadTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        DetachEntity(loadedVehicle, true, true)
        SetEntityCollision(loadedVehicle, true, true)
        FreezeEntityPosition(loadedVehicle, false)
        SetVehicleEngineOn(loadedVehicle, true, true, false)
        local plate = GetVehicleNumberPlateText(loadedVehicle)
        loadedVehicle = nil
        isLoaded = false
        Wrappers.Notify(Locale('logistics.unloaded'), 'success')
        TriggerServerEvent('flatbed:server:unloaded', plate)
    end)
end)
