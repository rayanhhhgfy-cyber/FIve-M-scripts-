local QBox = exports['qbx_core']:GetCoreObject()
local playerSaves = {}
local activeSessions = {}

local function getLicense(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.find(id, 'license:') then return id end
    end
    return QBox.Functions.GetIdentifier(src)
end

RegisterNetEvent('character:requestCharacters', function()
    local src = source
    local license = getLicense(src)
    if not license then
        TriggerClientEvent('character:receiveCharacters', src, {})
        return
    end
    local rows = MySQL.query.await('SELECT citizenid, firstname, lastname, gender, birthdate, last_location, played_hours, created_at FROM characters WHERE license = ? ORDER BY created_at ASC', { license })
    if not rows then rows = {} end
    TriggerClientEvent('character:receiveCharacters', src, rows)
end)

RegisterNetEvent('character:createCharacter', function(data)
    local src = source
    local license = getLicense(src)
    if not license then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Could not identify you' })
        return
    end
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM characters WHERE license = ?', { license })
    if count >= Config.CharacterSystem.maxCharacters then
        TriggerClientEvent('character:creationFailed', src, 'Maximum of ' .. Config.CharacterSystem.maxCharacters .. ' characters reached')
        return
    end
    local maxCid = MySQL.scalar.await('SELECT MAX(CAST(citizenid AS UNSIGNED)) FROM characters') or 10000
    local citizenid = tostring(maxCid + 1)
    local firstname = data.firstname:sub(1, 1):upper() .. data.firstname:sub(2):lower()
    local lastname = data.lastname:sub(1, 1):upper() .. data.lastname:sub(2):lower()
    local insertId = MySQL.insert.await('INSERT INTO characters (license, citizenid, firstname, lastname, gender, birthdate, cash, bank) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        license, citizenid, firstname, lastname, data.gender, data.birthdate,
        Config.CharacterSystem.newCharacterDefaults.cash,
        Config.CharacterSystem.newCharacterDefaults.bank,
    })
    if insertId then
        -- Link to qbx_core players table
        local existingPlayer = MySQL.single.await('SELECT citizenid FROM players WHERE citizenid = ?', { citizenid })
        if not existingPlayer then
            MySQL.insert('INSERT INTO players (citizenid, license, firstname, lastname, gender, birthdate, cash, bank) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
                citizenid, license, firstname, lastname, data.gender, data.birthdate,
                Config.CharacterSystem.newCharacterDefaults.cash,
                Config.CharacterSystem.newCharacterDefaults.bank,
            })
        end
        MySQL.insert('INSERT INTO cid_registry (license, citizenid, slot) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE slot = slot', { license, citizenid, count + 1 })
        local newChar = MySQL.single.await('SELECT citizenid, firstname, lastname, gender, birthdate, last_location, played_hours FROM characters WHERE citizenid = ?', { citizenid })
        TriggerClientEvent('character:characterCreated', src, newChar)
    else
        TriggerClientEvent('character:creationFailed', src, 'Failed to create character')
    end
end)

RegisterNetEvent('character:selectCharacter', function(citizenid, spawnType, customCoords)
    local src = source
    local license = getLicense(src)
    if not license then return end
    local char = MySQL.single.await('SELECT * FROM characters WHERE citizenid = ? AND license = ?', { citizenid, license })
    if not char then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Character not found' })
        return
    end
    -- Load into qbx_core
    local player = QBox.Functions.GetPlayer(src)
    if player then
        player.PlayerData.citizenid = citizenid
        player.PlayerData.charinfo.firstname = char.firstname
        player.PlayerData.charinfo.lastname = char.lastname
        player.PlayerData.charinfo.birthdate = char.birthdate
        player.PlayerData.charinfo.gender = char.gender
        player.PlayerData.money.cash = char.cash or Config.CharacterSystem.newCharacterDefaults.cash
        player.PlayerData.money.bank = char.bank or Config.CharacterSystem.newCharacterDefaults.bank
    end
    Player(src).state:set('cid', citizenid, true)
    activeSessions[src] = { citizenid = citizenid, joined = os.time() }

    -- Determine spawn coords
    local spawnCoords = nil
    if spawnType == 'last' and char.last_location then
        local parsed = json.decode(char.last_location)
        if parsed and parsed.x then spawnCoords = parsed end
    elseif spawnType == 'custom' and customCoords then
        spawnCoords = customCoords
    end
    if not spawnCoords then
        local spawnDef = Config.CharacterSystem.spawnLocations[spawnType]
        if spawnDef and spawnDef.coords then
            spawnCoords = spawnDef.coords
        else
            spawnCoords = Config.CharacterSystem.defaultSpawn
        end
    end
    TriggerClientEvent('character:spawnPlayer', src, citizenid, spawnCoords)
    -- Grant starter items
    local idCount = exports.ox_inventory:GetItemCount(src, 'id_card', nil, true)
    if idCount == 0 then
        exports.ox_inventory:AddItem(src, 'id_card', 1, {
            label = 'State Identification Card',
            description = 'Official Los Santos ID Card',
            info = { firstname = char.firstname, lastname = char.lastname, cid = citizenid, dob = char.birthdate, issued = os.date('%Y-%m-%d') },
        })
    end
    -- Update last login
    MySQL.update('UPDATE characters SET last_login = NOW() WHERE citizenid = ?', { citizenid })
end)

RegisterNetEvent('character:savePosition', function(coords)
    local src = source
    local session = activeSessions[src]
    if not session then return end
    playerSaves[session.citizenid] = { x = coords.x, y = coords.y, z = coords.z, heading = coords.heading or 0.0 }
end)

RegisterNetEvent('character:updatePlayTime', function()
    local src = source
    local session = activeSessions[src]
    if not session then return end
    local elapsed = os.time() - session.joined
    local hours = math.floor(elapsed / 3600)
    MySQL.update('UPDATE characters SET played_hours = played_hours + ?, last_location = ? WHERE citizenid = ?', { hours, json.encode(playerSaves[session.citizenid]), session.citizenid })
end)

-- Save on disconnect
AddEventHandler('playerDropped', function(reason)
    local src = source
    local session = activeSessions[src]
    if session then
        local save = playerSaves[session.citizenid]
        if save then
            MySQL.update('UPDATE characters SET last_location = ?, last_seen = NOW() WHERE citizenid = ?', { json.encode(save), session.citizenid })
        end
        local elapsed = os.time() - session.joined
        local hours = math.floor(elapsed / 3600)
        MySQL.update('UPDATE characters SET played_hours = played_hours + ? WHERE citizenid = ?', { hours, session.citizenid })
        activeSessions[src] = nil
    end
end)

-- Periodic save
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.CharacterSystem.saveInterval)
        for src, session in pairs(activeSessions) do
            TriggerClientEvent('character:saveMyPosition', src)
        end
    end
end)

QBox.Functions.CreateCallback('character:getSpawnLocations', function(source, cb)
    cb(Config.CharacterSystem.spawnLocations)
end)

lib.callback.register('character:getJobSpawns', function(source, citizenid)
    if not citizenid then return {} end
    local roster = MySQL.single.await('SELECT job FROM job_rosters WHERE citizenid = ?', { citizenid })
    if not roster or not roster.job then return {} end
    local jobLocations = Config.CharacterSystem.SpawnMap.jobs[roster.job]
    return jobLocations or {}
end)

QBox.Commands.Add('chars', 'Open character selection', {}, false, function(source)
    TriggerClientEvent('character:openSelector', source)
end)
