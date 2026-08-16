local QBox = exports['qbx_core']:GetCoreObject()

local function isOwner(identifier)
    if not identifier then return false end
    local res = MySQL.scalar.await('SELECT id FROM server_owners WHERE identifier = ? LIMIT 1', { identifier })
    return res ~= nil
end

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end

    if isOwner(player.PlayerData.license) or isOwner(player.PlayerData.citizenid) then
        return true
    end

    for _, g in ipairs({ 'admin', 'superadmin', 'god' }) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

local function fetchTickets(src)
    local activeRows = MySQL.query.await('SELECT id, subject, description, sender_source, sender_name, UNIX_TIMESTAMP(created_at) AS created_at FROM support_tickets WHERE status = ? ORDER BY created_at DESC', { 'open' }) or {}
    local historyRows = MySQL.query.await(
        'SELECT id, subject, description, sender_source, sender_name, resolver_source, resolver_name FROM support_tickets WHERE status = ? AND resolved_at >= DATE_SUB(NOW(), INTERVAL 2 MONTH) ORDER BY resolved_at DESC',
        { 'solved' }
    ) or {}

    local active = {}
    for _, r in ipairs(activeRows) do
        table.insert(active, {
            id = r.id,
            subject = r.subject,
            description = r.description,
            senderId = r.sender_source,
            senderName = r.sender_name,
            timestamp = r.created_at or os.time(),
        })
    end

    local history = {}
    for _, r in ipairs(historyRows) do
        table.insert(history, {
            id = r.id,
            subject = r.subject,
            description = r.description,
            senderId = r.sender_source,
            senderName = r.sender_name,
            resolverId = r.resolver_source,
            resolverName = r.resolver_name,
        })
    end

    TriggerClientEvent('ticket-system:client:openDashboard', src, active, history)
end

-- Player opens a support ticket
RegisterNetEvent('ticket-system:server:openTicket', function(subject, description)
    local src = source
    if not subject or not description or subject == '' or description == '' then return end

    local player = QBox.Functions.GetPlayer(src)
    local senderName = player and (player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname) or GetPlayerName(src)

    MySQL.insert('INSERT INTO support_tickets (sender_source, sender_citizenid, sender_name, subject, description, status) VALUES (?, ?, ?, ?, ?, ?)', {
        src,
        player and player.PlayerData.citizenid or nil,
        senderName,
        subject,
        description,
        'open',
    })

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Your ticket has been submitted. Staff will assist you shortly.' })

    -- Notify online admins a new ticket came in
    for _, playerId in ipairs(QBox.Functions.GetPlayers()) do
        if isAdmin(playerId) then
            TriggerClientEvent('ox_lib:notify', playerId, {
                type = 'inform',
                title = 'New Support Ticket',
                description = senderName .. ': ' .. subject,
            })
        end
    end
end)

-- Admin opens the ticket dashboard
RegisterCommand('tickets', function(source)
    local src = source
    if src == 0 then return end
    if not isAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Unauthorized' })
        return
    end
    fetchTickets(src)
end, false)

-- Refresh the dashboard (used when navigating back from a ticket detail view)
RegisterNetEvent('ticket-system:server:requestDashboard', function()
    local src = source
    if not isAdmin(src) then return end
    fetchTickets(src)
end)

-- Teleport admin to the ticket's sender
RegisterNetEvent('ticket-system:server:teleportToPlayer', function(targetId)
    local src = source
    if not isAdmin(src) then return end
    local targetSrc = tonumber(targetId)
    if not targetSrc then return end
    local ped = GetPlayerPed(targetSrc)
    if not ped or ped == 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player is no longer online' })
        return
    end
    local coords = GetEntityCoords(ped)
    TriggerClientEvent('admin:teleportTo', src, coords)
end)

-- Mark a ticket solved
RegisterNetEvent('ticket-system:server:solveTicket', function(ticketId)
    local src = source
    if not isAdmin(src) then return end
    local id = tonumber(ticketId)
    if not id then return end

    local player = QBox.Functions.GetPlayer(src)
    local resolverName = player and (player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname) or GetPlayerName(src)

    MySQL.update('UPDATE support_tickets SET status = ?, resolver_source = ?, resolver_name = ?, resolved_at = NOW() WHERE id = ?', {
        'solved', src, resolverName, id,
    })

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Ticket #' .. id .. ' marked as solved' })
    fetchTickets(src)
end)
