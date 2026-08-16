local QBox = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('shop-ownership:server:buyShop', function(shopId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local shopData = nil
    for _, s in ipairs(Config.Shops) do
        if s.shop_id == shopId then shopData = s break end
    end
    if not shopData then return end

    local price = shopData.price
    if player.Functions.RemoveMoney('bank', price, 'buy-shop') then
        MySQL.insert('INSERT INTO shops (shop_id, label, owner_citizenid, price, profit_share_percent) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE owner_citizenid = ?', {
            shopId, shopData.label, player.PlayerData.citizenid, price, shopData.profit_share, player.PlayerData.citizenid
        })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Purchased ' .. shopData.label .. '!' })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Insufficient bank funds' })
    end
end)

RegisterNetEvent('shop-ownership:server:processSale', function(shopId, saleAmount)
    local shop = MySQL.single.await('SELECT label, owner_citizenid, profit_share_percent FROM shops WHERE shop_id = ? LIMIT 1', { shopId })
    if shop and shop.owner_citizenid then
        local profit = math.floor((tonumber(saleAmount) or 0) * (shop.profit_share_percent or 0.10))
        if profit > 0 then
            local ownerPlayer = QBox.Functions.GetPlayerByCitizenId(shop.owner_citizenid)
            if ownerPlayer then
                ownerPlayer.Functions.AddMoney('bank', profit, 'shop-profit')
                MySQL.insert('INSERT INTO bank_transactions (citizenid, target, amount, type) VALUES (?, ?, ?, ?)', {
                    shop.owner_citizenid, shop.label, profit, 'shop_profit'
                })
                TriggerClientEvent('iphone:client:sendNotification', ownerPlayer.PlayerData.source, {
                    title = 'Bank',
                    message = '+$' .. profit .. ' — ' .. shop.label .. ' profit',
                    type = 'shop_profit'
                })
            end
        end
    end
end)
