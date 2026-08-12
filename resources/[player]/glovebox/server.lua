RegisterNetEvent('glovebox:server:registerAndOpen', function(plate)
    local src = source
    local ped = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(ped, false)

    if veh == 0 then
        -- Exploit check
        return
    end

    local targetPlate = GetVehicleNumberPlateText(veh)
    targetPlate = string.gsub(targetPlate, '^%s*(.-)%s*$', '%1')

    if targetPlate ~= plate then
        -- Exploit check: Plate mismatch
        return
    end

    local stashId = 'glovebox_' .. plate

    -- Dynamically register the glovebox stash in ox_inventory
    exports.ox_inventory:RegisterStash(
        stashId,
        'Glovebox [' .. plate .. ']',
        15,    -- 15 slots
        10000, -- 10kg
        nil
    )

    -- Open the glovebox stash
    TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stashId)
end)
