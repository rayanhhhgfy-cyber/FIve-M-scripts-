local QBox = exports['qbx-core']:GetCoreObject()

--- State
local activeCalls = {}
local callChannels = {}
local pendingCalls = {}

--- Rate limit
local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

--- Helpers
local function getNumberForSource(src)
    local p = QBox.Functions.GetPlayer(src)
    return p and p.PlayerData.charinfo and p.PlayerData.charinfo.phone or nil
end

local function getSourceForNumber(number)
    local players = QBox.Functions.GetPlayers()
    for _, sid in ipairs(players) do
        local pl = QBox.Functions.GetPlayer(sid)
        if pl and pl.PlayerData.charinfo and pl.PlayerData.charinfo.phone == number then
            return sid
        end
    end
    return nil
end

local function getPlayerName(src)
    local p = QBox.Functions.GetPlayer(src)
    if p and p.PlayerData.charinfo then
        return (p.PlayerData.charinfo.firstname or '') .. ' ' .. (p.PlayerData.charinfo.lastname or '')
    end
    return 'Unknown'
end

--- Data
RegisterNetEvent('phone:server:getData', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('SELECT * FROM phone_contacts WHERE owner_cid = ? ORDER BY name ASC', { cid }, function(ct)
        MySQL.query('SELECT * FROM phone_messages WHERE sender_cid = ? OR receiver_cid = ? ORDER BY created_at DESC LIMIT 200', { cid, cid }, function(msgs)
            MySQL.query('SELECT * FROM phone_notes WHERE citizenid = ? ORDER BY created_at DESC', { cid }, function(nt)
                MySQL.query('SELECT * FROM phone_photos WHERE citizenid = ? ORDER BY created_at DESC', { cid }, function(ph)
                    MySQL.query('SELECT * FROM phone_videos WHERE citizenid = ? ORDER BY created_at DESC', { cid }, function(vd)
                        MySQL.query('SELECT * FROM phone_call_history WHERE caller_cid = ? OR receiver_cid = ? ORDER BY called_at DESC LIMIT 100', { cid, cid }, function(ch)
                            MySQL.query('SELECT * FROM phone_groups WHERE owner_cid = ? OR JSON_CONTAINS(members, ?) ORDER BY created_at DESC', { cid, '"' .. p.PlayerData.charinfo.phone .. '"' }, function(grps)
                                local groupsData = {}
                                for _, g in ipairs(grps or {}) do
                                    table.insert(groupsData, { id = g.id, name = g.name, members = json.decode(g.members) or {}, created_at = g.created_at })
                                end
                                TriggerClientEvent('phone:client:receiveData', src, { contacts = ct or {}, messages = msgs or {}, notes = nt or {}, photos = ph or {}, videos = vd or {}, callHistory = ch or {}, groups = groupsData })
                            end)
                        end)
                    end)
                end)
            end)
        end)
    end)
end)

--- Messages
RegisterNetEvent('phone:server:sendMessage', function(number, content)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'sendMsg', 30) or not content or #content > 1000 then return end
    local myNum = p.PlayerData.charinfo.phone
    local cid = p.PlayerData.citizenid
    local tgt = getSourceForNumber(number)
    if tgt then
        local tp = QBox.Functions.GetPlayer(tgt)
        local tgtCid = tp and tp.PlayerData.citizenid
        if tgtCid then
            MySQL.insert('INSERT INTO phone_messages (sender_cid, receiver_cid, content) VALUES (?, ?, ?)', { cid, tgtCid, content })
            MySQL.insert('INSERT INTO phone_messages (sender_cid, receiver_cid, content) VALUES (?, ?, ?)', { tgtCid, cid, content })
            TriggerClientEvent('phone:client:receiveMessage', tgt, myNum, content)
        end
    end
end)

--- Contacts
RegisterNetEvent('phone:server:addContact', function(name, number)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not name or not number then return end
    MySQL.insert('INSERT INTO phone_contacts (owner_cid, name, number) VALUES (?, ?, ?)', { p.PlayerData.citizenid, name, number })
end)

--- Notes
RegisterNetEvent('phone:server:saveNote', function(content)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not content then return end
    MySQL.insert('INSERT INTO phone_notes (citizenid, title, content) VALUES (?, ?, ?)', { p.PlayerData.citizenid, 'Note', content })
end)

--- Photos
RegisterNetEvent('phone:server:savePhoto', function(base64data)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not base64data then return end
    MySQL.insert('INSERT INTO phone_photos (citizenid, image_data, filename) VALUES (?, ?, ?)', { p.PlayerData.citizenid, base64data, 'photo_' .. os.time() .. '.png' }, function(id)
        if id then
            local photoData = { id = id, image_data = base64data, created_at = os.time() }
            TriggerClientEvent('phone:client:photoSaved', src, photoData)
        end
    end)
end)

--- Image Messages
RegisterNetEvent('phone:server:sendImage', function(number, imageData)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'sendImg', 20) or not imageData then return end
    local myNum = p.PlayerData.charinfo.phone; local cid = p.PlayerData.citizenid
    local tgt = getSourceForNumber(number)
    if tgt then
        local tp = QBox.Functions.GetPlayer(tgt); local tgtCid = tp and tp.PlayerData.citizenid
        if tgtCid then
            MySQL.insert('INSERT INTO phone_messages (sender_cid, receiver_cid, content) VALUES (?, ?, ?)', { cid, tgtCid, '[Image]' })
            MySQL.insert('INSERT INTO phone_messages (sender_cid, receiver_cid, content) VALUES (?, ?, ?)', { tgtCid, cid, '[Image]' })
            TriggerClientEvent('phone:client:receiveImage', tgt, myNum, imageData)
        end
    end
end)

--- Group Messaging
RegisterNetEvent('phone:server:createGroup', function(name, members)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not name or not members or #members < 1 then return end
    local cid = p.PlayerData.citizenid
    MySQL.insert('INSERT INTO phone_groups (owner_cid, name, members, created_at) VALUES (?, ?, ?, ?)', { cid, name, json.encode(members), os.time() }, function(id)
        if id then
            TriggerClientEvent('phone:client:groupCreated', src, { id = id, name = name, members = members })
        end
    end)
end)

RegisterNetEvent('phone:server:sendGroupMessage', function(groupId, content)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not content then return end
    local myNum = p.PlayerData.charinfo.phone
    MySQL.query('SELECT * FROM phone_groups WHERE id = ?', { groupId }, function(group)
        if group and group[1] then
            local members = json.decode(group[1].members) or {}
            for _, memberNum in ipairs(members) do
                local tgt = getSourceForNumber(memberNum)
                if tgt and tgt ~= src then
                    TriggerClientEvent('phone:client:groupMessage', tgt, groupId, myNum, content)
                end
            end
        end
    end)
end)

RegisterNetEvent('phone:server:sendGroupImage', function(groupId, imageData)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not imageData then return end
    local myNum = p.PlayerData.charinfo.phone
    MySQL.query('SELECT * FROM phone_groups WHERE id = ?', { groupId }, function(group)
        if group and group[1] then
            local members = json.decode(group[1].members) or {}
            for _, memberNum in ipairs(members) do
                local tgt = getSourceForNumber(memberNum)
                if tgt and tgt ~= src then
                    TriggerClientEvent('phone:client:groupImage', tgt, groupId, myNum, imageData)
                end
            end
        end
    end)
end)

--- BlackChat (untraceable encrypted gang messaging — no DB, in-memory only)
local bcChats = {}
RegisterNetEvent('bc:server:startChat', function(peer)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not peer then return end
end)

RegisterNetEvent('bc:server:sendMessage', function(peer, content)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'bcMsg', 40) or not content then return end
    local myNum = p.PlayerData.charinfo.phone
    local tgt = getSourceForNumber(peer)
    if tgt then
        TriggerClientEvent('bc:client:message', tgt, myNum, content)
    end
end)

RegisterNetEvent('bc:server:sendImage', function(peer, imageData)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not imageData then return end
    local myNum = p.PlayerData.charinfo.phone
    local tgt = getSourceForNumber(peer)
    if tgt then
        TriggerClientEvent('bc:client:image', tgt, myNum, imageData)
    end
end)

RegisterNetEvent('bc:server:createGroup', function(name, members)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not name or not members or #members < 1 then return end
    local myNum = p.PlayerData.charinfo.phone
    local gid = 'bcg_' .. os.time() .. '_' .. src
    bcChats[gid] = { name = name, members = members, owner = myNum }
    for _, memberNum in ipairs(members) do
        local tgt = getSourceForNumber(memberNum)
        if tgt and tgt ~= src then
            TriggerClientEvent('bc:client:groupCreated', tgt, { id = gid, name = name, members = members })
        end
    end
    TriggerClientEvent('bc:client:groupCreated', src, { id = gid, name = name, members = members })
end)

RegisterNetEvent('bc:server:sendGroupMessage', function(groupId, content)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not content or not bcChats[groupId] then return end
    local myNum = p.PlayerData.charinfo.phone
    local group = bcChats[groupId]
    for _, memberNum in ipairs(group.members) do
        local tgt = getSourceForNumber(memberNum)
        if tgt and tgt ~= src then
            TriggerClientEvent('bc:client:groupMessage', tgt, groupId, myNum, content)
        end
    end
end)

RegisterNetEvent('bc:server:sendGroupImage', function(groupId, imageData)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not imageData or not bcChats[groupId] then return end
    local myNum = p.PlayerData.charinfo.phone
    local group = bcChats[groupId]
    for _, memberNum in ipairs(group.members) do
        local tgt = getSourceForNumber(memberNum)
        if tgt and tgt ~= src then
            TriggerClientEvent('bc:client:groupImage', tgt, groupId, myNum, imageData)
        end
    end
end)

--- Calling
RegisterNetEvent('phone:server:dialNumber', function(number)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not number or not rl(src, 'dial', 10) then return end
    local myNum = p.PlayerData.charinfo.phone
    local myCid = p.PlayerData.citizenid
    if number == myNum then TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Cannot call yourself' }) return end
    if activeCalls[src] or pendingCalls[src] then TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already in a call' }) return end
    local tgt = getSourceForNumber(number)
    if not tgt then TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Number not found or offline' }) return end
    if activeCalls[tgt] or pendingCalls[tgt] then TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Line is busy' }) return end
    local callerName = getPlayerName(src); local peerName = getPlayerName(tgt)
    pendingCalls[src] = { peer = tgt, peerNumber = number, peerName = peerName, direction = 'outgoing' }
    pendingCalls[tgt] = { peer = src, peerNumber = myNum, peerName = callerName, direction = 'incoming' }
    TriggerClientEvent('phone:client:incomingCall', tgt, myNum, callerName)
    TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Calling ' .. (peerName or number) .. '...' })
    --- Log call
    MySQL.insert('INSERT INTO phone_call_history (caller_cid, receiver_cid, status) VALUES (?, ?, ?)', { myCid, number, 'dialed' })
end)

RegisterNetEvent('phone:server:answerCall', function()
    local src = source; local pending = pendingCalls[src]
    if not pending then return end
    local peer = pending.peer
    local channel = math.random(100, 999)
    while callChannels[channel] do channel = math.random(100, 999) end
    callChannels[src] = channel; callChannels[peer] = channel
    activeCalls[src] = { peer = peer, channel = channel, peerName = pending.peerName, peerNumber = pending.peerNumber }
    activeCalls[peer] = { peer = src, channel = channel, peerName = pending.peerName, peerNumber = pending.peerNumber }
    pendingCalls[src] = nil; pendingCalls[peer] = nil
    local pName = getPlayerName(src)
    TriggerClientEvent('phone:client:callConnected', peer, pending.peerNumber, pName)
    TriggerClientEvent('phone:client:callConnected', src, pending.peerNumber, pending.peerName)
    --- Update call history
    local p2 = QBox.Functions.GetPlayer(src); local p2Cid = p2 and p2.PlayerData.citizenid
    if p2Cid then
        MySQL.query('UPDATE phone_call_history SET status = ?, answered_at = NOW() WHERE caller_cid = ? AND receiver_cid = ? AND status = ? ORDER BY called_at DESC LIMIT 1', { 'answered', p2Cid, pending.peerNumber, 'dialed' })
    end
end)

RegisterNetEvent('phone:server:rejectCall', function()
    local src = source; local pending = pendingCalls[src]
    if not pending then return end
    local callerSrc = pending.peer
    pendingCalls[src] = nil; pendingCalls[callerSrc] = nil
    TriggerClientEvent('phone:client:callEnded', callerSrc)
    TriggerClientEvent('ox_lib:notify', callerSrc, { type = 'error', description = 'Call rejected' })
end)

RegisterNetEvent('phone:server:endCall', function()
    local src = source; local call = activeCalls[src]
    if not call then
        if pendingCalls[src] then
            local pending = pendingCalls[src]; local peer = pending.peer
            pendingCalls[src] = nil
            if pendingCalls[peer] then pendingCalls[peer] = nil; TriggerClientEvent('phone:client:callEnded', peer) end
        end
        return
    end
    local peer = call.peer; local channel = call.channel
    callChannels[src] = nil; callChannels[peer] = nil
    activeCalls[src] = nil; activeCalls[peer] = nil
    TriggerClientEvent('phone:client:callEnded', src)
    TriggerClientEvent('phone:client:callEnded', peer)
end)

RegisterNetEvent('phone:server:toggleMute', function(muted)
    local src = source; local call = activeCalls[src]
    if not call then return end
    TriggerClientEvent('phone:client:muteState', call.peer, muted or false)
end)

RegisterNetEvent('voice:server:toggleSpeaker', function(enabled)
    local src = source
    if enabled then
        exports['pma-voice']:setVoiceProperty('radioEnabled', false)
        exports['pma-voice']:setVoiceProperty('micClicks', false)
    else
        exports['pma-voice']:setVoiceProperty('radioEnabled', true)
        exports['pma-voice']:setVoiceProperty('micClicks', true)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activeCalls[src] then
        local call = activeCalls[src]; local peer = call.peer
        callChannels[src] = nil; callChannels[peer] = nil
        activeCalls[src] = nil; activeCalls[peer] = nil
        TriggerClientEvent('phone:client:callEnded', peer)
    end
    if pendingCalls[src] then
        local pending = pendingCalls[src]
        if pendingCalls[pending.peer] then pendingCalls[pending.peer] = nil; TriggerClientEvent('phone:client:callEnded', pending.peer) end
        pendingCalls[src] = nil
    end
end)

--- X (Twitter) Server Events
RegisterNetEvent('x:server:getTweets', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM phone_tweets ORDER BY created_at DESC LIMIT 50', {}, function(tweets)
        TriggerClientEvent('x:client:receiveTweets', src, tweets or {})
    end)
end)

RegisterNetEvent('x:server:postTweet', function(content)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not content or #content > 280 then return end
    local cid = p.PlayerData.citizenid
    local name = (p.PlayerData.charinfo.firstname or '') .. ' ' .. (p.PlayerData.charinfo.lastname or '')
    MySQL.insert('INSERT INTO phone_tweets (citizenid, name, content) VALUES (?, ?, ?)', { cid, name, content }, function(id)
        if id then
            local tweet = { id = id, citizenid = cid, name = name, content = content, created_at = os.time(), likes = 0 }
            TriggerClientEvent('x:client:newTweet', -1, tweet)
        end
    end)
end)

RegisterNetEvent('x:server:likeTweet', function(tweetId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not tweetId then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('SELECT * FROM phone_tweet_likes WHERE tweet_id = ? AND citizenid = ?', { tweetId, cid }, function(existing)
        if existing and #existing > 0 then
            MySQL.query('DELETE FROM phone_tweet_likes WHERE tweet_id = ? AND citizenid = ?', { tweetId, cid })
            MySQL.query('UPDATE phone_tweets SET likes = likes - 1 WHERE id = ?', { tweetId })
        else
            MySQL.insert('INSERT INTO phone_tweet_likes (tweet_id, citizenid) VALUES (?, ?)', { tweetId, cid })
            MySQL.query('UPDATE phone_tweets SET likes = likes + 1 WHERE id = ?', { tweetId })
        end
    end)
end)

--- TikTok Server Events
RegisterNetEvent('tiktok:server:getFeed', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM phone_tiktok_videos ORDER BY created_at DESC LIMIT 50', {}, function(videos)
        TriggerClientEvent('tiktok:client:receiveFeed', src, videos or {})
    end)
end)

RegisterNetEvent('tiktok:server:upload', function(videoData, description)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not videoData then return end
    local cid = p.PlayerData.citizenid
    local name = (p.PlayerData.charinfo.firstname or '') .. ' ' .. (p.PlayerData.charinfo.lastname or '')
    MySQL.insert('INSERT INTO phone_tiktok_videos (citizenid, name, video_data, description) VALUES (?, ?, ?, ?)', { cid, name, videoData, description or '' })
end)

RegisterNetEvent('tiktok:server:like', function(videoId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not videoId then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('SELECT * FROM phone_tiktok_likes WHERE video_id = ? AND citizenid = ?', { videoId, cid }, function(existing)
        if existing and #existing > 0 then
            MySQL.query('DELETE FROM phone_tiktok_likes WHERE video_id = ? AND citizenid = ?', { videoId, cid })
            MySQL.query('UPDATE phone_tiktok_videos SET likes = likes - 1 WHERE id = ?', { videoId })
        else
            MySQL.insert('INSERT INTO phone_tiktok_likes (video_id, citizenid) VALUES (?, ?)', { videoId, cid })
            MySQL.query('UPDATE phone_tiktok_videos SET likes = likes + 1 WHERE id = ?', { videoId })
        end
    end)
end)

--- Uber Eats Server Events
RegisterNetEvent('ubereats:server:getRestaurants', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM phone_restaurants ORDER BY name ASC', {}, function(restaurants)
        restaurants = restaurants or {}
        if #restaurants == 0 then
            TriggerClientEvent('ubereats:client:receiveRestaurants', src, {})
            return
        end
        local done = 0
        for i, r in ipairs(restaurants) do
            MySQL.query('SELECT * FROM phone_restaurant_menu WHERE restaurant_id = ? ORDER BY price ASC', { r.id }, function(menu)
                restaurants[i].menu = menu or {}
                done = done + 1
                if done >= #restaurants then
                    TriggerClientEvent('ubereats:client:receiveRestaurants', src, restaurants)
                end
            end)
        end
    end)
end)

RegisterNetEvent('ubereats:server:placeOrder', function(restaurantId, items)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not restaurantId or not items then return end
    local cid = p.PlayerData.citizenid
    local total = 0
    MySQL.query('SELECT * FROM phone_restaurant_menu WHERE restaurant_id = ?', { restaurantId }, function(menu)
        for _, item in ipairs(items or {}) do
            for _, mi in ipairs(menu or {}) do
                if mi.item_name == item.name then total = total + (mi.price or 0) * (item.qty or 1) end
            end
        end
        if total > 0 then
            MySQL.insert('INSERT INTO phone_delivery_orders (citizenid, restaurant_id, items, total, status) VALUES (?, ?, ?, ?, ?)', { cid, restaurantId, json.encode(items), total, 'pending' }, function(id)
                if id then
                    local order = { id = id, restaurant_id = restaurantId, items = items, total = total, status = 'pending' }
                    TriggerClientEvent('ubereats:client:orderPlaced', src, order)
                end
            end)
        end
    end)
end)

RegisterNetEvent('ubereats:server:getOrders', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('SELECT * FROM phone_delivery_orders WHERE citizenid = ? ORDER BY created_at DESC', { cid }, function(orders)
        local parsed = {}
        for _, o in ipairs(orders or {}) do
            o.items = json.decode(o.items) or {}
            table.insert(parsed, o)
        end
        TriggerClientEvent('ubereats:client:receiveOrders', src, parsed)
    end)
end)

--- Banking Server Events
RegisterNetEvent('banking:server:getData', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    local balance = p.PlayerData.money and p.PlayerData.money.bank or 0
    MySQL.query('SELECT * FROM bank_transactions WHERE citizenid = ? ORDER BY created_at DESC LIMIT 50', { cid }, function(transactions)
        TriggerClientEvent('banking:client:receiveData', src, balance, transactions or {})
    end)
end)

RegisterNetEvent('banking:server:transfer', function(target, amount)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not target or not amount then return end
    amount = tonumber(amount)
    if not amount or amount < 1 then return end
    local cid = p.PlayerData.citizenid
    local myNum = p.PlayerData.charinfo.phone
    if p.PlayerData.money.bank < amount then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient funds' })
        return
    end
    local tgt = getSourceForNumber(target)
    if not tgt then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Target not found' })
        return
    end
    local tp = QBox.Functions.GetPlayer(tgt)
    if not tp then return end
    p.Functions.RemoveMoney('bank', amount)
    tp.Functions.AddMoney('bank', amount)
    local tgtCid = tp.PlayerData.citizenid
    MySQL.insert('INSERT INTO bank_transactions (citizenid, target, amount, type) VALUES (?, ?, ?, ?)', { cid, target, amount, 'sent' })
    MySQL.insert('INSERT INTO bank_transactions (citizenid, target, amount, type) VALUES (?, ?, ?, ?)', { tgtCid, myNum, amount, 'received' })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Transferred $' .. amount })
    TriggerClientEvent('ox_lib:notify', tgt, { type = 'info', description = 'Received $' .. amount .. ' from ' .. myNum })
end)

--- Seed default restaurants on resource start
Citizen.CreateThread(function()
    Citizen.Wait(5000)
    MySQL.query('SELECT COUNT(*) as cnt FROM phone_restaurants', {}, function(result)
        if result and result[1] and result[1].cnt == 0 then
            MySQL.insert('INSERT INTO phone_restaurants (name, description, delivery_time) VALUES (?, ?, ?)', { "Pizza This", "Authentic Italian pizzas made in wood-fired ovens", "25-35" })
            MySQL.insert('INSERT INTO phone_restaurants (name, description, delivery_time) VALUES (?, ?, ?)', { "Burger Shot", "Juicy smash burgers with fresh ingredients", "20-30" })
            MySQL.insert('INSERT INTO phone_restaurants (name, description, delivery_time) VALUES (?, ?, ?)', { "Taco Bomb", "Mexican street tacos loaded with flavor", "15-25" })
            MySQL.insert('INSERT INTO phone_restaurants (name, description, delivery_time) VALUES (?, ?, ?)', { "Sushi Royale", "Premium Japanese sushi and sashimi", "30-45" })
            MySQL.insert('INSERT INTO phone_restaurants (name, description, delivery_time) VALUES (?, ?, ?)', { "Cluckin' Bell", "Fried chicken buckets and family meals", "20-35" })
            Citizen.Wait(100)
            MySQL.query('SELECT * FROM phone_restaurants', {}, function(rests)
                if rests then
                    for _, r in ipairs(rests) do
                        if r.name == "Pizza This" then
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Margherita", 12.99, "Pizza" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Pepperoni", 14.99, "Pizza" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "BBQ Chicken", 16.99, "Pizza" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Garlic Bread", 5.99, "Sides" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Tiramisu", 7.99, "Dessert" })
                        elseif r.name == "Burger Shot" then
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Classic Burger", 9.99, "Burgers" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Cheese Burger", 11.49, "Burgers" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Bacon Deluxe", 13.99, "Burgers" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Veggie Burger", 10.49, "Burgers" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Fries", 3.99, "Sides" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Milkshake", 4.99, "Drinks" })
                        elseif r.name == "Taco Bomb" then
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Street Taco", 3.99, "Tacos" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Burrito Supreme", 8.99, "Burritos" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Quesadilla", 6.99, "Specials" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Nachos", 5.99, "Sides" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Churros", 4.49, "Dessert" })
                        elseif r.name == "Sushi Royale" then
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "California Roll", 10.99, "Rolls" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Salmon Nigiri", 8.99, "Nigiri" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Dragon Roll", 14.99, "Rolls" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Miso Soup", 3.99, "Sides" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Edamame", 4.99, "Sides" })
                        elseif r.name == "Cluckin' Bell" then
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Fried Chicken Bucket", 15.99, "Chicken" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Chicken Sandwich", 8.99, "Chicken" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Chicken Tenders", 7.99, "Chicken" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Coleslaw", 2.99, "Sides" })
                            MySQL.insert('INSERT INTO phone_restaurant_menu (restaurant_id, item_name, price, category) VALUES (?, ?, ?, ?)', { r.id, "Corn on the Cob", 3.49, "Sides" })
                        end
                    end
                end
            end)
        end
    end)
end)

--- Gigs (Server Jobs Board) Events
RegisterNetEvent('gigs:server:getList', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('SELECT * FROM phone_gigs ORDER BY created_at DESC LIMIT 50', {}, function(gigs)
        local parsed = {}
        for _, g in ipairs(gigs or {}) do
            g.poster_name = 'Unknown'
            local poster = QBox.Functions.GetPlayerByCitizenId(g.poster_cid)
            if poster then
                g.poster_name = (poster.PlayerData.charinfo.firstname or '') .. ' ' .. (poster.PlayerData.charinfo.lastname or '')
            end
            table.insert(parsed, g)
        end
        TriggerClientEvent('gigs:client:receiveList', src, parsed)
    end)
end)

RegisterNetEvent('gigs:server:post', function(title, description, reward, locationLabel)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not title or not reward or reward <= 0 then return end
    local cid = p.PlayerData.citizenid
    local coords = GetEntityCoords(GetPlayerPed(src))
    MySQL.insert('INSERT INTO phone_gigs (poster_cid, title, description, reward, location_x, location_y, location_z, location_label, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { cid, title, description or '', reward, coords.x, coords.y, coords.z, locationLabel or 'Current location', 'open' }, function(id)
        if id then
            local gig = { id = id, poster_cid = cid, title = title, description = description or '', reward = reward, location_label = locationLabel or 'Current location', status = 'open' }
            TriggerClientEvent('gigs:client:gigCreated', src, gig)
        end
    end)
end)

RegisterNetEvent('gigs:server:accept', function(gigId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not gigId then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('SELECT * FROM phone_gigs WHERE id = ? AND status = ?', { gigId, 'open' }, function(gigs)
        if not gigs or #gigs == 0 then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Gig not available' })
            return
        end
        if gigs[1].poster_cid == cid then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Cannot accept your own gig' })
            return
        end
        MySQL.update('UPDATE phone_gigs SET status = ?, worker_cid = ? WHERE id = ? AND status = ?', { 'assigned', cid, gigId, 'open' }, function(rows)
            if rows and rows > 0 then
                TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gig accepted!' })
                local poster = QBox.Functions.GetPlayerByCitizenId(gigs[1].poster_cid)
                if poster then
                    TriggerClientEvent('ox_lib:notify', poster.PlayerData.source, { type = 'info', description = 'Your gig was accepted' })
                end
            end
        end)
    end)
end)

RegisterNetEvent('gigs:server:complete', function(gigId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not gigId then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('SELECT * FROM phone_gigs WHERE id = ? AND status = ? AND worker_cid = ?', { gigId, 'assigned', cid }, function(gigs)
        if not gigs or #gigs == 0 then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Gig not found or already completed' })
            return
        end
        local gig = gigs[1]
        MySQL.update('UPDATE phone_gigs SET status = ? WHERE id = ?', { 'completed', gigId }, function(rows)
            if rows and rows > 0 then
                p.Functions.AddMoney('bank', gig.reward)
                TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gig completed! +$' .. gig.reward })
                local poster = QBox.Functions.GetPlayerByCitizenId(gig.poster_cid)
                if poster then
                    local pMoney = poster.PlayerData.money.bank or 0
                    if pMoney >= gig.reward then
                        poster.Functions.RemoveMoney('bank', gig.reward)
                        TriggerClientEvent('ox_lib:notify', poster.PlayerData.source, { type = 'info', description = 'Your gig was completed -$' .. gig.reward })
                    end
                end
            end
        end)
    end)
end)

RegisterNetEvent('gigs:server:cancel', function(gigId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not gigId then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('SELECT * FROM phone_gigs WHERE id = ? AND poster_cid = ? AND status != ?', { gigId, cid, 'completed' }, function(gigs)
        if not gigs or #gigs == 0 then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Gig not found' })
            return
        end
        MySQL.update('UPDATE phone_gigs SET status = ? WHERE id = ?', { 'cancelled', gigId }, function()
            TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Gig cancelled' })
        end)
    end)
end)

--- Calendar Events
RegisterNetEvent('calendar:server:getEvents', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('SELECT * FROM phone_calendar WHERE citizenid = ? ORDER BY event_date ASC', { cid }, function(events)
        TriggerClientEvent('calendar:client:receiveEvents', src, events or {})
    end)
end)

RegisterNetEvent('calendar:server:saveEvent', function(title, description, date, time)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not title or not date then return end
    local cid = p.PlayerData.citizenid
    MySQL.insert('INSERT INTO phone_calendar (citizenid, title, description, event_date, event_time) VALUES (?, ?, ?, ?, ?)',
        { cid, title, description or '', date, time or '12:00' })
end)

RegisterNetEvent('calendar:server:deleteEvent', function(eventId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not eventId then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('DELETE FROM phone_calendar WHERE id = ? AND citizenid = ?', { eventId, cid })
end)

--- Wallet Events
RegisterNetEvent('wallet:server:getCards', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('SELECT * FROM phone_wallet WHERE citizenid = ? ORDER BY created_at ASC', { cid }, function(cards)
        TriggerClientEvent('wallet:client:receiveCards', src, cards or {})
    end)
end)

RegisterNetEvent('wallet:server:addCard', function(cardType, cardNumber, holderName)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not cardType then return end
    local cid = p.PlayerData.citizenid
    MySQL.insert('INSERT INTO phone_wallet (citizenid, card_type, card_number, holder_name) VALUES (?, ?, ?, ?)',
        { cid, cardType, cardNumber or '****', holderName or (p.PlayerData.charinfo.firstname or '') .. ' ' .. (p.PlayerData.charinfo.lastname or '') })
end)

RegisterNetEvent('wallet:server:deleteCard', function(cardId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not cardId then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('DELETE FROM phone_wallet WHERE id = ? AND citizenid = ?', { cardId, cid })
end)

--- Video Recording Events
RegisterNetEvent('video:server:saveVideo', function(videoData, thumbnail)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not videoData then return end
    local cid = p.PlayerData.citizenid
    MySQL.insert('INSERT INTO phone_videos (citizenid, video_data, thumbnail, filename) VALUES (?, ?, ?, ?)',
        { cid, videoData, thumbnail or '', 'video_' .. os.time() .. '.webm' }, function(id)
        if id then
            TriggerClientEvent('video:client:videoSaved', src, { id = id, video_data = videoData, thumbnail = thumbnail, created_at = os.time() })
        end
    end)
end)

--- Vehicle App
lib.callback.register('vehicleApp:server:getVehicles', function(source)
    local p = QBox.Functions.GetPlayer(source)
    if not p then return {} end
    local cid = p.PlayerData.citizenid
    local vehicles = MySQL.query.await('SELECT plate, model, garage, fuel FROM player_vehicles WHERE citizenid = ? ORDER BY id DESC', { cid })
    local result = {}
    for _, v in ipairs(vehicles) do
        local state = 'stored'
        if v.garage == 'out' then state = 'out' end
        table.insert(result, {
            plate = v.plate,
            model = v.model,
            state = state,
            garage = v.garage,
            fuel = v.fuel or 100
        })
    end
    return result
end)

lib.callback.register('vehicleApp:server:toggleLock', function(source, plate)
    local p = QBox.Functions.GetPlayer(source)
    if not p then return { success = false, error = 'Player not found' } end
    local cid = p.PlayerData.citizenid
    local vd = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, cid })
    if not vd then return { success = false, error = 'Not your vehicle' } end
    for _, entity in ipairs(GetAllVehicles()) do
        if GetVehicleNumberPlateText(entity) == plate then
            local locked = GetVehicleDoorLockStatus(entity)
            local newLocked = (locked == 1 or locked == 0)
            SetVehicleDoorsLocked(entity, newLocked and 2 or 1)
            SetVehicleDoorsLockedForAllPlayers(entity, newLocked)
            return { success = true, locked = newLocked }
        end
    end
    return { success = false, error = 'Vehicle not found in world' }
end)

lib.callback.register('vehicleApp:server:toggleEngine', function(source, plate)
    local p = QBox.Functions.GetPlayer(source)
    if not p then return { success = false, error = 'Player not found' } end
    local cid = p.PlayerData.citizenid
    local vd = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, cid })
    if not vd then return { success = false, error = 'Not your vehicle' } end
    for _, entity in ipairs(GetAllVehicles()) do
        if GetVehicleNumberPlateText(entity) == plate then
            local isOn = GetIsVehicleEngineRunning(entity)
            SetVehicleEngineOn(entity, not isOn, true, false)
            SetVehicleUndriveable(entity, false)
            return { success = true, engineOn = not isOn }
        end
    end
    return { success = false, error = 'Vehicle not found in world' }
end)

lib.callback.register('vehicleApp:server:trackVehicle', function(source, plate)
    local p = QBox.Functions.GetPlayer(source)
    if not p then return { success = false } end
    local cid = p.PlayerData.citizenid
    local vd = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, cid })
    if not vd or vd.garage ~= 'out' then return { success = false, error = 'Vehicle not spawned' } end
    for _, entity in ipairs(GetAllVehicles()) do
        if GetVehicleNumberPlateText(entity) == plate then
            local coords = GetEntityCoords(entity)
            return { success = true, x = coords.x, y = coords.y }
        end
    end
    return { success = false, error = 'Vehicle not found' }
end)

exports('getCallChannel', function(src) return callChannels[src] end)
exports('isInCall', function(src) return activeCalls[src] ~= nil end)
