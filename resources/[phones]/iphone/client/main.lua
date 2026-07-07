local QBox = exports['qbx-core']:GetCoreObject()
local phoneOpen = false
local batteryLevel = Config.Phone.BatteryMax
local phoneEnabled = true
local contacts = {}
local messages = {}
local photos = {}
local videos = {}
local notes = {}
local callHistory = {}

local function hasPhone() return QBox.Functions.HasItem(Config.Phone.ItemName) end

local function getMyNumber()
    local pData = QBox.Functions.GetPlayerData()
    return pData and pData.charinfo and pData.charinfo.phone or nil
end

local function getMyCitizenId()
    local pData = QBox.Functions.GetPlayerData()
    return pData and pData.citizenid or nil
end

RegisterCommand('+phone', function()
    if not hasPhone() then Wrappers.Notify(Locale('phone.no_phone'), 'error') return end
    phoneOpen = not phoneOpen
    if phoneOpen then
        TriggerServerEvent('phone:server:getData')
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', config = Config.Phone })
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
    end
end, false)
RegisterKeyMapping('+phone', 'Toggle Phone', 'keyboard', 'f1')

RegisterNetEvent('phone:client:receiveData', function(d)
    local myCid = getMyCitizenId()
    contacts = d.contacts or {}
    messages = {}
    for _, m in ipairs(d.messages or {}) do
        table.insert(messages, {
            sender = m.sender_cid,
            content = m.content,
            time = m.created_at and (type(m.created_at) == 'number' and m.created_at or os.time()),
            incoming = m.receiver_cid ~= nil and m.sender_cid ~= myCid or false,
            read = m.read
        })
    end
    notes = {}
    for _, n in ipairs(d.notes or {}) do
        table.insert(notes, { content = n.content, time = n.created_at and (type(n.created_at) == 'number' and n.created_at or os.time()) })
    end
    photos = d.photos or {}
    videos = d.videos or {}
    callHistory = {}
    for _, c in ipairs(d.callHistory or {}) do
        table.insert(callHistory, {
            peer = c.caller_cid ~= myCid and c.caller_cid or c.receiver_cid,
            direction = c.caller_cid == myCid and 'outgoing' or 'incoming',
            duration = c.duration or 0,
            time = c.called_at and (type(c.called_at) == 'number' and c.called_at or os.time())
        })
    end
    local groupsData = {}
    for _, g in ipairs(d.groups or {}) do
        table.insert(groupsData, { id = g.id, name = g.name, members = g.members or {}, messages = {} })
    end
    SendNUIMessage({ action = 'loadData', contacts = contacts, messages = messages, notes = notes, photos = photos, videos = videos, callHistory = callHistory, groups = groupsData, battery = batteryLevel, citizenid = myCid })
end)

--- NUI Callbacks
RegisterNUICallback('getData', function(_, cb)
    cb({ contacts = contacts, messages = messages, notes = notes, battery = batteryLevel })
end)

RegisterNUICallback('getCallHistory', function(_, cb)
    cb(callHistory)
end)

RegisterNUICallback('getMyNumber', function(_, cb)
    cb({ number = getMyNumber() })
end)

RegisterNUICallback('getMyCard', function(_, cb)
    local pData = QBox.Functions.GetPlayerData()
    if pData and pData.charinfo then
        local name = (pData.charinfo.firstname or '') .. ' ' .. (pData.charinfo.lastname or '')
        cb({ name = name, number = getMyNumber() })
    else
        cb({ name = 'Unknown', number = '—' })
    end
end)

--- Messages
RegisterNUICallback('sendMessage', function(data, cb)
    if data and data.number and data.content then
        local msg = { sender = getMyNumber(), content = data.content, time = os.time(), incoming = false }
        table.insert(messages, msg)
        SendNUIMessage({ action = 'newMessage', message = msg })
        TriggerServerEvent('phone:server:sendMessage', data.number, data.content)
    end
    cb('ok')
end)

RegisterNUICallback('sendImage', function(data, cb)
    if data and data.number and data.image then
        local msg = { sender = getMyNumber(), image = data.image, time = os.time(), incoming = false }
        table.insert(messages, msg)
        SendNUIMessage({ action = 'newMessage', message = msg })
        TriggerServerEvent('phone:server:sendImage', data.number, data.image)
    end
    cb('ok')
end)

RegisterNUICallback('createGroup', function(data, cb)
    if data and data.name and data.members then
        TriggerServerEvent('phone:server:createGroup', data.name, data.members)
    end
    cb('ok')
end)

RegisterNUICallback('sendGroupMessage', function(data, cb)
    if data and data.groupId and data.content then
        TriggerServerEvent('phone:server:sendGroupMessage', data.groupId, data.content)
    end
    cb('ok')
end)

RegisterNUICallback('sendGroupImage', function(data, cb)
    if data and data.groupId and data.image then
        TriggerServerEvent('phone:server:sendGroupImage', data.groupId, data.image)
    end
    cb('ok')
end)

--- BlackChat (encrypted gang messaging)
RegisterNUICallback('bcStartChat', function(data, cb)
    if data and data.peer then TriggerServerEvent('bc:server:startChat', data.peer) end
    cb('ok')
end)

RegisterNUICallback('bcSendMessage', function(data, cb)
    if data and data.peer and data.content then TriggerServerEvent('bc:server:sendMessage', data.peer, data.content) end
    cb('ok')
end)

RegisterNUICallback('bcSendImage', function(data, cb)
    if data and data.peer and data.image then TriggerServerEvent('bc:server:sendImage', data.peer, data.image) end
    cb('ok')
end)

RegisterNUICallback('bcCreateGroup', function(data, cb)
    if data and data.name and data.members then TriggerServerEvent('bc:server:createGroup', data.name, data.members) end
    cb('ok')
end)

RegisterNUICallback('bcSendGroupMessage', function(data, cb)
    if data and data.groupId and data.content then TriggerServerEvent('bc:server:sendGroupMessage', data.groupId, data.content) end
    cb('ok')
end)

RegisterNUICallback('bcSendGroupImage', function(data, cb)
    if data and data.groupId and data.image then TriggerServerEvent('bc:server:sendGroupImage', data.groupId, data.image) end
    cb('ok')
end)

RegisterNUICallback('addContact', function(data, cb)
    if data and data.name and data.number then
        local c = { name = data.name, number = data.number }
        table.insert(contacts, c)
        SendNUIMessage({ action = 'contactAdded', contact = c })
        TriggerServerEvent('phone:server:addContact', data.name, data.number)
    end
    cb('ok')
end)

--- Calling
RegisterNUICallback('dialNumber', function(data, cb)
    if data and data.number then
        TriggerServerEvent('phone:server:dialNumber', data.number)
    end
    cb('ok')
end)

RegisterNUICallback('answerCall', function(_, cb)
    TriggerServerEvent('phone:server:answerCall')
    cb('ok')
end)

RegisterNUICallback('endCall', function(_, cb)
    TriggerServerEvent('phone:server:endCall')
    cb('ok')
end)

RegisterNUICallback('rejectCall', function(_, cb)
    TriggerServerEvent('phone:server:rejectCall')
    cb('ok')
end)

RegisterNUICallback('toggleMute', function(data, cb)
    TriggerServerEvent('phone:server:toggleMute', data and data.muted)
    cb('ok')
end)

RegisterNUICallback('toggleSpeaker', function(data, cb)
    if data then TriggerServerEvent('voice:server:toggleSpeaker', data.enabled) end
    cb('ok')
end)

--- Camera / Video
RegisterNUICallback('takePhoto', function(_, cb)
    exports['screenshot']:RequestScreenshot(function(data)
        if data then
            TriggerServerEvent('phone:server:savePhoto', data)
            Wrappers.Notify('Photo captured', 'success')
        end
    end, { encoding = 'png' })
    cb('ok')
end)

RegisterNUICallback('captureFrame', function(_, cb)
    exports['screenshot']:RequestScreenshot(function(data)
        cb({ data = data or '' })
    end, { encoding = 'png' })
end)

--- Notes
RegisterNUICallback('saveNote', function(data, cb)
    if data and data.content then
        TriggerServerEvent('phone:server:saveNote', data.content)
    end
    cb('ok')
end)

--- GPS
RegisterNUICallback('gpsNavigate', function(data, cb)
    if data and data.destination then Wrappers.Notify('GPS: Navigating to ' .. data.destination, 'info') end
    cb('ok')
end)

RegisterNUICallback('gpsMyLocation', function(_, cb)
    Wrappers.Notify('GPS: Your location shown on map', 'info')
    cb('ok')
end)

--- Close
RegisterNUICallback('close', function(_, cb)
    phoneOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

--- Taxi callbacks
RegisterNUICallback('taxiToggleDuty', function(_, cb)
    TriggerServerEvent('taxi:toggleDuty')
    cb('ok')
end)

RegisterNUICallback('taxiRequest', function(_, cb)
    TriggerServerEvent('taxi:requestRide')
    cb('ok')
end)

RegisterNUICallback('taxiEndRide', function(_, cb)
    TriggerServerEvent('taxi:endRide')
    cb('ok')
end)

RegisterNUICallback('taxiRateDriver', function(data, cb)
    if data and data.rating then TriggerServerEvent('taxi:rateRide', data.rating) end
    cb('ok')
end)

--- Phone events from server
RegisterNetEvent('phone:client:incomingCall', function(caller, callerName)
    SendNUIMessage({ action = 'incomingCall', caller = caller, callerName = callerName })
end)

RegisterNetEvent('phone:client:callConnected', function(peer, peerNumber, peerName)
    SendNUIMessage({ action = 'callConnected', peer = peer, peerName = peerName })
    exports['pma-voice']:setCallChannel(1)
end)

RegisterNetEvent('phone:client:callEnded', function()
    SendNUIMessage({ action = 'callEnded' })
    exports['pma-voice']:setCallChannel(0)
end)

RegisterNetEvent('phone:client:receiveMessage', function(sender, content, msgTime)
    table.insert(messages, { sender = sender, content = content, time = msgTime or os.time(), incoming = true })
    SendNUIMessage({ action = 'newMessage', message = messages[#messages] })
    Wrappers.Notify(Locale('phone.new_message', sender), 'info')
end)

RegisterNetEvent('phone:client:receiveImage', function(sender, imageData)
    table.insert(messages, { sender = sender, image = imageData, time = os.time(), incoming = true })
    SendNUIMessage({ action = 'newMessage', message = messages[#messages] })
end)

--- Group messaging events
RegisterNetEvent('phone:client:groupCreated', function(groupData)
    SendNUIMessage({ action = 'groupCreated', group = groupData })
end)

RegisterNetEvent('phone:client:groupMessage', function(groupId, sender, content)
    SendNUIMessage({ action = 'groupNewMessage', groupId = groupId, message = { content = content, senderName = sender, time = os.time(), incoming = true } })
end)

RegisterNetEvent('phone:client:groupImage', function(groupId, sender, imageData)
    SendNUIMessage({ action = 'groupNewMessage', groupId = groupId, message = { image = imageData, senderName = sender, time = os.time(), incoming = true } })
end)

--- BlackChat events (untraceable encrypted gang messaging)
RegisterNetEvent('bc:client:message', function(sender, content)
    SendNUIMessage({ action = 'bcNewMessage', chatId = sender, message = { content = content, time = os.time(), incoming = true } })
end)

RegisterNetEvent('bc:client:image', function(sender, imageData)
    SendNUIMessage({ action = 'bcNewMessage', chatId = sender, message = { image = imageData, time = os.time(), incoming = true } })
end)

RegisterNetEvent('bc:client:groupCreated', function(groupData)
    SendNUIMessage({ action = 'bcGroupCreated', group = groupData })
end)

RegisterNetEvent('bc:client:groupMessage', function(groupId, sender, content)
    SendNUIMessage({ action = 'bcNewMessage', chatId = groupId, message = { content = content, senderName = sender, time = os.time(), incoming = true } })
end)

RegisterNetEvent('bc:client:groupImage', function(groupId, sender, imageData)
    SendNUIMessage({ action = 'bcNewMessage', chatId = groupId, message = { image = imageData, senderName = sender, time = os.time(), incoming = true } })
end)

RegisterNetEvent('phone:client:photoSaved', function(photoData)
    table.insert(photos, photoData)
    SendNUIMessage({ action = 'photoTaken', data = photoData })
end)

--- NUI callbacks for X (Twitter), TikTok, Uber Eats, Banking
RegisterNUICallback('xGetTweets', function(_, cb) TriggerServerEvent('x:server:getTweets') cb('ok') end)
RegisterNUICallback('xPostTweet', function(data, cb) if data and data.content then TriggerServerEvent('x:server:postTweet', data.content) end cb('ok') end)
RegisterNUICallback('xLikeTweet', function(data, cb) if data and data.tweetId then TriggerServerEvent('x:server:likeTweet', data.tweetId) end cb('ok') end)

RegisterNUICallback('tiktokGetFeed', function(_, cb) TriggerServerEvent('tiktok:server:getFeed') cb('ok') end)
RegisterNUICallback('tiktokUpload', function(data, cb) if data and data.videoData then TriggerServerEvent('tiktok:server:upload', data.videoData, data.description) end cb('ok') end)
RegisterNUICallback('tiktokLike', function(data, cb) if data and data.videoId then TriggerServerEvent('tiktok:server:like', data.videoId) end cb('ok') end)

RegisterNUICallback('ubereatsGetRestaurants', function(_, cb) TriggerServerEvent('ubereats:server:getRestaurants') cb('ok') end)
RegisterNUICallback('ubereatsGetOrders', function(_, cb) TriggerServerEvent('ubereats:server:getOrders') cb('ok') end)
RegisterNUICallback('ubereatsPlaceOrder', function(data, cb) if data and data.restaurantId and data.items then TriggerServerEvent('ubereats:server:placeOrder', data.restaurantId, data.items) end cb('ok') end)

RegisterNUICallback('bankingGetData', function(_, cb) TriggerServerEvent('banking:server:getData') cb('ok') end)
RegisterNUICallback('bankingTransfer', function(data, cb) if data and data.target and data.amount then TriggerServerEvent('banking:server:transfer', data.target, data.amount) end cb('ok') end)

--- Client events for X
RegisterNetEvent('x:client:receiveTweets', function(tweets) SendNUIMessage({ action = 'xData', tweets = tweets }) end)
RegisterNetEvent('x:client:newTweet', function(tweet) SendNUIMessage({ action = 'xNewTweet', tweet = tweet }) end)

--- Client events for TikTok
RegisterNetEvent('tiktok:client:receiveFeed', function(videos) SendNUIMessage({ action = 'tiktokData', videos = videos }) end)

--- Client events for Uber Eats
RegisterNetEvent('ubereats:client:receiveRestaurants', function(restaurants) SendNUIMessage({ action = 'ubereatsData', restaurants = restaurants }) end)
RegisterNetEvent('ubereats:client:receiveOrders', function(orders) SendNUIMessage({ action = 'ubereatsOrders', orders = orders }) end)
RegisterNetEvent('ubereats:client:orderPlaced', function(order) SendNUIMessage({ action = 'ubereatsOrderPlaced', order = order }) end)

--- Client events for Banking
RegisterNetEvent('banking:client:receiveData', function(balance, transactions) SendNUIMessage({ action = 'bankingData', balance = balance, transactions = transactions }) end)

--- Weather NUI callback
RegisterNUICallback('weatherGetData', function(_, cb)
    local weather = exports['weathersync']:GetWeather() or 'EXTRASUNNY'
    local time = exports['weathersync']:GetTime() or { hour = 12, minute = 0 }
    local blackout = exports['weathersync']:IsBlackoutActive() or false
    SendNUIMessage({ action = 'weatherData', weather = weather, hour = time.hour, minute = time.minute, blackout = blackout, sunrise = Config.Weather and Config.Weather.sunriseHour or 6, sunset = Config.Weather and Config.Weather.sunsetHour or 20 })
    cb('ok')
end)

--- Gigs NUI callbacks
RegisterNUICallback('gigsGetList', function(_, cb) TriggerServerEvent('gigs:server:getList') cb('ok') end)
RegisterNUICallback('gigsPost', function(data, cb)
    if data and data.title and data.reward then TriggerServerEvent('gigs:server:post', data.title, data.description, data.reward, data.location_label) end
    cb('ok')
end)
RegisterNUICallback('gigsAccept', function(data, cb) if data and data.gigId then TriggerServerEvent('gigs:server:accept', data.gigId) end cb('ok') end)
RegisterNUICallback('emergencyCall911', function(data, cb)
    if data and data.type then
        TriggerServerEvent('dispatch:server:call911', data.type)
    end
    cb('ok')
end)
RegisterNUICallback('gigsComplete', function(data, cb) if data and data.gigId then TriggerServerEvent('gigs:server:complete', data.gigId) end cb('ok') end)
RegisterNUICallback('gigsCancel', function(data, cb) if data and data.gigId then TriggerServerEvent('gigs:server:cancel', data.gigId) end cb('ok') end)

--- Gigs client events
RegisterNetEvent('gigs:client:receiveList', function(list) SendNUIMessage({ action = 'gigsData', gigs = list }) end)
RegisterNetEvent('gigs:client:gigCreated', function(gig) SendNUIMessage({ action = 'gigCreated', gig = gig }) end)

--- Calendar NUI callbacks
RegisterNUICallback('calendarGetEvents', function(_, cb) TriggerServerEvent('calendar:server:getEvents') cb('ok') end)
RegisterNUICallback('calendarSaveEvent', function(data, cb) if data then TriggerServerEvent('calendar:server:saveEvent', data.title, data.description, data.date, data.time) end cb('ok') end)
RegisterNUICallback('calendarDeleteEvent', function(data, cb) if data and data.eventId then TriggerServerEvent('calendar:server:deleteEvent', data.eventId) end cb('ok') end)
RegisterNetEvent('calendar:client:receiveEvents', function(events) SendNUIMessage({ action = 'calendarData', events = events }) end)

--- Wallet NUI callbacks
RegisterNUICallback('walletGetCards', function(_, cb) TriggerServerEvent('wallet:server:getCards') cb('ok') end)
RegisterNUICallback('walletAddCard', function(data, cb) if data then TriggerServerEvent('wallet:server:addCard', data.cardType, data.cardNumber, data.holderName) end cb('ok') end)
RegisterNUICallback('walletDeleteCard', function(data, cb) if data and data.cardId then TriggerServerEvent('wallet:server:deleteCard', data.cardId) end cb('ok') end)
RegisterNetEvent('wallet:client:receiveCards', function(cards) SendNUIMessage({ action = 'walletData', cards = cards }) end)

--- Video NUI callbacks
RegisterNUICallback('saveVideo', function(data, cb) if data then TriggerServerEvent('video:server:saveVideo', data.videoData, data.thumbnail) end cb('ok') end)
RegisterNetEvent('video:client:videoSaved', function(videoData) SendNUIMessage({ action = 'videoSaved', data = videoData }) end)

--- Vehicle App NUI callbacks
RegisterNUICallback('phoneGarageGetVehicles', function(_, cb)
    local vehicles = lib.callback.await('vehicleApp:server:getVehicles', false)
    cb(vehicles or {})
end)

RegisterNUICallback('phoneGarageToggleLock', function(data, cb)
    if not data or not data.plate then cb({ success = false }) return end
    local result = lib.callback.await('vehicleApp:server:toggleLock', false, data.plate)
    cb(result or { success = false })
end)

RegisterNUICallback('phoneGarageToggleEngine', function(data, cb)
    if not data or not data.plate then cb({ success = false }) return end
    local result = lib.callback.await('vehicleApp:server:toggleEngine', false, data.plate)
    cb(result or { success = false })
end)

RegisterNUICallback('phoneGarageTrackVehicle', function(data, cb)
    if not data or not data.plate then cb({ success = false }) return end
    local result = lib.callback.await('vehicleApp:server:trackVehicle', false, data.plate)
    if result and result.success then
        SetNewWaypoint(result.x, result.y)
        cb({ success = true })
    else
        cb(result or { success = false })
    end
end)

--- Taxi events
RegisterNetEvent('taxi:phoneFareUpdate', function(fareData)
    SendNUIMessage({ action = 'taxiFareUpdate', fare = fareData.fare, distance = fareData.distance })
end)

RegisterNetEvent('taxi:phoneDispatch', function(fareData)
    SendNUIMessage({ action = 'taxiDispatch', fare = fareData })
end)

--- Voice overlay
RegisterNetEvent('phone:client:voiceUpdate', function(data)
    SendNUIMessage({ action = 'voiceUpdate', talking = data.talking, mode = data.mode, radioFreq = data.radioFreq, targets = data.targets, forceShow = data.forceShow })
end)

--- Battery is always 100 (drain disabled)

--- Voice state tracking
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        if hasPhone() then
            local talking = false
            pcall(function() talking = exports['pma-voice']:isTalking() end)
            local voiceMode = 'Normal'
            local voiceRange = 0
            pcall(function() voiceRange = exports['pma-voice']:getVoiceProperty('radioRange') or 0 end)
            if voiceRange <= 5 then voiceMode = 'Whisper'
            elseif voiceRange <= 20 then voiceMode = 'Normal'
            elseif voiceRange <= 50 then voiceMode = 'Shouting'
            else voiceMode = 'Megaphone' end
            local targets = {}
            local nearby = GetActivePlayers()
            for _, pid in ipairs(nearby) do
                if pid ~= PlayerId() then
                    local dist = #(GetEntityCoords(GetPlayerPed(pid)) - GetEntityCoords(PlayerPedId()))
                    if dist < voiceRange + 5 then table.insert(targets, GetPlayerServerId(pid)) end
                end
            end
            TriggerEvent('phone:client:voiceUpdate', { talking = talking, mode = voiceMode, radioFreq = nil, targets = targets, forceShow = true })
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if GetCurrentResourceName() == r and phoneOpen then SetNuiFocus(false, false) end
end)
