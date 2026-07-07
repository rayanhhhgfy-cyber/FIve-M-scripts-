local QBox = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}
local playerData = {}
local strikeCount = {}
local godMenuLoaded = false

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

local function notifyAdmins(title, message, color)
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local player = QBox.Functions.GetPlayer(src)
        if player then
            local group = player.PlayerData.job and player.PlayerData.job.name or ''
            if group == 'police' or group == 'fib' or group == 'admin' then
                TriggerClientEvent('ox_lib:notify', src, {
                    type = 'warning',
                    description = '[ANTICHEAT] ' .. message,
                    duration = 10000,
                })
            end
        end
    end
end

local function addStrike(src, reason)
    strikeCount[src] = (strikeCount[src] or 0) + 1
    local strikes = strikeCount[src]
    local playerName = GetPlayerName(src)
    local identifiers = GetPlayerIdentifiers(src)
    local player = QBox.Functions.GetPlayer(src)

    notifyAdmins('Strike ' .. strikes .. '/' .. Config.Anticheat.maxStrikes, playerName .. ' - ' .. reason, 16753920)
    pcall(function()
        exports['discord-logs']:LogCustom({
            title = 'Anticheat Strike ' .. strikes .. '/' .. Config.Anticheat.maxStrikes,
            description = playerName .. ' (' .. (identifiers[1] or 'unknown') .. '): ' .. reason,
            color = 16753920,
        })
    end)
    pcall(function()
        MySQL.insert('INSERT INTO admin_logs (admin_cid, target_cid, action, reason, created_at) VALUES (?, ?, ?, ?, NOW())', {
            'SYSTEM', (player and player.PlayerData.citizenid or src), 'anticheat_strike', playerName .. ': ' .. reason,
        })
    end)

    if strikes >= Config.Anticheat.maxStrikes then
        notifyAdmins('Auto-Ban', playerName .. ' banned after ' .. strikes .. ' anticheat strikes.', 15158332)
        pcall(function()
            exports['discord-logs']:LogCustom({
                title = 'Anticheat Auto-Ban',
                description = playerName .. ' (' .. (identifiers[1] or 'unknown') .. ') auto-banned after ' .. strikes .. ' strikes.',
                color = 15158332,
            })
        end)
        DropPlayer(src, 'Banned: Cheating detected. Appeal at our Discord.')
    end
end

CreateThread(function()
    while true do
        Wait(Config.Anticheat.detectionInterval)
        local players = QBox.Functions.GetPlayers()
        for _, src in ipairs(players) do
            local player = QBox.Functions.GetPlayer(src)
            if player then
                local data = playerData[src] or {}
                local health = GetPlayerHealth(src)
                local armour = GetPlayerArmour(src)
                local coords = GetEntityCoords(GetPlayerPed(src))
                local ped = GetPlayerPed(src)

                if data.lastHealth and math.abs(health - data.lastHealth) > Config.Anticheat.maxHealthChanges then
                    addStrike(src, 'Suspicious health change: +' .. (health - data.lastHealth))
                end
                if data.lastArmour and math.abs(armour - data.lastArmour) > Config.Anticheat.maxArmourChanges then
                    addStrike(src, 'Suspicious armour change: +' .. (armour - data.lastArmour))
                end
                if data.lastCoords and data.lastCoords.x then
                    local dist = #(coords - data.lastCoords)
                    if dist > Config.Anticheat.maxTeleportDistance then
                        addStrike(src, 'Suspicious teleport: ' .. math.floor(dist) .. 'm')
                    end
                end

                local _, weapon = GetCurrentPedWeapon(ped, true)
                for _, banned in ipairs(Config.Anticheat.weaponBlacklist) do
                    if weapon == GetHashKey(banned) then
                        addStrike(src, 'Blacklisted weapon: ' .. banned)
                        RemoveWeaponFromPed(ped, GetHashKey(banned))
                    end
                end

                local speed = GetEntitySpeed(ped) * 3.6
                if speed > Config.Anticheat.maxVelocity then
                    addStrike(src, 'Suspicious velocity: ' .. math.floor(speed) .. ' km/h')
                end

                playerData[src] = { lastHealth = health, lastArmour = armour, lastCoords = coords }
            end
        end
    end
end)

RegisterNetEvent('anticheat:report', function(reason)
    local src = source
    if not checkRateLimit(src, 'report', 5) then return end
    if type(reason) ~= 'string' then return end
    addStrike(src, reason)
end)

AddEventHandler('playerDropped', function()
    local src = source
    playerData[src] = nil
    strikeCount[src] = nil
end)
