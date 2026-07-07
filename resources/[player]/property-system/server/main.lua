local QBox = exports['qbx_core']:GetCoreObject()
local propertyOwners = {}

Citizen.CreateThread(function()
    local rows = MySQL.query.await('SELECT property_id, citizenid FROM player_properties')
    if rows then
        for _, r in ipairs(rows) do
            propertyOwners[r.property_id] = r.citizenid
        end
    end
end)

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.Properties.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

RegisterNetEvent('property:server:buy', function(propertyId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local prop = nil
    for _, p in ipairs(Config.Properties.properties) do
        if p.id == propertyId then prop = p end
    end
    if not prop then return end
    if propertyOwners[propertyId] then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already owned' })
        return end
    local balance = exports['Renewed-Banking']:GetBalance(player.PlayerData.citizenid)
    if balance < prop.price then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need $' .. prop.price })
        return end
    exports['Renewed-Banking']:RemoveMoney(nil, prop.price, 'Property: ' .. prop.label)
    propertyOwners[propertyId] = player.PlayerData.citizenid
    MySQL.insert('INSERT INTO player_properties (citizenid, property_id) VALUES (?, ?)', { player.PlayerData.citizenid, propertyId })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bought ' .. prop.label .. ' for $' .. prop.price })
end)

RegisterNetEvent('property:server:sell', function(propertyId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local prop = nil
    for _, p in ipairs(Config.Properties.properties) do
        if p.id == propertyId then prop = p end
    end
    if not prop then return end
    if propertyOwners[propertyId] ~= player.PlayerData.citizenid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not your property' })
        return end
    local sellPrice = math.floor(prop.price * 0.6)
    exports['Renewed-Banking']:AddMoney(nil, player.PlayerData.citizenid, sellPrice, 'Property sale: ' .. prop.label)
    propertyOwners[propertyId] = nil
    MySQL.query('DELETE FROM player_properties WHERE property_id = ? AND citizenid = ?', { propertyId, player.PlayerData.citizenid })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Sold ' .. prop.label .. ' for $' .. sellPrice })
end)

RegisterNetEvent('property:server:getOwned', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local rows = MySQL.query.await('SELECT property_id FROM player_properties WHERE citizenid = ?', { player.PlayerData.citizenid })
    local result = {}
    if rows then
        for _, r in ipairs(rows) do
            table.insert(result, r.property_id)
        end
    end
    TriggerClientEvent('property:client:ownedList', src, result)
end)

QBox.Functions.CreateCallback('property:server:list', function(source, cb)
    cb(Config.Properties.properties)
end)

QBox.Functions.CreateCallback('property:server:getOwner', function(source, cb, propertyId)
    cb(propertyOwners[propertyId] or nil)
end)

QBox.Commands.Add('properties', 'List available properties', {}, false, function(source)
    TriggerClientEvent('property:client:openMenu', source)
end)
