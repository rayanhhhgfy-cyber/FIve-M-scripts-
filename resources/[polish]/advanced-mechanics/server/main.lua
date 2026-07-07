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
  local limit = Config.AdvancedMechanics.rateLimits[action] or 10
  return #RATE_LIMITS[key] <= limit
end

local function getPlayerJob(src)
  local player = QBox.Functions.GetPlayer(src)
  if not player then return nil end
  return player.PlayerData.job.name
end

local function getVehiclePlate(entity)
  return GetVehicleNumberPlateText(entity)
end

local function saveComponentDamage(plate, componentData)
  if not plate then return end
  local existing = MySQL.single.await('SELECT component_damage FROM player_vehicles WHERE plate = ?', { plate })
  local jsonData = json.encode(componentData)
  if existing then
    MySQL.update('UPDATE player_vehicles SET component_damage = ? WHERE plate = ?', { jsonData, plate })
  else
    -- If vehicle not tracked in player_vehicles, just skip
  end
end

local function loadComponentDamage(plate)
  if not plate then return {} end
  local row = MySQL.single.await('SELECT component_damage FROM player_vehicles WHERE plate = ?', { plate })
  if row and row.component_damage then
    return json.decode(row.component_damage) or {}
  end
  return {}
end

--- Field Repair: Basic Kit
RegisterNetEvent('advanced-mechanics:server:fieldRepair', function(vehicleNetId, kitType)
  local src = source
  if not checkRateLimit(src, 'fieldRepair') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local kitConfig = Config.AdvancedMechanics.fieldRepairs[kitType]
  if not kitConfig then return end
  if #kitConfig.allowedJobs > 0 then
    local job = getPlayerJob(src)
    local allowed = false
    for _, j in ipairs(kitConfig.allowedJobs) do
      if job == j then allowed = true break end
    end
    if not allowed then
      TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You lack the skill to use this' })
      return
    end
  end
  local hasKit = exports.ox_inventory:GetItemCount(src, kitConfig.item, nil, true)
  if not hasKit or hasKit < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need a ' .. kitConfig.item })
    return
  end
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicle or not DoesEntityExist(vehicle) then return end
  local plate = getVehiclePlate(vehicle)
  TriggerClientEvent('advanced-mechanics:client:doFieldRepair', src, vehicleNetId, kitType)
end)

RegisterNetEvent('advanced-mechanics:server:completeFieldRepair', function(vehicleNetId, kitType)
  local src = source
  if not checkRateLimit(src, 'fieldRepair') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local kitConfig = Config.AdvancedMechanics.fieldRepairs[kitType]
  if not kitConfig then return end
  local hasKit = exports.ox_inventory:GetItemCount(src, kitConfig.item, nil, true)
  if not hasKit or hasKit < 1 then return end
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicle or not DoesEntityExist(vehicle) then return end
  local engineHealth = GetVehicleEngineHealth(vehicle)
  local newEngineHealth = math.min(engineHealth + kitConfig.maxEngineRestore, 1000.0)
  SetVehicleEngineHealth(vehicle, newEngineHealth)
  if kitConfig.canFixTires then
    for i = 0, 5 do
      if IsVehicleTyreBurst(vehicle, i, false) then
        SetVehicleTyreFixed(vehicle, i)
      end
    end
  end
  SetVehicleBodyHealth(vehicle, math.min(GetVehicleBodyHealth(vehicle) + 200.0, 1000.0))
  exports.ox_inventory:RemoveItem(src, kitConfig.item, 1)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Repair complete' })
end)

--- Workshop: Diagnose
RegisterNetEvent('advanced-mechanics:server:diagnose', function(vehicleNetId)
  local src = source
  if not checkRateLimit(src, 'diagnose') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'mechanic' then return end
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicle or not DoesEntityExist(vehicle) then return end
  local plate = getVehiclePlate(vehicle)
  local componentData = loadComponentDamage(plate)
  if not componentData or next(componentData) == nil then
    componentData = {}
    for compKey, compDef in pairs(Config.AdvancedMechanics.components) do
      componentData[compKey] = compDef.maxHealth
    end
    saveComponentDamage(plate, componentData)
  end
  local dashboard = {}
  for compKey, compDef in pairs(Config.AdvancedMechanics.components) do
    local health = componentData[compKey] or compDef.maxHealth
    local pct = math.floor((health / compDef.maxHealth) * 100)
    table.insert(dashboard, {
      key = compKey,
      label = compDef.label,
      health = health,
      maxHealth = compDef.maxHealth,
      pct = pct,
      status = pct > 80 and 'Good' or (pct > 50 and 'Worn' or (pct > 25 and 'Damaged' or 'Critical'))
    })
  end
  TriggerClientEvent('advanced-mechanics:client:showDiagnosis', src, dashboard, plate)
end)

--- Workshop: Repair Component
RegisterNetEvent('advanced-mechanics:server:repairComponent', function(plate, componentKey)
  local src = source
  if not checkRateLimit(src, 'workshopRepair') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'mechanic' then return end
  local compDef = Config.AdvancedMechanics.components[componentKey]
  if not compDef then return end
  local hasPart = exports.ox_inventory:GetItemCount(src, compDef.restoreItem, nil, true)
  if not hasPart or hasPart < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need: ' .. compDef.restoreItem })
    return
  end
  local componentData = loadComponentDamage(plate)
  local currentHealth = componentData[componentKey] or compDef.maxHealth
  local restored = math.min(currentHealth + 250.0, compDef.maxHealth)
  componentData[componentKey] = restored
  saveComponentDamage(plate, componentData)
  exports.ox_inventory:RemoveItem(src, compDef.restoreItem, 1)
  local vehicle = GetVehiclePedIsIn(GetPlayerPed(src), false)
  if vehicle and vehicle ~= 0 then
    if componentKey == 'engine' then
      SetVehicleEngineHealth(vehicle, restored)
    elseif componentKey == 'body' then
      SetVehicleBodyHealth(vehicle, restored)
    end
  end
  local pct = math.floor((restored / compDef.maxHealth) * 100)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = compDef.label .. ' restored to ' .. pct .. '%' })
end)

--- Save vehicle state on garage park
RegisterNetEvent('advanced-mechanics:server:saveVehicleState', function(vehicleNetId)
  local src = source
  local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicle or not DoesEntityExist(vehicle) then return end
  local plate = getVehiclePlate(vehicle)
  if not plate then return end
  local compData = {}
  for compKey, compDef in pairs(Config.AdvancedMechanics.components) do
    if compKey == 'engine' then
      compData[compKey] = GetVehicleEngineHealth(vehicle)
    elseif compKey == 'body' then
      compData[compKey] = GetVehicleBodyHealth(vehicle)
    else
      compData[compKey] = compDef.maxHealth
    end
  end
  saveComponentDamage(plate, compData)
  local fuel = GetVehicleFuelLevel(vehicle)
  local odometer = GetEntityDistanceTraveled(vehicle)
  MySQL.update('UPDATE player_vehicles SET fuel = ?, engine_damage = ?, body_damage = ?, component_damage = ?, odometer = ?, last_parked = NOW() WHERE plate = ?', {
    math.floor(fuel or 100),
    1000.0 - GetVehicleEngineHealth(vehicle),
    1000.0 - GetVehicleBodyHealth(vehicle),
    json.encode(compData),
    math.floor(odometer or 0),
    plate
  })
end)

QBox.Functions.CreateCallback('advanced-mechanics:server:isInWorkshop', function(source, cb)
  local ped = GetPlayerPed(source)
  local coords = GetEntityCoords(ped)
  for _, zone in ipairs(Config.AdvancedMechanics.workshopZones) do
    local dist = #(coords - zone.coords)
    if dist <= zone.radius then
      cb(true, zone)
      return
    end
  end
  cb(false, nil)
end)
