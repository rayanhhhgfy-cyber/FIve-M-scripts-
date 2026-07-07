local QBox = exports['qbx_core']:GetCoreObject()
local RATE_LIMITS = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

local searchedCans = {}

--- Search a trash can
RegisterNetEvent('trashcan:search', function(netId)
    local src = source
    if not checkRateLimit(src, 'trashCan', 10) then return end
    local cooldown = Config.TrashCans.cooldown
    if searchedCans[netId] and os.time() - searchedCans[netId] < cooldown then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already searched recently' })
        return
    end

    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    searchedCans[netId] = os.time()

    -- Roll for loot category
    local roll = math.random(100)
    local lootCategory = nil
    if roll <= 60 then
        lootCategory = 'junk'
    elseif roll <= 85 then
        lootCategory = 'valuables'
    else
        lootCategory = 'evidence'
    end

    local lootPool = Config.TrashCans.lootTable[lootCategory]
    if not lootPool then return end

    -- Pick random items from the pool
    local numItems = math.random(1, 3)
    local given = {}
    for i = 1, numItems do
        local item = lootPool[math.random(#lootPool)]
        if math.random(100) <= item.weight then
            local count = math.random(item.min, item.max)
            if player.Functions.AddItem(item.item, count) then
                table.insert(given, item.label .. ' x' .. count)
            end
        end
    end

    if #given > 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Found: ' .. table.concat(given, ', ') })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Nothing useful in this can' })
    end
end)

-- Cleanup old cooldown entries
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        local now = os.time()
        for k, v in pairs(searchedCans) do
            if now - v > Config.TrashCans.cooldown then
                searchedCans[k] = nil
            end
        end
    end
end)
