local QBox = exports['qbx_core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, action)
  local key = src .. ':' .. action; local now = os.time()
  RATE_LIMITS[key] = RATE_LIMITS[key] or {}; table.insert(RATE_LIMITS[key], now)
  for i = #RATE_LIMITS[key], 1, -1 do if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end end
  local limit = Config.Immersion.rateLimits[action] or 10; return #RATE_LIMITS[key] <= limit
end

-- 1. Server-Authoritative Physics Carry & Escort System
local carryStates = {}

RegisterNetEvent('immersion:server:requestCarry', function(targetSrc)
  local src = source
  if not checkRateLimit(src, 'carry') then return end
  local targetPed = GetPlayerPed(targetSrc)
  if not DoesEntityExist(targetPed) then return end
  if IsPedDeadOrDying(targetPed) or IsEntityPlayingAnim(targetPed, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_loaded', 3) then
    carryStates[src] = { target = targetSrc, type = 'carry' }
    carryStates[targetSrc] = { target = src, type = 'carried' }
    TriggerClientEvent('immersion:client:startCarry', targetSrc, src)
    TriggerClientEvent('immersion:client:startCarry', src, targetSrc)
  end
end)

RegisterNetEvent('immersion:server:requestEscort', function(targetSrc)
  local src = source
  if not checkRateLimit(src, 'carry') then return end
  carryStates[src] = { target = targetSrc, type = 'escort' }
  carryStates[targetSrc] = { target = src, type = 'escorted' }
  TriggerClientEvent('immersion:client:startEscort', targetSrc, src)
  TriggerClientEvent('immersion:client:startEscort', src, targetSrc)
end)

RegisterNetEvent('immersion:server:releaseCarry', function()
  local src = source
  local state = carryStates[src]
  if not state then return end
  local target = state.target
  TriggerClientEvent('immersion:client:stopCarry', src)
  TriggerClientEvent('immersion:client:stopCarry', target)
  carryStates[src] = nil
  carryStates[target] = nil
end)

RegisterNetEvent('immersion:server:unstickCarry', function()
  local src = source
  local state = carryStates[src]
  if state then
    TriggerClientEvent('immersion:client:stopCarry', src)
    TriggerClientEvent('immersion:client:stopCarry', state.target)
    carryStates[src] = nil
    carryStates[state.target] = nil
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Carry state reset' })
  end
end)

-- 2. Synchronized AV Media Shacks
RegisterNetEvent('immersion:server:syncMedia', function(houseId, currentTime, isPlaying)
  TriggerClientEvent('immersion:client:syncMedia', -1, houseId, currentTime, isPlaying)
end)

-- 3. Club-Grid DJ Lighting Matrices
RegisterNetEvent('immersion:server:djControl', function(venue, effect, value)
  TriggerClientEvent('immersion:client:djEffect', -1, venue, effect, value)
end)

-- 4. Native Social Media Ecosystem (InstaShots)
RegisterNetEvent('immersion:server:postInstashot', function(imageUrl, caption)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local cid = player.PlayerData.citizenid
  local profile = MySQL.single.await('SELECT * FROM instashot_profiles WHERE citizenid = ?', { cid })
  if not profile then
    MySQL.insert('INSERT INTO instashot_profiles (citizenid, username) VALUES (?, ?)', { cid, player.PlayerData.charinfo.firstname .. '.' .. player.PlayerData.charinfo.lastname })
  end
  MySQL.insert('INSERT INTO instashot_posts (citizenid, image_url, caption) VALUES (?, ?, ?)', { cid, imageUrl or '', caption or '' })
  TriggerClientEvent('immersion:client:newInstashot', -1, {
    username = profile and profile.username or (player.PlayerData.charinfo.firstname .. '.' .. player.PlayerData.charinfo.lastname),
    image_url = imageUrl,
    caption = caption,
  })
end)

RegisterNetEvent('immersion:server:likeInstashot', function(postId)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  MySQL.update('UPDATE instashot_posts SET likes = likes + 1 WHERE id = ?', { postId })
  local post = MySQL.single.await('SELECT citizenid FROM instashot_posts WHERE id = ?', { postId })
  if post then
    MySQL.update('UPDATE instashot_profiles SET fame = fame + ? WHERE citizenid = ?', { Config.Immersion.instashots.famePerLike, post.citizenid })
  end
end)

-- 5. Expeditionary Camping & Wildwood Hunting
RegisterNetEvent('immersion:server:deployCamp', function(itemName, coords)
  local src = source
  if not checkRateLimit(src, 'deploy') then return end
  local hasItem = exports.ox_inventory:GetItemCount(src, itemName, nil, true)
  if not hasItem or hasItem < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Item not found' })
    return
  end
  exports.ox_inventory:RemoveItem(src, itemName, 1)
  TriggerClientEvent('immersion:client:deployObject', src, itemName, coords)
end)

-- 6. Automated Racing & Marathon Brackets
local activeRaces = {}

RegisterNetEvent('immersion:server:startRace', function(prizePool, trackData)
  local src = source
  if not checkRateLimit(src, 'startRace') then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  if player.PlayerData.money.bank < prizePool then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient prize pool funds' })
    return
  end
  player.Functions.RemoveMoney('bank', prizePool, 'Race prize pool')
  local raceId = #activeRaces + 1
  activeRaces[raceId] = {
    organizer = src,
    prizePool = prizePool,
    track = trackData,
    participants = { src },
    status = 'waiting'
  }
  MySQL.insert('INSERT INTO racing_events (organizer, track, prize_pool, status) VALUES (?, ?, ?, ?)', {
    Player(src).state.cid, json.encode(trackData), prizePool, 'waiting'
  })
  TriggerClientEvent('immersion:client:raceCreated', src, raceId, trackData)
end)

RegisterNetEvent('immersion:server:joinRace', function(raceId)
  local src = source
  local race = activeRaces[raceId]
  if not race or race.status ~= 'waiting' then return end
  if #race.participants >= Config.Immersion.racing.maxRacers then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Race full' })
    return
  end
  table.insert(race.participants, src)
  TriggerClientEvent('immersion:client:raceJoined', src, raceId)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Joined race #' .. raceId })
end)

RegisterNetEvent('immersion:server:finishRace', function(raceId, winnerSrc)
  local race = activeRaces[raceId]
  if not race then return end
  race.status = 'finished'
  local winner = QBox.Functions.GetPlayer(winnerSrc)
  if winner then
    winner.Functions.AddMoney('bank', race.prizePool, 'Race winnings')
    TriggerClientEvent('ox_lib:notify', winnerSrc, { type = 'success', description = 'You won $' .. race.prizePool })
  end
  MySQL.update('UPDATE racing_events SET status = ? WHERE id = ?', { 'finished', raceId })
  activeRaces[raceId] = nil
end)

-- 7. Remote-Controlled Scale Flight Toys
RegisterNetEvent('immersion:server:spawnRCToy', function(modelName, coords)
  local src = source
  if not checkRateLimit(src, 'rcControl') then return end
  local allowed = false
  for _, m in ipairs(Config.Immersion.rcToys.vehicles) do if m == modelName then allowed = true break end end
  if not allowed then return end
  local hasItem = exports.ox_inventory:GetItemCount(src, 'rc_controller', nil, true)
  if not hasItem or hasItem < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need RC controller' })
    return
  end
  TriggerClientEvent('immersion:client:spawnRCVehicle', src, modelName, coords)
  Citizen.SetTimeout(Config.Immersion.rcToys.controlDuration * 1000, function()
    TriggerClientEvent('immersion:client:rcTimeout', src)
  end)
end)

-- 8. Forensic Camera Snapshot Interfaces
RegisterNetEvent('immersion:server:savePhoto', function(imageUrl, metadata)
  local src = source
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  MySQL.insert('INSERT INTO id_card_logs (citizenid, action, data) VALUES (?, ?, ?)', {
    player.PlayerData.citizenid, 'photo', json.encode({ url = imageUrl, meta = metadata })
  })
  -- Also fire for MDT integration
  local cops = QBox.Functions.GetPlayers()
  for _, p in ipairs(cops) do
    local officer = QBox.Functions.GetPlayer(p)
    if officer and officer.PlayerData.job.name == 'police' then
      TriggerClientEvent('ox_lib:notify', p, { type = 'info', description = 'Forensic photo saved' })
    end
  end
end)

-- 9. Dynamic Outdoor Lounge Furniture
RegisterNetEvent('immersion:server:placeFurniture', function(model, coords, heading)
  local src = source
  TriggerClientEvent('immersion:client:spawnFurniture', -1, model, coords, heading, src)
end)

-- 10. Meteorological & Astronomical Forecasting
RegisterNetEvent('immersion:server:getForecast', function()
  local src = source
  local weather = 'SUNNY'
  if GetRainLevel() > 0.1 then weather = 'RAIN' elseif GetSnowLevel() > 0.1 then weather = 'SNOW' end
  TriggerClientEvent('immersion:client:forecast', src, weather)
end)

QBox.Functions.CreateCallback('immersion:server:getInstashots', function(source, cb)
  cb(MySQL.query.await('SELECT * FROM instashot_posts ORDER BY created_at DESC LIMIT 30'))
end)

-- Cleanup carry states on disconnect
AddEventHandler('playerDropped', function()
  local src = source
  local state = carryStates[src]
  if state then
    TriggerClientEvent('immersion:client:stopCarry', state.target)
    carryStates[state.target] = nil
    carryStates[src] = nil
  end
end)
