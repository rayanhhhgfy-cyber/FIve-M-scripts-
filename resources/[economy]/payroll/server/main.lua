local QBox = exports['qbx-core']:GetCoreObject()
local currentGameDay = 0
local gameDayInitialized = false

--- Load current game day from DB
local function loadGameDay()
    local rows = MySQL.scalar.await('SELECT value FROM payroll_config WHERE `key` = ?', { 'current_game_day' })
    if rows then
        currentGameDay = tonumber(rows) or 0
    else
        MySQL.insert.await('INSERT INTO payroll_config (`key`, value) VALUES (?, ?)', { 'current_game_day', '0' })
        currentGameDay = 0
    end
    gameDayInitialized = true
    print(('^2[Payroll] Current game day loaded: %d^7'):format(currentGameDay))
end

--- Save current game day to DB
local function saveGameDay()
    MySQL.update.await('UPDATE payroll_config SET value = ? WHERE `key` = ?', { tostring(currentGameDay), 'current_game_day' })
end

--- Increment game day and trigger payday checks
local function advanceGameDay()
    currentGameDay = currentGameDay + 1
    saveGameDay()
    print(('^3[Payroll] Game day advanced to %d^7'):format(currentGameDay))
    checkAllPlayersPayday()
end

--- Get salary for a job+grade
local function getSalary(jobName, grade)
    local jobConfig = Config.Payroll.Jobs[jobName]
    if not jobConfig then return 0 end
    for _, level in ipairs(jobConfig) do
        if level.grade == grade then
            return level.salary
        end
    end
    return 0
end

--- Get job label for notification
local function getJobLabel(jobName)
    local labels = {
        ['police'] = 'LSPD',
        ['cid'] = 'CID',
        ['ambulance'] = 'EMS',
    }
    return labels[jobName] or jobName
end

--- Get grade label for notification
local function getGradeLabel(jobName, grade)
    local jobConfig = Config.Payroll.Jobs[jobName]
    if not jobConfig then return 'Unknown' end
    for _, level in ipairs(jobConfig) do
        if level.grade == grade then
            return level.label
        end
    end
    return 'Unknown'
end

--- Process payday for a single player
local function processPayday(player)
    local citizenid = player.PlayerData.citizenid
    local jobName = player.PlayerData.job.name
    local grade = player.PlayerData.job.grade

    local salary = getSalary(jobName, grade)
    if salary <= 0 then return end

    -- Update last payday in DB
    local existing = MySQL.scalar.await('SELECT id FROM player_payrolls WHERE citizenid = ?', { citizenid })
    if existing then
        MySQL.update.await('UPDATE player_payrolls SET last_payday_game_day = ?, last_paid_at = NOW() WHERE citizenid = ?', { currentGameDay, citizenid })
    else
        MySQL.insert.await('INSERT INTO player_payrolls (citizenid, last_payday_game_day, last_paid_at) VALUES (?, ?, NOW())', { citizenid, currentGameDay })
    end

    -- Deposit salary into bank
    player.Functions.AddMoney('bank', salary, 'payroll')
    local src = player.PlayerData.source

    -- Phone notification
    local jobLabel = getJobLabel(jobName)
    local gradeLabel = getGradeLabel(jobName, grade)

    TriggerClientEvent('payroll:client:paydayNotification', src, jobLabel, gradeLabel, salary)
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        title = 'PAYDAY',
        description = ('$%s deposited — %s (%s)'):format(salary, jobLabel, gradeLabel),
    })
end

--- Check all online players for payday eligibility
local function checkAllPlayersPayday()
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local player = QBox.Functions.GetPlayer(src)
        if player then
            local citizenid = player.PlayerData.citizenid
            local jobName = player.PlayerData.job.name
            local grade = player.PlayerData.job.grade
            local salary = getSalary(jobName, grade)
            if salary > 0 then
                local row = MySQL.single.await('SELECT last_payday_game_day FROM player_payrolls WHERE citizenid = ?', { citizenid })
                local lastPayday = (row and row.last_payday_game_day) or 0
                if currentGameDay - lastPayday >= Config.Payroll.GameDayInterval then
                    processPayday(player)
                end
            end
        end
    end
end

--- Check payday for a specific player on join
local function checkPlayerPayday(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    local jobName = player.PlayerData.job.name
    local grade = player.PlayerData.job.grade
    local salary = getSalary(jobName, grade)
    if salary <= 0 then return end

    local row = MySQL.single.await('SELECT last_payday_game_day FROM player_payrolls WHERE citizenid = ?', { citizenid })
    local lastPayday = (row and row.last_payday_game_day) or 0

    if currentGameDay - lastPayday >= Config.Payroll.GameDayInterval then
        processPayday(player)
    end
end

--- Client syncs game time on join — used to detect offline day progression
RegisterNetEvent('payroll:server:syncGameTime', function(hour, minute)
    local src = source
    if not src then return end
end)

--- Client reports a new game day
RegisterNetEvent('payroll:server:gameDayPassed', function()
    if not gameDayInitialized then return end
    advanceGameDay()
end)

--- On player join, check if payday is due
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    Citizen.SetTimeout(5000, function()
        checkPlayerPayday(src)
    end)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    loadGameDay()

    -- Run catch-up check for already connected players
    Citizen.SetTimeout(10000, function()
        checkAllPlayersPayday()
    end)
end)
