local QBox = exports['qbx-core']:GetCoreObject()
local isTowing = false
local towedVehicle = nil
local ropeHandle = nil

local function isTowVehicle(model)
    for _, v in ipairs(Config.AdvancedTow.TowingVehicles) do
        if model == GetHashKey(v) then return true end
    end
    return false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and isTowVehicle(GetEntityModel(veh)) then
            if IsControlJustPressed(0, 38) then
                if isTowing then
                    TriggerEvent('advanced-tow:detach')
                else
                    TriggerEvent('advanced-tow:attach')
                end
            end
        end
    end
end)

RegisterNetEvent('advanced-tow:attach', function()
    if isTowing then Wrappers.Notify(Locale('logistics.already_towing'), 'error') return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end
    local targetVeh = QBox.Functions.GetClosestVehicle()
    if targetVeh == 0 or targetVeh == veh then Wrappers.Notify(Locale('logistics.no_vehicle_near'), 'error') return end
    local dist = #(GetEntityCoords(veh) - GetEntityCoords(targetVeh))
    if dist > Config.AdvancedTow.MaxTowDistance then Wrappers.Notify(Locale('logistics.too_far'), 'error') return end
    Wrappers.ProgressBar({ label = Locale('logistics.attaching'), duration = Config.AdvancedTow.AttachTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        towedVehicle = targetVeh
        isTowing = true
        AttachEntityToEntity(towedVehicle, veh, 20, 0.0, -5.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        SetEntityCollision(towedVehicle, false, false)
        FreezeEntityPosition(towedVehicle, false)
        Wrappers.Notify(Locale('logistics.attached'), 'success')
        TriggerServerEvent('advanced-tow:server:attached', GetVehicleNumberPlateText(towedVehicle))
    end)
end)

RegisterNetEvent('advanced-tow:detach', function()
    if not isTowing or not towedVehicle then return end
    Wrappers.ProgressBar({ label = Locale('logistics.detaching'), duration = Config.AdvancedTow.DetachTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        DetachEntity(towedVehicle, true, true)
        SetEntityCollision(towedVehicle, true, true)
        FreezeEntityPosition(towedVehicle, false)
        SetVehicleEngineOn(towedVehicle, true, true, false)
        local plate = GetVehicleNumberPlateText(towedVehicle)
        towedVehicle = nil
        isTowing = false
        Wrappers.Notify(Locale('logistics.detached'), 'success')
        TriggerServerEvent('advanced-tow:server:detached', plate)
    end)
end)

SetTimeout(1000, function()
    exports.ox_target:addGlobalVehicle({ options = {{
        name = 'advanced_tow',
        icon = Config.AdvancedTow.TargetOptions.attach.icon,
        label = isTowing and Config.AdvancedTow.TargetOptions.detach.label or Config.AdvancedTow.TargetOptions.attach.label,
        distance = Config.AdvancedTow.TargetOptions.attach.distance,
        canInteract = function(entity)
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            return veh ~= 0 and isTowVehicle(GetEntityModel(veh))
        end,
        onSelect = function(entity)
            if isTowing then TriggerEvent('advanced-tow:detach')
            else TriggerEvent('advanced-tow:attach') end
        end
    }}})
end)
