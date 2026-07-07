local preview = require 'client.preview'

function GodDashboard.SpawnVehicle(model)
    preview.startVehicle(model, function(result)
        TriggerServerEvent('god-dashboard:spawnVehicle', {
            model = model,
            coords = result.coords,
            heading = result.heading,
        })
    end)
end
