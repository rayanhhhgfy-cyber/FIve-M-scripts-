local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, a, m)
    local k = src .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('plate:server:scan', function(plate)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then return end
    if not checkRateLimit(src, 'plateScan', 60) then return end
    MySQL.query('SELECT p.citizenid, p.charinfo, pv.vehicle, pv.plate, pv.stolen, pv.insurance FROM players p JOIN player_vehicles pv ON p.citizenid = pv.citizenid WHERE pv.plate = ?',
        { plate }, function(result)
        local flags = {}
        local owner = nil
        if result and #result > 0 then
            local row = result[1]
            local ci = json.decode(row.charinfo)
            owner = ci.firstname .. ' ' .. ci.lastname
            if row.stolen == 1 then table.insert(flags, 'Stolen') end
            local daysSinceReg = 0
            if row.insurance == 0 then table.insert(flags, 'NoInsurance') end
        end
        if #flags == 0 then table.insert(flags, 'Clean') end
        TriggerClientEvent('plate:client:scanResult', src, plate, flags, owner)
        if Config.PlateScanner.StoreLogs then
            MySQL.insert('INSERT INTO plate_scans (citizenid, plate, flags, timestamp) VALUES (?, ?, ?, ?)',
                { p.PlayerData.citizenid, plate, table.concat(flags, ','), os.time() })
        end
        if Config.PlateScanner.AlertOnStolen and table.contains(flags, 'Stolen') then
            local players = QBox.Functions.GetPlayers()
            for _, sid in ipairs(players) do
                local pl = QBox.Functions.GetPlayer(sid)
                if pl and pl.PlayerData.job.type == 'leo' and pl.PlayerData.job.onduty then
                    TriggerClientEvent('Wrappers:Notify', sid, Locale('cid.stolen_plate_alert', plate), 'error')
                end
            end
            exports['discord-logs']:LogCustom(src, 'Stolen Plate', plate)
        end
    end)
end)

function table.contains(t, v)
    for _, val in ipairs(t) do if val == v then return true end end
    return false
end
