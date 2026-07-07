local QBox = exports['qbx-core']:GetCoreObject()
local isCooking = false
local currentRecipe = nil
local cookingStage = 0
local stageScores = {}
local tempNeedle = 270

RegisterNetEvent('methlab:openCookingMenu', function(bunkerId)
    if isCooking then notify('Already cooking!', 'error') return end
    local items = {}
    for key, recipe in pairs(Config.MethLab.cooking.recipes) do
        local hasIngredients = true
        for _, ing in ipairs(recipe.ingredients) do
            if getItemCount(ing.item) < ing.amount then hasIngredients = false break end
        end
        table.insert(items, {
            title = (hasIngredients and '' or '') .. recipe.label,
            description = 'Difficulty: ' .. recipe.difficulty .. ' | Requires: ' .. getRecipeIngredientsStr(recipe.ingredients),
            disabled = not hasIngredients,
            onSelect = function()
                if not hasIngredients then notify('Missing ingredients', 'error') return end
                startCookingProcess(bunkerId, key, recipe)
            end
        })
    end
    if #items > 0 then
        Wrappers.ContextMenu({ id = 'cook_menu', title = 'Select Recipe', menuItems = items })
    else
        notify('No recipes available. Get ingredients first.', 'error')
    end
end)

function getRecipeIngredientsStr(ingredients)
    local parts = {}
    for _, ing in ipairs(ingredients) do
        table.insert(parts, ing.amount .. 'x ' .. ing.label)
    end
    return table.concat(parts, ', ')
end

function startCookingProcess(bunkerId, recipeKey, recipe)
    isCooking = true
    currentRecipe = recipeKey
    cookingStage = 1
    stageScores = {}
    tempNeedle = 270
    notify('Starting ' .. recipe.label .. ' production...', 'info')
    runCookingStage(bunkerId, recipeKey, recipe)
end

function runCookingStage(bunkerId, recipeKey, recipe)
    if cookingStage > 4 then
        finishCooking(bunkerId, recipeKey, recipe)
        return
    end
    local stageName = ({ 'mix', 'heat', 'extract', 'crystallize' })[cookingStage]
    local stageConfig = Config.MethLab.cooking.stages[stageName]
    local duration = stageConfig.duration
    if cookingStage == 4 then
        local basePurity = calculateBasePurity()
        local extraTime = (1.0 - (basePurity / 100)) * 60000
        duration = math.max(15000, 90000 - extraTime)
    end

    if cookingStage == 2 then
        runHeatStage(bunkerId, recipeKey, recipe, duration)
    elseif cookingStage == 3 then
        runExtractStage(bunkerId, recipeKey, recipe, duration)
    else
        runSimpleStage(bunkerId, recipeKey, recipe, stageName, duration)
    end
end

function runSimpleStage(bunkerId, recipeKey, recipe, stageName, duration)
    local animDict = 'mini@repair'
    local animName = 'fixing_a_ped'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Citizen.Wait(100) end
    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8.0, duration, 3, 0, false, false, false)

    local success = exports.ox_lib:progressBar({
        duration = duration,
        label = Config.MethLab.cooking.stages[stageName].label .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })

    ClearPedTasks(PlayerPedId())

    if not success then
        notify('Cooking cancelled', 'error')
        isCooking = false
        return
    end

    local difficulty = ({ easy = 'easy', medium = 'medium', hard = 'hard', very_hard = { 'easy', 'medium', 'hard' } })[recipe.difficulty]
    local passed = exports.ox_lib:skillCheck(difficulty, 50)

    if passed then
        local addScore = math.random(60, 85)
        table.insert(stageScores, addScore)
        notify(stageName .. ' successful! Quality: ' .. addScore .. '%', 'success')
    else
        local addScore = math.random(20, 45)
        table.insert(stageScores, addScore)
        notify(Config.MethLab.cooking.stages[stageName].failedLabel, 'error')
    end

    cookingStage = cookingStage + 1
    runCookingStage(bunkerId, recipeKey, recipe)
end

function runHeatStage(bunkerId, recipeKey, recipe, duration)
    local passed = exports.ox_lib:progressBar({
        duration = duration,
        label = 'Heating reaction...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })
    if not passed then
        notify('Cooking cancelled', 'error')
        isCooking = false
        return
    end
    local idealMin = Config.MethLab.cooking.temperature.idealMin
    local idealMax = Config.MethLab.cooking.temperature.idealMax
    local actualTemp = math.random(idealMin - 30, idealMax + 30)
    local score
    if actualTemp >= idealMin and actualTemp <= idealMax then
        score = math.random(75, 100)
        notify('Perfect temperature! Quality: ' .. score .. '%', 'success')
    elseif actualTemp >= Config.MethLab.cooking.temperature.explosionTemp then
        score = 0
        notify('LAB EXPLOSION! Too hot!', 'error')
        TriggerServerEvent('methlab:cookingExplosion', bunkerId)
    elseif actualTemp <= Config.MethLab.cooking.temperature.freezeTemp then
        score = math.random(10, 25)
        notify('Batch too cold, quality ruined', 'error')
    else
        score = math.random(30, 60)
        notify('Suboptimal temperature, quality: ' .. score .. '%', 'warning')
    end
    table.insert(stageScores, score)
    cookingStage = cookingStage + 1
    runCookingStage(bunkerId, recipeKey, recipe)
end

function runExtractStage(bunkerId, recipeKey, recipe, duration)
    local success = exports.ox_lib:progressBar({
        duration = duration,
        label = 'Solvent extraction...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })
    if not success then
        notify('Cooking cancelled', 'error')
        isCooking = false
        return
    end
    local match = exports.ox_lib:skillCheck({ 'easy', 'medium' }, 60)
    local score
    if match then
        score = math.random(65, 95)
        notify('Extraction clean! Quality: ' .. score .. '%', 'success')
    else
        score = math.random(15, 40)
        notify('Extraction contaminated!', 'error')
    end
    table.insert(stageScores, score)
    cookingStage = cookingStage + 1
    runCookingStage(bunkerId, recipeKey, recipe)
end

function calculateBasePurity()
    if #stageScores == 0 then return 0 end
    local sum = 0
    for _, s in ipairs(stageScores) do sum = sum + s end
    return sum / #stageScores
end

function finishCooking(bunkerId, recipeKey, recipe)
    local basePurity = calculateBasePurity()
    local hasMixer = false
    local bunkers = exports['bunker-builder']:GetAllBunkers() or {}
    local bunker = bunkers[bunkerId]
    QBox.Functions.TriggerCallback('methlab:getBunkerState', function(state)
        if state and state.upgrades then
            for _, u in ipairs(state.upgrades) do
                if u == 'industrial_mixer' then hasMixer = true break end
            end
        end
        local purity = basePurity
        if hasMixer then purity = math.min(purity + 10, 100) end
        local purityCap = recipe.purityCap
        purity = math.min(purity, purityCap)
        local crysTime = 90 - (purity / 100 * 60)
        exports.ox_lib:progressBar({
            duration = math.max(15, crysTime) * 1000,
            label = 'Crystallizing...',
            useWhileDead = false,
            canCancel = true,
        })
        TriggerServerEvent('methlab:finishCooking', bunkerId, recipeKey, purity)
        isCooking = false
        cookingStage = 0
        stageScores = {}
        currentRecipe = nil
    end, bunkerId)
end

RegisterNetEvent('methlab:cookResult', function(data)
    if data.success then
        notify('Batch complete! ' .. data.amount .. 'x ' .. data.label .. ' (Purity: ' .. math.floor(data.purity) .. '%)', 'success')
    elseif data.exploded then
        notify('Lab exploded! Equipment damaged.', 'error')
    else
        notify('Cooking failed. Product lost.', 'error')
    end
end)

RegisterNetEvent('methlab:openStorage', function(bunkerId)
    TriggerEvent('ox_inventory:openInventory', 'stash', 'bunker_storage_' .. bunkerId)
end)
