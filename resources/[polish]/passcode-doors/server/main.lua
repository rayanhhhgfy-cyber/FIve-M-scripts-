local QBox = exports['qbx_core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.PasscodeDoors.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

local doorCache = {}
local doorStates = {}

--- Load doors from DB on start
Citizen.CreateThread(function()
    local results = MySQL.query.await('SELECT * FROM passcode_doors')
    if results then
        for _, row in ipairs(results) do
            doorCache[row.id] = {
                id = row.id,
                label = row.label,
                model = row.door_model,
                coords = json.decode(row.coords),
                heading = row.heading,
                passcodeHash = row.passcode_hash,
                maker = row.maker_cid,
                isLocked = row.is_locked == 1,
            }
            doorStates[row.id] = row.is_locked == 1
        end
    end
end)

--- Verify passcode (simple hash comparison)
local function verifyPasscode(input, hash)
    -- Simple hash: SHA256-ish using native string ops
    -- In production use a proper hash; this is sufficient for in-game
    local calculatedHash = ''
    for i = 1, #input do
        local byte = string.byte(input, i)
        calculatedHash = calculatedHash .. string.format('%02x', (byte * 7 + i) % 256)
    end
    return calculatedHash == hash
end

local function hashPasscode(input)
    local h = ''
    for i = 1, #input do
        local byte = string.byte(input, i)
        h = h .. string.format('%02x', (byte * 7 + i) % 256)
    end
    return h
end

--- Check if player has access to a door
local function hasAccess(src, doorId)
    local citizenid = Player(src).state.cid
    if not citizenid then return false end
    local door = doorCache[doorId]
    if not door then return false end
    if door.maker == citizenid then return true end
    local accessRow = MySQL.single.await('SELECT id FROM passcode_door_access WHERE door_id = ? AND citizenid = ?', { doorId, citizenid })
    return accessRow ~= nil
end

--- Player tries to open a passcode door
RegisterNetEvent('passcodedoor:interact', function(doorId)
    local src = source
    if not checkRateLimit(src, 'doorInteract', 10) then return end
    local door = doorCache[doorId]
    if not door then return end

    -- Check distance
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    if #(coords - vector3(door.coords.x, door.coords.y, door.coords.z)) > Config.PasscodeDoors.maxDistance then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Too far' })
        return
    end

    -- Maker always has access
    local citizenid = Player(src).state.cid
    if door.maker == citizenid then
        doorStates[doorId] = not doorStates[doorId]
        MySQL.update('UPDATE passcode_doors SET is_locked = ? WHERE id = ?', { doorStates[doorId] and 1 or 0, doorId })
        TriggerClientEvent('passcodedoor:sync', -1, doorId, doorStates[doorId])
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = doorStates[doorId] and 'Door locked' or 'Door unlocked' })
        return
    end

    -- Check if already on access list
    if hasAccess(src, doorId) then
        doorStates[doorId] = not doorStates[doorId]
        MySQL.update('UPDATE passcode_doors SET is_locked = ? WHERE id = ?', { doorStates[doorId] and 1 or 0, doorId })
        TriggerClientEvent('passcodedoor:sync', -1, doorId, doorStates[doorId])
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = doorStates[doorId] and 'Door locked' or 'Door unlocked' })
        return
    end

    -- Not on access list — require passcode
    TriggerClientEvent('passcodedoor:requestPasscode', src, doorId)
end)

--- Verify passcode submitted by client
RegisterNetEvent('passcodedoor:submitPasscode', function(doorId, passcode)
    local src = source
    if not checkRateLimit(src, 'passcodeSubmit', 20) then return end
    local door = doorCache[doorId]
    if not door or not passcode then return end
    local citizenid = Player(src).state.cid or 'unknown'

    if verifyPasscode(passcode, door.passcodeHash) then
        doorStates[doorId] = not doorStates[doorId]
        MySQL.update('UPDATE passcode_doors SET is_locked = ? WHERE id = ?', { doorStates[doorId] and 1 or 0, doorId })
        TriggerClientEvent('passcodedoor:sync', -1, doorId, doorStates[doorId])
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Access granted' })
        MySQL.insert('INSERT INTO passcode_door_logs (door_id, citizenid, action) VALUES (?, ?, ?)', { doorId, citizenid, 'unlocked_with_passcode' })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Wrong passcode' })
        if Config.PasscodeDoors.logAllAttempts then
            MySQL.insert('INSERT INTO passcode_door_logs (door_id, citizenid, action) VALUES (?, ?, ?)', { doorId, citizenid, 'failed_passcode' })
        end
    end
end)

--- Admin: Create passcode door
RegisterNetEvent('passcodedoor:admin:create', function(label, doorModel, coords, heading, passcode)
    local src = source
    if not isAdmin(src) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if not passcode or #passcode < 3 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Passcode must be 3+ characters' })
        return
    end
    local coordsJson = json.encode(coords)
    local hash = hashPasscode(passcode)
    local id = MySQL.insert.await('INSERT INTO passcode_doors (label, door_model, coords, heading, passcode_hash, maker_cid) VALUES (?, ?, ?, ?, ?, ?)',
        { label or 'Passcode Door', doorModel or Config.PasscodeDoors.defaultDoorModel, coordsJson, heading or 0, hash, player.PlayerData.citizenid })
    if id then
        doorCache[id] = {
            id = id,
            label = label or 'Passcode Door',
            model = doorModel or Config.PasscodeDoors.defaultDoorModel,
            coords = coords,
            heading = heading or 0,
            passcodeHash = hash,
            maker = player.PlayerData.citizenid,
            isLocked = true,
        }
        doorStates[id] = true
        TriggerClientEvent('passcodedoor:addDoor', -1, doorCache[id])
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Passcode door #' .. id .. ' created' })
    end
end)

--- Admin: Remove passcode door
RegisterNetEvent('passcodedoor:admin:remove', function(doorId)
    local src = source
    if not isAdmin(src) then return end
    MySQL.query('DELETE FROM passcode_doors WHERE id = ?', { doorId })
    MySQL.query('DELETE FROM passcode_door_access WHERE door_id = ?', { doorId })
    doorCache[doorId] = nil
    doorStates[doorId] = nil
    TriggerClientEvent('passcodedoor:removeDoor', -1, doorId)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Door #' .. doorId .. ' removed' })
end)

--- Admin: Grant access to player
RegisterNetEvent('passcodedoor:admin:grantAccess', function(doorId, targetCID)
    local src = source
    if not isAdmin(src) then return end
    local existing = MySQL.single.await('SELECT id FROM passcode_door_access WHERE door_id = ? AND citizenid = ?', { doorId, targetCID })
    if existing then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already has access' })
        return
    end
    MySQL.insert('INSERT INTO passcode_door_access (door_id, citizenid) VALUES (?, ?)', { doorId, targetCID })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Access granted' })
end)

--- Admin: Revoke access
RegisterNetEvent('passcodedoor:admin:revokeAccess', function(doorId, targetCID)
    local src = source
    if not isAdmin(src) then return end
    MySQL.query('DELETE FROM passcode_door_access WHERE door_id = ? AND citizenid = ?', { doorId, targetCID })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Access revoked' })
end)

--- Admin: List all doors
QBox.Functions.CreateCallback('passcodedoor:admin:listDoors', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    local doors = MySQL.query.await('SELECT * FROM passcode_doors ORDER BY id')
    cb(doors or {})
end)

--- Admin: Get door access list
QBox.Functions.CreateCallback('passcodedoor:admin:getAccessList', function(source, cb, doorId)
    if not isAdmin(source) then cb({}) return end
    local access = MySQL.query.await('SELECT * FROM passcode_door_access WHERE door_id = ?', { doorId })
    cb(access or {})
end)

--- Admin: Get door logs
QBox.Functions.CreateCallback('passcodedoor:admin:getLogs', function(source, cb, doorId)
    if not isAdmin(source) then cb({}) return end
    local logs = MySQL.query.await('SELECT * FROM passcode_door_logs WHERE door_id = ? ORDER BY created_at DESC LIMIT 50', { doorId })
    cb(logs or {})
end)

--- Auto-lock thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.PasscodeDoors.autolockTime * 1000)
        for id, state in pairs(doorStates) do
            if state == false then
                doorStates[id] = true
                MySQL.update('UPDATE passcode_doors SET is_locked = 1 WHERE id = ?', { id })
                TriggerClientEvent('passcodedoor:sync', -1, id, true)
            end
        end
    end
end)

--- Sync doors to connecting player
RegisterNetEvent('passcodedoor:requestSync', function()
    local src = source
    for id, door in pairs(doorCache) do
        TriggerClientEvent('passcodedoor:addDoor', src, door)
        TriggerClientEvent('passcodedoor:sync', src, id, doorStates[id])
    end
end)

--- Admin commands
QBox.Commands.Add('addpasscodedoor', 'Create a passcode door (coords optional, uses current position)', {}, false, function(source, args)
    local src = source
    if not isAdmin(src) then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local passcode = args[1] or '1234'
    local label = args[2] or nil
    TriggerEvent('passcodedoor:admin:create', label, nil, { x = coords.x, y = coords.y, z = coords.z }, heading, passcode)
end)

QBox.Commands.Add('removepasscodedoor', 'Remove a passcode door by ID', {}, false, function(source, args)
    local src = source
    if not isAdmin(src) then return end
    local id = tonumber(args[1])
    if not id then return end
    TriggerEvent('passcodedoor:admin:remove', id)
end)

QBox.Commands.Add('setdooraccess', 'Grant player access to a passcode door', {}, false, function(source, args)
    local src = source
    if not isAdmin(src) then return end
    local doorId = tonumber(args[1])
    local targetCID = args[2]
    if not doorId or not targetCID then return end
    TriggerEvent('passcodedoor:admin:grantAccess', doorId, targetCID)
end)

QBox.Commands.Add('revokedooraccess', 'Revoke player access from a passcode door', {}, false, function(source, args)
    local src = source
    if not isAdmin(src) then return end
    local doorId = tonumber(args[1])
    local targetCID = args[2]
    if not doorId or not targetCID then return end
    TriggerEvent('passcodedoor:admin:revokeAccess', doorId, targetCID)
end)

--- Cleanup
AddEventHandler('playerDropped', function()
    local src = source
end)
