local QBCore = exports['qbx_core']:GetCoreObject()

--- ==================== ZONE CRUD ====================

lib.callback.register('admin-zones:server:getActiveZones', function(source)
    local zones = MySQL.query.await('SELECT * FROM admin_zones WHERE is_active = 1 ORDER BY name ASC')
    local result = {}
    for _, z in ipairs(zones or {}) do
        result[#result + 1] = {
            id = z.id,
            name = z.name,
            zone_type = z.zone_type,
            coords = json.decode(z.coords),
            radius = z.radius,
            allowed_jobs = z.allowed_jobs and json.decode(z.allowed_jobs) or {},
            min_grade = z.min_grade,
            require_duty = z.require_duty,
            is_active = z.is_active,
            created_by = z.created_by,
        }
    end
    return result
end)

lib.callback.register('admin-zones:server:getAllZones', function(source)
    local p = QBCore.Functions.GetPlayer(source)
    if not p then return {} end
    local cid = p.PlayerData.citizenid
    local zones = MySQL.query.await('SELECT * FROM admin_zones ORDER BY name ASC')
    local result = {}
    for _, z in ipairs(zones or {}) do
        result[#result + 1] = {
            id = z.id,
            name = z.name,
            zone_type = z.zone_type,
            coords = json.decode(z.coords),
            radius = z.radius,
            allowed_jobs = z.allowed_jobs and json.decode(z.allowed_jobs) or {},
            min_grade = z.min_grade,
            require_duty = z.require_duty,
            is_active = z.is_active,
            created_by = z.created_by,
            created_at = z.created_at,
        }
    end
    return result
end)

RegisterNetEvent('admin-zones:server:createZone', function(name, zoneType, coords, radius, allowedJobs, minGrade, requireDuty)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    local coordsJson = json.encode(coords)
    local jobsJson = allowedJobs and json.encode(allowedJobs) or '[]'
    local id = MySQL.insert.await(
        'INSERT INTO admin_zones (name, zone_type, coords, radius, allowed_jobs, min_grade, require_duty, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        { name, zoneType, coordsJson, radius or 2.0, jobsJson, minGrade or 0, requireDuty or 0, cid }
    )
    if id then
        local newZone = MySQL.single.await('SELECT * FROM admin_zones WHERE id = ?', { id })
        if newZone then
            local zoneData = {
                id = newZone.id,
                name = newZone.name,
                zone_type = newZone.zone_type,
                coords = json.decode(newZone.coords),
                radius = newZone.radius,
                allowed_jobs = newZone.allowed_jobs and json.decode(newZone.allowed_jobs) or {},
                min_grade = newZone.min_grade,
                require_duty = newZone.require_duty,
                is_active = newZone.is_active,
                created_by = newZone.created_by,
            }
            TriggerClientEvent('admin-zones:client:addZone', -1, zoneData)
        end
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Zone created: ' .. name })
    end
end)

RegisterNetEvent('admin-zones:server:updateZone', function(zoneId, name, zoneType, coords, radius, allowedJobs, minGrade, requireDuty, isActive)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    local coordsJson = json.encode(coords)
    local jobsJson = allowedJobs and json.encode(allowedJobs) or '[]'
    MySQL.query(
        'UPDATE admin_zones SET name = ?, zone_type = ?, coords = ?, radius = ?, allowed_jobs = ?, min_grade = ?, require_duty = ?, is_active = ? WHERE id = ?',
        { name, zoneType, coordsJson, radius or 2.0, jobsJson, minGrade or 0, requireDuty or 0, isActive or 1, zoneId }
    )
    TriggerClientEvent('admin-zones:client:refreshZones', -1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Zone updated: ' .. name })
end)

RegisterNetEvent('admin-zones:server:deleteZone', function(zoneId)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('DELETE FROM admin_zone_items WHERE zone_id = ?', { zoneId })
    MySQL.query('DELETE FROM admin_zones WHERE id = ?', { zoneId })
    TriggerClientEvent('admin-zones:client:removeZone', -1, zoneId)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Zone deleted' })
end)

RegisterNetEvent('admin-zones:server:toggleZone', function(zoneId, active)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('UPDATE admin_zones SET is_active = ? WHERE id = ?', { active and 1 or 0, zoneId })
    TriggerClientEvent('admin-zones:client:refreshZones', -1)
end)

--- ==================== ZONE ITEMS CRUD ====================

lib.callback.register('admin-zones:server:getZoneItems', function(source, zoneId)
    if not zoneId then return {} end
    local items = MySQL.query.await('SELECT * FROM admin_zone_items WHERE zone_id = ? ORDER BY category, label', { zoneId })
    local result = {}
    for _, item in ipairs(items or {}) do
        result[#result + 1] = {
            id = item.id,
            zone_id = item.zone_id,
            item_name = item.item_name,
            label = item.label,
            price = item.price,
            min_rank = item.min_rank,
            currency = item.currency,
            category = item.category,
        }
    end
    return result
end)

RegisterNetEvent('admin-zones:server:addZoneItem', function(zoneId, itemName, label, price, minRank, currency, category)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    MySQL.insert(
        'INSERT INTO admin_zone_items (zone_id, item_name, label, price, min_rank, currency, category) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { zoneId, itemName, label, price or 0, minRank or 0, currency or 'money', category or 'general' }
    )
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Item added: ' .. label })
end)

RegisterNetEvent('admin-zones:server:updateZoneItem', function(itemId, itemName, label, price, minRank, currency, category)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query(
        'UPDATE admin_zone_items SET item_name = ?, label = ?, price = ?, min_rank = ?, currency = ?, category = ? WHERE id = ?',
        { itemName, label, price or 0, minRank or 0, currency or 'money', category or 'general', itemId }
    )
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Item updated: ' .. label })
end)

RegisterNetEvent('admin-zones:server:removeZoneItem', function(itemId)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('DELETE FROM admin_zone_items WHERE id = ?', { itemId })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Item removed' })
end)

--- ==================== ZONE INTERACTIONS ====================

RegisterNetEvent('admin-zones:server:takeItem', function(zoneId, itemName)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    local item = MySQL.single.await(
        'SELECT * FROM admin_zone_items WHERE zone_id = ? AND item_name = ?',
        { zoneId, itemName }
    )
    if not item then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Item not found' })
        return
    end
    local success = p.Functions.AddItem(itemName, 1)
    if success then
        local label = item.label ~= '' and item.label or itemName
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Received ' .. label })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Could not add item to inventory' })
    end
end)

RegisterNetEvent('admin-zones:server:buyItem', function(zoneId, itemName, price, currency)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    if price and price > 0 then
        local moneyType = currency == 'black_money' and 'black_money' or 'cash'
        local balance = p.Functions.GetMoney(moneyType)
        if balance < price then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough money' })
            return
        end
        p.Functions.RemoveMoney(moneyType, price)
    end
    local item = MySQL.single.await(
        'SELECT * FROM admin_zone_items WHERE zone_id = ? AND item_name = ?',
        { zoneId, itemName }
    )
    if not item then return end
    local success = p.Functions.AddItem(itemName, 1)
    if success then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Purchased ' .. item.label })
    else
        if price and price > 0 then
            p.Functions.AddMoney(currency == 'black_money' and 'black_money' or 'cash', price)
        end
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Could not add item to inventory' })
    end
end)

RegisterNetEvent('admin-zones:server:toggleDuty', function()
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    local onduty = p.PlayerData.job.onduty
    p.Functions.SetJobDuty(not onduty)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = onduty and 'Off duty' or 'On duty' })
end)

RegisterNetEvent('admin-zones:server:spawnVehicle', function(zoneId, model)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    TriggerClientEvent('admin-zones:client:spawnVehicle', src, model)
end)

--- ==================== EXPORTS ====================

exports('getActiveZones', function()
    return MySQL.query.await('SELECT * FROM admin_zones WHERE is_active = 1')
end)

exports('getAllZones', function()
    return MySQL.query.await('SELECT * FROM admin_zones ORDER BY name ASC')
end)

exports('createZone', function(name, zoneType, coords, radius, allowedJobs, minGrade, requireDuty, createdBy)
    local coordsJson = json.encode(coords)
    local jobsJson = allowedJobs and json.encode(allowedJobs) or '[]'
    return MySQL.insert.await(
        'INSERT INTO admin_zones (name, zone_type, coords, radius, allowed_jobs, min_grade, require_duty, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        { name, zoneType, coordsJson, radius or 2.0, jobsJson, minGrade or 0, requireDuty or 0, createdBy or '' }
    )
end)

exports('deleteZone', function(zoneId)
    MySQL.query('DELETE FROM admin_zone_items WHERE zone_id = ?', { zoneId })
    MySQL.query('DELETE FROM admin_zones WHERE id = ?', { zoneId })
    TriggerClientEvent('admin-zones:client:refreshZones', -1)
end)
