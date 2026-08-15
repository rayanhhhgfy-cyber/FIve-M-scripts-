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

local function handleShopProfit(shopName, shopLabel, totalCost)
    local dbShop = MySQL.single.await('SELECT * FROM shops WHERE shop_id = ?', { shopName })
    if not dbShop or not dbShop.owner_citizenid then return end

    local profitShare = dbShop.profit_share_percent or 15
    local profitAmount = math.floor(totalCost * (profitShare / 100))
    if profitAmount <= 0 then return end

    local ownerCid = dbShop.owner_citizenid
    local ownerPlayer = QBCore.Functions.GetPlayerByCitizenId(ownerCid)

    if ownerPlayer then
        ownerPlayer.Functions.AddMoney('bank', profitAmount)
        TriggerClientEvent('iphone:client:shopNotification', ownerPlayer.PlayerData.source, shopLabel, profitAmount)
    else
        MySQL.update('UPDATE players SET money = JSON_SET(money, "$.bank", JSON_EXTRACT(money, "$.bank") + ?) WHERE citizenid = ?', { profitAmount, ownerCid })
    end

    MySQL.insert('INSERT INTO bank_transactions (citizenid, target, amount, type) VALUES (?, ?, ?, ?)', {
        ownerCid, shopLabel, profitAmount, 'shop_profit'
    })
end

RegisterNetEvent('shop:buyOwnership', function(shopName)
    local src = source
    if not src or not shopName then return end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local shop = findShop(shopName)
    if not shop then return Notify(src, 'Invalid shop.', 'error') end

    local price = shop.price or 50000
    local existing = MySQL.single.await('SELECT owner_citizenid FROM shops WHERE shop_id = ?', { shopName })
    if existing and existing.owner_citizenid then
        return Notify(src, 'This shop is already owned by someone.', 'error')
    end

    if player.PlayerData.money.bank < price then
        return Notify(src, 'Insufficient bank balance ($' .. price .. ' required).', 'error')
    end

    player.Functions.RemoveMoney('bank', price)
    local coordsStr = json.encode({ x = shop.coords.x, y = shop.coords.y, z = shop.coords.z })

    if existing then
        MySQL.update('UPDATE shops SET owner_citizenid = ? WHERE shop_id = ?', { player.PlayerData.citizenid, shopName })
    else
        MySQL.insert('INSERT INTO shops (shop_id, label, coords, owner_citizenid, price, profit_share_percent) VALUES (?, ?, ?, ?, ?, ?)', {
            shopName, shop.label, coordsStr, player.PlayerData.citizenid, price, 15
        })
    end

    Notify(src, 'You purchased ownership of ' .. shop.label .. ' for $' .. price .. '!', 'success')
end)

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
        handleShopProfit(shopName, shop.label, totalCost)
        Notify(src, Locale('shops.bought') .. ' ' .. quantity .. 'x ' .. product.label, 'success')
    elseif player.PlayerData.money.bank >= totalCost then
        local added = exports['ox_inventory']:CanCarryItem(src, productName, quantity)
        if not added then return Notify(src, Locale('shops.no_space'), 'error') end
        player.Functions.RemoveMoney('bank', totalCost)
        exports['ox_inventory']:AddItem(src, productName, quantity)
        handleShopProfit(shopName, shop.label, totalCost)
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
