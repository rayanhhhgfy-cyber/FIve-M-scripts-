RegisterNetEvent('bolo:client:list', function()
    QBox.Functions.TriggerCallback('bolo:server:getActive', function(bolos)
        if not bolos or #bolos == 0 then
            Wrappers.Notify('No active BOLOs', 'info')
            return
        end
        local items = {}
        for _, b in ipairs(bolos) do
            local typeIcon = Config.BOLO.types[b.type] and Config.BOLO.types[b.type].icon or 'fas fa-exclamation'
            local info = b.description
            if b.plate and b.plate ~= '' then info = info .. ' | Plate: ' .. b.plate end
            table.insert(items, {
                title = '#' .. b.id .. ' [' .. (Config.BOLO.types[b.type] and Config.BOLO.types[b.type].label or b.type) .. '] ' .. b.title,
                description = info,
                icon = typeIcon,
                onSelect = function()
                    Wrappers.ContextMenu({ id = 'bolo_action_' .. b.id, title = 'BOLO #' .. b.id, menuItems = {
                        { title = 'Mark Resolved', icon = 'fas fa-check', onSelect = function() TriggerServerEvent('bolo:server:resolve', b.id) end },
                    }})
                end,
            })
        end
        Wrappers.ContextMenu({ id = 'bolo_list', title = 'Active BOLOs (' .. #bolos .. ')', menuItems = items })
    end)
end)

RegisterNetEvent('bolo:client:create', function()
    local input = Wrappers.InputDialog({ title = 'Create BOLO', options = {
        { type = 'select', label = 'Type', options = {
            { value = 'vehicle', label = 'Vehicle' },
            { value = 'person', label = 'Person' },
            { value = 'warrant', label = 'Warrant' },
            { value = 'property', label = 'Property' },
        }},
        { type = 'input', label = 'Title', placeholder = 'e.g. Suspect vehicle' },
        { type = 'input', label = 'Description', placeholder = 'e.g. Blue Buffalo, last seen...' },
        { type = 'input', label = 'License Plate (optional)' },
        { type = 'input', label = 'Last Seen Location (optional)' },
    }})
    if input then
        TriggerServerEvent('bolo:server:create', input[1], input[2], input[3], input[4] or '', input[5] or '')
    end
end)
