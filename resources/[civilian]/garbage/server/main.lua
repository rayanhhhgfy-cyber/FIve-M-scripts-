local QBox = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local AddMoney = function(source, amount)
    local p = QBox.Functions.GetPlayer(source)
    if p then
        p.Functions.AddMoney('cash', amount, 'Garbage Job')
        return
    end

    exports.ox_inventory:AddItem(source, 'money', amount)
end

local rateLimits = {}

RegisterNetEvent('garbage:startJob', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local now = os.time()

    if rateLimits[identifier] and rateLimits[identifier] > now then
        return DropPlayer(src, 'Rate limited. Please wait.')
    end

    rateLimits[identifier] = os.time() + 3
end)

RegisterNetEvent('garbage:completeJob', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local now = os.time()

    if rateLimits[identifier] and rateLimits[identifier] > now then
        return DropPlayer(src, 'Rate limited. Please wait.')
    end

    rateLimits[identifier] = os.time() + 3

    local playerPed = GetPlayerPed(src)
    local coords = GetEntityCoords(playerPed)
    local distance = #(coords - Config.Landfill)

    if distance > 15.0 then
        return DropPlayer(src, 'Cheater detected - invalid location.')
    end

    MySQL.Async.insert('INSERT INTO garbage_jobs (identifier, payment, completed_at) VALUES (?, ?, NOW())', {
        identifier, Config.PaymentPerRoute
    }, function()
        AddMoney(src, Config.PaymentPerRoute)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Payment Received',
            description = '$' .. Config.PaymentPerRoute,
            type = 'success',
        })
    end)
end)

lib.callback.register('garbage:getStats', function(source)
    local identifier = GetPlayerIdentifier(source, 0)

    local result = MySQL.query.await('SELECT COUNT(*) as count, COALESCE(SUM(payment), 0) as total FROM garbage_jobs WHERE identifier = ?', {
        identifier
    })

    return result[1]
end)

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS garbage_jobs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(64) NOT NULL,
            payment INT NOT NULL DEFAULT 0,
            completed_at DATETIME NOT NULL
        )
    ]])
end)
