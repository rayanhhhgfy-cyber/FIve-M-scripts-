local insideShelter = nil

RegisterNetEvent('advancedalerts:receive', function(alertType, title, message, duration)
    local config = Config.AdvancedAlerts.alertTypes[alertType]
    Wrappers.AlertDialog({
        title = (config and config.label or string.upper(alertType)) .. ': ' .. title,
        content = message,
        icon = config and config.icon or 'fas fa-bell',
        color = config and config.color or '#FFFFFF',
    })
end)

RegisterNetEvent('advancedalerts:evacuationZone', function(zone)
    Wrappers.AlertDialog({
        title = 'EVACUATION ORDER',
        content = 'You are in ' .. zone.name .. '. Proceed to shelter at ' .. tostring(zone.shelter) .. '.',
        icon = 'fas fa-people-arrows',
        color = '#FF9800',
    })
    SetNewWaypoint(zone.shelter.x, zone.shelter.y)
end)

RegisterNetEvent('advancedalerts:tornadoWarning', function(event)
    Wrappers.AlertDialog({
        title = 'TORNADO WARNING',
        content = 'A tornado has been detected in your area. Take cover immediately!',
        icon = 'fas fa-cloud',
        color = '#FFC107',
    })
end)

RegisterNetEvent('advancedalerts:hurricaneWarning', function(event)
    Wrappers.AlertDialog({
        title = 'HURRICANE WARNING',
        content = 'A hurricane is approaching. Evacuate coastal areas now.',
        icon = 'fas fa-wind',
        color = '#F44336',
    })
end)

RegisterNetEvent('advancedalerts:insideShelter', function(shelterId)
    insideShelter = shelterId
    Wrappers.Notify('You are safe in the shelter. Press X to exit.', 'success')
end)

RegisterNetEvent('advancedalerts:outsideShelter', function()
    insideShelter = nil
    Wrappers.Notify('You have left the shelter.', 'info')
end)

-- Shelter targets
Citizen.CreateThread(function()
    for _, shelter in ipairs(Config.AdvancedAlerts.shelters) do
        exports['ox_target']:addBoxZone({
            coords = shelter.coords,
            size = vector3(2.0, 2.0, 2.0),
            rotation = 0,
            debug = false,
            options = {
                { label = 'Enter ' .. shelter.name, icon = 'fas fa-home', onSelect = function()
                    TriggerServerEvent('advancedalerts:enterShelter', shelter.id)
                end },
            },
        })
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if insideShelter and IsControlJustPressed(0, 73) then -- X
            TriggerServerEvent('advancedalerts:exitShelter', insideShelter)
        end
    end
end)
