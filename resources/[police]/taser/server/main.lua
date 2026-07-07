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

RegisterNetEvent('taser:server:tase', function(targetId)
    local src = source
    if not checkRateLimit(src, 'tase', 20) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then
        Wrappers.Notify(src, Locale('police.not_on_duty'), 'error')
        return
    end
    local target = QBox.Functions.GetPlayer(targetId)
    if not target then
        Wrappers.Notify(src, Locale('police.player_not_found'), 'error')
        return
    end
    TriggerClientEvent('taser:client:getTased', targetId)
    if Config.Taser.DamageEnabled then
        target.Functions.SetPlayerData('health', target.PlayerData.health - Config.Taser.DamageAmount)
    end
    exports['discord-logs']:LogCustom(src, 'Taser Used', 'Tased player ' .. target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname)
end)
