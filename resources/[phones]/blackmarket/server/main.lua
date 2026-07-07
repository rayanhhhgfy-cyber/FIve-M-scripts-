local QBox = exports['qbx-core']:GetCoreObject()
local marketStocks = {}

local function initStocks()
    for li, loc in ipairs(Config.BlackMarket.Locations) do
        marketStocks[li] = {}
        for _, s in ipairs(Config.BlackMarket.Stocks) do
            marketStocks[li][s.item] = { item = s.item, label = s.label, price = s.price, stock = s.maxStock, maxStock = s.maxStock, minRank = s.minRank }
        end
    end
end
initStocks()

local function restock()
    for li, stock in pairs(marketStocks) do
        for itemId, s in pairs(stock) do
            local add = math.random(Config.BlackMarket.StockRefresh.min, Config.BlackMarket.StockRefresh.max)
            s.stock = math.min(s.maxStock, s.stock + add)
        end
    end
end

Citizen.CreateThread(function()
    while true do Citizen.Wait(Config.BlackMarket.RestockInterval * 1000) restock() end
end)

RegisterNetEvent('blackmarket:server:getStock', function(locId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local stock = {}
    for _, s in pairs(marketStocks[locId] or {}) do
        if p.PlayerData.job.grade.level >= s.minRank then
            table.insert(stock, { item = s.item, label = s.label, price = s.price, stock = s.stock })
        end
    end
    TriggerClientEvent('blackmarket:client:showStock', src, locId, stock)
end)

RegisterNetEvent('blackmarket:server:purchase', function(locId, item, qty, price)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not marketStocks[locId] or not marketStocks[locId][item] then return end
    local s = marketStocks[locId][item]
    if not s or s.stock < qty then Wrappers.Notify(src, Locale('phone.out_of_stock'), 'error') return end
    local total = price * qty
    if p.PlayerData.cash < total then Wrappers.Notify(src, Locale('phone.insufficient_funds'), 'error') return end
    p.Functions.RemoveMoney('cash', total)
    p.Functions.AddItem(item, qty)
    s.stock = s.stock - qty
    Wrappers.Notify(src, Locale('phone.purchase_success', s.label, qty), 'success')
    exports['discord-logs']:LogCustom(src, 'Black Market', 'Purchased ' .. qty .. 'x ' .. s.label .. ' for $' .. total)
end)
