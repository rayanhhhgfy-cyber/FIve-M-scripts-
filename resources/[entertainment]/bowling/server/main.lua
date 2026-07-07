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

local ActiveSessions = {}

local function generatePinLayout()
    local layout = {}
    for i = 1, Config.Bowling.pinsPerFrame do
        layout[i] = math.random(2) == 1
    end
    return layout
end

local function calculateThrowScore(aimAngle, power, pins)
    local baseScore = 0
    local standing = 0
    for _, standing_pin in ipairs(pins) do
        if standing_pin then
            standing = standing + 1
        end
    end
    if standing == 0 then
        return 10, pins, true
    end

    local accuracy = 1.0 - (math.abs(aimAngle - 0.5) * 2.0)
    local powerFactor = power
    local hitChance = (accuracy * 0.7 + powerFactor * 0.3)

    for i = 1, #pins do
        if pins[i] then
            local pinHit = math.random() < hitChance
            if pinHit then
                pins[i] = false
                baseScore = baseScore + 1
            end
        end
    end

    local remaining = 0
    for _, standing_pin in ipairs(pins) do
        if standing_pin then
            remaining = remaining + 1
        end
    end

    return baseScore, pins, remaining == 0
end

RegisterNetEvent('bowling:startGame', function()
    local src = source
    if not checkRateLimit(src, 'startGame', 2) then
        return Wrappers.Notify(src, Locale('bowling.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local cash = Player.Functions.GetMoney('cash')
    if cash < Config.Bowling.costPerGame then
        return Wrappers.Notify(src, Locale('bowling.no_money'), 'error')
    end

    Player.Functions.RemoveMoney('cash', Config.Bowling.costPerGame)

    local session = {
        src = src,
        frames = {},
        currentFrame = 1,
        currentThrow = 1,
        pins = generatePinLayout(),
        totalScore = 0,
        frameScores = {},
        active = true,
    }

    for i = 1, Config.Bowling.frames do
        session.frameScores[i] = { throw1 = 0, throw2 = 0, total = 0 }
    end

    ActiveSessions[src] = session
    TriggerClientEvent('bowling:gameStarted', src, session.pins)
    Wrappers.Notify(src, Locale('bowling.start_game'), 'success')
end)

RegisterNetEvent('bowling:throwBall', function(aimAngle, power)
    local src = source
    if not checkRateLimit(src, 'throwBall', 2) then
        return Wrappers.Notify(src, Locale('bowling.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local session = ActiveSessions[src]
    if not session or not session.active then
        return Wrappers.Notify(src, Locale('bowling.no_game'), 'error')
    end

    aimAngle = tonumber(aimAngle) or 0.5
    power = tonumber(power) or 0.5
    aimAngle = math.max(0, math.min(1, aimAngle))
    power = math.max(0, math.min(1, power))

    local score, newPins, allDown = calculateThrowScore(aimAngle, power, session.pins)
    session.pins = newPins

    local frame = session.frameScores[session.currentFrame]
    if session.currentThrow == 1 then
        frame.throw1 = score
        if allDown then
            frame.total = 10
            Wrappers.Notify(src, Locale('bowling.strike'), 'success')
            if session.currentFrame < Config.Bowling.frames then
                session.currentFrame = session.currentFrame + 1
                session.currentThrow = 1
                session.pins = generatePinLayout()
            else
                session.active = false
                TriggerClientEvent('bowling:gameOver', src, session)
            end
        else
            session.currentThrow = 2
        end
    elseif session.currentThrow == 2 then
        frame.throw2 = score
        local frameTotal = frame.throw1 + frame.throw2
        frame.total = frameTotal
        if frameTotal == 10 and frame.throw1 > 0 and frame.throw2 > 0 then
            Wrappers.Notify(src, Locale('bowling.spare'), 'success')
        else
            Wrappers.Notify(src, Locale('bowling.open_frame', frameTotal), 'info')
        end
        if session.currentFrame < Config.Bowling.frames then
            session.currentFrame = session.currentFrame + 1
            session.currentThrow = 1
            session.pins = generatePinLayout()
        else
            session.active = false
            TriggerClientEvent('bowling:gameOver', src, session)
        end
    end

    local totalScore = 0
    for i = 1, Config.Bowling.frames do
        totalScore = totalScore + session.frameScores[i].total
    end
    session.totalScore = totalScore

    TriggerClientEvent('bowling:throwResult', src, score, session.pins, session.frameScores, session.currentFrame, session.currentThrow, totalScore)
end)

RegisterNetEvent('bowling:endGame', function()
    local src = source
    local session = ActiveSessions[src]
    if not session then return end

    session.active = false
    local totalScore = 0
    for i = 1, Config.Bowling.frames do
        totalScore = totalScore + session.frameScores[i].total
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local result = MySQL.Sync.fetchAll('SELECT * FROM bowling_highscores WHERE citizenid = ?', { Player.PlayerData.citizenid })
        if #result > 0 then
            if totalScore > result[1].score then
                MySQL.Async.execute('UPDATE bowling_highscores SET score = ? WHERE citizenid = ?', { totalScore, Player.PlayerData.citizenid })
                Wrappers.Notify(src, Locale('bowling.new_highscore', totalScore), 'success')
            end
        else
            MySQL.Async.execute('INSERT INTO bowling_highscores (citizenid, name, score) VALUES (?, ?, ?)', {
                Player.PlayerData.citizenid,
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                totalScore,
            })
        end
    end

    ActiveSessions[src] = nil
    TriggerClientEvent('bowling:gameFinalized', src, totalScore)
    Wrappers.Notify(src, Locale('bowling.game_over', totalScore), 'info')
end)

AddEventHandler('playerDropped', function()
    local src = source
    ActiveSessions[src] = nil
    RATE_LIMITS[src .. ':startGame'] = nil
    RATE_LIMITS[src .. ':throwBall'] = nil
    RATE_LIMITS[src .. ':endGame'] = nil
end)

CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS bowling_highscores (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(64) NOT NULL UNIQUE,
            name VARCHAR(64) NOT NULL,
            score INT NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end)
