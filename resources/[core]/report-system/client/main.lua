RegisterNetEvent('report:client:showReports', function()
    QBox.Functions.TriggerCallback('report:server:getReports', function(reports)
        if not reports or #reports == 0 then
            Wrappers.Notify('No open reports', 'info')
            return
        end
        local items = {}
        for _, r in ipairs(reports) do
            local statusIcon = r.status == 'open' and '📩' or '🔄'
            table.insert(items, {
                title = '#' .. r.id .. ' ' .. r.playerName,
                description = r.reason .. ' [' .. r.status .. ']',
                icon = 'fas fa-ticket-alt',
                onSelect = function()
                    Wrappers.ContextMenu({ id = 'report_action_' .. r.id, title = 'Report #' .. r.id, menuItems = {
                        { title = 'Accept Report', icon = 'fas fa-check', onSelect = function() TriggerServerEvent('report:server:accept', r.id) end },
                        { title = 'Close Report', icon = 'fas fa-times', onSelect = function()
                            Wrappers.InputDialog({ title = 'Close Report #' .. r.id, options = { { type = 'input', label = 'Resolution', placeholder = 'e.g. Warned player' } } }, function(v)
                                if v then TriggerServerEvent('report:server:close', r.id, v[1]) end
                            end)
                        end},
                    }})
                end,
            })
        end
        Wrappers.ContextMenu({ id = 'report_list', title = 'Open Reports (' .. #reports .. ')', menuItems = items })
    end)
end)
