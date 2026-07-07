local activeReporters = {}
local broadcastCooldowns = {}

MySQL.query('CREATE TABLE IF NOT EXISTS news_shifts (id INT AUTO_INCREMENT PRIMARY KEY, citizenid VARCHAR(50) NOT NULL, start_time INT NOT NULL, end_time INT DEFAULT NULL, broadcasts_completed INT DEFAULT 0, earnings INT DEFAULT 0)')

MySQL.query('CREATE TABLE IF NOT EXISTS news_broadcasts (id INT AUTO_INCREMENT PRIMARY KEY, shift_id INT, citizenid VARCHAR(50), location VARCHAR(100), payment INT, completed_at INT, FOREIGN KEY (shift_id) REFERENCES news_shifts(id))')

local function LogToDiscord(message, color)
    if Config.DiscordWebhook == '' then return end
    local embed = {
        {
            ['color'] = color or 16753920,
            ['title'] = 'News Job Log',
            ['description'] = message,
            ['footer'] = { ['text'] = os.date('%Y-%m-%d %H:%M:%S') }
        }
    }
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({ embeds = embed }), { ['Content-Type'] = 'application/json' })
end

local function IsOnCooldown(src)
    if broadcastCooldowns[src] and broadcastCooldowns[src] > os.time() then
        return true
    end
    return false
end

local function IsValidBroadcastLocation(locationName)
    for _, loc in ipairs(Config.BroadcastLocations) do
        if loc.name == locationName then
            return true
        end
    end
    return false
end

RegisterNetEvent('news:server:startShift', function()
    local src = source
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    if activeReporters[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'Already on shift', type = 'error' })
        return
    end
    MySQL.insert('INSERT INTO news_shifts (citizenid, start_time) VALUES (?, ?)', { citizenid, os.time() }, function(insertId)
        if insertId then
            activeReporters[src] = {
                id = insertId,
                citizenid = citizenid,
                startTime = os.time(),
                broadcastsCompleted = 0,
                earnings = 0
            }
            TriggerClientEvent('news:client:startShift', src)
            LogToDiscord('Player ' .. GetPlayerName(src) .. ' started a news shift', 3066993)
        end
    end)
end)

RegisterNetEvent('news:server:endShift', function()
    local src = source
    if not activeReporters[src] then return end
    local reporter = activeReporters[src]
    MySQL.update('UPDATE news_shifts SET end_time = ?, broadcasts_completed = ?, earnings = ? WHERE id = ?', {
        os.time(),
        reporter.broadcastsCompleted,
        reporter.earnings,
        reporter.id
    })
    local totalEarnings = reporter.earnings
    activeReporters[src] = nil
    TriggerClientEvent('news:client:endShift', src)
    LogToDiscord('Player ' .. GetPlayerName(src) .. ' ended news shift. Earnings: $' .. totalEarnings, 16753920)
end)

RegisterNetEvent('news:server:completeBroadcast', function(locationName)
    local src = source
    if not activeReporters[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'Not on shift', type = 'error' })
        return
    end
    if not locationName or not IsValidBroadcastLocation(locationName) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'Invalid broadcast location', type = 'error' })
        return
    end
    if IsOnCooldown(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'Please wait before broadcasting again', type = 'error' })
        return
    end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    local payment = Config.PaymentPerBroadcast
    if payment < 1 or payment > 10000 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'Invalid payment amount', type = 'error' })
        return
    end
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local validLocation = false
    for _, loc in ipairs(Config.BroadcastLocations) do
        local dist = #(playerCoords - loc.coords)
        if dist < 15.0 and loc.name == locationName then
            validLocation = true
            break
        end
    end
    if not validLocation then
        TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'You are not at the broadcast location', type = 'error' })
        return
    end
    Player.Functions.AddMoney('cash', payment)
    activeReporters[src].broadcastsCompleted = activeReporters[src].broadcastsCompleted + 1
    activeReporters[src].earnings = activeReporters[src].earnings + payment
    broadcastCooldowns[src] = os.time() + math.floor(Config.MinBroadcastInterval / 1000)
    MySQL.insert('INSERT INTO news_broadcasts (shift_id, citizenid, location, payment, completed_at) VALUES (?, ?, ?, ?, ?)', {
        activeReporters[src].id,
        activeReporters[src].citizenid,
        locationName,
        payment,
        os.time()
    })
    TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'Broadcast payment: $' .. payment, type = 'success' })
    LogToDiscord(GetPlayerName(src) .. ' broadcast from ' .. locationName .. ' earned $' .. payment, 3066993)
end)

RegisterNetEvent('news:server:requestEquipment', function(itemType)
    local src = source
    if not activeReporters[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'Not on shift', type = 'error' })
        return
    end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    local itemName = nil
    if itemType == 'camera' then
        itemName = Config.Equipment.camera
    elseif itemType == 'mic' then
        itemName = Config.Equipment.mic
    end
    if not itemName then
        TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'Invalid equipment type', type = 'error' })
        return
    end
    if Player.Functions.GetItemByName(itemName) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'You already have this item', type = 'info' })
        return
    end
    Player.Functions.AddItem(itemName, 1)
    TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'Equipment issued: ' .. itemName, type = 'success' })
end)

RegisterNetEvent('news:server:returnEquipment', function(itemType)
    local src = source
    if not activeReporters[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'Not on shift', type = 'error' })
        return
    end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    local itemName = nil
    if itemType == 'camera' then
        itemName = Config.Equipment.camera
    elseif itemType == 'mic' then
        itemName = Config.Equipment.mic
    end
    if not itemName then return end
    Player.Functions.RemoveItem(itemName, 1)
    TriggerClientEvent('ox_lib:notify', src, { title = 'News', description = 'Equipment returned', type = 'info' })
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activeReporters[src] then
        local reporter = activeReporters[src]
        MySQL.update('UPDATE news_shifts SET end_time = ?, broadcasts_completed = ?, earnings = ? WHERE id = ?', {
            os.time(),
            reporter.broadcastsCompleted,
            reporter.earnings,
            reporter.id
        })
        activeReporters[src] = nil
        LogToDiscord(GetPlayerName(src) .. ' disconnected during news shift', 15158332)
    end
end)
