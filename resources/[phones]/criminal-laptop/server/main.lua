local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('criminal:server:browse', function(category)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    exports['discord-logs']:LogCustom(src, 'Dark Web Browse', 'Category: ' .. category)
end)

RegisterNetEvent('criminal:server:purchase', function(itemId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'darkPurchase', 10) then return end
    exports['discord-logs']:LogCustom(src, 'Dark Web Purchase', 'Item: ' .. itemId)
end)

RegisterNetEvent('criminal:server:encryptedMessage', function(message)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    exports['discord-logs']:LogCustom(src, 'Encrypted Chat', message:sub(1, 50))
end)
