local isOnShift = false
local grapeCount = 0
local wineInventory = {}
local currentQuality = 0
local playerPed = PlayerPedId()

local function Notify(msg, type)
    lib.notify({ title = 'Winery', description = msg, type = type or 'info' })
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function GetQualityLabel()
    for _, level in ipairs(Config.QualityLevels) do
        if currentQuality >= level.min and currentQuality <= level.max then
            return level.label
        end
    end
    return 'Standard'
end

local function GetQualityMultiplier()
    for _, level in ipairs(Config.QualityLevels) do
        if currentQuality >= level.min and currentQuality <= level.max then
            return level.mult
        end
    end
    return 1.0
end

local function HarvestGrapes(zoneIndex)
    if not isOnShift then
        Notify('Start your shift first', 'error')
        return
    end
    if grapeCount >= Config.MaxGrapes then
        Notify('Basket is full! Process grapes into wine.', 'error')
        return
    end
    local animDict = 'anim@amb@business@coc@coc_unpack_cut_left@'
    local animClip = 'coke_cut_v1_coccutter'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end
    TaskPlayAnim(playerPed, animDict, animClip, 8.0, -8.0, Config.HarvestTime, 49, 0, false, false, false)
    lib.progressBar({
        duration = Config.HarvestTime,
        label = 'Harvesting grapes...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = animDict, clip = animClip, flags = 49 }
    }, function(cancelled)
        ClearPedTasks(playerPed)
        if not cancelled then
            local harvested = math.random(2, 5)
            if grapeCount + harvested > Config.MaxGrapes then
                harvested = Config.MaxGrapes - grapeCount
            end
            if harvested > 0 then
                grapeCount = grapeCount + harvested
                currentQuality = math.min(100, currentQuality + math.random(1, 5))
                TriggerServerEvent('winery:server:harvestGrapes', zoneIndex, harvested)
                Notify('Harvested ' .. harvested .. ' grapes (Total: ' .. grapeCount .. '/' .. Config.MaxGrapes .. ' | Quality: ' .. GetQualityLabel() .. ')', 'success')
            else
                Notify('Basket is full!', 'error')
            end
        end
    end)
end

local function OpenWinePress()
    if not isOnShift then
        Notify('Start your shift first', 'error')
        return
    end
    if grapeCount <= 0 then
        Notify('No grapes to process', 'error')
        return
    end
    local wineOptions = {}
    for wineType, wineData in pairs(Config.WineTypes) do
        if grapeCount >= wineData.grapes then
            local maxBottles = math.floor(grapeCount / wineData.grapes)
            table.insert(wineOptions, {
                title = 'Make ' .. wineData.label,
                description = wineData.grapes .. ' grapes needed | Sell: $' .. wineData.price .. ' | Time: ' .. (wineData.time / 1000) .. 's | Available: ' .. maxBottles .. ' bottles',
                onSelect = function()
                    StartWineProcess(wineType, wineData)
                end
            })
        else
            table.insert(wineOptions, {
                title = wineData.label,
                description = 'Need ' .. wineData.grapes .. ' grapes (have ' .. grapeCount .. ')',
                disabled = true
            })
        end
    end
    if #wineOptions == 0 then
        Notify('Not enough grapes for any wine type', 'error')
        return
    end
    lib.registerContext({
        id = 'winery_wine_press_menu',
        title = 'Wine Press',
        options = wineOptions
    })
    lib.showContext('winery_wine_press_menu')
end

local function StartWineProcess(wineType, wineData)
    local animDict = 'anim@amb@business@coc@coc_unpack_cut_left@'
    local animClip = 'coke_cut_v1_coccutter'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end
    TaskPlayAnim(playerPed, animDict, animClip, 8.0, -8.0, wineData.time, 49, 0, false, false, false)
    local qualityMult = GetQualityMultiplier()
    lib.progressBar({
        duration = wineData.time,
        label = 'Processing ' .. wineData.label .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = animDict, clip = animClip, flags = 49 }
    }, function(cancelled)
        ClearPedTasks(playerPed)
        if not cancelled then
            if grapeCount < wineData.grapes then
                Notify('Not enough grapes', 'error')
                return
            end
            grapeCount = grapeCount - wineData.grapes
            wineInventory[wineType] = (wineInventory[wineType] or 0) + 1
            local finalQuality = currentQuality
            currentQuality = math.max(0, currentQuality - math.random(5, 15))
            TriggerServerEvent('winery:server:processWine', wineType, wineData, finalQuality, qualityMult)
            Notify('Produced 1x ' .. wineData.label .. ' (Quality: ' .. GetQualityLabel(finalQuality) .. ' | Value: $' .. math.floor(wineData.price * qualityMult) .. ')', 'success')
        end
    end)
end

local function SellWine()
    if not isOnShift then
        Notify('Start your shift first', 'error')
        return
    end
    local hasWine = false
    for _, amount in pairs(wineInventory) do
        if amount > 0 then
            hasWine = true
            break
        end
    end
    if not hasWine then
        local Player = exports.ox_lib:GetPlayer()
        if Player then
            local bottleItem = Player.Functions.GetItemByName(Config.WineBottleItem)
            if not bottleItem or bottleItem.amount <= 0 then
                Notify('No wine bottles to sell', 'error')
                return
            end
        else
            Notify('No wine bottles to sell', 'error')
            return
        end
    end
    local sellOptions = {}
    for wineType, amount in pairs(wineInventory) do
        if amount > 0 and Config.WineTypes[wineType] then
            local wineData = Config.WineTypes[wineType]
            local pricePer = math.floor(wineData.price * GetQualityMultiplier())
            table.insert(sellOptions, {
                title = 'Sell 1x ' .. wineData.label .. ' ($' .. pricePer .. ')',
                description = amount .. ' in inventory',
                onSelect = function()
                    TriggerServerEvent('winery:server:sellWine', wineType, 1, pricePer)
                    wineInventory[wineType] = wineInventory[wineType] - 1
                    if wineInventory[wineType] <= 0 then
                        wineInventory[wineType] = nil
                    end
                end
            })
        end
    end
    if #sellOptions == 0 then
        Notify('No wine to sell', 'error')
        return
    end
    lib.registerContext({
        id = 'winery_sell_menu',
        title = 'Sell Wine to Restaurant',
        options = sellOptions
    })
    lib.showContext('winery_sell_menu')
end

local function StartShift()
    if isOnShift then
        Notify('Already on shift', 'error')
        return
    end
    TriggerServerEvent('winery:server:startShift')
end

local function EndShift()
    if not isOnShift then
        Notify('Not on shift', 'error')
        return
    end
    TriggerServerEvent('winery:server:endShift')
end

RegisterNetEvent('winery:client:startShift', function()
    isOnShift = true
    grapeCount = 0
    wineInventory = {}
    currentQuality = 0
    Notify('Winery shift started! Harvest grapes, make wine, sell to restaurants.', 'success')
end)

RegisterNetEvent('winery:client:endShift', function()
    isOnShift = false
    Notify('Shift ended', 'info')
end)

RegisterNetEvent('winery:client:updateGrapes', function(amount)
    grapeCount = amount
end)

RegisterNetEvent('winery:client:updateWine', function(wineType, amount)
    wineInventory[wineType] = amount
end)

RegisterNetEvent('winery:client:forceEndShift', function()
    isOnShift = false
    grapeCount = 0
    wineInventory = {}
    currentQuality = 0
    Notify('Shift forcefully ended', 'error')
end)

Citizen.CreateThread(function()
    exports.ox_target:addSphereZone({
        coords = Config.VineyardLocation,
        radius = 3.0,
        debug = false,
        options = {
            {
                name = 'winery_start_shift',
                label = 'Start Winery Shift',
                icon = 'fas fa-wine-bottle',
                distance = 2.5,
                canInteract = function()
                    return not isOnShift
                end,
                onSelect = function()
                    StartShift()
                end
            },
            {
                name = 'winery_end_shift',
                label = 'End Winery Shift',
                icon = 'fas fa-stop-circle',
                distance = 2.5,
                canInteract = function()
                    return isOnShift
                end,
                onSelect = function()
                    EndShift()
                end
            }
        }
    })
    exports.ox_target:addSphereZone({
        coords = Config.WinePressLocation,
        radius = 2.0,
        debug = false,
        options = {
            {
                name = 'winery_wine_press',
                label = 'Use Wine Press',
                icon = 'fas fa-industry',
                distance = 2.0,
                canInteract = function()
                    return isOnShift and grapeCount > 0
                end,
                onSelect = function()
                    OpenWinePress()
                end
            }
        }
    })
    exports.ox_target:addSphereZone({
        coords = Config.RestaurantSellLocation,
        radius = 2.0,
        debug = false,
        options = {
            {
                name = 'winery_sell_wine',
                label = 'Sell Wine to Restaurant',
                icon = 'fas fa-dollar-sign',
                distance = 2.0,
                canInteract = function()
                    return isOnShift
                end,
                onSelect = function()
                    SellWine()
                end
            }
        }
    })
    for i, zoneCoords in ipairs(Config.GrapeHarvestZones) do
        exports.ox_target:addSphereZone({
            coords = zoneCoords,
            radius = 2.0,
            debug = false,
            options = {
                {
                    name = 'winery_harvest_' .. i,
                    label = 'Harvest Grapes',
                    icon = 'fas fa-leaf',
                    distance = 2.0,
                    canInteract = function()
                        return isOnShift and grapeCount < Config.MaxGrapes
                    end,
                    onSelect = function()
                        HarvestGrapes(i)
                    end
                }
            }
        })
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isOnShift then
            for i, zoneCoords in ipairs(Config.GrapeHarvestZones) do
                DrawText3D(zoneCoords.x, zoneCoords.y, zoneCoords.z + 1.0, '~g~Grape Vine~w~ [' .. i .. ']')
            end
            local pressPos = Config.WinePressLocation
            DrawText3D(pressPos.x, pressPos.y, pressPos.z + 1.0, '~y~Wine Press~w~ (Process Grapes)')
            local sellPos = Config.RestaurantSellLocation
            DrawText3D(sellPos.x, sellPos.y, sellPos.z + 1.0, '~g~Restaurant~w~ (Sell Wine)')
            local playerPos = GetEntityCoords(playerPed)
            local statusText = 'Grapes: ' .. grapeCount .. '/' .. Config.MaxGrapes .. ' | Quality: ' .. GetQualityLabel()
            if next(wineInventory) then
                local wineStr = ''
                for wt, amt in pairs(wineInventory) do
                    if amt > 0 then
                        wineStr = wineStr .. Config.WineTypes[wt].label .. ' x' .. amt .. ' '
                    end
                end
                statusText = statusText .. ' | Wine: ' .. wineStr
            end
            DrawText3D(playerPos.x, playerPos.y, playerPos.z + 1.0, statusText)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        grapeCount = 0
        wineInventory = {}
        currentQuality = 0
    end
end)
