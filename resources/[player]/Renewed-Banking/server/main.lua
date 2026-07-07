local QBCore = exports['qbx_core']:GetCoreObject()
local bankAccounts = {}
local accountCache = {}

function GenerateIBAN()
    local country = 'LS'
    local checksum = string.format('%02d', math.random(99))
    local bankCode = 'FIV'
    local accountNum = string.format('%010d', math.random(9999999999))
    return country .. checksum .. bankCode .. accountNum
end

function GetAccounts(citizenId)
    if accountCache[citizenId] then
        local age = GetGameTimer() - accountCache[citizenId].timestamp
        if age < 30000 then
            return accountCache[citizenId].accounts
        end
    end
    local result = MySQL.query.await('SELECT * FROM bank_accounts WHERE citizenid = ?', { citizenId })
    local accounts = result or {}
    accountCache[citizenId] = { accounts = accounts, timestamp = GetGameTimer() }
    return accounts
end

function GetAccount(accountId)
    local result = MySQL.query.await('SELECT * FROM bank_accounts WHERE id = ? LIMIT 1', { accountId })
    if result and #result > 0 then return result[1] end
    return nil
end

local function GetTransactions(accountId, limit)
    limit = limit or Config.Banking.maxTransactionLogs
    local result = MySQL.query.await(
        'SELECT * FROM bank_transactions WHERE account_id = ? ORDER BY timestamp DESC LIMIT ?',
        { accountId, limit }
    )
    return result or {}
end

local function AddTransaction(accountId, citizenId, transactionType, amount, reason, target)
    MySQL.insert.await(
        'INSERT INTO bank_transactions (account_id, citizenid, type, amount, reason, target) VALUES (?, ?, ?, ?, ?, ?)',
        { accountId, citizenId, transactionType, amount, reason or '', target or '' }
    )
    TriggerEvent('discord-logs:server:logBank', citizenId, transactionType, amount, reason or '')
end

local function UpdateBalance(accountId, newBalance)
    MySQL.update.await('UPDATE bank_accounts SET balance = ? WHERE id = ?', { newBalance, accountId })
end

function CreateAccount(citizenId, accountName, accountType)
    local existing = GetAccounts(citizenId)
    if #existing >= Config.Banking.maxAccounts then
        return false, 'Maximum accounts reached'
    end
    local iban = GenerateIBAN()
    local balance = accountType == 'personal' and Config.Banking.openingBalance or 0
    MySQL.insert.await(
        'INSERT INTO bank_accounts (citizenid, account_name, account_type, iban, balance) VALUES (?, ?, ?, ?, ?)',
        { citizenId, accountName, accountType, iban, balance }
    )
    accountCache[citizenId] = nil
    return true, iban
end

function Deposit(accountId, amount, reason)
    if amount <= 0 or amount > Config.Banking.maxDepositAmount then return false end
    local account = GetAccount(accountId)
    if not account then return false end
    local newBalance = account.balance + amount
    UpdateBalance(accountId, newBalance)
    AddTransaction(accountId, account.citizenid, 'deposit', amount, reason or 'Deposit', '')
    accountCache[account.citizenid] = nil
    return true, newBalance
end

function Withdraw(accountId, amount, reason)
    if amount <= 0 or amount > Config.Banking.maxWithdrawAmount then return false end
    local account = GetAccount(accountId)
    if not account then return false end
    if account.balance < amount then return false, 'Insufficient funds' end
    local newBalance = account.balance - amount
    UpdateBalance(accountId, newBalance)
    AddTransaction(accountId, account.citizenid, 'withdraw', -amount, reason or 'Withdrawal', '')
    accountCache[account.citizenid] = nil
    return true, newBalance
end

function Transfer(fromAccountId, toAccountId, amount, reason)
    if amount <= 0 then return false end
    local fee = math.max(Config.Banking.transferFeeMinimum, math.min(amount * Config.Banking.transferFee, Config.Banking.transferFeeMaximum))
    local totalDeduct = amount + fee
    local fromAccount = GetAccount(fromAccountId)
    if not fromAccount then return false, 'Source account not found' end
    if fromAccount.balance < totalDeduct then return false, 'Insufficient funds' end
    local toAccount = GetAccount(toAccountId)
    if not toAccount then return false, 'Target account not found' end
    UpdateBalance(fromAccountId, fromAccount.balance - totalDeduct)
    UpdateBalance(toAccountId, toAccount.balance + amount)
    AddTransaction(fromAccountId, fromAccount.citizenid, 'transfer', -totalDeduct, reason or ('Transfer to ' .. toAccount.iban), toAccount.iban)
    AddTransaction(toAccountId, toAccount.citizenid, 'transfer', amount, reason or ('Transfer from ' .. fromAccount.iban), fromAccount.iban)
    accountCache[fromAccount.citizenid] = nil
    accountCache[toAccount.citizenid] = nil
    if fee > 0 then
        AddTransaction(fromAccountId, 'SYSTEM', 'fee', -fee, 'Transfer fee', '')
    end
    return true, amount
end

lib.callback.register('Renewed-Banking:server:getAccounts', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return {} end
    return GetAccounts(player.PlayerData.citizenid)
end)

lib.callback.register('Renewed-Banking:server:getTransactions', function(source, accountId)
    return GetTransactions(accountId)
end)

lib.callback.register('Renewed-Banking:server:createAccount', function(source, accountName, accountType)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end
    return CreateAccount(player.PlayerData.citizenid, accountName, accountType)
end)

lib.callback.register('Renewed-Banking:server:deposit', function(source, accountId, amount, reason)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    if player.PlayerData.money.cash < amount then return false, 'Not enough cash' end
    player.Functions.RemoveMoney('cash', amount)
    local success, newBalance = Deposit(accountId, amount, reason)
    if success then
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = string.format('Deposited $%s | Balance: $%s', amount, newBalance) })
    end
    return success, newBalance
end)

lib.callback.register('Renewed-Banking:server:withdraw', function(source, accountId, amount, reason)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    local success, newBalance = Withdraw(accountId, amount, reason)
    if success then
        player.Functions.AddMoney('cash', amount)
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = string.format('Withdrew $%s | Balance: $%s', amount, newBalance) })
    end
    return success, newBalance
end)

lib.callback.register('Renewed-Banking:server:transfer', function(source, fromAccountId, targetIban, amount, reason)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end
    local targetResult = MySQL.query.await('SELECT * FROM bank_accounts WHERE iban = ? LIMIT 1', { targetIban })
    if not targetResult or #targetResult == 0 then return false, 'Target account not found' end
    local toAccountId = targetResult[1].id
    local success, result = Transfer(fromAccountId, toAccountId, amount, reason)
    if success then
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = string.format('Transferred $%s to %s', amount, targetIban) })
    end
    return success, result
end)

lib.callback.register('Renewed-Banking:server:getBalance', function(source, accountId)
    local account = GetAccount(accountId)
    if account then return account.balance end
    return 0
end)

RegisterNetEvent('Renewed-Banking:server:paySalary', function(source, amount, reason)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local accounts = GetAccounts(player.PlayerData.citizenid)
    if #accounts == 0 then
        CreateAccount(player.PlayerData.citizenid, 'Primary', 'personal')
        accounts = GetAccounts(player.PlayerData.citizenid)
    end
    if #accounts > 0 then
        Deposit(accounts[1].id, amount, reason or 'Salary')
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Banking.interestInterval)
        if Config.Banking.enableInterest then
            local accounts = MySQL.query.await('SELECT * FROM bank_accounts WHERE account_type = ? OR account_type = ?', { 'personal', 'savings' })
            for _, account in ipairs(accounts or {}) do
                local rate = Config.Banking.interestRate
                if account.account_type == 'savings' then
                    rate = Config.AccountTypes.savings.interestRate or Config.Banking.interestRate
                end
                if account.balance > 0 then
                    local interest = math.floor(account.balance * rate)
                    if interest > 0 then
                        UpdateBalance(account.id, account.balance + interest)
                        AddTransaction(account.id, account.citizenid, 'interest', interest, 'Interest payment', '')
                    end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[Renewed-Banking] Banking system initialized. %d ATM locations mapped.^7', #Config.ATMLocations)
end)

exports('GetAccount', GetAccount)
exports('GetAccounts', GetAccounts)
exports('GetBalance', function(accountId)
    local account = GetAccount(accountId)
    return account and account.balance or 0
end)
exports('Deposit', Deposit)
exports('Withdraw', Withdraw)
exports('Transfer', Transfer)
exports('CreateAccount', CreateAccount)
exports('GenerateIBAN', GenerateIBAN)
