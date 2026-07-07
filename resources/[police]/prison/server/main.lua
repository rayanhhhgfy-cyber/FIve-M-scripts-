local QBox = exports['qbx-core']:GetCoreObject()
local prisoners = {}

local RATE_LIMITS = {}
local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

RegisterNetEvent('prison:server:sentenceServed', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    MySQL.update('UPDATE jail_records SET release_time = ?, auto_release = 1 WHERE citizenid = ? AND release_time IS NULL',
        { os.time(), player.PlayerData.citizenid })
    TriggerClientEvent('police:client:releasePrisoner', src)
    exports['discord-logs']:LogCustom(src, 'Prison Release', 'Auto release - sentence served')
end)

RegisterNetEvent('prison:server:escapeAttempt', function()
    local src = source
    if not checkRateLimit(src, 'prisonEscape', 5) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    MySQL.insert('INSERT INTO prison_escape_attempts (citizenid, timestamp) VALUES (?, ?)',
        { player.PlayerData.citizenid, os.time() })
    exports['discord-logs']:LogCustom(src, 'Prison Escape', 'Attempted to escape')
end)

RegisterNetEvent('prison:server:guardRelease', function(targetId)
    local src = source
    if not checkRateLimit(src, 'guardRelease', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then return end
    local target = QBox.Functions.GetPlayer(targetId)
    if not target then
        Wrappers.Notify(src, Locale('police.player_not_found'), 'error')
        return
    end
    MySQL.query('SELECT * FROM jail_records WHERE citizenid = ? AND release_time IS NULL ORDER BY start_time DESC LIMIT 1',
        { target.PlayerData.citizenid }, function(result)
        if result and #result > 0 then
            MySQL.update('UPDATE jail_records SET release_time = ?, released_by = ? WHERE id = ?',
                { os.time(), player.PlayerData.citizenid, result[1].id })
            TriggerClientEvent('police:client:releasePrisoner', targetId)
            Wrappers.Notify(src, Locale('police.prisoner_released', target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname), 'success')
            exports['discord-logs']:LogCustom(src, 'Guard Release', 'Released ' .. target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname)
        else
            Wrappers.Notify(src, Locale('police.no_jail_record'), 'error')
        end
    end)
end)

QBox.Functions.CreateCallback('prison:server:getPrisonerInfo', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then cb(nil) return end
    MySQL.query('SELECT * FROM jail_records WHERE citizenid = ? AND release_time IS NULL ORDER BY start_time DESC LIMIT 1',
        { player.PlayerData.citizenid }, function(result)
        if result and #result > 0 then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end)
