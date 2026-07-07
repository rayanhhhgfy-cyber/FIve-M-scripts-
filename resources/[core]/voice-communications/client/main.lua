local currentChannel = nil
local channelType = nil
local speakerMode = false

RegisterNetEvent('voice:client:radioJoined', function(channel, ctype)
  currentChannel = channel
  channelType = ctype
end)

RegisterNetEvent('voice:client:radioLeft', function()
  currentChannel = nil
  channelType = nil
end)

RegisterNetEvent('voice:client:speakerToggled', function(enabled)
  speakerMode = enabled
  Wrappers.Notify(enabled and 'Speaker mode on' or 'Speaker mode off', enabled and 'success' or 'info')
end)

RegisterNetEvent('voice:client:panicWaypoint', function(coords, officerSrc)
  local job = exports['qbx_core']:GetPlayer(PlayerId())
  if not job or not job.PlayerData or job.PlayerData.job.name ~= 'police' then return end
  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(blip, 60)
  SetBlipColour(blip, 1)
  SetBlipScale(blip, 2.0)
  SetBlipAsShortRange(blip, false)
  SetBlipRoute(blip, true)
  SetBlipRouteColour(blip, 1)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentSubstringPlayerName('Panic Alert - Officer')
  EndTextCommandSetBlipName(blip)
  PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', false)
  SetTimeout(Config.VoiceComms.panicButton.waypointDuration, function()
    if DoesBlipExist(blip) then RemoveBlip(blip) end
  end)
end)

RegisterCommand(Config.VoiceComms.phoneSpeaker.toggleCommand, function()
  if not speakerMode then
    TriggerServerEvent('voice:server:toggleSpeaker', source, true)
  else
    TriggerServerEvent('voice:server:toggleSpeaker', source, false)
  end
end, false)

RegisterKeyMapping('+' .. Config.VoiceComms.phoneSpeaker.toggleCommand, 'Toggle Phone Speaker', 'keyboard', 'l')
