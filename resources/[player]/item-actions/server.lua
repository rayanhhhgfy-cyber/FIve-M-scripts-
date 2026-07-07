RegisterNetEvent('item-actions:server:cuffPlayer', function(targetSrc)
    local src = source
    TriggerClientEvent('police:client:CuffPlayerSoft', targetSrc)
end)

RegisterNetEvent('item-actions:server:breachDoor', function(netId)
    local vehicle = NetToVeh(netId)
    if vehicle then
        SetVehicleDoorBroken(vehicle, 0, true)
        SetVehicleDoorBroken(vehicle, 1, true)
        SetVehicleDoorBroken(vehicle, 2, true)
        SetVehicleDoorBroken(vehicle, 3, true)
    end
end)
