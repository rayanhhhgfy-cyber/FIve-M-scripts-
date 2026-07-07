local QBox = exports['qbx-core']:GetCoreObject()
local rateLimits = {}
local activeTags = {}
local tagIdCounter = 0

local function isRateLimited(src, key, limit, window)
    if not rateLimits[src] then rateLimits[src] = {} end
    local now = os.time()
    if not rateLimits[src][key] then rateLimits[src][key] = 0 end
    if now - rateLimits[src][key] < window then return true end
    rateLimits[src][key] = now
    return false
end

local function loadActiveTags()
    local results = MySQL.query.await('SELECT * FROM graffiti_tags WHERE cleaned = 0')
    for _, row in ipairs(results) do
        activeTags[row.id] = {
            id = row.id,
            coords = json.decode(row.coords),
            color = json.decode(row.color),
            tagType = json.decode(row.tag_type),
            gang = row.gang,
            player = row.citizenid,
            createdAt = row.created_at
        }
        if row.id >= tagIdCounter then
            tagIdCounter = row.id + 1
        end
    end
end

RegisterNetEvent('graffiti:server:tagPlaced', function(location, color, tagType)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'place_tag', 1, Config.Tagging.cooldown) then
        return Wrappers.Notify(src, 'Wait before tagging again', 'error')
    end
    local gang = MySQL.single.await('SELECT gang FROM players WHERE citizenid = ?', { player.PlayerData.citizenid })
    local gangName = gang and gang.gang or nil
    local tagData = {
        id = tagIdCounter,
        coords = location.coords,
        color = color,
        tagType = tagType,
        gang = gangName,
        player = player.PlayerData.citizenid,
        createdAt = os.time()
    }
    tagIdCounter = tagIdCounter + 1
    activeTags[tagData.id] = tagData
    MySQL.insert('INSERT INTO graffiti_tags (id, coords, color, tag_type, gang, citizenid, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())', {
        tagData.id, json.encode(location.coords), json.encode(color), json.encode(tagType), gangName, player.PlayerData.citizenid
    })
    TriggerClientEvent('graffiti:client:tagPlaced', -1, tagData)
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    exports['discord-logs']:sendLog('graffiti_tagged', {
        message = charName .. ' placed graffiti at ' .. location.label,
        color = 'blue'
    })
end)

RegisterNetEvent('graffiti:server:alertPolice', function(coords)
    local src = source
    if isRateLimited(src, 'police_alert', 1, 30000) then return end
    local players = QBox:GetPlayers()
    for _, playerId in ipairs(players) do
        local player = QBox.Functions.GetPlayer(playerId)
        if player and player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
            TriggerClientEvent('graffiti:client:policeAlert', playerId, coords)
        end
    end
end)

RegisterNetEvent('graffiti:server:cleanupTag', function(tagId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'cleanup', 1, 5) then return end
    if not activeTags[tagId] then
        return Wrappers.Notify(src, 'That graffiti no longer exists', 'error')
    end
    local money = player.Functions.GetMoney('bank')
    if money < Config.Cleanup.cost then
        return Wrappers.Notify(src, 'Cleanup costs $' .. Config.Cleanup.cost, 'error')
    end
    player.Functions.RemoveMoney('bank', Config.Cleanup.cost)
    MySQL.update('UPDATE graffiti_tags SET cleaned = 1 WHERE id = ?', { tagId })
    activeTags[tagId] = nil
    TriggerClientEvent('graffiti:client:tagRemoved', -1, tagId)
end)

RegisterNetEvent('graffiti:server:loadTags', function()
    local src = source
    local tags = {}
    for _, tag in pairs(activeTags) do
        tags[#tags + 1] = tag
    end
    TriggerClientEvent('graffiti:client:loadTags', src, tags)
end)

QBox:CreateCallback('graffiti:server:getActiveTags', function(source, cb)
    local tags = {}
    for _, tag in pairs(activeTags) do
        tags[#tags + 1] = tag
    end
    cb(tags)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        loadActiveTags()
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    rateLimits[src] = nil
end)
