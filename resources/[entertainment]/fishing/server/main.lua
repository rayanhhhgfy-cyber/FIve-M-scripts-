local QBCore = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local activeFishing = {}

local RARITY_WEIGHTS = {
    common = 60,
    uncommon = 25,
    rare = 12,
    legendary = 3,
}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    if not RATE_LIMITS[key] then
        RATE_LIMITS[key] = { count = 1, start = now }
        return true
    end
    if now - RATE_LIMITS[key].start >= 60 then
        RATE_LIMITS[key] = { count = 1, start = now }
        return true
    end
    if RATE_LIMITS[key].count >= maxPerMin then
        return false
    end
    RATE_LIMITS[key].count = RATE_LIMITS[key].count + 1
    return true
end

local function hasItem(src, itemName, count)
    local c = exports.ox_inventory:Search(src, 'count', itemName)
    return (c or 0) >= (count or 1)
end

local function removeItem(src, itemName, count)
    exports.ox_inventory:RemoveItem(src, itemName, count or 1)
end

local function addFishItem(src, fishName, weight)
    exports.ox_inventory:AddItem(src, fishName, 1, { weight = weight })
end

local function selectFish()
    local totalWeight = 0
    for _, fish in ipairs(Config.Fishing.fish) do
        local weight = RARITY_WEIGHTS[fish.rarity] or 1
        totalWeight = totalWeight + weight
    end
    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, fish in ipairs(Config.Fishing.fish) do
        local weight = RARITY_WEIGHTS[fish.rarity] or 1
        cumulative = cumulative + weight
        if roll <= cumulative then
            return fish
        end
    end
    return Config.Fishing.fish[#Config.Fishing.fish]
end

RegisterNetEvent('fishing:cast', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.spot) ~= 'table' then
        return
    end
    if not checkRateLimit(src, 'cast', 2) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    if activeFishing[src] then
        Wrappers.Notify(src, Locale('fishing.cast_line'), 'error')
        return
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not hasItem(src, Config.Fishing.rodItem) then
        Wrappers.Notify(src, Locale('fishing.need_rod'), 'error')
        return
    end
    if not hasItem(src, Config.Fishing.baitItem) then
        Wrappers.Notify(src, Locale('fishing.need_bait'), 'error')
        return
    end
    removeItem(src, Config.Fishing.baitItem)

    local targetFish = selectFish()
    local catchTime = math.random(Config.Fishing.catchTime.min, Config.Fishing.catchTime.max)

    activeFishing[src] = {
        fish = targetFish,
        catchTime = catchTime,
        startTime = os.time(),
    }

    TriggerClientEvent('fishing:castClient', src, catchTime, targetFish)
end)

RegisterNetEvent('fishing:reel', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.success) ~= 'boolean' then
        return
    end
    if not checkRateLimit(src, 'reel', 2) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local session = activeFishing[src]
    if not session then return end

    activeFishing[src] = nil

    if data.success then
        local fish = session.fish
        local weight = fish.minWeight + math.random() * (fish.maxWeight - fish.minWeight)
        weight = tonumber(string.format('%.2f', weight))
        addFishItem(src, fish.name, weight)
        Wrappers.Notify(src, Locale('fishing.fish_caught'), 'success')
    else
        Wrappers.Notify(src, Locale('fishing.fish_lost'), 'error')
    end
end)

RegisterNetEvent('fishing:sellFish', function()
    local src = source
    if not checkRateLimit(src, 'sellFish', 2) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local totalValue = 0
    for _, fishDef in ipairs(Config.Fishing.fish) do
        local count = exports.ox_inventory:Search(src, 'count', fishDef.name)
        if count and count > 0 then
            exports.ox_inventory:RemoveItem(src, fishDef.name, count)
            totalValue = totalValue + (count * fishDef.price)
        end
    end

    if totalValue > 0 then
        Player.Functions.AddMoney('cash', totalValue, nil)
        Wrappers.Notify(src, Locale('fishing.payment'), 'success')
    else
        Wrappers.Notify(src, Locale('fishing.sell_fish'), 'error')
    end
end)
