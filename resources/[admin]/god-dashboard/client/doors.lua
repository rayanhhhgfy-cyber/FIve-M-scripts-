local QBox = exports['qbx-core']:GetCoreObject()

function GodDashboard.GetDoors()
    QBox.Functions.TriggerCallback('god-dashboard:getDoors', function(doors)
        SendNUIMessage({ action = 'setDoors', doors = doors or {} })
    end)
end

function GodDashboard.DeleteDoor(id)
    TriggerServerEvent('god-dashboard:deleteDoor', id)
    Wrappers.Notify('Passcode door deleted', 'success')
end

function GodDashboard.CreateDoor(data)
    TriggerServerEvent('god-dashboard:createDoor', data)
    Wrappers.Notify('Passcode door created', 'success')
end

function GodDashboard.UpdateDoorPasscode(id, passcode)
    TriggerServerEvent('god-dashboard:updateDoorPasscode', id, passcode)
    Wrappers.Notify('Door passcode updated', 'success')
end

function GodDashboard.GrantDoorAccess(doorId, cid)
    TriggerServerEvent('god-dashboard:grantDoorAccess', doorId, cid)
end

function GodDashboard.RevokeDoorAccess(doorId, cid)
    TriggerServerEvent('god-dashboard:revokeDoorAccess', doorId, cid)
end
