local QBox = exports['qbx-core']:GetCoreObject()

function GodDashboard.GetCommands()
    QBox.Functions.TriggerCallback('god-dashboard:getCommands', function(commands)
        SendNUIMessage({ action = 'setCommands', commands = commands or {} })
    end)
end
