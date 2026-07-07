local QBox = exports['qbx-core']:GetCoreObject()
local rateLimits = {}
local strippedVehicles = {}

local function isRateLimited(src, key, limit, window)
    if not rateLimits[src] then rateLimits[src] = {} end
    local now = os.time()
    if not rateLimits[src][key] then rateLimits[src][key] = 0 end
    if now - rateLimits[src][key] < window then return true end
    rateLimits[src][key] = now
    return false
end

RegisterNetEvent('chop-shop:server:stripPart', function(partName, plate)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'strip_part', 1, 5) then return end
    if not Config.Parts[partName] then
        return Wrappers.Notify(src, 'That part does not exist', 'error')
    end
    if not strippedVehicles[plate] then
        strippedVehicles[plate] = {}
    end
    if strippedVehicles[plate][partName] then
        return Wrappers.Notify(src, 'This part has already been removed', 'error')
    end
    local policePlayers = QBox:GetPlayers()
    local policeCount = 0
    for _, pId in ipairs(policePlayers) do
        local p = QBox.Functions.GetPlayer(pId)
        if p and p.PlayerData.job.name == 'police' and p.PlayerData.job.onduty then
            policeCount = policeCount + 1
        end
    end
    if policeCount < Config.Stripping.minPolice then
        return Wrappers.Notify(src, 'Need ' .. Config.Stripping.minPolice .. ' police online', 'error')
    end
    player.Functions.AddItem(partName, 1)
    strippedVehicles[plate][partName] = true
    TriggerClientEvent('chop-shop:client:partStripped', src, Config.Parts[partName].label)
    MySQL.insert('INSERT INTO chop_shop_logs (citizenid, part, plate, action, date) VALUES (?, ?, ?, ?, NOW())', {
        player.PlayerData.citizenid, partName, plate, 'strip'
    })
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    exports['discord-logs']:sendLog('part_stripped', {
        message = charName .. ' stripped ' .. Config.Parts[partName].label .. ' from ' .. plate,
        source = src,
        color = 'orange'
    })
end)

RegisterNetEvent('chop-shop:server:removeVIN', function(plate)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'remove_vin', 1, 10) then return end
    local policePlayers = QBox:GetPlayers()
    local policeCount = 0
    for _, pId in ipairs(policePlayers) do
        local p = QBox.Functions.GetPlayer(pId)
        if p and p.PlayerData.job.name == 'police' and p.PlayerData.job.onduty then
            policeCount = policeCount + 1
        end
    end
    if policeCount < Config.Stripping.minPolice then
        return Wrappers.Notify(src, 'Need ' .. Config.Stripping.minPolice .. ' police online', 'error')
    end
    player.Functions.AddMoney('cash', Config.VINRemoval.reward)
    player.Functions.RemoveItem(Config.Tools.grindstoneItem, 1)
    TriggerClientEvent('chop-shop:client:vinRemoved', src)
    MySQL.insert('INSERT INTO chop_shop_logs (citizenid, plate, action, date) VALUES (?, ?, ?, NOW())', {
        player.PlayerData.citizenid, plate, 'vin_removal'
    })
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    exports['discord-logs']:sendLog('vin_removed', {
        message = charName .. ' removed VIN from ' .. plate,
        source = src,
        color = 'red'
    })
end)

RegisterNetEvent('chop-shop:server:scrapVehicle', function(plate)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'scrap', 1, 5) then return end
    player.Functions.AddItem(Config.Scrap.scrapItem, Config.Scrap.scrapPerVehicle)
    TriggerClientEvent('chop-shop:client:scrapReceived', src, Config.Scrap.scrapPerVehicle)
    MySQL.insert('INSERT INTO chop_shop_logs (citizenid, plate, action, date) VALUES (?, ?, ?, NOW())', {
        player.PlayerData.citizenid, plate, 'scrap'
    })
end)

RegisterNetEvent('chop-shop:server:sellScrap', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'sell_scrap', 1, 3) then return end
    local scrapItem = player.Functions.GetItemByName(Config.Scrap.scrapItem)
    if not scrapItem then
        return Wrappers.Notify(src, 'You have no scrap to sell', 'error')
    end
    local amount = scrapItem.amount
    local price = amount * Config.Scrap.scrapPrice
    player.Functions.RemoveItem(Config.Scrap.scrapItem, amount)
    player.Functions.AddMoney('cash', price)
    TriggerClientEvent('chop-shop:client:scrapSold', src, price)
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    exports['discord-logs']:sendLog('scrap_sold', {
        message = charName .. ' sold ' .. amount .. ' scrap for $' .. price,
        source = src,
        color = 'green'
    })
end)

RegisterNetEvent('chop-shop:server:alertPolice', function(coords)
    local src = source
    if isRateLimited(src, 'police_alert', 1, 30000) then return end
    local players = QBox:GetPlayers()
    for _, playerId in ipairs(players) do
        local player = QBox.Functions.GetPlayer(playerId)
        if player and player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
            TriggerClientEvent('chop-shop:client:policeAlert', playerId, coords)
        end
    end
    exports['discord-logs']:sendLog('chop_shop_alert', {
        message = 'Chop shop activity at ' .. json.encode(coords),
        color = 'red'
    })
end)

QBox:CreateCallback('chop-shop:server:getStrippedParts', function(source, cb, plate)
    if strippedVehicles[plate] then
        cb(strippedVehicles[plate])
    else
        cb({})
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    rateLimits[src] = nil
end)
