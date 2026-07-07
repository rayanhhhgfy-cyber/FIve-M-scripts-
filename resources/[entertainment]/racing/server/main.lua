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

local ActiveRaces = {}
local RaceCounter = 0

local function isAtMeetLocation(coords)
    for _, ml in ipairs(Config.Racing.meetLocations) do
        if #(ml - coords) < 50.0 then
            return true
        end
    end
    return false
end

RegisterNetEvent('racing:createRace', function(trackIndex)
    local src = source
    if not checkRateLimit(src, 'createRace', 1) then
        return Wrappers.Notify(src, Locale('racing.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    trackIndex = tonumber(trackIndex)
    if not trackIndex then return end
    local track = Config.Racing.tracks[trackIndex]
    if not track then return end

    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    if not isAtMeetLocation(pedCoords) then
        return Wrappers.Notify(src, Locale('racing.not_at_meet'), 'error')
    end

    for _, race in pairs(ActiveRaces) do
        if race.creator == src then
            return Wrappers.Notify(src, Locale('racing.already_racing'), 'error')
        end
    end

    RaceCounter = RaceCounter + 1
    local raceId = 'race_' .. RaceCounter

    ActiveRaces[raceId] = {
        id = raceId,
        creator = src,
        trackIndex = trackIndex,
        track = track,
        participants = {},
        status = 'waiting',
        bet = 0,
        pot = 0,
        startTime = 0,
    }

    table.insert(ActiveRaces[raceId].participants, {
        src = src,
        checkpointsPassed = 0,
        finished = false,
        finishTime = 0,
        bet = 0,
    })

    TriggerClientEvent('racing:raceCreated', src, raceId, track)
    Wrappers.Notify(src, Locale('racing.create_race'), 'success')
end)

RegisterNetEvent('racing:joinRace', function(raceId, betAmount)
    local src = source
    if not checkRateLimit(src, 'joinRace', 1) then
        return Wrappers.Notify(src, Locale('racing.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local race = ActiveRaces[raceId]
    if not race then
        return Wrappers.Notify(src, Locale('racing.race_cancelled'), 'error')
    end
    if race.status ~= 'waiting' then
        return Wrappers.Notify(src, Locale('racing.race_started'), 'error')
    end
    if #race.participants >= Config.Racing.maxRacers then
        return Wrappers.Notify(src, Locale('racing.race_full'), 'error')
    end

    betAmount = tonumber(betAmount)
    if not betAmount then return end

    if betAmount < race.track.minBet or betAmount > race.track.maxBet then
        return Wrappers.Notify(src, Locale('racing.invalid_bet'), 'error')
    end

    if race.bet > 0 and betAmount < race.bet then
        return Wrappers.Notify(src, Locale('racing.bet_too_low'), 'error')
    end

    local cash = Player.Functions.GetMoney('cash')
    if cash < betAmount then
        return Wrappers.Notify(src, Locale('racing.no_money'), 'error')
    end

    Player.Functions.RemoveMoney('cash', betAmount)

    local alreadyJoined = false
    for _, p in ipairs(race.participants) do
        if p.src == src then
            alreadyJoined = true
            break
        end
    end

    if not alreadyJoined then
        table.insert(race.participants, {
            src = src,
            checkpointsPassed = 0,
            finished = false,
            finishTime = 0,
            bet = betAmount,
        })
    end

    if betAmount > race.bet then
        race.bet = betAmount
    end

    TriggerClientEvent('racing:joinedRace', src, raceId)
    Wrappers.Notify(src, Locale('racing.join_race'), 'success')
end)

RegisterNetEvent('racing:startRace', function(raceId)
    local src = source
    if not checkRateLimit(src, 'startRace', 1) then
        return Wrappers.Notify(src, Locale('racing.too_fast'), 'error')
    end

    local race = ActiveRaces[raceId]
    if not race then return end
    if race.creator ~= src then return end
    if race.status ~= 'waiting' then return end
    if #race.participants < 2 then
        return Wrappers.Notify(src, Locale('racing.not_enough_players'), 'error')
    end

    local totalPot = 0
    for _, p in ipairs(race.participants) do
        local bet = p.bet > 0 and p.bet or race.bet
        totalPot = totalPot + bet
    end

    race.status = 'countdown'
    race.pot = totalPot

    for _, p in ipairs(race.participants) do
        TriggerClientEvent('racing:countdown', p.src, Config.Racing.countdownTime, race)
    end

    SetTimeout(Config.Racing.countdownTime * 1000, function()
        if not ActiveRaces[raceId] then return end
        race.status = 'racing'
        race.startTime = os.time()
        for _, p in ipairs(race.participants) do
            TriggerClientEvent('racing:raceStarted', p.src, race)
        end
    end)
end)

RegisterNetEvent('racing:checkpointPassed', function(raceId, checkpointIndex)
    local src = source
    if not checkRateLimit(src, 'checkpointPassed', 10) then return end

    local race = ActiveRaces[raceId]
    if not race or race.status ~= 'racing' then return end

    for _, p in ipairs(race.participants) do
        if p.src == src and not p.finished then
            if checkpointIndex == p.checkpointsPassed + 1 then
                p.checkpointsPassed = checkpointIndex
            end
            break
        end
    end
end)

RegisterNetEvent('racing:finishRace', function(raceId)
    local src = source
    if not checkRateLimit(src, 'finishRace', 1) then
        return Wrappers.Notify(src, Locale('racing.too_fast'), 'error')
    end

    local race = ActiveRaces[raceId]
    if not race or race.status ~= 'racing' then return end

    local racer = nil
    for _, p in ipairs(race.participants) do
        if p.src == src then
            racer = p
            break
        end
    end
    if not racer or racer.finished then return end

    if racer.checkpointsPassed < #race.track.checkpoints then
        return Wrappers.Notify(src, Locale('racing.not_all_checkpoints'), 'error')
    end

    racer.finished = true
    racer.finishTime = os.time() - race.startTime

    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local payout = math.floor(race.pot * Config.Racing.defaultPayoutMultiplier)
        Player.Functions.AddMoney('cash', payout)
        Wrappers.Notify(src, Locale('racing.won', payout), 'success')
        TriggerClientEvent('racing:raceFinished', src, 'won', payout)
    end

    local allFinished = true
    for _, p in ipairs(race.participants) do
        if not p.finished then
            allFinished = false
        end
    end

    if allFinished then
        ActiveRaces[raceId] = nil
    end
end)

RegisterNetEvent('racing:cancelRace', function(raceId)
    local src = source
    local race = ActiveRaces[raceId]
    if not race then return end
    if race.creator ~= src then return end

    for _, p in ipairs(race.participants) do
        if p.src ~= src then
            local pl = QBCore.Functions.GetPlayer(p.src)
            if pl then
                local bet = p.bet > 0 and p.bet or race.bet
                pl.Functions.AddMoney('cash', bet)
                TriggerClientEvent('racing:raceCancelled', p.src)
            end
        end
    end
    ActiveRaces[raceId] = nil
    Wrappers.Notify(src, Locale('racing.race_cancelled'), 'info')
end)

AddEventHandler('playerDropped', function()
    local src = source
    for raceId, race in pairs(ActiveRaces) do
        for i = #race.participants, 1, -1 do
            if race.participants[i].src == src then
                table.remove(race.participants, i)
                break
            end
        end
        if #race.participants == 0 then
            ActiveRaces[raceId] = nil
        elseif race.creator == src and race.status == 'waiting' then
            for _, p in ipairs(race.participants) do
                local pl = QBCore.Functions.GetPlayer(p.src)
                if pl then
                    local bet = p.bet > 0 and p.bet or race.bet
                    pl.Functions.AddMoney('cash', bet)
                    TriggerClientEvent('racing:raceCancelled', p.src)
                end
            end
            ActiveRaces[raceId] = nil
        end
    end
end)
