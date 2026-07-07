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

RegisterNetEvent('shields:server:deployed', function()
    local src = source
    if not checkRateLimit(src, 'shieldDeploy', 10) then return end
    exports['discord-logs']:LogCustom(src, 'Shield Deployed', 'Ballistic shield deployed')
end)

RegisterNetEvent('shields:server:stored', function()
    local src = source
    if not checkRateLimit(src, 'shieldStore', 10) then return end
end)
