local QBox = exports['qbx-core']:GetCoreObject()
local activeTaps = {}

local RATE_LIMITS = {}
local function checkRateLimit(src, a, m)
    local k = src .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('wiretaps:server:install', function(targetId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then return end
    local target = QBox.Functions.GetPlayer(targetId)
    if not target then Wrappers.Notify(src, Locale('cid.player_not_found'), 'error') return end
    local count = 0; for _, t in pairs(activeTaps) do if t.installedBy == p.PlayerData.citizenid then count = count + 1 end end
    if count >= Config.Wiretaps.MaxActiveTaps then Wrappers.Notify(src, Locale('cid.max_taps'), 'error') return end
    local tapId = 'TAP-' .. math.random(100000, 999999)
    activeTaps[tapId] = {
        id = tapId, target = target.PlayerData.citizenid, target_name = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname,
        phone_number = target.PlayerData.charinfo.phone, installedBy = p.PlayerData.citizenid, status = 'active',
        startTime = os.time(), duration = Config.Wiretaps.TapDuration
    }
    MySQL.insert('INSERT INTO wiretaps (tap_id, target_citizenid, target_name, phone_number, installed_by, status, start_time, duration) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        { tapId, target.PlayerData.citizenid, activeTaps[tapId].target_name, activeTaps[tapId].phone_number, p.PlayerData.citizenid, 'active', os.time(), Config.Wiretaps.TapDuration })
    TriggerClientEvent('Wrappers:Notify', targetId, Locale('cid.tap_warning'), 'warning')
    Wrappers.Notify(src, Locale('cid.tap_installed', activeTaps[tapId].target_name), 'success')
    exports['discord-logs']:LogCustom(src, 'Wiretap Installed', 'Target: ' .. activeTaps[tapId].target_name .. ' Phone: ' .. activeTaps[tapId].phone_number)
end)

RegisterNetEvent('wiretaps:server:getActiveTaps', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM wiretaps WHERE status = ? AND start_time + duration > ? ORDER BY start_time DESC', { 'active', os.time() }, function(r)
        TriggerClientEvent('wiretaps:client:activeTaps', src, r or {})
    end)
end)

RegisterNetEvent('wiretaps:server:getRecordings', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM wiretap_recordings ORDER BY timestamp DESC LIMIT 50', {}, function(r)
        TriggerClientEvent('wiretaps:client:recordings', src, r or {})
    end)
end)

RegisterNetEvent('wiretaps:server:getTranscripts', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM wiretap_transcripts ORDER BY timestamp DESC LIMIT 20', {}, function(r)
        if r and #r > 0 then
            local msg = Locale('cid.transcripts_header')
            for _, t in ipairs(r) do
                msg = msg .. '\n[' .. t.timestamp .. '] ' .. t.target_name .. ': ' .. t.transcript:sub(1, 80) .. '...'
            end
            Wrappers.Notify(src, msg, 'info')
        else
            Wrappers.Notify(src, Locale('cid.no_transcripts'), 'info')
        end
    end)
end)

RegisterNetEvent('wiretaps:server:locate', function(number)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local players = QBox.Functions.GetPlayers()
    for _, sid in ipairs(players) do
        local pl = QBox.Functions.GetPlayer(sid)
        if pl and pl.PlayerData.charinfo.phone == number then
            local coords = GetEntityCoords(GetPlayerPed(sid))
            TriggerClientEvent('wiretaps:client:location', src, coords)
            return
        end
    end
    TriggerClientEvent('wiretaps:client:location', src, nil)
end)

RegisterNetEvent('wiretaps:server:requestWarrant', function(target, cause)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.insert('INSERT INTO wiretap_warrants (requested_by, target, cause, status, timestamp) VALUES (?, ?, ?, ?, ?)',
        { p.PlayerData.citizenid, target, cause, 'pending', os.time() })
    Wrappers.Notify(src, Locale('cid.warrant_requested'), 'success')
    exports['discord-logs']:LogCustom(src, 'Wiretap Warrant', 'Requested for ' .. target)
end)

function RecordInterception(phoneNumber, dataType, content)
    MySQL.insert('INSERT INTO wiretap_recordings (phone_number, data_type, content, timestamp) VALUES (?, ?, ?, ?)',
        { phoneNumber, dataType, content, os.time() })
    local players = QBox.Functions.GetPlayers()
    for _, sid in ipairs(players) do
        local pl = QBox.Functions.GetPlayer(sid)
        if pl and pl.PlayerData.job.name == 'cid' and pl.PlayerData.job.onduty then
            TriggerClientEvent('Wrappers:Notify', sid, Locale('cid.new_interception', phoneNumber), 'info')
        end
    end
end
exports('RecordInterception', RecordInterception)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        local now = os.time()
        for id, tap in pairs(activeTaps) do
            if now - tap.startTime > tap.duration then
                tap.status = 'expired'
                MySQL.update('UPDATE wiretaps SET status = ? WHERE tap_id = ?', { 'expired', id })
                activeTaps[id] = nil
            end
        end
    end
end)
