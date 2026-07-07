local phoneOpen = false
local inCall = false
local callPeer = nil
local callTimer = nil

RegisterCommand('phone', function() TogglePhone() end)
RegisterKeyMapping('+phone', 'Open Phone', 'keyboard', 'm')
RegisterCommand('+phone', function() TogglePhone() end)

function TogglePhone()
    if phoneOpen then
        phoneOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ type = 'close' })
    else
        phoneOpen = true
        TriggerServerEvent('phone:open')
    end
end

RegisterNetEvent('phone:loadData', function(data)
    SendNUIMessage({ type = 'open', data = data, config = Config.Phone })
    SetNuiFocus(true, true)
end)

-- Call events
RegisterNetEvent('phone:incomingCall', function(data)
    SendNUIMessage({ type = 'incomingCall', caller = data.caller, callerName = data.callerName, callId = data.callId })
end)

RegisterNetEvent('phone:callConnected', function(data)
    inCall = true
    callPeer = data.peer
    SendNUIMessage({ type = 'callConnected', peer = data.peer, peerName = data.peerName })
    if Config.Phone.CallSettings.pmaVoiceIntegration then
        local success = pcall(function()
            exports['pma-voice']:setCallChannel(data.channel or 1)
        end)
        if not success then
            pcall(function()
                exports['pma-voice'].setCallChannel(data.channel or 1)
            end)
        end
    end
    if callTimer then Citizen.ClearTimeout(callTimer) end
    local start = GetGameTimer()
    callTimer = Citizen.CreateThread(function()
        while inCall do
            Citizen.Wait(1000)
            local elapsed = math.floor((GetGameTimer() - start) / 1000)
            SendNUIMessage({ type = 'callTimer', elapsed = elapsed })
        end
    end)
end)

RegisterNetEvent('phone:callEnded', function(data)
    inCall = false
    callPeer = nil
    if callTimer then
        callTimer = nil
    end
    if Config.Phone.CallSettings.pmaVoiceIntegration then
        local success = pcall(function()
            exports['pma-voice']:setCallChannel(0)
        end)
        if not success then
            pcall(function()
                exports['pma-voice'].setCallChannel(0)
            end)
        end
    end
    SendNUIMessage({ type = 'callEnded', reason = data.reason or 'ended' })
end)

RegisterNetEvent('phone:callMissed', function(data)
    SendNUIMessage({ type = 'callMissed', caller = data.caller, callerName = data.callerName })
end)

-- Data events
RegisterNetEvent('phone:contactAdded', function(contact)
    SendNUIMessage({ type = 'contactAdded', contact = contact })
end)

RegisterNetEvent('phone:messageSent', function(msg)
    SendNUIMessage({ type = 'messageSent', msg = msg })
end)

RegisterNetEvent('phone:newMessage', function(msg)
    SendNUIMessage({ type = 'newMessage', msg = msg })
    if not phoneOpen then
        Wrappers.Notify('New message from ' .. (msg.sender_name or 'Unknown'), 'info')
    end
end)

RegisterNetEvent('phone:bankBalance', function(bank, cash)
    SendNUIMessage({ type = 'bankBalance', bank = bank, cash = cash })
end)

RegisterNetEvent('phone:transferComplete', function(newBalance)
    SendNUIMessage({ type = 'transferComplete', balance = newBalance })
end)

RegisterNetEvent('phone:loadPhotos', function(photos)
    SendNUIMessage({ type = 'loadPhotos', photos = photos })
end)

RegisterNetEvent('phone:callHistory', function(history)
    SendNUIMessage({ type = 'callHistory', history = history })
end)

RegisterNetEvent('phone:loadVoicemails', function(voicemails)
    SendNUIMessage({ type = 'loadVoicemails', voicemails = voicemails })
end)

RegisterNetEvent('phone:voicemailSaved', function(data)
    SendNUIMessage({ type = 'voicemailSaved', data = data })
end)

RegisterNetEvent('phone:contactShared', function(data)
    SendNUIMessage({ type = 'contactShared', contact = data.contact, from = data.from })
end)

RegisterNetEvent('phone:setSpeaker', function(enabled)
    SendNUIMessage({ type = 'speakerChanged', enabled = enabled })
end)

RegisterNetEvent('phone:updatePlayerLocation', function(coords)
    SendNUIMessage({ type = 'updateLocation', lat = coords.x, lon = coords.y })
end)

-- NUI callbacks
RegisterNUICallback('close', function(_, cb) cb({ ok = true }) end)

RegisterNUICallback('dialNumber', function(data, cb)
    TriggerServerEvent('phone:dialNumber', data.number)
    cb({ ok = true })
end)

RegisterNUICallback('answerCall', function(_, cb)
    TriggerServerEvent('phone:answerCall')
    cb({ ok = true })
end)

RegisterNUICallback('endCall', function(_, cb)
    TriggerServerEvent('phone:endCall')
    cb({ ok = true })
end)

RegisterNUICallback('rejectCall', function(_, cb)
    TriggerServerEvent('phone:rejectCall')
    cb({ ok = true })
end)

RegisterNUICallback('sendVoicemail', function(data, cb)
    TriggerServerEvent('phone:sendVoicemail', data.callId, data.message)
    cb({ ok = true })
end)

RegisterNUICallback('getCallHistory', function(_, cb)
    TriggerServerEvent('phone:getCallHistory')
    cb({ ok = true })
end)

RegisterNUICallback('getVoicemails', function(_, cb)
    TriggerServerEvent('phone:getVoicemails')
    cb({ ok = true })
end)

RegisterNUICallback('addContact', function(data, cb)
    TriggerServerEvent('phone:addContact', data)
    cb({ ok = true })
end)

RegisterNUICallback('deleteContact', function(data, cb)
    TriggerServerEvent('phone:deleteContact', data.id)
    cb({ ok = true })
end)

RegisterNUICallback('updateContact', function(data, cb)
    TriggerServerEvent('phone:updateContact', data)
    cb({ ok = true })
end)

RegisterNUICallback('shareContact', function(data, cb)
    TriggerServerEvent('phone:shareContact', data.contactId, data.targetCid)
    cb({ ok = true })
end)

RegisterNUICallback('shareMyContact', function(data, cb)
    TriggerServerEvent('phone:shareMyContact', data.targetCid)
    cb({ ok = true })
end)

RegisterNUICallback('sendMessage', function(data, cb)
    TriggerServerEvent('phone:sendMessage', data)
    cb({ ok = true })
end)

RegisterNUICallback('getBankBalance', function(_, cb)
    TriggerServerEvent('phone:getBankBalance')
    cb({ ok = true })
end)

RegisterNUICallback('transferMoney', function(data, cb)
    TriggerServerEvent('phone:transferMoney', data)
    cb({ ok = true })
end)

RegisterNUICallback('savePhoto', function(data, cb)
    TriggerServerEvent('phone:savePhoto', data.imageData)
    cb({ ok = true })
end)

RegisterNUICallback('getPhotos', function(_, cb)
    TriggerServerEvent('phone:getPhotos')
    cb({ ok = true })
end)

RegisterNUICallback('deletePhoto', function(data, cb)
    TriggerServerEvent('phone:deletePhoto', data.id)
    cb({ ok = true })
end)

RegisterNUICallback('saveNote', function(data, cb)
    TriggerServerEvent('phone:saveNote', data)
    cb({ ok = true })
end)

RegisterNUICallback('getNotes', function(_, cb)
    TriggerServerEvent('phone:getNotes')
    cb({ ok = true })
end)

RegisterNUICallback('deleteNote', function(data, cb)
    TriggerServerEvent('phone:deleteNote', data.id)
    cb({ ok = true })
end)

RegisterNUICallback('saveCalendarEvent', function(data, cb)
    TriggerServerEvent('phone:saveCalendarEvent', data)
    cb({ ok = true })
end)

RegisterNUICallback('getCalendarEvents', function(_, cb)
    TriggerServerEvent('phone:getCalendarEvents')
    cb({ ok = true })
end)

RegisterNUICallback('deleteCalendarEvent', function(data, cb)
    TriggerServerEvent('phone:deleteCalendarEvent', data.id)
    cb({ ok = true })
end)

RegisterNUICallback('getWeather', function(_, cb)
    TriggerServerEvent('phone:getWeather')
    cb({ ok = true })
end)

RegisterNUICallback('getTweets', function(_, cb)
    TriggerServerEvent('phone:getTweets')
    cb({ ok = true })
end)

RegisterNUICallback('postTweet', function(data, cb)
    TriggerServerEvent('phone:postTweet', data.content)
    cb({ ok = true })
end)

RegisterNUICallback('likeTweet', function(data, cb)
    TriggerServerEvent('phone:likeTweet', data.tweetId)
    cb({ ok = true })
end)

RegisterNUICallback('retweet', function(data, cb)
    TriggerServerEvent('phone:retweet', data.tweetId)
    cb({ ok = true })
end)

RegisterNUICallback('commentTweet', function(data, cb)
    TriggerServerEvent('phone:commentTweet', data.tweetId, data.content)
    cb({ ok = true })
end)

RegisterNUICallback('getBlackChatRooms', function(_, cb)
    TriggerServerEvent('phone:getBlackChatRooms')
    cb({ ok = true })
end)

RegisterNUICallback('joinBlackChatRoom', function(data, cb)
    TriggerServerEvent('phone:joinBlackChatRoom', data.roomId)
    cb({ ok = true })
end)

RegisterNUICallback('sendBlackChatMessage', function(data, cb)
    TriggerServerEvent('phone:sendBlackChatMessage', data.roomId, data.content, data.selfDestruct)
    cb({ ok = true })
end)

RegisterNUICallback('addBlackChatMember', function(data, cb)
    TriggerServerEvent('phone:addBlackChatMember', data.roomId, data.targetCid)
    cb({ ok = true })
end)

RegisterNUICallback('removeBlackChatMember', function(data, cb)
    TriggerServerEvent('phone:removeBlackChatMember', data.roomId, data.targetCid)
    cb({ ok = true })
end)

RegisterNUICallback('getBlackChatMembers', function(data, cb)
    TriggerServerEvent('phone:getBlackChatMembers', data.roomId)
    cb({ ok = true })
end)

RegisterNUICallback('setSilentMode', function(data, cb)
    TriggerServerEvent('phone:setSilentMode', data.enabled)
    cb({ ok = true })
end)

RegisterNUICallback('setSpeaker', function(data, cb)
    TriggerServerEvent('phone:setSpeaker', data.enabled)
    cb({ ok = true })
end)

RegisterNUICallback('closePhone', function(_, cb)
    phoneOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('getCurrentLocation', function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    cb({ lat = coords.x, lon = coords.y })
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000)
        if phoneOpen then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            SendNUIMessage({ type = 'updateLocation', lat = coords.x, lon = coords.y })
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if inCall then
        TriggerServerEvent('phone:endCall')
    end
    if phoneOpen then
        SetNuiFocus(false, false)
        phoneOpen = false
    end
end)
