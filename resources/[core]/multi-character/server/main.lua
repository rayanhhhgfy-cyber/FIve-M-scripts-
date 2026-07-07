local QBCore = exports['qbx_core']:GetCoreObject()
local playerSessions = {}

function GenerateCitizenId()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local id = ''
    for i = 1, 8 do
        id = id .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    return 'QB' .. id
end

local function GeneratePhoneNumber()
    local areaCode = math.random(200, 999)
    local prefix = math.random(200, 999)
    local line = math.random(1000, 9999)
    return tostring(areaCode) .. tostring(prefix) .. tostring(line)
end

function GetCharacters(license)
    local result = MySQL.query.await('SELECT * FROM player_chars WHERE license = ? ORDER BY slot ASC', { license })
    return result or {}
end

local function GetCharacterBySlot(license, slot)
    local result = MySQL.query.await('SELECT * FROM player_chars WHERE license = ? AND slot = ? LIMIT 1', { license, slot })
    if result and #result > 0 then
        return result[1]
    end
    return nil
end

local function CreateCharacter(license, slot, data)
    local citizenid = GenerateCitizenId()
    local phone = GeneratePhoneNumber()
    local money = json.encode(Config.Character.defaultMoney)
    local job = json.encode(Config.Character.defaultJob)
    local gang = json.encode(Config.Character.defaultGang)
    local position = json.encode(Config.Character.spawnLocations[1].coords)
    local metadata = json.encode(Config.DefaultMetadata)
    local charinfo = json.encode({
        firstname = data.firstname,
        lastname = data.lastname,
        birthdate = data.birthdate or '1990-01-01',
        gender = data.gender or 0,
        nationality = data.nationality or 'American',
        phone = phone,
        account = 0
    })
    MySQL.insert.await(
        'INSERT INTO player_chars (license, citizenid, slot, firstname, lastname, dob, gender, phone, money, job, gang, position, metadata, charinfo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { license, citizenid, slot, data.firstname, data.lastname, data.birthdate or '1990-01-01', data.gender or 0, phone, money, job, gang, position, metadata, charinfo }
    )
    return citizenid
end

local function DeleteCharacter(license, slot)
    local char = GetCharacterBySlot(license, slot)
    if not char then return false end
    MySQL.query.await('DELETE FROM player_chars WHERE citizenid = ?', { char.citizenid })
    MySQL.query.await('DELETE FROM players WHERE citizenid = ?', { char.citizenid })
    return true
end

local function SelectCharacter(source, citizenid)
    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then return false end
    MySQL.query.await('UPDATE player_chars SET is_active = FALSE WHERE license = ?', { license })
    MySQL.query.await('UPDATE player_chars SET is_active = TRUE WHERE citizenid = ?', { citizenid })
    exports['qbx_core']:CreatePlayer(source, citizenid)
    playerSessions[source] = { citizenid = citizenid, license = license }
    return true
end

local function GiveStarterItems(source)
    Citizen.Wait(2000)
    for _, item in ipairs(Config.Character.starterItems) do
        exports['ox_inventory']:AddItem(source, item.name, item.count)
    end
end

lib.callback.register('multi-character:server:getCharacters', function(source)
    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then return {} end
    return GetCharacters(license)
end)

lib.callback.register('multi-character:server:createCharacter', function(source, data)
    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then return false, 'License not found' end
    local characters = GetCharacters(license)
    if #characters >= Config.Character.maxSlots then
        return false, string.format(Locales['char_max_slots'], Config.Character.maxSlots)
    end
    if not data.firstname or not data.lastname or data.firstname == '' or data.lastname == '' then
        return false, 'First and last name required'
    end
    if #data.firstname < 2 or #data.lastname < 2 then
        return false, 'Names must be at least 2 characters'
    end
    local nextSlot = #characters + 1
    local citizenid = CreateCharacter(license, nextSlot, data)
    local success = SelectCharacter(source, citizenid)
    if success then
        GiveStarterItems(source)
    end
    return success, 'Character created'
end)

lib.callback.register('multi-character:server:selectCharacter', function(source, citizenid)
    if not citizenid or type(citizenid) ~= 'string' then return false end
    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then return false end
    local chars = GetCharacters(license)
    local found = false
    for _, char in ipairs(chars) do
        if char.citizenid == citizenid then
            found = true
            break
        end
    end
    if not found then return false end
    return SelectCharacter(source, citizenid)
end)

lib.callback.register('multi-character:server:deleteCharacter', function(source, slot)
    if not Config.Character.allowDelete then return false, 'Deletion disabled' end
    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then return false, 'License not found' end
    slot = tonumber(slot)
    if not slot or slot < 1 or slot > Config.Character.maxSlots then return false, 'Invalid slot' end
    local char = GetCharacterBySlot(license, slot)
    if not char then return false, 'No character in this slot' end
    local success = DeleteCharacter(license, slot)
    if success then
        local remaining = GetCharacters(license)
        for i, c in ipairs(remaining) do
            MySQL.query.await('UPDATE player_chars SET slot = ? WHERE citizenid = ?', { i, c.citizenid })
        end
    end
    return success, success and 'Character deleted' or 'Deletion failed'
end)

lib.callback.register('multi-character:server:getSpawnLocations', function(source)
    return Config.Character.spawnLocations
end)

lib.callback.register('multi-character:server:getMaxSlots', function(source)
    return Config.Character.maxSlots
end)

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    deferrals.update('Loading character data...')
    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then
        deferrals.done('License identifier not found')
        return
    end
    local chars = GetCharacters(license)
    deferrals.done()
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    if playerSessions[source] then
        playerSessions[source] = nil
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[multi-character] Character system initialized. Max %d slots per player.^7', Config.Character.maxSlots)
end)

exports('GetCharacters', GetCharacters)
exports('GetCharacterCount', function(source)
    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then return 0 end
    local chars = GetCharacters(license)
    return #chars
end)
exports('GenerateCitizenId', GenerateCitizenId)
