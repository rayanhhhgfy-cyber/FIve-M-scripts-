local QBox = exports['qbx-core']:GetCoreObject()
local vangelicoState = { looted = {}, alarmTriggered = false }

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('vang:server:loot', function(i)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'vangLoot', 8) or vangelicoState.looted[i] then return end
    local c = Config.VangelicoHeist.GlassCases[i]
    if not c then return end
    vangelicoState.looted[i] = true
    local value = math.random(c.value.min, c.value.max)
    p.Functions.AddItem(c.item, 1)
    p.Functions.AddMoney('cash', value)
    if math.random() <= Config.VangelicoHeist.PoliceAlertChance then
        local coords = Config.VangelicoHeist.Location.coords
        TriggerClientEvent('police:client:sendAlert', -1, 'vangelicoHeist', coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
    end
    if math.random() <= 0.3 then
        local extra = Config.VangelicoHeist.Rewards.extraItems[math.random(#Config.VangelicoHeist.Rewards.extraItems)]
        p.Functions.AddItem(extra, 1)
    end
    exports['discord-logs']:LogCustom(src, 'Vangelico Heist', 'Took ' .. c.item .. ' ($' .. value .. ') from ' .. c.label)
    TriggerClientEvent('vang:client:lootResult', src, { id = i, item = c.item, value = value })
end)
