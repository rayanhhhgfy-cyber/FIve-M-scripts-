local QBox = exports['qbx-core']:GetCoreObject()
local activeYachtHeist = { active = false, vaultOpen = false }

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('yacht:server:pickpocket', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'yachtPick', 5) then return end
    local cash = math.random(200, 800)
    p.Functions.AddMoney('cash', cash)
    exports['discord-logs']:LogCustom(src, 'Yacht Heist', 'Pickpocketed $' .. cash)
    TriggerClientEvent('yacht:client:result', src, { message = 'Got $' .. cash, type = 'success' })
end)

RegisterNetEvent('yacht:server:searchRoom', function(id)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'yachtRoom', 5) then return end
    local loot = Config.YachtHeist.GuestRooms.loot
    local cash = math.random(loot.cash.min, loot.cash.max)
    p.Functions.AddMoney('cash', cash)
    if math.random() <= 0.5 then
        local item = loot.items[math.random(#loot.items)]
        p.Functions.AddItem(item, 1)
    end
    exports['discord-logs']:LogCustom(src, 'Yacht Heist', 'Searched room ' .. id .. ' - $' .. cash)
    TriggerClientEvent('yacht:client:result', src, { message = 'Found $' .. cash .. ' in room', type = 'success' })
end)

RegisterNetEvent('yacht:server:hackVault', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'yachtHack', 3) then return end
    if not p.Functions.RemoveItem('hacking_device', 1) then return end
    activeYachtHeist.vaultOpen = true
    exports['discord-logs']:LogCustom(src, 'Yacht Heist', 'Hacked vault terminal')
    TriggerClientEvent('yacht:client:result', src, { message = 'Vault terminal hacked!', vaultOpen = true, type = 'success' })
end)

RegisterNetEvent('yacht:server:crackSafe', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'yachtCrack', 3) or not activeYachtHeist.vaultOpen then return end
    activeYachtHeist.active = true
    if math.random() <= Config.YachtHeist.PoliceAlertChance then
        local coords = Config.YachtHeist.Yacht.coords
        TriggerClientEvent('police:client:sendAlert', -1, 'yachtHeist', coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
    end
    exports['discord-logs']:LogCustom(src, 'Yacht Heist', 'Cracked safe open')
    TriggerClientEvent('yacht:client:result', src, { message = 'Safe cracked! Loot it quickly', type = 'success' })
end)

RegisterNetEvent('yacht:server:lootVault', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'yachtLoot', 3) or not activeYachtHeist.active then return end
    local cash = math.random(Config.YachtHeist.Vault.cash.min, Config.YachtHeist.Vault.cash.max)
    p.Functions.AddMoney('cash', cash)
    local count = math.random(Config.YachtHeist.Vault.itemCount.min, Config.YachtHeist.Vault.itemCount.max)
    local itemsGranted = {}
    for i = 1, count do
        local item = Config.YachtHeist.Vault.valuableItems[math.random(#Config.YachtHeist.Vault.valuableItems)]
        p.Functions.AddItem(item, 1)
        table.insert(itemsGranted, item)
    end
    activeYachtHeist = { active = false, vaultOpen = false }
    exports['discord-logs']:LogCustom(src, 'Yacht Heist', 'Looted vault $' .. cash .. ' - ' .. table.concat(itemsGranted, ', '))
    TriggerClientEvent('yacht:client:result', src, { message = 'Stole $' .. cash .. ' and valuables!', type = 'success' })
end)
