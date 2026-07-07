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

RegisterNetEvent('god:server:giveAllItem', function(item, count)
    if not isOwner(source) then return end
    local players = QBCore.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local p = QBCore.Functions.GetPlayer(src)
        if p then
            p.Functions.AddItem(item, count or 1)
        end
    end
end)

RegisterNetEvent('god:server:setWeather', function(weather)
    if not isOwner(source) then return end
    GlobalState.weatherType = weather
    TriggerClientEvent('god:client:setWeather', -1, weather)
end)

RegisterNetEvent('god:server:setTime', function(hour, minute)
    if not isOwner(source) then return end
    hour = math.max(0, math.min(23, hour))
    minute = math.max(0, math.min(59, minute or 0))
    NetworkOverrideClockTime(hour, minute, 0)
    GlobalState.serverTime = { hour = hour, minute = minute }
    TriggerClientEvent('god:client:setTime', -1, hour, minute)
end)

RegisterNetEvent('god:server:announce', function(message)
    if not isOwner(source) then return end
    TriggerClientEvent('god:client:announce', -1, message)
end)

RegisterNetEvent('god:server:reviveAll', function()
    if not isOwner(source) then return end
    local players = QBCore.Functions.GetPlayers()
    for _, src in ipairs(players) do
        TriggerClientEvent('god:client:revive', src)
    end
end)

--- ============ NEW EXPANDED FEATURES ============

--- Set player job
RegisterNetEvent('god:server:setJob', function(id, job, grade)
    if not isOwner(source) then return end
    local p = QBCore.Functions.GetPlayer(id)
    if not p then return end
    p.Functions.SetJob(job, grade or 0)
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Set job to ' .. job .. ' grade ' .. (grade or 0) })
end)

--- Set admin group
RegisterNetEvent('god:server:setGroup', function(id, group)
    if not isOwner(source) then return end
    local p = QBCore.Functions.GetPlayer(id)
    if not p then return end
    p.Functions.SetGroup(group)
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Set group to ' .. group })
end)

--- Set player stats (health, armor, hunger, thirst)
RegisterNetEvent('god:server:setPlayerStat', function(id, statType, value)
    if not isOwner(source) then return end
    if statType == 'health' or statType == 'armor' then
        TriggerClientEvent('god:client:setStat', id, statType, value)
    elseif statType == 'hunger' or statType == 'thirst' then
        local p = QBCore.Functions.GetPlayer(id)
        if p then
            p.Functions.SetMetaData(statType, value)
            TriggerClientEvent('hud:client:UpdateNeeds', id, p.PlayerData.metadata.hunger, p.PlayerData.metadata.thirst)
        end
    end
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Set ' .. statType .. ' to ' .. value })
end)

--- Give car to player's garage
RegisterNetEvent('god:server:giveCarToGarage', function(id, vehicleModel)
    if not isOwner(source) then return end
    local p = QBCore.Functions.GetPlayer(id)
    if not p then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Player not found' })
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
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Gave ' .. vehicleModel .. ' (' .. plate .. ') to ' .. p.PlayerData.charinfo.firstname .. '\'s garage' })
        TriggerClientEvent('ox_lib:notify', id, { type = 'success', description = 'Admin gave you a ' .. vehicleModel .. ' (' .. plate .. ') — check your garage' })
    else
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Failed: ' .. tostring(result) })
    end
end)

--- Transfer vehicle ownership
RegisterNetEvent('god:server:transferVehicle', function(plate, newOwnerId)
    if not isOwner(source) then return end
    local target = QBCore.Functions.GetPlayer(newOwnerId)
    if not target then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'New owner not found' })
        return
    end
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicle then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Vehicle not found with plate: ' .. plate })
        return
    end
    MySQL.update.await('UPDATE player_vehicles SET citizenid = ? WHERE plate = ?', { target.PlayerData.citizenid, plate })
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Transferred ' .. vehicle.vehicle .. ' (' .. plate .. ') to ' .. target.PlayerData.charinfo.firstname })
    TriggerClientEvent('ox_lib:notify', newOwnerId, { type = 'success', description = 'Admin transferred ' .. vehicle.vehicle .. ' (' .. plate .. ') to your garage' })
end)

--- Kill all players
RegisterNetEvent('god:server:killAll', function()
    if not isOwner(source) then return end
    local players = QBCore.Functions.GetPlayers()
    for _, src in ipairs(players) do
        TriggerClientEvent('god:client:kill', src)
    end
end)

--- Freeze all players
RegisterNetEvent('god:server:freezeAll', function(state)
    if not isOwner(source) then return end
    local players = QBCore.Functions.GetPlayers()
    for _, src in ipairs(players) do
        TriggerClientEvent('god:client:freeze', src, state)
    end
end)

--- Teleport all players to admin
RegisterNetEvent('god:server:teleportAllToMe', function()
    if not isOwner(source) then return end
    local coords = GetEntityCoords(GetPlayerPed(source))
    local players = QBCore.Functions.GetPlayers()
    for _, src in ipairs(players) do
        if src ~= source then
            TriggerClientEvent('god:client:teleportTo', src, coords)
        end
    end
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Teleported all players to you' })
end)

--- Give money to all players
RegisterNetEvent('god:server:giveAllMoney', function(amount, mtype)
    if not isOwner(source) then return end
    local players = QBCore.Functions.GetPlayers()
    local count = 0
    for _, src in ipairs(players) do
        local p = QBCore.Functions.GetPlayer(src)
        if p then
            p.Functions.AddMoney(mtype or 'cash', amount)
            count = count + 1
        end
    end
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Gave $' .. amount .. ' to ' .. count .. ' players' })
end)

--- Set job for all players
RegisterNetEvent('god:server:setAllJob', function(job, grade)
    if not isOwner(source) then return end
    local players = QBCore.Functions.GetPlayers()
    local count = 0
    for _, src in ipairs(players) do
        local p = QBCore.Functions.GetPlayer(src)
        if p then
            p.Functions.SetJob(job, grade or 0)
            count = count + 1
        end
    end
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Set job ' .. job .. ' for ' .. count .. ' players' })
end)

--- Determine item category
local function getItemCategory(item)
    if item.metadata and item.metadata.type then
        local t = item.metadata.type:lower()
        if t == 'weapon' then return 'weapons' end
        if t == 'ammo' then return 'ammo' end
        if t == 'attachment' then return 'attachments' end
    end
    local n = item.name:lower()
    if n:find('^weapon_') then return 'weapons' end
    if n:find('_ammo$') or n:find('^ammo') then return 'ammo' end
    if n:find('^at_') then return 'attachments' end
    if n:find('^clothing_') or n:find('^shirt_') or n:find('^pants_') or n:find('^shoe_') or n:find('^hat_') or n:find('^mask_') or n:find('^vest_') or n:find('^bag_') then return 'clothing' end
    return 'items'
end

--- Component display names
local componentLabels = {
    at_suppressor = 'Suppressor', at_suppressor_light = 'Light Suppressor',
    at_grip = 'Grip', at_barrel = 'Heavy Barrel',
    at_flashlight = 'Flashlight', at_light = 'Light',
    at_scope_holo = 'Holo Sight', at_scope_small = 'Small Scope',
    at_scope_medium = 'Medium Scope', at_scope_large = 'Large Scope',
    at_scope_advanced = 'Advanced Scope', at_scope_nv = 'Night Vision',
    at_scope_thermal = 'Thermal Scope', at_muzzle = 'Muzzle',
    at_muzzle_bell = 'Muzzle Bell', at_muzzle_fat = 'Fat Muzzle',
    at_muzzle_flat = 'Flat Muzzle', at_muzzle_heavy = 'Heavy Muzzle',
    at_muzzle_slanted = 'Slanted Muzzle', at_muzzle_split = 'Split Muzzle',
    at_muzzle_squared = 'Squared Muzzle', at_muzzle_tactical = 'Tactical Muzzle',
    at_muzzle_precision = 'Precision Muzzle',
    at_clip_extended = 'Extended Mag', at_clip_extended2 = 'Drum Mag',
    at_clip_drum = 'Large Drum Mag',
    at_skin = 'Skin',
}

--- Get player details (inventory, job, stats)
lib.callback.register('god:server:getPlayerDetails', function(source, id)
    if not isOwner(source) then return {} end
    local p = QBCore.Functions.GetPlayer(id)
    if not p then return {} end
    local inventory = p.PlayerData.items or {}
    local invItems = {}
    for _, item in ipairs(inventory) do
        if item then
            local metadata = item.metadata or {}
            local components = {}
            if metadata.components and type(metadata.components) == 'table' then
                for _, comp in ipairs(metadata.components) do
                    components[#components + 1] = {
                        name = comp,
                        label = componentLabels[comp] or comp,
                    }
                end
            end
            invItems[#invItems + 1] = {
                name = item.name,
                label = item.label or item.name,
                count = item.count or item.amount or 1,
                slot = item.slot,
                weight = item.weight or 0,
                description = metadata.description or '',
                category = getItemCategory(item),
                durability = metadata.durability,
                components = components,
                ammo = metadata.ammo,
                ammotype = metadata.ammotype,
                serial = metadata.serial,
                weapon = metadata.weapon,
            }
        end
    end
    -- Sort by category then slot
    table.sort(invItems, function(a, b)
        if a.category ~= b.category then
            local order = { weapons = 1, attachments = 2, ammo = 3, items = 4, clothing = 5 }
            return (order[a.category] or 99) < (order[b.category] or 99)
        end
        return (a.slot or 0) < (b.slot or 0)
    end)
    return {
        citizenid = p.PlayerData.citizenid,
        job = p.PlayerData.job,
        group = p.PlayerData.group,
        metadata = p.PlayerData.metadata,
        inventory = invItems,
        money = {
            cash = p.PlayerData.money and p.PlayerData.money.cash or 0,
            bank = p.PlayerData.money and p.PlayerData.money.bank or 0,
        },
    }
end)

--- Remove item from player
RegisterNetEvent('god:server:removeItem', function(id, itemName, count)
    if not isOwner(source) then return end
    local p = QBCore.Functions.GetPlayer(id)
    if not p then return end
    p.Functions.RemoveItem(itemName, count or 1)
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Removed ' .. (count or 1) .. 'x ' .. itemName .. ' from player' })
end)

--- Warn a player
RegisterNetEvent('god:server:warnPlayer', function(id, message)
    if not isOwner(source) then return end
    TriggerClientEvent('ox_lib:notify', id, { type = 'warning', description = 'ADMIN WARNING: ' .. message, duration = 10000 })
    TriggerClientEvent('chat:addMessage', id, {
        color = { 255, 0, 0 },
        multiline = true,
        args = { 'ADMIN WARNING', message }
    })
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Warning sent to player ' .. id })
end)

--- Spawn vehicle for a specific player (in front of them)
RegisterNetEvent('god:server:spawnVehicleForPlayer', function(id, vehicleModel)
    if not isOwner(source) then return end
    TriggerClientEvent('god:client:spawnVehicleForPlayer', id, vehicleModel)
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Spawned ' .. vehicleModel .. ' for player ' .. id })
end)

--- Server restart countdown
RegisterNetEvent('god:server:restartCountdown', function(minutes)
    if not isOwner(source) then return end
    local players = QBCore.Functions.GetPlayers()
    for _, src in ipairs(players) do
        TriggerClientEvent('ox_lib:notify', src, { type = 'warning', description = 'SERVER RESTART in ' .. minutes .. ' minutes! Please save your work.', duration = 15000 })
        TriggerClientEvent('chat:addMessage', src, {
            color = { 255, 0, 0 },
            multiline = true,
            args = { 'SERVER', 'RESTART in ' .. minutes .. ' minutes! Please park vehicles and save your work.' }
        })
    end
end)

--- Get list of available jobs
lib.callback.register('god:server:getJobList', function(source)
    if not isOwner(source) then return {} end
    local jobs = {}
    if QBCore.Shared and QBCore.Shared.Jobs then
        for name, jobData in pairs(QBCore.Shared.Jobs) do
            local grades = {}
            if jobData.grades then
                for gradeNum, gradeData in pairs(jobData.grades) do
                    grades[#grades + 1] = { grade = tonumber(gradeNum), label = gradeData.label or gradeData.name or 'Grade ' .. gradeNum }
                end
            end
            table.sort(grades, function(a, b) return a.grade < b.grade end)
            jobs[#jobs + 1] = { name = name, label = jobData.label or name, grades = grades }
        end
    end
    table.sort(jobs, function(a, b) return a.label < b.label end)
    return jobs
end)

--- ==================== MANAGED DOORS ====================

local doorStates = {}
local function loadDoorStates()
    local doors = MySQL.query.await('SELECT * FROM admin_managed_doors')
    doorStates = {}
    for _, d in ipairs(doors or {}) do
        doorStates[d.id] = d.is_locked == 1
    end
end
local function hashPasscode(code) return string.format('%04x', tonumber(code or '0') * 7 + 1337) end
local function syncDoorToAll(doorId, locked)
    TriggerClientEvent('god:client:syncDoor', -1, doorId, locked)
end

lib.callback.register('god:server:getManagedDoors', function(source)
    if not isOwner(source) then return {} end
    local doors = MySQL.query.await('SELECT * FROM admin_managed_doors ORDER BY id DESC')
    local result = {}
    for _, d in ipairs(doors or {}) do
        table.insert(result, {
            id = d.id,
            label = d.label,
            door_model = d.door_model,
            coords = json.decode(d.coords),
            heading = d.heading,
            lock_type = d.lock_type,
            passcode_hash = d.passcode_hash,
            allowed_jobs = d.allowed_jobs and json.decode(d.allowed_jobs) or {},
            is_locked = d.is_locked == 1,
            created_by = d.created_by,
            created_at = d.created_at
        })
    end
    return result
end)

lib.callback.register('god:server:findNearestDoorModel', function(source)
    return {} -- client handles detection, this is just a passthrough
end)

lib.callback.register('god:server:verifyDoorPasscode', function(source, doorId, input)
    local p = QBox.Functions.GetPlayer(source)
    if not p then return false end
    local door = MySQL.single.await('SELECT * FROM admin_managed_doors WHERE id = ?', { doorId })
    if not door or door.lock_type ~= 'passcode' or not door.passcode_hash then return false end
    return hashPasscode(input) == door.passcode_hash
end)

RegisterNetEvent('god:server:createDoorLock', function(label, doorModel, coords, heading, lockType, passcode, allowedJobs)
    local src = source
    if not isOwner(src) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    local coordsJson = json.encode(coords)
    local passHash = (lockType == 'passcode' and passcode) and hashPasscode(passcode) or ''
    local jobsJson = (lockType == 'job' and allowedJobs) and json.encode(allowedJobs) or '[]'
    local id = MySQL.insert.await('INSERT INTO admin_managed_doors (label, door_model, coords, heading, lock_type, passcode_hash, allowed_jobs, is_locked, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)',
        { label or 'Door', doorModel or '', coordsJson, heading or 0, lockType or 'permanent', passHash, jobsJson, cid })
    if id then
        doorStates[id] = true
        local newDoor = MySQL.single.await('SELECT * FROM admin_managed_doors WHERE id = ?', { id })
        if newDoor then
            local doorData = {
                id = newDoor.id, label = newDoor.label, door_model = newDoor.door_model,
                coords = json.decode(newDoor.coords), heading = newDoor.heading,
                lock_type = newDoor.lock_type, passcode_hash = newDoor.passcode_hash,
                allowed_jobs = newDoor.allowed_jobs and json.decode(newDoor.allowed_jobs) or {},
                is_locked = true, created_by = newDoor.created_by
            }
            TriggerClientEvent('god:client:addDoorZone', -1, doorData)
            syncDoorToAll(id, true)
        end
    end
end)

RegisterNetEvent('god:server:updateManagedDoor', function(doorId, label, lockType, passcode, allowedJobs)
    local src = source
    if not isOwner(src) or not doorId then return end
    local passHash = (lockType == 'passcode' and passcode) and hashPasscode(passcode) or ''
    local jobsJson = (lockType == 'job' and allowedJobs) and json.encode(allowedJobs) or '[]'
    MySQL.query('UPDATE admin_managed_doors SET label = ?, lock_type = ?, passcode_hash = ?, allowed_jobs = ? WHERE id = ?',
        { label or 'Door', lockType or 'permanent', passHash, jobsJson, doorId })
    local updated = MySQL.single.await('SELECT * FROM admin_managed_doors WHERE id = ?', { doorId })
    if updated then
        local doorData = {
            id = updated.id, label = updated.label, door_model = updated.door_model,
            coords = json.decode(updated.coords), heading = updated.heading,
            lock_type = updated.lock_type, passcode_hash = updated.passcode_hash,
            allowed_jobs = updated.allowed_jobs and json.decode(updated.allowed_jobs) or {},
            is_locked = updated.is_locked == 1, created_by = updated.created_by
        }
        TriggerClientEvent('god:client:updateDoorZone', -1, doorData)
    end
end)

RegisterNetEvent('god:server:deleteManagedDoor', function(doorId)
    if not isOwner(source) or not doorId then return end
    MySQL.query('DELETE FROM admin_managed_doors WHERE id = ?', { doorId })
    doorStates[doorId] = nil
    TriggerClientEvent('god:client:removeDoorZone', -1, doorId)
end)

RegisterNetEvent('god:server:toggleManagedDoor', function(doorId)
    if not isOwner(source) or not doorId then return end
    local door = MySQL.single.await('SELECT * FROM admin_managed_doors WHERE id = ?', { doorId })
    if not door then return end
    local newState = door.is_locked == 1 and 0 or 1
    MySQL.query('UPDATE admin_managed_doors SET is_locked = ? WHERE id = ?', { newState, doorId })
    doorStates[doorId] = newState == 1
    syncDoorToAll(doorId, newState == 1)
end)

RegisterNetEvent('god:server:lockAllManagedDoors', function()
    if not isOwner(source) then return end
    MySQL.query('UPDATE admin_managed_doors SET is_locked = 1')
    local doors = MySQL.query.await('SELECT id FROM admin_managed_doors')
    for _, d in ipairs(doors or {}) do
        doorStates[d.id] = true
        syncDoorToAll(d.id, true)
    end
end)

RegisterNetEvent('god:server:unlockAllManagedDoors', function()
    if not isOwner(source) then return end
    MySQL.query('UPDATE admin_managed_doors SET is_locked = 0')
    local doors = MySQL.query.await('SELECT id FROM admin_managed_doors')
    for _, d in ipairs(doors or {}) do
        doorStates[d.id] = false
        syncDoorToAll(d.id, false)
    end
end)

RegisterNetEvent('god:server:interactManagedDoor', function(doorId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p or not doorId then return end
    local door = MySQL.single.await('SELECT * FROM admin_managed_doors WHERE id = ?', { doorId })
    if not door then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Door not found' })
        return
    end
    if door.lock_type == 'permanent' then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'This door is permanently locked' })
        return
    end
    if door.lock_type == 'job' then
        local playerJob = p.PlayerData.job and p.PlayerData.job.name or ''
        local allowed = json.decode(door.allowed_jobs) or {}
        local hasAccess = false
        for _, j in ipairs(allowed) do
            if j == playerJob then hasAccess = true; break end
        end
        if not hasAccess then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied — your job cannot open this door' })
            return
        end
    end
    local newState = door.is_locked == 1 and 0 or 1
    MySQL.query('UPDATE admin_managed_doors SET is_locked = ? WHERE id = ?', { newState, doorId })
    doorStates[doorId] = newState == 1
    syncDoorToAll(doorId, newState == 1)
end)

-- Load door states on startup
Citizen.CreateThread(function()
    Citizen.Wait(2000)
    loadDoorStates()
end)

--- ==================== BAN MANAGEMENT ====================

lib.callback.register('god:server:getActiveBans', function(source)
    if not isOwner(source) then return {} end
    local bans = MySQL.query.await('SELECT * FROM bans WHERE expires_at IS NULL OR expires_at > NOW() ORDER BY banned_at DESC')
    local result = {}
    for _, b in ipairs(bans or {}) do
        local remaining = ''
        if b.expires_at then
            local now = os.time()
            local exp = os.time({ year = b.expires_at:match('(%d+)'), month = b.expires_at:match('-(%d+)-'), day = b.expires_at:match('-(%d+)'), hour = b.expires_at:match('(%d+):'), min = b.expires_at:match(':(%d+):'), sec = b.expires_at:match(':(%d+)$') })
            local diff = exp - now
            if diff > 0 then
                local days = math.floor(diff / 86400)
                local hours = math.floor((diff % 86400) / 3600)
                remaining = days .. 'd ' .. hours .. 'h'
            else
                remaining = 'Expired'
            end
        else
            remaining = 'Permanent'
        end
        table.insert(result, {
            id = b.id,
            identifier = b.identifier,
            player_name = b.player_name,
            reason = b.reason,
            banner = b.banner,
            banner_cid = b.banner_cid,
            duration = b.duration,
            banned_at = b.banned_at,
            expires_at = b.expires_at,
            remaining = remaining,
        })
    end
    return result
end)

lib.callback.register('god:server:searchBans', function(source, query)
    if not isOwner(source) then return {} end
    local bans = MySQL.query.await('SELECT * FROM bans WHERE (player_name LIKE ? OR identifier LIKE ?) AND (expires_at IS NULL OR expires_at > NOW()) ORDER BY banned_at DESC',
        { '%' .. query .. '%', '%' .. query .. '%' })
    return bans or {}
end)

RegisterNetEvent('god:server:executeBan', function(targetId, reason, duration)
    local src = source
    if not isOwner(src) then return end
    local p = QBox.Functions.GetPlayer(src)
    local target = QBox.Functions.GetPlayer(targetId)
    if not p or not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    local identifiers = GetPlayerIdentifiers(targetId)
    local license = ''
    local steam = ''
    for _, id in ipairs(identifiers) do
        if id:find('^license:') then license = id end
        if id:find('^steam:') then steam = id end
    end
    local identifier = license ~= '' and license or steam
    if identifier == '' then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Could not find identifier for this player' })
        return
    end
    local expiresAt = nil
    if duration and duration > 0 then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + duration)
    end
    MySQL.insert('INSERT INTO bans (identifier, player_name, reason, banner, banner_cid, duration, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { identifier, GetPlayerName(targetId), reason or 'No reason', GetPlayerName(src), p.PlayerData.citizenid, duration or -1, expiresAt })
    DropPlayer(targetId, 'Banned: ' .. (reason or 'No reason'))
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Banned ' .. GetPlayerName(targetId) })
end)

RegisterNetEvent('god:server:executeUnban', function(banId)
    if not isOwner(source) or not banId then return end
    MySQL.query('DELETE FROM bans WHERE id = ?', { banId })
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Unban successful' })
end)

--- ==================== VEHICLE GARAGE VIEWER ====================
local function getVehicleStatus(garage, impounded)
    if impounded and impounded == 1 then return 'impounded' end
    if garage == 'out' or garage == '' then return 'out' end
    return 'stored'
end

lib.callback.register('god:server:getPlayerGarage', function(source, citizenid)
    if not isOwner(source) or not citizenid then return {} end
    local vehicles = MySQL.query.await('SELECT pv.*, iv.fee as impound_fee, iv.reason as impound_reason, iv.impound_time FROM player_vehicles pv LEFT JOIN impounded_vehicles iv ON pv.plate = iv.vehicle_plate AND iv.released = 0 WHERE pv.citizenid = ? ORDER BY pv.updated_at DESC', { citizenid })
    local result = {}
    for _, v in ipairs(vehicles or {}) do
        result[#result + 1] = {
            plate = v.plate,
            model = v.model or v.vehicle or 'Unknown',
            garage = v.garage or 'A',
            fuel = v.fuel or 100,
            status = getVehicleStatus(v.garage, v.released ~= nil and (1 - v.released) or nil),
            impound_fee = v.impound_fee,
            impound_reason = v.impound_reason,
            impound_time = v.impound_time,
            citizenid = v.citizenid,
        }
    end
    return result
end)

RegisterNetEvent('god:server:adminSpawnPlayerVehicle', function(citizenid, plate)
    if not isOwner(source) or not citizenid or not plate then return end
    local p = QBox.Functions.GetPlayerByCitizenId(citizenid)
    if p then
        TriggerClientEvent('god:client:spawnGarageVehicle', p.PlayerData.source, plate)
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Spawned vehicle for player' })
    else
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Player not online' })
    end
end)

RegisterNetEvent('god:server:adminDeletePlayerVehicle', function(plate)
    if not isOwner(source) or not plate then return end
    MySQL.query('DELETE FROM player_vehicles WHERE plate = ?', { plate })
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Vehicle ' .. plate .. ' deleted from database' })
end)

RegisterNetEvent('god:server:adminImpoundVehicle', function(citizenid, plate, reason)
    if not isOwner(source) or not citizenid or not plate then return end
    local p = QBox.Functions.GetPlayerByCitizenId(citizenid)
    if p then
        TriggerClientEvent('ox_lib:notify', p.PlayerData.source, { type = 'warning', description = 'Your vehicle ' .. plate .. ' has been impounded by an admin' })
    end
    MySQL.insert('INSERT INTO impounded_vehicles (vehicle_plate, citizenid, impound_time, fee, reason) VALUES (?, ?, UNIX_TIMESTAMP(), ?, ?)',
        { plate, citizenid, 0, reason or 'Admin impound' })
    MySQL.query('UPDATE player_vehicles SET garage = "impound" WHERE plate = ?', { plate })
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Vehicle ' .. plate .. ' impounded' })
end)

RegisterNetEvent('god:server:adminReleaseImpound', function(plate)
    if not isOwner(source) or not plate then return end
    MySQL.query('UPDATE impounded_vehicles SET released = 1 WHERE vehicle_plate = ? AND released = 0', { plate })
    MySQL.query('UPDATE player_vehicles SET garage = "A" WHERE plate = ?', { plate })
    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Vehicle ' .. plate .. ' released from impound' })
end)

--- ==================== STAFF MANAGEMENT ====================

local staffGroups = { 'admin', 'superadmin', 'god' }
local groupHierarchy = { user = 0, admin = 1, superadmin = 2, god = 3 }

lib.callback.register('god:server:getOnlineStaff', function(source)
    if not isOwner(source) then return {} end
    local players = QBox.Functions.GetPlayers()
    local staff = {}
    for _, src in ipairs(players or {}) do
        local p = QBox.Functions.GetPlayer(src)
        if p and p.PlayerData.group and groupHierarchy[p.PlayerData.group] and groupHierarchy[p.PlayerData.group] > 0 then
            local connectedTime = GetPlayerTime(src) or 0
            local hours = math.floor(connectedTime / 3600)
            local mins = math.floor((connectedTime % 3600) / 60)
            staff[#staff + 1] = {
                id = src,
                name = GetPlayerName(src),
                citizenid = p.PlayerData.citizenid,
                group = p.PlayerData.group,
                connected = hours .. 'h ' .. mins .. 'm',
            }
        end
    end
    table.sort(staff, function(a, b) return (groupHierarchy[b.group] or 0) < (groupHierarchy[a.group] or 0) end)
    return staff
end)

RegisterNetEvent('god:server:setStaffGroup', function(targetId, newGroup)
    local src = source
    if not isOwner(src) then return end
    local p = QBox.Functions.GetPlayer(src)
    local target = QBox.Functions.GetPlayer(targetId)
    if not p or not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    local myRank = groupHierarchy[p.PlayerData.group] or 0
    local targetRank = groupHierarchy[target.PlayerData.group] or 0
    local newRank = groupHierarchy[newGroup] or 0
    if myRank <= targetRank and p.PlayerData.group ~= 'god' then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You cannot manage someone of equal or higher rank' })
        return
    end
    if newRank >= myRank and p.PlayerData.group ~= 'god' then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You cannot promote to a rank equal or higher than your own' })
        return
    end
    target.Functions.SetGroup(newGroup)
    TriggerClientEvent('ox_lib:notify', targetId, { type = 'info', description = 'Your admin group has been changed to ' .. newGroup, duration = 5000 })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Changed ' .. GetPlayerName(targetId) .. ' to ' .. newGroup })
end)

lib.callback.register('god:server:getStaffActionLog', function(source, citizenid, limit)
    if not isOwner(source) then return {} end
    local logs = MySQL.query.await('SELECT * FROM admin_logs WHERE admin_cid = ? ORDER BY created_at DESC LIMIT ?', { citizenid, limit or 50 })
    return logs or {}
end)

--- ==================== REPORT QUEUE ====================

local activeReports = {}

-- Hook into report submissions to track them locally
AddEventHandler('report:server:submit', function(reason)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local report = {
        id = #activeReports + 1,
        playerSrc = src,
        playerName = p.PlayerData.charinfo and (p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname) or GetPlayerName(src),
        citizenid = p.PlayerData.citizenid,
        reason = reason or 'No reason',
        status = 'open',
        handledBy = nil,
        handlerName = nil,
    }
    activeReports[report.id] = report
    -- Push live update to all god-menu users
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        TriggerClientEvent('god:client:newReport', s, report)
    end
end)

lib.callback.register('god:server:getReports', function(source)
    if not isOwner(source) then return {} end
    local result = {}
    for _, r in pairs(activeReports) do
        if r.status ~= 'closed' then
            table.insert(result, r)
        end
    end
    return result
end)

RegisterNetEvent('god:server:acceptReport', function(reportId)
    local src = source
    if not isOwner(src) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local report = activeReports[reportId]
    if report and report.status == 'open' then
        report.status = 'handling'
        report.handledBy = src
        report.handlerName = GetPlayerName(src)
        TriggerClientEvent('ox_lib:notify', report.playerSrc, { type = 'info', description = 'Staff ' .. GetPlayerName(src) .. ' is handling your report #' .. reportId })
        -- Push update
        local players = QBox.Functions.GetPlayers()
        for _, s in ipairs(players) do
            TriggerClientEvent('god:client:updateReport', s, report)
        end
    end
end)

RegisterNetEvent('god:server:closeReport', function(reportId, resolution)
    local src = source
    if not isOwner(src) then return end
    local report = activeReports[reportId]
    if report and report.status ~= 'closed' then
        report.status = 'closed'
        report.resolution = resolution or 'No resolution'
        TriggerClientEvent('ox_lib:notify', report.playerSrc, { type = 'success', description = 'Your report #' .. reportId .. ' has been closed: ' .. (resolution or 'No resolution') })
        local players = QBox.Functions.GetPlayers()
        for _, s in ipairs(players) do
            TriggerClientEvent('god:client:removeReport', s, reportId)
        end
    end
end)
