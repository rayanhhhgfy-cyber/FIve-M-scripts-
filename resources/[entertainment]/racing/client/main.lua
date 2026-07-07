local QBCore = exports['qbx-core']:GetCoreObject()
local currentRace = nil
local checkpointBlips = {}
local inCountdown = false

local function clearCheckpointBlips()
    for _, blip in ipairs(checkpointBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    checkpointBlips = {}
end

local function createCheckpointBlips(track)
    clearCheckpointBlips()
    for i, cp in ipairs(track.checkpoints) do
        local blip = AddBlipForCoord(cp.x, cp.y, cp.z)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, 3)
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Locale('racing.checkpoint') .. ' ' .. i)
        EndTextCommandSetBlipName(blip)
        table.insert(checkpointBlips, blip)
    end
    if #track.checkpoints > 0 then
        SetNewWaypoint(track.checkpoints[1].x, track.checkpoints[1].y)
    end
end

local function setupRaceTargets()
    for idx, loc in ipairs(Config.Racing.meetLocations) do
        local model = GetHashKey('prop_race_meet_flag')
        RequestModel(model)
        local attempts = 0
        while not HasModelLoaded(model) and attempts < 50 do
            Wait(10)
            attempts = attempts + 1
        end

        local obj = GetClosestObjectOfType(loc.x, loc.y, loc.z, 2.0, model, false, false, false)
        if obj == 0 then
            obj = CreateObject(model, loc.x, loc.y, loc.z, false, false, false)
            FreezeEntityPosition(obj, true)
            SetEntityAsMissionEntity(obj, true, true)
        end

        if DoesEntityExist(obj) then
            exports.ox_target:addLocalEntity(obj, {
                {
                    name = 'racing_create_' .. idx,
                    label = Locale('racing.create_race'),
                    icon = 'fa-solid fa-flag-checkered',
                    onSelect = function()
                        local trackOptions = {}
                        for ti, track in ipairs(Config.Racing.tracks) do
                            local startCp = track.checkpoints[1]
                            local dist = #(GetEntityCoords(PlayerPedId()) - startCp)
                            if dist < 100.0 then
                                table.insert(trackOptions, {
                                    title = track.name,
                                    description = Locale('racing.bet') .. ': $' .. track.minBet .. ' - $' .. track.maxBet .. ' | Laps: ' .. track.laps,
                                    onSelect = function()
                                        TriggerServerEvent('racing:createRace', ti)
                                    end,
                                })
                            end
                        end
                        if #trackOptions == 0 then
                            table.insert(trackOptions, {
                                title = Locale('racing.no_tracks_nearby'),
                                description = '',
                                onSelect = function() end,
                            })
                        end
                        Wrappers.ContextMenu({
                            id = 'racing_create_menu_' .. idx,
                            title = Locale('racing.create_race'),
                            options = trackOptions,
                        })
                    end,
                },
                {
                    name = 'racing_join_' .. idx,
                    label = Locale('racing.join_race'),
                    icon = 'fa-solid fa-users',
                    onSelect = function()
                        Wrappers.InputDialog({
                            title = Locale('racing.bet'),
                            label = Locale('racing.bet'),
                            placeholder = 'Enter bet amount...',
                            type = 'number',
                        }, function(betAmount)
                            if not betAmount then return end
                            local bet = tonumber(betAmount)
                            if not bet or bet < 0 then
                                Wrappers.Notify(Locale('racing.invalid_bet'), 'error')
                                return
                            end
                            TriggerServerEvent('racing:createRace', bet)
                        end)
                    end,
                },
            })
        end
    end
end

RegisterNetEvent('racing:raceCreated', function(raceId, track)
    currentRace = { id = raceId, track = track }
    Wrappers.Notify(Locale('racing.create_race'), 'success')
    createCheckpointBlips(track)
end)

RegisterNetEvent('racing:joinedRace', function(raceId)
    Wrappers.Notify(Locale('racing.join_race'), 'success')
end)

RegisterNetEvent('racing:countdown', function(countdownTime, race)
    inCountdown = true
    createCheckpointBlips(race.track)
    currentRace = { id = race.id, track = race.track }

    for i = countdownTime, 1, -1 do
        Wrappers.TextUI(Locale('racing.countdown') .. ': ' .. i)
        Wait(1000)
    end
    Wrappers.HideTextUI()
    inCountdown = false
end)

RegisterNetEvent('racing:raceStarted', function(race)
    currentRace = { id = race.id, track = race.track }
    Wrappers.Notify(Locale('racing.start_race'), 'success')

    local track = race.track
    local checkpointIndex = 1

    CreateThread(function()
        while currentRace do
            Wait(500)
            if currentRace and checkpointIndex <= #track.checkpoints then
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local cp = track.checkpoints[checkpointIndex]
                local dist = #(pedCoords - cp)
                if dist < 15.0 then
                    TriggerServerEvent('racing:checkpointPassed', currentRace.id, checkpointIndex)
                    checkpointIndex = checkpointIndex + 1
                    if checkpointIndex <= #track.checkpoints then
                        local nextCp = track.checkpoints[checkpointIndex]
                        SetNewWaypoint(nextCp.x, nextCp.y)
                    end
                end
                if checkpointIndex > #track.checkpoints then
                    TriggerServerEvent('racing:finishRace', currentRace.id)
                    break
                end
            end
            if not currentRace then break end
        end
    end)
end)

RegisterNetEvent('racing:raceFinished', function(result, payout)
    if result == 'won' then
        Wrappers.Notify(Locale('racing.won', payout), 'success')
    else
        Wrappers.Notify(Locale('racing.lost'), 'error')
    end
    clearCheckpointBlips()
    currentRace = nil
end)

RegisterNetEvent('racing:raceCancelled', function()
    clearCheckpointBlips()
    currentRace = nil
    Wrappers.Notify(Locale('racing.race_cancelled'), 'error')
end)

CreateThread(function()
    setupRaceTargets()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        clearCheckpointBlips()
    end
end)
