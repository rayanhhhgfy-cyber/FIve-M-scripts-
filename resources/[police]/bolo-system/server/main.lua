local QBox = exports['qbx_core']:GetCoreObject()
local activeBOLOs = {}
local boloCounter = 0

local function isLEO(player)
    if not player then return false end
    for _, j in ipairs(Config.BOLO.allowedJobs) do
        if player.PlayerData.job.name == j then return true end
    end
    return false
end

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.BOLO.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

local function notifyLEO(msg)
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local p = QBox.Functions.GetPlayer(src)
        if isLEO(p) or isAdmin(src) then
            TriggerClientEvent('ox_lib:notify', src, { type = 'warning', description = msg })
        end
    end
end

RegisterNetEvent('bolo:server:create', function(boloType, title, description, plate, lastSeen)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not isLEO(player) and not isAdmin(src) then return end

    boloCounter = boloCounter + 1
    local bolo = {
        id = boloCounter,
        type = boloType or 'vehicle',
        title = title or 'BOLO',
        description = description or '',
        plate = plate or '',
        lastSeen = lastSeen or '',
        createdBy = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        creatorCID = player.PlayerData.citizenid,
        status = 'active',
        createdAt = os.time(),
    }
    activeBOLOs[boloCounter] = bolo
    MySQL.insert('INSERT INTO police_bolos (type, title, description, plate, last_seen, creator_cid, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { boloType, title, description, plate, lastSeen, player.PlayerData.citizenid, 'active' })
    notifyLEO('🚨 BOLO #' .. boloCounter .. ' (' .. (Config.BOLO.types[boloType] and Config.BOLO.types[boloType].label or boloType) .. '): ' .. title)
end)

RegisterNetEvent('bolo:server:resolve', function(boloId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not isLEO(player) and not isAdmin(src) then return end
    local bolo = activeBOLOs[boloId]
    if not bolo then return end
    bolo.status = 'resolved'
    MySQL.update('UPDATE police_bolos SET status = ? WHERE id = ?', { 'resolved', boloId })
    notifyLEO('✅ BOLO #' .. boloId .. ' resolved by ' .. player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname)
    activeBOLOs[boloId] = nil
end)

QBox.Functions.CreateCallback('bolo:server:getActive', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not isLEO(player) and not isAdmin(source) then cb({}) return end
    local result = {}
    for _, b in pairs(activeBOLOs) do
        table.insert(result, b)
    end
    cb(result)
end)

QBox.Commands.Add('bolo', 'Create a BOLO', {}, false, function(source, args)
    local player = QBox.Functions.GetPlayer(source)
    if not isLEO(player) and not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Not authorized' })
        return
    end
    TriggerClientEvent('bolo:client:create', source)
end)

QBox.Commands.Add('bololist', 'View active BOLOs', {}, false, function(source)
    TriggerClientEvent('bolo:client:list', source)
end)

QBox.Commands.Add('boloresolve', 'Resolve a BOLO', {}, false, function(source, args)
    local id = tonumber(args[1])
    if id then TriggerEvent('bolo:server:resolve', id) end
end)
