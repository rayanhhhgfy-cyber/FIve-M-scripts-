local QBox = exports['qbx_core']:GetCoreObject()
local ownedHouses = {}
local houseFurniture = {}
local houseGuests = {}
local houseAlarms = {}

local function isAdmin(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    for _, g in ipairs(Config.AdvancedHousing.adminGroups) do
        if p.PlayerData.group == g then return true end
    end
    return false
end

local function getHouse(houseId)
    for _, h in ipairs(Config.AdvancedHousing.properties) do
        if h.id == houseId then return h end
    end
    return nil
end

local function hasAccess(src, houseId)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    local cid = p.PlayerData.citizenid
    if ownedHouses[houseId] and ownedHouses[houseId].owner == cid then return true end
    if houseGuests[houseId] then
        for _, g in ipairs(houseGuests[houseId]) do
            if g.cid == cid then return true end
        end
    end
    return isAdmin(src)
end

MySQL.ready(function()
    local houses = MySQL.query.await('SELECT * FROM player_houses')
    for _, h in ipairs(houses) do
        ownedHouses[h.house_id] = { owner = h.owner_cid, ownerName = h.owner_name, purchased = h.purchased_at }
    end
    local furn = MySQL.query.await('SELECT * FROM house_furniture')
    for _, f in ipairs(furn) do
        if not houseFurniture[f.house_id] then houseFurniture[f.house_id] = {} end
        table.insert(houseFurniture[f.house_id], { id = f.id, furnId = f.furniture_id, coords = json.decode(f.coords), rotation = json.decode(f.rotation) })
    end
    local guests = MySQL.query.await('SELECT * FROM house_guests')
    for _, g in ipairs(guests) do
        if not houseGuests[g.house_id] then houseGuests[g.house_id] = {} end
        table.insert(houseGuests[g.house_id], { cid = g.guest_cid, name = g.guest_name })
    end
    local alarms = MySQL.query.await('SELECT * FROM house_alarms')
    for _, a in ipairs(alarms) do
        houseAlarms[a.house_id] = { active = a.active == 1, level = a.level, armed = a.armed == 1 }
    end
end)

RegisterNetEvent('housing:buy', function(houseId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p or not houseId then return end
    local house = getHouse(houseId)
    if not house then TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Invalid property' }) return end
    if ownedHouses[houseId] then TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already owned' }) return end
    local cid = p.PlayerData.citizenid
    if p.Functions.RemoveMoney('bank', house.price) then
        ownedHouses[houseId] = { owner = cid, ownerName = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname, purchased = os.time() }
        MySQL.insert('INSERT INTO player_houses (house_id, owner_cid, owner_name, purchased_at) VALUES (?, ?, ?, ?)', { houseId, cid, ownedHouses[houseId].ownerName, os.time() })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Purchased ' .. house.name .. ' for $' .. house.price })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough money' })
    end
end)

RegisterNetEvent('housing:sell', function(houseId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p or not houseId then return end
    local house = getHouse(houseId)
    if not house then return end
    local owner = ownedHouses[houseId]
    if not owner or owner.owner ~= p.PlayerData.citizenid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not your property' })
        return
    end
    local refund = math.floor(house.price * Config.AdvancedHousing.sellRefundPercent)
    p.Functions.AddMoney('bank', refund)
    MySQL.update('DELETE FROM player_houses WHERE house_id = ?', { houseId })
    MySQL.update('DELETE FROM house_furniture WHERE house_id = ?', { houseId })
    MySQL.update('DELETE FROM house_guests WHERE house_id = ?', { houseId })
    MySQL.update('DELETE FROM house_alarms WHERE house_id = ?', { houseId })
    ownedHouses[houseId] = nil
    houseFurniture[houseId] = nil
    houseGuests[houseId] = nil
    houseAlarms[houseId] = nil
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Sold for $' .. refund .. ' (60%)' })
end)

QBox.Functions.CreateCallback('housing:getOwned', function(source, cb)
    local p = QBox.Functions.GetPlayer(source)
    if not p then cb({}) return end
    local result = {}
    for id, info in pairs(ownedHouses) do
        if info.owner == p.PlayerData.citizenid then
            local house = getHouse(id)
            table.insert(result, { id = id, name = house and house.name or id, purchased = info.purchased })
        end
    end
    cb(result)
end)

QBox.Functions.CreateCallback('housing:getFurniture', function(source, houseId, cb)
    cb(houseFurniture[houseId] or {})
end)

RegisterNetEvent('housing:placeFurniture', function(houseId, furnId, coords, rotation)
    local src = source
    if not hasAccess(src, houseId) then return end
    local furnConfig = nil
    for _, f in ipairs(Config.AdvancedHousing.furniture) do
        if f.id == furnId then furnConfig = f; break end
    end
    if not furnConfig then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    if not p.Functions.RemoveMoney('bank', furnConfig.price) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Cannot afford $' .. furnConfig.price })
        return
    end
    local id = MySQL.insert.await('INSERT INTO house_furniture (house_id, furniture_id, coords, rotation) VALUES (?, ?, ?, ?)', { houseId, furnId, json.encode(coords), json.encode(rotation) })
    if not houseFurniture[houseId] then houseFurniture[houseId] = {} end
    table.insert(houseFurniture[houseId], { id = id, furnId = furnId, coords = coords, rotation = rotation })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = furnConfig.name .. ' placed' })
    TriggerClientEvent('housing:refreshFurniture', -1, houseId, houseFurniture[houseId])
end)

RegisterNetEvent('housing:removeFurniture', function(houseId, furnDbId)
    local src = source
    if not hasAccess(src, houseId) then return end
    if not houseFurniture[houseId] then return end
    for i, f in ipairs(houseFurniture[houseId]) do
        if f.id == furnDbId then
            local refund = 0
            for _, fc in ipairs(Config.AdvancedHousing.furniture) do
                if fc.id == f.furnId then refund = math.floor(fc.price * 0.5); break end
            end
            local p = QBox.Functions.GetPlayer(src)
            if p then p.Functions.AddMoney('bank', refund) end
            table.remove(houseFurniture[houseId], i)
            MySQL.update('DELETE FROM house_furniture WHERE id = ?', { furnDbId })
            TriggerClientEvent('housing:refreshFurniture', -1, houseId, houseFurniture[houseId])
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Furniture removed ($' .. refund .. ' refund)' })
            return
        end
    end
end)

RegisterNetEvent('housing:guestAdd', function(houseId, targetCid, targetName)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local owner = ownedHouses[houseId]
    if not owner or owner.owner ~= p.PlayerData.citizenid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not your property' })
        return
    end
    if p.Functions.RemoveMoney('bank', Config.AdvancedHousing.guestKeyPrice) then
        if not houseGuests[houseId] then houseGuests[houseId] = {} end
        table.insert(houseGuests[houseId], { cid = targetCid, name = targetName })
        MySQL.insert('INSERT INTO house_guests (house_id, guest_cid, guest_name) VALUES (?, ?, ?)', { houseId, targetCid, targetName })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = targetName .. ' added as guest ($' .. Config.AdvancedHousing.guestKeyPrice .. ')' })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough money for key' })
    end
end)

RegisterNetEvent('housing:guestRemove', function(houseId, targetCid)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local owner = ownedHouses[houseId]
    if not owner or owner.owner ~= p.PlayerData.citizenid then return end
    if houseGuests[houseId] then
        for i, g in ipairs(houseGuests[houseId]) do
            if g.cid == targetCid then
                table.remove(houseGuests[houseId], i)
                MySQL.update('DELETE FROM house_guests WHERE house_id = ? AND guest_cid = ?', { houseId, targetCid })
                TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Guest removed' })
                return
            end
        end
    end
end)

RegisterNetEvent('housing:installAlarm', function(houseId, level)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local owner = ownedHouses[houseId]
    if not owner or owner.owner ~= p.PlayerData.citizenid then return end
    local price = Config.AdvancedHousing.alarm.prices.install
    local alarmConfig = Config.AdvancedHousing.alarm.securityLevels[level]
    if not alarmConfig then return end
    if p.Functions.RemoveMoney('bank', price) then
        houseAlarms[houseId] = { active = true, level = level, armed = false }
        MySQL.insert('INSERT INTO house_alarms (house_id, active, level, armed) VALUES (?, 1, ?, 0) ON DUPLICATE KEY UPDATE active = 1, level = ?', { houseId, level, level })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Alarm installed ($' .. price .. ')' })
    end
end)

RegisterNetEvent('housing:toggleAlarm', function(houseId)
    local src = source
    if not hasAccess(src, houseId) then return end
    if not houseAlarms[houseId] then return end
    houseAlarms[houseId].armed = not houseAlarms[houseId].armed
    MySQL.update('UPDATE house_alarms SET armed = ? WHERE house_id = ?', { houseAlarms[houseId].armed and 1 or 0, houseId })
    TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Alarm ' .. (houseAlarms[houseId].armed and 'armed' or 'disarmed') })
end)

RegisterNetEvent('housing:storeVehicle', function(houseId, plate, model)
    local src = source
    if not hasAccess(src, houseId) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local house = getHouse(houseId)
    if not house then return end
    local existing = MySQL.query.await('SELECT COUNT(*) as count FROM house_vehicles WHERE house_id = ?', { houseId })
    if existing[1] and existing[1].count >= house.garageSlots then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Garage full (' .. house.garageSlots .. ' slots)' })
        return
    end
    MySQL.insert('INSERT INTO house_vehicles (house_id, plate, model, stored_by) VALUES (?, ?, ?, ?)', { houseId, plate, model, p.PlayerData.citizenid })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Vehicle stored' })
end)

RegisterNetEvent('housing:retrieveVehicle', function(houseId, plate)
    local src = source
    if not hasAccess(src, houseId) then return end
    MySQL.update('DELETE FROM house_vehicles WHERE house_id = ? AND plate = ?', { houseId, plate })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Vehicle retrieved' })
end)

QBox.Functions.CreateCallback('housing:getStoredVehicles', function(source, houseId, cb)
    if not hasAccess(source, houseId) then cb({}) return end
    local vehicles = MySQL.query.await('SELECT * FROM house_vehicles WHERE house_id = ?', { houseId })
    cb(vehicles or {})
end)

QBox.Functions.CreateCallback('housing:getGuests', function(source, houseId, cb)
    local p = QBox.Functions.GetPlayer(source)
    if not p then cb({}) return end
    local owner = ownedHouses[houseId]
    if not owner or owner.owner ~= p.PlayerData.citizenid then cb({}) return end
    cb(houseGuests[houseId] or {})
end)

QBox.Functions.CreateCallback('housing:getAlarmState', function(source, houseId, cb)
    cb(houseAlarms[houseId] or { active = false, armed = false })
end)

QBox.Functions.CreateCallback('housing:hasAccess', function(source, houseId, cb)
    cb(hasAccess(source, houseId))
end)

QBox.Functions.CreateCallback('housing:getFurnitureCatalog', function(source, cb)
    cb(Config.AdvancedHousing.furniture)
end)
