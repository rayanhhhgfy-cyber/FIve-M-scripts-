local QBCore = exports['qbx-core']:GetCoreObject()
local insideTheater = false

local function setupTheaterTargets()
    for idx, theater in ipairs(Config.MovieTheater.locations) do
        local model = GetHashKey('prop_cinema_boundary')
        RequestModel(model)
        local attempts = 0
        while not HasModelLoaded(model) and attempts < 50 do
            Wait(10)
            attempts = attempts + 1
        end

        local obj = GetClosestObjectOfType(theater.entrance.x, theater.entrance.y, theater.entrance.z, 2.0, model, false, false, false)
        if obj == 0 then
            obj = CreateObject(model, theater.entrance.x, theater.entrance.y, theater.entrance.z - 1.0, false, false, false)
            FreezeEntityPosition(obj, true)
            SetEntityAsMissionEntity(obj, true, true)
        end

        if DoesEntityExist(obj) then
            exports.ox_target:addLocalEntity(obj, {
                {
                    name = 'movie_theater_interact_' .. idx,
                    label = Locale('movie_theater.buy_ticket'),
                    icon = 'fa-solid fa-film',
                    onSelect = function()
                        local movieOptions = {}
                        for _, movie in ipairs(Config.MovieTheater.movies) do
                            table.insert(movieOptions, {
                                title = movie.name,
                                description = Locale('movie_theater.ticket_price', theater.ticketPrice) .. ' | ' .. movie.genre .. ' | ' .. movie.duration .. 'm',
                                onSelect = function()
                                    Wrappers.ContextMenu({
                                        id = 'movie_theater_confirm_' .. movie.id,
                                        title = Locale('movie_theater.select_movie'),
                                        options = {
                                            {
                                                title = Locale('movie_theater.buy_ticket'),
                                                description = movie.name .. ' - ' .. Locale('movie_theater.ticket_price', theater.ticketPrice),
                                                onSelect = function()
                                                    TriggerServerEvent('movie:buyTicket', idx, movie.id)
                                                end,
                                            },
                                            {
                                                title = Locale('movie_theater.enter'),
                                                description = '',
                                                onSelect = function()
                                                    TriggerServerEvent('movie:enterTheater', idx, movie.id)
                                                end,
                                            },
                                        },
                                    })
                                end,
                            })
                        end

                        Wrappers.ContextMenu({
                            id = 'movie_theater_movies_' .. idx,
                            title = theater.label,
                            options = movieOptions,
                        })
                    end,
                },
                {
                    name = 'movie_theater_snacks_' .. idx,
                    label = Locale('movie_theater.buy_snack'),
                    icon = 'fa-solid fa-candy-cane',
                    onSelect = function()
                        local snackOptions = {}
                        for _, snack in ipairs(Config.MovieTheater.snacks) do
                            table.insert(snackOptions, {
                                title = snack.label .. ' - $' .. snack.price,
                                description = '',
                                onSelect = function()
                                    TriggerServerEvent('movie:buySnack', idx, snack.name)
                                end,
                            })
                        end
                        Wrappers.ContextMenu({
                            id = 'movie_theater_snacks_menu_' .. idx,
                            title = Locale('movie_theater.buy_snack'),
                            options = snackOptions,
                        })
                    end,
                },
                {
                    name = 'movie_theater_exit_' .. idx,
                    label = Locale('movie_theater.exit'),
                    icon = 'fa-solid fa-door-open',
                    onSelect = function()
                        TriggerServerEvent('movie:leaveTheater')
                    end,
                },
            })
        end
    end
end

RegisterNetEvent('movie:ticketPurchased', function(theaterIndex, movieId, seatNumber)
    Wrappers.Notify(Locale('movie_theater.buy_ticket'), 'success')
end)

RegisterNetEvent('movie:enterInterior', function(theater, movie, seatNumber)
    insideTheater = true
    DoScreenFadeOut(500)
    Wait(1000)

    local ped = PlayerPedId()
    SetEntityCoords(ped, theater.interior.x, theater.interior.y, theater.interior.z - 1.0, false, false, false, false)
    SetEntityHeading(ped, 0.0)
    Wait(500)

    DoScreenFadeIn(500)
    Wait(500)

    local sitCoords = theater.seatCoords
    SetEntityCoords(ped, sitCoords.x, sitCoords.y, sitCoords.z - 0.5, false, false, false, false)
    SetEntityHeading(ped, 180.0)

    TaskStartScenarioInPlace(ped, 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER', 0, true)
    Wrappers.Notify(Locale('movie_theater.enjoy', movie.name), 'success')
end)

RegisterNetEvent('movie:exitInterior', function()
    insideTheater = false
    DoScreenFadeOut(500)
    Wait(1000)

    ClearPedTasks(PlayerPedId())

    local ped = PlayerPedId()
    for _, theater in ipairs(Config.MovieTheater.locations) do
        local dist = #(GetEntityCoords(ped) - theater.interior)
        if dist < 50.0 then
            SetEntityCoords(ped, theater.entrance.x, theater.entrance.y, theater.entrance.z, false, false, false, false)
            break
        end
    end

    DoScreenFadeIn(500)
    Wrappers.Notify(Locale('movie_theater.exit'), 'info')
end)

CreateThread(function()
    setupTheaterTargets()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if insideTheater then
            ClearPedTasks(PlayerPedId())
            DoScreenFadeIn(100)
        end
    end
end)
