local QBCore = exports['qbx_core']:GetCoreObject()
local currentAccountId = nil

local function OpenBankMenu()
    local accounts = lib.callback.await('Renewed-Banking:server:getAccounts', false)
    local options = {}
    for _, account in ipairs(accounts) do
        table.insert(options, {
            title = account.account_name,
            description = string.format('%s | $%s | IBAN: %s', account.account_type, account.balance, account.iban),
            icon = 'fas fa-piggy-bank',
            metadata = { id = account.id },
            onSelect = function()
                currentAccountId = account.id
                ShowAccountMenu(account)
            end
        })
    end
    table.insert(options, {
        title = 'Create New Account',
        icon = 'fas fa-plus-circle',
        onSelect = function()
            local input = lib.inputDialog('Create Account', {
                { type = 'input', label = 'Account Name', placeholder = 'My Account', required = true },
                { type = 'select', label = 'Account Type', options = {
                    { value = 'personal', label = 'Personal' },
                    { value = 'savings', label = 'Savings' },
                    { value = 'joint', label = 'Joint' },
                    { value = 'corporate', label = 'Corporate' }
                }, default = 'personal' }
            })
            if input then
                local success, msg = lib.callback.await('Renewed-Banking:server:createAccount', false, input[1], input[2])
                Wrappers.Notify({ type = success and 'success' or 'error', description = msg or 'Account created' })
            end
        end
    })
    lib.registerContext({
        id = 'bank_menu',
        title = 'Bank Accounts',
        options = options
    })
    lib.showContext('bank_menu')
end

local function ShowAccountMenu(account)
    local transactions = lib.callback.await('Renewed-Banking:server:getTransactions', false, account.id)
    local options = {
        {
            title = string.format('Balance: $%s', account.balance),
            description = string.format('Account: %s | IBAN: %s', account.account_name, account.iban),
            icon = 'fas fa-wallet',
            readOnly = true
        },
        {
            title = 'Deposit Cash',
            icon = 'fas fa-arrow-down',
            onSelect = function()
                local input = lib.inputDialog('Deposit', {
                    { type = 'number', label = 'Amount', placeholder = '0', required = true, min = 1, max = Config.Banking.maxDepositAmount }
                })
                if input then
                    local success = lib.callback.await('Renewed-Banking:server:deposit', false, account.id, tonumber(input[1]), 'ATM Deposit')
                    if not success then
                        Wrappers.Notify({ type = 'error', description = 'Deposit failed' })
                    end
                end
            end
        },
        {
            title = 'Withdraw Cash',
            icon = 'fas fa-arrow-up',
            onSelect = function()
                local input = lib.inputDialog('Withdraw', {
                    { type = 'number', label = 'Amount', placeholder = '0', required = true, min = 1, max = Config.Banking.maxWithdrawAmount }
                })
                if input then
                    local success = lib.callback.await('Renewed-Banking:server:withdraw', false, account.id, tonumber(input[1]), 'ATM Withdrawal')
                    if not success then
                        Wrappers.Notify({ type = 'error', description = 'Withdrawal failed' })
                    end
                end
            end
        },
        {
            title = 'Transfer Funds',
            icon = 'fas fa-exchange-alt',
            onSelect = function()
                local input = lib.inputDialog('Transfer', {
                    { type = 'input', label = 'Target IBAN', placeholder = 'LS00FIV...', required = true },
                    { type = 'number', label = 'Amount', placeholder = '0', required = true, min = 1 },
                    { type = 'input', label = 'Reason (Optional)', placeholder = 'Payment', required = false }
                })
                if input then
                    local success, msg = lib.callback.await('Renewed-Banking:server:transfer', false, account.id, input[1], tonumber(input[2]), input[3] or 'Transfer')
                    Wrappers.Notify({ type = success and 'success' or 'error', description = msg or 'Transfer complete' })
                end
            end
        },
        {
            title = 'Transaction History',
            icon = 'fas fa-history',
            onSelect = function()
                local txOptions = {}
                for _, tx in ipairs(transactions or {}) do
                    table.insert(txOptions, {
                        title = string.format('%s: $%s', tx.type, tx.amount),
                        description = string.format('%s | %s', tx.reason or '', tx.target or ''),
                        readOnly = true
                    })
                end
                if #txOptions == 0 then
                    table.insert(txOptions, { title = 'No transactions', readOnly = true })
                end
                lib.registerContext({
                    id = 'bank_tx_menu',
                    title = 'Transaction History',
                    options = txOptions,
                    onBack = function() ShowAccountMenu(account) end
                })
                lib.showContext('bank_tx_menu')
            end
        }
    }
    lib.registerContext({
        id = 'bank_account_menu',
        title = account.account_name,
        options = options,
        onBack = function() OpenBankMenu() end
    })
    lib.showContext('bank_account_menu')
end

RegisterNetEvent('Renewed-Banking:client:openBank', function()
    OpenBankMenu()
end)

RegisterNetEvent('Renewed-Banking:client:openATM', function()
    OpenBankMenu()
end)

exports('OpenBanking', OpenBankMenu)
