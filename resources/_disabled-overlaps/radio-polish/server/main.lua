local QBCore = exports['qbx_core']:GetCoreObject()
local RATE_LIMITS = {}
local radioChannels = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    if not RATE_LIMITS[key] then
        RATE_LIMITS[key] = { count = 1, start = now }
        return true
    end
    if now - RATE_LIMITS[key].start >= 60 then
        RATE_LIMITS[key] = { count = 1, start = now }
        return true
    end
    if RATE_LIMITS[key].count >= maxPerMin then
        return false
    end
    RATE_LIMITS[key].count = RATE_LIMITS[key].count + 1
    return true
end

local function Notify(src, msg, type)
    TriggerClientEvent('ox_lib:notify', src, { type = type or 'info', description = msg })
end

local function hasChannelAccess(player, channel)
    local groups = player.PlayerData.job.name
    for _, restricted in ipairs(Config.Radio.restrictedChannels) do
        if restricted.channel == channel then
            for j = 1, #restricted.groups do
                if groups == restricted.groups[j] then
                    return true
                end
            end
            return false
        end
    end
    return true
end

local function setVoiceChannel(src, channel)
    if channel and channel > 0 then
        exports['pma-voice']:setPlayerCall(src, channel)
        radioChannels[src] = channel
    else
        exports['pma-voice']:removePlayerFromCall(src)
        radioChannels[src] = nil
    end
end

RegisterNetEvent('radio:join', function(channel)
    local src = source
    if not src or not channel then return end
    if not checkRateLimit(src, 'join', 3) then return end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    channel = math.floor(tonumber(channel))
    if channel < 1 or channel > Config.Radio.maxChannels then return Notify(src, Locale('radio.restricted'), 'error') end
    if not hasChannelAccess(player, channel) then return Notify(src, Locale('radio.no_access'), 'error') end
    setVoiceChannel(src, channel)
    Notify(src, Locale('radio.joined') .. ' ' .. channel, 'success')
end)

RegisterNetEvent('radio:leave', function()
    local src = source
    if not src then return end
    if not checkRateLimit(src, 'leave', 3) then return end
    setVoiceChannel(src, nil)
    Notify(src, Locale('radio.left'), 'info')
end)

RegisterNetEvent('radio:cycleChannel', function(direction)
    local src = source
    if not src or not direction then return end
    if not checkRateLimit(src, 'cycle', 3) then return end
    local current = radioChannels[src] or 0
    local newChannel
    if direction == 'up' then
        newChannel = current + 1
        if newChannel > Config.Radio.maxChannels then newChannel = 1 end
    else
        newChannel = current - 1
        if newChannel < 1 then newChannel = Config.Radio.maxChannels end
    end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    if not hasChannelAccess(player, newChannel) then return Notify(src, Locale('radio.no_access'), 'error') end
    setVoiceChannel(src, newChannel)
    Notify(src, Locale('radio.joined') .. ' ' .. newChannel, 'success')
end)

RegisterNetEvent('radio:setChannel', function(channel)
    local src = source
    if not src or not channel then return end
    if not checkRateLimit(src, 'setChannel', 3) then return end
    channel = math.floor(tonumber(channel))
    if channel < 1 or channel > Config.Radio.maxChannels then return end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    if not hasChannelAccess(player, channel) then return Notify(src, Locale('radio.no_access'), 'error') end
    setVoiceChannel(src, channel)
    Notify(src, Locale('radio.joined') .. ' ' .. channel, 'success')
end)

AddEventHandler('playerDropped', function()
    local src = source
    if radioChannels[src] then
        setVoiceChannel(src, nil)
    end
end)
