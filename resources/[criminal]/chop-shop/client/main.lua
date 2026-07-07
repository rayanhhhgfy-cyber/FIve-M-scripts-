local QBox = exports['qbx-core']:GetCoreObject()
local ox_target = exports.ox_target
local ox_lib = exports.ox_lib

local isWorking = false
local currentVehicle = nil

local function hasItem(itemName)
    local player = QBox.Functions.GetPlayer()
    if not player then return false end
    local item = player.Functions.GetItemByName(itemName)
    return item and item.amount > 0
end

local function getSkillSpeed()
    local exp = QBox.Functions.GetPlayer().PlayerData.metadata.chopshop_exp or 0
    for i = #Config.SkillLevels, 1, -1 do
        if exp >= Config.SkillLevels[i].exp then
            return Config.SkillLevels[i].stripSpeed
        end
    end
    return 1.0
end

local function addExp(amount)
    local exp = QBox.Functions.GetPlayer().PlayerData.metadata.chopshop_exp or 0
    exp = exp + amount
    QBox:SetMetaData('chopshop_exp', exp)
end

local function isVehicleStolen(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    if plate and plate ~= '' then
        return true
    end
    return false
end

local function stripPart(vehicle, partName)
    if isWorking then return end
    if not hasItem(Config.Tools.crowbarItem) then
        return Wrappers.Notify('error', 'No Crowbar', 'You need a crowbar to strip parts')
    end
    isWorking = true
    local speed = getSkillSpeed()
    local duration = Config.Stripping.duration * speed
    local success = ox_lib:progressBar({
        duration = math.floor(duration),
        label = 'Stripping ' .. Config.Parts[partName].label .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        prop = {}
    })
    if success then
        local skillPass = ox_lib:skillCheck(Config.Stripping.skillCheck.difficulty, Config.Stripping.skillCheck.areaSize)
        if skillPass then
            TriggerServerEvent('chop-shop:server:stripPart', partName, GetVehicleNumberPlateText(vehicle))
            addExp(50)
            if math.random() < Config.Stripping.policeAlertChance then
                TriggerServerEvent('chop-shop:server:alertPolice', GetEntityCoords(PlayerPedId()))
            end
        else
            Wrappers.Notify('error', 'Failed', 'You damaged the part')
        end
    end
    isWorking = false
end

local function removeVIN(vehicle)
    if isWorking then return end
    if not hasItem(Config.Tools.grindstoneItem) then
        return Wrappers.Notify('error', 'No Grinder', 'You need an angle grinder')
    end
    isWorking = true
    local success = ox_lib:progressBar({
        duration = Config.VINRemoval.duration,
        label = 'Grinding VIN Number...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'weapon@weld_joint', clip = 'weld_joint_metal' },
        prop = {}
    })
    if success then
        local skillPass = ox_lib:skillCheck(Config.VINRemoval.skillCheck.difficulty, Config.VINRemoval.skillCheck.areaSize)
        if skillPass then
            TriggerServerEvent('chop-shop:server:removeVIN', GetVehicleNumberPlateText(vehicle))
            addExp(150)
            if math.random() < Config.VINRemoval.policeAlertChance then
                TriggerServerEvent('chop-shop:server:alertPolice', GetEntityCoords(PlayerPedId()))
            end
        else
            Wrappers.Notify('error', 'Failed', 'You messed up the VIN plate')
        end
    end
    isWorking = false
end

local function scrapVehicle(vehicle)
    if isWorking then return end
    isWorking = true
    local success = ox_lib:progressBar({
        duration = Config.Scrap.scrapDuration,
        label = 'Crushing Vehicle for Scrap...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        prop = {}
    })
    if success then
        TriggerServerEvent('chop-shop:server:scrapVehicle', GetVehicleNumberPlateText(vehicle))
        addExp(25)
        if math.random() < Config.Scrap.policeAlertChance then
            TriggerServerEvent('chop-shop:server:alertPolice', GetEntityCoords(PlayerPedId()))
        end
    end
    isWorking = false
end

local function sellScrap()
    if isWorking then return end
    if not hasItem(Config.Scrap.scrapItem) then
        return Wrappers.Notify('error', 'No Scrap', 'No scrap to sell')
    end
    isWorking = true
    local success = ox_lib:progressBar({
        duration = 3000,
        label = 'Selling scrap...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mp_common', clip = 'givetake1_a' },
        prop = {}
    })
    if success then
        TriggerServerEvent('chop-shop:server:sellScrap')
    end
    isWorking = false
end

local function openVehicleMenu(vehicle)
    local options = {}
    for partName, partData in pairs(Config.Parts) do
        options[#options + 1] = {
            title = 'Strip ' .. partData.label,
            description = '$' .. partData.basePrice,
            onSelect = function()
                stripPart(vehicle, partName)
            end,
            disabled = not hasItem(Config.Tools.crowbarItem)
        }
    end
    options[#options + 1] = {
        title = 'Remove VIN',
        description = '$' .. Config.VINRemoval.reward,
        onSelect = function()
            removeVIN(vehicle)
        end,
        disabled = not hasItem(Config.Tools.grindstoneItem)
    }
    options[#options + 1] = {
        title = 'Crush for Scrap',
        description = Config.Scrap.scrapPerVehicle .. ' scrap pieces',
        onSelect = function()
            scrapVehicle(vehicle)
        end
    }
    ox_lib:registerContext({
        id = 'chop_vehicle_menu',
        title = 'Chop Shop',
        options = options
    })
    ox_lib:showContext('chop_vehicle_menu')
end

local function setupChopZones()
    for _, location in ipairs(Config.ChopLocations) do
        local targetId = 'chop_shop_' .. _.label
        ox_target:removeZone(targetId)
        ox_target:addBoxZone({
            name = targetId,
            coords = location.coords,
            size = vec3(8.0, 8.0, 3.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'chop_vehicle_' .. _.label,
                    label = 'Chop Vehicle',
                    icon = 'fas fa-car-crash',
                    onSelect = function()
                        local ped = PlayerPedId()
                        local vehicle = GetVehiclePedIsIn(ped, false)
                        if not vehicle or vehicle == 0 then
                            vehicle = GetClosestVehicle(location.coords, 5.0)
                        end
                        if vehicle and vehicle ~= 0 then
                            currentVehicle = vehicle
                            openVehicleMenu(vehicle)
                        else
                            Wrappers.Notify('error', 'No Vehicle', 'No vehicle nearby')
                        end
                    end,
                    canInteract = function()
                        return not isWorking
                    end
                },
                {
                    name = 'sell_scrap_' .. _.label,
                    label = 'Sell Scrap',
                    icon = 'fas fa-recycle',
                    onSelect = function()
                        sellScrap()
                    end,
                    canInteract = function()
                        return hasItem(Config.Scrap.scrapItem) and not isWorking
                    end
                }
            }
        })
    end
end

local function createBlips()
    for _, location in ipairs(Config.ChopLocations) do
        local blip = AddBlipForCoord(location.coords)
        SetBlipSprite(blip, 446)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 1)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(location.label)
        EndTextCommandSetBlipName(blip)
    end
end

Citizen.CreateThread(function()
    setupChopZones()
    createBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    setupChopZones()
end)

RegisterNetEvent('chop-shop:client:partStripped', function(partLabel)
    Wrappers.Notify('success', 'Stripped', partLabel .. ' added to inventory')
end)

RegisterNetEvent('chop-shop:client:vinRemoved', function()
    Wrappers.Notify('success', 'VIN Removed', 'VIN number ground off')
end)

RegisterNetEvent('chop-shop:client:scrapReceived', function(amount)
    Wrappers.Notify('success', 'Scrap', 'Received ' .. amount .. ' scrap')
end)

RegisterNetEvent('chop-shop:client:scrapSold', function(price)
    Wrappers.Notify('success', 'Sold', 'Scrap sold for $' .. price)
end)

RegisterNetEvent('chop-shop:client:policeAlert', function(coords)
    Wrappers.Notify('error', 'Police Alert', 'Chop shop activity reported')
end)
