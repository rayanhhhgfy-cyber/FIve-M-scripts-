local QBox = exports['qbx_core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, action)
  local key = src .. ':' .. action
  local now = os.time()
  RATE_LIMITS[key] = RATE_LIMITS[key] or {}
  table.insert(RATE_LIMITS[key], now)
  for i = #RATE_LIMITS[key], 1, -1 do
    if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
  end
  local limit = Config.CIDLaptop.rateLimits[action] or 10
  return #RATE_LIMITS[key] <= limit
end

local function isCIDLeadership(src)
  local player = QBox.Functions.GetPlayer(src)
  if not player then return false end
  local grade = player.PlayerData.job.grade.level
  for _, lvl in ipairs(Config.CIDLaptop.leadershipGrades) do
    if grade == lvl then return true end
  end
  return false
end

RegisterNetEvent('cid:server:hire', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'hire') then return end
  if not isCIDLeadership(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local existing = MySQL.single.await('SELECT citizenid FROM job_rosters WHERE citizenid = ?', { targetCID })
  if existing then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already on roster' })
    return
  end
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('cid', 0)
  end
  MySQL.insert('INSERT INTO job_rosters (citizenid, job, grade, hired_by) VALUES (?, ?, 0, ?)', {
    targetCID, Config.CIDLaptop.allowedJob, player.PlayerData.citizenid
  })
  MySQL.insert('INSERT INTO job_logs (action, target_cid, performed_by) VALUES (?, ?, ?)', { 'cid_hire', targetCID, player.PlayerData.citizenid })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Agent hired' })
end)

RegisterNetEvent('cid:server:fire', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'fire') then return end
  if not isCIDLeadership(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('unemployed', 0)
  end
  MySQL.query('DELETE FROM job_rosters WHERE citizenid = ?', { targetCID })
  MySQL.insert('INSERT INTO job_logs (action, target_cid, performed_by) VALUES (?, ?, ?)', { 'cid_fire', targetCID, player.PlayerData.citizenid })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Agent fired' })
end)

RegisterNetEvent('cid:server:promote', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'promote') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if player.PlayerData.job.grade.level < Config.CIDLaptop.minGradeForPromote then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local row = MySQL.single.await('SELECT grade FROM job_rosters WHERE citizenid = ?', { targetCID })
  if not row then return end
  local newGrade = math.min(row.grade + 1, 10)
  MySQL.update('UPDATE job_rosters SET grade = ? WHERE citizenid = ?', { newGrade, targetCID })
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('cid', newGrade)
  end
  MySQL.insert('INSERT INTO job_logs (action, target_cid, performed_by) VALUES (?, ?, ?)', { 'cid_promote', targetCID, player.PlayerData.citizenid })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Agent promoted to grade ' .. newGrade })
end)

RegisterNetEvent('cid:server:demote', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'demote') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if player.PlayerData.job.grade.level < Config.CIDLaptop.minGradeForPromote then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local row = MySQL.single.await('SELECT grade FROM job_rosters WHERE citizenid = ?', { targetCID })
  if not row then return end
  local newGrade = math.max(row.grade - 1, 0)
  MySQL.update('UPDATE job_rosters SET grade = ? WHERE citizenid = ?', { newGrade, targetCID })
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('cid', newGrade)
  end
  MySQL.insert('INSERT INTO job_logs (action, target_cid, performed_by) VALUES (?, ?, ?)', { 'cid_demote', targetCID, player.PlayerData.citizenid })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Agent demoted to grade ' .. newGrade })
end)

QBox.Functions.CreateCallback('cid:server:getRoster', function(source, cb)
  local roster = MySQL.query.await('SELECT * FROM job_rosters WHERE job = ? ORDER BY grade DESC', { Config.CIDLaptop.allowedJob })
  for _, member in ipairs(roster) do
    local player = QBox.Functions.GetPlayerByCitizenId(member.citizenid)
    member.name = player and (player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname) or 'Offline'
    member.online = player and true or false
  end
  cb(roster)
end)

QBox.Functions.CreateCallback('cid:server:getFlaggedTransactions', function(source, cb)
  local txns = MySQL.query.await('SELECT * FROM flagged_transactions WHERE flagged = TRUE AND reviewed = FALSE ORDER BY created_at DESC LIMIT 50')
  cb(txns)
end)

RegisterNetEvent('cid:server:reviewTransaction', function(txnId)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'cid' then return end
  MySQL.update('UPDATE flagged_transactions SET reviewed = TRUE WHERE id = ?', { txnId })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Transaction reviewed' })
end)
