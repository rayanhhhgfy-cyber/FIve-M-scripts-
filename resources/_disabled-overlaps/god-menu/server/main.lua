local QBCore = exports['qbx_core']:GetCoreObject()
local ownerCache = {}
local ownerCacheReady = false

local function refreshOwnerCache()
    ownerCache = {}
    local rows = MySQL.query.await('SELECT identifier FROM server_owners WHERE group_name = \'god\'')
    if rows then
        for _, r in ipairs(rows) do
            ownerCache[r.identifier] = true
        end
    end
    ownerCacheReady = true
end

local function isOwner(source)
    local ids = GetPlayerIdentifiers(source)

    -- Check Config override first (hardcoded owners always pass)
    local cfgIds = Config.GodMenu.ownerIdentifiers
    if #cfgIds > 0 then
        for _, id in ipairs(ids) do
            for _, oid in ipairs(cfgIds) do
                if id == oid then return true end
            end
        end
    end

    -- Check DB cache
    if not ownerCacheReady then refreshOwnerCache() end
    for _, id in ipairs(ids) do
        if ownerCache[id] then return true end
    end

    return false
end

-- Initialize cache on resource start
AddEventHandler('onResourceStart', function(resName)
    if resName == GetCurrentResourceName() then
        refreshOwnerCache()
    end
end)

-- Auto-assign first player as god owner
AddEventHandler('playerJoining', function()
    local src = source
    if not ownerCacheReady then refreshOwnerCache() end
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM server_owners WHERE group_name = \'god\'')
    if count == 0 then
        local ids = GetPlayerIdentifiers(src)
        if #ids > 0 then
            local steamId = nil
            for _, id in ipairs(ids) do
                if string.find(id, 'steam:') then steamId = id break end
            end
            local ident = steamId or ids[1]
            MySQL.insert('INSERT INTO server_owners (identifier, group_name) VALUES (?, \'god\') ON DUPLICATE KEY UPDATE group_name = \'god\'', { ident })
            ownerCache[ident] = true
            Citizen.SetTimeout(500, function()
                TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'You have been auto-assigned as the God Owner!', duration = 8000 })
            end)
        end
    end
end)

-- Callback for client to check ownership server-side
lib.callback.register('god:server:checkOwner', function(source)
    return isOwner(source)
end)

-- /godowner command: add/remove/list god owners
RegisterCommand('godowner', function(src, args)
    if not isOwner(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
        return
    end
    local sub = (args[1] or ''):lower()
    if sub == 'add' and args[2] then
        local target = QBCore.Functions.GetPlayer(tonumber(args[2]))
        if not target then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
            return
        end
        local targetIds = GetPlayerIdentifiers(target.PlayerData.source)
        local steamId = nil
        for _, id in ipairs(targetIds) do
            if string.find(id, 'steam:') then steamId = id break end
        end
        local ident = steamId or targetIds[1]
        MySQL.insert('INSERT INTO server_owners (identifier, group_name) VALUES (?, \'god\') ON DUPLICATE KEY UPDATE group_name = \'god\'', { ident })
        ownerCache[ident] = true
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Added ' .. GetPlayerName(target.PlayerData.source) .. ' as god owner' })
        TriggerClientEvent('ox_lib:notify', target.PlayerData.source, { type = 'info', description = 'You have been granted god owner access' })
    elseif sub == 'remove' and args[2] then
        local ident = args[2]
        MySQL.execute('DELETE FROM server_owners WHERE identifier = ? AND group_name = \'god\'', { ident })
        ownerCache[ident] = nil
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Removed owner: ' .. ident })
    elseif sub == 'list' then
        local rows = MySQL.query.await('SELECT identifier, granted_at FROM server_owners WHERE group_name = \'god\'')
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'God owners: ' .. json.encode(rows or {}) })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Usage: /godowner add [playerID] | remove [identifier] | list' })
    end
end, false)

lib.callback.register('god:server:getPlayers', function(source)
    if not isOwner(source) then return {} end
    local players = {}
    local all = QBCore.Functions.GetPlayers()
    for _, src in ipairs(all) do
        local p = QBCore.Functions.GetPlayer(src)
        if p then
            players[#players + 1] = {
                id = src,
                name = GetPlayerName(src),
                cid = p.PlayerData.citizenid or 'N/A',
                ping = GetPlayerPing(src),
            }
        end
    end
    return players
end)

RegisterNetEvent('god:server:kickPlayer', function(id, reason)
    if not isOwner(source) then return end
    DropPlayer(id, reason or 'Kicked by owner')
end)

RegisterNetEvent('god:server:banPlayer', function(id, reason)
    if not isOwner(source) then return end
    DropPlayer(id, 'Banned: ' .. (reason or 'Banned by owner'))
end)

RegisterNetEvent('god:server:freezePlayer', function(id, state)
    if not isOwner(source) then return end
    TriggerClientEvent('god:client:freeze', id, state)
end)

RegisterNetEvent('god:server:teleportToMe', function(id)
    if not isOwner(source) then return end
    local coords = GetEntityCoords(GetPlayerPed(source))
    TriggerClientEvent('god:client:teleportTo', id, coords)
end)

RegisterNetEvent('god:server:teleportToPlayer', function(id)
    if not isOwner(source) then return end
    local coords = GetEntityCoords(GetPlayerPed(id))
    TriggerClientEvent('god:client:teleportTo', source, coords)
end)

RegisterNetEvent('god:server:slapPlayer', function(id)
    if not isOwner(source) then return end
    local ped = GetPlayerPed(id)
    local coords = GetEntityCoords(ped)
    local rng = math.random(-20, 20) / 10
    SetEntityCoords(ped, coords.x + rng, coords.y + rng, coords.z + 3.0, false, false, false, false)
    SetEntityVelocity(ped, rng, rng, 5.0)
    QBCore.Functions.Notify(id, 'You got slapped!', 'error')
end)

RegisterNetEvent('god:server:revivePlayer', function(id)
    if not isOwner(source) then return end
    TriggerClientEvent('god:client:revive', id)
end)

RegisterNetEvent('god:server:healPlayer', function(id)
    if not isOwner(source) then return end
    TriggerClientEvent('god:client:heal', id)
end)

RegisterNetEvent('god:server:giveArmor', function(id, amount)
    if not isOwner(source) then return end
    TriggerClientEvent('god:client:setArmor', id, amount or 100)
end)

RegisterNetEvent('god:server:giveMoney', function(id, amount, mtype)
    if not isOwner(source) then return end
    local p = QBCore.Functions.GetPlayer(id)
    if not p then return end
    if mtype == 'cash' then
        p.Functions.AddMoney('cash', amount)
    elseif mtype == 'bank' then
        p.Functions.AddMoney('bank', amount)
    end
end)

RegisterNetEvent('god:server:giveItem', function(id, item, count)
    if not isOwner(source) then return end
    local p = QBCore.Functions.GetPlayer(id)
    if not p then return end
    p.Functions.AddItem(item, count or 1)
end)