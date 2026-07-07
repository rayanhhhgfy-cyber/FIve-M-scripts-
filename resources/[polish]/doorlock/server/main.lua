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

local doorStates = {}

CreateThread(function()
    local results = MySQL.query('SELECT * FROM doors')
    if results then
        for _, row in ipairs(results) do
            doorStates[row.id] = row.locked == 1
        end
    end
end)

RegisterNetEvent('doorlock:toggle', function(doorId)
    local src = source
    if not checkRateLimit(src, 'toggle', 10) then return end
    local door = nil
    for _, d in ipairs(Config.Doorlock.doors) do
        if d.id == doorId then door = d end
    end
    if not door then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local hasAccess = false
    if door.groups then
        for _, g in ipairs(door.groups) do
            if player.PlayerData.job.name == g and player.PlayerData.job.grade.level >= (door.jobLevel or 0) then
                hasAccess = true
            end
        end
    end
    if not hasAccess then return Wrappers.Notify(src, Locale('doorlock.no_access'), 'error') end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    if #(coords - door.coords) > Config.Doorlock.maxDistance then return Wrappers.Notify(src, Locale('doorlock.too_far'), 'error') end
    doorStates[doorId] = not doorStates[doorId]
    MySQL.update('INSERT INTO doors (id, locked) VALUES (?, ?) ON DUPLICATE KEY UPDATE locked = VALUES(locked)', { doorId, doorStates[doorId] and 1 or 0 })
    TriggerClientEvent('doorlock:sync', -1, doorId, doorStates[doorId])
    Wrappers.Notify(src, doorStates[doorId] and Locale('doorlock.locked') or Locale('doorlock.unlocked'), 'info')
end)

RegisterNetEvent('doorlock:adminToggle', function(doorId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local isAdmin = false
    for _, g in ipairs(Config.Admin.groups) do
        if player.PlayerData.group == g then isAdmin = true end
    end
    if not isAdmin then return end
    doorStates[doorId] = not doorStates[doorId]
    TriggerClientEvent('doorlock:sync', -1, doorId, doorStates[doorId])
end)

QBox.Commands.Add('doorlock', 'Toggle nearest door', {}, false, function(source)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local nearest = nil
    local nearestDist = Config.Doorlock.maxDistance
    for _, d in ipairs(Config.Doorlock.doors) do
        local dist = #(coords - d.coords)
        if dist < nearestDist then
            nearestDist = dist
            nearest = d.id
        end
    end
    if nearest then
        TriggerEvent('doorlock:toggle', nearest)
    end
end)
