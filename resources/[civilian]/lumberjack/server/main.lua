local activeLumberjacks = {}
local treeRespawns = {}
local rateLimits = {}

MySQL.query('CREATE TABLE IF NOT EXISTS lumberjack_shifts (id INT AUTO_INCREMENT PRIMARY KEY, citizenid VARCHAR(50) NOT NULL, start_time INT NOT NULL, end_time INT DEFAULT NULL, trees_chopped INT DEFAULT 0, planks_made INT DEFAULT 0, planks_sold INT DEFAULT 0, earnings INT DEFAULT 0)')

MySQL.query('CREATE TABLE IF NOT EXISTS lumberjack_logs (id INT AUTO_INCREMENT PRIMARY KEY, shift_id INT, citizenid VARCHAR(50), action VARCHAR(50), wood_type VARCHAR(50), amount INT, earnings INT DEFAULT 0, created_at INT, FOREIGN KEY (shift_id) REFERENCES lumberjack_shifts(id))')

MySQL.query('CREATE TABLE IF NOT EXISTS lumberjack_tree_state (tree_index INT PRIMARY KEY, chopped BOOLEAN DEFAULT FALSE, chopped_at INT DEFAULT 0, respawn_at INT DEFAULT 0)')

local function LogToDiscord(message, color)
    if Config.DiscordWebhook == '' then return end
    local embed = {
        {
            ['color'] = color or 16753920,
            ['title'] = 'Lumberjack Log',
            ['description'] = message,
            ['footer'] = { ['text'] = os.date('%Y-%m-%d %H:%M:%S') }
        }
    }
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({ embeds = embed }), { ['Content-Type'] = 'application/json' })
end

local function IsRateLimited(src)
    if not rateLimits[src] then
        rateLimits[src] = {}
    end
    local now = os.time()
    rateLimits[src].lastAction = now
    if rateLimits[src].actions and #rateLimits[src].actions >= 10 then
        local oldest = rateLimits[src].actions[1]
        if now - oldest < 5 then
            return true
        end
        table.remove(rateLimits[src].actions, 1)
    end
    if not rateLimits[src].actions then
        rateLimits[src].actions = {}
    end
    table.insert(rateLimits[src].actions, now)
    return false
end

RegisterNetEvent('lumberjack:server:startShift', function()
    local src = source
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    if activeLumberjacks[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Already on shift', type = 'error' })
        return
    end
    local hasAxe = Player.Functions.GetItemByName(Config.AxeItem)
    local hasChainsaw = Config.ChainsawItem and Player.Functions.GetItemByName(Config.ChainsawItem)
    if not hasAxe and not hasChainsaw then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'You need an axe or chainsaw', type = 'error' })
        return
    end
    MySQL.insert('INSERT INTO lumberjack_shifts (citizenid, start_time) VALUES (?, ?)', { citizenid, os.time() }, function(insertId)
        if insertId then
            activeLumberjacks[src] = {
                id = insertId,
                citizenid = citizenid,
                startTime = os.time(),
                treesChopped = 0,
                planksMade = 0,
                planksSold = 0,
                earnings = 0
            }
            TriggerClientEvent('lumberjack:client:startShift', src)
            LogToDiscord('Player ' .. GetPlayerName(src) .. ' started a lumberjack shift', 3066993)
        end
    end)
end)

RegisterNetEvent('lumberjack:server:endShift', function()
    local src = source
    if not activeLumberjacks[src] then return end
    local lumberjack = activeLumberjacks[src]
    MySQL.update('UPDATE lumberjack_shifts SET end_time = ?, trees_chopped = ?, planks_made = ?, planks_sold = ?, earnings = ? WHERE id = ?', {
        os.time(),
        lumberjack.treesChopped,
        lumberjack.planksMade,
        lumberjack.planksSold,
        lumberjack.earnings,
        lumberjack.id
    })
    local totalEarnings = lumberjack.earnings
    activeLumberjacks[src] = nil
    TriggerClientEvent('lumberjack:client:endShift', src)
    LogToDiscord('Player ' .. GetPlayerName(src) .. ' ended lumberjack shift. Earnings: $' .. totalEarnings, 16753920)
end)

RegisterNetEvent('lumberjack:server:chopTree', function(treeIndex, woodType, amount)
    local src = source
    if not activeLumberjacks[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Not on shift', type = 'error' })
        return
    end
    if IsRateLimited(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Slow down!', type = 'error' })
        return
    end
    if not treeIndex or treeIndex < 1 or treeIndex > #Config.TreeLocations then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Invalid tree', type = 'error' })
        return
    end
    if not Config.WoodTypes[woodType] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Invalid wood type', type = 'error' })
        return
    end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    activeLumberjacks[src].treesChopped = activeLumberjacks[src].treesChopped + 1
    MySQL.insert('INSERT INTO lumberjack_logs (shift_id, citizenid, action, wood_type, amount, earnings, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        activeLumberjacks[src].id,
        activeLumberjacks[src].citizenid,
        'chop',
        woodType,
        amount,
        0,
        os.time()
    })
    MySQL.insert('INSERT INTO lumberjack_tree_state (tree_index, chopped, chopped_at, respawn_at) VALUES (?, TRUE, ?, ?) ON DUPLICATE KEY UPDATE chopped = TRUE, chopped_at = ?, respawn_at = ?', {
        treeIndex,
        os.time(),
        os.time() + math.floor(Config.TreeRespawnTime / 1000),
        os.time(),
        os.time() + math.floor(Config.TreeRespawnTime / 1000)
    })
    TriggerClientEvent('lumberjack:client:syncChopped', -1, treeIndex, true)
    LogToDiscord(GetPlayerName(src) .. ' chopped tree #' .. treeIndex .. ' (' .. woodType .. ' x' .. amount .. ')', 3066993)
end)

RegisterNetEvent('lumberjack:server:respawnTree', function(treeIndex)
    local src = source
    if not activeLumberjacks[src] then return end
    MySQL.update('UPDATE lumberjack_tree_state SET chopped = FALSE WHERE tree_index = ?', { treeIndex })
    TriggerClientEvent('lumberjack:client:syncChopped', -1, treeIndex, false)
end)

RegisterNetEvent('lumberjack:server:processWood', function(woodType, amount)
    local src = source
    if not activeLumberjacks[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Not on shift', type = 'error' })
        return
    end
    if IsRateLimited(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Slow down!', type = 'error' })
        return
    end
    if amount < 1 or amount > 10 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Invalid amount', type = 'error' })
        return
    end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    local planksToAdd = amount * 2
    Player.Functions.AddItem(Config.PlanksItem, planksToAdd)
    activeLumberjacks[src].planksMade = activeLumberjacks[src].planksMade + planksToAdd
    MySQL.insert('INSERT INTO lumberjack_logs (shift_id, citizenid, action, wood_type, amount, earnings, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        activeLumberjacks[src].id,
        activeLumberjacks[src].citizenid,
        'process',
        woodType,
        amount,
        0,
        os.time()
    })
    TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Processed ' .. amount .. 'x ' .. woodType .. ' into ' .. planksToAdd .. ' planks', type = 'success' })
    LogToDiscord(GetPlayerName(src) .. ' processed ' .. amount .. 'x ' .. woodType .. ' into ' .. planksToAdd .. ' planks', 3066993)
end)

RegisterNetEvent('lumberjack:server:sellPlanks', function(amount, price)
    local src = source
    if not activeLumberjacks[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Not on shift', type = 'error' })
        return
    end
    if IsRateLimited(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Slow down!', type = 'error' })
        return
    end
    if amount < 1 or amount > 100 or price ~= amount * Config.SellPricePerPlank then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Invalid sale', type = 'error' })
        return
    end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    if not Player.Functions.RemoveItem(Config.PlanksItem, amount) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Not enough planks', type = 'error' })
        return
    end
    Player.Functions.AddMoney('cash', price)
    activeLumberjacks[src].planksSold = activeLumberjacks[src].planksSold + amount
    activeLumberjacks[src].earnings = activeLumberjacks[src].earnings + price
    MySQL.insert('INSERT INTO lumberjack_logs (shift_id, citizenid, action, wood_type, amount, earnings, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        activeLumberjacks[src].id,
        activeLumberjacks[src].citizenid,
        'sell',
        'planks',
        amount,
        price,
        os.time()
    })
    TriggerClientEvent('ox_lib:notify', src, { title = 'Lumberjack', description = 'Sold ' .. amount .. ' planks for $' .. price, type = 'success' })
    LogToDiscord(GetPlayerName(src) .. ' sold ' .. amount .. ' planks for $' .. price, 3066993)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activeLumberjacks[src] then
        local lumberjack = activeLumberjacks[src]
        MySQL.update('UPDATE lumberjack_shifts SET end_time = ?, trees_chopped = ?, planks_made = ?, planks_sold = ?, earnings = ? WHERE id = ?', {
            os.time(),
            lumberjack.treesChopped,
            lumberjack.planksMade,
            lumberjack.planksSold,
            lumberjack.earnings,
            lumberjack.id
        })
        activeLumberjacks[src] = nil
        LogToDiscord(GetPlayerName(src) .. ' disconnected during lumberjack shift', 15158332)
    end
end)

Citizen.CreateThread(function()
    MySQL.query('SELECT * FROM lumberjack_tree_state WHERE chopped = TRUE', {}, function(results)
        if results and #results > 0 then
            local now = os.time()
            for _, row in ipairs(results) do
                if row.respawn_at and row.respawn_at <= now then
                    MySQL.update('UPDATE lumberjack_tree_state SET chopped = FALSE WHERE tree_index = ?', { row.tree_index })
                elseif row.respawn_at and row.respawn_at > now then
                    local remaining = (row.respawn_at - now) * 1000
                    Citizen.SetTimeout(remaining, function()
                        MySQL.update('UPDATE lumberjack_tree_state SET chopped = FALSE WHERE tree_index = ?', { row.tree_index })
                    end)
                end
            end
        end
    end)
end)
