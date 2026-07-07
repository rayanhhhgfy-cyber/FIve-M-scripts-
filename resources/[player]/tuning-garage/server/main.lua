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

local function chargePlayer(src, amount)
    if Config.Tuning.useBank then
        local player = QBox.Functions.GetPlayer(src)
        if not player then return false end
        local balance = exports['Renewed-Banking']:GetBalance(player.PlayerData.citizenid)
        if balance < amount then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough money' })
            return false
        end
        exports['Renewed-Banking']:RemoveMoney(nil, amount, 'Vehicle Tuning')
        return true
    else
        local player = QBox.Functions.GetPlayer(src)
        if not player then return false end
        if player.Functions.RemoveMoney('cash', amount) then return true end
        if player.Functions.RemoveMoney('bank', amount) then return true end
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough money' })
        return false
    end
end

--- Install a mod on the vehicle
RegisterNetEvent('tuning:server:installMod', function(modId, modLevel)
    local src = source
    if not checkRateLimit(src, 'tuning', 20) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local modConfig = nil
    for _, m in ipairs(Config.Tuning.mods) do
        if m.id == modId then modConfig = m end
    end
    if not modConfig then return end
    modLevel = math.min(modLevel or 1, modConfig.max)
    local price = modConfig.prices[modLevel]
    if not price then return end

    if not chargePlayer(src, price) then return end
    TriggerClientEvent('tuning:client:applyMod', src, modId, modLevel)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Installed ' .. modConfig.label .. ' Lv.' .. modLevel .. ' ($' .. price .. ')' })
end)

--- Paint vehicle
RegisterNetEvent('tuning:server:paint', function(colorIndex)
    local src = source
    if not checkRateLimit(src, 'tuning', 20) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local color = Config.Tuning.colorPresets[colorIndex]
    if not color then return end
    if not chargePlayer(src, color.price) then return end
    TriggerClientEvent('tuning:client:applyPaint', src, colorIndex)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Painted ' .. color.label .. ' ($' .. color.price .. ')' })
end)

--- Reset all mods
RegisterNetEvent('tuning:server:reset', function()
    local src = source
    if not checkRateLimit(src, 'tuning', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if not chargePlayer(src, 5000) then return end
    TriggerClientEvent('tuning:client:reset', src)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Reset to stock ($5000)' })
end)
