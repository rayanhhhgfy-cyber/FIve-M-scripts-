local QBox = exports['qbx_core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, action)
  local key = src .. ':' .. action; local now = os.time()
  RATE_LIMITS[key] = RATE_LIMITS[key] or {}; table.insert(RATE_LIMITS[key], now)
  for i = #RATE_LIMITS[key], 1, -1 do if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end end
  local limit = Config.Underground.rateLimits[action] or 10; return #RATE_LIMITS[key] <= limit
end

-- 1. Border-Smuggling (Air-Drop) Global Events
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(Config.Underground.borderSmuggling.interval * 1000)
    if not Config.Underground.borderSmuggling.enabled then break end
    local zone = Config.Underground.borderSmuggling.zones[math.random(#Config.Underground.borderSmuggling.zones)]
    local eventId = MySQL.insert.await('INSERT INTO smuggling_events (zone, status, drops_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 5 MINUTE))', { zone.label, 'active' })
    local crates = { 'weapon_crate', 'chemical_crate', 'money_crate' }
    local crateType = crates[math.random(#crates)]
    TriggerClientEvent('underground:client:airdrop', -1, zone.coords, eventId, crateType)
    local cidPlayers = QBox.Functions.GetPlayers()
    for _, src in ipairs(cidPlayers) do
      local player = QBox.Functions.GetPlayer(src)
      if player and player.PlayerData.job.name == 'cid' then
        TriggerClientEvent('ox_lib:notify', src, { type = 'warning', description = 'Smuggling air-drop detected: ' .. zone.label })
      end
    end
  end
end)

RegisterNetEvent('underground:server:claimDrop', function(eventId)
  local src = source
  local row = MySQL.single.await('SELECT * FROM smuggling_events WHERE id = ? AND status = ?', { eventId, 'active' })
  if not row then return end
  MySQL.update('UPDATE smuggling_events SET status = ?, claimed_by = ? WHERE id = ?', { 'claimed', Player(src).state.cid, eventId })
  local loot = math.random(1, 5)
  exports.ox_inventory:AddItem(src, 'weapon_crate', loot)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Claimed ' .. loot .. ' items' })
end)

-- 2. Mobile Refining Labs (RV Drug Cooking)
RegisterNetEvent('underground:server:deployLab', function(vehicleNetId)
  local src = source
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicle then return end
  local model = GetEntityModel(vehicle)
  local isRV = false
  for _, m in ipairs(Config.Underground.mobileLabs.rvModels) do
    if model == GetHashKey(m) then isRV = true break end
  end
  if not isRV then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not a suitable vehicle' })
    return
  end
  local plate = GetVehicleNumberPlateText(vehicle)
  MySQL.insert('INSERT INTO mobile_labs (owner, vehicle_plate, product, quantity, stability, coords) VALUES (?, ?, ?, ?, ?, ?)', {
    Player(src).state.cid, plate, 'meth', 0, 100, json.encode(GetEntityCoords(vehicle))
  })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Mobile lab deployed' })
end)

-- 3. Commercial Front Laundering Houses
RegisterNetEvent('underground:server:buyFront', function(businessName)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local allowed = false
  for _, b in ipairs(Config.Underground.frontLaundering.businesses) do
    if b == businessName then allowed = true break end
  end
  if not allowed then return end
  MySQL.insert('INSERT INTO front_businesses (citizenid, business) VALUES (?, ?)', { player.PlayerData.citizenid, businessName })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Purchased ' .. businessName })
end)

RegisterNetEvent('underground:server:launderMoney', function(amount)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local front = MySQL.single.await('SELECT * FROM front_businesses WHERE citizenid = ?', { player.PlayerData.citizenid })
  if not front then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No front business' })
    return
  end
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return end
  if player.PlayerData.money.cash < amount then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough cash' })
    return
  end
  player.Functions.RemoveMoney('cash', amount, 'Laundering')
  MySQL.update('UPDATE front_businesses SET dirty_money = dirty_money + ? WHERE citizenid = ?', { amount, player.PlayerData.citizenid })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = '$' .. amount .. ' queued for laundering' })
end)

-- 4. Wireless Syndicate Surveillance Arrays
RegisterNetEvent('underground:server:deployCamera', function(coords, heading)
  local src = source
  if not checkRateLimit(src, 'deployCamera') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local count = MySQL.scalar.await('SELECT COUNT(*) FROM surveillance_cams WHERE owner = ?', { player.PlayerData.citizenid })
  if count >= Config.Underground.surveillanceCams.maxCamsPerPlayer then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Max cameras deployed' })
    return
  end
  MySQL.insert('INSERT INTO surveillance_cams (owner, coords, heading) VALUES (?, ?, ?)', {
    player.PlayerData.citizenid, json.encode(coords), heading
  })
  exports.ox_inventory:RemoveItem(src, 'surveillance_cam', 1)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Camera deployed' })
end)

-- 5. Detonator-Linked Hostage Shells
RegisterNetEvent('underground:server:attachExplosive', function(targetSrc)
  local src = source
  local hasDetonator = exports.ox_inventory:GetItemCount(src, 'detonator', nil, true)
  if not hasDetonator or hasDetonator < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need a detonator' })
    return
  end
  exports.ox_inventory:RemoveItem(src, 'detonator', 1)
  TriggerClientEvent('underground:client:attachedExplosive', targetSrc, src)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Explosive attached' })
end)

RegisterNetEvent('underground:server:detonate', function(targetSrc)
  local src = source
  local coords = GetEntityCoords(GetPlayerPed(targetSrc))
  TriggerClientEvent('underground:client:detonateExplosion', -1, coords, src)
  local players = QBox.Functions.GetPlayers()
  for _, p in ipairs(players) do
    local ped = GetPlayerPed(p)
    if DoesEntityExist(ped) then
      local pCoords = GetEntityCoords(ped)
      if #(coords - pCoords) <= Config.Underground.hostageShells.explosionRadius then
        ApplyDamageToPed(ped, Config.Underground.hostageShells.damage, false)
      end
    end
  end
end)

-- 6. ATM Skimming Hardware Interceptor
RegisterNetEvent('underground:server:installSkimmer', function(atmCoords)
  local src = source
  if not checkRateLimit(src, 'skinATM') then return end
  local hasSkimmer = exports.ox_inventory:GetItemCount(src, 'atm_skimmer', nil, true)
  if not hasSkimmer or hasSkimmer < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need ATM skimmer' })
    return
  end
  exports.ox_inventory:RemoveItem(src, 'atm_skimmer', 1)
  MySQL.insert('INSERT INTO atm_skimmers (atm_coords, owner) VALUES (?, ?)', { json.encode(atmCoords), Player(src).state.cid })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Skimmer installed' })
end)

-- 7. Syndicate Renown Stack (Reputation Core)
RegisterNetEvent('underground:server:addRenown', function(gangName, xpAmount)
  if not Config.Underground.gangRenown.enabled then return end
  local row = MySQL.single.await('SELECT * FROM gang_renown WHERE gang = ?', { gangName })
  if not row then
    MySQL.insert('INSERT INTO gang_renown (gang, xp) VALUES (?, ?)', { gangName, xpAmount or Config.Underground.gangRenown.xpPerRobbery })
    return
  end
  local newXp = row.xp + (xpAmount or Config.Underground.gangRenown.xpPerRobbery)
  local newLevel = row.level
  for lvl = row.level, #Config.Underground.gangRenown.levels do
    if newXp >= lvl * 500 then newLevel = lvl end
  end
  MySQL.update('UPDATE gang_renown SET xp = ?, level = ? WHERE gang = ?', { newXp, newLevel, gangName })
  if newLevel > row.level then
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
      local p = QBox.Functions.GetPlayer(src)
      if p and p.PlayerData.gang.name == gangName then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gang renown level ' .. newLevel .. ' reached!' })
      end
    end
  end
end)

-- 8. Encrypted Black Market App
RegisterNetEvent('underground:server:listItem', function(itemName, price)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local hasItem = exports.ox_inventory:GetItemCount(src, itemName, nil, true)
  if not hasItem or hasItem < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Item not found' })
    return
  end
  exports.ox_inventory:RemoveItem(src, itemName, 1)
  MySQL.insert('INSERT INTO black_market_listings (seller, item, price) VALUES (?, ?, ?)', { player.PlayerData.citizenid, itemName, price })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Listed ' .. itemName .. ' for $' .. price })
end)

-- 9. Grid-Failure Prison Breakout
RegisterNetEvent('underground:server:gridFailure', function()
  local src = source
  local row = MySQL.single.await('SELECT * FROM prison_escape_progress WHERE id = 1')
  if not row then
    MySQL.insert('INSERT INTO prison_escape_progress (power_down) VALUES (TRUE)')
  else
    MySQL.update('UPDATE prison_escape_progress SET power_down = TRUE WHERE id = 1')
  end
  TriggerClientEvent('underground:client:prisonPowerDown', -1)
end)

RegisterNetEvent('underground:server:breachGate', function()
  local src = source
  local hasC4 = exports.ox_inventory:GetItemCount(src, 'c4_charge', nil, true)
  if not hasC4 or hasC4 < Config.Underground.prisonBreakout.gateC4Required then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need ' .. Config.Underground.prisonBreakout.gateC4Required .. ' C4 charges' })
    return
  end
  exports.ox_inventory:RemoveItem(src, 'c4_charge', Config.Underground.prisonBreakout.gateC4Required)
  MySQL.update('UPDATE prison_escape_progress SET gate_destroyed = TRUE WHERE id = 1')
  MySQL.query('DELETE FROM prison_escape_progress WHERE id = 1 AND power_down = TRUE AND gate_destroyed = TRUE')
  TriggerClientEvent('ox_lib:notify', -1, { type = 'warning', description = 'PRISON BREAK! Gate breached!' })
end)

-- 10. Authoritative NPC Interrogations
RegisterNetEvent('underground:server:interrogate', function(targetNetId)
  local src = source
  if not checkRateLimit(src, 'interrogate') then return end
  if math.random() <= Config.Underground.npcInterrogations.complianceChance then
    local lootItems = { 'gold_watch', 'diamond_ring', 'cash_stack', 'lockbox_key' }
    local loot = lootItems[math.random(#lootItems)]
    local amount = math.random(1, 3)
    exports.ox_inventory:AddItem(src, loot, amount)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'NPC cracked! Found ' .. loot })
  else
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'NPC is not talking' })
  end
end)

-- 11 & 12: Additional handlers that get attached via the client

-- 12. Car Chopping Syndicate Pipeline
RegisterNetEvent('underground:server:chopVehicle', function(vehicleNetId, part)
  local src = source
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicle then return end
  local plate = GetVehicleNumberPlateText(vehicle)
  local partItems = {
    engine = { item = 'scrap_metal', qty = 5 },
    doors = { item = 'scrap_metal', qty = 3 },
    wheels = { item = 'scrap_metal', qty = 2 },
    transmission = { item = 'scrap_metal', qty = 4 },
  }
  local p = partItems[part]
  if not p then return end
  exports.ox_inventory:AddItem(src, p.item, p.qty)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Chopped ' .. part .. ': +' .. p.qty .. ' ' .. p.item })
end)
