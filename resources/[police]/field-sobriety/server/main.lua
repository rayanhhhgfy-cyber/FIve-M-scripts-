local QBox = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('sobriety:result', function(targetSrc, test, passed)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    if passed then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = test .. ' — PASSED' })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = test .. ' — FAILED (DUI indicators)' })
    end
end)
