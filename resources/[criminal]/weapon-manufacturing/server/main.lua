local QBox = exports['qbx-core']:GetCoreObject()
local rateLimits = {}

local function isRateLimited(src, key, limit, window)
    if not rateLimits[src] then rateLimits[src] = {} end
    local now = GetGameTimer()
    if not rateLimits[src][key] then rateLimits[src][key] = {} end
    rateLimits[src][key] = lib.table.filter(rateLimits[src][key], function(t)
        return now - t < window
    end)
    if #rateLimits[src][key] >= limit then return true end
    rateLimits[src][key][#rateLimits[src][key] + 1] = now
    return false
end

RegisterNetEvent('weapon-manufacturing:server:crafted', function(weapon)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'craft', 3, 30000) then
        return Wrappers.Notify(src, 'Wait before crafting again', 'error')
    end
    local exp = player.PlayerData.metadata.weaponcraft_exp or 0
    player.Functions.SetMetaData('weaponcraft_exp', exp)
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    exports['discord-logs']:sendLog('weapon_manufactured', {
        message = charName .. ' crafted a ' .. weapon,
        source = src,
        color = 'orange'
    })
    MySQL.insert('INSERT INTO weapon_crafting_logs (citizenid, weapon, date) VALUES (?, ?, NOW())', {
        player.PlayerData.citizenid, weapon
    })
end)

RegisterNetEvent('weapon-manufacturing:server:alertPolice', function(coords)
    local src = source
    if isRateLimited(src, 'police_alert', 1, 60000) then return end
    local players = QBox:GetPlayers()
    for _, playerId in ipairs(players) do
        local player = QBox.Functions.GetPlayer(playerId)
        if player and player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
            TriggerClientEvent('weapon-manufacturing:client:policeAlert', playerId, coords)
        end
    end
    exports['discord-logs']:sendLog('weapon_alert', {
        message = 'Weapon crafting alert at ' .. json.encode(coords),
        color = 'red'
    })
end)

RegisterNetEvent('weapon-manufacturing:server:cleanup', function()
    local src = source
    rateLimits[src] = nil
end)

QBox:CreateCallback('weapon-manufacturing:server:getSkillLevel', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return cb(1) end
    cb(player.PlayerData.metadata.weaponcraft_exp or 0)
end)

AddEventHandler('playerDropped', function()
    local src = source
    rateLimits[src] = nil
end)
