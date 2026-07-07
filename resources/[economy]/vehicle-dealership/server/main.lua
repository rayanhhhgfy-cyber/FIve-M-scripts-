local QBCore = exports['qbx_core']:GetCoreObject()

local function generatePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local plate = ''
    for i = 1, 8 do
        plate = plate .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    return plate
end

local function getVehicleData(model)
    for category, vehicles in pairs(Config.DealershipVehicles) do
        for _, v in ipairs(vehicles) do
            if v.model == model then return v end
        end
    end
    return nil
end

local function hasReachedMaxFinancing(src)
    local citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
    local result = MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ? AND financed = 1', { citizenid })
    return result >= Config.Dealership.Financing.MaxFinancingVehicles
end

local function countOwnedVehicles(citizenid)
    return MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ?', { citizenid })
end

lib.callback.register('dealership:server:buyVehicle', function(src, category, model, paymentType)
    local source = src
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return { success = false, error = 'Player not found' } end

    local vehicleData = getVehicleData(model)
    if not vehicleData then return { success = false, error = 'Vehicle not found' } end

    local citizenid = Player.PlayerData.citizenid
    local plate = generatePlate()
    local price = vehicleData.price
    local financed = false
    local financeInfo = nil

    if paymentType == 'cash' then
        local cash = Player.PlayerData.money.cash or 0
        if cash < price then
            return { success = false, error = 'Not enough cash. Need: $' .. price }
        end
        Player.Functions.RemoveMoney('cash', price, 'vehicle-purchase')
    elseif paymentType == 'bank' then
        local bank = Player.PlayerData.money.bank or 0
        if bank < price then
            return { success = false, error = 'Not enough bank balance. Need: $' .. price }
        end
        Player.Functions.RemoveMoney('bank', price, 'vehicle-purchase')
    elseif paymentType == 'finance' then
        local finance = Config.Dealership.Financing
        local downPayment = math.floor(price * finance.MinDownPayment)
        local total = vehicleData.financingPrice
        local weekly = math.floor(total / finance.WeeklyPaymentTerm)

        local bank = Player.PlayerData.money.bank or 0
        if bank < downPayment then
            return { success = false, error = 'Not enough for down payment. Need: $' .. downPayment }
        end
        if hasReachedMaxFinancing(source) then
            return { success = false, error = 'Maximum financed vehicles reached (' .. finance.MaxFinancingVehicles .. ')' }
        end
        Player.Functions.RemoveMoney('bank', downPayment, 'vehicle-finance-downpayment')
        financed = true
        financeInfo = {
            weekly = weekly,
            terms = finance.WeeklyPaymentTerm,
            total = total,
            remaining = total - downPayment
        }
    else
        return { success = false, error = 'Invalid payment type' }
    end

    local inserted = MySQL.insert.await('INSERT INTO player_vehicles (citizenid, plate, model, garage, financed, finance_payments, finance_total, finance_weekly, model_data) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        citizenid, plate, model, 'A', financed and 1 or 0, 0, (financeInfo and financeInfo.total) or price, (financeInfo and financeInfo.weekly) or 0, '{}'
    })

    if not inserted then
        Player.Functions.AddMoney(paymentType == 'finance' and 'bank' or (paymentType == 'cash' and 'cash' or 'bank'), price, 'vehicle-purchase-refund')
        return { success = false, error = 'Database error - purchase refunded' }
    end

    exports['qbx_core']:CreateVehicle(model, plate, nil, nil)

    return { success = true, plate = plate, financeInfo = financeInfo }
end)

lib.callback.register('dealership:server:sellVehicle', function(src, plate)
    local source = src
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return { success = false, error = 'Player not found' } end

    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, Player.PlayerData.citizenid })
    if not vehicle then
        return { success = false, error = 'Vehicle not found or not yours' }
    end
    if vehicle.financed == 1 then
        return { success = false, error = 'Cannot sell a financed vehicle. Pay off financing first.' }
    end

    local vehicleData = getVehicleData(vehicle.model)
    if not vehicleData then
        return { success = false, error = 'Cannot determine vehicle value' }
    end

    local payout = math.floor(vehicleData.price * Config.Dealership.TradeInMultiplier)
    MySQL.update.await('DELETE FROM player_vehicles WHERE plate = ?', { plate })

    Player.Functions.AddMoney('bank', payout, 'vehicle-sale')

    return { success = true, payout = payout }
end)

lib.callback.register('dealership:server:getPlayerVehicles', function(src)
    local source = src
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end

    local vehicles = MySQL.query.await('SELECT plate, model, garage, financed FROM player_vehicles WHERE citizenid = ? ORDER BY id DESC', { Player.PlayerData.citizenid })
    return vehicles or {}
end)

RegisterNetEvent('dealership:server:makeFinancePayment', function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, Player.PlayerData.citizenid })
    if not vehicle or vehicle.financed ~= 1 then
        Wrappers.Notify(src, 'Financing', 'Vehicle not found or not financed', 'error')
        return
    end

    local bank = Player.PlayerData.money.bank
    if bank < vehicle.finance_weekly then
        Wrappers.Notify(src, 'Financing', 'Insufficient funds for weekly payment: $' .. vehicle.finance_weekly, 'error')
        return
    end

    Player.Functions.RemoveMoney('bank', vehicle.finance_weekly, 'finance-payment')
    local newPayments = vehicle.finance_payments + 1
    local newRemaining = vehicle.finance_total - (vehicle.finance_weekly * newPayments)

    if newRemaining <= 0 then
        MySQL.update.await('UPDATE player_vehicles SET financed = 0, finance_payments = ?, finance_total = 0, finance_weekly = 0 WHERE plate = ?', { newPayments, plate })
        Wrappers.Notify(src, 'Financing', 'Vehicle paid off! It is now fully yours.', 'success')
    else
        MySQL.update.await('UPDATE player_vehicles SET finance_payments = ? WHERE plate = ?', { newPayments, plate })
        Wrappers.Notify(src, 'Financing', 'Payment made. Remaining: $' .. newRemaining, 'success')
    end
end)

RegisterNetEvent('dealership:server:payoffFinancedVehicle', function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, Player.PlayerData.citizenid })
    if not vehicle or vehicle.financed ~= 1 then
        Wrappers.Notify(src, 'Financing', 'Vehicle not found or not financed', 'error')
        return
    end

    local remaining = vehicle.finance_total - (vehicle.finance_weekly * vehicle.finance_payments)
    if remaining <= 0 then
        MySQL.update.await('UPDATE player_vehicles SET financed = 0 WHERE plate = ?', { plate })
        Wrappers.Notify(src, 'Financing', 'Vehicle already paid off!', 'success')
        return
    end

    local penalty = math.floor(remaining * Config.Dealership.Financing.EarlyPayoffPenalty)
    local totalDue = remaining + penalty
    local bank = Player.PlayerData.money.bank

    if bank < totalDue then
        Wrappers.Notify(src, 'Financing', 'Need $' .. totalDue .. ' to pay off (incl. early payoff fee). Balance: $' .. bank, 'error')
        return
    end

    Player.Functions.RemoveMoney('bank', totalDue, 'finance-payoff')
    MySQL.update.await('UPDATE player_vehicles SET financed = 0, finance_payments = finance_payments + 1, finance_total = 0, finance_weekly = 0 WHERE plate = ?', { plate })
    Wrappers.Notify(src, 'Financing', 'Vehicle paid off! Early payoff fee: $' .. penalty, 'success')
end)

QBCore.Commands.Add('dealership', 'Open vehicle dealership menu', {}, false, function(source)
    TriggerClientEvent('dealership:client:openMenu', source)
end)
