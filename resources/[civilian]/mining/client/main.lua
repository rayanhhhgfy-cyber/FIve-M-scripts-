local miningSkill = 0
local isMining = false
local isProcessing = false
local currentOre = nil

Citizen.CreateThread(function()
    local blips = {
        { coord = Config.Mining.Locations.mining.coords, sprite = 527, color = 5, label = Config.Mining.Locations.mining.label },
        { coord = Config.Mining.Locations.processing.coords, sprite = 436, color = 1, label = Config.Mining.Locations.processing.label },
        { coord = Config.Mining.Locations.buyer.coords, sprite = 207, color = 2, label = Config.Mining.Locations.buyer.label }
    }
    for _, b in ipairs(blips) do
        local blip = AddBlipForCoord(b.coord.x, b.coord.y, b.coord.z)
        SetBlipSprite(blip, b.sprite)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, b.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(b.label)
        EndTextCommandSetBlipName(blip)
    end
end)

Citizen.CreateThread(function()
    exports.ox_target:addBoxZone({
        coords = Config.Mining.Locations.mining.coords,
        size = vec3(Config.Mining.Locations.mining.radius * 2, Config.Mining.Locations.mining.radius * 2, 10.0),
        rotation = 0,
        debug = false,
        options = {
            {
                icon = Config.Mining.TargetOptions.mine.icon,
                label = Config.Mining.TargetOptions.mine.label,
                distance = Config.Mining.TargetOptions.mine.distance,
                canInteract = function()
                    return not isMining and not isProcessing
                end,
                onSelect = function()
                    StartMining()
                end
            }
        }
    })

    exports.ox_target:addBoxZone({
        coords = Config.Mining.Locations.processing.coords,
        size = vec3(3.0, 3.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            {
                icon = Config.Mining.TargetOptions.process.icon,
                label = Config.Mining.TargetOptions.process.label,
                distance = Config.Mining.TargetOptions.process.distance,
                canInteract = function()
                    return not isProcessing and not isMining
                end,
                onSelect = function()
                    StartProcessing()
                end
            }
        }
    })

    exports.ox_target:addBoxZone({
        coords = Config.Mining.Locations.buyer.coords,
        size = vec3(3.0, 3.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            {
                icon = Config.Mining.TargetOptions.sell.icon,
                label = Config.Mining.TargetOptions.sell.label,
                distance = Config.Mining.TargetOptions.sell.distance,
                onSelect = function()
                    OpenSellMenu()
                end
            }
        }
    })
end)

local function StartMining()
    local ped = PlayerPedId()
    if not HasItem(Config.Mining.PickaxeItem) then
        Wrappers.Notify(Locale('mining', 'need_pickaxe') or 'You need a pickaxe to mine!', 'error')
        return
    end

    isMining = true
    local miningZones = {
        { coords = vector3(2975.0, 2800.0, 42.0), radius = 30.0 },
        { coords = vector3(2950.0, 2780.0, 42.0), radius = 25.0 },
        { coords = vector3(2990.0, 2820.0, 42.0), radius = 20.0 }
    }

    local zone = miningZones[math.random(#miningZones)]
    local mineCoords = vec3(
        zone.coords.x + math.random(-zone.radius, zone.radius),
        zone.coords.y + math.random(-zone.radius, zone.radius),
        zone.coords.z
    )

    local rockHash = GetHashKey('prop_rock_4_d')
    local rock = GetClosestObjectOfType(mineCoords, 10.0, rockHash, false, false, false)
    if rock == 0 then
        rock = CreateObject(rockHash, mineCoords.x, mineCoords.y, mineCoords.z, true, false, false)
        PlaceObjectOnGroundProperly(rock)
        SetEntityAsMissionEntity(rock, true, true)
    end

    local rockCoords = GetEntityCoords(rock)
    SetEntityHeading(ped, GetHeadingFromVector(rockCoords.x - GetEntityCoords(ped).x, rockCoords.y - GetEntityCoords(ped).y))

    local success = lib.progressBar({
        duration = Config.Mining.MiningTime,
        label = Locale('mining', 'mining_progress') or 'Mining...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        allowRagdoll = false,
        anim = {
            dict = 'melee@large_wpn@streamed_core',
            clip = 'ground_attack_on_spot',
            flag = 1
        }
    })

    if success then
        local oreTypes = {}
        for ore, data in pairs(Config.Mining.Ores) do
            if miningSkill >= data.skillReq then
                table.insert(oreTypes, ore)
            end
        end

        local oreChance = {}
        local totalWeight = 0
        for _, ore in ipairs(oreTypes) do
            local weight = 100 - (Config.Mining.Ores[ore].skillReq * 10)
            table.insert(oreChance, { ore = ore, weight = math.max(10, weight) })
            totalWeight = totalWeight + math.max(10, weight)
        end

        local roll = math.random(1, totalWeight)
        local cumulative = 0
        local selectedOre = oreTypes[1]
        for _, entry in ipairs(oreChance) do
            cumulative = cumulative + entry.weight
            if roll <= cumulative then
                selectedOre = entry.ore
                break
            end
        end

        local yieldAmount = math.random(Config.Mining.YieldMin, Config.Mining.YieldMax)
        local skillBonus = math.floor(yieldAmount * miningSkill * Config.Mining.SkillMultiplier)
        local totalYield = yieldAmount + skillBonus

        currentOre = selectedOre
        TriggerServerEvent('mining:collectOre', selectedOre, totalYield)

        SetEntityAsMissionEntity(rock, true, true)
        SetEntityAsNoLongerNeeded(rock)

        Wrappers.Notify(Locale('mining', 'mined', totalYield, Config.Mining.Ores[selectedOre].label) or string.format('Mined %d %s', totalYield, Config.Mining.Ores[selectedOre].label), 'success')

        miningSkill = miningSkill + 1
        TriggerServerEvent('mining:updateSkill', miningSkill)
    else
        Wrappers.Notify(Locale('mining', 'cancelled') or 'Mining cancelled', 'error')
        if DoesEntityExist(rock) then
            SetEntityAsMissionEntity(rock, true, true)
            SetEntityAsNoLongerNeeded(rock)
        end
    end

    isMining = false
end

local function StartProcessing()
    local ped = PlayerPedId()
    local hasOre = false
    local oreToProcess = nil

    for ore, data in pairs(Config.Mining.Ores) do
        if HasItem(ore) then
            hasOre = true
            oreToProcess = ore
            break
        end
    end

    if not hasOre then
        Wrappers.Notify(Locale('mining', 'no_ore') or 'You have no ore to process', 'error')
        return
    end

    isProcessing = true

    local success = lib.progressBar({
        duration = Config.Mining.ProcessingTime,
        label = Locale('mining', 'processing') or 'Smelting ore...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        allowRagdoll = false,
        anim = {
            dict = 'amb@prop_human_bum_bin@idle_a',
            clip = 'idle_a',
            flag = 50
        }
    })

    if success then
        TriggerServerEvent('mining:processOre', oreToProcess)
        Wrappers.Notify(Locale('mining', 'processed', Config.Mining.ProcessedOres[oreToProcess].label) or string.format('Processed into %s', Config.Mining.ProcessedOres[oreToProcess].label), 'success')
    else
        Wrappers.Notify(Locale('mining', 'cancelled') or 'Processing cancelled', 'error')
    end

    isProcessing = false
end

local function OpenSellMenu()
    local options = {}
    local hasAnything = false

    for ore, data in pairs(Config.Mining.Ores) do
        local count = GetItemCount(ore)
        if count > 0 then
            hasAnything = true
            table.insert(options, {
                title = string.format('%s x%d - $%d each', data.label, count, data.price),
                onSelect = function()
                    SellItem(ore, 'ore')
                end
            })
        end
    end

    for processed, data in pairs(Config.Mining.ProcessedOres) do
        local count = GetItemCount(processed .. '_processed')
        if count > 0 then
            hasAnything = true
            table.insert(options, {
                title = string.format('%s x%d - $%d each', data.label, count, data.price),
                onSelect = function()
                    SellItem(processed, 'processed')
                end
            })
        end
    end

    if not hasAnything then
        Wrappers.Notify(Locale('mining', 'nothing_to_sell') or 'Nothing to sell', 'info')
        return
    end

    lib.registerContext({
        id = 'mining_sell_menu',
        title = Locale('mining', 'sell_menu') or 'Sell Items',
        options = options
    })
    lib.showContext('mining_sell_menu')
end

local function SellItem(item, itemType)
    local input = lib.inputDialog(Locale('mining', 'sell_amount') or 'Sell Amount', {
        { type = 'number', label = Locale('mining', 'amount') or 'Amount', default = 1, min = 1 }
    })

    if not input then return end
    local amount = math.floor(input[1])
    if amount <= 0 then return end

    TriggerServerEvent('mining:sellItem', item, amount, itemType)
end

local function HasItem(itemName)
    local items = GetItemInventory()
    if not items then return false end
    for _, item in ipairs(items) do
        if item.name == itemName and item.count > 0 then
            return true
        end
    end
    return false
end

local function GetItemCount(itemName)
    local items = GetItemInventory()
    if not items then return 0 end
    for _, item in ipairs(items) do
        if item.name == itemName then
            return item.count
        end
    end
    return 0
end

local function GetItemInventory()
    local inventory = exports.ox_inventory
    if not inventory then return nil end
    return inventory:GetInventoryItems()
end

RegisterNetEvent('mining:updateSkill', function(skill)
    miningSkill = skill
end)

RegisterNetEvent('mining:sellResult', function(success, message)
    if success then
        Wrappers.Notify(message, 'success')
    else
        Wrappers.Notify(message, 'error')
    end
end)
