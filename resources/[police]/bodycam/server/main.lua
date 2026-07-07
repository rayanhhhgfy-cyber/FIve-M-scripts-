local QBox = exports['qbx-core']:GetCoreObject()
local recordings = {}

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

RegisterNetEvent('bodycam:server:startRecording', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    recordings[src] = { startTime = os.time(), citizenid = player.PlayerData.citizenid }
end)

RegisterNetEvent('bodycam:server:stopRecording', function(duration)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local recording = recordings[src]
    if recording then
        local recordData = {
            citizenid = player.PlayerData.citizenid,
            duration = duration,
            startTime = recording.startTime,
            endTime = os.time(),
            location = 'recording'
        }
        MySQL.insert('INSERT INTO bodycam_recordings (citizenid, duration, start_time, end_time) VALUES (?, ?, ?, ?)',
            { player.PlayerData.citizenid, duration, recording.startTime, os.time() })
        recordings[src] = nil
        if Config.Bodycam.Logging.LogUploads then
            exports['discord-logs']:LogCustom(src, 'Bodycam Recording', 'Duration: ' .. duration .. 's')
        end
    end
end)

RegisterNetEvent('bodycam:server:logToggle', function(state)
    local src = source
    if not checkRateLimit(src, 'bodycamLog', 30) then return end
    if Config.Bodycam.Logging.LogToggle then
        local player = QBox.Functions.GetPlayer(src)
        if player then
            exports['discord-logs']:LogCustom(src, 'Bodycam Toggle', state and 'Recording ON' or 'Recording OFF')
        end
    end
end)

QBox.Functions.CreateCallback('bodycam:server:getRecordings', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then cb({}) return end
    MySQL.query('SELECT * FROM bodycam_recordings WHERE citizenid = ? ORDER BY start_time DESC LIMIT 50',
        { player.PlayerData.citizenid }, function(result)
        cb(result or {})
    end)
end)
