local QBCore = exports['qbx_core']:GetCoreObject()
local RATE_LIMITS = {}

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

local function Notify(src, msg, type)
    TriggerClientEvent('ox_lib:notify', src, { type = type or 'info', description = msg })
end

local function isAtTattooShop(coords)
    for _, loc in ipairs(Config.Tattoo.locations) do
        local dist = #(coords - loc)
        if dist < 3.0 then return true end
    end
    return false
end

RegisterNetEvent('tattoo:openShop', function()
    local src = source
    if not src then return end
    if not checkRateLimit(src, 'openShop', 2) then return Notify(src, Locale('tattoo_shop.no_money'), 'error') end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    if not isAtTattooShop(coords) then return end
    if player.PlayerData.money.cash >= Config.Tattoo.pricePerTattoo then
        TriggerClientEvent('tattoo:client:openShop', src)
    elseif player.PlayerData.money.bank >= Config.Tattoo.pricePerTattoo then
        TriggerClientEvent('tattoo:client:openShop', src)
    else
        Notify(src, Locale('tattoo_shop.no_money'), 'error')
    end
end)

RegisterNetEvent('tattoo:apply', function(tattooData)
    local src = source
    if not src or not tattooData then return end
    if not checkRateLimit(src, 'apply', 2) then return end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    if not isAtTattooShop(coords) then return end
    local cost = math.floor(Config.Tattoo.pricePerTattoo)
    if player.PlayerData.money.cash >= cost then
        player.Functions.RemoveMoney('cash', cost)
    elseif player.PlayerData.money.bank >= cost then
        player.Functions.RemoveMoney('bank', cost)
    else
        return Notify(src, Locale('tattoo_shop.no_money'), 'error')
    end
    local citizenid = player.PlayerData.citizenid
    local tattoos = MySQL.query.await('SELECT * FROM player_tattoos WHERE citizenid = ?', { citizenid })
    local decoded = {}
    if tattoos and #tattoos > 0 then
        decoded = json.decode(tattoos[1].tattoos) or {}
    end
    decoded[#decoded + 1] = tattooData
    if tattoos and #tattoos > 0 then
        MySQL.query.await('UPDATE player_tattoos SET tattoos = ? WHERE citizenid = ?', { json.encode(decoded), citizenid })
    else
        MySQL.insert.await('INSERT INTO player_tattoos (citizenid, tattoos) VALUES (?, ?)', { citizenid, json.encode(decoded) })
    end
    Notify(src, Locale('tattoo_shop.applied'), 'success')
end)
