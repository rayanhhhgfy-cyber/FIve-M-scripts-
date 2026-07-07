local QBCore = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    if not RATE_LIMITS[key] then
        RATE_LIMITS[key] = { count = 1, start = now }
        return true
    end
    if now - RATE_LIMITS[key].start >= 60 then
        RATE_LIMITS[key] = { count = 1, start = now }
        return true
    end
    if RATE_LIMITS[key].count >= maxPerMin then
        return false
    end
    RATE_LIMITS[key].count = RATE_LIMITS[key].count + 1
    return true
end

local function findRestaurant(name)
    for _, r in ipairs(Config.Restaurants) do
        if r.name == name then return r end
    end
    return nil
end

local function findMenuItem(restaurant, itemName)
    for _, m in ipairs(restaurant.menu) do
        if m.name == itemName then return m end
    end
    return nil
end

local function hasItem(src, itemName)
    local count = exports.ox_inventory:Search(src, 'count', itemName)
    return (count or 0) >= 1
end

local function removeItem(src, itemName)
    exports.ox_inventory:RemoveItem(src, itemName, 1)
end

local function addItem(src, itemName, count)
    exports.ox_inventory:AddItem(src, itemName, count or 1)
end

RegisterNetEvent('restaurant:startShift', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.restaurant) ~= 'string' then
        Wrappers.Notify(src, Locale('restaurant_jobs.need_job'), 'error')
        return
    end
    if not checkRateLimit(src, 'startShift', 2) then return end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local restaurant = findRestaurant(data.restaurant)
    if not restaurant then
        Wrappers.Notify(src, Locale('restaurant_jobs.need_job'), 'error')
        return
    end
    if Player.PlayerData.job.name ~= restaurant.requiredJob then
        Wrappers.Notify(src, Locale('restaurant_jobs.need_job'), 'error')
        return
    end
    Wrappers.Notify(src, Locale('restaurant_jobs.start_shift'), 'success')
end)

RegisterNetEvent('restaurant:cookItem', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.restaurant) ~= 'string' or type(data.menuItem) ~= 'string' then
        return
    end
    if not checkRateLimit(src, 'cookItem', 2) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local restaurant = findRestaurant(data.restaurant)
    if not restaurant then return end
    if Player.PlayerData.job.name ~= restaurant.requiredJob then
        Wrappers.Notify(src, Locale('restaurant_jobs.need_job'), 'error')
        return
    end
    local menuItem = findMenuItem(restaurant, data.menuItem)
    if not menuItem then return end
    local reward = Config.Rewards[data.menuItem]
    if not reward then return end
    local count = math.random(reward.min, reward.max)
    addItem(src, reward.item, count)
    Wrappers.Notify(src, Locale('restaurant_jobs.cooked'), 'success')
end)

RegisterNetEvent('restaurant:serveCustomer', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.restaurant) ~= 'string' or type(data.menuItem) ~= 'string' then
        return
    end
    if not checkRateLimit(src, 'serveCustomer', 2) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local restaurant = findRestaurant(data.restaurant)
    if not restaurant or Player.PlayerData.job.name ~= restaurant.requiredJob then
        return
    end
    local reward = Config.Rewards[data.menuItem]
    if not reward then return end
    if not hasItem(src, reward.item) then
        Wrappers.Notify(src, Locale('restaurant_jobs.need_job'), 'error')
        return
    end
    removeItem(src, reward.item)
    Player.Functions.AddMoney('cash', restaurant.payment, nil)
    Wrappers.Notify(src, Locale('restaurant_jobs.serve'), 'success')
end)

RegisterNetEvent('restaurant:completeShift', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.restaurant) ~= 'string' or type(data.totalSales) ~= 'number' then
        return
    end
    if not checkRateLimit(src, 'completeShift', 2) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local restaurant = findRestaurant(data.restaurant)
    if not restaurant or Player.PlayerData.job.name ~= restaurant.requiredJob then
        return
    end
    local bonus = math.floor(data.totalSales * 0.1)
    Player.Functions.AddMoney('cash', bonus, nil)
    Wrappers.Notify(src, Locale('restaurant_jobs.shift_complete'), 'success')
end)
