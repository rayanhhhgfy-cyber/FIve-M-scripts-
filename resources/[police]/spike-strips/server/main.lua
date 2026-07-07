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

local deployedCount = 0

RegisterNetEvent('spikestrips:server:deploy', function(coords, heading)
    local src = source
    if not checkRateLimit(src, 'spikeDeploy', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then
        Wrappers.Notify(src, Locale('police.not_on_duty'), 'error')
        return
    end
    local activeCount = 0
    for _, v in pairs(deployedCount) do activeCount = 1 end
    if activeCount >= Config.SpikeStrips.MaxActive then
        Wrappers.Notify(src, Locale('police.max_strips'), 'error')
        return
    end
    local id = math.random(10000, 99999)
    deployedCount = deployedCount + 1
    TriggerClientEvent('spikestrips:client:deploy', -1, id, coords, heading)
    MySQL.insert('INSERT INTO police_spikestrips (deployed_by, coords_x, coords_y, coords_z, heading, timestamp) VALUES (?, ?, ?, ?, ?, ?)',
        { player.PlayerData.citizenid, coords.x, coords.y, coords.z, heading, os.time() })
    exports['discord-logs']:LogCustom(src, 'Spike Strip Deploy', 'Deployed at ' .. tostring(coords))
end)

RegisterNetEvent('spikestrips:server:pickup', function(id)
    local src = source
    if not checkRateLimit(src, 'spikePickup', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    deployedCount = math.max(0, deployedCount - 1)
    TriggerClientEvent('spikestrips:client:pickup', -1, id)
    Wrappers.Notify(src, Locale('police.strips_picked_up'), 'success')
end)
