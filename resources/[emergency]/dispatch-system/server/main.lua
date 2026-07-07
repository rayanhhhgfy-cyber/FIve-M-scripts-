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

local activeCalls = {}
local callCounter = 0
local VOICE_CHANNEL_OFFSET = 5000

local function isDispatch(player)
    if not player then return false end
    for _, j in ipairs(Config.Dispatch.dispatchJobs) do
        if player.PlayerData.job.name == j then return true end
    end
    return false
end

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.Dispatch.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

local function notifyDispatcher(msg)
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local p = QBox.Functions.GetPlayer(src)
        if isDispatch(p) or isAdmin(src) then
            TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = msg })
        end
    end
end

--- Citizen calls 911 (also triggered by panic bridge with optional callerSrc + callerCoords)
RegisterNetEvent('dispatch:server:call911', function(reason, callerSrc, callerCoords)
    local src = callerSrc or source
    if not checkRateLimit(src, 'call911', Config.Dispatch.cooldown) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Wait before calling again' })
        return
    end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local coords = callerCoords
    if not coords then
        local ped = GetPlayerPed(src)
        coords = GetEntityCoords(ped)
    end

    callCounter = callCounter + 1
    local call = {
        id = callCounter,
        caller = src,
        callerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        callerCID = player.PlayerData.citizenid,
        type = callerCoords and '🚨 PANIC ALERT' or '911 Call',
        description = reason or 'Emergency',
        coords = { x = coords.x, y = coords.y, z = coords.z },
        status = 'pending',
        dispatchedUnits = {},
        createdAt = os.time(),
    }
    activeCalls[callCounter] = call

    MySQL.insert('INSERT INTO emergency_calls (caller_cid, type, description, coords, status) VALUES (?, ?, ?, ?, ?)',
        { player.PlayerData.citizenid, call.type, call.description, json.encode({ x = coords.x, y = coords.y, z = coords.z }), 'pending' })

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = '911 dispatched. Units on the way.' })
    notifyDispatcher('🚨 ' .. call.type .. ' #' .. callCounter .. ' from ' .. call.callerName .. ': ' .. reason)
end)

--- Dispatch assigns unit
RegisterNetEvent('dispatch:server:assignUnit', function(callId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not isDispatch(player) and not isAdmin(src) then return end

    local call = activeCalls[callId]
    if not call then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Call not found' })
        return
    end

    table.insert(call.dispatchedUnits, src)
    call.status = 'dispatched'

    local voiceChannel = VOICE_CHANNEL_OFFSET + callId
    TriggerClientEvent('dispatch:client:joinCallChannel', src, voiceChannel)
    TriggerClientEvent('dispatch:client:setWaypoint', src, call.coords)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Assigned to call #' .. callId })
    if call.caller then
        TriggerClientEvent('ox_lib:notify', call.caller, { type = 'info', description = 'Unit dispatched to your location' })
    end
    notifyDispatcher('🚔 Unit assigned to call #' .. callId)
end)

--- Officer marks as on scene
RegisterNetEvent('dispatch:server:onScene', function(callId)
    local src = source
    local call = activeCalls[callId]
    if not call then return end
    call.status = 'on_scene'
    if call.caller then
        TriggerClientEvent('ox_lib:notify', call.caller, { type = 'info', description = 'Police on scene' })
    end
    notifyDispatcher('📍 Unit on scene at call #' .. callId)
end)

--- Officer resolves call
RegisterNetEvent('dispatch:server:resolveCall', function(callId, notes)
    local src = source
    local call = activeCalls[callId]
    if not call then return end
    call.status = 'resolved'
    local voiceChannel = VOICE_CHANNEL_OFFSET + callId
    for _, unitSrc in ipairs(call.dispatchedUnits) do
        TriggerClientEvent('dispatch:client:leaveCallChannel', unitSrc, voiceChannel)
    end
    MySQL.update('UPDATE emergency_calls SET status = ?, description = ? WHERE id = ?', { 'resolved', notes or '', callId })
    if call.caller then
        TriggerClientEvent('ox_lib:notify', call.caller, { type = 'info', description = 'Call #' .. callId .. ' resolved' })
    end
    notifyDispatcher('✅ Call #' .. callId .. ' resolved: ' .. (notes or ''))
    activeCalls[callId] = nil
end)

--- Officer skips / leaves a call
RegisterNetEvent('dispatch:server:skipCall', function(callId)
    local src = source
    local call = activeCalls[callId]
    if not call then return end
    for i, unitSrc in ipairs(call.dispatchedUnits) do
        if unitSrc == src then
            table.remove(call.dispatchedUnits, i)
            break
        end
    end
    local voiceChannel = VOICE_CHANNEL_OFFSET + callId
    TriggerClientEvent('dispatch:client:leaveCallChannel', src, voiceChannel)
    if #call.dispatchedUnits == 0 then
        call.status = 'pending'
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Left call #' .. callId })
end)

--- Get active calls for dispatch panel
QBox.Functions.CreateCallback('dispatch:server:getCalls', function(source, cb)
    local result = {}
    for _, call in pairs(activeCalls) do
        table.insert(result, call)
    end
    cb(result)
end)

--- Commands
QBox.Commands.Add('911', 'Call 911 for emergency dispatch', {}, false, function(source, args)
    local reason = table.concat(args, ' ', 1)
    if not reason or reason == '' then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Usage: /911 [reason]' })
        return
    end
    TriggerEvent('dispatch:server:call911', reason)
end)

QBox.Commands.Add('dispatch', 'Open dispatch panel', {}, false, function(source)
    local player = QBox.Functions.GetPlayer(source)
    if isDispatch(player) or isAdmin(source) then
        TriggerClientEvent('dispatch:client:openPanel', source)
    else
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Not authorized' })
    end
end)

QBox.Commands.Add('assign', 'Assign self to a call', {}, false, function(source, args)
    local id = tonumber(args[1])
    if id then TriggerEvent('dispatch:server:assignUnit', id) end
end)

QBox.Commands.Add('onscene', 'Mark as on scene', {}, false, function(source, args)
    local id = tonumber(args[1])
    if id then TriggerEvent('dispatch:server:onScene', id) end
end)

QBox.Commands.Add('resolvecall', 'Resolve a call', {}, false, function(source, args)
    local id = tonumber(args[1])
    local notes = table.concat(args, ' ', 2)
    if id then TriggerEvent('dispatch:server:resolveCall', id, notes) end
end)
