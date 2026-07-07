local QBox = exports['qbx_core']:GetCoreObject()
local adminCache = {}
local dbOwners = {}

local function getSteamIdentifier(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.find(id, 'steam:') then return id end
    end
    return nil
end

local function isOwner(identifier)
    if not identifier then return false end
    for _, ownerId in ipairs(Config.AdminCommander.ownerIdentifiers) do
        if identifier == ownerId then return true end
    end
    for _, dbOwner in ipairs(dbOwners) do
        if dbOwner.identifier == identifier then return true end
    end
    return false
end

local function loadOwnersFromDB()
    local owners = MySQL.query.await('SELECT identifier, group_name FROM server_owners')
    dbOwners = owners or {}
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        loadOwnersFromDB()
    end
end)

if GetResourceState('oxmysql') ~= 'started' then
    local tries = 0
    local timer = SetTimer(function()
        tries = tries + 1
        if GetResourceState('oxmysql') == 'started' or tries > 50 then
            loadOwnersFromDB()
            ClearTimer(timer)
        end
    end, 100, 0)
end

MySQL.ready(function()
    loadOwnersFromDB()
end)

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.AdminCommander.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

local function logAction(adminCID, action, target)
    if Config.AdminCommander.logAllActions then
        MySQL.insert('INSERT INTO admin_logs (admin_cid, action, target) VALUES (?, ?, ?)', { adminCID, action, target or 'none' })
    end
end

--- Open admin menu
RegisterNetEvent('admin:openMenu', function()
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:showMenu', src)
end)

--- Give item to player
RegisterNetEvent('admin:giveItem', function(targetSrc, itemName, count)
    local src = source
    if not isAdmin(src) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    if target.Functions.AddItem(itemName, count or 1) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave ' .. (count or 1) .. 'x ' .. itemName .. ' to ' .. target.PlayerData.charinfo.firstname })
        logAction(player.PlayerData.citizenid, 'giveitem', target.PlayerData.citizenid .. ':' .. itemName .. ':' .. (count or 1))
    end
end)

--- Give vehicle
RegisterNetEvent('admin:giveVehicle', function(targetSrc, vehicleModel)
    local src = source
    if not isAdmin(src) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    TriggerClientEvent('admin:spawnVehicle', targetSrc, vehicleModel)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Spawned ' .. vehicleModel .. ' for ' .. target.PlayerData.charinfo.firstname })
    logAction(player.PlayerData.citizenid, 'givevehicle', target.PlayerData.citizenid .. ':' .. vehicleModel)
end)

--- Spawn vehicle for self
RegisterNetEvent('admin:spawnVehicle', function(vehicleModel)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:spawnVehicle', src, vehicleModel)
    -- Log vehicle spawn for CID vehicle spawn tracker
    local p = QBox.Functions.GetPlayer(src)
    if p then
        local label = vehicleModel
        for _, v in ipairs(Config.AdminCommander.quickVehicles) do
            if v.model == vehicleModel then label = v.label; break end
        end
        MySQL.insert('INSERT INTO vehicle_spawn_log (spawner_cid, spawner_name, vehicle_model, vehicle_label) VALUES (?, ?, ?, ?)', {
            p.PlayerData.citizenid, p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname, vehicleModel, label
        })
    end
end)

--- Kick player
RegisterNetEvent('admin:kickPlayer', function(targetSrc, reason)
    local src = source
    if not isAdmin(src) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    logAction(player.PlayerData.citizenid, 'kick', target.PlayerData.citizenid .. ':' .. (reason or 'no reason'))
    DropPlayer(targetSrc, 'Kicked by admin: ' .. (reason or 'No reason given'))
end)

--- Freeze player
RegisterNetEvent('admin:freezePlayer', function(targetSrc)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:toggleFreeze', targetSrc)
end)

--- Teleport to player
RegisterNetEvent('admin:gotoPlayer', function(targetSrc)
    local src = source
    if not isAdmin(src) then return end
    local targetPed = GetPlayerPed(targetSrc)
    local coords = GetEntityCoords(targetPed)
    TriggerClientEvent('admin:teleportTo', src, coords)
end)

--- Bring player
RegisterNetEvent('admin:bringPlayer', function(targetSrc)
    local src = source
    if not isAdmin(src) then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    TriggerClientEvent('admin:teleportTo', targetSrc, coords)
end)

--- Get online players for admin menu
QBox.Functions.CreateCallback('admin:getPlayers', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    local players = {}
    local activePlayers = QBox.Functions.GetPlayers()
    for _, src in ipairs(activePlayers) do
        local player = QBox.Functions.GetPlayer(src)
        if player then
            table.insert(players, {
                src = src,
                citizenid = player.PlayerData.citizenid,
                name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                job = player.PlayerData.job.name,
                grade = player.PlayerData.job.grade.level,
            })
        end
    end
    cb(players)
end)

--- Admin commands
QBox.Commands.Add('admin', 'Open admin menu', {}, false, function(source)
    TriggerEvent('admin:openMenu', source)
end)

QBox.Commands.Add('kick', 'Kick player', {}, false, function(source, args)
    local targetSrc = tonumber(args[1])
    local reason = table.concat(args, ' ', 2)
    TriggerEvent('admin:kickPlayer', targetSrc, reason)
end)

QBox.Commands.Add('freeze', 'Freeze/unfreeze player', {}, false, function(source, args)
    local targetSrc = tonumber(args[1])
    TriggerEvent('admin:freezePlayer', targetSrc)
end)

QBox.Commands.Add('goto', 'Teleport to player', {}, false, function(source, args)
    local targetSrc = tonumber(args[1])
    TriggerEvent('admin:gotoPlayer', targetSrc)
end)

QBox.Commands.Add('bring', 'Bring player to you', {}, false, function(source, args)
    local targetSrc = tonumber(args[1])
    TriggerEvent('admin:bringPlayer', targetSrc)
end)

QBox.Commands.Add('givemoney', 'Give player money', {}, false, function(source, args)
    local src = source
    if not isAdmin(src) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local targetSrc = tonumber(args[1])
    local amount = tonumber(args[2])
    local moneyType = args[3] or 'cash'
    if not targetSrc or not amount then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    target.Functions.AddMoney(moneyType, amount)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave $' .. amount .. ' to ' .. target.PlayerData.charinfo.firstname })
    logAction(player.PlayerData.citizenid, 'givemoney', target.PlayerData.citizenid .. ':' .. amount .. ':' .. moneyType)
end)

QBox.Commands.Add('setjob', 'Set player job', {}, false, function(source, args)
    local src = source
    if not isAdmin(src) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local targetSrc = tonumber(args[1])
    local jobName = args[2]
    local grade = tonumber(args[3]) or 0
    if not targetSrc or not jobName then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    target.Functions.SetJob(jobName, grade)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Set job to ' .. jobName .. ' grade ' .. grade })
    logAction(player.PlayerData.citizenid, 'setjob', target.PlayerData.citizenid .. ':' .. jobName .. ':' .. grade)
end)

QBox.Commands.Add('setgroup', 'Set player admin group', {}, false, function(source, args)
    local src = source
    if not isAdmin(src) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local targetSrc = tonumber(args[1])
    local group = args[2]
    if not targetSrc or not group then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    target.Functions.SetGroup(group)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Set group to ' .. group })
    logAction(player.PlayerData.citizenid, 'setgroup', target.PlayerData.citizenid .. ':' .. group)
end)

--- Noclip
RegisterNetEvent('admin:toggleNoclip', function()
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:noclip', src)
end)

QBox.Commands.Add('noclip', 'Toggle noclip', {}, false, function(source)
    TriggerEvent('admin:toggleNoclip', source)
end)

QBox.Commands.Add('car', 'Spawn a vehicle', {}, false, function(source, args)
    local src = source
    if not isAdmin(src) then return end
    local vehicleModel = args[1]
    if not vehicleModel then return end
    TriggerEvent('admin:spawnVehicle', vehicleModel)
end)

--- Give car to player's garage
RegisterNetEvent('admin:giveCarToGarage', function(targetSrc, vehicleModel)
    local src = source
    if not isAdmin(src) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    local citizenId = target.PlayerData.citizenid
    local plate = 'ADM' .. math.random(10000, 99999)
    local hash = GetHashKey(vehicleModel)
    local success, result = pcall(function()
        return exports['Renewed-Garages']:AddVehicle(citizenId, {
            plate = plate,
            vehicle = vehicleModel,
            hash = hash,
        })
    end)
    if success then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave ' .. vehicleModel .. ' (' .. plate .. ') to ' .. target.PlayerData.charinfo.firstname .. '\'s garage' })
        TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'success', description = 'Admin gave you a ' .. vehicleModel .. ' (' .. plate .. ') — check your garage' })
        logAction(player.PlayerData.citizenid, 'givecar', target.PlayerData.citizenid .. ':' .. vehicleModel .. ':' .. plate)
        if exports['vehicle-keys'] then
            exports['vehicle-keys']:GiveKeyToPlayer(targetSrc, plate, vehicleModel)
        end
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Failed to add vehicle: ' .. tostring(result) })
    end
end)

QBox.Commands.Add('givecar', 'Give a car to player\'s garage', {}, false, function(source, args)
    local src = source
    if not isAdmin(src) then return end
    local targetSrc = tonumber(args[1])
    local vehicleModel = args[2]
    if not targetSrc or not vehicleModel then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Usage: /givecar [player_id] [model]' })
        return
    end
    TriggerEvent('admin:giveCarToGarage', targetSrc, vehicleModel)
end)

--- Transfer vehicle ownership
RegisterNetEvent('admin:transferVehicle', function(plate, newOwnerSrc)
    local src = source
    if not isAdmin(src) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local target = QBox.Functions.GetPlayer(newOwnerSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'New owner not found' })
        return
    end
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicle then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Vehicle not found with plate: ' .. plate })
        return
    end
    local oldOwner = vehicle.citizenid
    MySQL.update.await('UPDATE player_vehicles SET citizenid = ? WHERE plate = ?', { target.PlayerData.citizenid, plate })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Transferred ' .. vehicle.vehicle .. ' (' .. plate .. ') to ' .. target.PlayerData.charinfo.firstname })
    TriggerClientEvent('ox_lib:notify', newOwnerSrc, { type = 'success', description = 'Admin transferred ' .. vehicle.vehicle .. ' (' .. plate .. ') to your garage' })
    logAction(player.PlayerData.citizenid, 'transfervehicle', vehicle.vehicle .. ':' .. plate .. ':from:' .. oldOwner .. ':to:' .. target.PlayerData.citizenid)
end)

QBox.Commands.Add('transfervehicle', 'Transfer vehicle ownership to another player', {}, false, function(source, args)
    local src = source
    if not isAdmin(src) then return end
    local plate = args[1]
    local newOwnerSrc = tonumber(args[2])
    if not plate or not newOwnerSrc then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Usage: /transfervehicle [plate] [new_owner_id]' })
        return
    end
    TriggerEvent('admin:transferVehicle', plate, newOwnerSrc)
end)

QBox.Commands.Add('coords', 'Print your current coords', {}, false, function(source)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:printCoords', src)
end)

--- Spectate player
RegisterNetEvent('admin:spectate', function(targetSrc)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:startSpectate', src, targetSrc)
end)

QBox.Commands.Add('spectate', 'Spectate a player', {}, false, function(source, args)
    local targetSrc = tonumber(args[1])
    if targetSrc then TriggerEvent('admin:spectate', targetSrc) end
end)

QBox.Commands.Add('unspectate', 'Stop spectating', {}, false, function(source)
    TriggerClientEvent('admin:stopSpectate', source)
end)

--- Vanish
RegisterNetEvent('admin:vanish', function()
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:toggleVanish', src)
end)

QBox.Commands.Add('vanish', 'Toggle invisible', {}, false, function(source)
    TriggerEvent('admin:vanish', source)
end)

--- Admin log viewer
QBox.Commands.Add('adminlogs', 'View admin logs for a player', {}, false, function(source, args)
    local src = source
    if not isAdmin(src) then return end
    local cid = args[1]
    if not cid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Usage: /adminlogs [citizenid]' })
        return
    end
    local rows = MySQL.query.await('SELECT action, target, created_at FROM admin_logs WHERE admin_cid = ? ORDER BY created_at DESC LIMIT 20', { cid })
    TriggerClientEvent('admin:showLogs', src, cid, rows or {})
end)

QBox.Commands.Add('adminlogstats', 'View admin log statistics', {}, false, function(source)
    local src = source
    if not isAdmin(src) then return end
    local rows = MySQL.query.await('SELECT admin_cid, COUNT(*) as count FROM admin_logs GROUP BY admin_cid ORDER BY count DESC LIMIT 10')
    TriggerClientEvent('admin:showLogStats', src, rows or {})
end)

--- Auto-admin — DB-backed owner persistence
AddEventHandler('playerJoining', function()
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local identifier = getSteamIdentifier(src)
    if not identifier then return end

    -- Check config owners first
    for _, ownerId in ipairs(Config.AdminCommander.ownerIdentifiers) do
        if identifier == ownerId then
            p.Functions.SetGroup('god')
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Welcome, Server Owner (god admin)' })
            return
        end
    end

    -- Check DB owners
    for _, dbOwner in ipairs(dbOwners) do
        if dbOwner.identifier == identifier then
            p.Functions.SetGroup(dbOwner.group_name or 'god')
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Welcome back, Server Owner (god admin)' })
            return
        end
    end

    -- No owners exist at all (config empty + DB empty) → first player becomes permanent owner
    if #Config.AdminCommander.ownerIdentifiers == 0 and #dbOwners == 0 then
        p.Functions.SetGroup('god')
        MySQL.insert('INSERT INTO server_owners (identifier, group_name) VALUES (?, ?)', { identifier, 'god' })
        loadOwnersFromDB()
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'You are the first player — permanently saved as god admin owner!' })
    end
end)

--- Make another player admin
RegisterNetEvent('admin:setAdmin', function(targetSrc, rank)
    local src = source
    if not isAdmin(src) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local pIdentifier = getSteamIdentifier(src)
    local allowed = false
    for _, g in ipairs(Config.AdminCommander.adminRanks) do
        if p.PlayerData.group == g then
            if g == 'god' or g == 'superadmin' then allowed = true end
            break
        end
    end
    if not allowed then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only god/superadmin can promote others' })
        return
    end
    -- Restrict god promotion to owners only
    if rank == 'god' and not isOwner(pIdentifier) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only saved server owners can promote to god rank' })
        return
    end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    target.Functions.SetGroup(rank or 'admin')
    logAction(p.PlayerData.citizenid, 'setadmin', target.PlayerData.citizenid .. ':' .. (rank or 'admin'))
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = target.PlayerData.charinfo.firstname .. ' promoted to ' .. (rank or 'admin') })
    TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'success', description = 'You were promoted to ' .. (rank or 'admin') .. ' by ' .. p.PlayerData.charinfo.firstname })
end)

--- /addowner — permanently add a player as god owner in DB (config owner only)
QBox.Commands.Add('addowner', 'Permanently add a player as server owner', {}, false, function(source, args)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local pIdentifier = getSteamIdentifier(src)
    if not isOwner(pIdentifier) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only server owners can add new owners' })
        return
    end
    local targetSrc = tonumber(args[1])
    if not targetSrc then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Usage: /addowner [server_id]' })
        return
    end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    local targetIdentifier = getSteamIdentifier(targetSrc)
    if not targetIdentifier then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Target has no Steam identifier' })
        return
    end
    if isOwner(targetIdentifier) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player is already an owner' })
        return
    end
    MySQL.insert('INSERT INTO server_owners (identifier, group_name) VALUES (?, ?)', { targetIdentifier, 'god' })
    loadOwnersFromDB()
    target.Functions.SetGroup('god')
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = target.PlayerData.charinfo.firstname .. ' added as permanent server owner' })
    TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'success', description = 'You have been added as a permanent server owner' })
    logAction(p.PlayerData.citizenid, 'addowner', target.PlayerData.citizenid)
end)

--- /removeowner — remove a player from server owners (config owner only)
QBox.Commands.Add('removeowner', 'Remove a player from server owners', {}, false, function(source, args)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local pIdentifier = getSteamIdentifier(src)
    if not isOwner(pIdentifier) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only server owners can remove owners' })
        return
    end
    local targetSrc = tonumber(args[1])
    if not targetSrc then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Usage: /removeowner [server_id]' })
        return
    end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    local targetIdentifier = getSteamIdentifier(targetSrc)
    if not targetIdentifier then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Target has no Steam identifier' })
        return
    end
    MySQL.query('DELETE FROM server_owners WHERE identifier = ?', { targetIdentifier })
    loadOwnersFromDB()
    target.Functions.SetGroup('superadmin')
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = target.PlayerData.charinfo.firstname .. ' removed from server owners' })
    TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'warning', description = 'You have been removed from server owners, demoted to superadmin' })
    logAction(p.PlayerData.citizenid, 'removeowner', target.PlayerData.citizenid)
end)

--- /listowners — list all saved server owners
QBox.Commands.Add('listowners', 'List all saved server owners', {}, false, function(source)
    local src = source
    if not isAdmin(src) then return end
    local rows = MySQL.query.await('SELECT identifier, group_name, granted_at FROM server_owners')
    if not rows or #rows == 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'No server owners saved in DB' })
        return
    end
    local msg = 'Server Owners:\n'
    for _, r in ipairs(rows) do
        msg = msg .. r.identifier .. ' (' .. r.group_name .. ') - ' .. tostring(r.granted_at) .. '\n'
    end
    TriggerClientEvent('chat:addMessage', src, { args = { 'OWNERS', msg } })
end)

--- Full admin dashboard (admindash2)
RegisterNetEvent('admin:dashboard', function()
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:showDashboard', src)
end)

QBox.Commands.Add('admindash2', 'Full admin dashboard', {}, false, function(source)
    TriggerEvent('admin:dashboard', source)
end)

--- Dashboard sub-actions
RegisterNetEvent('admin:dashAnnounce', function(msg)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('chat:addMessage', -1, { args = { 'SERVER ANNOUNCEMENT: ' .. msg }, color = { 255, 200, 0 } })
end)

RegisterNetEvent('admin:dashWeather', function(weather)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:setWeather', -1, weather)
end)

RegisterNetEvent('admin:dashTime', function(hour)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:setTime', -1, hour)
end)

RegisterNetEvent('admin:dashClearArea', function()
    local src = source
    if not isAdmin(src) then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    ClearAreaOfEverything(coords.x, coords.y, coords.z, 100.0, false, false, false, false)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Area cleared (100m radius)' })
end)

RegisterNetEvent('admin:dashRevive', function(targetSrc)
    local src = source
    if not isAdmin(src) then return end
    local target = targetSrc or src
    TriggerClientEvent('hospital:client:Revive', target)
    local p = QBox.Functions.GetPlayer(src)
    if p then logAction(p.PlayerData.citizenid, 'revive', target == src and 'self' or 'player:' .. target) end
end)

RegisterNetEvent('admin:dashSlap', function(targetSrc)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:slapPlayer', targetSrc)
end)

RegisterNetEvent('admin:dashGiveAllItems', function(itemName, count)
    local src = source
    if not isAdmin(src) then return end
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local p = QBox.Functions.GetPlayer(s)
        if p then p.Functions.AddItem(itemName, count or 1) end
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave ' .. (count or 1) .. 'x ' .. itemName .. ' to all players' })
end)

QBox.Functions.CreateCallback('admin:dashPlayerCount', function(source, cb)
    cb(#QBox.Functions.GetPlayers())
end)

QBox.Functions.CreateCallback('admin:dashServerInfo', function(source, cb)
    local players = QBox.Functions.GetPlayers()
    local pCount = #players
    local adminCount = 0
    for _, s in ipairs(players) do
        local p = QBox.Functions.GetPlayer(s)
        if p then
            for _, g in ipairs(Config.AdminCommander.adminGroups) do
                if p.PlayerData.group == g then adminCount = adminCount + 1; break end
            end
        end
    end
    cb({ players = pCount, admins = adminCount, maxPlayers = Config.AdminCommander.server.maxPlayers })
end)
