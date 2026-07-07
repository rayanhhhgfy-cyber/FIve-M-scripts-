local QBox = exports['qbx-core']:GetCoreObject()
local activeSession = false
local suspectServerId = nil

local function isCID()
    local job = QBox.Functions.GetPlayerData().job
    return job and job.name == Config.Interrogation.allowedJob and job.onduty
end

Citizen.CreateThread(function()
    local loc = Config.Interrogation.location
    exports.ox_target:addBoxZone({
        coords = loc.coords,
        size = vector3(2.0, 2.0, 2.5),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'interrogation_start',
                icon = 'fas fa-microphone',
                label = 'Start Interrogation',
                distance = 2.0,
                canInteract = function() return isCID() and not activeSession end,
                onSelect = function()
                    local players = GetActivePlayers()
                    local closePlayers = {}
                    for _, pid in ipairs(players) do
                        local target = GetPlayerPed(pid)
                        local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(target))
                        if dist < 5.0 and pid ~= PlayerId() then
                            table.insert(closePlayers, { id = pid, label = GetPlayerName(pid) })
                        end
                    end
                    if #closePlayers == 0 then
                        Wrappers.Notify('No one nearby to interrogate', 'error')
                        return
                    end
                    local items = {}
                    for _, cp in ipairs(closePlayers) do
                        table.insert(items, { title = cp.label, onSelect = function()
                            suspectServerId = GetPlayerServerId(cp.id)
                            TriggerServerEvent('interrogation:start', suspectServerId)
                            activeSession = true
                        end})
                    end
                    Wrappers.ContextMenu({ id = 'interrogation_select', title = 'Select Suspect', menuItems = items })
                end,
            },
            {
                name = 'interrogation_present_evidence',
                icon = 'fas fa-file-alt',
                label = 'Present Evidence',
                distance = 2.0,
                canInteract = function() return activeSession end,
                onSelect = function()
                    Wrappers.ProgressBar({
                        duration = 3000,
                        label = 'Presenting evidence...',
                        useWhileDead = false,
                        canCancel = true,
                    }, function(cancelled)
                        if not cancelled then
                            local success = math.random() > 0.3
                            if success then
                                Wrappers.Notify('Suspect is breaking — evidence is compelling', 'success')
                            else
                                Wrappers.Notify('Suspect is resisting — need more evidence', 'error')
                            end
                            TriggerServerEvent('interrogation:presentEvidence', suspectServerId, success)
                        end
                    end)
                end,
            },
            {
                name = 'interrogation_end',
                icon = 'fas fa-stop',
                label = 'End Interrogation',
                distance = 2.0,
                canInteract = function() return activeSession end,
                onSelect = function()
                    TriggerServerEvent('interrogation:end', suspectServerId)
                    activeSession = false
                    suspectServerId = nil
                    Wrappers.Notify('Interrogation ended', 'info')
                end,
            },
        },
    })
end)

RegisterNetEvent('interrogation:sessionStarted', function()
    activeSession = true
    Wrappers.Notify('Interrogation session started — recording', 'info')
end)

RegisterNetEvent('interrogation:confession', function()
    Wrappers.Notify('CONFESSION OBTAINED', 'success')
    activeSession = false
end)
