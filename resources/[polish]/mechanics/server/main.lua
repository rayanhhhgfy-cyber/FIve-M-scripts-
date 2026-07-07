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

RegisterNetEvent('mechanics:startRepair', function(vehicleNetId)
    local src = source
    if not src or not vehicleNetId then return end
    if not checkRateLimit(src, 'startRepair', 2) then return Notify(src, Locale('mechanics.need_job'), 'error') end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    if player.PlayerData.job.name ~= Config.Mechanics.requiredJob then return Notify(src, Locale('mechanics.need_job'), 'error') end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or vehicle == 0 then return Notify(src, Locale('mechanics.no_vehicle'), 'error') end
    local ped = GetPlayerPed(src)
    local dist = #(GetEntityCoords(ped) - GetEntityCoords(vehicle))
    if dist > 10.0 then return Notify(src, Locale('mechanics.no_vehicle'), 'error') end
    TriggerClientEvent('mechanics:client:doRepair', src, vehicleNetId)
end)

RegisterNetEvent('mechanics:completeRepair', function(vehicleNetId)
    local src = source
    if not src or not vehicleNetId then return end
    if not checkRateLimit(src, 'completeRepair', 2) then return end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    if player.PlayerData.job.name ~= Config.Mechanics.requiredJob then return end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or vehicle == 0 then return end
    local health = GetVehicleEngineHealth(vehicle)
    local newHealth = math.min(health + Config.Mechanics.maxHealthPerRepair, 1000.0)
    SetVehicleEngineHealth(vehicle, newHealth)
    SetVehicleBodyHealth(vehicle, math.min(900.0, GetVehicleBodyHealth(vehicle) + 200.0))
    local cost = math.floor(Config.Mechanics.payment)
    if player.PlayerData.money.cash >= cost then
        player.Functions.RemoveMoney('cash', cost)
        Notify(src, Locale('mechanics.repaired'), 'success')
    elseif player.PlayerData.money.bank >= cost then
        player.Functions.RemoveMoney('bank', cost)
        Notify(src, Locale('mechanics.repaired'), 'success')
    else
        Notify(src, Locale('mechanics.no_money'), 'error')
    end
end)

RegisterNetEvent('mechanics:bill', function(target, amount)
    local src = source
    if not src or not target or not amount then return end
    if not checkRateLimit(src, 'bill', 2) then return end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    if player.PlayerData.job.name ~= Config.Mechanics.requiredJob then return end
    local targetPlayer = QBCore.Functions.GetPlayer(target)
    if not targetPlayer then return Notify(src, Locale('mechanics.no_vehicle'), 'error') end
    local billAmount = math.floor(tonumber(amount))
    if billAmount <= 0 then return end
    if targetPlayer.PlayerData.money.cash >= billAmount then
        targetPlayer.Functions.RemoveMoney('cash', billAmount)
        player.Functions.AddMoney('cash', billAmount)
        Notify(target, Locale('mechanics.bill_amount') .. ': $' .. billAmount, 'info')
        Notify(src, Locale('mechanics.payment_received'), 'success')
    elseif targetPlayer.PlayerData.money.bank >= billAmount then
        targetPlayer.Functions.RemoveMoney('bank', billAmount)
        player.Functions.AddMoney('bank', billAmount)
        Notify(target, Locale('mechanics.bill_amount') .. ': $' .. billAmount, 'info')
        Notify(src, Locale('mechanics.payment_received'), 'success')
    else
        Notify(src, Locale('mechanics.no_money'), 'error')
    end
end)
