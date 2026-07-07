local testDriveTimers = {}
local playerCooldowns = {}
local RATE_LIMITS = {}
local QBox = exports['qbx-core']:GetCoreObject()

Citizen.CreateThread(function()
    MySQL.ready(function()
        MySQL.query('CREATE TABLE IF NOT EXISTS player_vehicles (id INT AUTO_INCREMENT PRIMARY KEY, citizenid VARCHAR(50), vehicle VARCHAR(50), plate VARCHAR(12), color INT, showroom VARCHAR(50), financed BOOLEAN DEFAULT FALSE, down_payment INT DEFAULT 0, monthly_payment INT DEFAULT 0, payments_remaining INT DEFAULT 0, purchase_date INT DEFAULT 0)', {})
    end)
end)

RegisterNetEvent('vehicle_shop:purchase', function(model, label, price, colorIndex, showroomName, financed)
    local src = source
    if not src or src == 0 then return end
    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then return end

    local cooldownKey = 'vehshop_' .. license
    local now = os.time()
    if playerCooldowns[cooldownKey] and (now - playerCooldowns[cooldownKey]) < 3 then
        TriggerClientEvent('vehicle_shop:purchaseFailed', src, Locale('vehicle_shop.cooldown') or 'Please wait before purchasing again.')
        return
    end
    playerCooldowns[cooldownKey] = now

    local p = QBox.Functions.GetPlayer(src)
    if not p then return end

    local showroom = nil
    for _, sr in ipairs(Config.VehicleShop.Showrooms) do
        if sr.name == showroomName then
            showroom = sr
            break
        end
    end

    if not showroom then
        TriggerClientEvent('vehicle_shop:purchaseFailed', src, Locale('vehicle_shop.invalid_showroom') or 'Invalid showroom')
        return
    end

    local vehicleData = nil
    for _, veh in ipairs(showroom.vehicles) do
        if veh.model == model then
            vehicleData = veh
            break
        end
    end

    if not vehicleData then
        TriggerClientEvent('vehicle_shop:purchaseFailed', src, Locale('vehicle_shop.invalid_vehicle') or 'Invalid vehicle')
        return
    end

    local priceToUse = vehicleData.price
    local downPayment = 0
    local monthlyPayment = 0
    local paymentsRemaining = 0

    if financed then
        if not Config.VehicleShop.FinanceOptions.enabled then
            TriggerClientEvent('vehicle_shop:purchaseFailed', src, Locale('vehicle_shop.financing_disabled') or 'Financing is not available')
            return
        end
        local downPercent = Config.VehicleShop.FinanceOptions.minDownPayment / 100
        downPayment = math.ceil(vehicleData.price * downPercent)
        local financedAmount = vehicleData.price - downPayment
        monthlyPayment = math.ceil(financedAmount * (1 + Config.VehicleShop.FinanceOptions.interestRate) / Config.VehicleShop.FinanceOptions.maxPayments)
        paymentsRemaining = Config.VehicleShop.FinanceOptions.maxPayments

        if p.PlayerData.money.cash < downPayment then
            TriggerClientEvent('vehicle_shop:purchaseFailed', src, Locale('vehicle_shop.no_money_down') or string.format('Need $%d down payment', downPayment))
            return
        end
        p.Functions.RemoveMoney('cash', downPayment)
    else
        if p.PlayerData.money.cash < priceToUse then
            TriggerClientEvent('vehicle_shop:purchaseFailed', src, Locale('vehicle_shop.no_money') or 'Not enough money')
            return
        end
        p.Functions.RemoveMoney('cash', priceToUse)
    end

    local plate = GeneratePlate()
    local citizenid = p.PlayerData.citizenid

    MySQL.insert('INSERT INTO player_vehicles (citizenid, vehicle, plate, color, showroom, financed, down_payment, monthly_payment, payments_remaining, purchase_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { citizenid, model, plate, colorIndex or 0, showroomName, financed, downPayment, monthlyPayment, paymentsRemaining, os.time() },
        function()
            TriggerClientEvent('vehicle_shop:purchaseSuccess', src, model, label)
        end
    )

    local purchaseType = financed and 'Financed' or 'Full Purchase'
    local message = string.format('**Vehicle Purchase**\nPlayer: %s (%s)\nVehicle: %s\nPlate: %s\nPrice: $%s\nType: %s\nColor: %d\nShowroom: %s\nDate: %s',
        GetPlayerName(src), license, label, plate, FormatNumber(priceToUse), purchaseType, colorIndex or 0, showroomName, os.date('%Y-%m-%d %H:%M:%S'))
    exports['discord-logs']:LogCustom('vehicle_purchases', message)

    if financed then
        CreateFinanceThread(src, citizenid, model, plate, monthlyPayment)
    end
end)

local function CreateFinanceThread(src, citizenid, model, monthlyPayment)
    local threadKey = 'finance_' .. citizenid .. '_' .. model
    if testDriveTimers[threadKey] then return end

    testDriveTimers[threadKey] = Citizen.CreateThread(function()
        while true do
            Citizen.Wait(7 * 24 * 60 * 60 * 1000)
            local p = QBox.Functions.GetPlayer(src)
            if not p then
                Citizen.StopThread(testDriveTimers[threadKey])
                testDriveTimers[threadKey] = nil
                break
            end

            if p.PlayerData.money.cash >= monthlyPayment then
                p.Functions.RemoveMoney('cash', monthlyPayment)
                MySQL.update('UPDATE player_vehicles SET payments_remaining = payments_remaining - 1 WHERE citizenid = ? AND vehicle = ?', { citizenid, model })
                Wrappers.Notify(src, Locale('vehicle_shop.finance_paid', monthlyPayment) or string.format('Finance payment of $%d taken', monthlyPayment), 'info')

                MySQL.single('SELECT payments_remaining FROM player_vehicles WHERE citizenid = ? AND vehicle = ?', { citizenid, model }, function(result)
                    if result and result.payments_remaining <= 0 then
                        MySQL.update('UPDATE player_vehicles SET financed = FALSE WHERE citizenid = ? AND vehicle = ?', { citizenid, model })
                        Wrappers.Notify(src, Locale('vehicle_shop.finance_paid_off') or 'Vehicle is fully paid off!', 'success')
                        Citizen.StopThread(testDriveTimers[threadKey])
                        testDriveTimers[threadKey] = nil
                    end
                end)
            else
                Wrappers.Notify(src, Locale('vehicle_shop.finance_missed') or 'Missed finance payment! Vehicle may be repossessed.', 'error')
            end
        end
    end)
end

local function GeneratePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local plate = ''
    for i = 1, 8 do
        plate = plate .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    local exists = MySQL.single.await('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    if exists then return GeneratePlate() end
    return plate
end

local function FormatNumber(amount)
    local formatted = tostring(amount)
    local k = 3
    while #formatted > k do
        formatted = formatted:sub(1, #formatted - k) .. ',' .. formatted:sub(#formatted - k + 1)
        k = k + 4
    end
    return formatted
end

AddEventHandler('playerDropped', function(reason)
    local src = source
    playerCooldowns['vehshop_' .. GetPlayerIdentifierByType(src, 'license')] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for k, thread in pairs(testDriveTimers) do
            Citizen.StopThread(thread)
        end
        testDriveTimers = {}
    end
end)
