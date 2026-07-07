local QBox = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('methlab:findCustomer', function(zoneId, methItem)
    local src = source
    local p = getPlayer(src)
    if not p then return end
    if not rateLimit(src, 'findCustomer', 10) then return end
    local zone = Config.MethLab.dealing.zones[zoneId]
    if not zone then return end

    local heat = 0
    local allBunkers = exports['bunker-builder']:GetAllBunkers() or {}
    for id, _ in pairs(allBunkers) do
        local state = MySQL.single.await('SELECT heat FROM meth_lab_state WHERE bunker_id = ?', { id })
        if state then heat = heat + (state.heat or 0) end
    end

    local undercoverChance = Config.MethLab.dealing.undercoverChanceBase + (heat * Config.MethLab.dealing.undercoverChancePerHeat)
    local roll = math.random() * 100
    local cumulative = 0
    local buyerType = 'regular'

    for typeKey, typeConfig in pairs(Config.MethLab.dealing.buyerTypes) do
        cumulative = cumulative + typeConfig.chance
        if roll <= cumulative then
            buyerType = typeKey
            break end
    end

    if buyerType == 'undercover' then
        exports['discord-logs']:LogCustom(p.PlayerData.citizenid, 'Meth Lab', 'Undercover encounter at ' .. zone.label)
        local fine = math.random(Config.MethLab.dealing.police.fine.min, Config.MethLab.dealing.police.fine.max)
        p.Functions.RemoveMoney('cash', fine)
        local count = QBox.Functions.GetItemCount(p, methItem)
        if count > 0 then
            local loss = math.ceil(count * 0.5)
            p.Functions.RemoveItem(methItem, loss)
        end
        TriggerClientEvent('methlab:customerFound', src, { undercover = true, fine = fine })
        return
    end

    local buyerConfig = Config.MethLab.dealing.buyerTypes[buyerType] or Config.MethLab.dealing.buyerTypes.regular

    local repRow = MySQL.single.await('SELECT rep FROM meth_lab_dealing_reputation WHERE citizenid = ?', { p.PlayerData.citizenid })
    local rep = repRow and repRow.rep or 0

    local repLevel = 0
    for i, level in ipairs(Config.MethLab.dealing.reputation.levels) do
        if rep >= level then repLevel = i end
    end
    local repPerks = Config.MethLab.dealing.reputation.perks[repLevel] or Config.MethLab.dealing.reputation.perks[1]

    local itemCfg = Config.MethLab.ingredients[methItem] or {}
    local basePrice = 0
    local methPrices = { meth_blue_sky = 1200, meth_crystal = 1500, meth_street = 600 }
    basePrice = methPrices[methItem] or 500

    local pricePerUnit = math.floor(basePrice * buyerConfig.priceMult * repPerks.priceMult)
    local riskMod = Config.MethLab.dealing.riskModifiers[zone.risk] or 1
    local heatGain = Config.MethLab.heat.saleBase + (buyerConfig.risk * Config.MethLab.heat.perUnitSold * riskMod)

    exports['discord-logs']:LogCustom(p.PlayerData.citizenid, 'Meth Lab', 'Customer found at ' .. zone.label .. ' - ' .. buyerType)
    TriggerClientEvent('methlab:customerFound', src, {
        buyerType = buyerType,
        methItem = methItem,
        pricePerUnit = pricePerUnit,
        heatGain = heatGain,
        leave = false,
    })
end)

RegisterNetEvent('methlab:sellMeth', function(zoneId, methItem, qty, unitPrice, negotiated)
    local src = source
    local p = getPlayer(src)
    if not p then return end
    if not rateLimit(src, 'sellMeth', 15) then return end
    local zone = Config.MethLab.dealing.zones[zoneId]
    if not zone then return end

    local count = QBox.Functions.GetItemCount(p, methItem)
    if count < qty then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough product' })
        return
    end

    p.Functions.RemoveItem(methItem, qty)
    local total = math.floor(qty * unitPrice)
    p.Functions.AddMoney('cash', total)

    local repRow = MySQL.single.await('SELECT rep, total_sales, total_earned FROM meth_lab_dealing_reputation WHERE citizenid = ?', { p.PlayerData.citizenid })
    local curRep = repRow and repRow.rep or 0
    local totalSales = repRow and repRow.total_sales or 0
    local totalEarned = repRow and repRow.total_earned or 0

    local repGain = 1
    if methItem == 'meth_crystal' then repGain = 3
    elseif methItem == 'meth_blue_sky' then repGain = 2 end
    repGain = repGain * qty

    MySQL.update('UPDATE meth_lab_dealing_reputation SET rep = ?, total_sales = ?, total_earned = ? WHERE citizenid = ?', {
        curRep + repGain, totalSales + qty, totalEarned + total, p.PlayerData.citizenid
    })

    local heatGain = Config.MethLab.heat.saleBase + math.ceil(qty * Config.MethLab.heat.perUnitSold) * (Config.MethLab.dealing.riskModifiers[zone.risk] or 1)
    local allBunkers = exports['bunker-builder']:GetAllBunkers() or {}
    for id, _ in pairs(allBunkers) do
        addHeatToBunker(id, math.ceil(heatGain / math.max(1, #allBunkers)))
    end

    if math.random() <= Config.MethLab.dealing.policeAlertChance then
        local coords = zone.coords
        TriggerClientEvent('police:client:sendAlert', -1, 'drugDeal', coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
    end

    local name = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname
    exports['discord-logs']:LogCustom(p.PlayerData.citizenid, 'Meth Lab',
        name .. ' sold ' .. qty .. 'x ' .. methItem .. ' for $' .. total .. ' at ' .. zone.label
    )

    TriggerClientEvent('methlab:saleResult', src, { success = true, qty = qty, total = total })
end)
