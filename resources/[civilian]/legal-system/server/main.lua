local QBox = exports['qbx_core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, action)
  local key = src .. ':' .. action; local now = os.time()
  RATE_LIMITS[key] = RATE_LIMITS[key] or {}; table.insert(RATE_LIMITS[key], now)
  for i = #RATE_LIMITS[key], 1, -1 do if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end end
  local limit = Config.LegalSystem.rateLimits[action] or 10; return #RATE_LIMITS[key] <= limit
end

-- 1. Court & Prosecution App
RegisterNetEvent('legal:server:fileCase', function(defendantCID, charges)
  local src = source
  if not checkRateLimit(src, 'caseFile') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if player.PlayerData.job.name ~= 'judge' then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local plaintif = player.PlayerData.citizenid
  local caseId = MySQL.insert.await('INSERT INTO court_cases (plaintiff, defendant, charges, status) VALUES (?, ?, ?, ?)', { plaintif, defendantCID, charges, 'filed' })
  if caseId then
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Case #' .. caseId .. ' filed' })
  end
end)

RegisterNetEvent('legal:server:sentence', function(caseId, fine, prisonTime)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'judge' then return end
  local case = MySQL.single.await('SELECT * FROM court_cases WHERE id = ?', { caseId })
  if not case then return end
  MySQL.update('UPDATE court_cases SET status = ? WHERE id = ?', { 'sentenced', caseId })
  MySQL.insert('INSERT INTO criminal_records (citizenid, offense, fine, prison_time, officer) VALUES (?, ?, ?, ?, ?)', {
    case.defendant, 'Court conviction: ' .. case.charges, fine or 0, prisonTime or 0, player.PlayerData.citizenid
  })
  local target = QBox.Functions.GetPlayerByCitizenId(case.defendant)
  if target then
    if fine and fine > 0 then
      target.Functions.RemoveMoney('bank', fine, 'Court fine')
      TriggerClientEvent('ox_lib:notify', target.PlayerData.source, { type = 'error', description = 'Fined $' .. fine })
    end
  end
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Sentence applied' })
end)

-- 2. Digital Retainer Contracts
RegisterNetEvent('legal:server:createRetainer', function(clientCID, fee, contingency)
  local src = source
  if not checkRateLimit(src, 'retainer') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'lawyer' then return end
  fee = math.floor(tonumber(fee) or 0)
  if fee < Config.LegalSystem.retainerFees.min or fee > Config.LegalSystem.retainerFees.max then return end
  contingency = tonumber(contingency) or 0
  if contingency > Config.LegalSystem.retainerFees.contingencyMax then return end
  MySQL.insert('INSERT INTO retainer_contracts (lawyer_cid, client_cid, fee, contingency) VALUES (?, ?, ?, ?)', {
    player.PlayerData.citizenid, clientCID, fee, contingency
  })
  local target = QBox.Functions.GetPlayerByCitizenId(clientCID)
  if target then
    target.Functions.RemoveMoney('bank', fee, 'Legal retainer fee')
    TriggerClientEvent('ox_lib:notify', target.PlayerData.source, { type = 'info', description = 'Retainer locked: $' .. fee })
  end
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Retainer contract created' })
end)

-- 3. Seized Asset Auction Portal
RegisterNetEvent('legal:server:createAuction', function(plate, startingBid)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'cid' then return end
  local vehicleData = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
  if not vehicleData then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Vehicle not found' })
    return
  end
  MySQL.insert('INSERT INTO seized_auctions (vehicle_plate, current_bid) VALUES (?, ?)', { plate, startingBid or 1000 })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Auction created for ' .. plate })
end)

RegisterNetEvent('legal:server:placeBid', function(auctionId, amount)
  local src = source
  if not checkRateLimit(src, 'bid') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local auction = MySQL.single.await('SELECT * FROM seized_auctions WHERE id = ? AND ends_at > NOW()', { auctionId })
  if not auction then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Auction expired' })
    return
  end
  amount = math.floor(tonumber(amount) or 0)
  if amount <= (auction.current_bid or 0) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Bid must exceed current' })
    return
  end
  if player.PlayerData.money.bank < amount then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient funds' })
    return
  end
  exports['Renewed-Banking']:RemoveMoney(player.PlayerData.citizenid, amount, 'Auction bid')
  MySQL.update('UPDATE seized_auctions SET current_bid = ?, bidder = ? WHERE id = ?', { amount, player.PlayerData.citizenid, auctionId })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bid placed: $' .. amount })
end)

-- 4. Business License Matrix
RegisterNetEvent('legal:server:applyLicense', function(businessName)
  local src = source
  if not checkRateLimit(src, 'license') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if player.PlayerData.money.bank < Config.LegalSystem.businessLicense.cost then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient funds' })
    return
  end
  player.Functions.RemoveMoney('bank', Config.LegalSystem.businessLicense.cost, 'Business license')
  MySQL.insert('INSERT INTO business_licenses (business, owner) VALUES (?, ?)', { businessName, player.PlayerData.citizenid })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'License issued for ' .. businessName })
end)

-- 5. Ballistic Specimen Registry
RegisterNetEvent('legal:server:registerBallistic', function(weaponSerial, casingSerial, coords)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  MySQL.insert('INSERT INTO ballistic_records (casing_serial, weapon_serial, citizenid, incident_coords) VALUES (?, ?, ?, ?)', {
    casingSerial, weaponSerial, player.PlayerData.citizenid, json.encode(coords or {})
  })
end)

QBox.Functions.CreateCallback('legal:server:matchBallistic', function(source, cb, casingSerial)
  local match = MySQL.single.await('SELECT * FROM ballistic_records WHERE casing_serial = ?', { casingSerial })
  cb(match)
end)

-- 6. Bail Bond Escrow Protocol
RegisterNetEvent('legal:server:postBail', function(targetCID, amount)
  local src = source
  if not checkRateLimit(src, 'bail') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if player.PlayerData.money.bank < amount then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient funds' })
    return
  end
  player.Functions.RemoveMoney('bank', amount, 'Bail bond')
  MySQL.insert('INSERT INTO bail_bonds (citizenid, amount, posted_by, expires_at) VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL ? HOUR))', {
    targetCID, amount, player.PlayerData.citizenid, Config.LegalSystem.bailBonds.recidivismWindow
  })
  local target = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if target then
    TriggerClientEvent('ox_lib:notify', target.PlayerData.source, { type = 'info', description = 'Bail posted for you' })
  end
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bail posted: $' .. amount })
end)

-- 7. MDT-Linked Background Checker
QBox.Functions.CreateCallback('legal:server:backgroundCheck', function(source, cb, targetCID)
  local src = source
  if not checkRateLimit(src, 'backgroundCheck') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then cb({ cleared = false }) return end
  local job = player.PlayerData.job.name
  local allowed = false
  for _, j in ipairs(Config.LegalSystem.backgroundCheck.allowedJobs) do
    if job == j then allowed = true break end
  end
  if not allowed then cb({ cleared = false }) return end
  local records = MySQL.single.await('SELECT COUNT(*) as count FROM criminal_records WHERE citizenid = ?', { targetCID })
  cb({ cleared = records and records.count == 0, recordCount = records and records.count or 0 })
end)

-- 8. Dynamic Variable Taxation
RegisterNetEvent('legal:server:setTaxRate', function(taxType, rate)
  local src = source
  if not checkRateLimit(src, 'taxChange') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local allowedRanks = { 'judge', 'mayor', 'police' }
  local jobOk = false
  for _, job in ipairs(allowedRanks) do
    if player.PlayerData.job.name == job and player.PlayerData.job.grade.level >= 5 then jobOk = true break end
  end
  if not jobOk then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  rate = tonumber(rate)
  if not rate or rate < 0 or rate > 50 then return end
  if taxType == 'sales' then
    MySQL.update('UPDATE tax_config SET sales_tax = ?, updated_by = ?, updated_at = NOW() WHERE id = 1', { rate, player.PlayerData.citizenid })
    if MySQL.getChangedRows() == 0 then
      MySQL.insert('INSERT INTO tax_config (sales_tax, property_tax, updated_by) VALUES (?, 1.50, ?)', { rate, player.PlayerData.citizenid })
    end
  elseif taxType == 'property' then
    MySQL.update('UPDATE tax_config SET property_tax = ?, updated_by = ?, updated_at = NOW() WHERE id = 1', { rate, player.PlayerData.citizenid })
    if MySQL.getChangedRows() == 0 then
      MySQL.insert('INSERT INTO tax_config (property_tax, sales_tax, updated_by) VALUES (?, 8.00, ?)', { rate, player.PlayerData.citizenid })
    end
  end
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = taxType .. ' tax set to ' .. rate .. '%' })
end)

-- 9. Suspicious Wire-Transfer Interceptor
RegisterNetEvent('legal:server:checkTransfer', function(targetCID, amount)
  local src = source
  if not checkRateLimit(src, 'transferCheck') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if not amount or amount < Config.LegalSystem.wireTransferThreshold then return end
  MySQL.insert('INSERT INTO flagged_transactions (from_cid, to_cid, amount, flagged) VALUES (?, ?, ?, TRUE)', {
    player.PlayerData.citizenid, targetCID, amount
  })
  local cidPlayers = QBox.Functions.GetPlayers()
  for _, p in ipairs(cidPlayers) do
    local agent = QBox.Functions.GetPlayer(p)
    if agent and agent.PlayerData.job.name == 'cid' then
      TriggerClientEvent('ox_lib:notify', p, { type = 'warning', description = 'Flagged transfer: $' .. amount .. ' from ' .. player.PlayerData.citizenid })
    end
  end
end)

QBox.Functions.CreateCallback('legal:server:getTaxRates', function(source, cb)
  local row = MySQL.single.await('SELECT * FROM tax_config WHERE id = 1')
  cb(row or { sales_tax = Config.LegalSystem.taxDefaults.sales, property_tax = Config.LegalSystem.taxDefaults.property })
end)

QBox.Functions.CreateCallback('legal:server:getActiveAuctions', function(source, cb)
  cb(MySQL.query.await('SELECT * FROM seized_auctions WHERE ends_at > NOW() ORDER BY created_at DESC'))
end)

QBox.Functions.CreateCallback('legal:server:getCourtCases', function(source, cb)
  cb(MySQL.query.await('SELECT * FROM court_cases WHERE status = ? ORDER BY created_at DESC', { 'filed' }))
end)
