local QBox = exports['qbx-core']:GetCoreObject()
local rateLimits = {}
local dailyWash = {}

local function isRateLimited(src, key, limit, window)
    if not rateLimits[src] then rateLimits[src] = {} end
    local now = os.time()
    if not rateLimits[src][key] then rateLimits[src][key] = 0 end
    if now - rateLimits[src][key] < window then return true end
    rateLimits[src][key] = now
    return false
end

local function getDailyWash(citizenid)
    local today = os.date('%Y-%m-%d')
    local result = MySQL.single.await('SELECT SUM(amount) as total FROM money_laundry_logs WHERE citizenid = ? AND DATE(date) = ?', {
        citizenid, today
    })
    return result and result.total or 0
end

RegisterNetEvent('money-laundry:server:washMoney', function(dirtyAmount, cleanAmount, usedPapers, location)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'wash', 1, Config.Washing.cooldown) then
        return Wrappers.Notify(src, 'Laundry on cooldown', 'error')
    end
    local dailyTotal = getDailyWash(player.PlayerData.citizenid)
    if dailyTotal + dirtyAmount > Config.Washing.maxDailyWash then
        return Wrappers.Notify(src, 'Daily wash limit reached', 'error')
    end
    local item = player.Functions.GetItemByName(Config.Washing.dirtyMoneyItem)
    if not item or item.amount < dirtyAmount then
        return Wrappers.Notify(src, 'You do not have that much dirty money', 'error')
    end
    if usedPapers then
        local papers = player.Functions.GetItemByName(Config.Papers.item)
        if not papers or papers.amount < 1 then
            return Wrappers.Notify(src, 'You do not have laundering papers', 'error')
        end
        player.Functions.RemoveItem(Config.Papers.item, 1)
    end
    player.Functions.RemoveItem(Config.Washing.dirtyMoneyItem, dirtyAmount)
    player.Functions.AddMoney('bank', cleanAmount)
    dailyWash[player.PlayerData.citizenid] = (dailyWash[player.PlayerData.citizenid] or 0) + dirtyAmount
    TriggerClientEvent('money-laundry:client:washComplete', src, cleanAmount)
    MySQL.insert('INSERT INTO money_laundry_logs (citizenid, amount, clean_amount, location, date) VALUES (?, ?, ?, ?, NOW())', {
        player.PlayerData.citizenid, dirtyAmount, cleanAmount, location.business
    })
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    exports['discord-logs']:sendLog('money_laundered', {
        message = charName .. ' laundered $' .. dirtyAmount .. ' (clean: $' .. cleanAmount .. ')',
        source = src,
        color = 'yellow'
    })
end)

RegisterNetEvent('money-laundry:server:alertPolice', function(coords)
    local src = source
    if isRateLimited(src, 'police_alert', 1, 30000) then return end
    local players = QBox:GetPlayers()
    for _, playerId in ipairs(players) do
        local player = QBox.Functions.GetPlayer(playerId)
        if player and player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
            TriggerClientEvent('money-laundry:client:policeAlert', playerId, coords)
        end
    end
    exports['discord-logs']:sendLog('laundry_alert', {
        message = 'Laundering activity detected at ' .. json.encode(coords),
        color = 'red'
    })
end)

QBox:CreateCallback('money-laundry:server:getDailyWash', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return cb(0) end
    cb(getDailyWash(player.PlayerData.citizenid))
end)

AddEventHandler('playerDropped', function()
    local src = source
    rateLimits[src] = nil
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        dailyWash = {}
    end
end)
