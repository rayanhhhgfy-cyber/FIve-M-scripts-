local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('advanced-tow:server:attached', function(plate)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.insert('INSERT INTO tow_logs (citizenid, plate, action, timestamp) VALUES (?, ?, ?, ?)', { p.PlayerData.citizenid, plate, 'attached', os.time() })
end)

RegisterNetEvent('advanced-tow:server:detached', function(plate)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.insert('INSERT INTO tow_logs (citizenid, plate, action, timestamp) VALUES (?, ?, ?, ?)', { p.PlayerData.citizenid, plate, 'detached', os.time() })
end)
