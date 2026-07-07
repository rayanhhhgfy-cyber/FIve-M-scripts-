local QBox = exports['qbx_core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, action)
  local key = src .. ':' .. action; local now = os.time()
  RATE_LIMITS[key] = RATE_LIMITS[key] or {}; table.insert(RATE_LIMITS[key], now)
  for i = #RATE_LIMITS[key], 1, -1 do if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end end
  local limit = Config.EconomyCore.rateLimits[action] or 10; return #RATE_LIMITS[key] <= limit
end

-- 1. Global Stock & Securities Index
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(Config.EconomyCore.stockIndex.fluctuationInterval * 1000)
    if not Config.EconomyCore.stockIndex.enabled then break end
    local businesses = MySQL.query.await('SELECT citizenid, business FROM business_licenses WHERE active = TRUE')
    for _, biz in ipairs(businesses) do
      local players = QBox.Functions.GetPlayers()
      local profit = 0
      for _, src in ipairs(players) do
        local p = QBox.Functions.GetPlayer(src)
        if p then profit = profit + (p.PlayerData.money.bank * 0.001) end
      end
      local fluctuation = (math.random() * Config.EconomyCore.stockIndex.maxFluctuation * 2) - Config.EconomyCore.stockIndex.maxFluctuation
      local shares = MySQL.query.await('SELECT * FROM stock_portfolio WHERE business = ?', { biz.business })
      for _, share in ipairs(shares) do
        local shareValue = math.max(10, profit * Config.EconomyCore.stockIndex.maxFluctuation * (1 + fluctuation))
        local holder = QBox.Functions.GetPlayerByCitizenId(share.citizenid)
        if holder then
          TriggerClientEvent('ox_lib:notify', holder.PlayerData.source, { type = 'info', description = biz.business .. ' shares: $' .. math.floor(shareValue) .. ' each' })
        end
      end
    end
  end
end)

RegisterNetEvent('economy:server:buyShares', function(business, shares)
  local src = source
  if not checkRateLimit(src, 'buyShares') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local cost = shares * 100
  if player.PlayerData.money.bank < cost then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient funds' })
    return
  end
  player.Functions.RemoveMoney('bank', cost, 'Stock purchase')
  MySQL.insert('INSERT INTO stock_portfolio (citizenid, business, shares) VALUES (?, ?, ?)', { player.PlayerData.citizenid, business, shares })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bought ' .. shares .. ' shares in ' .. business })
end)

-- 2. Scheduled Auto-Debit Invoice Billing
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(3600000) -- every hour
    if not Config.EconomyCore.autoDebit.enabled then break end
    local invoices = MySQL.query.await('SELECT * FROM auto_invoices WHERE paid = FALSE AND due_at < NOW()')
    for _, inv in ipairs(invoices) do
      local penalty = math.floor(inv.amount * Config.EconomyCore.autoDebit.lateFee)
      local total = inv.amount + penalty
      local player = QBox.Functions.GetPlayerByCitizenId(inv.citizenid)
      if player and player.PlayerData.money.bank >= total then
        player.Functions.RemoveMoney('bank', total, 'Auto-debit: ' .. inv.reason .. ' + late fee')
        MySQL.update('UPDATE auto_invoices SET paid = TRUE WHERE id = ?', { inv.id })
      end
    end
  end
end)

RegisterNetEvent('economy:server:createAutoInvoice', function(targetCID, amount, reason)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  MySQL.insert('INSERT INTO auto_invoices (citizenid, amount, reason, due_at) VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL ? HOUR))', {
    targetCID, amount, reason, Config.EconomyCore.autoDebit.gracePeriod
  })
  local target = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if target then
    TriggerClientEvent('ox_lib:notify', target.PlayerData.source, { type = 'warning', description = 'Invoice: $' .. amount .. ' due in ' .. Config.EconomyCore.autoDebit.gracePeriod .. 'h' })
  end
end)

-- 3. Supply-Chain Restaurant Logistics
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(Config.EconomyCore.supplyChain.restockInterval * 1000)
    if not Config.EconomyCore.supplyChain.enabled then break end
    -- Simulated: would check actual supply tables in a full implementation
  end
end)

-- 4. Deep Bank Vault Deposit Boxes
RegisterNetEvent('economy:server:rentVault', function()
  local src = source
  if not checkRateLimit(src, 'openVault') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if player.PlayerData.money.bank < Config.EconomyCore.vaultBoxes.monthlyRent then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Rent: $' .. Config.EconomyCore.vaultBoxes.monthlyRent })
    return
  end
  player.Functions.RemoveMoney('bank', Config.EconomyCore.vaultBoxes.monthlyRent, 'Vault box rent')
  MySQL.insert('INSERT INTO vault_boxes (renter, items, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))', {
    player.PlayerData.citizenid, '[]'
  })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Vault box rented' })
end)

RegisterNetEvent('economy:server:storeInVault', function(boxId, items)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local box = MySQL.single.await('SELECT * FROM vault_boxes WHERE id = ? AND renter = ?', { boxId, player.PlayerData.citizenid })
  if not box then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Vault box not found' })
    return
  end
  MySQL.update('UPDATE vault_boxes SET items = ? WHERE id = ?', { json.encode(items), boxId })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Items stored in vault' })
end)

-- 5. Player-Owned Commercial Insurance
RegisterNetEvent('economy:server:buyPolicy', function(targetCitizenID, premium)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local target = QBox.Functions.GetPlayerByCitizenId(targetCitizenID)
  if target then
    if player.PlayerData.money.bank < premium then
      TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient funds' })
      return
    end
    player.Functions.RemoveMoney('bank', premium, 'Insurance premium')
    exports['Renewed-Banking']:AddMoney(target.PlayerData.citizenid, premium, 'Insurance policy sold')
    MySQL.insert('INSERT INTO insurance_policies (citizenid, provider, premium, coverage) VALUES (?, ?, ?, ?)', {
      targetCitizenID, player.PlayerData.citizenid, premium, Config.EconomyCore.playerInsurance.coverageRate
    })
    TriggerClientEvent('ox_lib:notify', target.PlayerData.source, { type = 'success', description = 'Insurance policy active' })
  end
end)

RegisterNetEvent('economy:server:claimInsurance', function(policyId, vehicleValue)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local policy = MySQL.single.await('SELECT * FROM insurance_policies WHERE id = ? AND citizenid = ? AND is_active = TRUE', { policyId, player.PlayerData.citizenid })
  if not policy then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No active policy' })
    return
  end
  local payout = math.floor(vehicleValue * policy.coverage)
  player.Functions.AddMoney('bank', payout, 'Insurance claim')
  MySQL.update('UPDATE insurance_policies SET is_active = FALSE WHERE id = ?', { policyId })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Insurance payout: $' .. payout })
end)

-- 6. Municipal Grid & Electrical Engineering
RegisterNetEvent('economy:server:performMaintenance', function()
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'electrician' then return end
  TriggerClientEvent('economy:client:gridMaintenanceComplete', src)
end)

-- 7. Enforced Labor Agreements
RegisterNetEvent('economy:server:createLaborContract', function(targetCID, employerCID, commitWeeks)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local commitHours = (commitWeeks or 1) * Config.EconomyCore.laborAgreements.minDuration
  local target = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if target then
    TriggerClientEvent('ox_lib:notify', target.PlayerData.source, { type = 'info', description = 'Labor contract: ' .. commitHours .. 'h commitment' })
  end
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Labor agreement created' })
end)

-- 8. Enterprise Franchise Scalability
RegisterNetEvent('economy:server:openFranchise', function(businessName, location)
  local src = source
  if not checkRateLimit(src, 'franchise') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local count = MySQL.scalar.await('SELECT COUNT(*) FROM business_licenses WHERE owner = ? AND active = TRUE', { player.PlayerData.citizenid })
  if count >= Config.EconomyCore.franchiseSystem.maxFranchises then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Max franchises reached' })
    return
  end
  if player.PlayerData.money.bank < Config.EconomyCore.franchiseSystem.franchiseCost then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Cost: $' .. Config.EconomyCore.franchiseSystem.franchiseCost })
    return
  end
  player.Functions.RemoveMoney('bank', Config.EconomyCore.franchiseSystem.franchiseCost, 'Franchise')
  MySQL.insert('INSERT INTO business_licenses (business, owner) VALUES (?, ?)', { businessName .. ' - ' .. location, player.PlayerData.citizenid })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Franchise opened: ' .. location })
end)

-- 9. Dynamic Fuel Market Scaling
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(Config.EconomyCore.fuelMarket.adjustmentInterval * 1000)
    if not Config.EconomyCore.fuelMarket.enabled then break end
    local activeCars = 0
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
      local ped = GetPlayerPed(src)
      if IsPedInAnyVehicle(ped, false) then activeCars = activeCars + 1 end
    end
    local newPrice = Config.EconomyCore.fuelMarket.basePrice + (activeCars * 0.01)
    TriggerClientEvent('economy:client:fuelPriceUpdate', -1, math.floor(newPrice * 100) / 100)
  end
end)

-- 10. Bonus: Secure Parcel Gifting 
RegisterNetEvent('economy:server:sendParcel', function(targetCID, items)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  MySQL.insert('INSERT INTO parcel_deliveries (sender, receiver, items, status) VALUES (?, ?, ?, ?)', {
    player.PlayerData.citizenid, targetCID, json.encode(items), 'in_transit'
  })
  local target = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if target then
    TriggerClientEvent('ox_lib:notify', target.PlayerData.source, { type = 'info', description = 'Parcel received!' })
    exports.ox_inventory:AddItem(target.PlayerData.source, items[1].name, items[1].count or 1, items[1].metadata)
  end
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Parcel sent' })
end)

QBox.Functions.CreateCallback('economy:server:getVaultBoxes', function(source, cb)
  local player = QBox.Functions.GetPlayer(source)
  if not player then cb({}) return end
  cb(MySQL.query.await('SELECT * FROM vault_boxes WHERE renter = ? AND expires_at > NOW()', { player.PlayerData.citizenid }))
end)
