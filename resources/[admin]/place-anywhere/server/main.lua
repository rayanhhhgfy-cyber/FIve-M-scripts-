local QBox = exports['qbx_core']:GetCoreObject()
local placedObjects = {}

local function isGod(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    return player.PlayerData.group == 'god'
end

local function loadPlacedObjects()
    local rows = MySQL.query.await('SELECT * FROM placed_objects')
    placedObjects = {}
    for _, row in ipairs(rows or {}) do
        placedObjects[row.id] = row
    end
end

AddEventHandler('onResourceStart', function(r)
    if r == GetCurrentResourceName() then loadPlacedObjects() end
end)

MySQL.ready(function() loadPlacedObjects() end)

RegisterNetEvent('place-anywhere:save', function(data)
    local src = source
    if not isGod(src) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local coordsJson = json.encode(data.coords)
    local rotJson = json.encode(data.rotation)

    local existing = MySQL.query.await('SELECT COUNT(*) as count FROM placed_objects WHERE admin_cid = ?', { player.PlayerData.citizenid })
    if existing[1] and existing[1].count >= Config.PlaceAnywhere.maxObjects then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Max ' .. Config.PlaceAnywhere.maxObjects .. ' objects reached' })
        return
    end

    MySQL.insert('INSERT INTO placed_objects (model, coords, rotation, admin_cid) VALUES (?, ?, ?, ?)',
        { data.model, coordsJson, rotJson, player.PlayerData.citizenid })
    loadPlacedObjects()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Object placed permanently' })
end)

RegisterNetEvent('place-anywhere:delete', function(objectId)
    local src = source
    if not isGod(src) then return end
    MySQL.query('DELETE FROM placed_objects WHERE id = ?', { objectId })
    loadPlacedObjects()
    TriggerClientEvent('place-anywhere:syncDelete', -1, objectId)
end)

RegisterNetEvent('place-anywhere:spawnAll', function()
    local src = source
    if not isGod(src) then return end
    for _, obj in pairs(placedObjects) do
        local coords = json.decode(obj.coords)
        local rot = json.decode(obj.rotation)
        TriggerClientEvent('place-anywhere:spawnObject', -1, obj.id, obj.model, coords, rot)
    end
end)

AddEventHandler('playerJoining', function()
    local src = source
    for _, obj in pairs(placedObjects) do
        local coords = json.decode(obj.coords)
        local rot = json.decode(obj.rotation)
        TriggerClientEvent('place-anywhere:spawnObject', src, obj.id, obj.model, coords, rot)
    end
end)

QBox.Functions.CreateCallback('place-anywhere:getObjects', function(source, cb)
    if not isGod(source) then cb({}) return end
    cb(placedObjects)
end)

QBox.Commands.Add('place', 'Open place-anywhere menu (god)', {}, false, function(source)
    if not isGod(source) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'God admin only' })
        return
    end
    TriggerClientEvent('place-anywhere:openMenu', source)
end)
