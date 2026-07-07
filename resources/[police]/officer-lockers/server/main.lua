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

--- Open locker for player
RegisterNetEvent('officerlocker:open', function(locationId)
    local src = source
    if not checkRateLimit(src, 'lockerOpen', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local location = Config.OfficerLockers.locations[locationId]
    if not location then return end
    local jobAllowed = false
    for _, j in ipairs(location.allowedJobs) do
        if player.PlayerData.job.name == j then
            jobAllowed = true
            break
        end
    end
    if not jobAllowed then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not authorized' })
        return
    end
    local citizenid = player.PlayerData.citizenid
    local stashId = 'locker_' .. locationId .. '_' .. citizenid
    TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stashId, { slots = location.stashSlots, weight = location.stashWeight })
end)

--- Admin: clear a specific locker
RegisterNetEvent('officerlocker:admin:clear', function(locationId, targetCID)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local isAdmin = false
    for _, g in ipairs(Config.OfficerLockers.adminGroups) do
        if player.PlayerData.group == g then isAdmin = true end
    end
    if not isAdmin then return end
    local stashId = 'locker_' .. locationId .. '_' .. targetCID
    exports.ox_inventory:ClearStash(stashId)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Locker cleared' })
end)

QBox.Commands.Add('clearlocker', 'Clear a player\'s locker', {}, false, function(source, args)
    local src = source
    local locationId = args[1] or 'lspd'
    local targetCID = args[2]
    if not targetCID then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Usage: /clearlocker [location] [citizenid]' })
        return
    end
    TriggerEvent('officerlocker:admin:clear', locationId, targetCID)
end)
