local QBox = exports['qbx_core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, action)
  local key = src .. ':' .. action; local now = os.time()
  RATE_LIMITS[key] = RATE_LIMITS[key] or {}; table.insert(RATE_LIMITS[key], now)
  for i = #RATE_LIMITS[key], 1, -1 do if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end end
  local limit = Config.AdvancedTrauma.rateLimits[action] or 10; return #RATE_LIMITS[key] <= limit
end

-- 1. Post-Mortem Autopsy Core
RegisterNetEvent('trauma:server:conductAutopsy', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'autopsy') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local jobOk = false
  for _, j in ipairs(Config.AdvancedTrauma.autopsy.allowedJobs) do
    if player.PlayerData.job.name == j then jobOk = true break end
  end
  if not jobOk then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local existing = MySQL.single.await('SELECT * FROM autopsy_reports WHERE citizenid = ?', { targetCID })
  if existing then
    TriggerClientEvent('trauma:client:autopsyResult', src, existing)
  else
    TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'No autopsy on record for ' .. targetCID })
  end
end)

-- 2. Chemical Dependency & Withdrawal Loop
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(Config.AdvancedTrauma.addiction.checkInterval * 1000)
    if not Config.AdvancedTrauma.addiction.enabled then break end
    local addictions = MySQL.query.await('SELECT * FROM addiction_trackers WHERE dependency > 0')
    for _, add in ipairs(addictions) do
      local target = QBox.Functions.GetPlayerByCitizenId(add.citizenid)
      if target then
        local subDef = Config.AdvancedTrauma.addiction.substances[add.substance]
        if subDef and add.dependency > 50 then
          if subDef.withdrawalDebuffs.tremor then
            TriggerClientEvent('trauma:client:withdrawalTremor', target.PlayerData.source, true)
          end
          if target.PlayerData.metadata.stamina then
            exports['qbx_core']:SetPlayerStamina(target.PlayerData.source, target.PlayerData.metadata.stamina - subDef.withdrawalDebuffs.staminaDrain)
          end
        end
      end
    end
  end
end)

RegisterNetEvent('trauma:server:useSubstance', function(substance)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local subDef = Config.AdvancedTrauma.addiction.substances[substance]
  if not subDef then return end
  local row = MySQL.single.await('SELECT * FROM addiction_trackers WHERE citizenid = ? AND substance = ?', { player.PlayerData.citizenid, substance })
  if row then
    MySQL.update('UPDATE addiction_trackers SET dependency = LEAST(dependency + ?, 100), last_dose = NOW() WHERE id = ?', { subDef.dependencyRate, row.id })
  else
    MySQL.insert('INSERT INTO addiction_trackers (citizenid, substance, dependency) VALUES (?, ?, ?)', { player.PlayerData.citizenid, substance, subDef.dependencyRate })
  end
end)

-- 3. Dynamic Vector Pathogens
RegisterNetEvent('trauma:server:infectPlayer', function(targetSrc, disease)
  local src = source
  local diseaseDef = Config.AdvancedTrauma.vectorPathogens.diseases[disease]
  if not diseaseDef then return end
  if math.random() <= diseaseDef.transmissionChance then
    TriggerClientEvent('trauma:client:infected', targetSrc, disease)
    TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'error', description = 'You were infected with ' .. diseaseDef.label })
  end
end)

RegisterNetEvent('trauma:server:cureDisease', function(targetSrc, disease)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'ambulance' then return end
  local diseaseDef = Config.AdvancedTrauma.vectorPathogens.diseases[disease]
  if not diseaseDef then return end
  local hasCure = exports.ox_inventory:GetItemCount(src, diseaseDef.cureItem, nil, true)
  if not hasCure or hasCure < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need ' .. diseaseDef.cureItem })
    return
  end
  exports.ox_inventory:RemoveItem(src, diseaseDef.cureItem, 1)
  TriggerClientEvent('trauma:client:cured', targetSrc, disease)
end)

-- 4. Validated Blood Bank Allocation
RegisterNetEvent('trauma:server:donateBlood', function(bloodType)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local valid = false
  for _, bt in ipairs(Config.AdvancedTrauma.bloodBank.types) do if bt == bloodType then valid = true break end end
  if not valid then return end
  MySQL.insert('INSERT INTO blood_bank (donor, blood_type) VALUES (?, ?)', { player.PlayerData.citizenid, bloodType })
  exports.ox_inventory:RemoveItem(src, 'blood_sample', 1)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Blood donated: ' .. bloodType })
end)

RegisterNetEvent('trauma:server:transfuseBlood', function(targetSrc, bloodType)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'ambulance' then return end
  local blood = MySQL.single.await('SELECT * FROM blood_bank WHERE blood_type = ? AND id > 0 LIMIT 1', { bloodType })
  if not blood then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No ' .. bloodType .. ' in blood bank' })
    return
  end
  MySQL.query('DELETE FROM blood_bank WHERE id = ?', { blood.id })
  TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'success', description = 'Transfusion complete: ' .. bloodType })
end)

-- 5. Procedural Fire Propagation Engine
RegisterNetEvent('trauma:server:startFire', function(coords)
  local src = source
  TriggerClientEvent('trauma:client:propagateFire', -1, coords)
end)

-- 6. Skeletal Prosthetics & Compound Trauma
RegisterNetEvent('trauma:server:limbDamage', function(targetSrc, limb)
  local src = source
  TriggerClientEvent('trauma:client:limbBroken', targetSrc, limb)
end)

RegisterNetEvent('trauma:server:repairLimb', function(targetSrc, limb)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'ambulance' then return end
  local hasSupplies = exports.ox_inventory:GetItemCount(src, 'splint', nil, true)
  if not hasSupplies or hasSupplies < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need splint' })
    return
  end
  exports.ox_inventory:RemoveItem(src, 'splint', 1)
  TriggerClientEvent('trauma:client:limbHealed', targetSrc, limb)
end)

-- 7. Medevac Aerial Telemetry Arrays
RegisterNetEvent('trauma:server:medevacScan', function(targetCID)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'ambulance' then return end
  local target = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if not target then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Patient not found' })
    return
  end
  local health = GetEntityHealth(GetPlayerPed(target.PlayerData.source))
  local coords = GetEntityCoords(GetPlayerPed(target.PlayerData.source))
  TriggerClientEvent('trauma:client:medevacData', src, {
    name = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname,
    health = health,
    coords = coords
  })
end)

-- 8. Toxicological Diagnostic Terminals
RegisterNetEvent('trauma:server:bloodTest', function(targetSrc)
  local src = source
  if not checkRateLimit(src, 'diagnose') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local target = QBox.Functions.GetPlayer(targetSrc)
  if not target then return end
  local addictions = MySQL.query.await('SELECT * FROM addiction_trackers WHERE citizenid = ?', { target.PlayerData.citizenid })
  local results = {}
  for _, add in ipairs(addictions) do
    local subDef = Config.AdvancedTrauma.addiction.substances[add.substance]
    if subDef then
      table.insert(results, { substance = subDef.label, level = add.dependency })
    end
  end
  TriggerClientEvent('trauma:client:toxicologyResult', src, results)
end)

-- 9. Trauma-Induced Amnesia Pipeline
RegisterNetEvent('trauma:server:applyAmnesia', function(targetSrc)
  if not Config.AdvancedTrauma.amnesia.enabled then return end
  TriggerClientEvent('trauma:client:amnesiaBlind', targetSrc, Config.AdvancedTrauma.amnesia.duration)
end)

-- 10. Field Trauma Deployable Kits
RegisterNetEvent('trauma:server:deployFieldKit', function(coords)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local count = MySQL.scalar.await('SELECT COUNT(*) FROM field_medical_kits WHERE owner = ? AND is_deployed = TRUE', { player.PlayerData.citizenid })
  if count >= Config.AdvancedTrauma.fieldKits.maxKitsPerPlayer then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Max kits deployed' })
    return
  end
  MySQL.insert('INSERT INTO field_medical_kits (owner, items, coords, is_deployed) VALUES (?, ?, ?, TRUE)', {
    player.PlayerData.citizenid, json.encode({}), json.encode(coords)
  })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Field kit deployed' })
end)

RegisterNetEvent('trauma:server:restockFieldKit', function(kitId)
  local src = source
  if not checkRateLimit(src, 'restock') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player or player.PlayerData.job.name ~= 'ambulance' then return end
  local kit = MySQL.single.await('SELECT * FROM field_medical_kits WHERE id = ?', { kitId })
  if not kit then return end
  local currentItems = json.decode(kit.items) or {}
  for _, item in ipairs(Config.AdvancedTrauma.fieldKits.restockItems) do
    currentItems[item] = (currentItems[item] or 0) + 5
  end
  MySQL.update('UPDATE field_medical_kits SET items = ? WHERE id = ?', { json.encode(currentItems), kitId })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Field kit restocked' })
end)
