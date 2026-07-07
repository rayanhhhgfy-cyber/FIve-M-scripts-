local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('store:server:robRegister', function(id)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'storeRob', 3) then return end
    local loc = Config.StoreRobbery.Locations[id]
    if not loc then return end
    local cash = math.random(Config.StoreRobbery.Registers[loc.registerId].reward.min, Config.StoreRobbery.Registers[loc.registerId].reward.max)
    p.Functions.AddMoney('cash', cash)
    for _, item in pairs(Config.StoreRobbery.Items) do
        if math.random() <= item.chance then
            p.Functions.AddItem(item.label, math.random(Config.StoreRobbery.Rewards.item.min, Config.StoreRobbery.Rewards.item.max))
        end
    end
    if math.random() <= Config.StoreRobbery.PoliceAlertChance then
        local coords = GetEntityCoords(GetPlayerPed(src))
        TriggerClientEvent('police:client:sendAlert', -1, 'storeRobbery', coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
    end
    exports['discord-logs']:LogCustom(src, 'Store Robbery', 'Register ' .. id .. ' - Cash: $' .. cash)
    TriggerClientEvent('store:client:robberyResult', src, { cash = cash, registerId = id })
end)

RegisterNetEvent('store:server:searchShelf', function(id)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'storeSearch', 3) then return end
    local itemsGranted = {}
    for _, item in pairs(Config.StoreRobbery.Items) do
        if math.random() <= item.chance then
            p.Functions.AddItem(item.label, math.random(Config.StoreRobbery.Rewards.item.min, Config.StoreRobbery.Rewards.item.max))
            table.insert(itemsGranted, item.label)
        end
    end
    local cash = math.random(Config.StoreRobbery.Rewards.cash.min, Config.StoreRobbery.Rewards.cash.max)
    p.Functions.AddMoney('cash', cash)
    exports['discord-logs']:LogCustom(src, 'Store Robbery', 'Shelf search - Cash: $' .. cash .. ' Items: ' .. table.concat(itemsGranted, ', '))
    TriggerClientEvent('store:client:searchResult', src, { cash = cash, items = itemsGranted })
end)
