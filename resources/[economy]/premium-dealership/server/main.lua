local QBox = exports['qbx-core']:GetCoreObject()

local function generatePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local plate = 'PD'
    for i = 1, 6 do
        plate = plate .. chars:sub(math.random(#chars), math.random(#chars))
    end
    return plate
end

--- Buy a vehicle from dealership
RegisterNetEvent('dealership:server:buyVehicle', function(data)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local vehicleData = data.vehicleData
    local plate = data.plate or generatePlate()
    local paymentType = data.paymentType or 'cash'
    local financeWeeks = data.financeWeeks or 0

    if not vehicleData or not vehicleData.model then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Invalid vehicle data' })
        return
    end

    local totalPrice = vehicleData.price
    local tradeInValue = data.tradeInValue or 0
    local finalPrice = math.max(0, totalPrice - tradeInValue)

    if paymentType == 'cash' then
        local cash = player.PlayerData.money.cash or 0
        if cash < finalPrice then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough cash. Need $' .. finalPrice .. ', have $' .. cash })
            return
        end
        player.Functions.RemoveMoney('cash', finalPrice, 'dealership-purchase')
    elseif paymentType == 'bank' then
        local bank = player.PlayerData.money.bank or 0
        if bank < finalPrice then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough bank balance. Need $' .. finalPrice .. ', have $' .. bank })
            return
        end
        player.Functions.RemoveMoney('bank', finalPrice, 'dealership-purchase')
    elseif paymentType == 'finance' then
        local weekly = math.ceil((finalPrice * Config.PremiumDealership.FinanceInterestRate) / financeWeeks)
        player.Functions.RemoveMoney('bank', math.ceil(finalPrice * 0.1), 'dealership-finance-deposit')
        local depositPaid = math.ceil(finalPrice * 0.1)
        MySQL.insert('INSERT INTO bank_loans (citizenid, loan_type, amount, interest, total_repayment, weekly_payment, remaining, term_days, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            player.PlayerData.citizenid, 'vehicle_finance', finalPrice - depositPaid, 5, finalPrice, weekly, finalPrice - depositPaid, financeWeeks * 7, 'active'
        })
    end

    local vehicleJson = json.encode({
        model = vehicleData.model,
        label = vehicleData.label,
        price = totalPrice,
        tradeIn = tradeInValue,
        paid = finalPrice,
        paymentType = paymentType,
    })

    exports['qbx-core']:CreateVehicle(vehicleData.model, plate, nil, false, function(created)
        if created then
            -- Update plate on the players_vehicles entry
            MySQL.update('UPDATE player_vehicles SET plate = ?, model_data = ? WHERE plate = ? AND citizenid = ?', {
                plate, vehicleJson, plate, player.PlayerData.citizenid
            })
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Purchased ' .. vehicleData.label .. ' for $' .. finalPrice .. ' [' .. plate .. ']' })
            TriggerClientEvent('dealership:client:purchaseComplete', src, plate)
        else
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Failed to create vehicle' })
        end
    end)
end)

--- Sell vehicle to dealership
RegisterNetEvent('dealership:server:sellVehicle', function(plate)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    MySQL.query('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, player.PlayerData.citizenid }, function(vehicles)
        if not vehicles or #vehicles == 0 then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Vehicle not found in your garage' })
            return
        end

        local modelData = vehicles[1].model_data
        local price = 50000
        if modelData then
            local md = json.decode(modelData)
            if md and md.price then
                price = math.floor(md.price * Config.PremiumDealership.TradeInMultiplier)
            end
        end

        MySQL.update('DELETE FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, player.PlayerData.citizenid })
        player.Functions.AddMoney('bank', price, 'dealership-sale')
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Sold vehicle ' .. plate .. ' for $' .. price })
    end)
end)

--- Get player's owned vehicles for trade-in
QBox.Functions.CreateCallback('dealership:server:getOwnedVehicles', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then cb({}) return end

    MySQL.query('SELECT plate, model, model_data FROM player_vehicles WHERE citizenid = ?', { player.PlayerData.citizenid }, function(vehicles)
        cb(vehicles or {})
    end)
end)

--- Calc trade-in value
QBox.Functions.CreateCallback('dealership:server:calcTradeIn', function(source, cb, plate)
    local player = QBox.Functions.GetPlayer(source)
    if not player then cb(0) return end

    MySQL.query('SELECT model_data FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, player.PlayerData.citizenid }, function(vehicles)
        if not vehicles or #vehicles == 0 then cb(0) return end
        local modelData = vehicles[1].model_data
        local price = 50000
        if modelData then
            local md = json.decode(modelData)
            if md and md.price then
                price = math.floor(md.price * Config.PremiumDealership.TradeInMultiplier)
            end
        end
        cb(price)
    end)
end)

--- Check plate availability
QBox.Functions.CreateCallback('dealership:server:checkPlate', function(source, cb, plate)
    MySQL.query('SELECT id FROM player_vehicles WHERE plate = ?', { plate }, function(vehicles)
        cb(not vehicles or #vehicles == 0)
    end)
end)
