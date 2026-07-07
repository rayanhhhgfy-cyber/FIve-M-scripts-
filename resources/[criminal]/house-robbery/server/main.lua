local QBox = exports['qbx-core']:GetCoreObject()
local activeBurglaries = {}

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('house:server:breakIn', function(id, lockpick)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'houseBreak', 5) or activeBurglaries[id] then return end
    p.Functions.RemoveItem(lockpick, 1)
    activeBurglaries[id] = src
    if math.random() <= Config.HouseRobbery.PoliceAlertChance then
        local coords = Config.HouseRobbery.Houses[id].coords
        TriggerClientEvent('police:client:sendAlert', -1, 'houseBurglary', coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
    end
    exports['discord-logs']:LogCustom(src, 'House Robbery', 'Broke into house ' .. id)
    TriggerClientEvent('house:client:breakIn', src, id)
end)

RegisterNetEvent('house:server:search', function(id)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'houseSearch', 5) or activeBurglaries[id] ~= src then return end
    local tierId = Config.HouseRobbery.Houses[id].tier
    local rewards = Config.HouseRobbery.TierRewards[tierId]
    if not rewards then return end
    local cash = math.random(rewards.cash.min, rewards.cash.max)
    p.Functions.AddMoney('cash', cash)
    local granted = {}
    local count = math.random(rewards.itemCount.min, rewards.itemCount.max)
    for i = 1, count do
        local pick = rewards.items[math.random(#rewards.items)]
        p.Functions.AddItem(pick, 1)
        table.insert(granted, pick)
    end
    exports['discord-logs']:LogCustom(src, 'House Robbery', 'Searched house ' .. id .. ' - $' .. cash .. ' - ' .. table.concat(granted, ', '))
    TriggerClientEvent('house:client:searchResult', src, { cash = cash, items = granted })
end)

RegisterNetEvent('house:server:leave', function()
    local src = source
    for id, s in pairs(activeBurglaries) do
        if s == src then activeBurglaries[id] = nil end
    end
    TriggerClientEvent('house:client:leave', src)
end)

MySQL.ready(function()
    MySQL.query('CREATE TABLE IF NOT EXISTS player_houses (id INT AUTO_INCREMENT PRIMARY KEY, citizenid VARCHAR(50), house_id INT, purchased INT DEFAULT 0)')
end)
