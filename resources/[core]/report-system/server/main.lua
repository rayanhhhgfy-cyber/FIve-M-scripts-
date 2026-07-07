local QBox = exports['qbx_core']:GetCoreObject()

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

local activeReports = {}
local reportCounter = 0

local function isStaff(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.Reports.staffGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.Reports.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

local function sendWebhook(title, description, color)
    if Config.Reports.discordWebhook and Config.Reports.discordWebhook ~= '' then
        PerformHttpRequest(Config.Reports.discordWebhook, function() end, 'POST', json.encode({
            embeds = { { title = title, description = description, color = color or 3092790 } }
        }), { ['Content-Type'] = 'application/json' })
    end
end

local function notifyStaff(msg)
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
        if isStaff(src) then
            TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = msg, duration = 5000 })
        end
    end
end

--- Player submits a report
RegisterNetEvent('report:server:submit', function(reason)
    local src = source
    if not checkRateLimit(src, 'report', Config.Reports.cooldown) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Wait before sending another report' })
        return
    end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    -- Check max open reports
    local openCount = 0
    for _, r in pairs(activeReports) do
        if r.playerSrc == src and r.status ~= 'closed' then openCount = openCount + 1 end
    end
    if openCount >= Config.Reports.maxReports then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Too many open reports' })
        return
    end

    reportCounter = reportCounter + 1
    local report = {
        id = reportCounter,
        playerSrc = src,
        playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        citizenid = player.PlayerData.citizenid,
        reason = reason or 'No reason given',
        status = 'open',
        handledBy = nil,
    }
    activeReports[reportCounter] = report

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Report #' .. reportCounter .. ' submitted' })
    notifyStaff('New report #' .. reportCounter .. ' from ' .. report.playerName .. ': ' .. report.reason)
    sendWebhook('New Report #' .. reportCounter, report.playerName .. ': ' .. report.reason, 16753920)
end)

--- Staff: get open reports
QBox.Functions.CreateCallback('report:server:getReports', function(source, cb)
    if not isStaff(source) then cb({}) return end
    local result = {}
    for _, r in pairs(activeReports) do
        table.insert(result, r)
    end
    cb(result)
end)

--- Staff: accept report
RegisterNetEvent('report:server:accept', function(reportId)
    local src = source
    if not isStaff(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not authorized' })
        return
    end
    local report = activeReports[reportId]
    if not report then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Report not found' })
        return
    end
    if report.status ~= 'open' then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Report already being handled' })
        return
    end
    local player = QBox.Functions.GetPlayer(src)
    report.status = 'handling'
    report.handledBy = src
    report.handlerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    TriggerClientEvent('ox_lib:notify', report.playerSrc, { type = 'info', description = 'Report #' .. reportId .. ' accepted by ' .. report.handlerName })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Accepted report #' .. reportId })
end)

--- Staff: close report
RegisterNetEvent('report:server:close', function(reportId, resolution)
    local src = source
    if not isStaff(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not authorized' })
        return
    end
    local report = activeReports[reportId]
    if not report then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Report not found' })
        return
    end
    if report.status == 'closed' then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already closed' })
        return
    end
    report.status = 'closed'
    report.resolution = resolution or 'Closed'
    TriggerClientEvent('ox_lib:notify', report.playerSrc, { type = 'info', description = 'Report #' .. reportId .. ' closed: ' .. (resolution or '') })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Closed report #' .. reportId })
    sendWebhook('Report #' .. reportId .. ' Closed', 'By: ' .. (report.handlerName or 'Unknown') .. ' | ' .. (resolution or ''), 3066993)
    MySQL.insert('INSERT INTO report_logs (report_id, reporter_cid, handler_cid, reason, resolution) VALUES (?, ?, ?, ?, ?)',
        { reportId, report.citizenid, report.handledBy and QBox.Functions.GetPlayer(report.handledBy).PlayerData.citizenid or 'unknown', report.reason, resolution or '' })
end)

QBox.Commands.Add('report', 'Submit a report to staff', {}, false, function(source, args)
    local reason = table.concat(args, ' ', 1)
    if not reason or reason == '' then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Usage: /report [reason]' })
        return
    end
    TriggerEvent('report:server:submit', reason)
end)

QBox.Commands.Add('reports', 'View open reports', {}, false, function(source)
    if not isStaff(source) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Not authorized' })
        return
    end
    TriggerClientEvent('report:client:showReports', source)
end)

QBox.Commands.Add('acceptreport', 'Accept a report', {}, false, function(source, args)
    local id = tonumber(args[1])
    if id then TriggerEvent('report:server:accept', id) end
end)

QBox.Commands.Add('closereport', 'Close a report', {}, false, function(source, args)
    local id = tonumber(args[1])
    local resolution = table.concat(args, ' ', 2)
    if id then TriggerEvent('report:server:close', id, resolution) end
end)
