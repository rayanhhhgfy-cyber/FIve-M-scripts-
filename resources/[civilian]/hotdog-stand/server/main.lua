local activeWorkers = {}
local wageTimers = {}

MySQL.query('CREATE TABLE IF NOT EXISTS hotdog_shifts (id INT AUTO_INCREMENT PRIMARY KEY, citizenid VARCHAR(50) NOT NULL, start_time INT NOT NULL, end_time INT DEFAULT NULL, earnings INT DEFAULT 0, items_sold INT DEFAULT 0)')

MySQL.query('CREATE TABLE IF NOT EXISTS hotdog_sales (id INT AUTO_INCREMENT PRIMARY KEY, shift_id INT, citizenid VARCHAR(50), item VARCHAR(50), price INT, sale_type VARCHAR(20), sold_at INT, FOREIGN KEY (shift_id) REFERENCES hotdog_shifts(id))')

local function LogToDiscord(message, color)
    if Config.DiscordWebhook == '' then return end
    local embed = {
        {
            ['color'] = color or 16753920,
            ['title'] = 'Hotdog Stand Log',
            ['description'] = message,
            ['footer'] = { ['text'] = os.date('%Y-%m-%d %H:%M:%S') }
        }
    }
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({ embeds = embed }), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('hotdog:server:startShift', function()
    local src = source
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    if activeWorkers[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Hotdog Stand', description = 'Already on shift', type = 'error' })
        return
    end
    MySQL.insert('INSERT INTO hotdog_shifts (citizenid, start_time) VALUES (?, ?)', { citizenid, os.time() }, function(insertId)
        if insertId then
            activeWorkers[src] = {
                id = insertId,
                citizenid = citizenid,
                startTime = os.time(),
                itemsSold = 0,
                earnings = 0
            }
            LogToDiscord('Player ' .. GetPlayerName(src) .. ' started a hotdog stand shift', 3066993)
            local wageTimer = Citizen.CreateThread(function()
                while activeWorkers[src] do
                    Citizen.Wait(Config.WagePaymentInterval)
                    if activeWorkers[src] then
                        Player.Functions.AddMoney('cash', Config.HourlyWage)
                        activeWorkers[src].earnings = activeWorkers[src].earnings + Config.HourlyWage
                        TriggerClientEvent('ox_lib:notify', src, { title = 'Hotdog Stand', description = 'Hourly wage paid: $' .. Config.HourlyWage, type = 'success' })
                        LogToDiscord('Hourly wage paid to ' .. GetPlayerName(src) .. ': $' .. Config.HourlyWage, 16753920)
                    end
                end
            end)
            wageTimers[src] = wageTimer
            local npcTimer = Citizen.CreateThread(function()
                while activeWorkers[src] do
                    Citizen.Wait(math.random(Config.NPCCustomerInterval.min, Config.NPCCustomerInterval.max))
                    if activeWorkers[src] then
                        TriggerClientEvent('hotdog:client:npcCustomer', src)
                    end
                end
            end)
            activeWorkers[src].npcTimer = npcTimer
        end
    end)
end)

RegisterNetEvent('hotdog:server:endShift', function()
    local src = source
    if not activeWorkers[src] then return end
    local worker = activeWorkers[src]
    MySQL.update('UPDATE hotdog_shifts SET end_time = ?, earnings = ?, items_sold = ? WHERE id = ?', { os.time(), worker.earnings, worker.itemsSold, worker.id })
    if wageTimers[src] then
        Citizen.StopThread(wageTimers[src])
        wageTimers[src] = nil
    end
    if worker.npcTimer then
        Citizen.StopThread(worker.npcTimer)
        worker.npcTimer = nil
    end
    local totalEarnings = worker.earnings
    activeWorkers[src] = nil
    TriggerClientEvent('hotdog:client:endShift', src)
    LogToDiscord('Player ' .. GetPlayerName(src) .. ' ended hotdog shift. Earnings: $' .. totalEarnings, 16753920)
end)

RegisterNetEvent('hotdog:server:purchaseItem', function(itemKey, price)
    local src = source
    if not activeWorkers[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Hotdog Stand', description = 'Not on shift', type = 'error' })
        return
    end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    local buyer = GetPlayerPed(src)
    local closestPlayers = GetPlayers()
    local validBuyer = false
    for _, playerId in ipairs(closestPlayers) do
        if playerId ~= src then
            local ped = GetPlayerPed(playerId)
            local dist = #(GetEntityCoords(ped) - GetEntityCoords(buyer))
            if dist < 5.0 then
                validBuyer = playerId
                break
            end
        end
    end
    if not validBuyer then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Hotdog Stand', description = 'No customer nearby', type = 'error' })
        return
    end
    local buyerPlayer = exports.ox_lib:GetPlayer(validBuyer)
    if not buyerPlayer then return end
    if buyerPlayer.Functions.RemoveMoney('cash', price) then
        Player.Functions.AddMoney('cash', price)
        activeWorkers[src].itemsSold = activeWorkers[src].itemsSold + 1
        activeWorkers[src].earnings = activeWorkers[src].earnings + price
        local itemLabel = Config.Items[itemKey] and Config.Items[itemKey].label or itemKey
        local itemEmoji = Config.Items[itemKey] and Config.Items[itemKey].emoji or ''
        TriggerClientEvent('ox_lib:notify', validBuyer, { title = 'Hotdog Stand', description = 'You bought a ' .. itemLabel .. ' for $' .. price, type = 'success' })
        TriggerClientEvent('ox_lib:notify', src, { title = 'Hotdog Stand', description = 'Sold ' .. itemLabel .. ' for $' .. price, type = 'success' })
        MySQL.insert('INSERT INTO hotdog_sales (shift_id, citizenid, item, price, sale_type, sold_at) VALUES (?, ?, ?, ?, ?, ?)', {
            activeWorkers[src].id,
            activeWorkers[src].citizenid,
            itemKey,
            price,
            'player',
            os.time()
        })
        LogToDiscord(GetPlayerName(src) .. ' sold ' .. itemLabel .. ' to ' .. GetPlayerName(validBuyer) .. ' for $' .. price, 3066993)
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'Hotdog Stand', description = 'Customer does not have enough money', type = 'error' })
    end
end)

RegisterNetEvent('hotdog:server:npcSale', function(itemKey, price)
    local src = source
    if not activeWorkers[src] then return end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    Player.Functions.AddMoney('cash', price)
    activeWorkers[src].itemsSold = activeWorkers[src].itemsSold + 1
    activeWorkers[src].earnings = activeWorkers[src].earnings + price
    local itemLabel = Config.Items[itemKey] and Config.Items[itemKey].label or itemKey
    TriggerClientEvent('ox_lib:notify', src, { title = 'Hotdog Stand', description = 'NPC bought ' .. itemLabel .. ' for $' .. price, type = 'success' })
    MySQL.insert('INSERT INTO hotdog_sales (shift_id, citizenid, item, price, sale_type, sold_at) VALUES (?, ?, ?, ?, ?, ?)', {
        activeWorkers[src].id,
        activeWorkers[src].citizenid,
        itemKey,
        price,
        'npc',
        os.time()
    })
end)

RegisterNetEvent('hotdog:server:restock', function(supplyItem, amount)
    local src = source
    if not activeWorkers[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Hotdog Stand', description = 'Not on shift', type = 'error' })
        return
    end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    if not Player.Functions.RemoveItem(supplyItem, 1) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Hotdog Stand', description = 'You do not have ' .. supplyItem, type = 'error' })
        return
    end
    local itemKey = nil
    for k, _ in pairs(Config.Items) do
        itemKey = k
    end
    if itemKey then
        TriggerClientEvent('hotdog:client:updateStock', src, itemKey, amount)
    end
    TriggerClientEvent('ox_lib:notify', src, { title = 'Hotdog Stand', description = 'Restocked!', type = 'success' })
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activeWorkers[src] then
        local worker = activeWorkers[src]
        MySQL.update('UPDATE hotdog_shifts SET end_time = ?, earnings = ?, items_sold = ? WHERE id = ?', { os.time(), worker.earnings, worker.itemsSold, worker.id })
        if wageTimers[src] then
            Citizen.StopThread(wageTimers[src])
            wageTimers[src] = nil
        end
        if worker.npcTimer then
            Citizen.StopThread(worker.npcTimer)
        end
        activeWorkers[src] = nil
        LogToDiscord(GetPlayerName(src) .. ' disconnected during hotdog shift', 15158332)
    end
end)
