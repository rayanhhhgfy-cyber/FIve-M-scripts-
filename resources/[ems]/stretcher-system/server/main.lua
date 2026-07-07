local QBCore = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('stretcher-system:server:fold', function()
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    p.Functions.AddItem('stretcher', 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Stretcher returned to inventory' })
end)
