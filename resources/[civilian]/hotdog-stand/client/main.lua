local isWorking = false
local currentStand = nil
local currentStandCoords = nil
local standStock = {}
local npcCustomerActive = false
local playerPed = PlayerPedId()

local function Notify(msg, type)
    lib.notify({ title = 'Hotdog Stand', description = msg, type = type or 'info' })
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

local function SpawnStand(coords)
    if currentStand and DoesEntityExist(currentStand) then
        DeleteEntity(currentStand)
        currentStand = nil
    end
    local model = Config.StandModels[math.random(#Config.StandModels)]
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if not HasModelLoaded(model) then
        Notify('Failed to load stand model', 'error')
        return false
    end
    currentStand = CreateObject(model, coords.x, coords.y, coords.z - 0.5, false, false, false)
    SetEntityHeading(currentStand, coords.w or 0.0)
    PlaceObjectOnGroundProperly(currentStand)
    FreezeEntityPosition(currentStand, true)
    SetModelAsNoLongerNeeded(model)
    currentStandCoords = coords
    return true
end

local function RemoveStand()
    if currentStand and DoesEntityExist(currentStand) then
        DeleteEntity(currentStand)
        currentStand = nil
    end
    currentStandCoords = nil
end

local function OpenShopMenu()
    if not isWorking then
        Notify('You need to start your shift first', 'error')
        return
    end
    local options = {}
    for itemKey, itemData in pairs(Config.Items) do
        local stock = standStock[itemKey] or 0
        local label = itemData.label .. ' ($' .. itemData.price .. ') [' .. stock .. ' left]'
        table.insert(options, {
            title = label,
            description = 'Click to sell one ' .. itemData.label,
            icon = 'hotdog',
            onSelect = function()
                if stock <= 0 then
                    Notify('Out of stock! Restock first.', 'error')
                    return
                end
                TriggerServerEvent('hotdog:server:purchaseItem', itemKey, itemData.price)
            end
        })
    end
    table.insert(options, {
        title = 'Restock Supplies',
        description = 'Restock your stand',
        icon = 'box',
        onSelect = function()
            local supplyOptions = {}
            for _, supply in ipairs(Config.SupplyItems) do
                table.insert(supplyOptions, {
                    title = 'Restock ' .. supply.label,
                    description = 'Gives ' .. supply.give .. ' units',
                    onSelect = function()
                        TriggerServerEvent('hotdog:server:restock', supply.item, supply.give)
                    end
                })
            end
            lib.registerContext({
                id = 'hotdog_restock_menu',
                title = 'Restock Supplies',
                options = supplyOptions
            })
            lib.showContext('hotdog_restock_menu')
        end
    })
    lib.registerContext({
        id = 'hotdog_shop_menu',
        title = 'Hotdog Stand',
        options = options
    })
    lib.showContext('hotdog_shop_menu')
end

local function StartShift(standCoords)
    if isWorking then
        Notify('Already working', 'error')
        return
    end
    isWorking = true
    standStock = {}
    for k, _ in pairs(Config.Items) do
        standStock[k] = Config.MaxStockPerItem
    end
    if not SpawnStand(standCoords) then
        isWorking = false
        return
    end
    TriggerServerEvent('hotdog:server:startShift')
    Notify('Shift started! Stand is open for business.', 'success')
    exports.ox_target:addLocalEntity(currentStand, {
        {
            name = 'hotdog_open_shop',
            label = 'Open Shop',
            icon = 'fas fa-hotdog',
            distance = 2.0,
            onSelect = function()
                OpenShopMenu()
            end
        },
        {
            name = 'hotdog_end_shift',
            label = 'End Shift',
            icon = 'fas fa-stop',
            distance = 2.0,
            onSelect = function()
                EndShift()
            end
        }
    })
end

local function EndShift()
    if not isWorking then
        Notify('Not working', 'error')
        return
    end
    isWorking = false
    RemoveStand()
    TriggerServerEvent('hotdog:server:endShift')
    Notify('Shift ended', 'info')
end

local function NPCCustomer()
    if npcCustomerActive or not isWorking or not currentStand then return end
    npcCustomerActive = true
    local npcModel = 'a_m_m_business_01'
    RequestModel(npcModel)
    local attempts = 0
    while not HasModelLoaded(npcModel) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if not HasModelLoaded(npcModel) then
        npcCustomerActive = false
        return
    end
    local standPos = GetEntityCoords(currentStand)
    local offsetX = math.random(-3, 3)
    local offsetY = math.random(-3, 3)
    local npc = CreatePed(4, npcModel, standPos.x + offsetX, standPos.y + offsetY, standPos.z, math.random(360), false, false)
    SetEntityAsMissionEntity(npc, true, true)
    TaskGoToCoordAnyMeans(npc, standPos.x, standPos.y, standPos.z, 1.0, 0, 0, 786603, 0xbf800000)
    Citizen.CreateThread(function()
        local timeout = 0
        while timeout < 200 do
            Citizen.Wait(50)
            timeout = timeout + 1
            if not DoesEntityExist(npc) then break end
            local npcPos = GetEntityCoords(npc)
            local dist = #(npcPos - standPos)
            if dist < 2.0 then
                TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
                Citizen.Wait(3000)
                local items = {}
                for k, _ in pairs(Config.Items) do
                    table.insert(items, k)
                end
                local chosenItem = items[math.random(#items)]
                local stock = standStock[chosenItem] or 0
                if stock > 0 then
                    standStock[chosenItem] = stock - 1
                    local price = Config.Items[chosenItem].price
                    TriggerServerEvent('hotdog:server:npcSale', chosenItem, price)
                    TaskStartScenarioInPlace(npc, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
                    Citizen.Wait(2000)
                end
                break
            end
        end
        if DoesEntityExist(npc) then
            TaskWanderStandard(npc, 10.0, 10)
            Citizen.SetTimeout(10000, function()
                if DoesEntityExist(npc) then
                    DeletePed(npc)
                end
            end)
        end
        npcCustomerActive = false
    end)
end

RegisterNetEvent('hotdog:client:startShift', function()
end)

RegisterNetEvent('hotdog:client:endShift', function()
    if isWorking then
        isWorking = false
        RemoveStand()
    end
end)

RegisterNetEvent('hotdog:client:updateStock', function(item, amount)
    standStock[item] = (standStock[item] or 0) + amount
    if standStock[item] > Config.MaxStockPerItem then
        standStock[item] = Config.MaxStockPerItem
    end
    Notify('Restocked ' .. (Config.Items[item] and Config.Items[item].label or item), 'success')
end)

RegisterNetEvent('hotdog:client:npcCustomer', function()
    NPCCustomer()
end)

RegisterNetEvent('hotdog:client:syncStock', function(stock)
    standStock = stock
end)

Citizen.CreateThread(function()
    for _, coords in ipairs(Config.StandLocations) do
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 2.0,
            debug = false,
            options = {
                {
                    name = 'hotdog_start_shift',
                    label = 'Start Hotdog Shift',
                    icon = 'fas fa-hotdog',
                    distance = 2.5,
                    canInteract = function()
                        return not isWorking
                    end,
                    onSelect = function()
                        StartShift(coords)
                    end
                }
            }
        })
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isWorking and currentStand and DoesEntityExist(currentStand) then
            local standPos = GetEntityCoords(currentStand)
            local playerPos = GetEntityCoords(playerPed)
            local dist = #(playerPos - standPos)
            if dist > 20.0 then
                DrawText3D(standPos.x, standPos.y, standPos.z + 1.0, '~y~Your Stand~w~ (' .. string.format('%.0fm', dist) .. ')')
            end
            for k, v in pairs(standStock) do
                local label = Config.Items[k] and Config.Items[k].label or k
                DrawText3D(standPos.x, standPos.y, standPos.z + 0.5, label .. ': ' .. tostring(v))
                break
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if currentStand and DoesEntityExist(currentStand) then
            DeleteEntity(currentStand)
        end
    end
end)
