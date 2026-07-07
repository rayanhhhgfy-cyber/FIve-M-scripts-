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
  local limit = Config.MechanicLaptop.rateLimits[action] or 10
  return #RATE_LIMITS[key] <= limit
end

local function isOwner(src)
  local player = QBox.Functions.GetPlayer(src)
  if not player then return false end
  return player.PlayerData.job.grade.level >= Config.MechanicLaptop.ownerGrade
end

local function isManager(src)
  local player = QBox.Functions.GetPlayer(src)
  if not player then return false end
  local grade = player.PlayerData.job.grade.level
  for _, mgr in ipairs(Config.MechanicLaptop.managerGrades) do
    if grade >= mgr then return true end
  end
  return false
end

local function getBusinessAccount()
  local accounts = exports['Renewed-Banking']:GetAccounts()
  for _, acc in ipairs(accounts) do
    if acc.label == Config.MechanicLaptop.bankAccountName then
      return acc
    end
  end
  return nil
end

RegisterNetEvent('mechanic:server:hire', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'hire') then return end
  if not isManager(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local existing = MySQL.single.await('SELECT citizenid FROM mechanic_rosters WHERE citizenid = ?', { targetCID })
  if existing then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already employed' })
    return
  end
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('mechanic', 0)
  end
  MySQL.insert('INSERT INTO mechanic_rosters (citizenid, job, grade, hired_by) VALUES (?, ?, 0, ?)', {
    targetCID, Config.MechanicLaptop.allowedJob, player.PlayerData.citizenid
  })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Technician hired' })
end)

RegisterNetEvent('mechanic:server:fire', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'fire') then return end
  if not isManager(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('unemployed', 0)
  end
  MySQL.query('DELETE FROM mechanic_rosters WHERE citizenid = ?', { targetCID })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Technician fired' })
end)

RegisterNetEvent('mechanic:server:promote', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'promote') then return end
  if not isManager(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local row = MySQL.single.await('SELECT grade FROM mechanic_rosters WHERE citizenid = ?', { targetCID })
  if not row then return end
  local newGrade = math.min(row.grade + 1, 4)
  MySQL.update('UPDATE mechanic_rosters SET grade = ? WHERE citizenid = ?', { newGrade, targetCID })
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('mechanic', newGrade)
    local salary = Config.MechanicLaptop.salaryGrades[newGrade] or 0
    local account = getBusinessAccount()
    if account then
      exports['Renewed-Banking']:RemoveMoney(account.id, salary, 'Salary payment')
      TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'info', description = 'Promoted! Salary: $' .. salary })
    end
  end
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Promoted to ' .. (Config.MechanicLaptop.ranks[newGrade] or ('grade ' .. newGrade)) })
end)

RegisterNetEvent('mechanic:server:demote', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'promote') then return end
  if not isManager(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local row = MySQL.single.await('SELECT grade FROM mechanic_rosters WHERE citizenid = ?', { targetCID })
  if not row then return end
  local newGrade = math.max(row.grade - 1, 0)
  MySQL.update('UPDATE mechanic_rosters SET grade = ? WHERE citizenid = ?', { newGrade, targetCID })
  local targetSrc = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if targetSrc then
    targetSrc.Functions.SetJob('mechanic', newGrade)
  end
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Demoted to ' .. (Config.MechanicLaptop.ranks[newGrade] or ('grade ' .. newGrade)) })
end)

RegisterNetEvent('mechanic:server:sendInvoice', function(targetSrc, items, total)
  local src = source
  if not checkRateLimit(src, 'sendInvoice') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= Config.MechanicLaptop.allowedJob then return end
  local target = QBox.Functions.GetPlayer(targetSrc)
  if not target then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Target not found' })
    return
  end
  MySQL.insert('INSERT INTO mechanic_invoices (customer, mechanic, items, total, status) VALUES (?, ?, ?, ?, ?)', {
    target.PlayerData.citizenid, player.PlayerData.citizenid, json.encode(items), total, 'pending'
  })
  TriggerClientEvent('mechanic:client:receiveInvoice', targetSrc, {
    mechanicName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
    items = items,
    total = total,
    mechanicSrc = src
  })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Invoice sent' })
end)

RegisterNetEvent('mechanic:server:payInvoice', function(invoiceData)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if player.PlayerData.money.bank < invoiceData.total then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient funds' })
    return
  end
  local account = getBusinessAccount()
  if not account then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Business account not found' })
    return
  end
  player.Functions.RemoveMoney('bank', invoiceData.total, 'Mechanic invoice')
  exports['Renewed-Banking']:AddMoney(account.id, invoiceData.total, 'Invoice payment')
  TriggerClientEvent('ox_lib:notify', invoiceData.mechanicSrc, { type = 'success', description = 'Payment received: $' .. invoiceData.total })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Invoice paid' })
end)

RegisterNetEvent('mechanic:server:orderParts', function(itemName, quantity)
  local src = source
  if not checkRateLimit(src, 'orderParts') then return end
  if not isOwner(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only the owner can order parts' })
    return
  end
  local partConfig = nil
  for _, p in ipairs(Config.MechanicLaptop.partsSupply) do
    if p.item == itemName then partConfig = p break end
  end
  if not partConfig then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Invalid part' })
    return
  end
  quantity = math.floor(tonumber(quantity) or 1)
  if quantity < 1 or quantity > 100 then quantity = 1 end
  local totalCost = partConfig.cost * quantity
  local account = getBusinessAccount()
  if not account then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Business account not found' })
    return
  end
  local success = exports['Renewed-Banking']:RemoveMoney(account.id, totalCost, 'Parts order: ' .. quantity .. 'x ' .. partConfig.label)
  if not success then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient business funds' })
    return
  end
  exports.ox_inventory:AddItem(src, itemName, quantity)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Ordered ' .. quantity .. 'x ' .. partConfig.label .. ' for $' .. totalCost })
end)

QBox.Functions.CreateCallback('mechanic:server:getRoster', function(source, cb)
  local roster = MySQL.query.await('SELECT * FROM mechanic_rosters WHERE job = ? ORDER BY grade DESC', { Config.MechanicLaptop.allowedJob })
  for _, member in ipairs(roster) do
    local p = QBox.Functions.GetPlayerByCitizenId(member.citizenid)
    member.name = p and (p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname) or 'Offline'
    member.online = p and true or false
    member.rankLabel = Config.MechanicLaptop.ranks[member.grade] or 'Unknown'
  end
  cb(roster)
end)

QBox.Functions.CreateCallback('mechanic:server:getPartsSupply', function(source, cb)
  cb(Config.MechanicLaptop.partsSupply)
end)

QBox.Functions.CreateCallback('mechanic:server:nearbyPlayers', function(source, cb)
  local ped = GetPlayerPed(source)
  local coords = GetEntityCoords(ped)
  local nearby = {}
  local players = QBox.Functions.GetPlayers()
  for _, p in ipairs(players) do
    if p ~= source then
      local otherPed = GetPlayerPed(p)
      if DoesEntityExist(otherPed) then
        local otherCoords = GetEntityCoords(otherPed)
        local dist = #(coords - otherCoords)
        if dist < 5.0 then
          local otherPlayer = QBox.Functions.GetPlayer(p)
          if otherPlayer then
            table.insert(nearby, { src = p, name = otherPlayer.PlayerData.charinfo.firstname .. ' ' .. otherPlayer.PlayerData.charinfo.lastname, cid = otherPlayer.PlayerData.citizenid })
          end
        end
      end
    end
  end
  cb(nearby)
end)
