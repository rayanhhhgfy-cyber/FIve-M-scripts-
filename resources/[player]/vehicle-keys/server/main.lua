local QBox = exports['qbx_core']:GetCoreObject()

local function getPlayerKeys(src, plate)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    local cid = player.PlayerData.citizenid
    local items = exports.ox_inventory:GetItems(src)
    if not items then return false end
    for _, item in ipairs(items) do
        if item.name == 'vehicle_key' and item.metadata and item.metadata.plate == plate then
            return true
        end
    end
    return false
end

exports('HasVehicleKey', getPlayerKeys)

exports('GiveKeyToPlayer', function(target, plate, model)
    local target = tonumber(target)
    if not target then return false end
    local success = exports.ox_inventory:AddItem(target, 'vehicle_key', 1, {
        plate = plate,
        model = model or 'Vehicle',
        label = plate .. ' (' .. (model or 'Vehicle') .. ')',
    })
    if success then
        TriggerClientEvent('ox_lib:notify', target, { type = 'success', description = 'Vehicle key for ' .. plate .. ' added to your inventory' })
    end
    return success
end)

lib.callback.register('vehicle-keys:checkKey', function(source, plate)
    return getPlayerKeys(source, plate)
end)

lib.callback.register('vehicle-keys:getKeyList', function(source)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return {} end
    local items = exports.ox_inventory:GetItems(source)
    if not items then return {} end
    local keys = {}
    for _, item in ipairs(items) do
        if item.name == 'vehicle_key' and item.metadata and item.metadata.plate then
            table.insert(keys, {
                plate = item.metadata.plate,
                model = item.metadata.model or 'Unknown',
                label = item.metadata.label or ('Key (' .. item.metadata.plate .. ')'),
            })
        end
    end
    return keys
end)

lib.callback.register('vehicle-keys:getNearestPlayerKeys', function(source)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return {} end
    local items = exports.ox_inventory:GetItems(source)
    if not items then return {} end
    local keys = {}
    for _, item in ipairs(items) do
        if item.name == 'vehicle_key' and item.metadata and item.metadata.plate then
            table.insert(keys, {
                plate = item.metadata.plate,
                model = item.metadata.model or 'Unknown',
                label = item.metadata.label or ('Key (' .. item.metadata.plate .. ')'),
            })
        end
    end
    return keys
end)

RegisterNetEvent('vehicle-keys:giveKey', function(plate, model, target)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid

    local items = exports.ox_inventory:GetItems(src)
    local foundSlot = nil
    if items then
        for _, item in ipairs(items) do
            if item.name == 'vehicle_key' and item.metadata and item.metadata.plate == plate then
                foundSlot = item.slot
                break
            end
        end
    end
    if not foundSlot then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You do not have a key for ' .. plate })
        return
    end

    local targetPlayer = QBox.Functions.GetPlayer(target)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end

    local success = exports.ox_inventory:SwapSlots(src, foundSlot, target, nil)
    if success then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Key for ' .. plate .. ' given to ' .. GetPlayerName(target) })
        TriggerClientEvent('ox_lib:notify', target, { type = 'info', description = GetPlayerName(src) .. ' gave you a vehicle key for ' .. plate })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Failed to give key. Player may be too far or inventory full.' })
    end
end)

RegisterNetEvent('vehicle-keys:server:lockPickSuccess', function(netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleUndriveable(vehicle, false)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Vehicle started. Engine running.' })
end)

RegisterNetEvent('vehicle-keys:server:lockPickFail', function(netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    exports.ox_inventory:RemoveItem(src, 'lockpick', 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Lockpick broke! Try again.' })
end)

RegisterNetEvent('vehicle-keys:server:lockPickAlarm', function(netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end
    local plate = GetVehicleNumberPlateText(vehicle)

    SetVehicleAlarm(vehicle, true)
    SetVehicleAlarmTimeLeft(vehicle, 30000)
    exports.ox_inventory:RemoveItem(src, 'lockpick', 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Alarm triggered! Time to run.' })

    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        TriggerClientEvent('ox_lib:notify', s, { type = 'warning', description = 'Vehicle alarm heard near plate ' .. plate })
    end
end)

RegisterNetEvent('vehicle-keys:server:createKey', function(plate, model)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local items = exports.ox_inventory:GetItems(src)
    if items then
        for _, item in ipairs(items) do
            if item.name == 'vehicle_key' and item.metadata and item.metadata.plate == plate then
                TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'You already have a key for ' .. plate })
                return
            end
        end
    end

    exports.ox_inventory:AddItem(src, 'vehicle_key', 1, {
        plate = plate,
        model = model,
        label = plate .. ' (' .. (model or 'Vehicle') .. ')',
    })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Key created for ' .. plate })
end)

lib.addCommand('givekey', {
    help = 'Give vehicle key to a player',
    params = {
        { name = 'plate', type = 'string', help = 'Vehicle plate' },
        { name = 'target', type = 'playerId', help = 'Target player ID' },
    },
}, function(source, args)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local success = exports.ox_inventory:AddItem(tonumber(args.target), 'vehicle_key', 1, {
        plate = args.plate,
        model = 'Admin',
        label = args.plate .. ' (Admin)',
    })
    if success then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Key for ' .. args.plate .. ' given to ' .. args.target })
        TriggerClientEvent('ox_lib:notify', tonumber(args.target), { type = 'info', description = 'Admin gave you a vehicle key for ' .. args.plate })
    end
end)
