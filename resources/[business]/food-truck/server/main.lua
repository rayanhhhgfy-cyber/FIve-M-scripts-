local QBox = exports['qbx_core']:GetCoreObject()
local ownedTrucks = {}
local truckMenus = {}
local truckInventory = {}
local truckSatisfaction = {}
local activeOrders = {}
local orderCounter = 0

local function isTruckOwner(src, truckId)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    local truck = ownedTrucks[truckId]
    return truck and truck.owner == p.PlayerData.citizenid
end

MySQL.ready(function()
    local trucks = MySQL.query.await('SELECT * FROM food_trucks')
    for _, t in ipairs(trucks) do
        ownedTrucks[t.truck_id] = { owner = t.owner_cid, ownerName = t.owner_name, purchased = t.purchased_at, passedInspection = t.passed_inspection == 1 }
        truckSatisfaction[t.truck_id] = t.satisfaction or 100.0
    end
    local menus = MySQL.query.await('SELECT * FROM food_truck_menu')
    for _, m in ipairs(menus) do
        if not truckMenus[m.truck_id] then truckMenus[m.truck_id] = {} end
        table.insert(truckMenus[m.truck_id], { itemId = m.menu_item_id, price = m.price, available = m.available == 1 })
    end
    local inv = MySQL.query.await('SELECT * FROM food_truck_inventory')
    for _, i in ipairs(inv) do
        if not truckInventory[i.truck_id] then truckInventory[i.truck_id] = {} end
        truckInventory[i.truck_id][i.ingredient] = i.quantity
    end
end)

RegisterNetEvent('foodtruck:buy', function(truckId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local truckDef = nil
    for _, t in ipairs(Config.FoodTruck.trucks) do
        if t.id == truckId then truckDef = t; break end
    end
    if not truckDef then return end
    if ownedTrucks[truckId] then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already owned' })
        return
    end
    if p.Functions.RemoveMoney('bank', truckDef.price) then
        ownedTrucks[truckId] = { owner = p.PlayerData.citizenid, ownerName = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname, purchased = os.time(), passedInspection = false }
        truckSatisfaction[truckId] = 100.0
        MySQL.insert('INSERT INTO food_trucks (truck_id, owner_cid, owner_name, purchased_at) VALUES (?, ?, ?, ?)', { truckId, p.PlayerData.citizenid, ownedTrucks[truckId].ownerName, os.time() })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Purchased ' .. truckDef.name .. ' for $' .. truckDef.price })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough money' })
    end
end)

RegisterNetEvent('foodtruck:addMenuItem', function(truckId, itemId, price)
    local src = source
    if not isTruckOwner(src, truckId) then return end
    local menuItem = nil
    for _, mi in ipairs(Config.FoodTruck.menuItems) do
        if mi.id == itemId then menuItem = mi; break end
    end
    if not menuItem then return end
    if not truckMenus[truckId] then truckMenus[truckId] = {} end
    table.insert(truckMenus[truckId], { itemId = itemId, price = price or menuItem.price, available = true })
    MySQL.insert('INSERT INTO food_truck_menu (truck_id, menu_item_id, price) VALUES (?, ?, ?)', { truckId, itemId, price or menuItem.price })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = menuItem.name .. ' added to menu ($' .. (price or menuItem.price) .. ')' })
end)

RegisterNetEvent('foodtruck:removeMenuItem', function(truckId, itemId)
    local src = source
    if not isTruckOwner(src, truckId) then return end
    if truckMenus[truckId] then
        for i, mi in ipairs(truckMenus[truckId]) do
            if mi.itemId == itemId then
                table.remove(truckMenus[truckId], i)
                MySQL.update('DELETE FROM food_truck_menu WHERE truck_id = ? AND menu_item_id = ?', { truckId, itemId })
                TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Item removed from menu' })
                return
            end
        end
    end
end)

RegisterNetEvent('foodtruck:stockIngredient', function(truckId, ingredientId, quantity)
    local src = source
    if not isTruckOwner(src, truckId) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local ingDef = Config.FoodTruck.ingredients[ingredientId]
    if not ingDef then return end
    local cost = ingDef.price * quantity
    if p.Functions.RemoveMoney('bank', cost) then
        if not truckInventory[truckId] then truckInventory[truckId] = {} end
        truckInventory[truckId][ingredientId] = (truckInventory[truckId][ingredientId] or 0) + quantity
        MySQL.insert('INSERT INTO food_truck_inventory (truck_id, ingredient, quantity) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE quantity = quantity + ?',
            { truckId, ingredientId, quantity, quantity })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Stocked ' .. quantity .. 'x ' .. ingDef.label .. ' ($' .. cost .. ')' })
    end
end)

RegisterNetEvent('foodtruck:cook', function(truckId, itemId)
    local src = source
    if not isTruckOwner(src, truckId) then return end
    local menuItem = nil
    for _, mi in ipairs(Config.FoodTruck.menuItems) do
        if mi.id == itemId then menuItem = mi; break end
    end
    if not menuItem then return end
    -- check ingredients
    if not truckInventory[truckId] then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No ingredients stocked' })
        return
    end
    for _, ing in ipairs(menuItem.ingredients) do
        local have = truckInventory[truckId][ing.item] or 0
        if have < ing.qty then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Missing ' .. (Config.FoodTruck.ingredients[ing.item] and Config.FoodTruck.ingredients[ing.item].label or ing.item) })
            return
        end
    end
    -- consume ingredients
    for _, ing in ipairs(menuItem.ingredients) do
        truckInventory[truckId][ing.item] = truckInventory[truckId][ing.item] - ing.qty
        MySQL.update('UPDATE food_truck_inventory SET quantity = ? WHERE truck_id = ? AND ingredient = ?', { truckInventory[truckId][ing.item], truckId, ing.item })
    end
    local foodItem = 'food_' .. itemId
    local p = QBox.Functions.GetPlayer(src)
    if p then p.Functions.AddItem(foodItem, 1) end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = menuItem.name .. ' cooked!' })
end)

RegisterNetEvent('foodtruck:order', function(truckId, itemId, quantity)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local truck = ownedTrucks[truckId]
    if not truck then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Truck not found' })
        return
    end
    local menuItem = nil
    local menuPrice = nil
    if truckMenus[truckId] then
        for _, mi in ipairs(truckMenus[truckId]) do
            if mi.itemId == itemId and mi.available then
                menuItem = mi
                menuPrice = mi.price
                break
            end
        end
    end
    if not menuItem then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Item not available' })
        return
    end
    local total = menuPrice * (quantity or 1)
    if not p.Functions.RemoveMoney('cash', total) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough cash' })
        return
    end
    -- pay owner
    local owner = QBox.Functions.GetPlayerByCitizenId(truck.owner)
    if owner then
        owner.Functions.AddMoney('bank', total)
    end
    orderCounter = orderCounter + 1
    local orderId = 'ORD-' .. orderCounter
    activeOrders[orderId] = { truckId = truckId, itemId = itemId, customer = p.PlayerData.citizenid, total = total, status = 'completed' }
    MySQL.insert('INSERT INTO food_truck_orders (truck_id, order_id, customer_cid, item_id, total) VALUES (?, ?, ?, ?, ?)', { truckId, orderId, p.PlayerData.citizenid, itemId, total })
    -- satisfaction
    truckSatisfaction[truckId] = math.max(0, (truckSatisfaction[truckId] or 100) - Config.FoodTruck.satisfactionDecay)
    MySQL.update('UPDATE food_trucks SET satisfaction = ? WHERE truck_id = ?', { truckSatisfaction[truckId], truckId })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Order placed: $' .. total })
end)

RegisterNetEvent('foodtruck:sell', function(truckId)
    local src = source
    if not isTruckOwner(src, truckId) then return end
    local truckDef = nil
    for _, t in ipairs(Config.FoodTruck.trucks) do
        if t.id == truckId then truckDef = t; break end
    end
    if not truckDef then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local refund = math.floor(truckDef.price * 0.6)
    p.Functions.AddMoney('bank', refund)
    MySQL.update('DELETE FROM food_trucks WHERE truck_id = ?', { truckId })
    MySQL.update('DELETE FROM food_truck_menu WHERE truck_id = ?', { truckId })
    MySQL.update('DELETE FROM food_truck_inventory WHERE truck_id = ?', { truckId })
    ownedTrucks[truckId] = nil
    truckMenus[truckId] = nil
    truckInventory[truckId] = nil
    truckSatisfaction[truckId] = nil
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Sold truck for $' .. refund })
end)

RegisterNetEvent('foodtruck:healthInspection', function(truckId)
    local src = source
    if not isTruckOwner(src, truckId) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    if p.Functions.RemoveMoney('bank', Config.FoodTruck.healthInspectionFee) then
        local passed = truckSatisfaction[truckId] and truckSatisfaction[truckId] >= 70
        ownedTrucks[truckId].passedInspection = passed
        MySQL.update('UPDATE food_trucks SET passed_inspection = ? WHERE truck_id = ?', { passed and 1 or 0, truckId })
        if passed then
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Passed health inspection!' })
        else
            TriggerClientEvent('ox_lib:notify', src, { type = 'warning', description = 'Failed inspection (satisfaction too low). Improve quality!' })
        end
    end
end)

QBox.Functions.CreateCallback('foodtruck:getOwned', function(source, cb)
    local p = QBox.Functions.GetPlayer(source)
    if not p then cb({}) return end
    local result = {}
    for id, info in pairs(ownedTrucks) do
        if info.owner == p.PlayerData.citizenid then
            table.insert(result, { id = id, satisfaction = truckSatisfaction[id], passedInspection = info.passedInspection })
        end
    end
    cb(result)
end)

QBox.Functions.CreateCallback('foodtruck:getMenu', function(source, truckId, cb)
    cb(truckMenus[truckId] or {})
end)

QBox.Functions.CreateCallback('foodtruck:getInventory', function(source, truckId, cb)
    cb(truckInventory[truckId] or {})
end)
