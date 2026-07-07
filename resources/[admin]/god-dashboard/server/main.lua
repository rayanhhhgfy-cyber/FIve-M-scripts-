local QBox = exports['qbx_core']:GetCoreObject()

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.GodDashboard.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

--- Bunkers
QBox.Functions.CreateCallback('god-dashboard:getBunkers', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    local bunkers = exports['bunker-builder']:GetAllBunkers() or {}
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
    local bunker = exports['bunker-builder']:GetBunker(id)
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
