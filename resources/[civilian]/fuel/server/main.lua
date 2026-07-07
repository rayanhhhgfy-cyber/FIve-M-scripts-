local fuelJobTimers = {}
local playerCooldowns = {}
local RATE_LIMITS = {}
local QBox = exports['qbx-core']:GetCoreObject()

Citizen.CreateThread(function()
    MySQL.ready(function()
        MySQL.query('CREATE TABLE IF NOT EXISTS vehicle_fuel (plate VARCHAR(12) PRIMARY KEY, fuel_level FLOAT DEFAULT 100.0, last_updated INT DEFAULT 0)', {})
    end)
end)

RegisterNetEvent('fuel:requestLevel', function(netId)
    local src = source
    local vehicle = NetToVeh(netId)
    if not DoesEntityExist(vehicle) then return end
    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate or plate == '' then return end

    MySQL.single('SELECT fuel_level FROM vehicle_fuel WHERE plate = ?', { plate }, function(result)
        local level = Config.Fuel.MaxFuel
        if result then
            level = result.fuel_level
        else
            MySQL.insert('INSERT INTO vehicle_fuel (plate, fuel_level, last_updated) VALUES (?, ?, ?)', { plate, level, os.time() })
        end
        Entity(vehicle).state:set('fuel', level, true)
        TriggerClientEvent('fuel:setLevel', src, netId, level)
    end)
end)

RegisterNetEvent('fuel:purchase', function(cost)
    local src = source
    if not src or src == 0 then return end
    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then return end

    local cooldownKey = 'fuel_purchase_' .. license
    local now = os.time()
    if playerCooldowns[cooldownKey] and (now - playerCooldowns[cooldownKey]) < 3 then
        Wrappers.Notify(src, Locale('fuel.cooldown') or 'Wait a moment before purchasing again.', 'error')
        return
    end
    playerCooldowns[cooldownKey] = now

    local p = QBox.Functions.GetPlayer(src)
    if not p then return end

    cost = math.floor(cost * 100) / 100
    if cost <= 0 then return end

    local money = p.PlayerData.money.cash
    if money < cost then
        Wrappers.Notify(src, Locale('fuel.no_money') or 'Not enough money!', 'error')
        return
    end

    p.Functions.RemoveMoney('cash', cost)
    MySQL.update('UPDATE vehicle_fuel SET fuel_level = ?, last_updated = ? WHERE plate IN (SELECT plate FROM player_vehicles WHERE citizenid = ?)',
        { Config.Fuel.MaxFuel, os.time(), p.PlayerData.citizenid })

    local message = string.format('**Fuel Purchase**\nPlayer: %s (%s)\nAmount: $%.2f\nDate: %s', GetPlayerName(src), license, cost, os.date('%Y-%m-%d %H:%M:%S'))
    exports['discord-logs']:LogCustom('fuel_purchases', message)

    Wrappers.Notify(src, Locale('fuel.purchased', cost) or string.format('Paid $%.2f for fuel', cost), 'success')
end)

RegisterNetEvent('fuel:startJob', function()
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end

    if fuelJobTimers[src] then return end

    local jobName = Config.Fuel.FuelJob.name
    p.Functions.SetJob(jobName, 0)

    fuelJobTimers[src] = Citizen.CreateThread(function()
        while fuelJobTimers[src] do
            Citizen.Wait(60000)
        end
    end)

    Wrappers.Notify(src, Locale('fuel.job_started') or 'Gas station job started!', 'success')
end)

RegisterNetEvent('fuel:stopJob', function()
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end

    if fuelJobTimers[src] then
        Citizen.StopThread(fuelJobTimers[src])
        fuelJobTimers[src] = nil
    end

    p.Functions.SetJob('unemployed', 0)
    Wrappers.Notify(src, Locale('fuel.job_ended') or 'Gas station job ended.', 'info')
end)

RegisterNetEvent('fuel:jobPayment', function()
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end

    local payment = Config.Fuel.FuelJob.payment
    p.Functions.AddMoney('cash', payment)

    local message = string.format('**Fuel Job Payment**\nPlayer: %s (%s)\nAmount: $%d\nDate: %s',
        GetPlayerName(src), GetPlayerIdentifierByType(src, 'license'), payment, os.date('%Y-%m-%d %H:%M:%S'))
    exports['discord-logs']:LogCustom('fuel_job_payments', message)

    Wrappers.Notify(src, Locale('fuel.job_payment_received', payment) or string.format('Received $%d from gas station job', payment), 'success')
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if fuelJobTimers[src] then
        Citizen.StopThread(fuelJobTimers[src])
        fuelJobTimers[src] = nil
    end
    playerCooldowns['fuel_purchase_' .. GetPlayerIdentifierByType(src, 'license')] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for src, thread in pairs(fuelJobTimers) do
            Citizen.StopThread(thread)
        end
        fuelJobTimers = {}
    end
end)
