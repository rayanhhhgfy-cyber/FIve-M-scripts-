local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

RegisterNetEvent('spotlight:server:used', function()
    local src = source
    if not checkRateLimit(src, 'spotlightUse', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    exports['discord-logs']:LogCustom(src, 'Spotlight Used', 'Player activated spotlight')
end)
