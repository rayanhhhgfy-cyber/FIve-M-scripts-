local isCarrying = false
local carryTarget = nil

-- 1. Carry & Escort System
RegisterNetEvent('immersion:client:startCarry', function(targetSrc)
  isCarrying = true
  carryTarget = targetSrc
  local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
  if DoesEntityExist(targetPed) then
    AttachEntityToEntity(targetPed, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), Config.Immersion.carrySystem.carryBone), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
    TaskPlayAnim(PlayerPedId(), Config.Immersion.carrySystem.carryAnim.dict, Config.Immersion.carrySystem.carryAnim.clip, 8.0, -8.0, -1, Config.Immersion.carrySystem.carryAnim.flag, 0, false, false, false)
  end
end)

RegisterNetEvent('immersion:client:startEscort', function(targetSrc)
  isCarrying = true
  carryTarget = targetSrc
  local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
  if DoesEntityExist(targetPed) then
    TaskPlayAnim(targetPed, Config.Immersion.carrySystem.escortAnim.dict, Config.Immersion.carrySystem.escortAnim.clip, 8.0, -8.0, -1, Config.Immersion.carrySystem.escortAnim.flag, 0, false, false, false)
    AttachEntityToEntity(PlayerPedId(), targetPed, GetPedBoneIndex(targetPed, Config.Immersion.carrySystem.escortBone), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
  end
end)

RegisterNetEvent('immersion:client:stopCarry', function()
  if isCarrying then
    DetachEntity(PlayerPedId(), true, false)
    ClearPedTasks(PlayerPedId())
    if carryTarget then
      local tPed = GetPlayerPed(GetPlayerFromServerId(carryTarget))
      if DoesEntityExist(tPed) then
        DetachEntity(tPed, true, false)
        ClearPedTasks(tPed)
      end
    end
    isCarrying = false
    carryTarget = nil
  end
end)

RegisterCommand(Config.Immersion.carrySystem.unstickCommand, function()
  TriggerServerEvent('immersion:server:unstickCarry')
end, false)

-- 3. DJ Lighting
RegisterNetEvent('immersion:client:djEffect', function(venue, effect, value)
  if effect == 'smoke' then
    SetPtfxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord('ent_smoke_fire_small', venue.coords.x, venue.coords.y, venue.coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
  elseif effect == 'lighting' then
    SetArtificialLightState(true)
  end
end)

-- 4. InstaShots
RegisterNetEvent('immersion:client:newInstashot', function(post)
  Wrappers.Notify(post.username .. ' posted: ' .. (post.caption or ''), 'info')
end)

-- 5. Camping Deploy
RegisterNetEvent('immersion:client:deployObject', function(itemName, coords)
  local model = itemName == 'camping_tent' and 'prop_tent' or itemName == 'campfire_kit' and 'prop_beach_fire' or 'prop_chair'
  RequestModel(GetHashKey(model))
  while not HasModelLoaded(GetHashKey(model)) do Citizen.Wait(50) end
  local obj = CreateObject(GetHashKey(model), coords.x, coords.y, coords.z, false, false, false)
  FreezeEntityPosition(obj, true)
  Wrappers.Notify('Deployed ' .. itemName, 'success')
end)

-- 6. Racing
RegisterNetEvent('immersion:client:raceCreated', function(raceId, trackData)
  for _, checkpoint in ipairs(trackData) do
    local blip = AddBlipForCoord(checkpoint.x, checkpoint.y, checkpoint.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, false)
  end
  Wrappers.Notify('Race #' .. raceId .. ' created!', 'success')
end)

RegisterNetEvent('immersion:client:raceJoined', function(raceId)
  Wrappers.Notify('Joined race #' .. raceId, 'success')
end)

-- 7. RC Toys
RegisterNetEvent('immersion:client:spawnRCVehicle', function(modelName, coords)
  local model = GetHashKey(modelName)
  RequestModel(model)
  while not HasModelLoaded(model) do Citizen.Wait(50) end
  local veh = CreateVehicle(model, coords.x, coords.y, coords.z, 0.0, false, false)
  SetVehicleOnGroundProperly(veh)
  TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
  Wrappers.Notify('RC vehicle active (' .. Config.Immersion.rcToys.controlDuration .. 's)', 'success')
end)

RegisterNetEvent('immersion:client:rcTimeout', function()
  Wrappers.Notify('RC control timed out', 'info')
end)

-- 9. Outdoor Furniture
RegisterNetEvent('immersion:client:spawnFurniture', function(model, coords, heading)
  local obj = CreateObject(GetHashKey(model), coords.x, coords.y, coords.z, false, false, false)
  SetEntityHeading(obj, heading)
  FreezeEntityPosition(obj, true)
end)

-- 10. Weather Forecast
RegisterNetEvent('immersion:client:forecast', function(weather)
  Wrappers.Notify('Weather forecast: ' .. weather, 'info')
end)

-- Carry/escort via ox_target
CreateThread(function()
  exports['ox_target']:addGlobalPlayer({
    {
      name = 'carry_player',
      label = 'Carry',
      icon = 'fas fa-hand-paper',
      distance = 2.0,
      canInteract = function(entity)
        return IsPedDeadOrDying(entity) or IsPedFatallyInjured(entity)
      end,
      onSelect = function(entity)
        TriggerServerEvent('immersion:server:requestCarry', GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)))
      end
    },
    {
      name = 'escort_player',
      label = 'Escort',
      icon = 'fas fa-hand-holding',
      distance = 2.0,
      canInteract = function(entity)
        return not IsPedDeadOrDying(entity) and entity ~= PlayerPedId()
      end,
      onSelect = function(entity)
        TriggerServerEvent('immersion:server:requestEscort', GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)))
      end
    }
  })
end)

-- Release carry on key
RegisterCommand('releasecarry', function()
  if isCarrying then
    TriggerServerEvent('immersion:server:releaseCarry')
  end
end, false)
RegisterKeyMapping('releasecarry', 'Release Carry/Escort', 'keyboard', 'e')
