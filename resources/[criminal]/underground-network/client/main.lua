RegisterNetEvent('underground:client:airdrop', function(coords, eventId, crateType)
  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(blip, 501)
  SetBlipColour(blip, 1)
  SetBlipScale(blip, 2.0)
  SetBlipAsShortRange(blip, false)
  SetBlipRoute(blip, true)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentSubstringPlayerName('Smuggling Air-Drop')
  EndTextCommandSetBlipName(blip)
  Wrappers.Notify('Air-drop incoming: ' .. crateType, 'warning')
  SetTimeout(300000, function()
    if DoesBlipExist(blip) then RemoveBlip(blip) end
  end)
end)

RegisterNetEvent('underground:client:attachedExplosive', function(detOwner)
  Wrappers.Notify('Explosive device attached to you!', 'error')
end)

RegisterNetEvent('underground:client:detonateExplosion', function(coords)
  AddExplosion(coords.x, coords.y, coords.z, 2, 200.0, true, false, 1.0)
end)

RegisterNetEvent('underground:client:prisonPowerDown', function()
  Wrappers.Notify('City power grid failure detected!', 'warning')
end)

-- Camera deploy via ox_target
CreateThread(function()
  exports['ox_target']:addGlobalPlayer({
    {
      name = 'attach_explosive',
      label = 'Attach Explosive',
      icon = 'fas fa-bomb',
      distance = 2.0,
      canInteract = function(entity)
        local has = exports.ox_inventory:Search('count', 'detonator')
        return has and has > 0
      end,
      onSelect = function(entity)
        local target = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
        TriggerServerEvent('underground:server:attachExplosive', target)
      end
    }
  })
end)
