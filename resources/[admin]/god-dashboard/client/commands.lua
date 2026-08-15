local QBox = exports['qbx_core']:GetCoreObject()

function GodDashboard.GetCommands()
    QBox.Functions.TriggerCallback('god-dashboard:getCommands', function(commands)
        SendNUIMessage({ action = 'setCommands', commands = commands or {} })
    end)
end
