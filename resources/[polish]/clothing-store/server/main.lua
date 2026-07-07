local QBox = exports['qbx-core']:GetCoreObject()
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

RegisterNetEvent('clothing:openStore', function()
    local src = source
    if not checkRateLimit(src, 'openStore', 5) then return Wrappers.Notify(src, Locale('error.rate_limit'), 'error') end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local cash = player.PlayerData.money.cash
    if cash < Config.Clothing.price then return Wrappers.Notify(src, Locale('clothing_store.cost'), 'error') end
    player.Functions.RemoveMoney('cash', Config.Clothing.price, 'clothing-store')
    TriggerClientEvent('clothing:openUI', src)
    Wrappers.Notify(src, Locale('clothing_store.open'), 'success')
end)

RegisterNetEvent('clothing:saveOutfit', function(name)
    local src = source
    if not checkRateLimit(src, 'saveOutfit', 5) then return end
    if type(name) ~= 'string' or string.len(name) < 1 or string.len(name) > 64 then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local citizenid = player.PlayerData.citizenid
    local ped = GetPlayerPed(src)
    local outfit = {
        model = GetEntityModel(ped),
        drawables = {},
        props = {},
        tattoos = {},
    }
    for i = 0, 11 do
        outfit.drawables[i] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i),
            palette = GetPedPaletteVariation(ped, i),
        }
    end
    for i = 0, 4 do
        outfit.props[i] = {
            drawable = GetPedPropIndex(ped, i),
            texture = GetPedPropTextureIndex(ped, i),
        }
    end
    MySQL.insert('INSERT INTO outfits (citizenid, name, outfit) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE outfit = VALUES(outfit)', {
        citizenid, name, json.encode(outfit)
    })
    Wrappers.Notify(src, Locale('clothing_store.saved'), 'success')
end)

RegisterNetEvent('clothing:loadOutfit', function(name)
    local src = source
    if not checkRateLimit(src, 'loadOutfit', 5) then return end
    if type(name) ~= 'string' then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local result = MySQL.query('SELECT outfit FROM outfits WHERE citizenid = ? AND name = ?', { player.PlayerData.citizenid, name })
    if result and result[1] then
        TriggerClientEvent('clothing:applyOutfit', src, json.decode(result[1].outfit))
    end
end)
