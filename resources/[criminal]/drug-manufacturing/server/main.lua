local QBox = exports['qbx-core']:GetCoreObject()
local cookingJobs = {}

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('drug:server:cook', function(i)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'drugCook', 5) or cookingJobs[src] then return end
    local lab = Config.DrugManufacturing.Labs[i]
    local recipe = Config.DrugManufacturing.Recipes[lab.type]
    if not recipe then return end
    for _, req in ipairs(recipe.requiredItems) do
        local count = QBox.Functions.GetItemCount(p, req.item)
        if count < req.amount then Wrappers.Notify(src, 'Missing ' .. req.label, 'error') return end
    end
    for _, req in ipairs(recipe.requiredItems) do
        p.Functions.RemoveItem(req.item, req.amount)
    end
    cookingJobs[src] = { labId = i, ready = false }
    if math.random() <= Config.DrugManufacturing.Risk.explosionChance then
        cookingJobs[src] = nil
        p.Functions.AddItem('bandage', math.random(1, 3))
        exports['discord-logs']:LogCustom(src, 'Drug Manufacturing', 'Lab explosion at ' .. lab.label)
        TriggerClientEvent('drug:client:accident', src, 'Lab exploded! Lucky to be alive', 'error')
        return
    end
    exports['discord-logs']:LogCustom(src, 'Drug Manufacturing', 'Started cooking ' .. recipe.label .. ' at ' .. lab.label)
    TriggerClientEvent('drug:client:cookStarted', src, i)
    Citizen.SetTimeout(recipe.cookTime, function()
        if cookingJobs[src] then
            cookingJobs[src].ready = true
            TriggerClientEvent('drug:client:cookReady', src, i)
            if math.random() <= Config.DrugManufacturing.PoliceAlertChance then
                local coords = lab.coords
                TriggerClientEvent('police:client:sendAlert', -1, 'drugLab', coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
            end
        end
    end)
end)

RegisterNetEvent('drug:server:collect', function(i)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'drugCollect', 5) then return end
    if not cookingJobs[src] or not cookingJobs[src].ready then return end
    local lab = Config.DrugManufacturing.Labs[i]
    local recipe = Config.DrugManufacturing.Recipes[lab.type]
    if not recipe then return end
    local count = math.random(recipe.outputMin, recipe.outputMax)
    p.Functions.AddItem(recipe.outputItem, count)
    cookingJobs[src] = nil
    exports['discord-logs']:LogCustom(src, 'Drug Manufacturing', 'Collected ' .. count .. 'x ' .. recipe.outputItem)
    TriggerClientEvent('drug:client:collectResult', src, i, { count = count, label = recipe.label })
end)

MySQL.ready(function()
    MySQL.query('CREATE TABLE IF NOT EXISTS drug_labs (id INT AUTO_INCREMENT PRIMARY KEY, lab_type VARCHAR(50), owner VARCHAR(50), upgrades TEXT, last_cook INT DEFAULT 0)')
end)
