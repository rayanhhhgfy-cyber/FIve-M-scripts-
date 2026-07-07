RegisterNetEvent('trauma:client:autopsyResult', function(data)
  Wrappers.AlertDialog({
    title = 'Autopsy Report',
    content = 'Subject: ' .. data.citizenid .. '\nTime of Death: ' .. (data.time_of_death or 'Unknown') .. '\nWeapon: ' .. (data.weapon_used or 'Unknown') .. '\nAngle: ' .. (data.angle or 'N/A')
  })
end)

RegisterNetEvent('trauma:client:withdrawalTremor', function(enabled)
  if enabled then
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
  end
end)

RegisterNetEvent('trauma:client:infected', function(disease)
  Wrappers.Notify('You feel sick... (' .. disease .. ')', 'error')
end)

RegisterNetEvent('trauma:client:cured', function(disease)
  Wrappers.Notify('You were cured of ' .. disease, 'success')
end)

RegisterNetEvent('trauma:client:propagateFire', function(coords)
  local fire = StartScriptFire(coords.x, coords.y, coords.z, 5, true)
  Citizen.SetTimeout(30000, function()
    if fire then RemoveScriptFire(fire) end
  end)
end)

RegisterNetEvent('trauma:client:limbBroken', function(limb)
  Wrappers.Notify('Your ' .. limb .. ' is broken!', 'error')
  SetRunSprintMultiplierForPlayer(PlayerId(), 0.5)
end)

RegisterNetEvent('trauma:client:limbHealed', function(limb)
  Wrappers.Notify('Your ' .. limb .. ' has been healed', 'success')
  SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end)

RegisterNetEvent('trauma:client:medevacData', function(data)
  local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
  SetBlipSprite(blip, 153)
  SetBlipColour(blip, 1)
  SetBlipScale(blip, 1.5)
  SetBlipRoute(blip, true)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentSubstringPlayerName(data.name .. ' - HP: ' .. data.health)
  EndTextCommandSetBlipName(blip)
  SetTimeout(120000, function()
    if DoesBlipExist(blip) then RemoveBlip(blip) end
  end)
end)

RegisterNetEvent('trauma:client:toxicologyResult', function(results)
  if #results == 0 then
    Wrappers.Notify('Blood panel clean', 'success')
    return
  end
  local lines = {}
  for _, r in ipairs(results) do
    table.insert(lines, r.substance .. ': ' .. r.level .. '%')
  end
  Wrappers.AlertDialog({ title = 'Toxicology Report', content = table.concat(lines, '\n') })
end)

RegisterNetEvent('trauma:client:amnesiaBlind', function(duration)
  Wrappers.Notify('Memory loss! You cannot recall your attacker.', 'error')
  SetTimeout(duration * 1000, function()
    Wrappers.Notify('Memory slowly returning...', 'info')
  end)
end)
