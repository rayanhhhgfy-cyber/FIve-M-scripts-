local QBox = exports['qbx_core']:GetCoreObject()
local creditScores = {}
local activeLoans = {}
local activeInvestments = {}
local transferLimits = {}
local atmCooldowns = {}
local dailyTransfers = {}

local function isAdmin(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    for _, g in ipairs(Config.BankingPlus.adminGroups) do
        if p.PlayerData.group == g then return true end
    end
    return false
end

local function getCreditScore(cid)
    if creditScores[cid] then return creditScores[cid] end
    local row = MySQL.query.await('SELECT score FROM bank_credit_scores WHERE citizenid = ?', { cid })
    if row and row[1] then
        creditScores[cid] = row[1].score
        return row[1].score
    end
    MySQL.insert('INSERT INTO bank_credit_scores (citizenid, score) VALUES (?, ?)', { cid, Config.BankingPlus.creditScore.startingScore })
    creditScores[cid] = Config.BankingPlus.creditScore.startingScore
    return Config.BankingPlus.creditScore.startingScore
end

local function updateCreditScore(cid, delta)
    local current = getCreditScore(cid)
    local newScore = math.max(Config.BankingPlus.creditScore.minScore, math.min(Config.BankingPlus.creditScore.maxScore, current + delta))
    creditScores[cid] = newScore
    MySQL.update('UPDATE bank_credit_scores SET score = ? WHERE citizenid = ?', { newScore, cid })
    return newScore
end

local function notifyPolice(message)
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local p = QBox.Functions.GetPlayer(src)
        if p and p.PlayerData.job.name == 'police' and p.PlayerData.job.onduty then
            TriggerClientEvent('ox_lib:notify', src, { type = 'warning', description = message })
        end
    end
end

MySQL.ready(function()
    local loans = MySQL.query.await('SELECT * FROM bank_loans WHERE status = ?', { 'active' })
    for _, l in ipairs(loans) do
        activeLoans[l.id] = l
    end
    local invs = MySQL.query.await('SELECT * FROM bank_investments WHERE status = ?', { 'active' })
    for _, inv in ipairs(invs) do
        activeInvestments[inv.id] = inv
    end
end)

--- Send money between players
RegisterNetEvent('banking:sendMoney', function(targetSrc, amount)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    local cid = p.PlayerData.citizenid
    local today = os.date('%Y-%m-%d')
    if not dailyTransfers[cid] then dailyTransfers[cid] = {} end
    if not dailyTransfers[cid][today] then dailyTransfers[cid][today] = 0 end
    if dailyTransfers[cid][today] + amount > Config.BankingPlus.dailyTransferLimit then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Daily transfer limit exceeded ($' .. Config.BankingPlus.dailyTransferLimit .. ')' })
        return
    end
    local fee = math.floor(amount * Config.BankingPlus.transferFeePercent)
    local total = amount + fee
    if not p.Functions.RemoveMoney('bank', total) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient funds (needs $' .. total .. ' with fee)' })
        return
    end
    target.Functions.AddMoney('bank', amount)
    dailyTransfers[cid][today] = dailyTransfers[cid][today] + amount
    MySQL.insert('INSERT INTO bank_transactions (sender_cid, receiver_cid, amount, fee, type) VALUES (?, ?, ?, ?, ?)', { cid, target.PlayerData.citizenid, amount, fee, 'transfer' })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Sent $' .. amount .. ' (' .. target.PlayerData.charinfo.firstname .. ')' })
    TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'success', description = 'Received $' .. amount .. ' from ' .. p.PlayerData.charinfo.firstname })
end)

--- Credit score
QBox.Functions.CreateCallback('banking:getCreditScore', function(source, cb)
    local p = QBox.Functions.GetPlayer(source)
    if not p then cb(0) return end
    cb(getCreditScore(p.PlayerData.citizenid))
end)

--- Loan application
RegisterNetEvent('banking:applyLoan', function(loanType, amount)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    local loanDef = Config.BankingPlus.loans.types[loanType]
    if not loanDef then return end
    if amount < loanDef.minAmount or amount > loanDef.maxAmount then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Amount must be $' .. loanDef.minAmount .. '-$' .. loanDef.maxAmount })
        return
    end
    local score = getCreditScore(cid)
    if score < 400 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Credit score too low (' .. score .. '/999)' })
        return
    end
    local totalOwed = 0
    for _, l in pairs(activeLoans) do
        if l.citizenid == cid and l.status == 'active' then
            totalOwed = totalOwed + l.remaining
        end
    end
    if totalOwed > 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You have outstanding loans ($' .. totalOwed .. ')' })
        return
    end
    local interest = math.floor(amount * loanDef.interestRate)
    local totalRepayment = amount + interest
    local weeklyPayment = math.ceil(totalRepayment / (loanDef.termDays / 7))
    local id = MySQL.insert.await('INSERT INTO bank_loans (citizenid, loan_type, amount, interest, total_repayment, weekly_payment, term_days, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        { cid, loanType, amount, interest, totalRepayment, weeklyPayment, loanDef.termDays, 'active' })
    activeLoans[id] = { id = id, citizenid = cid, loan_type = loanType, amount = amount, interest = interest, total_repayment = totalRepayment, weekly_payment = weeklyPayment, term_days = loanDef.termDays, status = 'active', remaining = totalRepayment }
    p.Functions.AddMoney('bank', amount)
    updateCreditScore(cid, -10)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Loan approved! $' .. amount .. ' deposited. $' .. weeklyPayment .. '/wk for ' .. (loanDef.termDays / 7) .. ' weeks' })
end)

QBox.Functions.CreateCallback('banking:getLoans', function(source, cb)
    local p = QBox.Functions.GetPlayer(source)
    if not p then cb({}) return end
    local result = {}
    for _, l in pairs(activeLoans) do
        if l.citizenid == p.PlayerData.citizenid then
            table.insert(result, l)
        end
    end
    cb(result)
end)

--- Investments
RegisterNetEvent('banking:invest', function(investTypeId, amount)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local invDef = nil
    for _, t in ipairs(Config.BankingPlus.investments.types) do
        if t.id == investTypeId then invDef = t; break end
    end
    if not invDef then return end
    if amount < invDef.minAmount then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Minimum investment: $' .. invDef.minAmount })
        return
    end
    if not p.Functions.RemoveMoney('bank', amount) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient funds' })
        return
    end
    local id = MySQL.insert.await('INSERT INTO bank_investments (citizenid, invest_type, amount, duration, status) VALUES (?, ?, ?, ?, ?)', { p.PlayerData.citizenid, investTypeId, amount, invDef.duration, 'active' })
    activeInvestments[id] = { id = id, citizenid = p.PlayerData.citizenid, invest_type = investTypeId, amount = amount, duration = invDef.duration, status = 'active', created_at = os.time() }
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Invested $' .. amount .. ' in ' .. invDef.name })
end)

RegisterNetEvent('banking:withdrawInvestment', function(investId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local inv = activeInvestments[investId]
    if not inv or inv.citizenid ~= p.PlayerData.citizenid then return end
    local invDef = nil
    for _, t in ipairs(Config.BankingPlus.investments.types) do
        if t.id == inv.invest_type then invDef = t; break end
    end
    if not invDef then return end
    local elapsed = os.time() - inv.created_at
    local daysElapsed = elapsed / 86400
    local returnMultiplier = 1.0
    if daysElapsed >= invDef.duration then
        local r = invDef.minReturn + math.random() * (invDef.maxReturn - invDef.minReturn)
        returnMultiplier = 1.0 + r
    else
        returnMultiplier = 1.0 - Config.BankingPlus.investments.withdrawalFeePercent
    end
    local payout = math.floor(inv.amount * returnMultiplier)
    p.Functions.AddMoney('bank', payout)
    activeInvestments[investId] = nil
    MySQL.update('UPDATE bank_investments SET status = ?, payout = ? WHERE id = ?', { 'withdrawn', payout, investId })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Withdrew $' .. payout .. ' (return: ' .. math.floor((returnMultiplier - 1.0) * 100) .. '%)' })
end)

--- ATM robbery
RegisterNetEvent('banking:atmRobbery', function(atmIndex)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    if atmCooldowns[cid] and atmCooldowns[cid] > os.time() then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Wait ' .. math.ceil((atmCooldowns[cid] - os.time()) / 60) .. 'm' })
        return
    end
    if math.random() < Config.BankingPlus.atmRobbery.policeNotifyChance then
        notifyPolice('ATM robbery in progress at ' .. GetStreetNameFromHashKey(GetStreetNameAtCoord(table.unpack(Config.BankingPlus.atmLocations[atmIndex]))))
    end
    local loot = math.random(Config.BankingPlus.atmRobbery.minLoot, Config.BankingPlus.atmRobbery.maxLoot)
    p.Functions.AddMoney('cash', loot)
    atmCooldowns[cid] = os.time() + Config.BankingPlus.atmRobbery.cooldown
    MySQL.insert('INSERT INTO bank_transactions (sender_cid, amount, type) VALUES (?, ?, ?)', { cid, loot, 'atm_robbery' })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Stole $' .. loot .. ' from ATM' })
end)

--- Transfer history
QBox.Functions.CreateCallback('banking:getTransactionHistory', function(source, cb)
    local p = QBox.Functions.GetPlayer(source)
    if not p then cb({}) return end
    local rows = MySQL.query.await('SELECT * FROM bank_transactions WHERE sender_cid = ? OR receiver_cid = ? ORDER BY created_at DESC LIMIT 20',
        { p.PlayerData.citizenid, p.PlayerData.citizenid })
    cb(rows or {})
end)

--- Process weekly loan payments (called by server scheduler)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(604800000) -- 7 days
        for id, loan in pairs(activeLoans) do
            if loan.status == 'active' then
                local p = QBox.Functions.GetPlayerByCitizenId(loan.citizenid)
                if p then
                    if p.Functions.RemoveMoney('bank', loan.weekly_payment) then
                        loan.remaining = loan.remaining - loan.weekly_payment
                        MySQL.update('UPDATE bank_loans SET remaining = ? WHERE id = ?', { loan.remaining, id })
                        updateCreditScore(loan.citizenid, Config.BankingPlus.creditScore.onTimePayment)
                        if loan.remaining <= 0 then
                            loan.status = 'paid'
                            MySQL.update('UPDATE bank_loans SET status = ? WHERE id = ?', { 'paid', id })
                        end
                    else
                        local lateFee = math.floor(loan.weekly_payment * Config.BankingPlus.loans.lateFeePercent)
                        loan.remaining = loan.remaining + lateFee
                        MySQL.update('UPDATE bank_loans SET remaining = ? WHERE id = ?', { loan.remaining, id })
                        updateCreditScore(loan.citizenid, Config.BankingPlus.loans.missedPaymentPenalty)
                        p.Functions.AddMoney('bank', 0) -- notify of missed payment
                    end
                else
                    updateCreditScore(loan.citizenid, Config.BankingPlus.loans.missedPaymentPenalty)
                end
            end
        end
    end
end)
