local QBCore = exports['qbx-core']:GetCoreObject()
local currentSessionId = nil
local currentGameType = nil

local function setupDartTargets()
    for idx, loc in ipairs(Config.MiniGames.darts.locations) do
        local model = GetHashKey('prop_dart_1')
        RequestModel(model)
        local attempts = 0
        while not HasModelLoaded(model) and attempts < 50 do
            Wait(10)
            attempts = attempts + 1
        end

        local obj = GetClosestObjectOfType(loc.x, loc.y, loc.z, 2.0, model, false, false, false)
        if obj == 0 and Config.MiniGames.darts.boardCoords[idx] then
            local bc = Config.MiniGames.darts.boardCoords[idx]
            obj = GetClosestObjectOfType(bc.x, bc.y, bc.z, 2.0, model, false, false, false)
        end
        if obj == 0 then
            obj = CreateObject(model, loc.x, loc.y, loc.z, false, false, false)
            FreezeEntityPosition(obj, true)
            SetEntityAsMissionEntity(obj, true, true)
        end

        if DoesEntityExist(obj) then
            exports.ox_target:addLocalEntity(obj, {
                {
                    name = 'darts_start_' .. idx,
                    label = Locale('mini_games.start_game') .. ' - Darts',
                    icon = 'fa-solid fa-bullseye',
                    onSelect = function()
                        TriggerServerEvent('mini_games:startGame', 'darts', idx)
                    end,
                },
                {
                    name = 'darts_throw_' .. idx,
                    label = Locale('mini_games.dart_throw'),
                    icon = 'fa-solid fa-hand-fist',
                    onSelect = function()
                        if currentGameType ~= 'darts' then
                            Wrappers.Notify(Locale('mini_games.no_active_game'), 'error')
                            return
                        end
                        Wrappers.SkillCheck({ { area = 50, label = 'Power' }, { area = 30, label = 'Accuracy' } }, function(success)
                            if success then
                                local baseScore = math.random(1, 20)
                                local multiplier = math.random(1, 3)
                                local score = baseScore * multiplier
                                if math.random() < 0.1 then
                                    score = 50
                                elseif math.random() < 0.05 then
                                    score = 25
                                end
                                TriggerServerEvent('mini_games:makeMove', currentSessionId, { score = score })
                            else
                                TriggerServerEvent('mini_games:makeMove', currentSessionId, { score = 0 })
                            end
                        end)
                    end,
                },
            })
        end
    end
end

local function setupPoolTargets()
    for idx, loc in ipairs(Config.MiniGames.pool.locations) do
        local model = GetHashKey('prop_pool_table_01')
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
                    name = 'pool_start_' .. idx,
                    label = Locale('mini_games.start_game') .. ' - Pool',
                    icon = 'fa-solid fa-table',
                    onSelect = function()
                        TriggerServerEvent('mini_games:startGame', 'pool', idx)
                    end,
                },
                {
                    name = 'pool_shoot_' .. idx,
                    label = Locale('mini_games.dart_throw'),
                    icon = 'fa-solid fa-circle',
                    onSelect = function()
                        if currentGameType ~= 'pool' then
                            Wrappers.Notify(Locale('mini_games.no_active_game'), 'error')
                            return
                        end
                        Wrappers.InputDialog({
                            title = 'Aim Angle',
                            label = 'Angle (1-100)',
                            placeholder = '50',
                            type = 'number',
                        }, function(angle)
                            if not angle then return end
                            angle = tonumber(angle)
                            if not angle or angle < 1 or angle > 100 then
                                Wrappers.Notify(Locale('mini_games.invalid_input'), 'error')
                                return
                            end
                            Wrappers.InputDialog({
                                title = 'Shot Power',
                                label = 'Power (1-100)',
                                placeholder = '50',
                                type = 'number',
                            }, function(power)
                                if not power then return end
                                power = tonumber(power)
                                if not power or power < 1 or power > 100 then
                                    Wrappers.Notify(Locale('mini_games.invalid_input'), 'error')
                                    return
                                end
                                local targetBall = math.random(1, 15)
                                local foul = math.random() < 0.1
                                TriggerServerEvent('mini_games:makeMove', currentSessionId, {
                                    angle = angle,
                                    power = power,
                                    ball = targetBall,
                                    foul = foul,
                                })
                                if foul then
                                    Wrappers.Notify(Locale('mini_games.foul'), 'error')
                                else
                                    Wrappers.Notify(Locale('mini_games.ball_potted', targetBall), 'success')
                                end
                            end)
                        end)
                    end,
                },
            })
        end
    end
end

local function setupChessTargets()
    for idx, loc in ipairs(Config.MiniGames.chess.locations) do
        local model = GetHashKey('prop_chess_set_01')
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
                    name = 'chess_start_' .. idx,
                    label = Locale('mini_games.start_game') .. ' - Chess',
                    icon = 'fa-solid fa-chess',
                    onSelect = function()
                        TriggerServerEvent('mini_games:startGame', 'chess', idx)
                    end,
                },
                {
                    name = 'chess_move_' .. idx,
                    label = 'Make Move',
                    icon = 'fa-solid fa-arrow-right',
                    onSelect = function()
                        if currentGameType ~= 'chess' then
                            Wrappers.Notify(Locale('mini_games.no_active_game'), 'error')
                            return
                        end
                        Wrappers.InputDialog({
                            title = 'Select Piece',
                            label = 'From X (1-8)',
                            placeholder = '1',
                            type = 'number',
                        }, function(fromX)
                            if not fromX then return end
                            fromX = tonumber(fromX)
                            if not fromX or fromX < 1 or fromX > 8 then
                                Wrappers.Notify(Locale('mini_games.invalid_input'), 'error')
                                return
                            end
                            Wrappers.InputDialog({
                                title = 'Select Piece',
                                label = 'From Y (1-8)',
                                placeholder = '1',
                                type = 'number',
                            }, function(fromY)
                                if not fromY then return end
                                fromY = tonumber(fromY)
                                if not fromY or fromY < 1 or fromY > 8 then
                                    Wrappers.Notify(Locale('mini_games.invalid_input'), 'error')
                                    return
                                end
                                Wrappers.InputDialog({
                                    title = 'Move To',
                                    label = 'To X (1-8)',
                                    placeholder = '1',
                                    type = 'number',
                                }, function(toX)
                                    if not toX then return end
                                    toX = tonumber(toX)
                                    if not toX or toX < 1 or toX > 8 then
                                        Wrappers.Notify(Locale('mini_games.invalid_input'), 'error')
                                        return
                                    end
                                    Wrappers.InputDialog({
                                        title = 'Move To',
                                        label = 'To Y (1-8)',
                                        placeholder = '1',
                                        type = 'number',
                                    }, function(toY)
                                        if not toY then return end
                                        toY = tonumber(toY)
                                        if not toY or toY < 1 or toY > 8 then
                                            Wrappers.Notify(Locale('mini_games.invalid_input'), 'error')
                                            return
                                        end
                                        TriggerServerEvent('mini_games:makeMove', currentSessionId, {
                                            fromX = fromX, fromY = fromY, toX = toX, toY = toY,
                                        })
                                    end)
                                end)
                            end)
                        end)
                    end,
                },
            })
        end
    end
end

RegisterNetEvent('mini_games:gameStarted', function(sessionId, gameType)
    currentSessionId = sessionId
    currentGameType = gameType
    Wrappers.Notify(Locale('mini_games.start_game', gameType), 'success')
end)

RegisterNetEvent('mini_games:playerJoined', function(sessionId)
    Wrappers.Notify(Locale('mini_games.player_joined'), 'success')
end)

RegisterNetEvent('mini_games:gameUpdate', function(session)
    if session.type == 'darts' then
        local scoreText = ''
        for src, score in pairs(session.scores) do
            scoreText = scoreText .. 'P' .. src .. ': ' .. score .. ' '
        end
        Wrappers.TextUI(Locale('mini_games.score') .. ': ' .. scoreText .. ' | ' .. Locale('mini_games.your_turn'))
        Wait(3000)
        Wrappers.HideTextUI()
    elseif session.type == 'pool' then
        local potted = #session.balls.potted
        Wrappers.Notify(Locale('mini_games.ball_potted', potted) .. ' | Fouls: ' .. #session.fouls, 'info')
    elseif session.type == 'chess' then
        Wrappers.Notify(Locale('mini_games.your_turn'), 'info')
    end
end)

RegisterNetEvent('mini_games:gameOver', function(sessionId, winner)
    if winner == GetPlayerServerId(PlayerId()) then
        Wrappers.Notify(Locale('mini_games.won'), 'success')
    else
        Wrappers.Notify(Locale('mini_games.lost'), 'error')
    end
    Wrappers.Notify(Locale('mini_games.game_over'), 'info')
    currentSessionId = nil
    currentGameType = nil
end)

CreateThread(function()
    setupDartTargets()
    setupPoolTargets()
    setupChessTargets()
end)
