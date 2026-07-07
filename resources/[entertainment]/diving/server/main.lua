local QBCore = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    if not RATE_LIMITS[key] then
        RATE_LIMITS[key] = { count = 1, resetAt = now + 60 }
        return true
    end
    if now > RATE_LIMITS[key].resetAt then
        RATE_LIMITS[key] = { count = 1, resetAt = now + 60 }
        return true
    end
    RATE_LIMITS[key].count = RATE_LIMITS[key].count + 1
    if RATE_LIMITS[key].count > maxPerMin then
        return false
    end
    return true
end

local ActiveDivers = {}
local OxygenTimers = {}

local function getRarityWeight(rarity)
    if rarity == 'common' then return 50
    elseif rarity == 'uncommon' then return 30
    elseif rarity == 'rare' then return 15
    elseif rarity == 'legendary' then return 5
    end
    return 0
end

local function rollTreasure()
    local totalWeight = 0
    for _, t in ipairs(Config.Diving.treasure) do
        totalWeight = totalWeight + getRarityWeight(t.rarity)
    end
    local roll = math.random(totalWeight)
    local cumulative = 0
    for _, t in ipairs(Config.Diving.treasure) do
        cumulative = cumulative + getRarityWeight(t.rarity)
        if roll <= cumulative then
            return t
        end
    end
    return Config.Diving.treasure[1]
end

RegisterNetEvent('diving:equipGear', function()
    local src = source
    if not checkRateLimit(src, 'equipGear', 2) then
        return Wrappers.Notify(src, Locale('diving.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if ActiveDivers[src] then
        return Wrappers.Notify(src, Locale('diving.already_equipped'), 'error')
    end

    local hasGear = Player.Functions.GetItemByName(Config.Diving.gearItem)
    local hasTank = Player.Functions.GetItemByName(Config.Diving.tankItem)
    if not hasGear or hasGear.amount < 1 then
        return Wrappers.Notify(src, Locale('diving.need_gear'), 'error')
    end
    if not hasTank or hasTank.amount < 1 then
        return Wrappers.Notify(src, Locale('diving.need_gear'), 'error')
    end

    Player.Functions.RemoveItem(Config.Diving.tankItem, 1)

    ActiveDivers[src] = {
        oxygen = Config.Diving.oxygenPerTank,
        maxOxygen = Config.Diving.oxygenPerTank,
        gearItem = Config.Diving.gearItem,
        active = true,
    }

    if OxygenTimers[src] then
        ClearTimeout(OxygenTimers[src])
    end

    OxygenTimers[src] = SetTimeout(1000, function()
        if not ActiveDivers[src] then return end
        ActiveDivers[src].oxygen = ActiveDivers[src].oxygen - 1
        local oxygen = ActiveDivers[src].oxygen

        TriggerClientEvent('diving:oxygenUpdate', src, oxygen)

        if oxygen <= 0 then
            TriggerClientEvent('diving:lowOxygen', src)
            ActiveDivers[src] = nil
            OxygenTimers[src] = nil
            return
        end

        OxygenTimers[src] = SetTimeout(1000, function()
            if ActiveDivers[src] then
                ActiveDivers[src].oxygen = ActiveDivers[src].oxygen - 1
                TriggerClientEvent('diving:oxygenUpdate', src, ActiveDivers[src].oxygen)
                if ActiveDivers[src].oxygen <= 0 then
                    TriggerClientEvent('diving:lowOxygen', src)
                    ActiveDivers[src] = nil
                    OxygenTimers[src] = nil
                else
                    OxygenTimers[src] = SetTimeout(1000, function()
                        if ActiveDivers[src] then
                            ActiveDivers[src].oxygen = ActiveDivers[src].oxygen - 1
                            TriggerClientEvent('diving:oxygenUpdate', src, ActiveDivers[src].oxygen)
                            if ActiveDivers[src].oxygen <= 0 then
                                TriggerClientEvent('diving:lowOxygen', src)
                                ActiveDivers[src] = nil
                                OxygenTimers[src] = nil
                            end
                        end
                    end)
                end
            end
        end)
    end)

    Wrappers.Notify(src, Locale('diving.gear_equipped'), 'success')
    TriggerClientEvent('diving:oxygenUpdate', src, Config.Diving.oxygenPerTank)
end)

RegisterNetEvent('diving:searchTreasure', function()
    local src = source
    if not checkRateLimit(src, 'searchTreasure', 2) then
        return Wrappers.Notify(src, Locale('diving.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local diver = ActiveDivers[src]
    if not diver or not diver.active then
        return Wrappers.Notify(src, Locale('diving.need_gear'), 'error')
    end

    local treasure = rollTreasure()
    if not treasure then
        return Wrappers.Notify(src, Locale('diving.nothing_found'), 'info')
    end

    Player.Functions.AddItem(treasure.name, 1)
    TriggerClientEvent('diving:treasureFound', src, treasure)
    Wrappers.Notify(src, Locale('diving.found_item', treasure.label), 'success')
end)

RegisterNetEvent('diving:sellTreasure', function(treasureName)
    local src = source
    if not checkRateLimit(src, 'sellTreasure', 2) then
        return Wrappers.Notify(src, Locale('diving.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    local sellLoc = Config.Diving.sellLocation
    local dist = #(pedCoords - sellLoc)
    if dist > 10.0 then
        return Wrappers.Notify(src, Locale('diving.too_far'), 'error')
    end

    local treasureItem = nil
    for _, t in ipairs(Config.Diving.treasure) do
        if t.name == treasureName then
            treasureItem = t
            break
        end
    end
    if not treasureItem then return end

    local item = Player.Functions.GetItemByName(treasureName)
    if not item or item.amount < 1 then
        return Wrappers.Notify(src, Locale('diving.no_treasure'), 'error')
    end

    Player.Functions.RemoveItem(treasureName, 1)
    Player.Functions.AddMoney('cash', treasureItem.price)

    Wrappers.Notify(src, Locale('diving.payment', treasureItem.price), 'success')
end)

RegisterNetEvent('diving:surface', function()
    local src = source
    if not checkRateLimit(src, 'surface', 2) then
        return Wrappers.Notify(src, Locale('diving.too_fast'), 'error')
    end

    if OxygenTimers[src] then
        ClearTimeout(OxygenTimers[src])
        OxygenTimers[src] = nil
    end

    ActiveDivers[src] = nil
    Wrappers.Notify(src, Locale('diving.surfaced'), 'info')
    TriggerClientEvent('diving:oxygenUpdate', src, -1)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if OxygenTimers[src] then
        ClearTimeout(OxygenTimers[src])
        OxygenTimers[src] = nil
    end
    ActiveDivers[src] = nil
end)
