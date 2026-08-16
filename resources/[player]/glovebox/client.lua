RegisterCommand('glovebox', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        lib.notify({ type = 'error', description = 'You must be inside a vehicle to open the glovebox' })
        return
    end

    local plate = GetVehicleNumberPlateText(veh)
    -- Clean the plate of spaces
    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')

    TriggerServerEvent('glovebox:server:registerAndOpen', plate)
end, false)

RegisterCommand('glove', function()
    ExecuteCommand('glovebox')
end, false)

RegisterNetEvent('glovebox:client:radialOpen', function()
    ExecuteCommand('glovebox')
end)
