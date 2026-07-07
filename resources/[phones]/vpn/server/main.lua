local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('vpn:server:connected', function(serverId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    exports['discord-logs']:LogCustom(src, 'VPN Connected', 'Server: ' .. serverId)
end)

RegisterNetEvent('vpn:server:disconnected', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    exports['discord-logs']:LogCustom(src, 'VPN Disconnected', '')
end)

function IsVPNActive(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    return false
end
exports('IsVPNActive', IsVPNActive)
