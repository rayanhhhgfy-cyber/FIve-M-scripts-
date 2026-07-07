local ox_inventory = exports.ox_inventory

function useRepairKit()
    local ped = cache.ped
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 then
        exports.ox_lib:notify({ type = 'error', description = 'Get out of the vehicle first' })
        return
    end

    local closestVeh = lib.getClosestVehicle(GetEntityCoords(ped), 3.0, true)

    if not closestVeh then
        exports.ox_lib:notify({ type = 'error', description = 'No vehicle nearby' })
        return
    end

    local engineHealth = GetVehicleEngineHealth(closestVeh)
    local bodyHealth = GetVehicleBodyHealth(closestVeh)

    if engineHealth >= 1000.0 and bodyHealth >= 1000.0 then
        exports.ox_lib:notify({ type = 'info', description = 'Vehicle is already fully repaired' })
        return
    end

    if not lib.progressBar({
        duration = 10000,
        label = 'Repairing vehicle...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        prop = {
            model = `prop_tool_chest_01`,
            pos = vec3(0.03, 0.03, 0.03),
            rot = vec3(0.0, 0.0, 0.0),
        },
    }) then return end

    TriggerServerEvent('repair-kit:server:repairVehicle', VehToNet(closestVeh))
end

exports('useRepairKit', useRepairKit)
