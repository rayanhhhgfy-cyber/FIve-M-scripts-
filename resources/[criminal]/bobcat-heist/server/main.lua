local QBox = exports['qbx-core']:GetCoreObject()
local bobcatState = { gates = {}, looted = {} }

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('bobcat:server:burnGate', function(i)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'bobcatGate', 5) or bobcatState.gates[i] then return end
    local gate = Config.BobcatHeist.Gates[i]
    if not gate then return end
    if not p.Functions.RemoveItem(gate.requiredItem, 1) then return end
    bobcatState.gates[i] = true
    TriggerClientEvent('bobcat:client:gateOpened', -1, i)
    if math.random() <= Config.BobcatHeist.PoliceAlertChance then
        local coords = Config.BobcatHeist.Location.coords
        TriggerClientEvent('police:client:sendAlert', -1, 'bobcatHeist', coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
    end
    exports['discord-logs']:LogCustom(src, 'Bobcat Heist', 'Burned through gate ' .. i .. ' (' .. gate.label .. ')')
end)

RegisterNetEvent('bobcat:server:loot', function(j)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'bobcatLoot', 8) or bobcatState.looted[j] then return end
    local loot = Config.BobcatHeist.Lootables[j]
    if not loot then return end
    bobcatState.looted[j] = true
    local cash = math.random(loot.cash.min, loot.cash.max)
    p.Functions.AddMoney('cash', cash)
    local itemsGranted = {}
    local count = math.random(1, 3)
    for i = 1, count do
        local item = loot.items[math.random(#loot.items)]
        p.Functions.AddItem(item, 1)
        table.insert(itemsGranted, item)
    end
    exports['discord-logs']:LogCustom(src, 'Bobcat Heist', 'Looted ' .. loot.label .. ' - $' .. cash .. ' - ' .. table.concat(itemsGranted, ', '))
    TriggerClientEvent('bobcat:client:lootResult', src, { id = j, label = loot.label, cash = cash, items = itemsGranted })
end)
