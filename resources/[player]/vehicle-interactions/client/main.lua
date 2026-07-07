local vehicle = 0
local isInVehicle = false

RegisterCommand('windows', function(source, args)
    local action = args[1]
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        Wrappers.Notify('Not in a vehicle', 'error')
        return
    end
    if action == 'up' then
        RollUpWindow(veh, 0)
        RollUpWindow(veh, 1)
        RollUpWindow(veh, 2)
        RollUpWindow(veh, 3)
        Wrappers.Notify('Windows rolled up', 'success')
    elseif action == 'down' then
        RollDownWindow(veh, 0)
        RollDownWindow(veh, 1)
        RollDownWindow(veh, 2)
        RollDownWindow(veh, 3)
        Wrappers.Notify('Windows rolled down', 'success')
    else
        Wrappers.Notify('Usage: /windows [up/down]', 'error')
    end
end)

RegisterCommand('door', function(source, args)
    local doorIdx = tonumber(args[1])
    if not doorIdx or doorIdx < 0 or doorIdx > 5 then
        local items = {}
        for i, label in ipairs(Config.VehicleInteractions.doorLabels) do
            table.insert(items, { title = label, onSelect = function() ToggleDoor(i - 1) end })
        end
        Wrappers.ContextMenu({ id = 'vehicle_doors', title = 'Toggle Door', menuItems = items })
        return
    end
    ToggleDoor(doorIdx)
end)

RegisterCommand('trunk', function()
    ToggleDoor(5)
end)

RegisterCommand('frunk', function()
    ToggleDoor(4)
end)

function ToggleDoor(idx)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        Wrappers.Notify('Not in a vehicle', 'error')
        return
    end
    if GetVehicleDoorAngleRatio(veh, idx) > 0.1 then
        SetVehicleDoorShut(veh, idx, false)
        Wrappers.Notify(Config.VehicleInteractions.doorLabels[idx + 1] .. ' closed', 'info')
    else
        SetVehicleDoorOpen(veh, idx, false, false)
        Wrappers.Notify(Config.VehicleInteractions.doorLabels[idx + 1] .. ' opened', 'info')
    end
end

--- Keybind handling
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        vehicle = GetVehiclePedIsIn(ped, false)
        local wasIn = isInVehicle
        isInVehicle = vehicle ~= 0

        if isInVehicle and IsThisModelACar(GetEntityModel(vehicle)) then
            if IsControlJustPressed(0, Config.VehicleInteractions.keybind.toggleWindow) then
                if GetVehicleWindowTint(vehicle) == 0 then
                    RollDownWindow(vehicle, 0)
                    RollDownWindow(vehicle, 1)
                    RollDownWindow(vehicle, 2)
                    RollDownWindow(vehicle, 3)
                    Wrappers.Notify('Windows down', 'info')
                else
                    RollUpWindow(vehicle, 0)
                    RollUpWindow(vehicle, 1)
                    RollUpWindow(vehicle, 2)
                    RollUpWindow(vehicle, 3)
                    Wrappers.Notify('Windows up', 'info')
                end
            end
            if IsControlJustPressed(0, Config.VehicleInteractions.keybind.toggleDoor) then
                local items = {}
                for i, label in ipairs(Config.VehicleInteractions.doorLabels) do
                    table.insert(items, { title = label, onSelect = function() ToggleDoor(i - 1) end })
                end
                Wrappers.ContextMenu({ id = 'vehicle_doors_kb', title = 'Toggle Door', menuItems = items })
            end
            if IsControlJustPressed(0, Config.VehicleInteractions.keybind.openTrunk) then
                ToggleDoor(5)
            end
            if IsControlJustPressed(0, Config.VehicleInteractions.keybind.openFrunk) then
                ToggleDoor(4)
            end
        end
    end
end)
