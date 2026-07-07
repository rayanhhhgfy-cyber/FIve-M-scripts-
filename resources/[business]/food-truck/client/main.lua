local truckSpawnerZones = {}
local currentTruck = nil

Citizen.CreateThread(function()
    for _, truck in ipairs(Config.FoodTruck.trucks) do
        exports['ox_target']:addBoxZone({
            coords = truck.spawn,
            size = vector3(3.0, 3.0, 2.0),
            rotation = 0,
            debug = false,
            options = {
                { label = 'Buy ' .. truck.name .. ' ($' .. truck.price .. ')', icon = 'fas fa-truck', onSelect = function() TriggerServerEvent('foodtruck:buy', truck.id) end },
                { label = 'Manage ' .. truck.name, icon = 'fas fa-cog', onSelect = function() OpenTruckMenu(truck.id) end },
                { label = 'Order Food', icon = 'fas fa-utensils', onSelect = function() OpenOrderMenu(truck.id) end },
            },
        })
    end
end)

function OpenTruckMenu(truckId)
    local items = {
        { title = 'Manage Menu', icon = 'fas fa-book-open', onSelect = function() OpenMenuEditor(truckId) end },
        { title = 'Stock Ingredients', icon = 'fas fa-boxes', onSelect = function() OpenStockMenu(truckId) end },
        { title = 'Cook Item', icon = 'fas fa-fire', onSelect = function() OpenCookMenu(truckId) end },
        { title = 'View Inventory', icon = 'fas fa-clipboard-list', onSelect = function() OpenInventoryView(truckId) end },
        { title = 'Health Inspection ($' .. Config.FoodTruck.healthInspectionFee .. ')', icon = 'fas fa-clipboard-check', onSelect = function() TriggerServerEvent('foodtruck:healthInspection', truckId) end },
        { title = 'Sell Truck', icon = 'fas fa-hand-holding-usd', onSelect = function() TriggerServerEvent('foodtruck:sell', truckId) end },
    }
    Wrappers.ContextMenu({ id = 'truck_mgmt_' .. truckId, title = 'Truck Management', menuItems = items })
end

function OpenMenuEditor(truckId)
    local items = {}
    for _, mi in ipairs(Config.FoodTruck.menuItems) do
        table.insert(items, { title = 'Add ' .. mi.name .. ' ($' .. mi.price .. ')', icon = 'fas fa-plus', onSelect = function()
            Wrappers.InputDialog({ title = 'Set Price for ' .. mi.name, options = { { type = 'number', label = 'Price', default = mi.price } }}, function(v)
                if v then TriggerServerEvent('foodtruck:addMenuItem', truckId, mi.id, tonumber(v[1])) end
            end)
        end })
    end
    table.insert(items, { title = 'Remove Item from Menu', icon = 'fas fa-minus', onSelect = function()
        QBox.Functions.TriggerCallback('foodtruck:getMenu', function(menu)
            local removeItems = {}
            for _, mi in ipairs(menu) do
                table.insert(removeItems, { title = mi.itemId, onSelect = function() TriggerServerEvent('foodtruck:removeMenuItem', truckId, mi.itemId) end })
            end
            Wrappers.ContextMenu({ id = 'remove_menu', title = 'Remove Item', menuItems = removeItems })
        end, truckId)
    end })
    Wrappers.ContextMenu({ id = 'menu_editor', title = 'Menu Editor', menuItems = items })
end

function OpenStockMenu(truckId)
    local items = {}
    for id, ing in pairs(Config.FoodTruck.ingredients) do
        table.insert(items, { title = ing.label .. ' ($' .. ing.price .. '/ea)', icon = 'fas fa-cube', onSelect = function()
            Wrappers.InputDialog({ title = 'Stock ' .. ing.label, options = { { type = 'number', label = 'Quantity', default = 10 } }}, function(v)
                if v then TriggerServerEvent('foodtruck:stockIngredient', truckId, id, tonumber(v[1]) or 10) end
            end)
        end })
    end
    Wrappers.ContextMenu({ id = 'stock_' .. truckId, title = 'Stock Ingredients', menuItems = items })
end

function OpenCookMenu(truckId)
    QBox.Functions.TriggerCallback('foodtruck:getMenu', function(menu)
        local items = {}
        for _, mi in ipairs(menu) do
            local menuItem = nil
            for _, m in ipairs(Config.FoodTruck.menuItems) do
                if m.id == mi.itemId then menuItem = m; break end
            end
            if menuItem then
                table.insert(items, { title = 'Cook ' .. menuItem.name, icon = 'fas fa-fire', onSelect = function()
                    Wrappers.ProgressBar({ label = 'Cooking ' .. menuItem.name .. '...', duration = menuItem.cookTime, onFinish = function()
                        TriggerServerEvent('foodtruck:cook', truckId, menuItem.id)
                    end })
                end })
            end
        end
        Wrappers.ContextMenu({ id = 'cook_' .. truckId, title = 'Cook Item', menuItems = items })
    end, truckId)
end

function OpenInventoryView(truckId)
    QBox.Functions.TriggerCallback('foodtruck:getInventory', function(inv)
        local items = {}
        for id, qty in pairs(inv) do
            local label = (Config.FoodTruck.ingredients[id] and Config.FoodTruck.ingredients[id].label) or id
            table.insert(items, { title = label .. ': ' .. qty .. ' units' })
        end
        if #items == 0 then table.insert(items, { title = 'Empty', description = 'Stock some ingredients!' }) end
        Wrappers.ContextMenu({ id = 'inventory_' .. truckId, title = 'Truck Inventory', menuItems = items })
    end, truckId)
end

function OpenOrderMenu(truckId)
    QBox.Functions.TriggerCallback('foodtruck:getMenu', function(menu)
        if not menu or #menu == 0 then
            Wrappers.Notify('Menu is empty', 'info')
            return
        end
        local items = {}
        for _, mi in ipairs(menu) do
            local menuItem = nil
            for _, m in ipairs(Config.FoodTruck.menuItems) do
                if m.id == mi.itemId then menuItem = m; break end
            end
            if menuItem then
                table.insert(items, { title = menuItem.name .. ' ($' .. mi.price .. ')', icon = 'fas fa-utensils', onSelect = function()
                    TriggerServerEvent('foodtruck:order', truckId, mi.itemId, 1)
                end })
            end
        end
        Wrappers.ContextMenu({ id = 'order_' .. truckId, title = 'Order Food', menuItems = items })
    end, truckId)
end
