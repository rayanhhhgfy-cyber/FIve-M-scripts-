local QBox = exports['qbx_core']:GetCoreObject()

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

RegisterNetEvent('tackle:server:tackle', function(targetId)
    local src = source
    if not checkRateLimit(src, 'tackle', 15) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You are not on duty' })
        return
    end
    if not QBox.Functions.GetPlayer(targetId) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    TriggerClientEvent('tackle:client:getTackled', targetId)
    pcall(function()
        exports['discord-logs']:LogCustom(src, 'Tackle', 'Tackled player ' .. targetId)
    end)
end)
