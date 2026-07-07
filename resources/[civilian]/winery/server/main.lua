local activeWineryWorkers = {}
local rateLimits = {}

MySQL.query('CREATE TABLE IF NOT EXISTS winery_shifts (id INT AUTO_INCREMENT PRIMARY KEY, citizenid VARCHAR(50) NOT NULL, start_time INT NOT NULL, end_time INT DEFAULT NULL, grapes_harvested INT DEFAULT 0, bottles_produced INT DEFAULT 0, bottles_sold INT DEFAULT 0, earnings INT DEFAULT 0)')

MySQL.query('CREATE TABLE IF NOT EXISTS winery_production (id INT AUTO_INCREMENT PRIMARY KEY, shift_id INT, citizenid VARCHAR(50), wine_type VARCHAR(50), quantity INT, quality INT, quality_label VARCHAR(20), created_at INT, FOREIGN KEY (shift_id) REFERENCES winery_shifts(id))')

MySQL.query('CREATE TABLE IF NOT EXISTS winery_sales (id INT AUTO_INCREMENT PRIMARY KEY, shift_id INT, citizenid VARCHAR(50), wine_type VARCHAR(50), quantity INT, price_per INT, total_price INT, quality INT, sold_at INT, FOREIGN KEY (shift_id) REFERENCES winery_shifts(id))')

local function LogToDiscord(message, color)
    if Config.DiscordWebhook == '' then return end
    local embed = {
        {
            ['color'] = color or 16753920,
            ['title'] = 'Winery Log',
            ['description'] = message,
            ['footer'] = { ['text'] = os.date('%Y-%m-%d %H:%M:%S') }
        }
    }
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({ embeds = embed }), { ['Content-Type'] = 'application/json' })
end

local function IsRateLimited(src)
    if not rateLimits[src] then
        rateLimits[src] = { actions = {} }
    end
    local now = os.time()
    if #rateLimits[src].actions >= 15 then
        local oldest = rateLimits[src].actions[1]
        if now - oldest < 5 then
            return true
        end
        table.remove(rateLimits[src].actions, 1)
    end
    table.insert(rateLimits[src].actions, now)
    return false
end

local function GetQualityLabel(quality)
    for _, level in ipairs(Config.QualityLevels) do
        if quality >= level.min and quality <= level.max then
            return level.label
        end
    end
    return 'Standard'
end

RegisterNetEvent('winery:server:startShift', function()
    local src = source
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    if activeWineryWorkers[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Already on shift', type = 'error' })
        return
    end
    MySQL.insert('INSERT INTO winery_shifts (citizenid, start_time) VALUES (?, ?)', { citizenid, os.time() }, function(insertId)
        if insertId then
            activeWineryWorkers[src] = {
                id = insertId,
                citizenid = citizenid,
                startTime = os.time(),
                grapesHarvested = 0,
                bottlesProduced = 0,
                bottlesSold = 0,
                earnings = 0
            }
            TriggerClientEvent('winery:client:startShift', src)
            LogToDiscord('Player ' .. GetPlayerName(src) .. ' started a winery shift', 3066993)
        end
    end)
end)

RegisterNetEvent('winery:server:endShift', function()
    local src = source
    if not activeWineryWorkers[src] then return end
    local worker = activeWineryWorkers[src]
    MySQL.update('UPDATE winery_shifts SET end_time = ?, grapes_harvested = ?, bottles_produced = ?, bottles_sold = ?, earnings = ? WHERE id = ?', {
        os.time(),
        worker.grapesHarvested,
        worker.bottlesProduced,
        worker.bottlesSold,
        worker.earnings,
        worker.id
    })
    local totalEarnings = worker.earnings
    activeWineryWorkers[src] = nil
    TriggerClientEvent('winery:client:endShift', src)
    LogToDiscord('Player ' .. GetPlayerName(src) .. ' ended winery shift. Earnings: $' .. totalEarnings, 16753920)
end)

RegisterNetEvent('winery:server:harvestGrapes', function(zoneIndex, amount)
    local src = source
    if not activeWineryWorkers[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Not on shift', type = 'error' })
        return
    end
    if IsRateLimited(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Slow down!', type = 'error' })
        return
    end
    if not zoneIndex or zoneIndex < 1 or zoneIndex > #Config.GrapeHarvestZones then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Invalid harvest zone', type = 'error' })
        return
    end
    if amount < 1 or amount > 10 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Invalid harvest amount', type = 'error' })
        return
    end
    local playerPed = GetPlayerPed(src)
    if not playerPed or playerPed == 0 then return end
    local playerCoords = GetEntityCoords(playerPed)
    local zoneCoords = Config.GrapeHarvestZones[zoneIndex]
    local dist = #(playerCoords - zoneCoords)
    if dist > 5.0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'You are not at the harvest zone', type = 'error' })
        return
    end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    activeWineryWorkers[src].grapesHarvested = activeWineryWorkers[src].grapesHarvested + amount
    LogToDiscord(GetPlayerName(src) .. ' harvested ' .. amount .. ' grapes at zone #' .. zoneIndex, 3066993)
end)

RegisterNetEvent('winery:server:processWine', function(wineType, wineData, quality, qualityMult)
    local src = source
    if not activeWineryWorkers[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Not on shift', type = 'error' })
        return
    end
    if IsRateLimited(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Slow down!', type = 'error' })
        return
    end
    if not Config.WineTypes[wineType] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Invalid wine type', type = 'error' })
        return
    end
    if not wineData or not wineData.grapes then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Invalid wine data', type = 'error' })
        return
    end
    local playerPed = GetPlayerPed(src)
    if not playerPed or playerPed == 0 then return end
    local playerCoords = GetEntityCoords(playerPed)
    local pressCoords = Config.WinePressLocation
    local dist = #(playerCoords - pressCoords)
    if dist > 5.0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'You are not at the wine press', type = 'error' })
        return
    end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    local qualityClamped = math.max(0, math.min(100, quality or 50))
    local qualityLabel = GetQualityLabel(qualityClamped)
    local priceWithQuality = math.floor(wineData.price * (qualityMult or 1.0))
    Player.Functions.AddItem(Config.WineBottleItem, 1)
    activeWineryWorkers[src].bottlesProduced = activeWineryWorkers[src].bottlesProduced + 1
    MySQL.insert('INSERT INTO winery_production (shift_id, citizenid, wine_type, quantity, quality, quality_label, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        activeWineryWorkers[src].id,
        activeWineryWorkers[src].citizenid,
        wineType,
        1,
        qualityClamped,
        qualityLabel,
        os.time()
    })
    TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Produced ' .. Config.WineTypes[wineType].label .. ' (Quality: ' .. qualityLabel .. ' | Est. Value: $' .. priceWithQuality .. ')', type = 'success' })
    LogToDiscord(GetPlayerName(src) .. ' produced ' .. Config.WineTypes[wineType].label .. ' (Quality: ' .. qualityLabel .. ', Value: $' .. priceWithQuality .. ')', 3066993)
end)

RegisterNetEvent('winery:server:sellWine', function(wineType, quantity, pricePer)
    local src = source
    if not activeWineryWorkers[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Not on shift', type = 'error' })
        return
    end
    if IsRateLimited(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Slow down!', type = 'error' })
        return
    end
    if not Config.WineTypes[wineType] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Invalid wine type', type = 'error' })
        return
    end
    if quantity < 1 or quantity > 10 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Invalid quantity', type = 'error' })
        return
    end
    local wineData = Config.WineTypes[wineType]
    local expectedPrice = math.floor(wineData.price)
    if pricePer < expectedPrice * 0.5 or pricePer > expectedPrice * 2.0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Price mismatch', type = 'error' })
        return
    end
    local playerPed = GetPlayerPed(src)
    if not playerPed or playerPed == 0 then return end
    local playerCoords = GetEntityCoords(playerPed)
    local sellCoords = Config.RestaurantSellLocation
    local dist = #(playerCoords - sellCoords)
    if dist > 5.0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'You are not at the restaurant', type = 'error' })
        return
    end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    if not Player.Functions.RemoveItem(Config.WineBottleItem, quantity) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Not enough wine bottles', type = 'error' })
        return
    end
    local totalPrice = pricePer * quantity
    Player.Functions.AddMoney('cash', totalPrice)
    activeWineryWorkers[src].bottlesSold = activeWineryWorkers[src].bottlesSold + quantity
    activeWineryWorkers[src].earnings = activeWineryWorkers[src].earnings + totalPrice
    MySQL.insert('INSERT INTO winery_sales (shift_id, citizenid, wine_type, quantity, price_per, total_price, quality, sold_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        activeWineryWorkers[src].id,
        activeWineryWorkers[src].citizenid,
        wineType,
        quantity,
        pricePer,
        totalPrice,
        0,
        os.time()
    })
    TriggerClientEvent('ox_lib:notify', src, { title = 'Winery', description = 'Sold ' .. quantity .. 'x ' .. wineData.label .. ' for $' .. totalPrice, type = 'success' })
    LogToDiscord(GetPlayerName(src) .. ' sold ' .. quantity .. 'x ' .. wineData.label .. ' for $' .. totalPrice, 3066993)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activeWineryWorkers[src] then
        local worker = activeWineryWorkers[src]
        MySQL.update('UPDATE winery_shifts SET end_time = ?, grapes_harvested = ?, bottles_produced = ?, bottles_sold = ?, earnings = ? WHERE id = ?', {
            os.time(),
            worker.grapesHarvested,
            worker.bottlesProduced,
            worker.bottlesSold,
            worker.earnings,
            worker.id
        })
        activeWineryWorkers[src] = nil
        LogToDiscord(GetPlayerName(src) .. ' disconnected during winery shift', 15158332)
    end
end)
