local QBox = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

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

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, group in ipairs(Config.Admin.groups) do
        if player.PlayerData.group == group then return true end
    end
    return false
end

local function logAction(src, action, target)
    local player = QBox.Functions.GetPlayer(src)
    local name = player and player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname or 'Unknown'
    local targetName = 'N/A'
    if target then
        local tp = QBox.Functions.GetPlayer(target)
        targetName = tp and tp.PlayerData.charinfo.firstname .. ' ' .. tp.PlayerData.charinfo.lastname or tostring(target)
    end
    exports['discord-logs']:LogCustom({
        title = 'Admin Action',
        description = name .. ' (' .. src .. ') performed ' .. action .. ' on ' .. targetName,
        color = 15158332,
        fields = {},
    })
end

RegisterNetEvent('admin:noclip', function()
    local src = source
    if not isAdmin(src) then return Wrappers.Notify(src, Locale('admin_menu.no_perm'), 'error') end
    if not checkRateLimit(src, 'noclip', 60) then return end
    TriggerClientEvent('admin:toggleNoclip', src)
    logAction(src, 'noclip')
end)

RegisterNetEvent('admin:godmode', function()
    local src = source
    if not isAdmin(src) then return Wrappers.Notify(src, Locale('admin_menu.no_perm'), 'error') end
    if not checkRateLimit(src, 'godmode', 60) then return end
    TriggerClientEvent('admin:toggleGodmode', src)
    logAction(src, 'godmode')
end)

RegisterNetEvent('admin:invisible', function()
    local src = source
    if not isAdmin(src) then return Wrappers.Notify(src, Locale('admin_menu.no_perm'), 'error') end
    if not checkRateLimit(src, 'invisible', 60) then return end
    TriggerClientEvent('admin:toggleInvisible', src)
    logAction(src, 'invisible')
end)

RegisterNetEvent('admin:freeze', function(target)
    local src = source
    if not isAdmin(src) then return Wrappers.Notify(src, Locale('admin_menu.no_perm'), 'error') end
    if not checkRateLimit(src, 'freeze', 60) then return end
    target = tonumber(target)
    if not target or not QBox.Functions.GetPlayer(target) then return Wrappers.Notify(src, Locale('admin_menu.player_offline'), 'error') end
    TriggerClientEvent('admin:toggleFreeze', target)
    logAction(src, 'freeze', target)
end)

RegisterNetEvent('admin:revive', function(target)
    local src = source
    if not isAdmin(src) then return Wrappers.Notify(src, Locale('admin_menu.no_perm'), 'error') end
    if not checkRateLimit(src, 'revive', 60) then return end
    target = tonumber(target) or src
    if not QBox.Functions.GetPlayer(target) then return Wrappers.Notify(src, Locale('admin_menu.player_offline'), 'error') end
    TriggerClientEvent('admin:revivePlayer', target)
    logAction(src, 'revive', target)
end)

RegisterNetEvent('admin:teleport', function(coords)
    local src = source
    if not isAdmin(src) then return Wrappers.Notify(src, Locale('admin_menu.no_perm'), 'error') end
    if not checkRateLimit(src, 'teleport', 30) then return end
    if type(coords) ~= 'table' or not coords.x then return end
    TriggerClientEvent('admin:teleportTo', src, coords)
    logAction(src, 'teleport')
end)

RegisterNetEvent('admin:spawnVehicle', function(model)
    local src = source
    if not isAdmin(src) then return Wrappers.Notify(src, Locale('admin_menu.no_perm'), 'error') end
    if not checkRateLimit(src, 'spawnVehicle', 30) then return end
    if type(model) ~= 'string' then return end
    TriggerClientEvent('admin:spawnVehicle', src, model)
    logAction(src, 'spawnVehicle')
end)

RegisterNetEvent('admin:ban', function(data)
    local src = source
    if not isAdmin(src) then return Wrappers.Notify(src, Locale('admin_menu.no_perm'), 'error') end
    if not checkRateLimit(src, 'ban', 10) then return end
    if type(data) ~= 'table' then return end
    local target, reason = tonumber(data.target), data.reason or 'No reason'
    if not target or not QBox.Functions.GetPlayer(target) then return Wrappers.Notify(src, Locale('admin_menu.player_offline'), 'error') end
    if string.len(reason) > 256 then reason = reason:sub(1, 256) end
    local tp = QBox.Functions.GetPlayer(target)
    local identifier = tp and tp.PlayerData.citizenid or ''
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, banner, time) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(target), identifier, '', '', reason, GetPlayerName(src), os.time() * 1000
    })
    TriggerClientEvent('admin:banned', target, reason)
    DropPlayer(target, 'Banned: ' .. reason)
    logAction(src, 'ban', target)
end)

RegisterNetEvent('admin:kick', function(data)
    local src = source
    if not isAdmin(src) then return Wrappers.Notify(src, Locale('admin_menu.no_perm'), 'error') end
    if not checkRateLimit(src, 'kick', 20) then return end
    if type(data) ~= 'table' then return end
    local target, reason = tonumber(data.target), data.reason or 'No reason'
    if not target or not QBox.Functions.GetPlayer(target) then return Wrappers.Notify(src, Locale('admin_menu.player_offline'), 'error') end
    if string.len(reason) > 256 then reason = reason:sub(1, 256) end
    DropPlayer(target, 'Kicked: ' .. reason)
    logAction(src, 'kick', target)
end)

QBox.Commands.Add('admin', 'Open admin menu', {}, false, function(source)
    if not isAdmin(source) then return Wrappers.Notify(source, Locale('admin_menu.no_perm'), 'error') end
    TriggerClientEvent('admin:openMenu', source)
end)
