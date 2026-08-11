local interactiveObjects = {}

function GetHash(model)
    if type(model) == 'number' then
        return model
    elseif type(model) == 'string' then
        return joaat(model)
    else
        return 0
    end
end

RegisterNetEvent('map-builder:client:registerInteractiveProp', function(propData, netId)
    local hash = GetHash(propData.model)
    local model = propData.model
    local logic = propData.logic
    if not logic then return end

    local id = propData.id
    local coords = vector3(propData.coords.x, propData.coords.y, propData.coords.z)

    interactiveObjects[id] = propData

    -- Handle specific spawned entity targeting (prevents global model targeting bug!)
    CreateThread(function()
        local entity = 0
        if netId then
            local timer = 0
            while not NetworkDoesNetworkIdExist(netId) and timer < 100 do
                Wait(10)
                timer = timer + 1
            end
            if NetworkDoesNetworkIdExist(netId) then
                entity = NetworkGetEntityFromNetworkId(netId)
            end
        end
        if entity == 0 then
            entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, hash, false, false, false)
        end

        if entity ~= 0 and DoesEntityExist(entity) then
            if GetResourceState('ox_target') == 'started' then
                exports.ox_target:addLocalEntity(entity, {
                    {
                        name = 'map_builder_interact_' .. id,
                        icon = GetLogicIcon(logic.type),
                        label = GetLogicLabel(logic.type),
                        onSelect = function()
                            TriggerInteractiveLogic(id, logic)
                        end
                    }
                })
            elseif GetResourceState('qb-target') == 'started' then
                exports['qb-target']:AddTargetEntity(entity, {
                    options = {
                        {
                            num = 1,
                            type = 'client',
                            icon = GetLogicIcon(logic.type),
                            label = GetLogicLabel(logic.type),
                            action = function()
                                TriggerInteractiveLogic(id, logic)
                            end
                        }
                    },
                    distance = 2.5
                })
            end
        end
    end)
end)

function GetLogicIcon(lType)
    if lType == 'trash' then return 'fas fa-trash'
    elseif lType == 'garage' then return 'fas fa-car'
    elseif lType == 'stash' then return 'fas fa-box-open'
    elseif lType == 'door' then return 'fas fa-door-closed'
    elseif lType == 'fuel' then return 'fas fa-gas-pump'
    elseif lType == 'shop' then return 'fas fa-shopping-basket'
    else return 'fas fa-circle-exclamation' end
end

function GetLogicLabel(lType)
    if lType == 'trash' then return 'Search Container / Throw Away'
    elseif lType == 'garage' then return 'Open Garage Depot'
    elseif lType == 'stash' then return 'Access Storage'
    elseif lType == 'door' then return 'Unlock / Lock Door'
    elseif lType == 'fuel' then return 'Refuel Vehicle'
    elseif lType == 'shop' then return 'Browse Items / Crafting'
    else return 'Interact' end
end

function TriggerInteractiveLogic(id, logic)
    local ped = PlayerPedId()

    if logic.type == 'trash' then
        -- Cooldown & looting
        local success = exports.ox_lib:progressBar({
            duration = 4000,
            label = 'Searching container...',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, mouse = false, combat = true },
            anim = { dict = 'amb@prop_human_bum_bin@idle_b', clip = 'idle_d', flag = 1 }
        })
        if success then
            TriggerServerEvent('map-builder:server:searchTrash', id)
        end

    elseif logic.type == 'garage' then
        -- Spawn or store vehicles
        local items = {
            { title = 'Retrieve Stored Vehicle', description = 'View available personal vehicles', onSelect = function()
                TriggerServerEvent('map-builder:server:getGarageVehicles', id)
            end },
            { title = 'Store Nearby Vehicle', description = 'Return your vehicle to depot', onSelect = function()
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= 0 then
                    local plate = GetVehicleNumberPlateText(vehicle)
                    TriggerServerEvent('map-builder:server:storeGarageVehicle', id, plate)
                    DeleteEntity(vehicle)
                else
                    exports.ox_lib:notify({ type = 'error', description = 'You must be inside a vehicle to store it' })
                end
            end }
        }
        exports.ox_lib:registerContextMenu({
            id = 'map_builder_garage_' .. id,
            title = 'Garage Depot',
            options = items
        })
        exports.ox_lib:showContextMenu('map_builder_garage_' .. id)

    elseif logic.type == 'stash' then
        -- Functional stashes (Secure server lookup)
        TriggerServerEvent('map-builder:server:openStash', id)

    elseif logic.type == 'door' then
        -- Lockpicking, animating or standard lock toggling
        local hasKeycard = true
        if logic.data.requireKeycard then
            if GetResourceState('ox_inventory') == 'started' then
                hasKeycard = exports.ox_inventory:Search('count', logic.data.keycardItem) > 0
            end
        end
        if not hasKeycard then
            exports.ox_lib:notify({ type = 'error', description = 'You need a keycard: ' .. tostring(logic.data.keycardItem) })
            return
        end

        local options = {
            { title = 'Toggle Door Lock', onSelect = function()
                TriggerServerEvent('map-builder:server:toggleDoorLock', id)
            end }
        }
        if logic.data.lockpickable then
            table.insert(options, { title = 'Lockpick Door', onSelect = function()
                local success = exports.ox_lib:progressBar({
                    duration = 6000,
                    label = 'Lockpicking door...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true },
                    anim = { dict = '3anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loob_mechandplayer', flag = 1 }
                })
                if success then
                    TriggerServerEvent('map-builder:server:lockpickSuccess', id)
                end
            end })
        end
        exports.ox_lib:registerContextMenu({
            id = 'map_builder_door_' .. id,
            title = 'Door lock security',
            options = options
        })
        exports.ox_lib:showContextMenu('map_builder_door_' .. id)

    elseif logic.type == 'fuel' then
        -- Refueling vehicle
        local coords = GetEntityCoords(ped)
        local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
        if vehicle ~= 0 then
            local success = exports.ox_lib:progressBar({
                duration = 5000,
                label = 'Refueling vehicle...',
                useWhileDead = false,
                canCancel = true,
                disable = { move = true },
                anim = { dict = 'timetable@gardener@filling_can', clip = 'gar_filling_can', flag = 1 }
            })
            if success then
                TriggerServerEvent('map-builder:server:refuelVehicle', id, GetVehicleNumberPlateText(vehicle))
                SetVehicleFuelLevel(vehicle, 100.0)
            end
        else
            exports.ox_lib:notify({ type = 'error', description = 'No vehicle near the fuel pump' })
        end

    elseif logic.type == 'shop' then
        -- Open items shop or crafting menu
        if logic.data.isCrafting then
            TriggerServerEvent('map-builder:server:openCrafting', id)
        else
            TriggerServerEvent('map-builder:server:openShop', id)
        end

    elseif logic.type == 'custom' then
        -- Custom teleports or triggers
        if logic.data.teleportCoords then
            DoScreenFadeOut(500)
            Wait(500)
            SetEntityCoords(ped, logic.data.teleportCoords.x, logic.data.teleportCoords.y, logic.data.teleportCoords.z, false, false, false, false)
            DoScreenFadeIn(500)
            exports.ox_lib:notify({ type = 'success', description = 'Teleported successfully' })
        end
        if logic.data.triggerEvent then
            if logic.data.isServerEvent then
                TriggerServerEvent(logic.data.triggerEvent, id)
            else
                TriggerEvent(logic.data.triggerEvent, id)
            end
        end
    end
end

-- Sync lockable door state client-side
RegisterNetEvent('map-builder:client:syncDoorState', function(id, locked)
    local prop = interactiveObjects[id]
    if prop then
        -- Find object in world near coordinates
        local hash = GetHash(prop.model)
        local obj = GetClosestObjectOfType(prop.coords.x, prop.coords.y, prop.coords.z, 2.0, hash, false, false, false)
        if obj ~= 0 and DoesEntityExist(obj) then
            if locked then
                SetEntityCollision(obj, true, true)
                FreezeEntityPosition(obj, true)
            else
                FreezeEntityPosition(obj, false)
            end
        end
    end
end)

-- Auto sync maps for connecting players
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('map-builder:server:requestProps')
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        TriggerServerEvent('map-builder:server:requestProps')
    end
end)

RegisterNetEvent('map-builder:client:warpPedIntoVehicle', function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end
end)

RegisterNetEvent('map-builder:client:syncHiddenProp', function(coords, modelHash)
    -- Official, professional FiveM native to permanently hide original world map entities globally!
    local hash = GetHash(modelHash)
    CreateModelHide(coords.x, coords.y, coords.z, 5.0, hash, true)
end)

RegisterNetEvent('map-builder:client:receiveGarageVehicles', function(id, list)
    local options = {}
    local prop = interactiveObjects[id]
    local spawnPoint = prop and prop.logic and prop.logic.data and prop.logic.data.spawnPoint

    for _, v in ipairs(list) do
        table.insert(options, {
            title = v.model .. ' [' .. v.plate .. ']',
            description = 'Click to spawn this vehicle',
            onSelect = function()
                TriggerServerEvent('map-builder:server:spawnGarageVehicleSelected', id, v.model, spawnPoint)
            end
        })
    end

    if #options == 0 then
        table.insert(options, { title = 'No vehicles available in this garage' })
    end

    exports.ox_lib:registerContextMenu({
        id = 'map_builder_garage_spawn_' .. id,
        title = 'Select Vehicle',
        options = options
    })
    exports.ox_lib:showContextMenu('map_builder_garage_spawn_' .. id)
end)

RegisterNetEvent('map-builder:client:rotateProp', function(netId, rotation)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity ~= 0 and DoesEntityExist(entity) then
        SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)
    end
end)
