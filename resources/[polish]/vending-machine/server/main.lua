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

local function findMachineByModel(model)
    for _, machine in ipairs(Config.Vending.machines) do
        if machine.model == model then return machine end
    end
    return nil
end

local function findItem(machine, itemName)
    for _, item in ipairs(machine.items) do
        if item.name == itemName then return item end
    end
    return nil
end

RegisterNetEvent('vending:machineBuy', function(modelHash, itemName)
    local src = source
    if not src or not modelHash or not itemName then return end
    if not checkRateLimit(src, 'machineBuy', 3) then return Notify(src, Locale('vending.no_money'), 'error') end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local machine = findMachineByModel(modelHash)
    if not machine then return Notify(src, Locale('vending.vending_machine'), 'error') end
    local item = findItem(machine, itemName)
    if not item then return Notify(src, Locale('vending.vending_machine'), 'error') end
    local nearModel = Wrappers.GetClosestVehicle(coords, Config.Vending.maxDistance, { modelHash })
    if not nearModel then return Notify(src, Locale('vending.vending_machine'), 'error') end
    if player.PlayerData.money.cash >= item.price then
        player.Functions.RemoveMoney('cash', math.floor(item.price))
        exports['ox_inventory']:AddItem(src, item.name, 1)
        Notify(src, Locale('vending.bought') .. ' ' .. item.label, 'success')
    elseif player.PlayerData.money.bank >= item.price then
        player.Functions.RemoveMoney('bank', math.floor(item.price))
        exports['ox_inventory']:AddItem(src, item.name, 1)
        Notify(src, Locale('vending.bought') .. ' ' .. item.label, 'success')
    else
        Notify(src, Locale('vending.no_money'), 'error')
    end
end)
