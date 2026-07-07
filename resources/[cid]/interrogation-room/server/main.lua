local QBox = exports['qbx_core']:GetCoreObject()
local sessions = {}

RegisterNetEvent('interrogation:start', function(suspectSrc)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p or not (p.PlayerData.job.name == Config.Interrogation.allowedJob and p.PlayerData.job.onduty) then return end
    sessions[src] = { suspect = suspectSrc, started = os.time(), evidencePresented = 0 }
    TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Interrogation recording started' })
    TriggerClientEvent('interrogation:sessionStarted', src)
end)

RegisterNetEvent('interrogation:presentEvidence', function(suspectSrc, effective)
    local src = source
    if not sessions[src] then return end
    sessions[src].evidencePresented = (sessions[src].evidencePresented or 0) + 1
    if sessions[src].evidencePresented >= 3 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Suspect confessed after overwhelming evidence' })
        TriggerClientEvent('interrogation:confession', src)
        sessions[src] = nil
        MySQL.insert('INSERT INTO mdt_reports (citizenid, title, content, time) VALUES (?, ?, ?, ?)',
            { p.PlayerData.citizenid, 'Interrogation Confession', 'Confession obtained after ' .. sessions[src].evidencePresented .. ' evidence presented', os.time() })
    end
end)

RegisterNetEvent('interrogation:end', function(suspectSrc)
    local src = source
    sessions[src] = nil
end)
