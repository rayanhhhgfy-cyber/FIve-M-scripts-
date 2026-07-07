local QBox = exports['qbx-core']:GetCoreObject()
local isCooking = false
local cookingData = {}

local function hasItem(item) return QBox.Functions.HasItem(item) end

local function hasIngredients(recipe)
    for _, req in ipairs(recipe.requiredItems) do
        local count = QBox.Functions.GetItemCount(req.item)
        if count < req.amount then return false, req.label end
    end
    return true, nil
end

Citizen.CreateThread(function()
    for i, lab in ipairs(Config.DrugManufacturing.Labs) do
        exports.ox_target:addBoxZone({
            coords = lab.coords, size = vec3(2.0, 2.0, 2.0), rotation = 0, debug = false,
            options = {{
                name = 'drug_cook_' .. i,
                icon = Config.DrugManufacturing.TargetOptions.cook.icon,
                label = 'Cook ' .. Config.DrugManufacturing.Recipes[lab.type].label,
                distance = Config.DrugManufacturing.TargetOptions.cook.distance,
                canInteract = function() return not isCooking and not cookingData[i] end,
                onSelect = function() TriggerEvent('drug:cook', i) end
            }, {
                name = 'drug_collect_' .. i,
                icon = Config.DrugManufacturing.TargetOptions.collect.icon,
                label = Config.DrugManufacturing.TargetOptions.collect.label,
                distance = Config.DrugManufacturing.TargetOptions.collect.distance,
                canInteract = function() return cookingData[i] end,
                onSelect = function() TriggerEvent('drug:collect', i) end
            }}
        })
    end
end)

RegisterNetEvent('drug:cook', function(i)
    if isCooking then return end
    local lab = Config.DrugManufacturing.Labs[i]
    local recipe = Config.DrugManufacturing.Recipes[lab.type]
    if not recipe then return end
    local hasAll, missing = hasIngredients(recipe)
    if not hasAll then Wrappers.Notify('Missing: ' .. missing, 'error') return end
    isCooking = true
    Wrappers.ProgressBar({ label = 'Cooking ' .. recipe.label .. '...', duration = recipe.cookTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then isCooking = false return end
        TriggerServerEvent('drug:server:cook', i)
    end)
end)

RegisterNetEvent('drug:collect', function(i)
    Wrappers.ProgressBar({ label = 'Collecting product...', duration = Config.DrugManufacturing.Processing.time, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('drug:server:collect', i)
    end)
end)

RegisterNetEvent('drug:client:cookStarted', function(i)
    cookingData[i] = { ready = false, time = os.time() + Config.DrugManufacturing.Recipes[Config.DrugManufacturing.Labs[i].type].cookTime / 1000 }
    isCooking = false
    Wrappers.Notify('Cooking started! Come back later', 'success')
end)

RegisterNetEvent('drug:client:cookReady', function(i)
    cookingData[i] = { ready = true }
    Wrappers.Notify('Your product is ready to collect!', 'success')
end)

RegisterNetEvent('drug:client:collectResult', function(i, data)
    cookingData[i] = nil
    Wrappers.Notify('Collected ' .. data.count .. 'x ' .. data.label, 'success')
end)

RegisterNetEvent('drug:client:accident', function(msg)
    isCooking = false
    Wrappers.Notify(msg, 'error')
end)
