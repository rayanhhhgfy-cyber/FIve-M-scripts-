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

RegisterNetEvent('crosshair:server:toggled', function(enabled)
    local src = source
    if not checkRateLimit(src, 'crosshair', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    MySQL.update('UPDATE players SET crosshair_enabled = ? WHERE citizenid = ?',
        { enabled and 1 or 0, player.PlayerData.citizenid })
end)

QBox.Functions.CreateCallback('crosshair:server:getState', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then cb(false) return end
    MySQL.query('SELECT crosshair_enabled FROM players WHERE citizenid = ?',
        { player.PlayerData.citizenid }, function(result)
        cb(result and result[1] and result[1].crosshair_enabled == 1)
    end)
end)
