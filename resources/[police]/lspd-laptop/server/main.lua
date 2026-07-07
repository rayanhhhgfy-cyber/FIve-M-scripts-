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
  local limit = Config.LSPDLaptop.rateLimits[action] or 10
  return #RATE_LIMITS[key] <= limit
end

local function isLeadership(src)
  local player = QBox.Functions.GetPlayer(src)
  if not player then return false end
  local grade = player.PlayerData.job.grade.level
  for _, lvl in ipairs(Config.LSPDLaptop.leadershipGrades) do
    if grade == lvl then return true end
  end
  return false
end

local function logAction(action, targetCID, performedBy)
  MySQL.insert('INSERT INTO job_logs (action, target_cid, performed_by) VALUES (?, ?, ?)', { action, targetCID, performedBy })
end

local active911Calls = {}
local officerGpsData = {}
local lprHitBuffer = {}
local activeDronePositions = {}
local activeK9Units = {}
local k9UnitIdCounter = 1

--- ROSTER MANAGEMENT (existing)
RegisterNetEvent('lspd:server:hire', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'hire') then return end
  if not isLeadership(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  if not targetCID or targetCID == '' then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local existing = MySQL.single.await('SELECT citizenid FROM job_rosters WHERE citizenid = ?', { targetCID })
  if existing then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already hired' })
    return
  end
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('police', 0)
  end
  MySQL.insert('INSERT INTO job_rosters (citizenid, job, grade, hired_by) VALUES (?, ?, 0, ?)', {
    targetCID, Config.LSPDLaptop.allowedJob, player.PlayerData.citizenid
  })
  logAction('hire', targetCID, player.PlayerData.citizenid)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Hired ' .. targetCID })
end)

RegisterNetEvent('lspd:server:fire', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'fire') then return end
  if not isLeadership(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  if not targetCID then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('unemployed', 0)
  end
  MySQL.query('DELETE FROM job_rosters WHERE citizenid = ?', { targetCID })
  logAction('fire', targetCID, player.PlayerData.citizenid)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Fired ' .. targetCID })
end)

RegisterNetEvent('lspd:server:promote', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'promote') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if player.PlayerData.job.grade.level < Config.LSPDLaptop.minGradeForPromote then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local row = MySQL.single.await('SELECT grade FROM job_rosters WHERE citizenid = ?', { targetCID })
  if not row then return end
  local newGrade = math.min(row.grade + 1, 12)
  MySQL.update('UPDATE job_rosters SET grade = ? WHERE citizenid = ?', { newGrade, targetCID })
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('police', newGrade)
    local salary = Config.LSPDLaptop.salaryGrades[newGrade] or 0
    TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'info', description = 'Promoted! Salary: $' .. salary })
  end
  logAction('promote', targetCID, player.PlayerData.citizenid)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Promoted ' .. targetCID .. ' to grade ' .. newGrade })
end)

RegisterNetEvent('lspd:server:demote', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'demote') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if player.PlayerData.job.grade.level < Config.LSPDLaptop.minGradeForPromote then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local row = MySQL.single.await('SELECT grade FROM job_rosters WHERE citizenid = ?', { targetCID })
  if not row then return end
  local newGrade = math.max(row.grade - 1, 0)
  MySQL.update('UPDATE job_rosters SET grade = ? WHERE citizenid = ?', { newGrade, targetCID })
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('police', newGrade)
  end
  logAction('demote', targetCID, player.PlayerData.citizenid)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Demoted ' .. targetCID .. ' to grade ' .. newGrade })
end)

RegisterNetEvent('lspd:server:backgroundCheck', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'backgroundCheck') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'police' then return end
  local records = MySQL.query.await('SELECT * FROM criminal_records WHERE citizenid = ? ORDER BY created_at DESC LIMIT 20', { targetCID })
  local targetPlayer = QBox.Functions.GetPlayerByCitizenId(targetCID)
  local name = 'Unknown'
  if targetPlayer then
    name = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
  end
  TriggerClientEvent('lspd:client:backgroundCheckResult', src, { citizenid = targetCID, name = name, records = records })
end)

QBox.Functions.CreateCallback('lspd:server:getRoster', function(source, cb)
  local roster = MySQL.query.await('SELECT * FROM job_rosters WHERE job = ? ORDER BY grade DESC', { Config.LSPDLaptop.allowedJob })
  for _, member in ipairs(roster) do
    local player = QBox.Functions.GetPlayerByCitizenId(member.citizenid)
    if player then
      member.name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
      member.online = true
    else
      member.name = 'Offline'
      member.online = false
    end
  end
  cb(roster)
end)

QBox.Functions.CreateCallback('lspd:server:getActiveWarrants', function(source, cb)
  local warrants = MySQL.query.await('SELECT * FROM mdt_warrants WHERE is_active = TRUE')
  cb(warrants)
end)

--- === CRIME CENTER ===

--- 911 Call System
RegisterNetEvent('emergency:server:call911', function(callType, description)
  local src = source
  if not checkRateLimit(src, 'call911') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local ped = GetPlayerPed(src)
  local coords = GetEntityCoords(ped)
  local callId = #active911Calls + 1
  local call = {
    id = callId,
    caller = player.PlayerData.citizenid,
    callerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
    type = callType or 'General',
    description = description or '',
    coords = { x = coords.x, y = coords.y, z = coords.z },
    status = 'Active',
    time = os.time(),
    assignedUnit = nil
  }
  table.insert(active911Calls, call)
  MySQL.insert('INSERT INTO emergency_calls (caller_cid, type, description, coords, status) VALUES (?, ?, ?, ?, ?)',
    { player.PlayerData.citizenid, call.type, call.description, json.encode(call.coords), 'Active' })
  TriggerClientEvent('crime:client:newCall', -1, call)
  local players = QBox.Functions.GetPlayers()
  for _, p in ipairs(players) do
    local target = QBox.Functions.GetPlayer(p)
    if target and target.PlayerData.job.name == 'police' and target.PlayerData.job.onduty then
      TriggerClientEvent('ox_lib:notify', p, { type = 'warning', description = '911 Call: ' .. call.type .. ' at ' .. tostring(coords.x) .. ', ' .. tostring(coords.y) })
    end
  end
end)

--- Officer GPS Polling Thread
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(Config.LSPDLaptop.crimeCenter.officerGpsPollInterval or 5000)
    officerGpsData = {}
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
      local player = QBox.Functions.GetPlayer(src)
      if player and player.PlayerData.job and player.PlayerData.job.onduty then
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        officerGpsData[src] = {
          cid = player.PlayerData.citizenid,
          name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
          job = player.PlayerData.job.name,
          grade = player.PlayerData.job.grade.level,
          coords = { x = coords.x, y = coords.y, z = coords.z },
          vehicle = IsPedInAnyVehicle(ped, false) and GetEntityModel(GetVehiclePedIsIn(ped, false)) or nil,
          status = player.PlayerData.metadata['isdead'] and 'Injured' or 'Active',
        }
      end
    end
    TriggerClientEvent('crime:client:updateGps', -1, officerGpsData)
  end
end)

--- LPR Hit Ingestion
RegisterNetEvent('lpr:server:reportHit', function(plate, coords)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local hit = {
    plate = plate,
    coords = coords,
    timestamp = os.time(),
    officer = player.PlayerData.citizenid,
    officerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
  }
  table.insert(lprHitBuffer, hit)
  if #lprHitBuffer > (Config.LSPDLaptop.crimeCenter.maxLprHitsDisplayed or 50) then
    table.remove(lprHitBuffer, 1)
  end
  TriggerClientEvent('crime:client:newLprHit', -1, hit)
end)

--- Drone Position Feed (called by camera-drone resource)
RegisterNetEvent('drone:server:positionUpdate', function(coords)
  local src = source
  if not coords then return end
  activeDronePositions[src] = { coords = coords, time = os.time() }
end)

RegisterNetEvent('drone:server:stored', function()
  local src = source
  activeDronePositions[src] = nil
end)

--- Crime Center Data Callback
QBox.Functions.CreateCallback('crime:server:getFullDashboard', function(source, cb)
  local src = source
  if not checkRateLimit(src, 'crimeCenterRefresh') then cb(nil) return end
  local activeDroneList = {}
  for srcKey, droneData in pairs(activeDronePositions) do
    if os.time() - droneData.time < 30 then
      activeDroneList[srcKey] = droneData
    else
      activeDronePositions[srcKey] = nil
    end
  end
  local activeCalls = {}
  for _, call in ipairs(active911Calls) do
    if os.time() - call.time < (Config.LSPDLaptop.crimeCenter.callLifetimeMinutes or 120) * 60 then
      table.insert(activeCalls, call)
    end
  end
  cb({
    officers = officerGpsData,
    calls = activeCalls,
    drones = activeDroneList,
    lprHits = lprHitBuffer,
    k9Units = activeK9Units,
  })
end)

--- Dispatch Call Assignment
RegisterNetEvent('crime:server:assignUnit', function(callId, targetSrc)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'police' then return end
  for _, call in ipairs(active911Calls) do
    if call.id == callId then
      call.status = 'Responding'
      call.assignedUnit = targetSrc
      local targetPlayer = QBox.Functions.GetPlayer(targetSrc)
      if targetPlayer then
        TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'info', description = 'Dispatched to: ' .. call.type })
      end
      TriggerClientEvent('crime:client:callUpdated', -1, call)
      break
    end
  end
end)

RegisterNetEvent('crime:server:resolveCall', function(callId)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'police' then return end
  for i, call in ipairs(active911Calls) do
    if call.id == callId then
      call.status = 'Resolved'
      MySQL.update('UPDATE emergency_calls SET status = ? WHERE id = ?', { 'Resolved', callId })
      TriggerClientEvent('crime:client:callUpdated', -1, call)
      table.remove(active911Calls, i)
      break
    end
  end
end)

--- === K-9 OPS CENTER ===

RegisterNetEvent('k9:server:deploy', function(breed, specialization, callSign)
  local src = source
  if not checkRateLimit(src, 'k9Deploy') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'police' then return end
  if player.PlayerData.job.grade.level < Config.LSPDLaptop.k9Ops.deployRank then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Rank too low for K-9' })
    return
  end
  local activeCount = 0
  for _, unit in pairs(activeK9Units) do
    if unit.handler == src then activeCount = activeCount + 1 end
  end
  if activeCount >= Config.LSPDLaptop.k9Ops.maxActiveK9 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Max K-9 units deployed' })
    return
  end
  local unitId = k9UnitIdCounter
  k9UnitIdCounter = k9UnitIdCounter + 1
  local ped = GetPlayerPed(src)
  local coords = GetEntityCoords(ped)
  local unit = {
    id = unitId,
    callSign = callSign or ('K9-' .. unitId),
    breed = breed or 'German Shepherd',
    specialization = specialization or 'Patrol',
    handler = src,
    handlerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
    coords = { x = coords.x, y = coords.y, z = coords.z },
    status = 'Deployed',
    deployedAt = os.time(),
    targetPed = nil,
    mode = 'follow',
  }
  activeK9Units[unitId] = unit
  MySQL.insert('INSERT INTO k9_units (call_sign, breed, specialization, handler_cid, status) VALUES (?, ?, ?, ?, ?)',
    { unit.callSign, unit.breed, unit.specialization, player.PlayerData.citizenid, 'Deployed' })
  TriggerClientEvent('k9:client:spawnDog', src, unit)
  TriggerClientEvent('crime:client:k9Updated', -1, activeK9Units)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = unit.callSign .. ' deployed' })
end)

RegisterNetEvent('k9:server:recall', function(unitId)
  local src = source
  local unit = activeK9Units[unitId]
  if not unit or unit.handler ~= src then return end
  unit.status = 'Returning'
  TriggerClientEvent('k9:client:recallDog', unit.handler, unitId)
  MySQL.update('UPDATE k9_units SET status = ? WHERE id = ?', { 'Stored', unitId })
  activeK9Units[unitId] = nil
  TriggerClientEvent('crime:client:k9Updated', -1, activeK9Units)
  TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = unit.callSign .. ' recalled' })
end)

RegisterNetEvent('k9:server:command', function(unitId, command, targetSrc)
  local src = source
  if not checkRateLimit(src, 'k9Command') then return end
  local unit = activeK9Units[unitId]
  if not unit or unit.handler ~= src then return end
  if command == 'track' and targetSrc then
    unit.mode = 'tracking'
    unit.targetPed = targetSrc
    TriggerClientEvent('k9:client:track', src, unitId, targetSrc)
  elseif command == 'apprehend' and targetSrc then
    unit.mode = 'apprehending'
    unit.targetPed = targetSrc
    TriggerClientEvent('k9:client:apprehend', src, unitId, targetSrc)
  elseif command == 'search_narcotics' then
    unit.mode = 'searching_narc'
    TriggerClientEvent('k9:client:searchNarcotics', src, unitId)
  elseif command == 'search_explosives' then
    unit.mode = 'searching_exp'
    TriggerClientEvent('k9:client:searchExplosives', src, unitId)
  elseif command == 'guard' then
    unit.mode = 'guarding'
    TriggerClientEvent('k9:client:guard', src, unitId)
  elseif command == 'stay' then
    unit.mode = 'staying'
    TriggerClientEvent('k9:client:stay', src, unitId)
  elseif command == 'heel' then
    unit.mode = 'follow'
    unit.targetPed = nil
    TriggerClientEvent('k9:client:heel', src, unitId)
  end
  unit.status = command:sub(1,1):upper() .. command:sub(2)
  TriggerClientEvent('crime:client:k9Updated', -1, activeK9Units)
  MySQL.insert('INSERT INTO k9_logs (unit_id, action, handler_cid) VALUES (?, ?, ?)',
    { unitId, command, player and player.PlayerData.citizenid or 'unknown' })
end)

QBox.Functions.CreateCallback('k9:server:getActiveUnits', function(source, cb)
  cb(activeK9Units)
end)

QBox.Functions.CreateCallback('k9:server:getK9Logs', function(source, cb)
  local logs = MySQL.query.await('SELECT * FROM k9_logs ORDER BY created_at DESC LIMIT 50')
  cb(logs)
end)

--- Cleanup on disconnect
AddEventHandler('playerDropped', function()
  local src = source
  activeDronePositions[src] = nil
  officerGpsData[src] = nil
  for id, unit in pairs(activeK9Units) do
    if unit.handler == src then
      TriggerClientEvent('k9:client:recallDog', src, id)
      activeK9Units[id] = nil
    end
  end
end)
