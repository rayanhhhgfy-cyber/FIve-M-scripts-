local QBox = exports['qbx-core']:GetCoreObject()

function GodDashboard.GetBunkers()
    QBox.Functions.TriggerCallback('god-dashboard:getBunkers', function(list)
        SendNUIMessage({ action = 'setBunkers', bunkers = list or {} })
    end)
end

function GodDashboard.TeleportToBunker(id)
    QBox.Functions.TriggerCallback('god-dashboard:getBunkerCoords', function(coords)
        if coords then
            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0)
            Wrappers.Notify('Teleported to bunker', 'success')
        end
    end, id)
end

function GodDashboard.DeleteBunker(id)
    TriggerServerEvent('god-dashboard:deleteBunker', id)
    Wrappers.Notify('Bunker deleted', 'success')
end

function GodDashboard.UpdateBunker(id, data)
    TriggerServerEvent('god-dashboard:updateBunker', id, data)
    Wrappers.Notify('Bunker updated', 'success')
end

function GodDashboard.DuplicateBunker(id)
    TriggerServerEvent('god-dashboard:duplicateBunker', id)
    Wrappers.Notify('Bunker duplicated', 'success')
end

function GodDashboard.PreviewBunker(id)
    QBox.Functions.TriggerCallback('god-dashboard:getBunkerCoords', function(coords)
        if coords then
            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0)
            Wrappers.Notify('Teleported to bunker entrance', 'success')
        end
    end, id)
end
