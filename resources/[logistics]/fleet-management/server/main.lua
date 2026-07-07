local QBox = exports['qbx_core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, action)
  local key = src .. ':' .. action; local now = os.time()
  RATE_LIMITS[key] = RATE_LIMITS[key] or {}; table.insert(RATE_LIMITS[key], now)
  for i = #RATE_LIMITS[key], 1, -1 do if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end end
  local limit = Config.FleetManagement.rateLimits[action] or 10; return #RATE_LIMITS[key] <= limit
end

-- 1. Mechanical Component Degradation
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(Config.FleetManagement.componentDegradation.checkInterval)
    if not Config.FleetManagement.componentDegradation.enabled then break end
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
      local ped = GetPlayerPed(src)
      if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local speed = GetEntitySpeed(vehicle) * 3.6
        if speed > 10 then
          local engineHealth = GetVehicleEngineHealth(vehicle)
          local newHealth = engineHealth - (Config.FleetManagement.componentDegradation.ratePerKm * (speed / 100))
          SetVehicleEngineHealth(vehicle, math.max(newHealth, 0))
        end
      end
    end
  end
end)

-- 2. Dynamic P2P Used Vehicle Lots
RegisterNetEvent('fleet:server:listVehicle', function(plate, price)
  local src = source
  if not checkRateLimit(src, 'listVehicle') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local count = MySQL.scalar.await('SELECT COUNT(*) FROM vehicle_listings WHERE citizenid = ? AND is_active = TRUE', { player.PlayerData.citizenid })
  if count >= Config.FleetManagement.p2pVehicleLots.maxListingsPerPlayer then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Max listings reached' })
    return
  end
  local vehicleData = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, player.PlayerData.citizenid })
  if not vehicleData then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Vehicle not found' })
    return
  end
  if player.PlayerData.money.cash < Config.FleetManagement.p2pVehicleLots.listingFee then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Listing fee: $' .. Config.FleetManagement.p2pVehicleLots.listingFee })
    return
  end
  player.Functions.RemoveMoney('cash', Config.FleetManagement.p2pVehicleLots.listingFee, 'Vehicle listing')
  MySQL.insert('INSERT INTO vehicle_listings (citizenid, plate, price, coords) VALUES (?, ?, ?, ?)', {
    player.PlayerData.citizenid, plate, price, json.encode(Config.FleetManagement.p2pVehicleLots.lotCoords)
  })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Listed for $' .. price })
end)

RegisterNetEvent('fleet:server:buyVehicle', function(listingId)
  local src = source
  if not checkRateLimit(src, 'buyVehicle') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local listing = MySQL.single.await('SELECT * FROM vehicle_listings WHERE id = ? AND is_active = TRUE', { listingId })
  if not listing then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Listing not available' })
    return
  end
  local totalCost = listing.price + math.floor(listing.price * Config.FleetManagement.p2pVehicleLots.salesTax)
  if player.PlayerData.money.bank < totalCost then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient funds (incl. tax: $' .. totalCost .. ')' })
    return
  end
  player.Functions.RemoveMoney('bank', totalCost, 'Vehicle purchase')
  local seller = QBox.Functions.GetPlayerByCitizenId(listing.citizenid)
  if seller then
    seller.Functions.AddMoney('bank', listing.price, 'Vehicle sale')
    TriggerClientEvent('ox_lib:notify', seller.PlayerData.source, { type = 'success', description = 'Vehicle sold: $' .. listing.price })
  end
  MySQL.update('UPDATE player_vehicles SET citizenid = ? WHERE plate = ?', { player.PlayerData.citizenid, listing.plate })
  MySQL.update('UPDATE vehicle_listings SET is_active = FALSE WHERE id = ?', { listingId })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Purchased ' .. listing.plate .. ' for $' .. totalCost })
end)

-- 3. Heavy Cargo Freight Logistics
RegisterNetEvent('fleet:server:weighCargo', function(vehicleNetId)
  local src = source
  if not checkRateLimit(src, 'weigh') then return end
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicle then return end
  local weight = math.random(1000, 45000) -- simulated weight
  if weight > Config.FleetManagement.cargoFreight.maxWeight then
    local player = QBox.Functions.GetPlayer(src)
    if player then
      player.Functions.RemoveMoney('bank', Config.FleetManagement.cargoFreight.overWeightFine, 'Overweight fine')
      TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Overweight! Fine: $' .. Config.FleetManagement.cargoFreight.overWeightFine })
    end
  else
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Weight: ' .. weight .. 'kg - OK' })
  end
end)

-- 4. Persistent Odometer Telemetry
RegisterNetEvent('fleet:server:saveOdometer', function(plate, mileage)
  if not Config.FleetManagement.odometer.enabled then return end
  MySQL.update('UPDATE player_vehicles SET odometer = ? WHERE plate = ?', { math.floor(mileage or 0), plate })
end)

-- 5. High-Velocity Blowout Physics
RegisterNetEvent('fleet:server:blowoutTire', function(vehicleNetId, wheelIndex)
  if not Config.FleetManagement.blowoutPhysics.enabled then return end
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicle then return end
  SetVehicleTyreBurst(vehicle, wheelIndex, true, 1000.0)
end)

-- 6. Mobile Workshop Fleet
RegisterNetEvent('fleet:server:fieldBodyRepair', function(vehicleNetId)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if Config.FleetManagement.mobileWorkshop.jobRestriction and player.PlayerData.job.name ~= Config.FleetManagement.mobileWorkshop.jobRestriction then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local hasKit = exports.ox_inventory:GetItemCount(src, Config.FleetManagement.mobileWorkshop.toolKitItem, nil, true)
  if not hasKit or hasKit < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need toolkit' })
    return
  end
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicle then return end
  local hasBodyParts = exports.ox_inventory:GetItemCount(src, 'body_panels', nil, true)
  if not hasBodyParts or hasBodyParts < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need body panels' })
    return
  end
  exports.ox_inventory:RemoveItem(src, 'body_panels', 1)
  SetVehicleBodyHealth(vehicle, math.min(GetVehicleBodyHealth(vehicle) + 300.0, 1000.0))
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Body panels replaced' })
end)

-- 7. Car Chopping Syndicate Pipeline
RegisterNetEvent('fleet:server:chopPart', function(vehicleNetId, part)
  local src = source
  if not checkRateLimit(src, 'chop') then return end
  local chopZones = Config.FleetManagement.carChopping.chopZones
  local ped = GetPlayerPed(src)
  local coords = GetEntityCoords(ped)
  local inZone = false
  for _, zone in ipairs(chopZones) do
    if #(coords - zone.coords) < 10.0 then inZone = true break end
  end
  if not inZone then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not at a chop shop' })
    return
  end
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicle then return end
  local yields = { engine = 5, doors = 3, wheels = 2, transmission = 4, body = 6 }
  local qty = yields[part] or 1
  exports.ox_inventory:AddItem(src, 'scrap_metal', qty)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Chopped ' .. part .. ': +' .. qty .. ' scrap metal' })
end)

-- 8. Automated Tow Parking Citations
RegisterNetEvent('fleet:server:issueCitation', function(vehiclePlate, reason)
  local src = source
  if not checkRateLimit(src, 'cite') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local owner = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ?', { vehiclePlate })
  if owner then
    local ownerPlayer = QBox.Functions.GetPlayerByCitizenId(owner.citizenid)
    if ownerPlayer then
      ownerPlayer.Functions.RemoveMoney('bank', Config.FleetManagement.towCitations.citationFine, 'Tow citation')
      TriggerClientEvent('ox_lib:notify', ownerPlayer.PlayerData.source, { type = 'error', description = 'Tow citation: $' .. Config.FleetManagement.towCitations.citationFine })
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Citation issued to ' .. owner.citizenid })
  end
end)

-- 9. Tactical Window Tint Occlusion
RegisterNetEvent('fleet:server:applyTint', function(vehicleNetId, tintLevel)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local tintLevels = { none = 0, light = 1, medium = 2, dark = 3, limo = 4 }
  local tintValue = tintLevels[tintLevel]
  if not tintValue then return end
  local hasTint = exports.ox_inventory:GetItemCount(src, 'window_tint_' .. tintLevel, nil, true)
  if not hasTint or hasTint < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need window tint film' })
    return
  end
  exports.ox_inventory:RemoveItem(src, 'window_tint_' .. tintLevel, 1)
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if vehicle then
    SetVehicleWindowTint(vehicle, tintValue)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Tint applied: ' .. tintLevel })
  end
end)

-- 10. Fleet Garage Log (saves on park)
RegisterNetEvent('fleet:server:logGarageEntry', function(plate, odometer)
  local src = source
  MySQL.insert('INSERT INTO fleet_garage_log (plate, citizenid, odometer) VALUES (?, ?, ?)', {
    plate, Player(src).state.cid, math.floor(odometer or 0)
  })
end)

QBox.Functions.CreateCallback('fleet:server:getListings', function(source, cb)
  cb(MySQL.query.await('SELECT * FROM vehicle_listings WHERE is_active = TRUE'))
end)

QBox.Functions.CreateCallback('fleet:server:getVehicleMileage', function(source, cb, plate)
  local data = MySQL.single.await('SELECT odometer FROM player_vehicles WHERE plate = ?', { plate })
  cb(data and data.odometer or 0)
end)
