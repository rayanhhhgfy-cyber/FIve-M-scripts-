local QBox = exports['qbx_core']:GetCoreObject()
local activeCalls = {}
local callIdCounter = 0

local function getCID(src)
    local p = QBox.Functions.GetPlayer(src)
    return p and p.PlayerData.citizenid or nil
end

local function getPlayerName(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return 'Unknown' end
    return p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname
end

local function getPlayerNumber(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return nil end
    return p.PlayerData.charinfo.phone or p.PlayerData.citizenid
end

local function getPlayerByCID(cid)
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local p = QBox.Functions.GetPlayer(s)
        if p and p.PlayerData.citizenid == cid then return s end
    end
    return nil
end

local function findPlayerByNumber(number)
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local p = QBox.Functions.GetPlayer(s)
        if p then
            local phoneNumber = p.PlayerData.charinfo.phone
            if phoneNumber and phoneNumber == number then return s, p.PlayerData.citizenid end
        end
    end
    local result = MySQL.single.await('SELECT citizenid FROM characters WHERE phone_number = ? LIMIT 1', { number })
    if result then
        local src = getPlayerByCID(result.citizenid)
        return src, result.citizenid
    end
    return nil, nil
end

-- ==================== PHONE OPEN ====================
RegisterNetEvent('phone:open', function()
    local src = source
    local cid = getCID(src)
    if not cid then return end

    local contacts = MySQL.query.await('SELECT id, name, number, cid FROM phone_contacts WHERE owner_cid = ? ORDER BY name ASC', { cid })
    local messages = MySQL.query.await(
        'SELECT m.id, m.sender_cid, m.receiver_cid, m.content, m.`read`, m.created_at, ' ..
        'COALESCE(s.firstname, "Unknown") as sender_first, COALESCE(s.lastname, "") as sender_last, ' ..
        'COALESCE(r.firstname, "Unknown") as receiver_first, COALESCE(r.lastname, "") as receiver_last ' ..
        'FROM phone_messages m ' ..
        'LEFT JOIN characters s ON s.citizenid = m.sender_cid ' ..
        'LEFT JOIN characters r ON r.citizenid = m.receiver_cid ' ..
        'WHERE m.sender_cid = ? OR m.receiver_cid = ? ORDER BY m.created_at ASC LIMIT ?',
        { cid, cid, Config.Phone.messagesPerPage }
    )
    local unread = MySQL.scalar.await('SELECT COUNT(*) FROM phone_messages WHERE receiver_cid = ? AND `read` = 0', { cid })
    local transactions = MySQL.query.await('SELECT * FROM bank_transactions WHERE sender_cid = ? OR receiver_cid = ? ORDER BY created_at DESC LIMIT 10', { cid, cid })
    local notes = MySQL.query.await('SELECT id, title, content, color, created_at, updated_at FROM phone_notes WHERE citizenid = ? ORDER BY updated_at DESC', { cid })
    local events = MySQL.query.await('SELECT id, title, description, event_date, event_time, color FROM phone_calendar WHERE citizenid = ? AND event_date >= CURDATE() ORDER BY event_date ASC, event_time ASC LIMIT 20', { cid })
    local callHistory = MySQL.query.await('SELECT * FROM phone_call_history WHERE caller_cid = ? OR receiver_cid = ? ORDER BY called_at DESC LIMIT 50', { cid, cid })
    local voicemails = MySQL.query.await('SELECT * FROM phone_voicemails WHERE target_cid = ? AND `read` = 0 ORDER BY created_at DESC LIMIT 10', { cid })
    local balance = 0
    local p = QBox.Functions.GetPlayer(src)
    if p then balance = p.PlayerData.money.bank or 0 end

    TriggerClientEvent('phone:loadData', src, {
        contacts = contacts or {},
        messages = messages or {},
        unread = unread or 0,
        transactions = transactions or {},
        notes = notes or {},
        calendar = events or {},
        callHistory = callHistory or {},
        voicemails = voicemails or {},
        bank = balance,
        name = getPlayerName(src),
        playerCid = cid,
        playerNumber = getPlayerNumber(src),
    })
end)

-- ==================== CALL SYSTEM ====================
RegisterNetEvent('phone:dialNumber', function(number)
    local src = source
    local cid = getCID(src)
    if not cid then return end

    if activeCalls[src] then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You are already in a call' })
        return
    end

    local targetSrc, targetCid = findPlayerByNumber(number)
    if not targetSrc then
        local contact = MySQL.single.await('SELECT cid FROM phone_contacts WHERE number = ? LIMIT 1', { number })
        if contact then
            targetSrc = getPlayerByCID(contact.cid)
            targetCid = contact.cid
        end
    end

    if not targetSrc or not targetCid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Number not found or player offline' })
        if Config.Phone.CallSettings.voicemailEnabled then
            MySQL.insert('INSERT INTO phone_call_history (caller_cid, receiver_cid, status, duration) VALUES (?, ?, ?, 0)', { cid, number:match('%d+') or number, 'missed' })
        end
        return
    end

    if activeCalls[targetSrc] then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player is already in a call' })
        return
    end

    if targetSrc == src then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Cannot call yourself' })
        return
    end

    callIdCounter = callIdCounter + 1
    local callId = 'call_' .. callIdCounter

    activeCalls[src] = { peer = targetSrc, peerCid = targetCid, callId = callId, startTime = os.time(), channel = callIdCounter }
    activeCalls[targetSrc] = { peer = src, peerCid = cid, callId = callId, startTime = os.time(), channel = callIdCounter }

    TriggerClientEvent('phone:incomingCall', targetSrc, {
        caller = cid,
        callerName = getPlayerName(src),
        callId = callId,
    })

    MySQL.insert('INSERT INTO phone_call_history (caller_cid, receiver_cid, status, duration) VALUES (?, ?, ?, 0)', { cid, targetCid, 'dialed' })
end)

RegisterNetEvent('phone:answerCall', function()
    local src = source
    local cid = getCID(src)
    if not cid then return end
    if not activeCalls[src] then return end

    local call = activeCalls[src]
    local caller = call.peer

    TriggerClientEvent('phone:callConnected', caller, { peer = src, peerName = getPlayerName(src), channel = call.channel })
    TriggerClientEvent('phone:callConnected', src, { peer = caller, peerName = getPlayerName(caller), channel = call.channel })

    MySQL.update('UPDATE phone_call_history SET status = ?, answered_at = UNIX_TIMESTAMP() WHERE caller_cid = ? AND receiver_cid = ? AND status = "dialed" ORDER BY id DESC LIMIT 1',
        { 'connected', call.peerCid, cid })
end)

RegisterNetEvent('phone:rejectCall', function()
    local src = source
    local cid = getCID(src)
    if not cid then return end
    if not activeCalls[src] then return end

    local call = activeCalls[src]
    TriggerClientEvent('phone:callEnded', call.peer, { reason = 'rejected' })
    TriggerClientEvent('phone:callEnded', src, { reason = 'rejected' })

    MySQL.update('UPDATE phone_call_history SET status = ? WHERE caller_cid = ? AND receiver_cid = ? AND status = "dialed" ORDER BY id DESC LIMIT 1',
        { 'rejected', call.peerCid, cid })

    activeCalls[src] = nil
    activeCalls[call.peer] = nil
end)

RegisterNetEvent('phone:endCall', function()
    local src = source
    local cid = getCID(src)
    if not cid then return end
    if not activeCalls[src] then return end

    local call = activeCalls[src]
    local duration = os.time() - (call.startTime or os.time())

    TriggerClientEvent('phone:callEnded', call.peer, { reason = 'ended' })
    TriggerClientEvent('phone:callEnded', src, { reason = 'ended' })

    MySQL.update('UPDATE phone_call_history SET status = ?, duration = ? WHERE caller_cid = ? AND receiver_cid = ? AND status = "connected" ORDER BY id DESC LIMIT 1',
        { 'ended', duration, (call.peerCid or cid), (call.peerCid == cid and call.peerCid or cid) })

    activeCalls[src] = nil
    activeCalls[call.peer] = nil
end)

RegisterNetEvent('phone:sendVoicemail', function(callId, message)
    local src = source
    local cid = getCID(src)
    if not cid then return end

    local callRecord = MySQL.single.await('SELECT * FROM phone_call_history WHERE id = ? OR caller_cid = ? ORDER BY id DESC LIMIT 1', { callId, cid })
    if not callRecord then return end

    local targetCid = callRecord.receiver_cid == cid and callRecord.caller_cid or callRecord.receiver_cid
    MySQL.insert('INSERT INTO phone_voicemails (target_cid, caller_cid, caller_name, message, duration) VALUES (?, ?, ?, ?, ?)',
        { targetCid, cid, getPlayerName(src), message, math.floor(#message / 15) })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Voicemail sent' })
end)

RegisterNetEvent('phone:getCallHistory', function()
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local history = MySQL.query.await('SELECT * FROM phone_call_history WHERE caller_cid = ? OR receiver_cid = ? ORDER BY called_at DESC LIMIT 50', { cid, cid })
    TriggerClientEvent('phone:callHistory', src, history or {})
end)

RegisterNetEvent('phone:getVoicemails', function()
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local voicemails = MySQL.query.await('SELECT * FROM phone_voicemails WHERE target_cid = ? ORDER BY created_at DESC LIMIT 20', { cid })
    TriggerClientEvent('phone:loadVoicemails', src, voicemails or {})
end)

-- ==================== CONTACTS ====================
RegisterNetEvent('phone:addContact', function(data)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM phone_contacts WHERE owner_cid = ?', { cid })
    if count >= Config.Phone.maxContacts then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Max contacts reached (' .. Config.Phone.maxContacts .. ')' })
        return
    end
    local contactId = MySQL.insert.await('INSERT INTO phone_contacts (owner_cid, name, number, cid) VALUES (?, ?, ?, ?)',
        { cid, data.name, data.number or '', data.targetCid or '' })
    TriggerClientEvent('phone:contactAdded', src, { id = contactId, name = data.name, number = data.number or '', cid = data.targetCid or '' })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Contact added' })
end)

RegisterNetEvent('phone:deleteContact', function(contactId)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    MySQL.update('DELETE FROM phone_contacts WHERE id = ? AND owner_cid = ?', { contactId, cid })
end)

RegisterNetEvent('phone:updateContact', function(data)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    MySQL.update('UPDATE phone_contacts SET name = ?, number = ? WHERE id = ? AND owner_cid = ?',
        { data.name, data.number or '', data.id, cid })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Contact updated' })
end)

RegisterNetEvent('phone:shareContact', function(contactId, targetCid)
    local src = source
    local cid = getCID(src)
    if not cid then return end

    local contact = MySQL.single.await('SELECT * FROM phone_contacts WHERE id = ? AND owner_cid = ?', { contactId, cid })
    if not contact then return end

    local targetSrc = getPlayerByCID(targetCid)
    if targetSrc then
        TriggerClientEvent('phone:contactShared', targetSrc, {
            contact = { name = contact.name, number = contact.number, cid = contact.cid },
            from = cid,
        })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Contact shared with ' .. targetCid })
    else
        MySQL.insert('INSERT INTO phone_messages (sender_cid, receiver_cid, content) VALUES (?, ?, ?)',
            { cid, targetCid, '📇 Shared contact: ' .. contact.name .. ' - ' .. (contact.number or 'N/A') })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Contact sent via message' })
    end
end)

RegisterNetEvent('phone:shareMyContact', function(targetCid)
    local src = source
    local cid = getCID(src)
    if not cid then return end

    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local name = getPlayerName(src)
    local number = getPlayerNumber(src)

    local targetSrc = getPlayerByCID(targetCid)
    if targetSrc then
        TriggerClientEvent('phone:contactShared', targetSrc, {
            contact = { name = name, number = number or cid, cid = cid },
            from = cid,
        })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Your contact shared with ' .. targetCid })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
    end
end)

-- ==================== MESSAGES ====================
RegisterNetEvent('phone:sendMessage', function(data)
    local src = source
    local cid = getCID(src)
    if not cid then return end

    local count = MySQL.scalar.await(
        'SELECT COUNT(*) FROM phone_messages WHERE (sender_cid = ? OR receiver_cid = ?) AND created_at > DATE_SUB(NOW(), INTERVAL 1 DAY)',
        { cid, cid }
    )
    if count >= Config.Phone.maxMessages then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Daily message limit reached' })
        return
    end

    local targetCid = data.targetCid
    if not targetCid then
        local contact = MySQL.single.await('SELECT cid FROM phone_contacts WHERE number = ? AND owner_cid <> ? LIMIT 1', { data.number, cid })
        if contact then
            targetCid = contact.cid
        elseif data.number and #data.number > 3 then
            local player = MySQL.single.await('SELECT citizenid FROM characters WHERE citizenid = ?', { data.number })
            if player then targetCid = player.citizenid end
        end
    end

    if not targetCid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Recipient not found' })
        return
    end

    MySQL.insert('INSERT INTO phone_messages (sender_cid, receiver_cid, content) VALUES (?, ?, ?)', { cid, targetCid, data.content })
    TriggerClientEvent('phone:messageSent', src, { content = data.content, sent = true })

    local targetSrc = getPlayerByCID(targetCid)
    if targetSrc then
        TriggerClientEvent('phone:newMessage', targetSrc, {
            sender_cid = cid,
            sender_name = getPlayerName(src),
            content = data.content,
            created_at = os.date('%Y-%m-%d %H:%M:%S')
        })
    end
end)

RegisterNetEvent('phone:markRead', function(data)
    local src = source
    local cid = getCID(src)
    if not cid or not data or not data.ids then return end
    for _, id in ipairs(data.ids) do
        MySQL.update('UPDATE phone_messages SET `read` = 1 WHERE id = ? AND receiver_cid = ?', { id, cid })
    end
end)

-- ==================== BANKING ====================
RegisterNetEvent('phone:getBankBalance', function()
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    TriggerClientEvent('phone:bankBalance', src, p.PlayerData.money.bank or 0, p.PlayerData.money.cash or 0)
end)

RegisterNetEvent('phone:transferMoney', function(data)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    local targetCid = data.targetCid
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Invalid amount' })
        return
    end
    if not targetCid then
        local contact = MySQL.single.await('SELECT cid FROM phone_contacts WHERE number = ? LIMIT 1', { data.number })
        if contact then targetCid = contact.cid end
    end
    if not targetCid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Recipient not found' })
        return
    end
    if not p.Functions.RemoveMoney('bank', amount, 'phone-transfer') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient funds' })
        return
    end
    local target = QBox.Functions.GetPlayerByCitizenId(targetCid)
    if target then
        target.Functions.AddMoney('bank', amount, 'phone-transfer')
    end
    MySQL.insert('INSERT INTO bank_transactions (sender_cid, receiver_cid, amount, type) VALUES (?, ?, ?, ?)', { cid, targetCid, amount, 'phone_transfer' })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Transferred $' .. amount })
    TriggerClientEvent('phone:transferComplete', src, p.PlayerData.money.bank)
end)

-- ==================== PHOTOS ====================
RegisterNetEvent('phone:savePhoto', function(imageData)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local filename = 'photo_' .. cid .. '_' .. os.time() .. '.png'
    MySQL.insert('INSERT INTO phone_photos (citizenid, filename, image_data) VALUES (?, ?, ?)', { cid, filename, imageData })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Photo saved' })
end)

RegisterNetEvent('phone:getPhotos', function()
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local photos = MySQL.query.await('SELECT id, filename, image_data, created_at FROM phone_photos WHERE citizenid = ? ORDER BY created_at DESC LIMIT 50', { cid })
    TriggerClientEvent('phone:loadPhotos', src, photos or {})
end)

RegisterNetEvent('phone:deletePhoto', function(photoId)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    MySQL.update('DELETE FROM phone_photos WHERE id = ? AND citizenid = ?', { photoId, cid })
end)

-- ==================== NOTES ====================
RegisterNetEvent('phone:saveNote', function(data)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    if data.id then
        MySQL.update('UPDATE phone_notes SET title = ?, content = ?, color = ?, updated_at = NOW() WHERE id = ? AND citizenid = ?',
            { data.title, data.content, data.color or '#FFD60A', data.id, cid })
    else
        MySQL.insert('INSERT INTO phone_notes (citizenid, title, content, color) VALUES (?, ?, ?, ?)',
            { cid, data.title, data.content, data.color or '#FFD60A' })
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Note saved' })
end)

RegisterNetEvent('phone:getNotes', function()
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local notes = MySQL.query.await('SELECT id, title, content, color, created_at, updated_at FROM phone_notes WHERE citizenid = ? ORDER BY updated_at DESC', { cid })
    TriggerClientEvent('phone:loadNotes', src, notes or {})
end)

RegisterNetEvent('phone:deleteNote', function(noteId)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    MySQL.update('DELETE FROM phone_notes WHERE id = ? AND citizenid = ?', { noteId, cid })
end)

-- ==================== CALENDAR ====================
RegisterNetEvent('phone:saveCalendarEvent', function(data)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    if data.id then
        MySQL.update('UPDATE phone_calendar SET title = ?, description = ?, event_date = ?, event_time = ?, color = ? WHERE id = ? AND citizenid = ?',
            { data.title, data.description or '', data.date, data.time or '12:00', data.color or '#007AFF', data.id, cid })
    else
        MySQL.insert('INSERT INTO phone_calendar (citizenid, title, description, event_date, event_time, color) VALUES (?, ?, ?, ?, ?, ?)',
            { cid, data.title, data.description or '', data.date, data.time or '12:00', data.color or '#007AFF' })
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Event saved' })
end)

RegisterNetEvent('phone:getCalendarEvents', function()
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local events = MySQL.query.await('SELECT id, title, description, event_date as date, event_time as time, color FROM phone_calendar WHERE citizenid = ? AND event_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) ORDER BY event_date ASC, event_time ASC', { cid })
    TriggerClientEvent('phone:loadCalendarEvents', src, events or {})
end)

RegisterNetEvent('phone:deleteCalendarEvent', function(eventId)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    MySQL.update('DELETE FROM phone_calendar WHERE id = ? AND citizenid = ?', { eventId, cid })
end)

-- ==================== SOCIAL / TWEETS ====================
RegisterNetEvent('phone:getTweets', function()
    local src = source
    local tweets = MySQL.query.await([[
        SELECT t.*, c.firstname, c.lastname,
            (SELECT COUNT(*) FROM phone_tweet_likes WHERE tweet_id = t.id) as like_count,
            (SELECT COUNT(*) FROM phone_tweet_comments WHERE tweet_id = t.id) as comment_count
        FROM phone_tweets t
        LEFT JOIN characters c ON c.citizenid = t.citizenid
        ORDER BY t.created_at DESC LIMIT 50
    ]])
    TriggerClientEvent('phone:loadTweets', src, tweets or {})
end)

RegisterNetEvent('phone:postTweet', function(content)
    local src = source
    local cid = getCID(src)
    if not cid or not content or #content > 280 then return end
    MySQL.insert('INSERT INTO phone_tweets (citizenid, content) VALUES (?, ?)', { cid, content })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Tweet posted' })
end)

RegisterNetEvent('phone:likeTweet', function(tweetId)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local existing = MySQL.single.await('SELECT id FROM phone_tweet_likes WHERE tweet_id = ? AND citizenid = ?', { tweetId, cid })
    if existing then
        MySQL.update('DELETE FROM phone_tweet_likes WHERE id = ?', { existing.id })
    else
        MySQL.insert('INSERT INTO phone_tweet_likes (tweet_id, citizenid) VALUES (?, ?)', { tweetId, cid })
    end
end)

RegisterNetEvent('phone:retweet', function(tweetId)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local tweet = MySQL.single.await('SELECT content FROM phone_tweets WHERE id = ?', { tweetId })
    if tweet then
        MySQL.insert('INSERT INTO phone_tweets (citizenid, content) VALUES (?, ?)', { cid, 'RT: ' .. tweet.content })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Retweeted' })
    end
end)

RegisterNetEvent('phone:commentTweet', function(tweetId, content)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    MySQL.insert('INSERT INTO phone_tweet_comments (tweet_id, citizenid, content) VALUES (?, ?, ?)', { tweetId, cid, content })
end)

-- ==================== BLACK CHAT (Group Chats) ====================
local function isBCMember(roomId, cid)
    local member = MySQL.single.await('SELECT id FROM blackchat_room_members WHERE room_id = ? AND citizenid = ?', { roomId, cid })
    return member ~= nil
end

local function getBCMemberCount(roomId)
    return MySQL.scalar.await('SELECT COUNT(*) FROM blackchat_room_members WHERE room_id = ?', { roomId })
end

RegisterNetEvent('phone:getBlackChatRooms', function()
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local hasItem = exports.ox_inventory:Search(src, 1, 'crypto_phone')
    if not hasItem or #hasItem == 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need a Crypto Phone for Black Chat' })
        return
    end
    local rooms = MySQL.query.await([[
        SELECT r.*, (SELECT COUNT(*) FROM blackchat_room_members WHERE room_id = r.room_id) as member_count
        FROM blackchat_rooms r
        WHERE r.room_id IN (SELECT rm.room_id FROM blackchat_room_members rm WHERE rm.citizenid = ?)
        ORDER BY r.display_name ASC
    ]], { cid })
    TriggerClientEvent('phone:loadBlackChatRooms', src, rooms or {})
end)

RegisterNetEvent('phone:joinBlackChatRoom', function(roomId)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local hasItem = exports.ox_inventory:Search(src, 1, 'crypto_phone')
    if not hasItem or #hasItem == 0 then return end

    local room = MySQL.single.await('SELECT * FROM blackchat_rooms WHERE room_id = ?', { roomId })
    if not room then
        MySQL.insert('INSERT INTO blackchat_rooms (room_id, display_name, created_by) VALUES (?, ?, ?)', { roomId, roomId, cid })
    end

    local existing = MySQL.single.await('SELECT id FROM blackchat_room_members WHERE room_id = ? AND citizenid = ?', { roomId, cid })
    if not existing then
        local count = getBCMemberCount(roomId)
        MySQL.insert('INSERT INTO blackchat_room_members (room_id, citizenid, role) VALUES (?, ?, ?)',
            { roomId, cid, count == 0 and 'owner' or 'member' })
    end

    local members = MySQL.query.await('SELECT citizenid, role, joined_at FROM blackchat_room_members WHERE room_id = ? ORDER BY joined_at ASC', { roomId })
    local messages = MySQL.query.await(
        'SELECT m.*, c.firstname, c.lastname FROM blackchat_messages m LEFT JOIN characters c ON c.citizenid = m.sender_cid WHERE m.room_id = ? ORDER BY m.created_at ASC LIMIT 50',
        { roomId }
    )
    TriggerClientEvent('phone:loadBlackChatMessages', src, { roomId = roomId, messages = messages or {}, members = members or {} })
end)

RegisterNetEvent('phone:addBlackChatMember', function(roomId, targetCid)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local hasItem = exports.ox_inventory:Search(src, 1, 'crypto_phone')
    if not hasItem or #hasItem == 0 then return end

    local member = MySQL.single.await('SELECT role FROM blackchat_room_members WHERE room_id = ? AND citizenid = ?', { roomId, cid })
    if not member or (member.role ~= 'owner' and member.role ~= 'admin') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only room owner/admins can add members' })
        return
    end

    local already = MySQL.single.await('SELECT id FROM blackchat_room_members WHERE room_id = ? AND citizenid = ?', { roomId, targetCid })
    if already then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already a member' })
        return
    end

    MySQL.insert('INSERT INTO blackchat_room_members (room_id, citizenid, role) VALUES (?, ?, ?)', { roomId, targetCid, 'member' })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Added ' .. targetCid .. ' to the room' })

    local targetSrc = getPlayerByCID(targetCid)
    if targetSrc then
        local memberCount = getBCMemberCount(roomId)
        local room = MySQL.single.await('SELECT display_name FROM blackchat_rooms WHERE room_id = ?', { roomId })
        TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'info', description = 'You were added to Black Chat room: ' .. (room and room.display_name or roomId) })
        local members = MySQL.query.await('SELECT citizenid, role, joined_at FROM blackchat_room_members WHERE room_id = ? ORDER BY joined_at ASC', { roomId })
        local messages = MySQL.query.await(
            'SELECT m.*, c.firstname, c.lastname FROM blackchat_messages m LEFT JOIN characters c ON c.citizenid = m.sender_cid WHERE m.room_id = ? ORDER BY m.created_at ASC LIMIT 50',
            { roomId }
        )
        TriggerClientEvent('phone:loadBlackChatMessages', targetSrc, { roomId = roomId, messages = messages or {}, members = members or {} })
    end
end)

RegisterNetEvent('phone:removeBlackChatMember', function(roomId, targetCid)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local hasItem = exports.ox_inventory:Search(src, 1, 'crypto_phone')
    if not hasItem or #hasItem == 0 then return end

    local member = MySQL.single.await('SELECT role FROM blackchat_room_members WHERE room_id = ? AND citizenid = ?', { roomId, cid })
    if not member or (member.role ~= 'owner' and member.role ~= 'admin') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only room owner/admins can remove members' })
        return
    end

    if cid == targetCid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Cannot remove yourself' })
        return
    end

    MySQL.update('DELETE FROM blackchat_room_members WHERE room_id = ? AND citizenid = ?', { roomId, targetCid })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Removed ' .. targetCid .. ' from room' })

    local targetSrc = getPlayerByCID(targetCid)
    if targetSrc then
        TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'error', description = 'You were removed from a Black Chat room' })
    end
end)

RegisterNetEvent('phone:getBlackChatMembers', function(roomId)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    if not isBCMember(roomId, cid) then return end
    local members = MySQL.query.await([[
        SELECT rm.citizenid, rm.role, rm.joined_at, c.firstname, c.lastname
        FROM blackchat_room_members rm
        LEFT JOIN characters c ON c.citizenid = rm.citizenid
        WHERE rm.room_id = ? ORDER BY rm.joined_at ASC
    ]], { roomId })
    TriggerClientEvent('phone:loadBCMembers', src, { roomId = roomId, members = members or {} })
end)

RegisterNetEvent('phone:sendBlackChatMessage', function(roomId, content, selfDestruct)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    local hasItem = exports.ox_inventory:Search(src, 1, 'crypto_phone')
    if not hasItem or #hasItem == 0 then return end
    if not isBCMember(roomId, cid) then return end

    if content:sub(1,1) == '/' then
        local cmd, args = content:sub(2):match('^(%S+)%s*(.*)$')
        if cmd == 'add' and args and args ~= '' then
            TriggerEvent('phone:addBlackChatMember', roomId, args)
            return
        end
    end

    local msgId = MySQL.insert.await('INSERT INTO blackchat_messages (sender_cid, room_id, content, self_destruct_after) VALUES (?, ?, ?, ?)',
        { cid, roomId, content, selfDestruct or 0 })

    if msgId and selfDestruct and selfDestruct > 0 then
        Citizen.CreateThread(function()
            Citizen.Wait(selfDestruct * 1000)
            MySQL.update('DELETE FROM blackchat_messages WHERE id = ?', { msgId })
        end)
    end

    local members = MySQL.query.await('SELECT citizenid FROM blackchat_room_members WHERE room_id = ?', { roomId })
    for _, m in ipairs(members) do
        local targetSrc = getPlayerByCID(m.citizenid)
        if targetSrc then
            local pHasItem = exports.ox_inventory:Search(targetSrc, 1, 'crypto_phone')
            if pHasItem and #pHasItem > 0 then
                TriggerClientEvent('phone:blackChatMessage', targetSrc, {
                    roomId = roomId,
                    sender = cid,
                    senderName = getPlayerName(src),
                    content = content,
                    created_at = os.date('%Y-%m-%d %H:%M:%S'),
                    selfDestruct = selfDestruct or 0,
                })
            end
        end
    end
end)

-- ==================== SETTINGS ====================
RegisterNetEvent('phone:setSilentMode', function(enabled)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    MySQL.update('INSERT INTO phone_settings (citizenid, silent_mode) VALUES (?, ?) ON DUPLICATE KEY UPDATE silent_mode = ?',
        { cid, enabled and 1 or 0, enabled and 1 or 0 })
end)

RegisterNetEvent('phone:setSpeaker', function(enabled)
    local src = source
    local cid = getCID(src)
    if not cid then return end
    if enabled then
        TriggerClientEvent('phone:setSpeaker', src, true)
        TriggerEvent('voice:server:toggleSpeaker', src, true)
    else
        TriggerClientEvent('phone:setSpeaker', src, false)
        TriggerEvent('voice:server:toggleSpeaker', src, false)
    end
end)

-- ==================== WEATHER ====================
RegisterNetEvent('phone:getWeather', function()
    local src = source
    local weatherState = GlobalState.weatherType or 'CLEAR'
    local weatherMap = {
        CLEAR = { icon = '☀️', temp = 78, label = 'Clear Sky', humidity = 40 },
        EXTRASUNNY = { icon = '☀️', temp = 85, label = 'Extra Sunny', humidity = 35 },
        CLOUDS = { icon = '☁️', temp = 72, label = 'Cloudy', humidity = 55 },
        OVERCAST = { icon = '☁️', temp = 68, label = 'Overcast', humidity = 65 },
        RAIN = { icon = '🌧️', temp = 62, label = 'Rainy', humidity = 85 },
        THUNDER = { icon = '⛈️', temp = 60, label = 'Thunderstorm', humidity = 90 },
        SMOG = { icon = '🌫️', temp = 70, label = 'Smoggy', humidity = 50 },
        FOGGY = { icon = '🌫️', temp = 65, label = 'Foggy', humidity = 70 },
        SNOW = { icon = '❄️', temp = 28, label = 'Snowy', humidity = 80 },
        BLIZZARD = { icon = '❄️', temp = 22, label = 'Blizzard', humidity = 85 },
        HALLOWEEN = { icon = '🌧️', temp = 55, label = 'Spooky', humidity = 75 },
        NEUTRAL = { icon = '☁️', temp = 72, label = 'Neutral', humidity = 50 },
    }
    local weather = weatherMap[weatherState] or { icon = '☀️', temp = 78, label = 'Clear', humidity = 45 }
    TriggerClientEvent('phone:loadWeather', src, weather)
end)

-- ==================== ON PLAYER DROP ====================
AddEventHandler('playerDropped', function()
    local src = source
    if activeCalls[src] then
        local call = activeCalls[src]
        TriggerClientEvent('phone:callEnded', call.peer, { reason = 'disconnected' })
        activeCalls[call.peer] = nil
        activeCalls[src] = nil
    end
end)
