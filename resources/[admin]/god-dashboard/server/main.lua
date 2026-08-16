local QBox = exports['qbx_core']:GetCoreObject()

local function isOwner(identifier)
    if not identifier then return false end
    local res = MySQL.scalar.await('SELECT id FROM server_owners WHERE identifier = ? LIMIT 1', { identifier })
    return res ~= nil
end

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end

    if isOwner(player.PlayerData.license) or isOwner(player.PlayerData.citizenid) then
        return true
    end

    for _, g in ipairs(Config.GodDashboard.adminGroups or { 'admin', 'superadmin', 'god' }) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

local function logAdminAction(src, action, target)
    local p = QBox.Functions.GetPlayer(src)
    local adminCid = p and p.PlayerData.citizenid or 'console'
    local targetCid = 'none'
    if target then
        if type(target) == 'number' then
            local tp = QBox.Functions.GetPlayer(target)
            targetCid = tp and tp.PlayerData.citizenid or tostring(target)
        else
            targetCid = tostring(target)
        end
    end
    MySQL.insert('INSERT INTO admin_logs (admin_cid, action, target) VALUES (?, ?, ?)', { adminCid, action, targetCid })
end

RegisterNetEvent('god-dashboard:checkAndOpen', function()
    local src = source
    if isAdmin(src) then
        TriggerClientEvent('god-dashboard:open', src)
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Unauthorized' })
    end
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    local identifiers = GetPlayerIdentifiers(src)
    local license = nil
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 8) == "license:" then
            license = id
            break
        end
    end
    if not license then return end

    deferrals.defer()
    Wait(0)
    deferrals.update("Checking ban status...")

    local res = MySQL.single.await('SELECT reason, expires_at FROM bans WHERE identifier = ? AND (expires_at IS NULL OR expires_at > NOW()) ORDER BY id DESC LIMIT 1', { license })
    if res then
        local reason = res.reason or "No reason specified."
        local expireStr = res.expires_at and tostring(res.expires_at) or "Permanent"
        deferrals.done(string.format([=[You are banned from this server.
Reason: %s
Expires: %s]=], reason, expireStr))
    else
        deferrals.done()
    end
end)

--- Bunkers
QBox.Functions.CreateCallback('god-dashboard:getBunkers', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    local bunkers = (GetResourceState('bunker-builder') == 'started' and exports['bunker-builder']:GetAllBunkers() or {}) or {}
    cb(bunkers)
end)

QBox.Functions.CreateCallback('god-dashboard:getBunkerCoords', function(source, cb, id)
    if not isAdmin(source) then cb(nil) return end
    local bunker = (GetResourceState('bunker-builder') == 'started' and exports['bunker-builder']:GetBunker(id) or nil)
    if bunker then
        cb(bunker.coords)
    else
        cb(nil)
    end
end)

RegisterNetEvent('god-dashboard:deleteBunker', function(id)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'deleteBunker', id)
    TriggerEvent('bunker-builder:delete', id)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bunker deleted' })
end)

RegisterNetEvent('god-dashboard:duplicateBunker', function(id)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'duplicateBunker', id)
    TriggerEvent('bunker-builder:duplicate', id)
end)

RegisterNetEvent('god-dashboard:updateBunker', function(id, data)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'updateBunker', id)
    TriggerEvent('bunker-builder:update', id, data)
end)

--- Objects
QBox.Functions.CreateCallback('god-dashboard:getPlacedObjects', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    QBox.Functions.TriggerCallback('place-anywhere:getObjects', function(objects)
        cb(objects or {})
    end, source)
end)

QBox.Functions.CreateCallback('god-dashboard:getObjectCoords', function(source, cb, id)
    if not isAdmin(source) then cb(nil) return end
    local objects = exports['place-anywhere'] and exports['place-anywhere']:GetPlacedObjects() or {}
    local obj = objects[id]
    if obj then
        local coords = json.decode(obj.coords)
        cb(coords)
    else
        cb(nil)
    end
end)

RegisterNetEvent('god-dashboard:placeObject', function(data)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'placeObject', data and data.model or 'unknown')
    TriggerEvent('place-anywhere:place', data)
end)

RegisterNetEvent('god-dashboard:deleteObject', function(id)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'deleteObject', id)
    TriggerEvent('place-anywhere:delete', id)
end)

--- Doors
QBox.Functions.CreateCallback('god-dashboard:getDoors', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    QBox.Functions.TriggerCallback('passcodedoor:admin:listDoors', function(doors)
        cb(doors or {})
    end, source)
end)

RegisterNetEvent('god-dashboard:createDoor', function(data)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'createDoor', data and data.label or 'unknown')
    TriggerEvent('passcodedoor:admin:create', data)
end)

RegisterNetEvent('god-dashboard:deleteDoor', function(id)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'deleteDoor', id)
    TriggerEvent('passcodedoor:admin:remove', id)
end)

RegisterNetEvent('god-dashboard:updateDoorPasscode', function(id, passcode)
    local src = source
    if not isAdmin(src) or not passcode then return end
    if #passcode < 3 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Passcode must be 3+ characters' })
        return
    end
    logAdminAction(src, 'updateDoorPasscode', id)
    TriggerEvent('passcodedoor:admin:setPasscode', id, passcode)
end)

RegisterNetEvent('god-dashboard:grantDoorAccess', function(doorId, cid)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'grantDoorAccess', doorId .. ' -> ' .. tostring(cid))
    TriggerEvent('passcodedoor:admin:grantAccess', doorId, cid)
end)

RegisterNetEvent('god-dashboard:revokeDoorAccess', function(doorId, cid)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'revokeDoorAccess', doorId .. ' -> ' .. tostring(cid))
    TriggerEvent('passcodedoor:admin:revokeAccess', doorId, cid)
end)

--- Vehicles
RegisterNetEvent('god-dashboard:spawnVehicle', function(data)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'spawnVehicle', data and data.model or 'unknown')
    TriggerClientEvent('god-dashboard:spawnVehicleAtCoords', src, data.model, data.coords, data.heading)
end)

--- Commands
QBox.Functions.CreateCallback('god-dashboard:getCommands', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    local cmds = QBox.Functions.GetCommands() or {}
    local list = {}
    for name, cmd in pairs(cmds) do
        table.insert(list, {
            name = name,
            description = cmd.description or '',
            params = cmd.params or {},
            adminOnly = cmd.adminOnly or false,
        })
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    cb(list)
end)

--- Players
QBox.Functions.CreateCallback('god-dashboard:getPlayers', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    local players = {}
    local activePlayers = QBox.Functions.GetPlayers()
    for _, s in ipairs(activePlayers) do
        local p = QBox.Functions.GetPlayer(s)
        if p then
            table.insert(players, {
                src = s,
                citizenid = p.PlayerData.citizenid,
                name = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname,
                job = p.PlayerData.job.name,
                grade = p.PlayerData.job.grade.level,
                group = p.PlayerData.group,
            })
        end
    end
    cb(players)
end)

--- Server Actions
RegisterNetEvent('god-dashboard:setWeather', function(weather)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'setWeather', weather)
    TriggerClientEvent('admin:setWeather', -1, weather)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Weather set to ' .. weather })
end)

RegisterNetEvent('god-dashboard:setTime', function(hour)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'setTime', tostring(hour))
    TriggerClientEvent('admin:setTime', -1, hour)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Time set to ' .. hour .. ':00' })
end)

RegisterNetEvent('god-dashboard:announce', function(msg)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'announce', msg)
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 255, 0, 0 },
        multiline = true,
        args = { 'ANNOUNCEMENT', msg }
    })
end)

RegisterNetEvent('god-dashboard:revive', function(target)
    local src = source
    if not isAdmin(src) then return end
    local targetSrc = tonumber(target) or src
    logAdminAction(src, 'revive', targetSrc)
    TriggerClientEvent('wasabi-ambulance:client:revive', targetSrc)
end)

RegisterNetEvent('god-dashboard:clearArea', function()
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'clearArea', '100m')
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    ClearAreaOfEverything(coords.x, coords.y, coords.z, 100.0, false, false, false, false)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Area cleared (100m radius)' })
end)

RegisterNetEvent('god-dashboard:kickPlayer', function(target, reason)
    local src = source
    if not isAdmin(src) then return end
    local targetPlayer = QBox.Functions.GetPlayer(target)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    logAdminAction(src, 'kickPlayer', target)
    DropPlayer(target, reason or 'Kicked by administrator.')
end)

RegisterNetEvent('god-dashboard:freezePlayer', function(target)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'freezePlayer', target)
    TriggerClientEvent('admin:toggleFreeze', target)
end)

RegisterNetEvent('god-dashboard:teleportToPlayer', function(target)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'teleportToPlayer', target)
    local targetPed = GetPlayerPed(target)
    local coords = GetEntityCoords(targetPed)
    local ped = GetPlayerPed(src)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
end)

RegisterNetEvent('god-dashboard:bringPlayer', function(target)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'bringPlayer', target)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    TriggerClientEvent('admin:teleportTo', target, coords)
end)

--- Ported god-menu features

-- Money management
RegisterNetEvent('god-dashboard:giveMoney', function(target, amount, mtype)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'giveMoney', target)
    local p = QBox.Functions.GetPlayer(target)
    if not p then return end
    p.Functions.AddMoney(mtype or 'cash', amount or 0)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave $' .. amount .. ' (' .. (mtype or 'cash') .. ') to ' .. p.PlayerData.charinfo.firstname })
end)

RegisterNetEvent('god-dashboard:giveAllMoney', function(amount, mtype)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'giveAllMoney', 'all (' .. (amount or 0) .. ')')
    local players = QBox.Functions.GetPlayers()
    local count = 0
    for _, s in ipairs(players) do
        local p = QBox.Functions.GetPlayer(s)
        if p then
            p.Functions.AddMoney(mtype or 'cash', amount or 0)
            count = count + 1
        end
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave $' .. amount .. ' (' .. (mtype or 'cash') .. ') to ' .. count .. ' players' })
end)

-- Item management (using exports.ox_inventory)
RegisterNetEvent('god-dashboard:giveItem', function(target, item, count)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'giveItem', tostring(target) .. ' (' .. tostring(item) .. ' x' .. tostring(count) .. ')')
    exports.ox_inventory:AddItem(target, item, count or 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave ' .. (count or 1) .. 'x ' .. item .. ' to ID ' .. target })
end)

RegisterNetEvent('god-dashboard:spawnItem', function(target, item, count)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'spawnItem', tostring(item) .. ' x' .. tostring(count))
    exports.ox_inventory:AddItem(target or src, item, count or 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Spawned ' .. (count or 1) .. 'x ' .. item })
end)

RegisterNetEvent('god-dashboard:giveAllItem', function(item, count)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'giveAllItem', tostring(item) .. ' x' .. tostring(count))
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        exports.ox_inventory:AddItem(s, item, count or 1)
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave ' .. (count or 1) .. 'x ' .. item .. ' to all players' })
end)

RegisterNetEvent('god-dashboard:removeItem', function(target, item, count)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'removeItem', tostring(target) .. ' (' .. tostring(item) .. ' x' .. tostring(count) .. ')')
    exports.ox_inventory:RemoveItem(target, item, count or 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Removed ' .. (count or 1) .. 'x ' .. item .. ' from ID ' .. target })
end)

-- Player actions (slap, heal, armor, warn)
RegisterNetEvent('god-dashboard:slapPlayer', function(target)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'slapPlayer', target)
    local ped = GetPlayerPed(target)
    if not ped or ped == 0 then return end
    local coords = GetEntityCoords(ped)
    local rng = math.random(-20, 20) / 10
    SetEntityCoords(ped, coords.x + rng, coords.y + rng, coords.z + 3.0, false, false, false, false)
    SetEntityVelocity(ped, rng, rng, 5.0)
    TriggerClientEvent('ox_lib:notify', target, { type = 'error', description = 'You got slapped by an admin!' })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Slapped player ' .. target })
end)

RegisterNetEvent('god-dashboard:healPlayer', function(target)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'healPlayer', target or src)
    TriggerClientEvent('wasabi-ambulance:client:revive', target or src)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Healed player ' .. (target or src) })
end)

RegisterNetEvent('god-dashboard:giveArmor', function(target, amount)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'giveArmor', tostring(target or src) .. ' (' .. tostring(amount) .. ')')
    local ped = GetPlayerPed(target or src)
    if ped and ped ~= 0 then
        SetPedArmour(ped, amount or 100)
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Set armor to ' .. (amount or 100) .. ' for ID ' .. (target or src) })
end)

RegisterNetEvent('god-dashboard:warnPlayer', function(target, reason)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'warnPlayer', tostring(target) .. ' (' .. tostring(reason) .. ')')
    TriggerClientEvent('chat:addMessage', target, {
        color = { 255, 0, 0 },
        multiline = true,
        args = { 'ADMIN WARNING', reason or 'No reason specified' }
    })
    TriggerClientEvent('ox_lib:notify', target, { type = 'error', description = 'ADMIN WARNING: ' .. (reason or 'No reason specified'), duration = 10000 })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Warning sent to player ' .. target })
end)

-- Job and group assignment
RegisterNetEvent('god-dashboard:setJob', function(target, job, grade)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'setJob', tostring(target) .. ' (' .. tostring(job) .. ' ' .. tostring(grade) .. ')')
    local p = QBox.Functions.GetPlayer(target)
    if not p then return end
    p.Functions.SetJob(job, grade or 0)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Set job for ' .. p.PlayerData.charinfo.firstname .. ' to ' .. job .. ' (grade ' .. (grade or 0) .. ')' })
end)

RegisterNetEvent('god-dashboard:setGroup', function(target, group)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'setGroup', tostring(target) .. ' (' .. tostring(group) .. ')')
    local p = QBox.Functions.GetPlayer(target)
    if not p then return end
    p.Functions.SetGroup(group)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Set group for ' .. p.PlayerData.charinfo.firstname .. ' to ' .. group })
end)

RegisterNetEvent('god-dashboard:setPlayerStat', function(target, statType, value)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'setPlayerStat', tostring(target) .. ' (' .. tostring(statType) .. '=' .. tostring(value) .. ')')
    local p = QBox.Functions.GetPlayer(target)
    if not p then return end
    if statType == 'health' then
        local ped = GetPlayerPed(target)
        if ped and ped ~= 0 then SetEntityHealth(ped, value or 200) end
    elseif statType == 'armor' then
        local ped = GetPlayerPed(target)
        if ped and ped ~= 0 then SetPedArmour(ped, value or 100) end
    elseif statType == 'hunger' or statType == 'thirst' then
        p.Functions.SetMetaData(statType, value)
        TriggerClientEvent('hud:client:UpdateNeeds', target, p.PlayerData.metadata.hunger, p.PlayerData.metadata.thirst)
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Set ' .. statType .. ' to ' .. value .. ' for ID ' .. target })
end)

RegisterNetEvent('god-dashboard:setAllJob', function(job, grade)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'setAllJob', tostring(job) .. ' (' .. tostring(grade) .. ')')
    local players = QBox.Functions.GetPlayers()
    local count = 0
    for _, s in ipairs(players) do
        local p = QBox.Functions.GetPlayer(s)
        if p then
            p.Functions.SetJob(job, grade or 0)
            count = count + 1
        end
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Set job ' .. job .. ' for ' .. count .. ' players' })
end)

-- Vehicles and garage
RegisterNetEvent('god-dashboard:giveCarToGarage', function(target, vehicleModel)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'giveCarToGarage', tostring(target) .. ' (' .. tostring(vehicleModel) .. ')')
    local p = QBox.Functions.GetPlayer(target)
    if not p then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    local citizenId = p.PlayerData.citizenid
    local plate = 'GOD' .. math.random(10000, 99999)
    local hash = GetHashKey(vehicleModel)
    local success, result = pcall(function()
        return exports['Renewed-Garages']:AddVehicle(citizenId, {
            plate = plate,
            vehicle = vehicleModel,
            hash = hash,
        })
    end)
    if success then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave ' .. vehicleModel .. ' (' .. plate .. ') to ' .. p.PlayerData.charinfo.firstname })
        TriggerClientEvent('ox_lib:notify', target, { type = 'success', description = 'Admin gave you a ' .. vehicleModel .. ' (' .. plate .. ') in your garage' })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Failed: ' .. tostring(result) })
    end
end)

RegisterNetEvent('god-dashboard:transferVehicle', function(plate, newOwnerId)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'transferVehicle', tostring(plate) .. ' -> ' .. tostring(newOwnerId))
    local target = QBox.Functions.GetPlayer(newOwnerId)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'New owner not found' })
        return
    end
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicle then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Vehicle not found with plate: ' .. plate })
        return
    end
    MySQL.update.await('UPDATE player_vehicles SET citizenid = ? WHERE plate = ?', { target.PlayerData.citizenid, plate })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Transferred ' .. vehicle.vehicle .. ' (' .. plate .. ') to ' .. target.PlayerData.charinfo.firstname })
    TriggerClientEvent('ox_lib:notify', newOwnerId, { type = 'success', description = 'Admin transferred ' .. vehicle.vehicle .. ' (' .. plate .. ') to your garage' })
end)

-- Mass player management
RegisterNetEvent('god-dashboard:killAll', function()
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'killAll', 'all')
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local ped = GetPlayerPed(s)
        if ped and ped ~= 0 then
            SetEntityHealth(ped, 0)
        end
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Killed all players' })
end)

RegisterNetEvent('god-dashboard:freezeAll', function(state)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'freezeAll', tostring(state))
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        TriggerClientEvent('admin:toggleFreeze', s, state)
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = (state and 'Frozen' or 'Unfrozen') .. ' all players' })
end)

RegisterNetEvent('god-dashboard:teleportAllToMe', function()
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'teleportAllToMe', 'all')
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        if s ~= src then
            TriggerClientEvent('admin:teleportTo', s, coords)
        end
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Teleported all players to you' })
end)

RegisterNetEvent('god-dashboard:reviveAll', function()
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'reviveAll', 'all')
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        TriggerClientEvent('wasabi-ambulance:client:revive', s)
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Revived all players' })
end)

RegisterNetEvent('god-dashboard:toggleNoclip', function()
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'toggleNoclip', src)
    TriggerClientEvent('god-dashboard:client:toggleNoclip', src)
end)

RegisterNetEvent('god-dashboard:spectatePlayer', function(target)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'spectatePlayer', target)
    local targetSrc = tonumber(target)
    if targetSrc then
        TriggerClientEvent('god-dashboard:client:spectate', src, targetSrc)
    end
end)

-- Ambient Events Management
RegisterNetEvent('god-dashboard:forceSpawnAmbientEvent', function(eventType)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'forceSpawnAmbientEvent', eventType or 'random')
    TriggerEvent('ambient-events:server:forceSpawn', eventType)
end)

RegisterNetEvent('god-dashboard:resolveAmbientEvent', function(eventId)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'resolveAmbientEvent', eventId)
    TriggerEvent('ambient-events:server:resolveEvent', eventId)
end)

QBox.Functions.CreateCallback('god-dashboard:getAmbientEvents', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    QBox.Functions.TriggerCallback('ambient-events:server:getEvents', function(events)
        cb(events or {})
    end, source)
end)
