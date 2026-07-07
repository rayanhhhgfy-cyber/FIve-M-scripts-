local QBox = exports['qbx-core']:GetCoreObject()

--- Get player's primary bank account
local function getPrimaryAccount(citizenid)
    local accounts = exports['Renewed-Banking']:GetAccounts(citizenid)
    if accounts and #accounts > 0 then
        return accounts[1]
    end
    return nil
end

lib.callback.register('atm-card:server:getAccounts', function(source)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return {} end
    return exports['Renewed-Banking']:GetAccounts(player.PlayerData.citizenid) or {}
end)

lib.callback.register('atm-card:server:deposit', function(source, accountId, amount)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return false, 'Invalid amount' end
    if amount > Config.ATM.MaxDeposit then return false, 'Deposit limit exceeded' end
    if player.PlayerData.money.cash < amount then return false, 'Not enough cash' end

    local success, newBalance = exports['Renewed-Banking']:Deposit(accountId, amount, 'ATM Deposit')
    if success then
        player.Functions.RemoveMoney('cash', amount)
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', title = 'ATM', description = ('Deposited $%s | Balance: $%s'):format(amount, newBalance) })
        return true, newBalance
    end
    return false, 'Transaction failed'
end)

lib.callback.register('atm-card:server:withdraw', function(source, accountId, amount)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return false, 'Invalid amount' end
    if amount > Config.ATM.MaxWithdraw then return false, 'Withdrawal limit exceeded' end

    -- Apply ATM fee
    local total = amount + Config.ATM.WithdrawFee

    local success, newBalance = exports['Renewed-Banking']:Withdraw(accountId, total, 'ATM Withdrawal')
    if success then
        player.Functions.AddMoney('cash', amount)
        if Config.ATM.WithdrawFee > 0 then
            TriggerClientEvent('ox_lib:notify', source, { type = 'info', title = 'ATM', description = ('Fee: $%s'):format(Config.ATM.WithdrawFee) })
        end
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', title = 'ATM', description = ('Withdrew $%s | Balance: $%s'):format(amount, newBalance) })
        return true, newBalance
    end
    return false, 'Insufficient funds'
end)
