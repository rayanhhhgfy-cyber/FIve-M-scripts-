local QBox = exports['qbx_core']:GetCoreObject()

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.Alerts.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

RegisterNetEvent('alert:server:send', function(presetId, message, duration)
    local src = source
    if not isAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not authorized' })
        return
    end
    if not message then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Message required' })
        return
    end
    TriggerClientEvent('alert:client:receive', -1, presetId, message, duration or Config.Alerts.defaultDuration)
end)

RegisterNetEvent('alert:server:emergency', function(message)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('alert:client:receive', -1, 'emergency', message or '⚠️ Emergency Alert', 30000)
end)

QBox.Commands.Add('alert', 'Send a server alert', {}, false, function(source, args)
    local presetId = args[1] or 'news'
    local msg = table.concat(args, ' ', 2)
    if msg == '' then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Usage: /alert [preset] [message]' })
        return
    end
    TriggerEvent('alert:server:send', presetId, msg)
end)

QBox.Commands.Add('emergency', 'Send an emergency alert', {}, false, function(source, args)
    local msg = table.concat(args, ' ', 1)
    TriggerEvent('alert:server:emergency', msg)
end)
