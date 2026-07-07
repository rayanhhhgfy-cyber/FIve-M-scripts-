local QBCore = exports['qbx_core']:GetCoreObject()
local flipping = false

RegisterNetEvent('vehicle-physics:client:startFlip', function(netId, flipData)
    flipping = true
    local progress = exports['ox_lib']:progressBar({
        duration = Config.Flip.flipTime,
        label = 'Flipping vehicle...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
        anim = {
            dict = 'missfinale_c2ig_11',
            clip = 'pushcar_offcliff_f'
        }
    })
    if progress then
        TriggerServerEvent('vehicle-physics:server:joinFlip', netId)
    end
    flipping = false
end)

RegisterNetEvent('vehicle-physics:client:joinFlip', function(netId, flipData)
    flipping = true
    local progress = exports['ox_lib']:progressBar({
        duration = Config.Flip.flipTime,
        label = 'Helping flip vehicle...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
        anim = {
            dict = 'missfinale_c2ig_11',
            clip = 'pushcar_offcliff_f'
        }
    })
    flipping = false
end)

RegisterNetEvent('vehicle-physics:client:doFlip', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then return end
    local coords = GetEntityCoords(entity)
    SetEntityCoords(entity, coords.x, coords.y, coords.z + 1.0)
    SetEntityRotation(entity, 0.0, 0.0, GetEntityHeading(entity), 2, true)
    SetVehicleOnGroundProperly(entity)
end)

RegisterNetEvent('vehicle-physics:client:pushVehicle', function(netId, direction, force)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then return end
    ApplyForceToEntity(entity, 1, direction.x * force, direction.y * force, direction.z * force, 0, 0, 0, 0, true, true, true, false, true)
end)

if Config.Flip.disableDefaultFlip then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(100)
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle and vehicle > 0 then
                if IsControlPressed(0, 46) and IsControlPressed(0, 22) then
                    DisableControlAction(0, 22, true)
                    DisableControlAction(0, 46, true)
                end
            end
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local vehicles = GetGamePool('CVehicle')
        for _, veh in ipairs(vehicles) do
            local dist = #(GetEntityCoords(veh) - coords)
            if dist < Config.Flip.flipRange then
                local rotation = GetEntityRotation(veh)
                if math.abs(rotation.x) > 80 or math.abs(rotation.y) > 80 then
                    exports['ox_target']:addLocalEntity(veh, {
                        {
                            name = 'flip_vehicle',
                            label = 'Flip Vehicle',
                            icon = 'fas fa-car-side',
                            distance = Config.Flip.flipRange,
                            onSelect = function()
                                local netId = NetworkGetNetworkIdFromEntity(veh)
                                local success, msg = lib.callback.await('vehicle-physics:server:startFlip', false, netId)
                                if not success then
                                    Wrappers.Notify({ type = 'error', description = msg or 'Cannot flip' })
                                end
                            end
                        },
                        {
                            name = 'push_vehicle',
                            label = 'Push Vehicle',
                            icon = 'fas fa-hand',
                            distance = Config.Push.pushRange,
                            onSelect = function()
                                local netId = NetworkGetNetworkIdFromEntity(veh)
                                local heading = GetEntityHeading(ped)
                                local direction = vector3(-math.sin(heading * math.pi / 180), math.cos(heading * math.pi / 180), 0)
                                TriggerServerEvent('vehicle-physics:server:pushVehicle', netId, direction)
                            end
                        }
                    })
                end
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[vehicle-physics] Client physics system active. GTA default flip disabled.^7')
end)

exports('IsFlipping', function() return flipping end)
