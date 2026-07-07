local inCourt = false

RegisterNetEvent('court:jurySummon', function(caseId)
    Wrappers.AlertDialog({
        title = 'JURY SUMMONS',
        content = 'You have been summoned for jury duty on Case ' .. caseId .. '. Report to the courthouse.',
        icon = 'fas fa-gavel',
        color = '#4CAF50',
    })
end)

RegisterNetEvent('court:verdict', function(caseId, verdict, guiltyVotes, totalVotes)
    Wrappers.AlertDialog({
        title = 'VERDICT REACHED',
        content = 'Case ' .. caseId .. ': ' .. string.upper(verdict) .. ' (' .. guiltyVotes .. '/' .. totalVotes .. ')',
        icon = 'fas fa-gavel',
        color = verdict == 'guilty' and '#F44336' or '#4CAF50',
    })
end)

RegisterNetEvent('court:sentenced', function(caseId, sentenceTime, fine)
    Wrappers.AlertDialog({
        title = 'SENTENCED',
        content = 'Case ' .. caseId .. ': ' .. sentenceTime .. 's jail, $' .. fine .. ' fine',
        icon = 'fas fa-handcuffs',
        color = '#FF9800',
    })
end)

RegisterCommand('filecase', function(source, args)
    local input = Wrappers.InputDialog({ title = 'File Case', options = {
        { type = 'input', label = 'Defendant CID', placeholder = 'e.g. ABC123' },
        { type = 'input', label = 'Charge', placeholder = 'e.g. Grand Theft Auto' },
        { type = 'input', label = 'Description', placeholder = 'Details of the case...' },
    }})
    if input then
        TriggerServerEvent('court:fileCase', input[1], input[2], input[3])
    end
end)

RegisterCommand('cases', function()
    QBox.Functions.TriggerCallback('court:getCases', function(cases)
        if not cases or #cases == 0 then
            Wrappers.Notify('No active cases', 'info')
            return
        end
        local items = {}
        for _, c in ipairs(cases) do
            table.insert(items, { title = c.id .. ' - ' .. c.charge, description = 'Status: ' .. c.status, onSelect = function()
                ShowCaseMenu(c.id)
            end })
        end
        Wrappers.ContextMenu({ id = 'case_list', title = 'Active Cases', menuItems = items })
    end)
end)

function ShowCaseMenu(caseId)
    QBox.Functions.TriggerCallback('court:getCase', function(c)
        if not c then return end
        local items = {
            { title = 'View Evidence', icon = 'fas fa-folder-open', onSelect = function()
                if not c.evidence or #c.evidence == 0 then
                    Wrappers.Notify('No evidence', 'info')
                    return
                end
                local evItems = {}
                for _, e in ipairs(c.evidence) do
                    table.insert(evItems, { title = '#' .. e.id .. ': ' .. e.label, description = e.description })
                end
                Wrappers.ContextMenu({ id = 'evidence_' .. caseId, title = 'Evidence', menuItems = evItems })
            end },
            { title = 'Add Evidence', icon = 'fas fa-plus', onSelect = function()
                local input = Wrappers.InputDialog({ title = 'Add Evidence', options = {
                    { type = 'input', label = 'Label', placeholder = 'e.g. Weapon found at scene' },
                    { type = 'input', label = 'Description', placeholder = 'Detailed description...' },
                }})
                if input then
                    TriggerServerEvent('court:addEvidence', caseId, input[1], input[2])
                end
            end },
            { title = 'Request Bail', icon = 'fas fa-hand-holding-usd', onSelect = function() TriggerServerEvent('court:requestBail', caseId) end },
            { title = 'Pay Bail', icon = 'fas fa-dollar-sign', onSelect = function() TriggerServerEvent('court:payBail', caseId) end },
            { title = 'Appeal ($' .. Config.CourtSystem.appealCost .. ')', icon = 'fas fa-redo', onSelect = function() TriggerServerEvent('court:appeal', caseId) end },
        }
        Wrappers.ContextMenu({ id = 'case_' .. caseId, title = c.id .. ' - ' .. c.charge, menuItems = items })
    end, caseId)
end

RegisterCommand('starttrial', function(source, args)
    local caseId = args[1]
    if caseId then TriggerServerEvent('court:startTrial', caseId) end
end)

RegisterCommand('juryvote', function(source, args)
    local caseId = args[1]
    local vote = args[2]
    if caseId and (vote == 'guilty' or vote == 'not_guilty') then
        TriggerServerEvent('court:juryVote', caseId, vote)
    end
end)

RegisterCommand('sentence', function(source, args)
    local caseId = args[1]
    local time = tonumber(args[2]) or 0
    local fine = tonumber(args[3]) or 0
    if caseId then TriggerServerEvent('court:sentence', caseId, time, fine) end
end)
