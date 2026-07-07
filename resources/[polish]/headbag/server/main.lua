local QBox = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}
local headbagged = {}

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

RegisterNetEvent('headbag:apply', function(target)
    local src = source
    if not checkRateLimit(src, 'apply', 5) then return end
    target = tonumber(target)
    if not target then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local hasAccess = false
    for _, g in ipairs(Config.Headbag.groups) do
        if player.PlayerData.job.name == g then hasAccess = true end
    end
    if not hasAccess then return Wrappers.Notify(src, Locale('headbag.cannot_apply'), 'error') end
    local item = player.Functions.GetItemByName(Config.Headbag.item)
    if not item then return Wrappers.Notify(src, Locale('headbag.no_item'), 'error') end
    local ped = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)
    local coords = GetEntityCoords(ped)
    local tCoords = GetEntityCoords(targetPed)
    if #(coords - tCoords) > Config.Headbag.maxDistance then return end
    player.Functions.RemoveItem(Config.Headbag.item, 1)
    headbagged[target] = true
    TriggerClientEvent('headbag:applyBag', target)
    TriggerClientEvent('headbag:applied', src)
    Wrappers.Notify(src, Locale('headbag.applied'), 'success')
end)

RegisterNetEvent('headbag:remove', function()
    local src = source
    if not checkRateLimit(src, 'remove', 5) then return end
    if not headbagged[src] then return end
    headbagged[src] = nil
    TriggerClientEvent('headbag:removeBag', src)
    Wrappers.Notify(src, Locale('headbag.removed'), 'success')
end)

RegisterNetEvent('headbag:forceRemove', function(target)
    headbagged[target] = nil
    TriggerClientEvent('headbag:removeBag', target)
end)
