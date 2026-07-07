local QBox = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local AddMoney = function(source, amount)
    local p = QBox.Functions.GetPlayer(source)
    if p then
        p.Functions.AddMoney('cash', amount, 'Delivery Job')
        return
    end

    exports.ox_inventory:AddItem(source, 'money', amount)
end

local rateLimits = {}

RegisterNetEvent('delivery:startJob', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local now = os.time()

    if rateLimits[identifier] and rateLimits[identifier] > now then
        return DropPlayer(src, 'Rate limited. Please wait.')
    end

    rateLimits[identifier] = os.time() + 3
end)

RegisterNetEvent('delivery:deliverPackage', function(stopIndex)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local now = os.time()

    if rateLimits[identifier] and rateLimits[identifier] > now then
        return DropPlayer(src, 'Rate limited. Please wait.')
    end

    rateLimits[identifier] = os.time() + 2

    if type(stopIndex) ~= 'number' or stopIndex < 1 or stopIndex > #Config.DeliveryLocations then
        return DropPlayer(src, 'Cheater detected - invalid package index.')
    end

    local playerPed = GetPlayerPed(src)
    local coords = GetEntityCoords(playerPed)
    local stopCoords = Config.DeliveryLocations[stopIndex]

    if #(coords - stopCoords) > 10.0 then
        return DropPlayer(src, 'Cheater detected - too far from delivery point.')
    end

    MySQL.Async.insert('INSERT INTO delivery_logs (identifier, stop_index, payment, delivered_at) VALUES (?, ?, ?, NOW())', {
        identifier, stopIndex, Config.PaymentPerPackage
    }, function()
        AddMoney(src, Config.PaymentPerPackage)
    end)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Payment',
        description = '+$' .. Config.PaymentPerPackage,
        type = 'success',
    })
end)

RegisterNetEvent('delivery:bonusPayment', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)

    MySQL.Async.insert('INSERT INTO delivery_logs (identifier, stop_index, payment, delivered_at) VALUES (?, ?, ?, NOW())', {
        identifier, 0, Config.BonusAmount
    }, function()
        AddMoney(src, Config.BonusAmount)
    end)
end)

RegisterNetEvent('delivery:completeRoute', function()
    local src = source
end)

lib.callback.register('delivery:getStats', function(source)
    local identifier = GetPlayerIdentifier(source, 0)

    local result = MySQL.query.await('SELECT COUNT(*) as deliveries, COALESCE(SUM(payment), 0) as total FROM delivery_logs WHERE identifier = ?', {
        identifier
    })

    return result[1]
end)

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS delivery_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(64) NOT NULL,
            stop_index INT NOT NULL DEFAULT 0,
            payment INT NOT NULL DEFAULT 0,
            delivered_at DATETIME NOT NULL
        )
    ]])
end)
