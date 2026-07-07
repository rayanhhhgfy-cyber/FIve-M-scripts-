local QBox = exports['qbx-core']:GetCoreObject()
local rateLimits = {}
local atmCooldowns = {}
local robberyCounts = {}

local function isRateLimited(src, key, limit, window)
    if not rateLimits[src] then rateLimits[src] = {} end
    local now = os.time()
    if not rateLimits[src][key] then rateLimits[src][key] = 0 end
    if now - rateLimits[src][key] < window then return true end
    rateLimits[src][key] = now
    return false
end

RegisterNetEvent('atm-robbery:server:robATM', function(atm, method)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'atm_rob', 1, 5) then return end
    if atmCooldowns[atm.label] and atmCooldowns[atm.label] > os.time() then
        local remaining = atmCooldowns[atm.label] - os.time()
        return TriggerClientEvent('atm-robbery:client:onCooldown', src, remaining)
    end
    local policePlayers = QBox:GetPlayers()
    local policeCount = 0
    for _, pId in ipairs(policePlayers) do
        local p = QBox.Functions.GetPlayer(pId)
        if p and p.PlayerData.job.name == 'police' and p.PlayerData.job.onduty then
            policeCount = policeCount + 1
        end
    end
    if policeCount < Config.Robbery.minPolice then
        return Wrappers.Notify(src, 'Need ' .. Config.Robbery.minPolice .. ' police online', 'error')
    end
    if method == 'drill' then
        local drill = player.Functions.GetItemByName(Config.Robbery.drillItem)
        if not drill then return end
        player.Functions.RemoveItem(Config.Robbery.drillItem, 1)
    elseif method == 'explosive' then
        local c4 = player.Functions.GetItemByName(Config.Robbery.explosiveItem)
        if not c4 then return end
        player.Functions.RemoveItem(Config.Robbery.explosiveItem, 1)
    end
    local lootAmount = math.random(Config.Robbery.lootMin, Config.Robbery.lootMax)
    local lootBags = math.random(1, Config.Robbery.maxLootBags)
    local perBag = math.floor(lootAmount / lootBags)
    for i = 1, lootBags do
        player.Functions.AddItem(Config.Robbery.lootBagItem, 1, nil, { amount = perBag })
    end
    atmCooldowns[atm.label] = os.time() + Config.Robbery.cooldown
    robberyCounts[player.PlayerData.citizenid] = (robberyCounts[player.PlayerData.citizenid] or 0) + 1
    TriggerClientEvent('atm-robbery:client:robberyResult', src, true, lootAmount)
    if math.random() < Config.Robbery.policeAlertChance then
        for _, pId in ipairs(policePlayers) do
            local p = QBox.Functions.GetPlayer(pId)
            if p and p.PlayerData.job.name == 'police' and p.PlayerData.job.onduty then
                TriggerClientEvent('atm-robbery:client:policeAlert', pId, atm.coords, atm.label)
            end
        end
    end
    MySQL.insert('INSERT INTO atm_robberies (citizenid, atm_label, method, loot, date) VALUES (?, ?, ?, ?, NOW())', {
        player.PlayerData.citizenid, atm.label, method, lootAmount
    })
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    exports['discord-logs']:sendLog('atm_robbery', {
        message = charName .. ' robbed ' .. atm.label .. ' using ' .. method .. ' for $' .. lootAmount,
        source = src,
        color = 'red'
    })
end)

RegisterNetEvent('atm-robbery:server:cashLootBag', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'cash_loot', 1, 3) then return end
    local bag = player.Functions.GetItemByName(Config.Robbery.lootBagItem)
    if not bag then
        return Wrappers.Notify(src, 'You have no loot bags', 'error')
    end
    local amount = bag.info.amount or math.random(Config.Robbery.lootMin, Config.Robbery.lootMax)
    player.Functions.RemoveItem(Config.Robbery.lootBagItem, 1)
    local fee = math.floor(amount * 0.1)
    local clean = amount - fee
    player.Functions.AddMoney('cash', clean)
    TriggerClientEvent('atm-robbery:client:lootReceived', src, clean)
end)

QBox:CreateCallback('atm-robbery:server:getCooldown', function(source, cb, atmLabel)
    if atmCooldowns[atmLabel] then
        cb(atmCooldowns[atmLabel] - os.time())
    else
        cb(0)
    end
end)

QBox:CreateCallback('atm-robbery:server:getRobberyCount', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return cb(0) end
    cb(robberyCounts[player.PlayerData.citizenid] or 0)
end)

AddEventHandler('playerDropped', function()
    local src = source
    rateLimits[src] = nil
end)
