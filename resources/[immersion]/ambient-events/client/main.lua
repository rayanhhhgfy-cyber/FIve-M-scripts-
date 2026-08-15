local activeEventBlips = {}

RegisterNetEvent('ambient-events:client:eventSpawned', function(eventData)
    Wrappers.Notify('Dispatch Alert: ' .. eventData.label, 'warning')
    if eventData.coords then
        local blip = AddBlipForCoord(eventData.coords.x, eventData.coords.y, eventData.coords.z)
        SetBlipSprite(blip, 161)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 0.9)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Incident: " .. eventData.label)
        EndTextCommandSetBlipName(blip)
        activeEventBlips[eventData.id] = blip
    end
end)

RegisterNetEvent('ambient-events:client:eventResolved', function(eventId)
    if activeEventBlips[eventId] then
        RemoveBlip(activeEventBlips[eventId])
        activeEventBlips[eventId] = nil
    end
    Wrappers.Notify('Incident resolved and cleared.', 'success')
end)
