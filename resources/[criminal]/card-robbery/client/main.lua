local QBox = exports['qbx-core']:GetCoreObject()
local ox_target = exports.ox_target
local ox_lib = exports.ox_lib

local installedSkimmers = {}
local isOperating = false

local function hasItem(itemName)
    local player = QBox.Functions.GetPlayer()
    if not player then return false end
    local item = player.Functions.GetItemByName(itemName)
    return item and item.amount > 0
end

local function installSkimmer(atm)
    if isOperating then return end
    if not hasItem(Config.Skimming.deviceItem) then
        return Wrappers.Notify('error', 'No Skimmer', 'You need a card skimmer')
    end
    isOperating = true
    local success = ox_lib:progressBar({
        duration = Config.Skimming.installTime,
        label = 'Installing Skimmer...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        prop = {}
    })
    if success then
        local skillPass = ox_lib:skillCheck(Config.SkillCheck.difficulty, Config.SkillCheck.areaSize)
        if skillPass then
            QBox:RemoveItem(Config.Skimming.deviceItem, 1)
            TriggerServerEvent('card-robbery:server:installSkimmer', atm)
            Wrappers.Notify('success', 'Installed', 'Skimmer installed at ' .. atm.label)
        else
            Wrappers.Notify('error', 'Failed', 'Failed to install skimmer')
        end
    end
    isOperating = false
end

local function collectData(atm)
    if isOperating then return end
    isOperating = true
    local success = ox_lib:progressBar({
        duration = Config.Skimming.collectTime,
        label = 'Collecting Card Data...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
        prop = {}
    })
    if success then
        TriggerServerEvent('card-robbery:server:collectData', atm)
        if math.random() < Config.Skimming.policeAlertChance then
            TriggerServerEvent('card-robbery:server:alertPolice', GetEntityCoords(PlayerPedId()))
        end
    end
    isOperating = false
end

local function encodeCards()
    if isOperating then return end
    if not hasItem(Config.CardFraud.blankCardItem) then
        return Wrappers.Notify('error', 'No Blank Cards', 'You need blank cards')
    end
    if not hasItem('card_data') then
        return Wrappers.Notify('error', 'No Card Data', 'You need stolen card data')
    end
    isOperating = true
    local success = ox_lib:progressBar({
        duration = Config.CardFraud.encodeTime,
        label = 'Encoding Cards...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
        prop = {}
    })
    if success then
        local skillPass = ox_lib:skillCheck({ 'medium', 'hard' }, 50)
        if skillPass then
            QBox:RemoveItem('card_data', 1)
            QBox:RemoveItem(Config.CardFraud.blankCardItem, 1)
            QBox:AddItem(Config.CardFraud.encodedCardItem, 1)
            Wrappers.Notify('success', 'Encoded', 'Card encoded successfully')
        else
            QBox:RemoveItem('card_data', 1)
            QBox:RemoveItem(Config.CardFraud.blankCardItem, 1)
            Wrappers.Notify('error', 'Failed', 'Card destroyed in encoding')
        end
    end
    isOperating = false
end

local function commitFraud()
    if isOperating then return end
    if not hasItem(Config.CardFraud.encodedCardItem) then
        return Wrappers.Notify('error', 'No Encoded Card', 'You need an encoded card')
    end
    isOperating = true
    local success = ox_lib:progressBar({
        duration = Config.CardFraud.fraudTime,
        label = 'Processing Fraudulent Transaction...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'amb@prop_human_atm@male@idle_a', clip = 'idle_a' },
        prop = {}
    })
    if success then
        TriggerServerEvent('card-robbery:server:commitFraud')
        if math.random() < Config.CardFraud.traceChance then
            TriggerServerEvent('card-robbery:server:alertPolice', GetEntityCoords(PlayerPedId()))
            Wrappers.Notify('error', 'Traced', 'The transaction was traced by the bank!')
        end
    end
    isOperating = false
end

local function setupATMs()
    for _, atm in ipairs(Config.ATM_Locations) do
        local targetId = 'card_atm_' .. _.label
        ox_target:removeZone(targetId)
        ox_target:addBoxZone({
            name = targetId,
            coords = atm.coords,
            size = vec3(1.2, 1.2, 1.5),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'install_skimmer_' .. _.label,
                    label = 'Install Skimmer',
                    icon = 'fas fa-microchip',
                    onSelect = function()
                        installSkimmer(atm)
                    end,
                    canInteract = function()
                        return hasItem(Config.Skimming.deviceItem) and not installedSkimmers[atm.label] and not isOperating
                    end
                },
                {
                    name = 'collect_data_' .. _.label,
                    label = 'Collect Card Data',
                    icon = 'fas fa-database',
                    onSelect = function()
                        collectData(atm)
                    end,
                    canInteract = function()
                        return installedSkimmers[atm.label] and not isOperating
                    end
                },
                {
                    name = 'commit_fraud_' .. _.label,
                    label = 'Use Encoded Card',
                    icon = 'fas fa-credit-card',
                    onSelect = function()
                        commitFraud()
                    end,
                    canInteract = function()
                        return hasItem(Config.CardFraud.encodedCardItem) and not isOperating
                    end
                }
            }
        })
    end
end

local function setupLaptops()
    for _, laptop in ipairs(Config.LaptopLocations) do
        local targetId = 'card_laptop_' .. _.label
        ox_target:removeZone(targetId)
        ox_target:addBoxZone({
            name = targetId,
            coords = laptop.coords,
            size = vec3(1.0, 1.0, 1.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'encode_cards_' .. _.label,
                    label = 'Encode Cards',
                    icon = 'fas fa-laptop',
                    onSelect = function()
                        encodeCards()
                    end,
                    canInteract = function()
                        return hasItem(Config.CardFraud.blankCardItem) and hasItem('card_data') and not isOperating
                    end
                }
            }
        })
    end
end

Citizen.CreateThread(function()
    setupATMs()
    setupLaptops()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    setupATMs()
    setupLaptops()
    TriggerServerEvent('card-robbery:server:getInstalledSkimmers')
end)

RegisterNetEvent('card-robbery:client:setSkimmers', function(skimmers)
    installedSkimmers = skimmers or {}
end)

RegisterNetEvent('card-robbery:client:skimmerInstalled', function(atmLabel)
    installedSkimmers[atmLabel] = true
end)

RegisterNetEvent('card-robbery:client:dataCollected', function()
    Wrappers.Notify('success', 'Data Collected', 'Card data retrieved from skimmer')
end)

RegisterNetEvent('card-robbery:client:fraudComplete', function(payout)
    Wrappers.Notify('success', 'Fraud Complete', 'Received $' .. payout)
end)

RegisterNetEvent('card-robbery:client:policeAlert', function(coords)
    Wrappers.Notify('error', 'Police Alert', 'Card fraud detected by bank security')
end)

RegisterNetEvent('card-robbery:client:skimmerRemoved', function(atmLabel)
    installedSkimmers[atmLabel] = nil
end)
