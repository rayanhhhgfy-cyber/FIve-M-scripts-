local presetColors = {
    weather = '#FFC107',
    emergency = '#F44336',
    news = '#4CAF50',
    maintenance = '#9E9E9E',
    event = '#E040FB',
}

RegisterNetEvent('alert:client:receive', function(presetId, message, duration)
    local color = presetColors[presetId] or '#FFFFFF'
    Wrappers.AlertDialog({
        title = string.upper(presetId) .. ' ALERT',
        content = message,
        icon = 'fas fa-bullhorn',
        color = color,
    })
end)
