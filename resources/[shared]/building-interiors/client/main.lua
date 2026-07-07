local activeInteriors = {}

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end

    for _, interior in ipairs(Config.BuildingInteriors.interiors) do
        -- Entrance target
        exports.ox_target:addBoxZone({
            coords = interior.entrance,
            size = vector3(1.5, 1.5, 2.5),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'interior_enter_' .. interior.id,
                    icon = 'fas fa-door-open',
                    label = 'Enter ' .. interior.label,
                    distance = Config.BuildingInteriors.maxDistance,
                    onSelect = function()
                        if interior.ipl then
                            RequestIpl(interior.ipl)
                        end
                        DoScreenFadeOut(500)
                        while not IsScreenFadedOut() do Citizen.Wait(10) end
                        SetEntityCoords(PlayerPedId(), interior.interior.x, interior.interior.y, interior.interior.z)
                        SetEntityHeading(PlayerPedId(), interior.headingIn)
                        Citizen.Wait(500)
                        DoScreenFadeIn(500)
                        activeInteriors[interior.id] = true
                    end,
                },
            },
        })

        -- Exit target at interior
        exports.ox_target:addBoxZone({
            coords = interior.interior,
            size = vector3(1.5, 1.5, 2.5),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'interior_exit_' .. interior.id,
                    icon = 'fas fa-door-open',
                    label = 'Exit ' .. interior.label,
                    distance = Config.BuildingInteriors.maxDistance,
                    onSelect = function()
                        DoScreenFadeOut(500)
                        while not IsScreenFadedOut() do Citizen.Wait(10) end
                        SetEntityCoords(PlayerPedId(), interior.entrance.x, interior.entrance.y, interior.entrance.z)
                        SetEntityHeading(PlayerPedId(), interior.headingOut)
                        Citizen.Wait(500)
                        DoScreenFadeIn(500)
                        activeInteriors[interior.id] = nil
                    end,
                },
            },
        })
    end
end)
