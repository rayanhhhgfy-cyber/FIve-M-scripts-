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

local ActiveViewers = {}
local TheaterSessions = {}
local SeatAssignments = {}

local function ensureMovieTables()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS movie_tickets (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(64) NOT NULL,
            theater_index INT NOT NULL,
            movie_id INT NOT NULL,
            seat_number INT NOT NULL,
            purchase_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS movie_sessions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            theater_index INT NOT NULL,
            movie_id INT NOT NULL,
            start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            active TINYINT(1) DEFAULT 1
        )
    ]])
end

CreateThread(function()
    ensureMovieTables()
end)

RegisterNetEvent('movie:buyTicket', function(theaterIndex, movieId)
    local src = source
    if not checkRateLimit(src, 'buyTicket', 2) then
        return Wrappers.Notify(src, Locale('movie_theater.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    theaterIndex = tonumber(theaterIndex)
    movieId = tonumber(movieId)
    if not theaterIndex or not movieId then return end

    local theater = Config.MovieTheater.locations[theaterIndex]
    if not theater then return end

    local movie = nil
    for _, m in ipairs(Config.MovieTheater.movies) do
        if m.id == movieId then
            movie = m
            break
        end
    end
    if not movie then return end

    local price = theater.ticketPrice
    local cash = Player.Functions.GetMoney('cash')
    if cash < price then
        return Wrappers.Notify(src, Locale('movie_theater.no_money'), 'error')
    end

    Player.Functions.RemoveMoney('cash', price)

    local seatNumber = math.random(1, 50)
    MySQL.Async.insert('INSERT INTO movie_tickets (citizenid, theater_index, movie_id, seat_number) VALUES (?, ?, ?, ?)', {
        Player.PlayerData.citizenid, theaterIndex, movieId, seatNumber,
    })

    if not TheaterSessions[theaterIndex] then
        TheaterSessions[theaterIndex] = {}
    end
    if not TheaterSessions[theaterIndex][movieId] then
        TheaterSessions[theaterIndex][movieId] = { viewers = {} }
    end
    table.insert(TheaterSessions[theaterIndex][movieId].viewers, src)

    SeatAssignments[src] = {
        theaterIndex = theaterIndex,
        movieId = movieId,
        seatNumber = seatNumber,
    }

    Wrappers.Notify(src, Locale('movie_theater.buy_ticket', movie.name), 'success')
    TriggerClientEvent('movie:ticketPurchased', src, theaterIndex, movieId, seatNumber)
end)

RegisterNetEvent('movie:enterTheater', function(theaterIndex, movieId)
    local src = source
    if not checkRateLimit(src, 'enterTheater', 2) then
        return Wrappers.Notify(src, Locale('movie_theater.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local assignment = SeatAssignments[src]
    if not assignment then
        return Wrappers.Notify(src, Locale('movie_theater.no_ticket'), 'error')
    end

    local theater = Config.MovieTheater.locations[assignment.theaterIndex]
    if not theater then return end

    local movie = nil
    for _, m in ipairs(Config.MovieTheater.movies) do
        if m.id == assignment.movieId then
            movie = m
            break
        end
    end

    ActiveViewers[src] = {
        theaterIndex = assignment.theaterIndex,
        movieId = assignment.movieId,
        seatNumber = assignment.seatNumber,
    }

    TriggerClientEvent('movie:enterInterior', src, theater, movie, assignment.seatNumber)
    Wrappers.Notify(src, Locale('movie_theater.enjoy', movie and movie.name or ''), 'success')
end)

RegisterNetEvent('movie:leaveTheater', function()
    local src = source
    if not checkRateLimit(src, 'leaveTheater', 2) then
        return Wrappers.Notify(src, Locale('movie_theater.too_fast'), 'error')
    end

    local viewer = ActiveViewers[src]
    if not viewer then
        local assignment = SeatAssignments[src]
        if not assignment then
            return Wrappers.Notify(src, Locale('movie_theater.not_inside'), 'error')
        end
    end

    ActiveViewers[src] = nil
    SeatAssignments[src] = nil

    TriggerClientEvent('movie:exitInterior', src)
    Wrappers.Notify(src, Locale('movie_theater.exit'), 'info')
end)

RegisterNetEvent('movie:buySnack', function(theaterIndex, snackName)
    local src = source
    if not checkRateLimit(src, 'buySnack', 2) then
        return Wrappers.Notify(src, Locale('movie_theater.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    theaterIndex = tonumber(theaterIndex)
    if not theaterIndex then return end

    local snack = nil
    for _, s in ipairs(Config.MovieTheater.snacks) do
        if s.name == snackName then
            snack = s
            break
        end
    end
    if not snack then return end

    local cash = Player.Functions.GetMoney('cash')
    if cash < snack.price then
        return Wrappers.Notify(src, Locale('movie_theater.no_money'), 'error')
    end

    Player.Functions.RemoveMoney('cash', snack.price)
    Player.Functions.AddItem(snack.name, 1)

    Wrappers.Notify(src, Locale('movie_theater.buy_snack', snack.label), 'success')
end)

AddEventHandler('playerDropped', function()
    local src = source
    ActiveViewers[src] = nil
    SeatAssignments[src] = nil
    for theaterIdx, sessions in pairs(TheaterSessions) do
        for movieId, session in pairs(sessions) do
            for i = #session.viewers, 1, -1 do
                if session.viewers[i] == src then
                    table.remove(session.viewers, i)
                end
            end
        end
    end
end)
