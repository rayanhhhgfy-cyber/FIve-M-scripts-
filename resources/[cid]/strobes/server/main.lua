local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, a, m)
    local k = src .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('strobes:server:deploy', function(coords, heading)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then return end
    local id = math.random(10000, 99999)
    TriggerClientEvent('strobes:client:deploy', -1, id, coords, heading)
end)

RegisterNetEvent('strobes:server:pickup', function(id)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    TriggerClientEvent('strobes:client:pickup', -1, id)
end)
