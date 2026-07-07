local QBCore = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('txadmin-hooks:client:notification', function(message, type, duration)
    TriggerEvent('ox_lib:notify', {
        type = type or 'info',
        description = message or '',
        duration = duration or 5000
    })
end)

RegisterNetEvent('chat:addMessage', function(data)
    TriggerEvent('chat:addMessage', data)
end)
