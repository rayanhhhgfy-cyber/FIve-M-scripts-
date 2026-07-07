local QBox = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local AddMoney = function(source, amount)
    local p = QBox.Functions.GetPlayer(source)
    if p then
        p.Functions.AddMoney('cash', amount, 'Electrician Job')
        return
    end

    exports.ox_inventory:AddItem(source, 'money', amount)
end

local rateLimits = {}
local jobAssignments = {}

RegisterNetEvent('electrician:startJob', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local now = os.time()

    if rateLimits[identifier] and rateLimits[identifier] > now then
        return DropPlayer(src, 'Rate limited. Please wait.')
    end

    rateLimits[identifier] = os.time() + 3

    jobAssignments[src] = {
        identifier = identifier,
        startTime = os.time(),
        repairsDone = {},
    }
end)

RegisterNetEvent('electrician:completeJob', function(stopIndex)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local now = os.time()

    if rateLimits[identifier] and rateLimits[identifier] > now then
        return DropPlayer(src, 'Rate limited. Please wait.')
    end

    rateLimits[identifier] = os.time() + 2

    if type(stopIndex) ~= 'number' or stopIndex < 1 or stopIndex > #Config.RepairLocations then
        return DropPlayer(src, 'Cheater detected - invalid repair index.')
    end

    if jobAssignments[src] then
        if jobAssignments[src].repairsDone[stopIndex] then
            return DropPlayer(src, 'Cheater detected - duplicate repair.')
        end
        jobAssignments[src].repairsDone[stopIndex] = true
    end

    local playerPed = GetPlayerPed(src)
    local coords = GetEntityCoords(playerPed)
    local stopCoords = Config.RepairLocations[stopIndex]

    if #(coords - stopCoords) > 10.0 then
        return DropPlayer(src, 'Cheater detected - too far from repair location.')
    end

    MySQL.Async.insert('INSERT INTO electrician_jobs (identifier, stop_index, logged_at) VALUES (?, ?, NOW())', {
        identifier, stopIndex
    })
end)

RegisterNetEvent('electrician:collectPayment', function(repairCount, totalAmount)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local now = os.time()

    if rateLimits[identifier] and rateLimits[identifier] > now then
        return DropPlayer(src, 'Rate limited. Please wait.')
    end

    rateLimits[identifier] = os.time() + 3

    if type(repairCount) ~= 'number' or type(totalAmount) ~= 'number' then
        return DropPlayer(src, 'Invalid payment data.')
    end

    if repairCount < 1 or repairCount > #Config.RepairLocations then
        return DropPlayer(src, 'Invalid repair count.')
    end

    local expectedTotal = repairCount * Config.PaymentPerJob
    if totalAmount ~= expectedTotal then
        return DropPlayer(src, 'Payment mismatch detected.')
    end

    local playerPed = GetPlayerPed(src)
    local coords = GetEntityCoords(playerPed)
    if #(coords - Config.Depot) > 15.0 then
        return DropPlayer(src, 'Cheater detected - not at depot.')
    end

    AddMoney(src, totalAmount)

    MySQL.Async.insert('INSERT INTO electrician_payments (identifier, repairs, total_amount, paid_at) VALUES (?, ?, ?, NOW())', {
        identifier, repairCount, totalAmount
    })

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Payment Received',
        description = '$' .. totalAmount,
        type = 'success',
    })

    if jobAssignments[src] then
        jobAssignments[src] = nil
    end
end)

lib.callback.register('electrician:getStats', function(source)
    local identifier = GetPlayerIdentifier(source, 0)

    local payments = MySQL.query.await('SELECT COALESCE(SUM(total_amount), 0) as total, COALESCE(SUM(repairs), 0) as repairs FROM electrician_payments WHERE identifier = ?', {
        identifier
    })

    return payments[1] or { total = 0, repairs = 0 }
end)

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS electrician_jobs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(64) NOT NULL,
            stop_index INT NOT NULL DEFAULT 0,
            logged_at DATETIME NOT NULL
        )
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS electrician_payments (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(64) NOT NULL,
            repairs INT NOT NULL DEFAULT 0,
            total_amount INT NOT NULL DEFAULT 0,
            paid_at DATETIME NOT NULL
        )
    ]])
end)
