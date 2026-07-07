local QBox = exports['qbx_core']:GetCoreObject()
local activeCooks = {}

RegisterNetEvent('methlab:finishCooking', function(bunkerId, recipeKey, purity)
    local src = source
    local p = getPlayer(src)
    if not p then return end
    if not rateLimit(src, 'finishCook', 5) then return end
    local recipe = Config.MethLab.cooking.recipes[recipeKey]
    if not recipe then return end
    if activeCooks[src] then return end
    activeCooks[src] = true

    for _, ing in ipairs(recipe.ingredients) do
        local count = QBox.Functions.GetItemCount(p, ing.item)
        if count < ing.amount then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Missing ingredients' })
            activeCooks[src] = nil
            return
        end
    end

    for _, ing in ipairs(recipe.ingredients) do
        p.Functions.RemoveItem(ing.item, ing.amount)
    end

    local purityLabel, priceMult = getPurityTier(purity)
    local amount = math.random(recipe.outputMin, recipe.outputMax)
    amount = math.ceil(amount * priceMult)
    if amount < 1 then amount = 1 end

    local toxicWasteAmount = math.random(Config.MethLab.cooking.toxicWastePerCook.min, Config.MethLab.cooking.toxicWastePerCook.max)
    p.Functions.AddItem('toxic_waste', toxicWasteAmount)

    if purity > 0 then
        p.Functions.AddItem(recipe.outputItem, amount)
    end

    local hasVentilation = false
    local state = MySQL.single.await('SELECT upgrades_json FROM meth_lab_state WHERE bunker_id = ?', { bunkerId })
    if state then
        local upgrades = json.decode(state.upgrades_json) or {}
        for _, u in ipairs(upgrades) do
            if u == 'ventilation' then hasVentilation = true break end
        end
    end

    local heatAmount = Config.MethLab.heat.cookingPerBatch
    if hasVentilation then heatAmount = math.ceil(heatAmount * 0.75) end
    addHeatToBunker(bunkerId, heatAmount)

    local name = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname
    exports['discord-logs']:LogCustom(p.PlayerData.citizenid, 'Meth Lab',
        name .. ' cooked ' .. amount .. 'x ' .. recipe.outputItem .. ' (Purity: ' .. math.floor(purity) .. '%) at bunker ' .. bunkerId
    )

    MySQL.insert('INSERT INTO meth_lab_cooks (citizenid, bunker_id, recipe, purity, amount, timestamp) VALUES (?, ?, ?, ?, ?, ?)', {
        p.PlayerData.citizenid, bunkerId, recipeKey, purity, amount, os.time()
    })

    TriggerClientEvent('methlab:cookResult', src, {
        success = purity > 0,
        amount = amount,
        label = recipe.label,
        purity = purity,
    })

    local heatLevel = getBunkerHeat(bunkerId)
    if heatLevel > Config.MethLab.heat.thresholds.investigated.max then
        local coords = exports['bunker-builder']:GetBunker(bunkerId)
        if coords and coords.entrance then
            TriggerClientEvent('police:client:sendAlert', -1, 'drugLab', coords.entrance.coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.entrance.coords.x, coords.entrance.coords.y, coords.entrance.coords.z)))
        end
    end

    activeCooks[src] = nil
end)

RegisterNetEvent('methlab:cookingExplosion', function(bunkerId)
    local src = source
    local p = getPlayer(src)
    if not p then return end
    local ped = GetPlayerPed(src)
    local health = GetEntityHealth(ped)
    SetEntityHealth(ped, health - 80)
    addHeatToBunker(bunkerId, Config.MethLab.heat.explosion)
    exports['discord-logs']:LogCustom(p.PlayerData.citizenid, 'Meth Lab', 'Lab explosion at bunker ' .. bunkerId)
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'The lab exploded! You\'re injured.' })
end)

function getPurityTier(purity)
    for _, tier in ipairs(Config.MethLab.cooking.purityStages) do
        if purity >= tier.min then
            return tier.label, tier.priceMult
        end
    end
    return 'Burned Batch', 0
end

exports('GetPurityTier', getPurityTier)
