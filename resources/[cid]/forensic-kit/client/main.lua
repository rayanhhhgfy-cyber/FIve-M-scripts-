local QBox = exports['qbx-core']:GetCoreObject()
local collectedEvidence = {}

local function isCID()
    local job = QBox.Functions.GetPlayerData().job
    return job and job.name == Config.ForensicKit.allowedJob and job.onduty
end

RegisterCommand('forensic', function()
    if not isCID() then Wrappers.Notify('CID only', 'error') return end
    local items = {}
    for ekey, edata in pairs(Config.ForensicKit.evidenceTypes) do
        table.insert(items, { title = 'Collect ' .. edata.label, description = edata.collectTime / 1000 .. 's', onSelect = function()
            Wrappers.ProgressBar({
                duration = edata.collectTime,
                label = 'Collecting ' .. edata.label .. '...',
                useWhileDead = false,
                canCancel = true,
                disable = { move = true, car = true, combat = true },
                anim = { dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', clip = 'base' },
            }, function(cancelled)
                if not cancelled then
                    table.insert(collectedEvidence, { type = ekey, label = edata.label, time = os.time() })
                    TriggerServerEvent('forensic:collect', ekey)
                    Wrappers.Notify(edata.label .. ' collected', 'success')
                end
            end)
        end})
    end
    table.insert(items, { title = 'View Collected (' .. #collectedEvidence .. ')', onSelect = function()
        local viewItems = {}
        for _, e in ipairs(collectedEvidence) do
            table.insert(viewItems, { title = e.label, description = os.date('%H:%M:%S', e.time) })
        end
        table.insert(viewItems, { title = 'Clear Evidence Log', onSelect = function()
            collectedEvidence = {}
            Wrappers.Notify('Evidence log cleared', 'info')
        end})
        Wrappers.ContextMenu({ id = 'evidence_log', title = 'Collected Evidence', menuItems = viewItems })
    end})
    Wrappers.ContextMenu({ id = 'forensic_menu', title = 'Forensic Kit', menuItems = items })
end, false)
RegisterKeyMapping('forensic', 'Forensic Kit', 'keyboard', 'i')

exports('getCollectedEvidence', function() return collectedEvidence end)
