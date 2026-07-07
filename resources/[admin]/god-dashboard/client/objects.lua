local QBox = exports['qbx-core']:GetCoreObject()
local preview = require 'client.preview'

function GodDashboard.PlaceObject(model)
    preview.startObject(model, function(result)
        TriggerServerEvent('god-dashboard:placeObject', {
            model = model,
            coords = result.coords,
            heading = result.heading,
        })
        Wrappers.Notify('Object placed: ' .. model, 'success')
    end)
end

function GodDashboard.DeletePlacedObject(id)
    TriggerServerEvent('god-dashboard:deleteObject', id)
    Wrappers.Notify('Object deleted', 'success')
end

function GodDashboard.GetPlacedObjects()
    QBox.Functions.TriggerCallback('god-dashboard:getPlacedObjects', function(objects)
        SendNUIMessage({ action = 'setObjects', objects = objects or {} })
    end)
end

function GodDashboard.TeleportToObject(id)
    QBox.Functions.TriggerCallback('god-dashboard:getObjectCoords', function(coords)
        if coords then
            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0)
            Wrappers.Notify('Teleported to object', 'success')
        end
    end, id)
end
