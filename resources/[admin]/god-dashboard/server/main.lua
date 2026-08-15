RegisterNetEvent('god-dashboard:checkAndOpen', function()
    local src = source
    if isAdmin(src) then
        TriggerClientEvent('god-dashboard:open', src)
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Unauthorized' })
    end
end)
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
    local player = QBox.Functions.GetPlayer(src)
    local cid = player and (player.PlayerData.citizenid or player.PlayerData.license) or "console"
    MySQL.insert('INSERT INTO admin_logs (admin_cid, action, target) VALUES (?, ?, ?)', {
        cid, action, tostring(target or '')
    })
end

--- Bunkers
QBox.Functions.CreateCallback('god-dashboard:getBunkers', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    local bunkers = (GetResourceState('bunker-builder') == 'started' and exports['bunker-builder']:GetAllBunkers() or {}) or {}
    local list = {}
    for id, b in pairs(bunkers) do
        table.insert(list, {
            id = id,
            label = b.label,
            passcode = b.passcode or '2193',
            locked = b.locked ~= false,
            cidBypass = b.cidBypass ~= false,
            interiorType = b.interiorType or 'bunker_meth_lab',
            interiorName = b.interiorName,
            entrance = { x = b.entrance.coords.x, y = b.entrance.coords.y, z = b.entrance.coords.z },
            entranceHeading = b.entrance.heading,
            interiorCoords = { x = b.interior.coords.x, y = b.interior.coords.y, z = b.interior.coords.z },
        })
    end
    cb(list)
end)

QBox.Functions.CreateCallback('god-dashboard:getBunkerCoords', function(source, cb, id)
    if not isAdmin(source) then cb(nil) return end
    local bunker = (GetResourceState('bunker-builder') == 'started' and exports['bunker-builder']:GetBunker(id) or nil)
    if bunker and bunker.entrance then
        cb({ x = bunker.entrance.coords.x, y = bunker.entrance.coords.y, z = bunker.entrance.coords.z })
    else
        cb(nil)
    end
end)

RegisterNetEvent('god-dashboard:deleteBunker', function(id)
    local src = source
    if not isAdmin(src) then return end
    TriggerEvent('bunker-builder:delete', id)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bunker deleted' })
end)

RegisterNetEvent('god-dashboard:duplicateBunker', function(id)
    local src = source
    if not isAdmin(src) then return end
    TriggerEvent('bunker-builder:duplicate', id)
end)

RegisterNetEvent('god-dashboard:updateBunker', function(id, data)
    local src = source
    if not isAdmin(src) then return end
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
    TriggerEvent('place-anywhere:save', data)
end)

RegisterNetEvent('god-dashboard:deleteObject', function(id)
    local src = source
    if not isAdmin(src) then return end
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
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    TriggerEvent('passcodedoor:admin:create', data.label, data.doorModel, { x = coords.x, y = coords.y, z = coords.z }, heading, data.passcode or '1234')
end)

RegisterNetEvent('god-dashboard:deleteDoor', function(id)
    local src = source
    if not isAdmin(src) then return end
    TriggerEvent('passcodedoor:admin:remove', id)
end)

RegisterNetEvent('god-dashboard:updateDoorPasscode', function(id, passcode)
    local src = source
    if not isAdmin(src) or not passcode then return end
    if #passcode < 3 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Passcode must be 3+ characters' })
        return
    end
    local h = ''
    for i = 1, #passcode do
        local byte = string.byte(passcode, i)
        h = h .. string.format('%02x', (byte * 7 + i) % 256)
    end
    MySQL.update('UPDATE passcode_doors SET passcode_hash = ? WHERE id = ?', { h, id })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Door passcode updated' })
end)

RegisterNetEvent('god-dashboard:grantDoorAccess', function(doorId, cid)
    local src = source
    if not isAdmin(src) then return end
    TriggerEvent('passcodedoor:admin:grantAccess', doorId, cid)
end)

RegisterNetEvent('god-dashboard:revokeDoorAccess', function(doorId, cid)
    local src = source
    if not isAdmin(src) then return end
    TriggerEvent('passcodedoor:admin:revokeAccess', doorId, cid)
end)

--- Vehicles
RegisterNetEvent('god-dashboard:spawnVehicle', function(data)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('god-dashboard:spawnVehicleAtCoords', src, data.model, data.coords, data.heading)
end)

RegisterNetEvent('god-dashboard:spawnVehicleAtCoords', function(model, coords, heading)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 200 do
        Citizen.Wait(10)
        tries = tries + 1
    end
    if not HasModelLoaded(hash) then
        Wrappers.Notify('Failed to load vehicle: ' .. model, 'error')
        return
    end
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading or 0.0, true, false)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetModelAsNoLongerNeeded(hash)
    Wrappers.Notify('Spawned ' .. model, 'success')
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
    TriggerClientEvent('admin:setWeather', -1, weather)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Weather set to ' .. weather })
end)

RegisterNetEvent('god-dashboard:setTime', function(hour)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:setTime', -1, hour)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Time set to ' .. hour .. ':00' })
end)

RegisterNetEvent('god-dashboard:announce', function(msg)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('chat:addMessage', -1, { args = { 'SERVER ANNOUNCEMENT', msg }, color = { 255, 200, 0 } })
end)

RegisterNetEvent('god-dashboard:revive', function(target)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('hospital:client:Revive', target or src)
end)

RegisterNetEvent('god-dashboard:clearArea', function()
    local src = source
    if not isAdmin(src) then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    ClearAreaOfEverything(coords.x, coords.y, coords.z, 100.0, false, false, false, false)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Area cleared (100m radius)' })
end)

RegisterNetEvent('god-dashboard:kickPlayer', function(target, reason)
    local src = source
    if not isAdmin(src) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local targetPlayer = QBox.Functions.GetPlayer(target)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    DropPlayer(target, 'Kicked by admin: ' .. (reason or 'No reason'))
end)

RegisterNetEvent('god-dashboard:freezePlayer', function(target)
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('admin:toggleFreeze', target)
end)

RegisterNetEvent('god-dashboard:teleportToPlayer', function(target)
    local src = source
    if not isAdmin(src) then return end
    local targetPed = GetPlayerPed(target)
    local coords = GetEntityCoords(targetPed)
    TriggerClientEvent('admin:teleportTo', src, coords)
end)

RegisterNetEvent('god-dashboard:bringPlayer', function(target)
    local src = source
    if not isAdmin(src) then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    TriggerClientEvent('admin:teleportTo', target, coords)
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


--- Ported god-menu Server Events ---
RegisterNetEvent('god-dashboard:giveAllMoney', function(moneyType, amount)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'giveAllMoney', tostring(moneyType) .. ':' .. tostring(amount))
    local amt = tonumber(amount) or 0
    if amt > 0 then
        for _, pSrc in ipairs(GetPlayers()) do
            local p = QBox.Functions.GetPlayer(tonumber(pSrc))
            if p then p.Functions.AddMoney(moneyType or 'cash', amt, 'god-admin-all') end
        end
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave $' .. amt .. ' to all players' })
    end
end)

RegisterNetEvent('god-dashboard:giveAllItem', function(item, amount)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'giveAllItem', tostring(item) .. ':' .. tostring(amount))
    local amt = tonumber(amount) or 1
    if item and amt > 0 then
        for _, pSrc in ipairs(GetPlayers()) do
            exports.ox_inventory:AddItem(tonumber(pSrc), item, amt)
        end
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave ' .. amt .. 'x ' .. item .. ' to all players' })
    end
end)

RegisterNetEvent('god-dashboard:removeItem', function(target, item, amount)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'removeItem', tostring(target) .. ':' .. tostring(item) .. ':' .. tostring(amount))
    local targetSrc = tonumber(target)
    local amt = tonumber(amount) or 1
    if targetSrc and item and amt > 0 then
        exports.ox_inventory:RemoveItem(targetSrc, item, amt)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Removed ' .. amt .. 'x ' .. item .. ' from ID ' .. targetSrc })
    end
end)

RegisterNetEvent('god-dashboard:slapPlayer', function(target)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'slapPlayer', target)
    local targetSrc = tonumber(target)
    if targetSrc then
        TriggerClientEvent('god-dashboard:client:slap', targetSrc)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Slapped player ID ' .. targetSrc })
    end
end)

RegisterNetEvent('god-dashboard:healPlayer', function(target)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'healPlayer', target)
    local targetSrc = tonumber(target) or src
    TriggerClientEvent('wasabi-ambulance:client:heal', targetSrc)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Healed player ID ' .. targetSrc })
end)

RegisterNetEvent('god-dashboard:giveArmor', function(target, amount)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'giveArmor', tostring(target) .. ':' .. tostring(amount))
    local targetSrc = tonumber(target) or src
    local armor = tonumber(amount) or 100
    TriggerClientEvent('god-dashboard:client:setArmor', targetSrc, armor)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave armor to ID ' .. targetSrc })
end)

RegisterNetEvent('god-dashboard:setGroup', function(target, group)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'setGroup', tostring(target) .. ':' .. tostring(group))
    local targetSrc = tonumber(target)
    local p = QBox.Functions.GetPlayer(targetSrc)
    if p and group then
        p.Functions.SetMetaData('group', group)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Set group for ID ' .. targetSrc })
    end
end)

RegisterNetEvent('god-dashboard:setAllJob', function(job, grade)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'setAllJob', tostring(job) .. ':' .. tostring(grade))
    if job then
        for _, pSrc in ipairs(GetPlayers()) do
            local p = QBox.Functions.GetPlayer(tonumber(pSrc))
            if p then p.Functions.SetJob(job, tonumber(grade) or 0) end
        end
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Set all players job to ' .. job })
    end
end)

RegisterNetEvent('god-dashboard:giveCarToGarage', function(target, model)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'giveCarToGarage', tostring(target) .. ':' .. tostring(model))
    local targetSrc = tonumber(target)
    local p = QBox.Functions.GetPlayer(targetSrc)
    if p and model then
        local plate = 'GOD' .. math.random(1000, 9999)
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            p.PlayerData.license, p.PlayerData.citizenid, model, GetHashKey(model), '{}', plate, 1
        })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave vehicle ' .. model .. ' (Plate: ' .. plate .. ') to garage' })
    end
end)

RegisterNetEvent('god-dashboard:killAll', function()
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'killAll', 'all')
    for _, pSrc in ipairs(GetPlayers()) do
        TriggerClientEvent('god-dashboard:client:kill', tonumber(pSrc))
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Killed all players' })
end)

RegisterNetEvent('god-dashboard:freezeAll', function()
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'freezeAll', 'all')
    for _, pSrc in ipairs(GetPlayers()) do
        TriggerClientEvent('god-dashboard:client:freeze', tonumber(pSrc))
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Toggled freeze for all players' })
end)

RegisterNetEvent('god-dashboard:teleportAllToMe', function()
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'teleportAllToMe', 'all')
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    for _, pSrc in ipairs(GetPlayers()) do
        local tSrc = tonumber(pSrc)
        if tSrc ~= src then
            SetEntityCoords(GetPlayerPed(tSrc), coords.x, coords.y, coords.z, false, false, false, false)
        end
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Teleported all players to you' })
end)

RegisterNetEvent('god-dashboard:reviveAll', function()
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'reviveAll', 'all')
    for _, pSrc in ipairs(GetPlayers()) do
        TriggerClientEvent('wasabi-ambulance:client:revive', tonumber(pSrc))
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Revived all players' })
end)

RegisterNetEvent('god-dashboard:warnPlayer', function(target, reason)
    local src = source
    if not isAdmin(src) then return end
    logAdminAction(src, 'warnPlayer', tostring(target) .. ':' .. tostring(reason))
    local targetSrc = tonumber(target)
    if targetSrc then
        TriggerClientEvent('ox_lib:notify', targetSrc, { title = 'WARNING', description = reason or 'You have received an admin warning.', type = 'warning', length = 10000 })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Warned player ID ' .. targetSrc })
    end
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
