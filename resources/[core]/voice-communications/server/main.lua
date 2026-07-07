local QBox = exports['qbx_core']:GetCoreObject()
local playerRadioState = {}
local playerSpeakerState = {}

local RATE_LIMITS = {}
local function checkRateLimit(src, action)
  local key = src .. ':' .. action
  local now = os.time()
  RATE_LIMITS[key] = RATE_LIMITS[key] or {}
  table.insert(RATE_LIMITS[key], now)
  for i = #RATE_LIMITS[key], 1, -1 do
    if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
  end
  local limit = Config.VoiceComms.rateLimits[action] or 10
  return #RATE_LIMITS[key] <= limit
end

local function getPlayerJobName(src)
  local player = QBox.Functions.GetPlayer(src)
  if not player then return nil end
  return player.PlayerData.job.name
end

--- Tier 1: Police Radio
RegisterNetEvent('voice:server:joinPoliceChannel', function(channel)
  local src = source
  if not checkRateLimit(src, 'joinChannel') then return end
  local job = getPlayerJobName(src)
  if not job or job ~= Config.VoiceComms.policeJob then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  channel = tonumber(channel)
  if not channel then return end
  exports['pma-voice']:setPlayerCall(src, channel)
  playerRadioState[src] = { channel = channel, type = 'police' }
  if Config.VoiceComms.militaryRadioClicks then
    exports['pma-voice']:setRadioClicks(src, true)
  end
  TriggerClientEvent('voice:client:radioJoined', src, channel, 'police')
end)

--- Tier 2: CID Encrypted Network
RegisterNetEvent('voice:server:joinCIDChannel', function(channel)
  local src = source
  if not checkRateLimit(src, 'joinChannel') then return end
  local job = getPlayerJobName(src)
  if not job or job ~= Config.VoiceComms.cidJob then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  channel = tonumber(channel)
  if not channel then return end
  exports['pma-voice']:setPlayerCall(src, channel)
  playerRadioState[src] = { channel = channel, type = 'cid' }
  if Config.VoiceComms.cidSilentMode then
    exports['pma-voice']:setRadioClicks(src, false)
  end
  TriggerClientEvent('voice:client:radioJoined', src, channel, 'cid')
end)

RegisterNetEvent('voice:server:leaveChannel', function()
  local src = source
  if not checkRateLimit(src, 'leaveChannel') then return end
  exports['pma-voice']:removePlayerFromCall(src)
  playerRadioState[src] = nil
  TriggerClientEvent('voice:client:radioLeft', src)
end)

--- Phone Speaker Mode
RegisterNetEvent('voice:server:toggleSpeaker', function(targetSrc, enabled)
  local src = source
  if not checkRateLimit(src, 'speakerToggle') then return end
  if enabled then
    exports['pma-voice']:setProximityOverride(targetSrc, Config.VoiceComms.phoneSpeaker.distance)
    playerSpeakerState[src] = targetSrc
  else
    exports['pma-voice']:clearProximityOverride(targetSrc)
    playerSpeakerState[src] = nil
  end
  TriggerClientEvent('voice:client:speakerToggled', src, enabled)
end)

--- Panic Button -> GPS Waypoint for all on channel
RegisterNetEvent('voice:server:panicWaypoint', function(coords)
  local src = source
  if not checkRateLimit(src, 'panicWaypoint') then return end
  local job = getPlayerJobName(src)
  if not job then return end
  TriggerClientEvent('voice:client:panicWaypoint', -1, coords, src)
end)

--- X (Twitter) App
RegisterNetEvent('phone:server:postTweet', function(content, imageUrl)
  local src = source
  local citizenid = Player(src).state.cid
  if not citizenid or not content or content == '' then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
  local tweetId = MySQL.insert.await('INSERT INTO phone_tweets (citizenid, content, image_url) VALUES (?, ?, ?)', {
    citizenid, content, imageUrl or nil
  })
  if tweetId then
    TriggerClientEvent('phone:client:newTweet', -1, {
      id = tweetId,
      citizenid = citizenid,
      name = name,
      content = content,
      image_url = imageUrl,
      likes = 0,
      retweets = 0,
      created_at = os.time()
    })
  end
end)

RegisterNetEvent('phone:server:likeTweet', function(tweetId)
  local src = source
  local citizenid = Player(src).state.cid
  if not citizenid or not tweetId then return end
  local existing = MySQL.single.await('SELECT id FROM phone_tweet_likes WHERE tweet_id = ? AND citizenid = ?', { tweetId, citizenid })
  if existing then
    MySQL.query('DELETE FROM phone_tweet_likes WHERE tweet_id = ? AND citizenid = ?', { tweetId, citizenid })
    MySQL.update('UPDATE phone_tweets SET likes = likes - 1 WHERE id = ?', { tweetId })
    TriggerClientEvent('phone:client:tweetLiked', -1, tweetId, false)
  else
    MySQL.insert('INSERT INTO phone_tweet_likes (tweet_id, citizenid) VALUES (?, ?)', { tweetId, citizenid })
    MySQL.update('UPDATE phone_tweets SET likes = likes + 1 WHERE id = ?', { tweetId })
    TriggerClientEvent('phone:client:tweetLiked', -1, tweetId, true)
  end
end)

RegisterNetEvent('phone:server:retweet', function(tweetId)
  local src = source
  local citizenid = Player(src).state.cid
  if not citizenid or not tweetId then return end
  MySQL.update('UPDATE phone_tweets SET retweets = retweets + 1 WHERE id = ?', { tweetId })
  TriggerClientEvent('phone:client:tweetRetweeted', -1, tweetId)
end)

RegisterNetEvent('phone:server:commentTweet', function(tweetId, content)
  local src = source
  local citizenid = Player(src).state.cid
  if not citizenid or not tweetId or not content then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
  MySQL.insert('INSERT INTO phone_tweet_comments (tweet_id, citizenid, content) VALUES (?, ?, ?)', { tweetId, citizenid, content })
  TriggerClientEvent('phone:client:newComment', -1, tweetId, {
    citizenid = citizenid,
    name = name,
    content = content
  })
end)

QBox.Functions.CreateCallback('phone:server:getTweets', function(source, cb)
  local tweets = MySQL.query.await([[
    SELECT t.*, COALESCE(l.liked, FALSE) as liked
    FROM phone_tweets t
    LEFT JOIN (
      SELECT tweet_id, TRUE as liked FROM phone_tweet_likes WHERE citizenid = ?
    ) l ON t.id = l.tweet_id
    ORDER BY t.created_at DESC LIMIT 50
  ]], { Player(source).state.cid or '' })
  for _, tweet in ipairs(tweets) do
    local player = QBox.Functions.GetPlayerByCitizenId(tweet.citizenid)
    if player then
      tweet.name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    else
      tweet.name = 'Unknown'
    end
    tweet.comments = MySQL.query.await('SELECT * FROM phone_tweet_comments WHERE tweet_id = ? ORDER BY created_at ASC', { tweet.id })
    for _, comment in ipairs(tweet.comments) do
      local commentPlayer = QBox.Functions.GetPlayerByCitizenId(comment.citizenid)
      comment.name = commentPlayer and (commentPlayer.PlayerData.charinfo.firstname .. ' ' .. commentPlayer.PlayerData.charinfo.lastname) or 'Unknown'
    end
  end
  cb(tweets)
end)

--- Black Chat (Encrypted)
RegisterNetEvent('blackchat:server:send', function(roomId, content, coords, selfDestructAfter)
  local src = source
  local citizenid = Player(src).state.cid
  if not citizenid then return end
  local hasItem = exports.ox_inventory:GetItemCount(src, 'crypto_phone', nil, true)
  if not hasItem or hasItem < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need a crypto phone' })
    return
  end
  local msgId = MySQL.insert.await('INSERT INTO blackchat_messages (sender_cid, room_id, content, coords, self_destruct_after) VALUES (?, ?, ?, ?, ?)', {
    citizenid, roomId, content, coords and json.encode(coords) or nil, selfDestructAfter or 0
  })
  TriggerClientEvent('blackchat:client:receive', -1, {
    id = msgId,
    sender_cid = citizenid,
    room_id = roomId,
    content = content,
    coords = coords,
    self_destruct_after = selfDestructAfter,
    created_at = os.time()
  })
  if selfDestructAfter and selfDestructAfter > 0 then
    Citizen.SetTimeout(selfDestructAfter * 1000, function()
      MySQL.query('DELETE FROM blackchat_messages WHERE id = ?', { msgId })
      TriggerClientEvent('blackchat:client:deleteMessage', -1, msgId)
    end)
  end
end)

QBox.Functions.CreateCallback('blackchat:server:getMessages', function(source, cb, roomId)
  local msgs = MySQL.query.await('SELECT * FROM blackchat_messages WHERE room_id = ? ORDER BY created_at ASC LIMIT 100', { roomId })
  cb(msgs)
end)

AddEventHandler('playerDropped', function()
  local src = source
  if playerRadioState[src] then
    exports['pma-voice']:removePlayerFromCall(src)
    playerRadioState[src] = nil
  end
  if playerSpeakerState[src] then
    exports['pma-voice']:clearProximityOverride(src)
    playerSpeakerState[src] = nil
  end
end)
