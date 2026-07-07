local QBCore = exports['qbx_core']:GetCoreObject()
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

local function Notify(src, msg, type)
    TriggerClientEvent('ox_lib:notify', src, { type = type or 'info', description = msg })
end

local function findShop(shopName)
    for _, shop in ipairs(Config.Shops) do
        if shop.name == shopName then return shop end
    end
    return nil
end

local function findProduct(shop, productName)
    for _, product in ipairs(shop.products) do
        if product.name == productName then return product end
    end
    return nil
end

RegisterNetEvent('shop:buy', function(shopName, productName, quantity)
    local src = source
    if not src or not shopName or not productName or not quantity then return end
    if not checkRateLimit(src, 'buy', 3) then return Notify(src, Locale('shops.invalid_item'), 'error') end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local shop = findShop(shopName)
    if not shop then return Notify(src, Locale('shops.invalid_item'), 'error') end
    local product = findProduct(shop, productName)
    if not product then return Notify(src, Locale('shops.invalid_item'), 'error') end
    quantity = math.floor(tonumber(quantity))
    if quantity < 1 then quantity = 1 end
    local totalCost = math.floor(product.price * quantity)
    if player.PlayerData.money.cash >= totalCost then
        local added = exports['ox_inventory']:CanCarryItem(src, productName, quantity)
        if not added then return Notify(src, Locale('shops.no_space'), 'error') end
        player.Functions.RemoveMoney('cash', totalCost)
        exports['ox_inventory']:AddItem(src, productName, quantity)
        Notify(src, Locale('shops.bought') .. ' ' .. quantity .. 'x ' .. product.label, 'success')
    elseif player.PlayerData.money.bank >= totalCost then
        local added = exports['ox_inventory']:CanCarryItem(src, productName, quantity)
        if not added then return Notify(src, Locale('shops.no_space'), 'error') end
        player.Functions.RemoveMoney('bank', totalCost)
        exports['ox_inventory']:AddItem(src, productName, quantity)
        Notify(src, Locale('shops.bought') .. ' ' .. quantity .. 'x ' .. product.label, 'success')
    else
        Notify(src, Locale('shops.no_money'), 'error')
    end
end)

RegisterNetEvent('shop:sell', function(shopName, productName, quantity)
    local src = source
    if not src or not shopName or not productName or not quantity then return end
    if not checkRateLimit(src, 'sell', 3) then return Notify(src, Locale('shops.invalid_item'), 'error') end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local shop = findShop(shopName)
    if not shop then return Notify(src, Locale('shops.invalid_item'), 'error') end
    local product = findProduct(shop, productName)
    if not product then return Notify(src, Locale('shops.invalid_item'), 'error') end
    quantity = math.floor(tonumber(quantity))
    if quantity < 1 then quantity = 1 end
    local hasItem = exports['ox_inventory']:GetItemCount(src, productName)
    if hasItem < quantity then return Notify(src, Locale('shops.invalid_item'), 'error') end
    local totalPrice = math.floor((product.price * 0.5) * quantity)
    exports['ox_inventory']:RemoveItem(src, productName, quantity)
    player.Functions.AddMoney('cash', totalPrice)
    Notify(src, Locale('shops.sold') .. ' ' .. quantity .. 'x ' .. product.label .. ' for $' .. totalPrice, 'success')
end)
