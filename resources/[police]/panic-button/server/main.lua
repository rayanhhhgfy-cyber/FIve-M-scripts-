local QBox = exports['qbx-core']:GetCoreObject()
local activePanics = {}

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

RegisterNetEvent('panic:server:sendAlert', function(alertId, label, urgent)
    local src = source
    if not checkRateLimit(src, 'panicAlert', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then
        Wrappers.Notify(src, Locale('police.not_on_duty'), 'error')
        return
    end
    local coords = GetEntityCoords(GetPlayerPed(src))
    local officerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local alertData = {
        id = alertId,
        label = label,
        urgent = urgent,
        officer = officerName,
        citizenid = player.PlayerData.citizenid,
        coords = coords,
        src = src,
        time = os.time()
    }
    table.insert(activePanics, alertData)
    TriggerClientEvent('panic:client:receiveAlert', -1, alertId, label, urgent, officerName, coords, src)
    MySQL.insert('INSERT INTO panic_alerts (citizenid, alert_type, label, coords_x, coords_y, coords_z, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { player.PlayerData.citizenid, alertId, label, coords.x, coords.y, coords.z, os.time() })

    -- Bridge to dispatch system: create a dispatch call for the panic
    local dispatchReason = '🚨 ' .. label .. ' - ' .. officerName
    local callerCoords = { x = coords.x, y = coords.y, z = coords.z }
    TriggerEvent('dispatch:server:call911', dispatchReason, src, callerCoords)
end)

QBox.Functions.CreateCallback('panic:server:getActiveAlerts', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then cb({}) return end
    local recent = {}
    local now = os.time()
    for _, alert in ipairs(activePanics) do
        if now - alert.time < Config.PanicButton.AlertDuration then
            table.insert(recent, alert)
        end
    end
    activePanics = recent
    cb(activePanics)
end)
