local QBox = exports['qbx-core']:GetCoreObject()
local ox_target = exports.ox_target
local ox_lib = exports.ox_lib

local isWashing = false
local dailyWashAmount = 0

local function hasDirtyMoney()
    local player = QBox.Functions.GetPlayer()
    if not player then return false end
    local item = player.Functions.GetItemByName(Config.Washing.dirtyMoneyItem)
    return item and item.amount >= Config.Washing.minAmount
end

local function getDirtyMoneyAmount()
    local player = QBox.Functions.GetPlayer()
    if not player then return 0 end
    local item = player.Functions.GetItemByName(Config.Washing.dirtyMoneyItem)
    return item and item.amount or 0
end

local function hasPapers()
    local player = QBox.Functions.GetPlayer()
    if not player then return false end
    local item = player.Functions.GetItemByName(Config.Papers.item)
    return item and item.amount > 0
end

local function startWashing(location)
    if isWashing then return end
    local dirtyAmount = getDirtyMoneyAmount()
    if dirtyAmount < Config.Washing.minAmount then
        return Wrappers.Notify('error', 'Not Enough', 'You need at least $' .. Config.Washing.minAmount .. ' dirty money')
    end
    local washAmount = math.min(dirtyAmount, Config.Washing.maxAmount)
    local input = ox_lib:inputDialog('Launder Money', {
        { type = 'number', label = 'Amount to wash (max $' .. string.format('%.0f', washAmount) .. ')', required = true, min = Config.Washing.minAmount, max = washAmount }
    })
    if not input then return end
    local amount = tonumber(input[1])
    if not amount or amount < Config.Washing.minAmount or amount > washAmount then
        return Wrappers.Notify('error', 'Invalid', 'Invalid amount')
    end
    if dailyWashAmount + amount > Config.Washing.maxDailyWash then
        return Wrappers.Notify('error', 'Daily Limit', 'Daily wash limit reached')
    end
    local usePapers = hasPapers()
    local risk = usePapers and Config.Risk.low or Config.Risk.medium
    isWashing = true
    local success = ox_lib:progressBar({
        duration = location.washTime or Config.Washing.duration,
        label = 'Laundering money...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'amb@prop_human_bum_bin@idle_a', clip = 'idle_a' },
        prop = {}
    })
    if success then
        local skillPass = ox_lib:skillCheck(Config.SkillCheck.difficulty, Config.SkillCheck.areaSize)
        if not skillPass then
            if math.random() < risk.chanceWithPapers then
                Wrappers.Notify('success', 'Lucky', 'Despite the fumble, you got away with it')
            else
                Wrappers.Notify('error', 'Busted', 'You messed up and lost the money')
                QBox:RemoveItem(Config.Washing.dirtyMoneyItem, amount)
                isWashing = false
                return
            end
        end
        local fee = math.floor(amount * (Config.Washing.feePercent / 100))
        local cleanAmount = amount - fee
        if usePapers then
            QBox:RemoveItem(Config.Papers.item, 1)
            cleanAmount = math.floor(cleanAmount * risk.multiplier)
        end
        TriggerServerEvent('money-laundry:server:washMoney', amount, cleanAmount, usePapers, location)
        dailyWashAmount = dailyWashAmount + amount
        if math.random() < Config.Washing.policeAlertChance then
            TriggerServerEvent('money-laundry:server:alertPolice', GetEntityCoords(PlayerPedId()))
        end
    end
    isWashing = false
end

local function setupLocations()
    for _, location in ipairs(Config.LaundryLocations) do
        local targetId = 'laundry_' .. location.business
        ox_target:removeZone(targetId)
        ox_target:addBoxZone({
            name = targetId,
            coords = location.coords,
            size = vec3(1.5, 1.5, 1.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'launder_money_' .. location.business,
                    label = 'Launder Money',
                    icon = 'fas fa-money-bill-wave',
                    onSelect = function()
                        startWashing(location)
                    end,
                    canInteract = function()
                        return hasDirtyMoney() and not isWashing
                    end
                }
            }
        })
    end
end

local function createBlips()
    for _, location in ipairs(Config.LaundryLocations) do
        local blip = AddBlipForCoord(location.coords)
        SetBlipSprite(blip, 478)
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(location.label)
        EndTextCommandSetBlipName(blip)
    end
end

Citizen.CreateThread(function()
    setupLocations()
    createBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    setupLocations()
end)

RegisterNetEvent('money-laundry:client:washComplete', function(cleanAmount)
    Wrappers.Notify('success', 'Laundered', '$' .. cleanAmount .. ' washed successfully')
    dailyWashAmount = dailyWashAmount + cleanAmount
end)

RegisterNetEvent('money-laundry:client:policeAlert', function(coords)
    Wrappers.Notify('error', 'Police Alert', 'Police have been alerted to laundering activity')
end)

RegisterNetEvent('money-laundry:client:resetDaily', function()
    dailyWashAmount = 0
end)
