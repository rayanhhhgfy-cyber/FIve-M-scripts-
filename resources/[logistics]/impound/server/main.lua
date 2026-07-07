local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('impound:server:getImpounded', function(locName)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM impounded_vehicles WHERE citizenid = ? AND location = ? AND released = 0 AND impound_time + duration > ?',
        { p.PlayerData.citizenid, locName, os.time() }, function(r)
        TriggerClientEvent('impound:client:showImpounded', src, r or {}, locName)
    end)
end)

RegisterNetEvent('impound:server:release', function(impoundId, fee, plate, locName)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    if not rl(src, 'impoundRelease', 10) then return end
    MySQL.query('SELECT * FROM impounded_vehicles WHERE id = ?', { impoundId }, function(result)
        if not result or #result == 0 then Wrappers.Notify(src, Locale('logistics.not_found'), 'error') return end
        local vehData = result[1]
        if p.PlayerData.cash < fee and p.PlayerData.bank < fee then
            Wrappers.Notify(src, Locale('logistics.insufficient_funds'), 'error')
            return
        end
        if p.PlayerData.cash >= fee then p.Functions.RemoveMoney('cash', fee)
        else p.Functions.RemoveMoney('bank', fee) end
        MySQL.update('UPDATE impounded_vehicles SET released = 1, release_time = ? WHERE id = ?', { os.time(), impoundId })
        local loc = Config.Impound.Locations[locName]
        if loc then
            local spawn = loc.spawns[math.random(#loc.spawns)]
            QBox.Functions.SpawnVehicle(vehData.vehicle, function(veh)
                SetVehicleNumberPlateText(veh, plate)
                SetEntityCoords(veh, spawn.coords)
                SetEntityHeading(veh, spawn.heading)
                TaskWarpPedIntoVehicle(GetPlayerPed(src), veh, -1)
            end, spawn.coords, true)
        end
        Wrappers.Notify(src, Locale('logistics.vehicle_released'), 'success')
    end)
end)

RegisterNetEvent('impound:server:policeImpound', function(plate, reasonId, fee, reasonLabel)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then return end
    MySQL.query('SELECT citizenid, vehicle FROM player_vehicles WHERE plate = ?', { plate }, function(r)
        if r and #r > 0 then
            local locName = 'Police'
            MySQL.insert('INSERT INTO impounded_vehicles (citizenid, plate, vehicle, location, reason, release_fee, impound_time, duration) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                { r[1].citizenid, plate, r[1].vehicle, locName, reasonLabel, fee, os.time(), Config.Impound.ImpoundDuration })
            exports['discord-logs']:LogCustom(src, 'Vehicle Impounded', plate .. ' - ' .. reasonLabel)
            Wrappers.Notify(src, Locale('logistics.vehicle_impounded', plate), 'success')
        else
            Wrappers.Notify(src, Locale('logistics.not_found'), 'error')
        end
    end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(86400000)
        MySQL.update('UPDATE impounded_vehicles SET released = 1, release_time = ? WHERE released = 0 AND impound_time + duration < ?',
            { os.time(), os.time() })
    end
end)
