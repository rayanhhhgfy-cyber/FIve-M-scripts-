RegisterCommand('openticket', function()
    local input = exports.ox_lib:inputDialog('Support Ticket Form', {
        { type = 'input', label = 'What Happened? (Subject)', required = true, placeholder = 'e.g. Stuck in vehicle' },
        { type = 'textarea', label = 'Detailed Description', required = true, placeholder = 'Provide as much detail as possible...' }
    })
    if not input then return end
    local subject = input[1]
    local desc = input[2]

    TriggerServerEvent('ticket-system:server:openTicket', subject, desc)
end, false)

RegisterNetEvent('ticket-system:client:openDashboard', function(activeTickets, historyTickets)
    local mainOptions = {
        {
            title = 'Active Support Tickets (' .. #activeTickets .. ')',
            description = 'View and solve open player tickets',
            icon = 'fas fa-ticket-alt',
            onSelect = function()
                OpenActiveTicketsMenu(activeTickets)
            end
        },
        {
            title = 'Ticket History (Prev/Current Month)',
            description = 'View resolved ticket history list',
            icon = 'fas fa-history',
            onSelect = function()
                OpenHistoryTicketsMenu(historyTickets)
            end
        }
    }
    exports.ox_lib:registerContext({
        id = 'ticket_admin_main',
        title = 'Admin Ticket Dashboard',
        options = mainOptions
    })
    exports.ox_lib:showContext('ticket_admin_main')
end)

function OpenActiveTicketsMenu(tickets)
    local options = {}
    for i, t in ipairs(tickets) do
        table.insert(options, {
            title = t.subject .. ' (ID: ' .. t.senderId .. ')',
            description = 'Opened by ' .. t.senderName .. ' - ' .. os.date('%H:%M:%S', t.timestamp),
            icon = 'fas fa-envelope-open-text',
            onSelect = function()
                OpenTicketDetailMenu(t)
            end
        })
    end
    if #options == 0 then
        table.insert(options, { title = 'No active tickets', disabled = true })
    end
    table.insert(options, {
        title = '← Back to Main Menu',
        onSelect = function()
            exports.ox_lib:showContext('ticket_admin_main')
        end
    })
    exports.ox_lib:registerContext({
        id = 'ticket_active_list',
        title = 'Active Tickets',
        options = options
    })
    exports.ox_lib:showContext('ticket_active_list')
end

function OpenTicketDetailMenu(t)
    local options = {
        {
            title = 'Subject: ' .. t.subject,
            description = t.description,
            disabled = true
        },
        {
            title = 'Opener: ' .. t.senderName .. ' (ID: ' .. t.senderId .. ')',
            disabled = true
        },
        {
            title = 'Teleport to Player',
            description = 'Instantly teleport to ' .. t.senderName,
            icon = 'fas fa-location-arrow',
            onSelect = function()
                TriggerServerEvent('ticket-system:server:teleportToPlayer', t.senderId)
            end
        },
        {
            title = 'Mark as Solved',
            description = 'Resolve this support ticket',
            icon = 'fas fa-check-circle',
            onSelect = function()
                TriggerServerEvent('ticket-system:server:solveTicket', t.id)
            end
        },
        {
            title = '← Back to Active Tickets',
            onSelect = function()
                TriggerServerEvent('ticket-system:server:requestDashboard')
            end
        }
    }
    exports.ox_lib:registerContext({
        id = 'ticket_detail_' .. t.id,
        title = 'Ticket Details',
        options = options
    })
    exports.ox_lib:showContext('ticket_detail_' .. t.id)
end

function OpenHistoryTicketsMenu(tickets)
    local options = {}
    for i, t in ipairs(tickets) do
        table.insert(options, {
            title = t.subject .. ' [SOLVED]',
            description = 'Opener: ' .. t.senderName .. ' (ID: ' .. t.senderId .. ')\nSolved by: ' .. t.resolverName .. ' (ID: ' .. t.resolverId .. ')',
            disabled = true,
            icon = 'fas fa-check'
        })
    end
    if #options == 0 then
        table.insert(options, { title = 'No ticket history found', disabled = true })
    end
    table.insert(options, {
        title = '← Back to Main Menu',
        onSelect = function()
            exports.ox_lib:showContext('ticket_admin_main')
        end
    })
    exports.ox_lib:registerContext({
        id = 'ticket_history_list',
        title = 'Ticket History',
        options = options
    })
    exports.ox_lib:showContext('ticket_history_list')
end
