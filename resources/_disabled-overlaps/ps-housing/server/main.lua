local QBCore = exports['qbx_core']:GetCoreObject()
local playerHouses = {}
local houseCache = {}

local function GeneratePropertyId()
    return 'PROP-' .. string.format('%06d', math.random(999999))
end

function GetPlayerHouses(citizenId)
    if houseCache[citizenId] then
        local age = GetGameTimer() - houseCache[citizenId].timestamp
        if age < 30000 then return houseCache[citizenId].houses end
    end
    local result = MySQL.query.await(
        'SELECT * FROM player_houses WHERE citizenid = ? OR JSON_CONTAINS(keys, ?)',
        { citizenId, '"' .. citizenId .. '"' }
    )
    local houses = {}
    for _, row in ipairs(result or {}) do
        row.keys = json.decode(row.keys or '[]')
        row.furniture = json.decode(row.furniture or '[]')
        houses[#houses + 1] = row
    end
    houseCache[citizenId] = { houses = houses, timestamp = GetGameTimer() }
    return houses
end

function GetHouse(propertyId)
    local result = MySQL.query.await('SELECT * FROM player_houses WHERE property_id = ? LIMIT 1', { propertyId })
    if result and #result > 0 then
        local house = result[1]
        house.keys = json.decode(house.keys or '[]')
        house.furniture = json.decode(house.furniture or '[]')
        return house
    end
    return nil
end

local function PurchaseHouse(citizenId, locationName)
    local houses = GetPlayerHouses(citizenId)
    if #houses >= Config.Housing.maxProperties then
        return false, 'Maximum properties owned'
    end
    local location = nil
    for _, loc in ipairs(Config.HousingLocations) do
        if loc.name == locationName then
            location = loc
            break
        end
    end
    if not location then return false, 'Invalid location' end
    local shell = Config.Shells[location.shell]
    if not shell then return false, 'Invalid shell type' end
    local propertyId = GeneratePropertyId()
    MySQL.insert.await(
        'INSERT INTO player_houses (citizenid, property_id, label, shell_id, price, coords, entrance, exit_coords) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        { citizenId, propertyId, location.name, location.shell, shell.price, json.encode(location.coords), json.encode(location.entrance), json.encode(location.exit) }
    )
    houseCache[citizenId] = nil
    return true, propertyId
end

local function AddKey(propertyId, targetCitizenId)
    local house = GetHouse(propertyId)
    if not house then return false, 'House not found' end
    if #house.keys >= Config.Housing.maxKeys then return false, 'Max keys reached' end
    for _, key in ipairs(house.keys) do
        if key == targetCitizenId then return false, 'Already has a key' end
    end
    table.insert(house.keys, targetCitizenId)
    MySQL.update.await('UPDATE player_houses SET keys = ? WHERE id = ?', { json.encode(house.keys), house.id })
    houseCache[house.citizenid] = nil
    houseCache[targetCitizenId] = nil
    return true
end

local function RemoveKey(propertyId, targetCitizenId)
    local house = GetHouse(propertyId)
    if not house then return false end
    local newKeys = {}
    for _, key in ipairs(house.keys) do
        if key ~= targetCitizenId then table.insert(newKeys, key) end
    end
    MySQL.update.await('UPDATE player_houses SET keys = ? WHERE id = ?', { json.encode(newKeys), house.id })
    houseCache[house.citizenid] = nil
    houseCache[targetCitizenId] = nil
    return true
end

local function SetFurniture(propertyId, furniture)
    if type(furniture) ~= 'string' then
        furniture = json.encode(furniture)
    end
    MySQL.update.await('UPDATE player_houses SET furniture = ? WHERE property_id = ?', { furniture, propertyId })
end

local function ToggleLock(propertyId, shouldLock)
    MySQL.update.await('UPDATE player_houses SET is_locked = ? WHERE property_id = ?', { shouldLock and 1 or 0, propertyId })
end

lib.callback.register('ps-housing:server:getHouses', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return {} end
    return GetPlayerHouses(player.PlayerData.citizenid)
end)

lib.callback.register('ps-housing:server:getHouse', function(source, propertyId)
    return GetHouse(propertyId)
end)

lib.callback.register('ps-housing:server:purchase', function(source, locationName)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end
    local location = nil
    for _, loc in ipairs(Config.HousingLocations) do
        if loc.name == locationName then
            location = loc
            break
        end
    end
    if not location then return false, 'Invalid location' end
    local shell = Config.Shells[location.shell]
    local price = shell.price
    if player.PlayerData.money.bank < price then
        return false, 'Insufficient funds'
    end
    player.Functions.RemoveMoney('bank', price)
    local success, result = PurchaseHouse(player.PlayerData.citizenid, locationName)
    if success then
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Purchased ' .. locationName })
    end
    return success, result
end)

lib.callback.register('ps-housing:server:addKey', function(source, propertyId, targetCitizenId)
    return AddKey(propertyId, targetCitizenId)
end)

lib.callback.register('ps-housing:server:removeKey', function(source, propertyId, targetCitizenId)
    return RemoveKey(propertyId, targetCitizenId)
end)

lib.callback.register('ps-housing:server:toggleLock', function(source, propertyId)
    local house = GetHouse(propertyId)
    if not house then return false end
    local newLockState = not house.is_locked
    ToggleLock(propertyId, newLockState)
    return newLockState
end)

lib.callback.register('ps-housing:server:saveFurniture', function(source, propertyId, furniture)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    SetFurniture(propertyId, furniture)
    return true
end)

lib.callback.register('ps-housing:server:getLocations', function(source)
    return Config.HousingLocations
end)

lib.callback.register('ps-housing:server:canAccess', function(source, propertyId)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    local house = GetHouse(propertyId)
    if not house then return false end
    if house.citizenid == player.PlayerData.citizenid then return true end
    for _, key in ipairs(house.keys) do
        if key == player.PlayerData.citizenid then return true end
    end
    return false
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[ps-housing] Housing system initialized. %d locations available.^7', #Config.HousingLocations)
end)

exports('GetHouse', GetHouse)
exports('GetPlayerHouses', GetPlayerHouses)
exports('HasAccess', function(citizenId, propertyId)
    local house = GetHouse(propertyId)
    if not house then return false end
    return house.citizenid == citizenId
end)
