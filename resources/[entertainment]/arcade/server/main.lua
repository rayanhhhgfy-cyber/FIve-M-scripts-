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

local HighScores = {}

local function loadHighScores()
    local result = MySQL.Sync.fetchAll('SELECT * FROM arcade_highscores ORDER BY score DESC LIMIT ?', { Config.Arcade.highScoreLimit })
    for _, row in ipairs(result) do
        if not HighScores[row.game] then
            HighScores[row.game] = {}
        end
        table.insert(HighScores[row.game], {
            citizenid = row.citizenid,
            score = row.score,
            name = row.name,
        })
    end
end

local function saveHighScore(game, citizenid, name, score)
    MySQL.Async.insert('INSERT INTO arcade_highscores (game, citizenid, name, score) VALUES (?, ?, ?, ?)', {
        game, citizenid, name, score,
    })
end

local function ensureHighScoreTable()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS arcade_highscores (
            id INT AUTO_INCREMENT PRIMARY KEY,
            game VARCHAR(32) NOT NULL,
            citizenid VARCHAR(64) NOT NULL,
            name VARCHAR(64) NOT NULL,
            score INT NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end

CreateThread(function()
    ensureHighScoreTable()
    loadHighScores()
end)

RegisterNetEvent('arcade:play', function(gameType)
    local src = source
    if not checkRateLimit(src, 'play', 2) then
        return Wrappers.Notify(src, Locale('arcade.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local validGames = { snake = true, tetris = true, pong = true }
    if not validGames[gameType] then
        return Wrappers.Notify(src, Locale('arcade.invalid_game'), 'error')
    end

    local cost = Config.Arcade.costPerPlay
    local cash = Player.Functions.GetMoney('cash')
    if cash < cost then
        return Wrappers.Notify(src, Locale('arcade.no_money'), 'error')
    end

    Player.Functions.RemoveMoney('cash', cost)
    TriggerClientEvent('arcade:openGame', src, gameType)
    Wrappers.Notify(src, Locale('arcade.play_game', gameType), 'success')
end)

RegisterNetEvent('arcade:submitScore', function(gameType, score)
    local src = source
    if not checkRateLimit(src, 'submitScore', 2) then
        return Wrappers.Notify(src, Locale('arcade.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local validGames = { snake = true, tetris = true, pong = true }
    if not validGames[gameType] then
        return
    end

    score = tonumber(score)
    if not score or score < 0 or score > 999999 then
        return
    end

    local citizenid = Player.PlayerData.citizenid
    local name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname

    if not HighScores[gameType] then
        HighScores[gameType] = {}
    end

    local isHighScore = false
    if #HighScores[gameType] < Config.Arcade.highScoreLimit then
        isHighScore = true
    else
        local lowest = HighScores[gameType][#HighScores[gameType]].score
        if score > lowest then
            isHighScore = true
        end
    end

    if isHighScore then
        saveHighScore(gameType, citizenid, name, score)
        table.insert(HighScores[gameType], {
            citizenid = citizenid,
            score = score,
            name = name,
        })
        table.sort(HighScores[gameType], function(a, b)
            return a.score > b.score
        end)
        if #HighScores[gameType] > Config.Arcade.highScoreLimit then
            table.remove(HighScores[gameType])
        end
        Wrappers.Notify(src, Locale('arcade.new_high_score', score), 'success')
    end

    local leaderboard = {}
    for _, entry in ipairs(HighScores[gameType] or {}) do
        table.insert(leaderboard, { name = entry.name, score = entry.score })
    end
    TriggerClientEvent('arcade:showLeaderboard', src, leaderboard)
end)

AddEventHandler('playerDropped', function()
    local src = source
    RATE_LIMITS[src .. ':play'] = nil
    RATE_LIMITS[src .. ':submitScore'] = nil
end)
