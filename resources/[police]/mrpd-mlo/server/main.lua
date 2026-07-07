local QBox = exports['qbx-core']:GetCoreObject()
local evidenceItems = {}
local cellOccupants = {}
local activeDispatchCalls = {}

local RATE_LIMITS = {}
local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    if not RATE_LIMITS[key] then RATE_LIMITS[key] = {} end
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then
            table.remove(RATE_LIMITS[key], i)
        end
    end
    if #RATE_LIMITS[key] > maxPerMin then return false end
    return true
end

RegisterNetEvent('mrpd:server:toggleDuty', function()
    local src = source
    if not checkRateLimit(src, 'toggleDuty', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local job = player.PlayerData.job
    if job.type ~= 'leo' then
        Wrappers.Notify(src, Locale('police.not_police'), 'error')
        return
    end
    local newDuty = not job.onduty
    player.Functions.SetJobDuty(newDuty)
    Wrappers.Notify(src, newDuty and Locale('police.now_on_duty') or Locale('police.now_off_duty'), 'success')
    exports['discord-logs']:LogCustom(src, 'Duty Toggle', 'Player toggled duty to ' .. tostring(newDuty))
end)

RegisterNetEvent('mrpd:server:removeWeapon', function(weaponModel)
    local src = source
    if not checkRateLimit(src, 'removeWeapon', 20) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if not player.PlayerData.job.onduty then
        Wrappers.Notify(src, Locale('police.not_on_duty'), 'error')
        return
    end
    local rank = player.PlayerData.job.grade.level or 0
    for _, weapon in ipairs(Config.MRPD.Zones.Armory.weapons) do
        if weapon.model == weaponModel and rank >= weapon.rank then
            local weaponInfo = {
                model = weaponModel,
                serial = exports['resources']:GenerateSerial()
            }
            MySQL.insert('INSERT INTO weapon_serials (citizenid, serial, weapon_model, issued_by) VALUES (?, ?, ?, ?)',
                { player.PlayerData.citizenid, weaponInfo.serial, weaponModel, player.PlayerData.citizenid })
            player.Functions.AddItem(weaponModel, 1, nil, weaponInfo.serial)
            Wrappers.Notify(src, Locale('police.weapon_issued', weapon.label), 'success')
            exports['discord-logs']:LogCustom(src, 'Armory Issue', 'Issued ' .. weapon.label .. ' serial: ' .. weaponInfo.serial)
            return
        end
    end
    Wrappers.Notify(src, Locale('police.weapon_unavailable'), 'error')
end)

RegisterNetEvent('mrpd:server:storeEvidence', function(label, description)
    local src = source
    if not checkRateLimit(src, 'storeEvidence', 30) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then return end
    local id = #evidenceItems + 1
    evidenceItems[id] = {
        id = id,
        label = label,
        description = description or '',
        storedBy = player.PlayerData.citizenid,
        timestamp = os.time()
    }
    MySQL.insert('INSERT INTO evidence_items (citizenid, label, description, stored_by, timestamp) VALUES (?, ?, ?, ?, ?)',
        { player.PlayerData.citizenid, label, description or '', player.PlayerData.citizenid, os.time() })
    Wrappers.Notify(src, Locale('police.evidence_stored'), 'success')
    exports['discord-logs']:LogCustom(src, 'Evidence Stored', 'Stored: ' .. label)
end)

RegisterNetEvent('mrpd:server:retrieveEvidence', function(id)
    local src = source
    if not checkRateLimit(src, 'retrieveEvidence', 20) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then return end
    if evidenceItems[id] then
        local item = evidenceItems[id]
        Wrappers.Notify(src, Locale('police.evidence_retrieved', item.label), 'success')
        table.remove(evidenceItems, id)
        exports['discord-logs']:LogCustom(src, 'Evidence Retrieved', 'Retrieved: ' .. item.label)
    end
end)

QBox.Functions.CreateCallback('mrpd:server:getEvidenceItems', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player or not player.PlayerData.job.onduty then cb({}) return end
    cb(evidenceItems)
end)

RegisterNetEvent('mrpd:server:syncDoor', function(doorModel, state)
    local src = source
    if not checkRateLimit(src, 'syncDoor', 30) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then return end
    TriggerClientEvent('mrpd:server:syncDoor', -1, doorModel, state)
end)

RegisterNetEvent('mrpd:server:getSchedule', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    MySQL.query('SELECT * FROM duty_schedules WHERE citizenid = ? AND date >= CURDATE() ORDER BY date ASC LIMIT 7',
        { player.PlayerData.citizenid }, function(result)
        local scheduleText = Locale('police.schedule_header')
        if result and #result > 0 then
            for _, row in ipairs(result) do
                scheduleText = scheduleText .. '\n' .. row.date .. ' - ' .. row.shift
            end
        else
            scheduleText = scheduleText .. '\n' .. Locale('police.no_schedule')
        end
        Wrappers.Notify(src, scheduleText, 'info')
    end)
end)

RegisterNetEvent('mrpd:server:getCellStatus', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local statusText = Locale('police.cell_status_header')
    for i = 1, Config.MRPD.Zones.Cells.cellCount do
        local occupant = cellOccupants[i]
        if occupant then
            statusText = statusText .. '\n' .. Locale('police.cell_occupied', i, occupant.name, occupant.time .. 'm')
        else
            statusText = statusText .. '\n' .. Locale('police.cell_empty', i)
        end
    end
    Wrappers.Notify(src, statusText, 'info')
end)

RegisterNetEvent('police:server:incarcerate', function(targetId, time, charges)
    local src = source
    if not checkRateLimit(src, 'incarcerate', 15) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then return end
    local target = QBox.Functions.GetPlayer(targetId)
    if not target then
        Wrappers.Notify(src, Locale('police.player_not_found'), 'error')
        return
    end
    local cellFound = false
    for i = 1, Config.MRPD.Zones.Cells.cellCount do
        if not cellOccupants[i] then
            cellOccupants[i] = {
                citizenid = target.PlayerData.citizenid,
                name = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname,
                time = time,
                charges = charges,
                jailedBy = player.PlayerData.citizenid,
                startTime = os.time()
            }
            cellFound = i
            break
        end
    end
    if not cellFound then
        Wrappers.Notify(src, Locale('police.no_cells_available'), 'error')
        return
    end
    TriggerClientEvent('police:client:incarcerate', targetId, cellFound, time, charges)
    MySQL.insert('INSERT INTO jail_records (citizenid, jailed_by, charges, sentence_minutes, start_time) VALUES (?, ?, ?, ?, ?)',
        { target.PlayerData.citizenid, player.PlayerData.citizenid, charges, time, os.time() })
    exports['discord-logs']:LogCustom(src, 'Incarceration', target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname .. ' - ' .. charges .. ' - ' .. time .. 'm')
    Wrappers.Notify(src, Locale('police.prisoner_incarcerated', target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname, cellFound), 'success')
end)

RegisterNetEvent('police:server:releasePrisoner', function(cellNumber)
    local src = source
    if not checkRateLimit(src, 'releasePrisoner', 15) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then return end
    if not cellOccupants[cellNumber] then
        Wrappers.Notify(src, Locale('police.cell_empty', cellNumber), 'error')
        return
    end
    local occupant = cellOccupants[cellNumber]
    local target = QBox.Functions.GetPlayerByCitizenId(occupant.citizenid)
    if target then
        TriggerClientEvent('police:client:releasePrisoner', target.PlayerData.source)
    end
    MySQL.update('UPDATE jail_records SET release_time = ? WHERE citizenid = ? AND release_time IS NULL',
        { os.time(), occupant.citizenid })
    cellOccupants[cellNumber] = nil
    exports['discord-logs']:LogCustom(src, 'Prisoner Release', 'Cell ' .. cellNumber .. ' - ' .. occupant.name)
    Wrappers.Notify(src, Locale('police.prisoner_released', occupant.name), 'success')
end)

RegisterNetEvent('police:server:plateLookup', function(plate)
    local src = source
    if not checkRateLimit(src, 'plateLookup', 20) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then return end
    MySQL.query('SELECT p.citizenid, p.charinfo, v.plate, v.vehicle FROM players p JOIN player_vehicles v ON p.citizenid = v.citizenid WHERE v.plate = ?',
        { plate }, function(result)
        if result and #result > 0 then
            local charinfo = json.decode(result[1].charinfo)
            Wrappers.Notify(src, Locale('police.vehicle_owner', result[1].plate, charinfo.firstname .. ' ' .. charinfo.lastname, result[1].vehicle), 'info')
        else
            Wrappers.Notify(src, Locale('police.no_vehicle_found'), 'error')
        end
    end)
end)

RegisterNetEvent('police:server:nameLookup', function(name)
    local src = source
    if not checkRateLimit(src, 'nameLookup', 20) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then return end
    MySQL.query('SELECT citizenid, charinfo FROM players WHERE JSON_EXTRACT(charinfo, "$.firstname") LIKE ? OR JSON_EXTRACT(charinfo, "$.lastname") LIKE ?',
        { '%' .. name .. '%', '%' .. name .. '%' }, function(result)
        if result and #result > 0 then
            local msg = ''
            for _, row in ipairs(result) do
                local charinfo = json.decode(row.charinfo)
                msg = msg .. '\n' .. charinfo.firstname .. ' ' .. charinfo.lastname .. ' (ID: ' .. row.citizenid .. ')'
            end
            Wrappers.Notify(src, Locale('police.search_results') .. msg, 'info')
        else
            Wrappers.Notify(src, Locale('police.no_results'), 'error')
        end
    end)
end)

RegisterNetEvent('police:server:getBolos', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    MySQL.query('SELECT * FROM bolos WHERE active = 1 ORDER BY created_at DESC', {}, function(result)
        if result and #result > 0 then
            local msg = Locale('police.bolos_header')
            for _, bolo in ipairs(result) do
                msg = msg .. '\n- ' .. bolo.title .. ': ' .. bolo.description
            end
            Wrappers.Notify(src, msg, 'info')
        else
            Wrappers.Notify(src, Locale('police.no_bolos'), 'info')
        end
    end)
end)

RegisterNetEvent('police:server:getActiveCalls', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if #activeDispatchCalls == 0 then
        Wrappers.Notify(src, Locale('police.no_active_calls'), 'info')
        return
    end
    local msg = Locale('police.active_calls_header')
    for _, call in ipairs(activeDispatchCalls) do
        msg = msg .. '\n' .. call.type .. ': ' .. call.location .. ' (' .. call.status .. ')'
    end
    Wrappers.Notify(src, msg, 'info')
end)

RegisterNetEvent('police:server:newDispatchCall', function(callType, location, description)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local call = {
        id = #activeDispatchCalls + 1,
        type = callType,
        location = location,
        description = description or '',
        status = Locale('police.pending'),
        reportedBy = player.PlayerData.citizenid,
        time = os.time()
    }
    table.insert(activeDispatchCalls, call)
    TriggerClientEvent('police:client:newDispatchCall', -1, call)
    exports['discord-logs']:LogCustom(src, 'Dispatch Call', callType .. ' at ' .. location)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        for i, occupant in pairs(cellOccupants) do
            occupant.time = occupant.time - 1
            if occupant.time <= 0 then
                local target = QBox.Functions.GetPlayerByCitizenId(occupant.citizenid)
                if target then
                    TriggerClientEvent('police:client:releasePrisoner', target.PlayerData.source)
                end
                MySQL.update('UPDATE jail_records SET release_time = ? WHERE citizenid = ? AND release_time IS NULL',
                    { os.time(), occupant.citizenid })
                cellOccupants[i] = nil
                exports['discord-logs']:LogCustom(0, 'Auto Release', 'Cell ' .. i .. ' - ' .. occupant.name)
            end
        end
    end
end)
