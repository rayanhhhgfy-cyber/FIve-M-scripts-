local isOnShift = false
local currentWood = {}
local currentWoodCount = 0
local treeStates = {}
local choppedTrees = {}
local playerPed = PlayerPedId()

local function Notify(msg, type)
    lib.notify({ title = 'Lumberjack', description = msg, type = type or 'info' })
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

local function HasAxe()
    local Player = exports.ox_lib:GetPlayer()
    if not Player then return false end
    if Player.Functions.GetItemByName(Config.AxeItem) then
        return true
    end
    if Config.ChainsawItem and Player.Functions.GetItemByName(Config.ChainsawItem) then
        return true
    end
    return false
end

local function ChopTree(treeIndex, treeCoords)
    if not HasAxe() then
        Notify('You need an axe or chainsaw', 'error')
        return
    end
    if currentWoodCount >= Config.MaxWoodCarry then
        Notify('Inventory full! Process or sell wood first.', 'error')
        return
    end
    if choppedTrees[treeIndex] then
        Notify('This tree has been cut recently', 'error')
        return
    end
    local propTree = GetClosestObjectOfType(treeCoords.x, treeCoords.y, treeCoords.z, 5.0, GetHashKey('prop_tree_f_ci_v_01'), false, false, true)
    if not propTree or not DoesEntityExist(propTree) then
        for _, model in ipairs(Config.TreeModels) do
            propTree = GetClosestObjectOfType(treeCoords.x, treeCoords.y, treeCoords.z, 5.0, GetHashKey(model), false, false, true)
            if propTree and DoesEntityExist(propTree) then break end
        end
    end
    local treeObj = propTree
    local Player = exports.ox_lib:GetPlayer()
    if not Player then return end
    local hasChainsaw = Config.ChainsawItem and Player.Functions.GetItemByName(Config.ChainsawItem)
    local chopTime = hasChainsaw and math.floor(Config.ChopTime * 0.5) or Config.ChopTime
    local animDict = hasChainsaw and 'melee@small_wpn@streamed_core' or 'melee@hatchet@streamed_core'
    local animClip = hasChainsaw and 'ground_attack_on_spot' or 'plyr_front_left'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end
    TaskPlayAnim(playerPed, animDict, animClip, 8.0, -8.0, chopTime, 49, 0, false, false, false)
    if hasChainsaw then
        local chainsawProp = CreateObject(GetHashKey('prop_tool_chainsaw'), 0, 0, 0, true, true, true)
        AttachEntityToEntity(chainsawProp, playerPed, GetPedBoneIndex(playerPed, 57005), 0.12, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        lib.progressBar({
            duration = chopTime,
            label = 'Chopping tree with chainsaw...',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true }
        }, function(cancelled)
            if DoesEntityExist(chainsawProp) then DeleteEntity(chainsawProp) end
            ClearPedTasks(playerPed)
            if not cancelled then
                OnTreeChopped(treeIndex, treeCoords, treeObj)
            end
        end)
    else
        lib.progressBar({
            duration = chopTime,
            label = 'Chopping tree with axe...',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true }
        }, function(cancelled)
            ClearPedTasks(playerPed)
            if not cancelled then
                OnTreeChopped(treeIndex, treeCoords, treeObj)
            end
        end)
    end
end

local function OnTreeChopped(treeIndex, treeCoords, treeObj)
    local woodTypes = {}
    for k, _ in pairs(Config.WoodTypes) do
        table.insert(woodTypes, k)
    end
    local chosenWood = woodTypes[math.random(#woodTypes)]
    local amount = math.random(1, 3)
    if currentWoodCount + amount > Config.MaxWoodCarry then
        amount = Config.MaxWoodCarry - currentWoodCount
    end
    if amount <= 0 then
        Notify('Inventory full!', 'error')
        return
    end
    currentWood[chosenWood] = (currentWood[chosenWood] or 0) + amount
    currentWoodCount = currentWoodCount + amount
    choppedTrees[treeIndex] = true
    if treeObj and DoesEntityExist(treeObj) then
        SetEntityAsMissionEntity(treeObj, true, true)
        DeleteEntity(treeObj)
    end
    TriggerServerEvent('lumberjack:server:chopTree', treeIndex, chosenWood, amount)
    Notify('Chopped ' .. amount .. 'x ' .. Config.WoodTypes[chosenWood].label, 'success')
    Citizen.SetTimeout(Config.TreeRespawnTime, function()
        choppedTrees[treeIndex] = nil
        TriggerServerEvent('lumberjack:server:respawnTree', treeIndex)
    end)
end

local function ProcessWood()
    if currentWoodCount <= 0 then
        Notify('No wood to process', 'error')
        return
    end
    local woodOptions = {}
    for woodType, amount in pairs(currentWood) do
        if amount > 0 then
            table.insert(woodOptions, {
                title = Config.WoodTypes[woodType].label .. ' (x' .. amount .. ')',
                description = 'Process into planks',
                onSelect = function()
                    StartProcessing(woodType)
                end
            })
        end
    end
    if #woodOptions == 0 then
        Notify('No wood to process', 'error')
        return
    end
    lib.registerContext({
        id = 'lumberjack_process_menu',
        title = 'Process Wood',
        options = woodOptions
    })
    lib.showContext('lumberjack_process_menu')
end

local function StartProcessing(woodType)
    local amount = currentWood[woodType] or 0
    if amount <= 0 then
        Notify('No ' .. woodType .. ' wood to process', 'error')
        return
    end
    local processAmount = math.min(amount, 5)
    local animDict = 'anim@amb@business@coc@coc_unpack_cut_left@'
    local animClip = 'coke_cut_v1_coccutter'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end
    TaskPlayAnim(playerPed, animDict, animClip, 8.0, -8.0, Config.ProcessTime, 49, 0, false, false, false)
    lib.progressBar({
        duration = Config.ProcessTime,
        label = 'Processing ' .. Config.WoodTypes[woodType].label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = animDict, clip = animClip, flags = 49 }
    }, function(cancelled)
        ClearPedTasks(playerPed)
        if not cancelled then
            currentWood[woodType] = currentWood[woodType] - processAmount
            currentWoodCount = currentWoodCount - processAmount
            TriggerServerEvent('lumberjack:server:processWood', woodType, processAmount)
            Notify('Processed ' .. processAmount .. 'x ' .. Config.WoodTypes[woodType].label .. ' into planks', 'success')
        end
    end)
end

local function SellPlanks()
    local Player = exports.ox_lib:GetPlayer()
    if not Player then return end
    local planks = Player.Functions.GetItemByName(Config.PlanksItem)
    if not planks or planks.amount <= 0 then
        Notify('No planks to sell', 'error')
        return
    end
    local amount = planks.amount
    local price = amount * Config.SellPricePerPlank
    lib.registerContext({
        id = 'lumberjack_sell_menu',
        title = 'Sell Planks',
        options = {
            {
                title = 'Sell ' .. amount .. ' planks for $' .. price,
                description = 'Current price: $' .. Config.SellPricePerPlank .. ' per plank',
                onSelect = function()
                    TriggerServerEvent('lumberjack:server:sellPlanks', amount, price)
                end
            }
        }
    })
    lib.showContext('lumberjack_sell_menu')
end

local function StartShift()
    if isOnShift then
        Notify('Already on shift', 'error')
        return
    end
    if not HasAxe() then
        Notify('You need an axe to start working', 'error')
        return
    end
    TriggerServerEvent('lumberjack:server:startShift')
end

local function EndShift()
    if not isOnShift then
        Notify('Not on shift', 'error')
        return
    end
    TriggerServerEvent('lumberjack:server:endShift')
end

RegisterNetEvent('lumberjack:client:startShift', function()
    isOnShift = true
    currentWood = {}
    currentWoodCount = 0
    Notify('Lumberjack shift started! Chop trees and process them.', 'success')
end)

RegisterNetEvent('lumberjack:client:endShift', function()
    isOnShift = false
    Notify('Shift ended', 'info')
end)

RegisterNetEvent('lumberjack:client:syncChopped', function(treeIndex, state)
    if state then
        choppedTrees[treeIndex] = true
    else
        choppedTrees[treeIndex] = nil
    end
end)

RegisterNetEvent('lumberjack:client:addWood', function(woodType, amount)
    currentWood[woodType] = (currentWood[woodType] or 0) + amount
    currentWoodCount = currentWoodCount + amount
end)

RegisterNetEvent('lumberjack:client:removeWood', function(woodType, amount)
    currentWood[woodType] = math.max(0, (currentWood[woodType] or 0) - amount)
    currentWoodCount = math.max(0, currentWoodCount - amount)
end)

Citizen.CreateThread(function()
    for i, coords in ipairs(Config.TreeLocations) do
        local treeModel = Config.TreeModels[math.random(#Config.TreeModels)]
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 2.5,
            debug = false,
            options = {
                {
                    name = 'lumberjack_chop_' .. i,
                    label = 'Chop Tree',
                    icon = 'fas fa-tree',
                    distance = 3.0,
                    canInteract = function()
                        return isOnShift and not choppedTrees[i] and HasAxe()
                    end,
                    onSelect = function()
                        ChopTree(i, coords)
                    end
                },
                {
                    name = 'lumberjack_inspect_' .. i,
                    label = 'Inspect Tree',
                    icon = 'fas fa-search',
                    distance = 3.0,
                    canInteract = function()
                        return isOnShift
                    end,
                    onSelect = function()
                        local states = { 'Healthy', 'Ready to cut', 'Tall and strong', 'Good lumber quality' }
                        Notify('Tree looks ' .. states[math.random(#states)], 'info')
                    end
                }
            }
        })
    end
    exports.ox_target:addSphereZone({
        coords = Config.SawmillLocation,
        radius = 2.0,
        debug = false,
        options = {
            {
                name = 'lumberjack_sawmill',
                label = 'Process Wood at Sawmill',
                icon = 'fas fa-industry',
                distance = 2.5,
                canInteract = function()
                    return isOnShift and currentWoodCount > 0
                end,
                onSelect = function()
                    ProcessWood()
                end
            }
        }
    })
    exports.ox_target:addSphereZone({
        coords = Config.SellLocation,
        radius = 2.0,
        debug = false,
        options = {
            {
                name = 'lumberjack_sell',
                label = 'Sell Planks',
                icon = 'fas fa-dollar-sign',
                distance = 2.5,
                canInteract = function()
                    return isOnShift
                end,
                onSelect = function()
                    local Player = exports.ox_lib:GetPlayer()
                    if Player and Player.Functions.GetItemByName(Config.PlanksItem) and Player.Functions.GetItemByName(Config.PlanksItem).amount > 0 then
                        SellPlanks()
                    else
                        Notify('No planks to sell', 'error')
                    end
                end
            }
        }
    })
    exports.ox_target:addSphereZone({
        coords = Config.TreeLocations[1],
        radius = 2.0,
        debug = false,
        options = {
            {
                name = 'lumberjack_start_shift',
                label = 'Start Lumberjack Shift',
                icon = 'fas fa-play',
                distance = 2.5,
                canInteract = function()
                    return not isOnShift
                end,
                onSelect = function()
                    StartShift()
                end
            },
            {
                name = 'lumberjack_end_shift',
                label = 'End Lumberjack Shift',
                icon = 'fas fa-stop',
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
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isOnShift then
            for i, coords in ipairs(Config.TreeLocations) do
                if not choppedTrees[i] then
                    DrawText3D(coords.x, coords.y, coords.z + 2.5, '~g~Tree~w~ [' .. i .. ']')
                else
                    DrawText3D(coords.x, coords.y, coords.z + 2.5, '~r~Chopped~w~ [' .. i .. ']')
                end
            end
            local sawmillPos = Config.SawmillLocation
            DrawText3D(sawmillPos.x, sawmillPos.y, sawmillPos.z + 1.0, '~y~Sawmill~w~ (Process Wood)')
            local sellPos = Config.SellLocation
            DrawText3D(sellPos.x, sellPos.y, sellPos.z + 1.0, '~g~Sell Planks~w~ ($' .. Config.SellPricePerPlank .. '/ea)')
            local woodStr = 'Wood: '
            for wt, amt in pairs(currentWood) do
                if amt > 0 then
                    woodStr = woodStr .. Config.WoodTypes[wt].label .. ' x' .. amt .. ' '
                end
            end
            if currentWoodCount == 0 then
                woodStr = 'Wood: None'
            end
            local playerPos = GetEntityCoords(playerPed)
            DrawText3D(playerPos.x, playerPos.y, playerPos.z + 1.0, woodStr)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        currentWood = {}
        currentWoodCount = 0
        choppedTrees = {}
    end
end)
