--- Creates ox_target zones on all trash can prop models
Citizen.CreateThread(function()
    for _, model in ipairs(Config.TrashCans.propModels) do
        exports['ox_target']:addTargetModel(model, {
            options = {
                {
                    name = 'search_trash',
                    icon = 'fas fa-trash',
                    label = 'Search Trash',
                    distance = Config.TrashCans.maxDistance,
                    onSelect = function(data)
                        local entity = data.entity
                        if not entity then return end
                        local netId = NetworkGetNetworkIdFromEntity(entity)
                        -- Play search animation
                        local ped = PlayerPedId()
                        local animDict = 'amb@prop_human_bum_bin@base'
                        local animName = 'base'
                        RequestAnimDict(animDict)
                        while not HasAnimDictLoaded(animDict) do Citizen.Wait(10) end
                        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, Config.TrashCans.searchTime, 1, 0, false, false, false)
                        -- Progress bar
                        Wrappers.ProgressBar({
                            label = 'Searching trash...',
                            duration = Config.TrashCans.searchTime,
                            useWhileDead = false,
                            canCancel = true,
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        }, function(cancelled)
                            ClearPedTasks(ped)
                            if not cancelled then
                                TriggerServerEvent('trashcan:search', netId)
                            end
                        end)
                    end,
                },
            },
            distance = Config.TrashCans.maxDistance,
        })
    end
end)
