local QBox = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local AddMoney = function(source, amount)
    local p = QBox.Functions.GetPlayer(source)
    if p then
        p.Functions.AddMoney('cash', amount, 'Bus Job')
        return
    end

    exports.ox_inventory:AddItem(source, 'money', amount)
end

local rateLimits = {}
local playerShifts = {}

RegisterNetEvent('bus:startJob', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local now = os.time()

    if rateLimits[identifier] and rateLimits[identifier] > now then
        return DropPlayer(src, 'Rate limited. Please wait.')
    end

    rateLimits[identifier] = os.time() + 3

    playerShifts[src] = {
        identifier = identifier,
        startTime = os.time(),
        stopsServiced = 0,
    }
end)

RegisterNetEvent('bus:payWage', function(amount)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local now = os.time()

    if rateLimits[identifier] and rateLimits[identifier] > now then
        return DropPlayer(src, 'Rate limited. Please wait.')
    end

    rateLimits[identifier] = os.time() + 2

    if type(amount) ~= 'number' or amount < 0 or amount > 10000 then
        return DropPlayer(src, 'Invalid wage amount.')
    end

    AddMoney(src, amount)

    MySQL.Async.insert('INSERT INTO bus_logs (identifier, type, amount, logged_at) VALUES (?, ?, ?, NOW())', {
        identifier, 'wage', amount
    })
end)

RegisterNetEvent('bus:completeRoute', function(stopsServiced)
    local src = source

    if playerShifts[src] then
        playerShifts[src].stopsServiced = stopsServiced
        playerShifts[src].endTime = os.time()

        local data = playerShifts[src]
        MySQL.Async.insert('INSERT INTO bus_shifts (identifier, start_time, end_time, stops_serviced, logged_at) VALUES (?, FROM_UNIXTIME(?), FROM_UNIXTIME(?), ?, NOW())', {
            data.identifier, data.startTime, data.endTime, data.stopsServiced or 0
        })

        playerShifts[src] = nil
    end
end)

lib.callback.register('bus:getStats', function(source)
    local identifier = GetPlayerIdentifier(source, 0)

    local totalWage = MySQL.query.await('SELECT COALESCE(SUM(amount), 0) as total FROM bus_logs WHERE identifier = ? AND type = ?', {
        identifier, 'wage'
    })

    local shifts = MySQL.query.await('SELECT COUNT(*) as count FROM bus_shifts WHERE identifier = ?', {
        identifier
    })

    return {
        totalEarned = totalWage[1] and totalWage[1].total or 0,
        shiftsCompleted = shifts[1] and shifts[1].count or 0,
    }
end)

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS bus_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(64) NOT NULL,
            type VARCHAR(32) NOT NULL DEFAULT 'wage',
            amount INT NOT NULL DEFAULT 0,
            logged_at DATETIME NOT NULL
        )
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS bus_shifts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(64) NOT NULL,
            start_time DATETIME NOT NULL,
            end_time DATETIME NOT NULL,
            stops_serviced INT NOT NULL DEFAULT 0,
            logged_at DATETIME NOT NULL
        )
    ]])
end)
