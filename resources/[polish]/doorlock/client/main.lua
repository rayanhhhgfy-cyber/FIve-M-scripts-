local doorStates = {}

RegisterNetEvent('doorlock:sync', function(doorId, locked)
    doorStates[doorId] = locked
end)

CreateThread(function()
    for _, door in ipairs(Config.Doorlock.doors) do
        exports.ox_target:addBoxZone({
            coords = door.coords,
            size = vector3(1.0, 1.0, 2.0),
            rotation = 0,
            options = {
                {
                    name = 'doorlock_' .. door.id,
                    label = door.label,
                    icon = 'fas fa-door-open',
                    onSelect = function()
                        local player = QBox.Functions.GetPlayerData()
                        local hasAccess = false
                        if door.groups then
                            for _, g in ipairs(door.groups) do
                                if player.job.name == g and player.job.grade.level >= (door.jobLevel or 0) then
                                    hasAccess = true
                                end
                            end
                        end
                        if hasAccess then
                            TriggerServerEvent('doorlock:toggle', door.id)
                        else
                            Wrappers.Notify(Locale('doorlock.no_access'), 'error')
                        end
                    end,
                },
            },
        })
    end
end)

CreateThread(function()
    while true do
        Wait(100)
        for id, locked in pairs(doorStates) do
            for _, door in ipairs(Config.Doorlock.doors) do
                if door.id == id then
                    local doorHash = GetHashKey(door.model)
                    DoorSystemSetDoorState(doorHash, locked and 1 or 0, false, false)
                end
            end
        end
    end
end)
