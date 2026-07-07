local QBox = exports['qbx_core']:GetCoreObject()
local activeCases = {}
local caseCounter = 0
local juryPools = {}
local activeTrials = {}

local function isCourtStaff(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    for _, j in pairs(Config.CourtSystem.jobs) do
        if p.PlayerData.job.name == j.label then return true end
    end
    return false
end

RegisterNetEvent('court:fileCase', function(defendantCid, charge, description)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    caseCounter = caseCounter + 1
    local caseId = 'CASE-' .. caseCounter
    activeCases[caseId] = {
        id = caseId,
        prosecutor = p.PlayerData.citizenid,
        prosecutorName = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname,
        defendant = defendantCid,
        charge = charge,
        description = description,
        status = 'filed',
        evidence = {},
        createdAt = os.time(),
    }
    MySQL.insert('INSERT INTO court_cases (case_id, prosecutor_cid, defendant_cid, charge, description, status) VALUES (?, ?, ?, ?, ?, ?)', { caseId, p.PlayerData.citizenid, defendantCid, charge, description, 'filed' })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Case ' .. caseId .. ' filed' })
end)

RegisterNetEvent('court:assignJudge', function(caseId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p or p.PlayerData.job.name ~= 'clerk' then return end
    local case = activeCases[caseId]
    if not case then return end
    local input = Wrappers.InputDialog({ title = 'Assign Judge', options = { { type = 'input', label = 'Judge Citizen ID' } }})
    if not input then return end
    case.judge = input[1]
    case.status = 'assigned'
    MySQL.update('UPDATE court_cases SET judge_cid = ?, status = ? WHERE case_id = ?', { input[1], 'assigned', caseId })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Judge assigned' })
end)

RegisterNetEvent('court:addEvidence', function(caseId, label, description)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local case = activeCases[caseId]
    if not case then return end
    if #case.evidence >= Config.CourtSystem.evidenceSlots then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Evidence slots full' })
        return
    end
    local evId = #case.evidence + 1
    table.insert(case.evidence, { id = evId, label = label, description = description, submittedBy = p.PlayerData.citizenid })
    MySQL.insert('INSERT INTO court_evidence (case_id, evidence_id, label, description, submitted_cid) VALUES (?, ?, ?, ?, ?)', { caseId, evId, label, description, p.PlayerData.citizenid })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Evidence added (# ' .. evId .. ')' })
end)

RegisterNetEvent('court:requestBail', function(caseId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local case = activeCases[caseId]
    if not case or case.status ~= 'filed' then return end
    local severity = 'misdemeanor'
    for s, _ in pairs(Config.CourtSystem.sentencing) do
        severity = s
    end
    local bailAmount = math.floor(Config.CourtSystem.bailMultiplier * Config.CourtSystem.sentencing[severity].fineMax)
    case.bail = { amount = bailAmount, paid = false, requestedBy = p.PlayerData.citizenid }
    MySQL.update('UPDATE court_cases SET bail_amount = ?, bail_paid = 0 WHERE case_id = ?', { bailAmount, caseId })
    TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Bail set at $' .. bailAmount .. '. /paybail ' .. caseId .. ' to pay' })
end)

RegisterNetEvent('court:payBail', function(caseId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local case = activeCases[caseId]
    if not case or not case.bail or case.bail.paid then return end
    if p.Functions.RemoveMoney('bank', case.bail.amount) then
        case.bail.paid = true
        case.status = 'bailed'
        MySQL.update('UPDATE court_cases SET bail_paid = 1, status = ? WHERE case_id = ?', { 'bailed', caseId })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bail paid ($' .. case.bail.amount .. ')' })
    end
end)

RegisterNetEvent('court:startTrial', function(caseId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p or p.PlayerData.job.name ~= 'judge' then return end
    local case = activeCases[caseId]
    if not case then return end
    case.status = 'trial'
    MySQL.update('UPDATE court_cases SET status = ? WHERE case_id = ?', { 'trial', caseId })
    -- summon jury pool
    local players = QBox.Functions.GetPlayers()
    local pool = {}
    for _, s in ipairs(players) do
        local pl = QBox.Functions.GetPlayer(s)
        if pl and not isCourtStaff(s) then
            table.insert(pool, { src = s, cid = pl.PlayerData.citizenid, name = pl.PlayerData.charinfo.firstname .. ' ' .. pl.PlayerData.charinfo.lastname })
            if #pool >= Config.CourtSystem.juryPoolSize then break end
        end
    end
    juryPools[caseId] = pool
    for _, juror in ipairs(pool) do
        TriggerClientEvent('court:jurySummon', juror.src, caseId)
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Trial started. Jury summoned.' })
end)

RegisterNetEvent('court:juryVote', function(caseId, vote)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    if not activeTrials[caseId] then activeTrials[caseId] = { votes = {} } end
    activeTrials[caseId].votes[p.PlayerData.citizenid] = vote
    local totalVotes = 0
    local guiltyVotes = 0
    for _, v in pairs(activeTrials[caseId].votes) do
        totalVotes = totalVotes + 1
        if v == 'guilty' then guiltyVotes = guiltyVotes + 1 end
    end
    if totalVotes >= Config.CourtSystem.juryRequired then
        local verdict = guiltyVotes > totalVotes / 2 and 'guilty' or 'not_guilty'
        activeCases[caseId].status = 'verdict'
        activeCases[caseId].verdict = verdict
        MySQL.update('UPDATE court_cases SET status = ?, verdict = ? WHERE case_id = ?', { 'verdict', verdict, caseId })
        TriggerClientEvent('court:verdict', -1, caseId, verdict, guiltyVotes, totalVotes)
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Vote recorded (' .. totalVotes .. '/' .. Config.CourtSystem.juryRequired .. ' needed)' })
    end
end)

RegisterNetEvent('court:sentence', function(caseId, sentenceTime, fine)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p or p.PlayerData.job.name ~= 'judge' then return end
    local case = activeCases[caseId]
    if not case then return end
    case.status = 'sentenced'
    case.sentence = { time = sentenceTime or 0, fine = fine or 0 }
    MySQL.update('UPDATE court_cases SET status = ?, sentence_time = ?, sentence_fine = ? WHERE case_id = ?', { 'sentenced', sentenceTime or 0, fine or 0, caseId })
    TriggerClientEvent('court:sentenced', -1, caseId, sentenceTime, fine)
end)

RegisterNetEvent('court:appeal', function(caseId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local case = activeCases[caseId]
    if not case or case.status ~= 'sentenced' then return end
    if p.Functions.RemoveMoney('bank', Config.CourtSystem.appealCost) then
        case.status = 'appealed'
        MySQL.update('UPDATE court_cases SET status = ? WHERE case_id = ?', { 'appealed', caseId })
        MySQL.insert('INSERT INTO court_appeals (case_id, appellant_cid, reason) VALUES (?, ?, ?)', { caseId, p.PlayerData.citizenid, 'Appeal filed' })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Appeal filed ($' .. Config.CourtSystem.appealCost .. ')' })
    end
end)

QBox.Functions.CreateCallback('court:getCases', function(source, cb)
    local p = QBox.Functions.GetPlayer(source)
    if not p then cb({}) return end
    local result = {}
    for _, c in pairs(activeCases) do
        table.insert(result, c)
    end
    cb(result)
end)

QBox.Functions.CreateCallback('court:getCase', function(source, caseId, cb)
    cb(activeCases[caseId] or nil)
end)
