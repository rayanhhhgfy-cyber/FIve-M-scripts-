local QBCore = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    if not RATE_LIMITS[key] then
        RATE_LIMITS[key] = { count = 1, resetAt = now + 60 }
        return true
    end
    if now > RATE_LIMITS[key].resetAt then
        RATE_LIMITS[key] = { count = 1, resetAt = now + 60 }
        return true
    end
    RATE_LIMITS[key].count = RATE_LIMITS[key].count + 1
    if RATE_LIMITS[key].count > maxPerMin then
        return false
    end
    return true
end

local GameSessions = {}
local SessionCounter = 0

local function isValidDartScore(score)
    if score < 0 or score > 180 then return false end
    local validTriples = { 20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5 }
    local validDoubles = { 40, 2, 36, 8, 26, 12, 20, 30, 4, 34, 6, 38, 14, 32, 16, 22, 28, 18, 24, 10 }
    local validSingles = { 20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5 }
    for _, v in ipairs(validSingles) do if score == v then return true end end
    for _, v in ipairs(validDoubles) do if score == v then return true end end
    for _, v in ipairs(validTriples) do if score == v then return true end end
    if score == 25 or score == 50 then return true end
    return false
end

local ChessInitialState = {
    board = {
        {'br','bn','bb','bq','bk','bb','bn','br'},
        {'bp','bp','bp','bp','bp','bp','bp','bp'},
        {nil,nil,nil,nil,nil,nil,nil,nil},
        {nil,nil,nil,nil,nil,nil,nil,nil},
        {nil,nil,nil,nil,nil,nil,nil,nil},
        {nil,nil,nil,nil,nil,nil,nil,nil},
        {'wp','wp','wp','wp','wp','wp','wp','wp'},
        {'wr','wn','wb','wq','wk','wb','wn','wr'},
    },
    turn = 'white',
    moves = {},
    winner = nil,
}

local function isValidChessMove(board, fromX, fromY, toX, toY, turn)
    if fromX < 1 or fromX > 8 or fromY < 1 or fromY > 8 then return false end
    if toX < 1 or toX > 8 or toY < 1 or toY > 8 then return false end
    local piece = board[fromY][fromX]
    if not piece then return false end
    local color = string.sub(piece, 1, 1)
    if color ~= string.sub(turn, 1, 1) then return false end
    local target = board[toY][toX]
    if target and string.sub(target, 1, 1) == color then return false end
    return true
end

local function processDartMove(session, score)
    local playerScore = session.scores[session.currentPlayer]
    if not playerScore then playerScore = Config.MiniGames.darts.startingScore end
    if score > playerScore then return false end
    local remaining = playerScore - score
    if remaining == 0 then
        if Config.MiniGames.darts.doublesRequired then
            local isDouble = false
            local validDoubles = { 40, 2, 36, 8, 26, 12, 20, 30, 4, 34, 6, 38, 14, 32, 16, 22, 28, 18, 24, 10, 50 }
            for _, v in ipairs(validDoubles) do if score == v then isDouble = true break end end
            if not isDouble then return false end
        end
        session.scores[session.currentPlayer] = 0
        session.winner = session.currentPlayer
        return true
    end
    if remaining == 1 then return false end
    session.scores[session.currentPlayer] = remaining
    return true
end

RegisterNetEvent('mini_games:startGame', function(gameType, locationIndex)
    local src = source
    if not checkRateLimit(src, 'startGame', 3) then
        return Wrappers.Notify(src, Locale('mini_games.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local validTypes = { darts = true, pool = true, chess = true }
    if not validTypes[gameType] then return end

    for _, session in pairs(GameSessions) do
        for _, p in ipairs(session.players) do
            if p == src then
                return Wrappers.Notify(src, Locale('mini_games.already_playing'), 'error')
            end
        end
    end

    SessionCounter = SessionCounter + 1
    local sessionId = 'mg_' .. SessionCounter

    if gameType == 'darts' then
        GameSessions[sessionId] = {
            id = sessionId,
            type = 'darts',
            players = { src },
            scores = { [src] = Config.MiniGames.darts.startingScore },
            currentPlayer = src,
            turn = 1,
            winner = nil,
            locationIndex = locationIndex,
            dartsThrown = 0,
        }
    elseif gameType == 'pool' then
        GameSessions[sessionId] = {
            id = sessionId,
            type = 'pool',
            players = { src },
            scores = {},
            currentPlayer = src,
            turn = 1,
            winner = nil,
            locationIndex = locationIndex,
            balls = {
                solids = { 1, 2, 3, 4, 5, 6, 7 },
                stripes = { 9, 10, 11, 12, 13, 14, 15 },
                eightBall = 8,
                potted = {},
                assigned = {},
            },
            fouls = {},
            currentTurnBalls = {},
        }
    elseif gameType == 'chess' then
        local chessState = {}
        for y = 1, 8 do
            chessState[y] = {}
            for x = 1, 8 do
                chessState[y][x] = ChessInitialState.board[y][x]
            end
        end
        GameSessions[sessionId] = {
            id = sessionId,
            type = 'chess',
            players = { src },
            scores = {},
            currentPlayer = src,
            turn = 1,
            winner = nil,
            locationIndex = locationIndex,
            chess = {
                board = chessState,
                turn = 'white',
                moves = {},
                winner = nil,
            },
        }
    end

    TriggerClientEvent('mini_games:gameStarted', src, sessionId, gameType)
    Wrappers.Notify(src, Locale('mini_games.start_game', gameType), 'success')
end)

RegisterNetEvent('mini_games:joinGame', function(sessionId)
    local src = source
    if not checkRateLimit(src, 'joinGame', 3) then
        return Wrappers.Notify(src, Locale('mini_games.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local session = GameSessions[sessionId]
    if not session then
        return Wrappers.Notify(src, Locale('mini_games.game_not_found'), 'error')
    end
    if #session.players >= 2 then
        return Wrappers.Notify(src, Locale('mini_games.game_full'), 'error')
    end

    table.insert(session.players, src)
    if session.type == 'darts' then
        session.scores[src] = Config.MiniGames.darts.startingScore
    end

    TriggerClientEvent('mini_games:playerJoined', src, sessionId)
    for _, p in ipairs(session.players) do
        TriggerClientEvent('mini_games:gameUpdate', p, session)
    end
end)

RegisterNetEvent('mini_games:makeMove', function(sessionId, moveData)
    local src = source
    if not checkRateLimit(src, 'makeMove', 3) then
        return Wrappers.Notify(src, Locale('mini_games.too_fast'), 'error')
    end

    local session = GameSessions[sessionId]
    if not session or session.winner then return end
    if session.currentPlayer ~= src then
        return Wrappers.Notify(src, Locale('mini_games.your_turn'), 'error')
    end

    if session.type == 'darts' then
        local score = tonumber(moveData.score)
        if not score or not isValidDartScore(score) then return end
        session.dartsThrown = session.dartsThrown + 1
        if processDartMove(session, score) then
            if session.winner then
                for _, p in ipairs(session.players) do
                    Wrappers.Notify(p, Locale('mini_games.won', p == src and 'you' or 'opponent'), 'success')
                    TriggerClientEvent('mini_games:gameOver', p, sessionId, session.winner)
                end
                GameSessions[sessionId] = nil
                return
            end
        end
        if session.dartsThrown >= 3 then
            session.dartsThrown = 0
            for i, p in ipairs(session.players) do
                if p ~= src then
                    session.currentPlayer = p
                    break
                end
            end
        end
    elseif session.type == 'pool' then
        local ballNumber = tonumber(moveData.ball)
        local isFoul = moveData.foul or false
        if not ballNumber then return end

        if ballNumber == 8 then
            local allSolids = true
            local allStripes = true
            for _, b in ipairs(session.balls.solids) do
                local potted = false
                for _, p in ipairs(session.balls.potted) do if p == b then potted = true break end end
                if not potted then allSolids = false break end
            end
            for _, b in ipairs(session.balls.stripes) do
                local potted = false
                for _, p in ipairs(session.balls.potted) do if p == b then potted = true break end end
                if not potted then allStripes = false break end
            end

            if session.balls.assigned[src] == 'solids' and not allSolids then
                isFoul = true
            elseif session.balls.assigned[src] == 'stripes' and not allStripes then
                isFoul = true
            end

            if not isFoul then
                session.winner = src
                for _, p in ipairs(session.players) do
                    TriggerClientEvent('mini_games:gameOver', p, sessionId, session.winner)
                end
                GameSessions[sessionId] = nil
                return
            end
        end

        table.insert(session.balls.potted, ballNumber)
        if not session.balls.assigned[src] then
            if ballNumber <= 7 then
                session.balls.assigned[src] = 'solids'
                for _, p in ipairs(session.players) do
                    if p ~= src then
                        session.balls.assigned[p] = 'stripes'
                    end
                end
            elseif ballNumber >= 9 then
                session.balls.assigned[src] = 'stripes'
                for _, p in ipairs(session.players) do
                    if p ~= src then
                        session.balls.assigned[p] = 'solids'
                    end
                end
            end
        end

        if isFoul then
            table.insert(session.fouls, src)
            for i, p in ipairs(session.players) do
                if p ~= src then
                    session.currentPlayer = p
                    break
                end
            end
        end
    elseif session.type == 'chess' then
        local fromX = tonumber(moveData.fromX)
        local fromY = tonumber(moveData.fromY)
        local toX = tonumber(moveData.toX)
        local toY = tonumber(moveData.toY)
        if not fromX or not fromY or not toX or not toY then return end

        if not isValidChessMove(session.chess.board, fromX, fromY, toX, toY, session.chess.turn) then
            return Wrappers.Notify(src, Locale('mini_games.invalid_move'), 'error')
        end

        session.chess.board[toY][toX] = session.chess.board[fromY][fromX]
        session.chess.board[fromY][fromX] = nil
        table.insert(session.chess.moves, { from = { fromX, fromY }, to = { toX, toY }, piece = session.chess.board[toY][toX] })
        session.chess.turn = session.chess.turn == 'white' and 'black' or 'white'

        local kingFound = false
        local kingColor = session.chess.turn == 'white' and 'wk' or 'bk'
        for y = 1, 8 do
            for x = 1, 8 do
                if session.chess.board[y][x] == kingColor then
                    kingFound = true
                    break
                end
            end
            if kingFound then break end
        end
        if not kingFound then
            session.winner = src
            for _, p in ipairs(session.players) do
                TriggerClientEvent('mini_games:gameOver', p, sessionId, session.winner)
            end
            GameSessions[sessionId] = nil
            return
        end

        for i, p in ipairs(session.players) do
            if p ~= src then
                session.currentPlayer = p
                break
            end
        end
    end

    for _, p in ipairs(session.players) do
        TriggerClientEvent('mini_games:gameUpdate', p, session)
    end
end)

RegisterNetEvent('mini_games:endGame', function(sessionId)
    local src = source
    local session = GameSessions[sessionId]
    if not session then return end

    session.winner = src
    for _, p in ipairs(session.players) do
        local pl = QBCore.Functions.GetPlayer(p)
        if pl then
            Wrappers.Notify(p, Locale('mini_games.game_over'), 'info')
            TriggerClientEvent('mini_games:gameOver', p, sessionId, src)
        end
    end
    GameSessions[sessionId] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    for sessionId, session in pairs(GameSessions) do
        for i = #session.players, 1, -1 do
            if session.players[i] == src then
                table.remove(session.players, i)
                break
            end
        end
        if #session.players == 0 then
            GameSessions[sessionId] = nil
        elseif #session.players == 1 then
            local winner = session.players[1]
            local pl = QBCore.Functions.GetPlayer(winner)
            if pl then
                Wrappers.Notify(winner, Locale('mini_games.opponent_left'), 'info')
                TriggerClientEvent('mini_games:gameOver', winner, sessionId, winner)
            end
            GameSessions[sessionId] = nil
        end
    end
end)
