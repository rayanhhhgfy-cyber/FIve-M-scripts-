local QBox = exports['qbx-core']:GetCoreObject()
local lockedDoors = {}
local alarmedDoors = {}

--- Plant evidence on a target
RegisterNetEvent('covert:server:plantEvidence', function(targetCharacterCid, location)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local success = math.random(100) <= Config.CovertEntry.PlantEvidenceChance
    if not success then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Evidence planting failed - materials compromised' })
        return
    end

    MySQL.query('SELECT * FROM players WHERE citizenid = ?', { targetCharacterCid }, function(targetPlayers)
        local targetName = targetCharacterCid
        if targetPlayers and #targetPlayers > 0 then
            local ci = json.decode(targetPlayers[1].charinfo) or {}
            targetName = (ci.firstname or '') .. ' ' .. (ci.lastname or '')
        end

        MySQL.insert('INSERT INTO criminal_records (citizenid, offense, fine, prison_time, officer, created_at) VALUES (?, ?, ?, ?, ?, NOW())', {
            targetCharacterCid, 'Covert evidence planted at ' .. location, 0, 0, player.PlayerData.citizenid
        })

        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Evidence planted successfully on ' .. targetName })
    end)
end)

--- Fail alarm - auto dispatch
RegisterNetEvent('covert:server:failAlarm', function(location, coords)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player or not Config.CovertEntry.FailAutoDispatch then return end
    local locationStr = location or 'Unknown location'
    TriggerEvent('dispatch:server:call911', 'ALARM - ' .. locationStr, {
        coords = coords,
        caller = 'Security System',
        type = 'Alarm',
    })
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Alarm triggered! Dispatch notified.' })
end)

--- Lockpick success - door unlock
RegisterNetEvent('covert:server:lockpickSuccess', function(doorModel, coords)
    local src = source
    local doorKey = tostring(doorModel) .. ':' .. tostring(coords.x) .. ':' .. tostring(coords.y)
    lockedDoors[doorKey] = {
        unlocked = true,
        unlockedAt = os.time(),
        source = src,
    }
    TriggerClientEvent('covert:client:unlockDoor', -1, doorModel, coords.x, coords.y, coords.z)
end)

--- Alarm bypass success
RegisterNetEvent('covert:server:alarmBypass', function(doorModel, coords)
    local src = source
    local alarmKey = tostring(doorModel) .. ':' .. tostring(coords.x) .. ':' .. tostring(coords.y)
    alarmedDoors[alarmKey] = {
        bypassed = true,
        bypassedUntil = os.time() + (Config.CovertEntry.AlarmBypass.bypassDuration / 1000),
        source = src,
    }
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Alarm bypassed for ' .. (Config.CovertEntry.AlarmBypass.bypassDuration / 1000) .. ' seconds' })
end)

--- Check if alarm is active
QBox.Functions.CreateCallback('covert:server:isAlarmActive', function(source, cb, doorModel, coords)
    local alarmKey = tostring(doorModel) .. ':' .. tostring(coords.x) .. ':' .. tostring(coords.y)
    local alarm = alarmedDoors[alarmKey]
    if alarm and alarm.bypassed and alarm.bypassedUntil > os.time() then
        cb(false)
    else
        cb(true)
    end
end)

--- Lockpick jam cleanup
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        local now = os.time()
        for k, v in pairs(lockedDoors) do
            if v.unlockedAt and (now - v.unlockedAt) > 120 then
                lockedDoors[k] = nil
            end
        end
        for k, v in pairs(alarmedDoors) do
            if v.bypassedUntil and v.bypassedUntil < now then
                alarmedDoors[k] = nil
            end
        end
    end
end)
