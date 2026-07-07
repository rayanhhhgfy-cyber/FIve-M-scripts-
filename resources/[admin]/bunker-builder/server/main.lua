local QBox = exports['qbx_core']:GetCoreObject()
local customBunkers = {}

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    local group = player.PlayerData.group
    for _, g in ipairs(Config.BunkerBuilder.adminGroups) do
        if group == g then return true end
    end
    return false
end

local function loadCustomBunkers()
    local rows = MySQL.query.await('SELECT * FROM custom_bunkers ORDER BY created_at DESC')
    customBunkers = {}
    for _, row in ipairs(rows or {}) do
        local entrance = json.decode(row.entrance_coords)
        local interior = json.decode(row.interior_coords)
        local rocks = json.decode(row.rocks_json or '[]')
        local roofProps = json.decode(row.roof_props_json or 'null')
        local allowedJobs = json.decode(row.allowed_jobs or 'null')

        local locationData = {
            id = row.id,
            label = row.label,
            passcode = row.passcode or '2193',
            locked = row.locked ~= 0,
            cidBypass = row.cid_bypass ~= 0,
            interiorType = row.interior_type or 'bunker_meth_lab',
            entrance = {
                coords = vector3(entrance.x, entrance.y, entrance.z),
                heading = row.entrance_heading,
                rocks = rocks,
            },
            interior = {
                coords = vector3(interior.x, interior.y, interior.z),
                heading = row.interior_heading,
                vehicleSpawn = row.vehicle_spawn and json.decode(row.vehicle_spawn) or nil,
                heliSpawn = row.heli_spawn and json.decode(row.heli_spawn) or nil,
                exit = { coords = vector3(interior.x, interior.y - 3.0, interior.z), heading = 0.0 },
            },
            interiorName = row.interior_name,
            armory = { weapons = {}, ammo = {}, equipment = {} },
        }

        if allowedJobs then
            locationData.allowedJobs = allowedJobs
            locationData.minRank = row.min_rank or 0
        end

        if roofProps then
            locationData.interior.roofProps = roofProps
        end

        customBunkers[row.id] = locationData
        Config.SecretBunkers = Config.SecretBunkers or {}
        Config.SecretBunkers.locations = Config.SecretBunkers.locations or {}
        Config.SecretBunkers.locations[row.id] = locationData
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() or resourceName == 'secret-bunkers' or resourceName == 'meth-lab-empire' then
        loadCustomBunkers()
    end
end)

MySQL.ready(function()
    loadCustomBunkers()
end)

RegisterNetEvent('bunker-builder:save', function(data)
    local src = source
    if not isAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Admin only' })
        return
    end

    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local id = 'custom_' .. player.PlayerData.citizenid .. '_' .. math.random(10000, 99999)
    local entranceJson = json.encode(data.entranceCoords)
    local interiorJson = json.encode(data.interiorCoords)
    local rocksJson = json.encode(data.rocks)
    local roofPropsJson = data.roofProps and json.encode(data.roofProps) or null
    local allowedJobsJson = data.allowedJobs and json.encode(data.allowedJobs) or null
    local vehicleSpawnJson = data.vehicleSpawn and json.encode(data.vehicleSpawn) or null
    local heliSpawnJson = data.heliSpawn and json.encode(data.heliSpawn) or null

    MySQL.insert('INSERT INTO custom_bunkers (id, label, entrance_coords, entrance_heading, interior_name, interior_coords, interior_heading, allowed_jobs, min_rank, vehicle_spawn, heli_spawn, rocks_json, roof_props_json, created_by, passcode, locked, cid_bypass, interior_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        id, data.label, entranceJson, data.entranceHeading, data.interiorName, interiorJson, data.interiorHeading,
        allowedJobsJson, data.minRank or 0, vehicleSpawnJson, heliSpawnJson, rocksJson, roofPropsJson, player.PlayerData.citizenid,
        data.passcode or '2193', data.locked and 1 or 0, data.cidBypass and 1 or 0, data.interiorType or 'bunker_meth_lab'
    })

    loadCustomBunkers()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bunker "' .. data.label .. '" created!' })
    TriggerClientEvent('bunker-builder:reloadTargets', -1)
end)

RegisterNetEvent('bunker-builder:update', function(bunkerId, data)
    local src = source
    if not isAdmin(src) then return end

    local entranceJson = json.encode(data.entranceCoords)
    local interiorJson = json.encode(data.interiorCoords)
    local rocksJson = json.encode(data.rocks)
    local roofPropsJson = data.roofProps and json.encode(data.roofProps) or null

    MySQL.update('UPDATE custom_bunkers SET label = ?, entrance_coords = ?, entrance_heading = ?, interior_name = ?, interior_coords = ?, interior_heading = ?, passcode = ?, locked = ?, cid_bypass = ?, interior_type = ?, rocks_json = ?, roof_props_json = ? WHERE id = ?', {
        data.label, entranceJson, data.entranceHeading, data.interiorName, interiorJson, data.interiorHeading,
        data.passcode or '2193', data.locked and 1 or 0, data.cidBypass and 1 or 0, data.interiorType or 'bunker_meth_lab',
        rocksJson, roofPropsJson, bunkerId
    })

    loadCustomBunkers()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bunker "' .. data.label .. '" updated!' })
    TriggerClientEvent('bunker-builder:reloadTargets', -1)
end)

RegisterNetEvent('bunker-builder:delete', function(bunkerId)
    local src = source
    if not isAdmin(src) then return end

    MySQL.query('DELETE FROM custom_bunkers WHERE id = ?', { bunkerId })
    if Config.SecretBunkers and Config.SecretBunkers.locations then
        Config.SecretBunkers.locations[bunkerId] = nil
    end
    customBunkers[bunkerId] = nil
    loadCustomBunkers()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bunker deleted' })
    TriggerClientEvent('bunker-builder:reloadTargets', -1)
end)

RegisterNetEvent('bunker-builder:duplicate', function(bunkerId)
    local src = source
    if not isAdmin(src) then return end
    local original = customBunkers[bunkerId]
    if not original then return end

    local newId = bunkerId .. '_copy_' .. math.random(1000, 9999)
    local entranceJson = json.encode({ x = original.entrance.coords.x, y = original.entrance.coords.y, z = original.entrance.coords.z })
    local interiorJson = json.encode({ x = original.interior.coords.x, y = original.interior.coords.y, z = original.interior.coords.z })
    local rocksJson = json.encode(original.entrance.rocks or {})
    local roofPropsJson = original.interior.roofProps and json.encode(original.interior.roofProps) or null

    MySQL.insert('INSERT INTO custom_bunkers (id, label, entrance_coords, entrance_heading, interior_name, interior_coords, interior_heading, rocks_json, roof_props_json, passcode, locked, cid_bypass, interior_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        newId, original.label .. ' (copy)', entranceJson, original.entrance.heading,
        original.interiorName, interiorJson, original.interior.heading,
        rocksJson, roofPropsJson, original.passcode or '2193', original.locked and 1 or 0,
        original.cidBypass and 1 or 0, original.interiorType or 'bunker_meth_lab'
    })

    loadCustomBunkers()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bunker duplicated' })
    TriggerClientEvent('bunker-builder:reloadTargets', -1)
end)

QBox.Functions.CreateCallback('bunker-builder:getList', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    local list = {}
    for id, bunker in pairs(customBunkers) do
        table.insert(list, {
            id = id,
            label = bunker.label,
            passcode = bunker.passcode or '2193',
            locked = bunker.locked ~= false,
            cidBypass = bunker.cidBypass ~= false,
            interiorType = bunker.interiorType or 'bunker_meth_lab',
            interiorName = bunker.interiorName,
            entrance = { x = bunker.entrance.coords.x, y = bunker.entrance.coords.y, z = bunker.entrance.coords.z },
            entranceHeading = bunker.entrance.heading,
            interiorCoords = { x = bunker.interior.coords.x, y = bunker.interior.coords.y, z = bunker.interior.coords.z },
            interiorHeading = bunker.interior.heading,
            allowedJobs = bunker.allowedJobs,
            minRank = bunker.minRank,
            rocks = bunker.entrance.rocks,
            roofProps = bunker.interior.roofProps,
        })
    end
    cb(list)
end)

QBox.Functions.CreateCallback('bunker-builder:getBunkerById', function(source, cb, bunkerId)
    cb(customBunkers[bunkerId] or nil)
end)

QBox.Commands.Add('bunker', 'Open bunker builder (admin)', {}, false, function(source)
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Admin only' })
        return
    end
    TriggerClientEvent('bunker-builder:openMenu', source)
end)

exports('GetAllBunkers', function()
    return customBunkers
end)

exports('GetBunker', function(bunkerId)
    return customBunkers[bunkerId]
end)

exports('UpdateBunkerState', function(bunkerId, state)
    if customBunkers[bunkerId] then
        for k, v in pairs(state) do
            customBunkers[bunkerId][k] = v
        end
    end
end)
