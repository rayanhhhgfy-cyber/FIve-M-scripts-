local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('barricades:server:deploy', function(typeId, coords, heading)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    if not rl(src, 'barricadeDeploy', 20) then return end
    local id = math.random(10000, 99999)
    TriggerClientEvent('barricades:client:deploy', -1, id, typeId, coords, heading)
end)

RegisterNetEvent('barricades:server:pickup', function(id)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    TriggerClientEvent('barricades:client:pickup', -1, id)
end)
