local QBox = exports['qbx-core']:GetCoreObject()
local rateLimits = {}
local installedSkimmers = {}
local dailyFraud = {}

local function isRateLimited(src, key, limit, window)
    if not rateLimits[src] then rateLimits[src] = {} end
    local now = os.time()
    if not rateLimits[src][key] then rateLimits[src][key] = 0 end
    if now - rateLimits[src][key] < window then return true end
    rateLimits[src][key] = now
    return false
end

local function getDailyFraud(citizenid)
    local today = os.date('%Y-%m-%d')
    local result = MySQL.single.await('SELECT SUM(payout) as total FROM card_fraud_logs WHERE citizenid = ? AND DATE(date) = ?', {
        citizenid, today
    })
    return result and result.total or 0
end

local function loadSkimmers()
    local results = MySQL.query.await('SELECT * FROM card_skimmers WHERE active = 1')
    for _, row in ipairs(results) do
        installedSkimmers[row.atm_label] = { id = row.id, owner = row.citizenid, installedAt = row.installed_at }
    end
end

RegisterNetEvent('card-robbery:server:installSkimmer', function(atm)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'install_skimmer', 1, 10) then return end
    if installedSkimmers[atm.label] then
        return Wrappers.Notify(src, 'A skimmer is already on this ATM', 'error')
    end
    MySQL.insert('INSERT INTO card_skimmers (citizenid, atm_label, installed_at) VALUES (?, ?, NOW())', {
        player.PlayerData.citizenid, atm.label
    })
    local id = MySQL.insert.await('SELECT LAST_INSERT_ID() as id')
    installedSkimmers[atm.label] = { id = id, owner = player.PlayerData.citizenid, installedAt = os.time() }
    TriggerClientEvent('card-robbery:client:skimmerInstalled', -1, atm.label)
    exports['discord-logs']:sendLog('skimmer_installed', {
        message = 'Skimmer installed at ' .. atm.label,
        source = src,
        color = 'orange'
    })
end)

RegisterNetEvent('card-robbery:server:collectData', function(atm)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'collect_data', 1, 5) then return end
    if not installedSkimmers[atm.label] then
        return Wrappers.Notify(src, 'No skimmer on this ATM', 'error')
    end
    if installedSkimmers[atm.label].owner == player.PlayerData.citizenid and math.random() < 0.5 then
        return Wrappers.Notify(src, 'Using your own skimmer raises suspicion', 'error')
    end
    player.Functions.AddItem('card_data', Config.Skimming.dataPerCollect)
    TriggerClientEvent('card-robbery:client:dataCollected', src)
    exports['discord-logs']:sendLog('card_data_collected', {
        message = 'Card data collected from ' .. atm.label,
        source = src,
        color = 'orange'
    })
end)

RegisterNetEvent('card-robbery:server:commitFraud', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'fraud', 1, 10) then return end
    local dailyTotal = getDailyFraud(player.PlayerData.citizenid)
    if dailyTotal >= Config.CardFraud.maxDailyFraud then
        return Wrappers.Notify(src, 'Daily fraud limit reached', 'error')
    end
    local cardItem = player.Functions.GetItemByName(Config.CardFraud.encodedCardItem)
    if not cardItem then
        return Wrappers.Notify(src, 'No encoded card', 'error')
    end
    local payout = math.random(Config.CardFraud.minPayout, Config.CardFraud.maxPayout)
    local remaining = Config.CardFraud.maxDailyFraud - dailyTotal
    payout = math.min(payout, remaining)
    player.Functions.RemoveItem(Config.CardFraud.encodedCardItem, 1)
    player.Functions.AddMoney('bank', payout)
    MySQL.insert('INSERT INTO card_fraud_logs (citizenid, payout, date) VALUES (?, ?, NOW())', {
        player.PlayerData.citizenid, payout
    })
    TriggerClientEvent('card-robbery:client:fraudComplete', src, payout)
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    exports['discord-logs']:sendLog('card_fraud', {
        message = charName .. ' committed card fraud for $' .. payout,
        source = src,
        color = 'red'
    })
end)

RegisterNetEvent('card-robbery:server:alertPolice', function(coords)
    local src = source
    if isRateLimited(src, 'police_alert', 1, 30000) then return end
    local players = QBox:GetPlayers()
    for _, playerId in ipairs(players) do
        local player = QBox.Functions.GetPlayer(playerId)
        if player and player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
            TriggerClientEvent('card-robbery:client:policeAlert', playerId, coords)
        end
    end
end)

RegisterNetEvent('card-robbery:server:getInstalledSkimmers', function()
    local src = source
    local clientSkimmers = {}
    for label, data in pairs(installedSkimmers) do
        clientSkimmers[label] = true
    end
    TriggerClientEvent('card-robbery:client:setSkimmers', src, clientSkimmers)
end)

RegisterNetEvent('card-robbery:server:removeSkimmer', function(atmLabel)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player or not installedSkimmers[atmLabel] then return end
    if player.PlayerData.job.name == 'police' then
        MySQL.execute('UPDATE card_skimmers SET active = 0 WHERE atm_label = ?', { atmLabel })
        installedSkimmers[atmLabel] = nil
        TriggerClientEvent('card-robbery:client:skimmerRemoved', -1, atmLabel)
    end
end)

QBox:CreateCallback('card-robbery:server:getDailyFraud', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return cb(0) end
    cb(getDailyFraud(player.PlayerData.citizenid))
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        loadSkimmers()
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    rateLimits[src] = nil
end)
