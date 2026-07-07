local cidReady = false
local myCID = ''

RegisterNetEvent('identity:client:cidReady', function(citizenid)
  myCID = citizenid
  cidReady = true
  LocalPlayer.state:set(Config.Identity.stateBagKey, citizenid, true)
end)

RegisterNetEvent('ox:playerLoaded', function()
  Citizen.SetTimeout(500, function()
    local existingCID = LocalPlayer.state[Config.Identity.stateBagKey]
    if existingCID then
      myCID = existingCID
      cidReady = true
    end
  end)
end)

function GetMyCID()
  if not cidReady then
    local bagCID = LocalPlayer.state[Config.Identity.stateBagKey]
    if bagCID then
      myCID = bagCID
      cidReady = true
      return myCID
    end
    return nil
  end
  return myCID
end

function IsCIDReady()
  return cidReady
end

exports('GetMyCID', GetMyCID)
exports('IsCIDReady', IsCIDReady)
