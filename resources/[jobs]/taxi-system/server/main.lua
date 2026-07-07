local QBox = exports['qbx_core']:GetCoreObject()
local activeFares = {}
local driverDuty = {}
local driverStats = {}
local activeFareSessions = {}
local RATE_LIMITS = {}

local function rl(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

local function isDriver(src)
    local p = QBox.Functions.GetPlayer(src)
    return p and p.PlayerData.job.name == Config.Taxi.driverJob
end

local function getOrCreateStats(cid)
    if not driverStats[cid] then
        driverStats[cid] = { rides = 0, totalEarned = 0, ratingSum = 0, ratingCount = 0, crashes = 0, smoothTotal = 0 }
    end
    return driverStats[cid]
end

RegisterNetEvent('taxi:toggleDuty', function()
    local src = source
    if not rl(src, 'duty', 6) then return end
    if not isDriver(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not a taxi driver' })
        return
    end
    driverDuty[src] = not driverDuty[src]
    TriggerClientEvent('taxi:dutyToggled', src, driverDuty[src])

    if driverDuty[src] then
        local p = QBox.Functions.GetPlayer(src)
        if p then
            local cid = p.PlayerData.citizenid
            local stats = getOrCreateStats(cid)
            local avgRating = stats.ratingCount > 0 and string.format('%.1f', stats.ratingSum / stats.ratingCount) or '—'
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'On duty | ' .. stats.rides .. ' rides | ' .. avgRating .. '/5 rating' })
        end
        scheduleNpcFare(src)
    end
end)

function scheduleNpcFare(src)
    if not driverDuty[src] then return end
    local delay = math.random(15000, 45000)
    SetTimeout(delay, function()
        if not driverDuty[src] then return end
        if activeFareSessions[src] then
            scheduleNpcFare(src)
            return
        end
        local route = Config.Taxi.npcFareRoutes[math.random(#Config.Taxi.npcFareRoutes)]
        local fareId = 'FARE-' .. os.time() .. '-' .. src
        activeFares[fareId] = {
            driver = src, route = route,
            started = os.time(), active = true,
            distance = route.distance, total = route.distance * Config.Taxi.perMileRate + Config.Taxi.baseFare,
            crashes = 0, speedViolations = 0, smoothScore = 100
        }
        activeFareSessions[src] = fareId
        TriggerClientEvent('taxi:npcFareCreated', src, fareId, route)
        TriggerClientEvent('taxi:phoneDispatch', src, { fare = { id = fareId, pickup = route.pickup, dropoff = route.dropoff, estimatedFare = activeFares[fareId].total } })
    end)
end

RegisterNetEvent('taxi:updateFarePos', function(fareId, fare, miles)
    local fareData = activeFares[fareId]
    if not fareData or not fareData.active then return end
    fareData.currentFare = fare
    fareData.currentMiles = miles
    TriggerClientEvent('taxi:phoneFareUpdate', fareData.driver, { fare = fare, distance = miles })
end)

RegisterNetEvent('taxi:crashDetected', function()
    local src = source
    local fareId = activeFareSessions[src]
    if not fareId then return end
    local fare = activeFares[fareId]
    if fare then fare.crashes = (fare.crashes or 0) + 1 end
end)

RegisterNetEvent('taxi:completeNpcFare', function(fareId)
    local src = source
    local fare = activeFares[fareId]
    if not fare or not fare.active then return end
    fare.active = false
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    local stats = getOrCreateStats(cid)

    local baseAmount = math.floor(fare.total)
    local crashPenalty = math.min(5, math.max(0, 5 - math.floor((fare.crashes or 0) / 1)))
    local smoothRating = math.min(5, math.max(0, math.floor((fare.smoothScore or 100) / 20)))
    local qualityScore = math.max(1, math.floor((crashPenalty + smoothRating) / 2))

    local tipPercent = (Config.Taxi.tipBaseMultiplier + (qualityScore / 10))
    local tip = math.floor(baseAmount * (tipPercent - Config.Taxi.tipBaseMultiplier))

    if (fare.crashes or 0) > 2 then tip = 0 end
    local totalPayout = baseAmount + tip
    p.Functions.AddMoney('cash', totalPayout, nil)

    stats.rides = stats.rides + 1
    stats.totalEarned = stats.totalEarned + totalPayout
    stats.crashes = stats.crashes + (fare.crashes or 0)

    local qualityLabel = 'Perfect'
    if qualityScore <= 2 then qualityLabel = 'Poor'
    elseif qualityScore <= 3 then qualityLabel = 'Fair'
    elseif qualityScore <= 4 then qualityLabel = 'Good'
    else qualityLabel = 'Excellent' end

    TriggerClientEvent('taxi:fareCompleted', src, baseAmount, tip, qualityLabel)
    activeFareSessions[src] = nil
    scheduleNpcFare(src)
end)

RegisterNetEvent('taxi:requestRide', function()
    local src = source
    if not rl(src, 'requestRide', 3) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end

    local availableDrivers = {}
    for sid, onDuty in pairs(driverDuty) do
        if onDuty and not activeFareSessions[sid] then
            table.insert(availableDrivers, sid)
        end
    end
    if #availableDrivers == 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No taxi drivers available' })
        return
    end
    local driverSrc = availableDrivers[math.random(#availableDrivers)]
    local route = Config.Taxi.npcFareRoutes[math.random(#Config.Taxi.npcFareRoutes)]
    local fareId = 'FARE-' .. os.time() .. '-' .. driverSrc
    activeFares[fareId] = {
        driver = driverSrc, passenger = src, route = route,
        started = os.time(), active = true,
        distance = route.distance, total = route.distance * Config.Taxi.perMileRate + Config.Taxi.baseFare,
        crashes = 0, speedViolations = 0, smoothScore = 100,
        passengerCid = p.PlayerData.citizenid
    }
    activeFareSessions[driverSrc] = fareId
    TriggerClientEvent('taxi:npcFareCreated', driverSrc, fareId, route)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Taxi dispatched! Driver incoming.' })
end)

RegisterNetEvent('taxi:endRide', function()
    local src = source
    local fareId = activeFareSessions[src]
    if not fareId then return end
    local fare = activeFares[fareId]
    if fare and fare.active then
        fare.active = false
        local p = QBox.Functions.GetPlayer(src)
        if p then
            local baseAmount = math.floor(fare.total or 20)
            local tip = math.floor(baseAmount * 0.15)
            local totalPayout = baseAmount + tip
            p.Functions.AddMoney('cash', totalPayout, nil)
            local cid = p.PlayerData.citizenid
            local stats = getOrCreateStats(cid)
            stats.rides = stats.rides + 1
            stats.totalEarned = stats.totalEarned + totalPayout
            TriggerClientEvent('taxi:fareCompleted', src, baseAmount, tip, 'Manual')
        end
    end
    activeFareSessions[src] = nil
    scheduleNpcFare(src)
end)

RegisterNetEvent('taxi:rateRide', function(rating)
    local src = source
    if not rl(src, 'rate', 5) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    local stats = getOrCreateStats(cid)
    stats.ratingSum = stats.ratingSum + (rating or 3)
    stats.ratingCount = stats.ratingCount + 1
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Rated ' .. (rating or 3) .. '/5' })
end)

RegisterNetEvent('taxi:updateFare', function(fareId, distance)
    local fare = activeFares[fareId]
    if not fare or not fare.active then return end
    fare.total = math.floor(Config.Taxi.baseFare + (distance * Config.Taxi.perMileRate))
end)

QBox.Functions.CreateCallback('taxi:getDriverStats', function(source, cb)
    local p = QBox.Functions.GetPlayer(source)
    if not p then cb({}) return end
    cb(getOrCreateStats(p.PlayerData.citizenid))
end)
