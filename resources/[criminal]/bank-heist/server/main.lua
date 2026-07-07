local QBox = exports['qbx-core']:GetCoreObject()
local bankRobberies = {}

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('bank:server:thermite', function(id)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'bankThermite', 3) or bankRobberies[id] then return end
    if not p.Functions.RemoveItem(Config.BankHeist.RequiredItems.thermite, Config.BankHeist.Thermite.required) then
        Wrappers.Notify(src, 'Need ' .. Config.BankHeist.Thermite.required .. ' thermite', 'error') return
    end
    bankRobberies[id] = { src = src, phase = 1, start = os.time() }
    if math.random() <= Config.BankHeist.PoliceAlertChance then
        local coords = Config.BankHeist.Banks[id].coords
        TriggerClientEvent('police:client:sendAlert', -1, 'bankRobbery', coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
    end
    exports['discord-logs']:LogCustom(src, 'Bank Heist', 'Thermite placed at ' .. Config.BankHeist.Banks[id].label)
    TriggerClientEvent('bank:client:phaseUpdate', src, id, 1)
end)

RegisterNetEvent('bank:server:drill', function(id)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'bankDrill', 3) then return end
    if not bankRobberies[id] or bankRobberies[id].phase ~= 1 or bankRobberies[id].src ~= src then return end
    if not p.Functions.RemoveItem(Config.BankHeist.RequiredItems.drill, 1) then
        Wrappers.Notify(src, 'Need a drill', 'error') return
    end
    bankRobberies[id].phase = 2
    exports['discord-logs']:LogCustom(src, 'Bank Heist', 'Drilled vault at ' .. Config.BankHeist.Banks[id].label)
    TriggerClientEvent('bank:client:phaseUpdate', src, id, 2)
end)

RegisterNetEvent('bank:server:lootVault', function(id)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'bankLoot', 3) then return end
    if not bankRobberies[id] or bankRobberies[id].phase ~= 2 or bankRobberies[id].src ~= src then return end
    local cash = math.random(Config.BankHeist.Vault.cash.min, Config.BankHeist.Vault.cash.max)
    p.Functions.AddMoney('cash', cash)
    local goldCount = math.random(Config.BankHeist.Vault.goldBars.min, Config.BankHeist.Vault.goldBars.max)
    p.Functions.AddItem('gold_bar', goldCount)
    if math.random() <= 0.5 then
        local rare = Config.BankHeist.Vault.rareItems[math.random(#Config.BankHeist.Vault.rareItems)]
        p.Functions.AddItem(rare, 1)
    end
    bankRobberies[id].phase = 3
    exports['discord-logs']:LogCustom(src, 'Bank Heist', 'Looted vault $' .. cash .. ' + ' .. goldCount .. ' gold bars')
    TriggerClientEvent('bank:client:lootResult', src, { cash = cash, gold = goldCount })
    TriggerClientEvent('bank:client:phaseUpdate', src, id, 3)
end)
