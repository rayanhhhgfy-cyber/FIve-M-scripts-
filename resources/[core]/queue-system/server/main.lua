local QBox = exports['qbx_core']:GetCoreObject()

local queue = {}
local queuePos = {}

local function getPlayerCount()
    local count = 0
    local players = QBox.Functions.GetPlayers()
    for _ in ipairs(players or {}) do count = count + 1 end
    return count
end

local function getPriority(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return 0 end
    local group = player.PlayerData.group
    for i, g in ipairs(Config.Queue.priorityGroups) do
        if group == g then return #Config.Queue.priorityGroups - i + 1 end
    end
    return 0
end

local function sortQueue()
    table.sort(queue, function(a, b)
        local pa = getPriority(a)
        local pb = getPriority(b)
        if pa ~= pb then return pa > pb end
        return (queuePos[a] or 0) < (queuePos[b] or 0)
    end)
end

local function updateQueuePositions()
    for i, src in ipairs(queue) do
        queuePos[src] = i
        local priority = getPriority(src)
        local msg = 'Position ' .. i .. '/' .. #queue .. ' in queue'
        if priority > 0 then msg = msg .. ' (Priority)' end
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = msg, duration = 4000 })
    end
end

local function admitPlayer(src)
    if not src then return end
    queue[src] = nil
    queuePos[src] = nil
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Welcome to the server!' })
    updateQueuePositions()
end

local function processQueue()
    local count = getPlayerCount()
    while count < Config.Queue.maxPlayers and #queue > 0 do
        sortQueue()
        local nextSrc = queue[1]
        if nextSrc then
            table.remove(queue, 1)
            count = count + 1
            admitPlayer(nextSrc)
        end
    end
end

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    local count = getPlayerCount()
    if count >= Config.Queue.maxPlayers then
        local prio = getPriority(src)
        if prio > 0 then
            -- Priority: find lowest-priority non-priority player and swap
            local found = false
            for i = #queue, 1, -1 do
                local qSrc = queue[i]
                if getPriority(qSrc) == 0 then
                    table.remove(queue, i)
                    admitPlayer(src)
                    table.insert(queue, i, qSrc)
                    found = true
                    break
                end
            end
            if not found then
                table.insert(queue, src)
                queuePos[src] = #queue
            end
        else
            table.insert(queue, src)
            queuePos[src] = #queue
        end
        local pos = queuePos[src] or #queue
        deferrals.defer()
        Citizen.Wait(100)
        deferrals.update('Server full. You are #' .. pos .. ' in queue (' .. #queue .. ' waiting)')
        deferrals.done('Server full. Queue position: ' .. pos)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    queue[src] = nil
    queuePos[src] = nil
    processQueue()
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Queue.checkInterval)
        processQueue()
    end
end)

--- Admin: pull player to front of queue
RegisterNetEvent('queue:server:pull', function(targetSrc)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local isAdmin = false
    for _, g in ipairs(Config.Queue.adminGroups) do
        if player.PlayerData.group == g then isAdmin = true end
    end
    if not isAdmin then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not authorized' })
        return
    end
    -- Find in queue
    for i, qSrc in ipairs(queue) do
        if qSrc == targetSrc then
            table.remove(queue, i)
            table.insert(queue, 1, qSrc)
            updateQueuePositions()
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Pulled to front of queue' })
            return
        end
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not in queue' })
end)

--- Admin: get queue list
QBox.Functions.CreateCallback('queue:server:getQueue', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then cb({}) return end
    local isAdmin = false
    for _, g in ipairs(Config.Queue.adminGroups) do
        if player.PlayerData.group == g then isAdmin = true end
    end
    if not isAdmin then cb({}) return end
    local result = {}
    for i, qSrc in ipairs(queue) do
        table.insert(result, { position = i, src = qSrc })
    end
    cb(result)
end)

QBox.Commands.Add('queuepull', 'Pull a player to front of queue', {}, false, function(source, args)
    local target = tonumber(args[1])
    if target then
        TriggerEvent('queue:server:pull', target)
    end
end)

QBox.Commands.Add('queuelist', 'View current queue', {}, false, function(source)
    TriggerClientEvent('ox_lib:notify', source, { type = 'info', description = 'Queue size: ' .. #queue })
end)
