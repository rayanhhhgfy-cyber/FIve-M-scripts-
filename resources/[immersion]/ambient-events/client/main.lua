RegisterNetEvent('ambient-events:client:eventSpawned', function(event)
    exports['ox_lib']:notify({
        title = 'AMBIENT INCIDENT',
        description = event.data.label,
        type = 'warning',
        length = 8000
    })
end)
