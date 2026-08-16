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