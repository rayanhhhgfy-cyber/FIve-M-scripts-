local QBCore = exports['qbx_core']:GetCoreObject()
local activeFlips = {}

local function GetVehicleClassConfig(vehicleClass)
    local className = Config.ClassLookup[vehicleClass]
    if not className then className = 'sedan' end
    for _, cfg in ipairs(Config.VehicleClasses) do
        if cfg.class == className then return cfg end
    end
    return { flipPlayers = 1, pushForce = 4.0, label = 'Vehicle' }
end

local function StartFlip(source, netId)
    if activeFlips[netId] then return false, 'Already being flipped' end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then return false end
    local class = GetVehicleClass(entity)
    local classCfg = GetVehicleClassConfig(class)
    activeFlips[netId] = { players = { source }, required = classCfg.flipPlayers, classCfg = classCfg, startTime = GetGameTimer() }
    TriggerClientEvent('vehicle-physics:client:startFlip', source, netId, activeFlips[netId])
    if classCfg.flipPlayers > 1 then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'info',
            description = 'Need ' .. classCfg.flipPlayers .. ' players to flip this ' .. classCfg.label .. '. Waiting for help...'
        })
    end
    return true, classCfg.flipPlayers
end

local function JoinFlip(source, netId)
    if not activeFlips[netId] then return false, 'No active flip' end
    local flip = activeFlips[netId]
    for _, p in ipairs(flip.players) do
        if p == source then return false, 'Already flipping' end
    end
    table.insert(flip.players, source)
    TriggerClientEvent('vehicle-physics:client:joinFlip', source, netId, flip)
    if #flip.players >= flip.required then
        TriggerClientEvent('vehicle-physics:client:doFlip', -1, netId)
        activeFlips[netId] = nil
        return true, 'Flipping now!'
    end
    local remaining = flip.required - #flip.players
    TriggerClientEvent('ox_lib:notify', source, { type = 'info', description = 'Joined! Need ' .. remaining .. ' more.' })
    return true, remaining .. ' more needed'
end

lib.callback.register('vehicle-physics:server:startFlip', function(source, netId)
    return StartFlip(source, netId)
end)

lib.callback.register('vehicle-physics:server:joinFlip', function(source, netId)
    return JoinFlip(source, netId)
end)

lib.callback.register('vehicle-physics:server:pushVehicle', function(source, netId, direction)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then return false end
    local class = GetVehicleClass(entity)
    local classCfg = GetVehicleClassConfig(class)
    local force = classCfg.pushForce * 100.0
    TriggerClientEvent('vehicle-physics:client:pushVehicle', -1, netId, direction, force)
    return true
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[vehicle-physics] Vehicle flip and push system active.^7')
end)

exports('GetActiveFlip', function(netId) return activeFlips[netId] end)
