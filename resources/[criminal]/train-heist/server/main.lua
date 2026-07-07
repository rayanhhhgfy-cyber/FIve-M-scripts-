local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

local function getRandomCargo()
    local types = {}
    for k, v in pairs(Config.TrainHeist.CargoTypes) do table.insert(types, k) end
    return types[math.random(#types)]
end

RegisterNetEvent('train:server:loot', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'trainLoot', 5) then return end
    local cargoType = getRandomCargo()
    local cargo = Config.TrainHeist.CargoTypes[cargoType]
    if not cargo then return end
    local cash = math.random(cargo.cash.min, cargo.cash.max)
    p.Functions.AddMoney('cash', cash)
    local itemsGranted = {}
    local lootCount = math.random(Config.TrainHeist.Rewards.lootCount.min, Config.TrainHeist.Rewards.lootCount.max)
    for i = 1, lootCount do
        if #cargo.items > 0 then
            local item = cargo.items[math.random(#cargo.items)]
            p.Functions.AddItem(item, 1)
            table.insert(itemsGranted, item)
        end
    end
    if math.random() <= Config.TrainHeist.PoliceAlertChance then
        local coords = GetEntityCoords(GetPlayerPed(src))
        TriggerClientEvent('police:client:sendAlert', -1, 'trainRobbery', coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
    end
    exports['discord-logs']:LogCustom(src, 'Train Heist', 'Looted ' .. cargoType .. ' - $' .. cash .. ' - ' .. table.concat(itemsGranted, ', '))
    TriggerClientEvent('train:client:lootResult', src, { cash = cash, items = itemsGranted })
end)
