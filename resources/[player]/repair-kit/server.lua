RegisterNetEvent('repair-kit:server:repairVehicle', function(netId)
    local src = source
    local vehicle = NetToVeh(netId)

    if not vehicle then return end

    if ox_inventory:RemoveItem(src, 'repair_kit', 1) then
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleFixed(vehicle)
        Notify(src, 'Vehicle fully repaired', 'success')
    else
        Notify(src, 'Failed to remove repair kit', 'error')
    end
end)
