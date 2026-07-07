local QBox = exports['qbx-core']:GetCoreObject()

--- Get available aircraft for a player based on job and rank
lib.callback.register('helipads:server:getAircraft', function(source)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return {} end

    local jobName = player.PlayerData.job.name
    local grade = player.PlayerData.job.grade

    local available = {}
    for _, heli in ipairs(Config.Helipads.PoliceHelicopters) do
        if grade >= heli.rank then
            table.insert(available, heli)
        end
    end

    return available
end)

--- Spawn a helicopter and register it
RegisterNetEvent('helipads:server:spawnAircraft', function(model, coords, heading)
    local src = source
    if not checkRateLimit(src, 'heliSpawn', 3) then return end

    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local grade = player.PlayerData.job.grade

    -- Verify player has access to this model
    local allowed = false
    for _, heli in ipairs(Config.Helipads.PoliceHelicopters) do
        if heli.model == model and grade >= heli.rank then
            allowed = true
            break
        end
    end

    if not allowed then
        Wrappers.Notify(src, 'You do not have access to this aircraft', 'error')
        return
    end

    TriggerClientEvent('helipads:client:spawnVehicle', src, model, coords, heading)
end)

-- Rate limiter
local RATE_LIMITS = {}
function checkRateLimit(src, action, maxPerMin)
    local key = tostring(src) .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end
