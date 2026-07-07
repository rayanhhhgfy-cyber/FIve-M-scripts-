local atmZones = {}

Citizen.CreateThread(function()
    for i, coords in ipairs(Config.BankingPlus.atmLocations) do
        exports['ox_target']:addBoxZone({
            coords = coords,
            size = vector3(1.0, 1.0, 2.0),
            rotation = 0,
            debug = false,
            options = {
                { label = 'Send Money', icon = 'fas fa-paper-plane', onSelect = function() OpenSendMoney() end },
                { label = 'Apply for Loan', icon = 'fas fa-hand-holding-usd', onSelect = function() OpenLoanMenu() end },
                { label = 'Investments', icon = 'fas fa-chart-line', onSelect = function() OpenInvestmentMenu() end },
                { label = 'Credit Score', icon = 'fas fa-star', onSelect = function() CheckCreditScore() end },
                { label = 'Transaction History', icon = 'fas fa-history', onSelect = function() ShowTransactionHistory() end },
                { label = 'Rob ATM [Criminal]', icon = 'fas fa-mask', onSelect = function()
                    local input = Wrappers.InputDialog({ title = 'Rob ATM', options = {
                        { type = 'select', label = 'Confirm', options = { { value = 'yes', label = 'Yes, rob this ATM' } } },
                    }})
                    if input then
                        Wrappers.ProgressBar({ label = 'Hacking ATM...', duration = Config.BankingPlus.atmRobbery.hackTime, onFinish = function()
                            TriggerServerEvent('banking:atmRobbery', i)
                        end })
                    end
                end },
            },
        })
    end
end)

function OpenSendMoney()
    local input = Wrappers.InputDialog({ title = 'Send Money', options = {
        { type = 'input', label = 'Player Server ID', placeholder = 'e.g. 5' },
        { type = 'input', label = 'Amount', placeholder = 'e.g. 1000' },
    }})
    if input then
        local targetId = tonumber(input[1])
        local amount = tonumber(input[2])
        if targetId and amount and amount > 0 then
            TriggerServerEvent('banking:sendMoney', targetId, amount)
        end
    end
end

function OpenLoanMenu()
    local items = {}
    for id, def in pairs(Config.BankingPlus.loans.types) do
        table.insert(items, { title = def.label or id:gsub('^%l', string.upper), description = '$' .. def.minAmount .. '-$' .. def.maxAmount .. ' @ ' .. (def.interestRate * 100) .. '%', onSelect = function()
            local input = Wrappers.InputDialog({ title = 'Apply for ' .. id:gsub('^%l', string.upper) .. ' Loan', options = {
                { type = 'input', label = 'Amount', placeholder = '$' .. def.minAmount .. '-$' .. def.maxAmount },
            }})
            if input then
                local amt = tonumber(input[1])
                if amt then TriggerServerEvent('banking:applyLoan', id, amt) end
            end
        end })
    end
    Wrappers.ContextMenu({ id = 'loan_menu', title = 'Loan Options', menuItems = items })
end

function OpenInvestmentMenu()
    local items = {}
    for _, def in ipairs(Config.BankingPlus.investments.types) do
        table.insert(items, { title = def.name .. ' [' .. def.risk:gsub('^%l', string.upper) .. ' Risk]', description = 'Min: $' .. def.minAmount .. ', ' .. def.duration .. 'd term', onSelect = function()
            local input = Wrappers.InputDialog({ title = 'Invest in ' .. def.name, options = {
                { type = 'input', label = 'Amount (min $' .. def.minAmount .. ')', placeholder = 'e.g. 10000' },
            }})
            if input then
                local amt = tonumber(input[1])
                if amt then TriggerServerEvent('banking:invest', def.id, amt) end
            end
        end })
    end
    table.insert(items, { title = 'My Investments', icon = 'fas fa-folder-open', onSelect = function() ShowMyInvestments() end })
    Wrappers.ContextMenu({ id = 'invest_menu', title = 'Investment Options', menuItems = items })
end

function ShowMyInvestments()
    QBox.Functions.TriggerCallback('banking:getLoans', function(loans)
        local items = {}
        for _, inv in ipairs(loans) do
            if inv.status == 'active' then
                table.insert(items, { title = 'Investment #' .. inv.id .. ': $' .. inv.amount, description = 'Status: ' .. inv.status, onSelect = function()
                    TriggerServerEvent('banking:withdrawInvestment', inv.id)
                end })
            end
        end
        if #items == 0 then Wrappers.Notify('No active investments', 'info') return end
        Wrappers.ContextMenu({ id = 'my_investments', title = 'My Investments', menuItems = items })
    end)
end

function CheckCreditScore()
    QBox.Functions.TriggerCallback('banking:getCreditScore', function(score)
        Wrappers.Notify('Credit Score: ' .. score .. '/999', 'info')
    end)
end

function ShowTransactionHistory()
    QBox.Functions.TriggerCallback('banking:getTransactionHistory', function(rows)
        if not rows or #rows == 0 then
            Wrappers.Notify('No transactions', 'info')
            return
        end
        local items = {}
        for _, t in ipairs(rows) do
            local label = t.type:gsub('_', ' '):gsub('^%l', string.upper)
            local desc = '$' .. t.amount
            if t.fee and t.fee > 0 then desc = desc .. ' (fee: $' .. t.fee .. ')' end
            table.insert(items, { title = label .. ': ' .. desc, description = t.created_at or '' })
        end
        Wrappers.ContextMenu({ id = 'transaction_history', title = 'Recent Transactions', menuItems = items })
    end)
end
