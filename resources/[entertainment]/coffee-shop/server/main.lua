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

local function findDrink(name)
    for _, d in ipairs(Config.CoffeeShop.drinks) do
        if d.name == name then return d end
    end
    return nil
end

RegisterNetEvent('coffee:orderDrink', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.drink) ~= 'string' then
        return
    end
    if not checkRateLimit(src, 'orderDrink', 2) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local drink = findDrink(data.drink)
    if not drink then return end
    local cash = Player.PlayerData.money.cash or 0
    if cash < drink.price then
        Wrappers.Notify(src, Locale('coffee_shop.need_money'), 'error')
        return
    end
    Player.Functions.RemoveMoney('cash', drink.price, nil)
    exports.ox_inventory:AddItem(src, drink.name, 1)
    Wrappers.Notify(src, Locale('coffee_shop.drink_ready'), 'success')
end)
