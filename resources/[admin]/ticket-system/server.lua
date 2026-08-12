local ticketsFile = 'tickets_save.json'
local tickets = {
    active = {},
    history = {}
}

local Framework = 'standalone'

-- Detect Framework
Citizen.CreateThread(function()
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        Framework = 'esx'
    end
    print('^2[ticket-system] Detected active framework bridge: ' .. string.upper(Framework) .. '^7')
    LoadTickets()
end)

function LoadTickets()
    local content = LoadResourceFile(GetCurrentResourceName(), ticketsFile)
    if content then
        tickets = json.decode(content) or { active = {}, history = {} }
        -- Perform auto-filtering on load for previous/current month history
        FilterHistory()
    else
        tickets = { active = {}, history = {} }
    end
end

function SaveTickets()
    SaveResourceFile(GetCurrentResourceName(), ticketsFile, json.encode(tickets, { indent = true }), -1)
end

function FilterHistory()
    local currentTime = os.date("*t", os.time())
    local filtered = {}
    for _, t in ipairs(tickets.history or {}) do
        local ticketTime = os.date("*t", t.timestamp)
        local isCurrentMonth = (ticketTime.year == currentTime.year and ticketTime.month == currentTime.month)
        local isPreviousMonth = false
        if currentTime.month == 1 then
            isPreviousMonth = (ticketTime.year == currentTime.year - 1 and ticketTime.month == 12)
        else
            isPreviousMonth = (ticketTime.year == currentTime.year and ticketTime.month == currentTime.month - 1)
        end
        if isCurrentMonth or isPreviousMonth then
            table.insert(filtered, t)
        end
    end
    tickets.history = filtered
    SaveTickets()
end

-- Robust player and admin group fetcher
local function GetPlayerServer(source)
    if Framework == 'qbox' then
        return exports.qbx_core:GetPlayer(source)
    elseif Framework == 'qb' then
        return exports['qb-core']:GetCoreObject().Functions.GetPlayer(source)
    elseif Framework == 'esx' then
        return exports['es_extended']:getSharedObject().GetPlayerFromId(source)
    else
        return nil
    end
end

local function isAdmin(src)
    -- Native ACE check first (Perfect for QBox and general standalone command registrations)
    if IsPlayerAceAllowed(src, 'command.tickets') or IsPlayerAceAllowed(src, 'command.mapbuilder') then
        return true
    end

    -- Fallback to group checking for QBCore / ESX
    local player = GetPlayerServer(src)
    if not player then return false end

    local group = 'user'
    if player.PlayerData and player.PlayerData.group then
        group = player.PlayerData.group
    elseif player.getGroup then
        group = player.getGroup()
    end

    local adminGroups = { 'admin', 'superadmin', 'god' }
    for _, g in ipairs(adminGroups) do
        if g == group then return true end
    end
    return false
end

local function GetPlayerNameServer(src)
    local p = GetPlayerServer(src)
    if not p then return GetPlayerName(src) or 'Unknown' end

    if Framework == 'qbox' or Framework == 'qb' then
        if p.PlayerData and p.PlayerData.charinfo then
            return (p.PlayerData.charinfo.firstname or '') .. ' ' .. (p.PlayerData.charinfo.lastname or '')
        end
    elseif Framework == 'esx' then
        return p.getName() or GetPlayerName(src) or 'Unknown'
    end
    return GetPlayerName(src) or 'Unknown'
end

-- Events
RegisterNetEvent('ticket-system:server:openTicket', function(subject, description)
    local src = source
    local name = GetPlayerNameServer(src)
    local id = 'ticket_' .. os.time() .. '_' .. math.random(1111, 9999)

    local ticket = {
        id = id,
        senderId = src,
        senderName = name,
        subject = subject,
        description = description,
        timestamp = os.time()
    }

    table.insert(tickets.active, ticket)
    SaveTickets()

    -- Notify player
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Support ticket submitted successfully!' })

    -- Notify all online admins
    local players = GetPlayers()
    for _, pid in ipairs(players) do
        local sid = tonumber(pid)
        if isAdmin(sid) then
            TriggerClientEvent('ox_lib:notify', sid, { type = 'info', description = 'New support ticket from ' .. name .. ' (ID: ' .. src .. ')' })
        end
    end
end)

RegisterNetEvent('ticket-system:server:requestDashboard', function()
    local src = source
    if not isAdmin(src) then return end
    -- Perform month filter before displaying history
    FilterHistory()
    TriggerClientEvent('ticket-system:client:openDashboard', src, tickets.active, tickets.history)
end)

RegisterNetEvent('ticket-system:server:teleportToPlayer', function(targetId)
    local src = source
    if not isAdmin(src) then return end

    local targetPed = GetPlayerPed(targetId)
    if targetPed ~= 0 and DoesEntityExist(targetPed) then
        local coords = GetEntityCoords(targetPed)
        local adminPed = GetPlayerPed(src)
        SetEntityCoords(adminPed, coords.x, coords.y, coords.z, false, false, false, false)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Teleported to player ID ' .. targetId })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player is offline or entity not found' })
    end
end)

RegisterNetEvent('ticket-system:server:solveTicket', function(ticketId)
    local src = source
    if not isAdmin(src) then return end

    local foundIndex = nil
    local ticket = nil
    for i, t in ipairs(tickets.active) do
        if t.id == ticketId then
            foundIndex = i
            ticket = t
            break
        end
    end

    if ticket then
        table.remove(tickets.active, foundIndex)

        -- Insert into history with responder details
        ticket.resolverId = src
        ticket.resolverName = GetPlayerNameServer(src)
        ticket.solvedAt = os.time()

        table.insert(tickets.history, ticket)
        SaveTickets()

        -- Notify player if online
        local targetPed = GetPlayerPed(ticket.senderId)
        if targetPed ~= 0 then
            TriggerClientEvent('ox_lib:notify', ticket.senderId, { type = 'success', description = 'Your ticket was marked as solved by admin ' .. ticket.resolverName })
        end

        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Support ticket solved!' })
        -- Re-open dashboard with updated states
        TriggerClientEvent('ticket-system:client:openDashboard', src, tickets.active, tickets.history)
    end
end)

RegisterCommand('tickets', function(source)
    local src = source
    if isAdmin(src) then
        -- Perform month filter before displaying history
        FilterHistory()
        TriggerClientEvent('ticket-system:client:openDashboard', src, tickets.active, tickets.history)
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Unauthorized' })
    end
end, false)

RegisterCommand('ticketdashboard', function(source)
    local src = source
    if isAdmin(src) then
        -- Perform month filter before displaying history
        FilterHistory()
        TriggerClientEvent('ticket-system:client:openDashboard', src, tickets.active, tickets.history)
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Unauthorized' })
    end
end, false)
