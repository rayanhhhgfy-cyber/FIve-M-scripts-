local QBox = exports['qbx-core']:GetCoreObject()
local rateLimits = {}
local fenceReputation = {}

local function isRateLimited(src, key, limit, window)
    if not rateLimits[src] then rateLimits[src] = {} end
    local now = os.time()
    if not rateLimits[src][key] then rateLimits[src][key] = 0 end
    if now - rateLimits[src][key] < window then return true end
    rateLimits[src][key] = now
    return false
end

local function loadReputation()
    local results = MySQL.query.await('SELECT * FROM fence_reputation')
    for _, row in ipairs(results) do
        fenceReputation[row.citizenid] = row.reputation
    end
end

local function saveReputation(citizenid, rep)
    MySQL.execute('INSERT INTO fence_reputation (citizenid, reputation) VALUES (?, ?) ON DUPLICATE KEY UPDATE reputation = VALUES(reputation)', {
        citizenid, rep
    })
end

RegisterNetEvent('jewelry-fence:server:sellItem', function(fence, itemName, amount, totalPrice)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'sell_fence', 1, Config.Fencing.cooldown) then
        return Wrappers.Notify(src, 'Fence is not interested right now', 'error')
    end
    if not Config.Items[itemName] then
        return Wrappers.Notify(src, 'Item cannot be fenced here', 'error')
    end
    local item = player.Functions.GetItemByName(itemName)
    if not item or item.amount < amount then
        return Wrappers.Notify(src, 'You do not have that many', 'error')
    end
    player.Functions.RemoveItem(itemName, amount)
    player.Functions.AddMoney('cash', totalPrice)
    local currentRep = fenceReputation[player.PlayerData.citizenid] or 0
    currentRep = currentRep + (Config.Fencing.reputationGain * amount)
    fenceReputation[player.PlayerData.citizenid] = currentRep
    saveReputation(player.PlayerData.citizenid, currentRep)
    TriggerClientEvent('jewelry-fence:client:setRep', src, currentRep)
    TriggerClientEvent('jewelry-fence:client:soldItem', src, Config.Items[itemName].label, totalPrice)
    MySQL.insert('INSERT INTO fencing_logs (citizenid, item, amount, price, fence, date) VALUES (?, ?, ?, ?, ?, NOW())', {
        player.PlayerData.citizenid, itemName, amount, totalPrice, fence.label
    })
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    exports['discord-logs']:sendLog('item_fenced', {
        message = charName .. ' fenced ' .. amount .. 'x ' .. itemName .. ' for $' .. totalPrice .. ' at ' .. fence.label,
        source = src,
        color = 'orange'
    })
end)

RegisterNetEvent('jewelry-fence:server:getRep', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local rep = fenceReputation[player.PlayerData.citizenid] or 0
    TriggerClientEvent('jewelry-fence:client:setRep', src, rep)
end)

RegisterNetEvent('jewelry-fence:server:alertPolice', function(coords)
    local src = source
    if isRateLimited(src, 'police_alert', 1, 30000) then return end
    local players = QBox:GetPlayers()
    for _, playerId in ipairs(players) do
        local player = QBox.Functions.GetPlayer(playerId)
        if player and player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
            TriggerClientEvent('jewelry-fence:client:policeAlert', playerId, coords)
        end
    end
end)

QBox:CreateCallback('jewelry-fence:server:getFenceRep', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return cb(0) end
    cb(fenceReputation[player.PlayerData.citizenid] or 0)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        loadReputation()
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    rateLimits[src] = nil
end)
