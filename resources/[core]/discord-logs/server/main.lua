local rateLimitData = {}

local function CheckRateLimit(source)
    if not Config.RateLimits.enabled then return true end
    local current = os.time()
    if not rateLimitData[source] then
        rateLimitData[source] = { timestamps = {}, secondCount = 0, minuteCount = 0, minuteStart = current }
    end
    local data = rateLimitData[source]
    data.timestamps[#data.timestamps + 1] = current
    local recent = 0
    for i = #data.timestamps, 1, -1 do
        if current - data.timestamps[i] <= 1 then
            recent = recent + 1
        else
            break
        end
    end
    while #data.timestamps > 100 do
        table.remove(data.timestamps, 1)
    end
    if current - data.minuteStart >= 60 then
        data.minuteCount = 0
        data.minuteStart = current
    end
    data.secondCount = recent
    data.minuteCount = data.minuteCount + 1
    if data.secondCount > Config.RateLimits.maxPerSecond then return false end
    if data.minuteCount > Config.RateLimits.maxPerMinute then return false end
    return true
end

RegisterNetEvent('discord-logs:server:sendLog', function(category, title, message, color, fields)
    local source = source
    if not source then return end
    if not CheckRateLimit(source) then return end
    if type(message) ~= 'string' then message = json.encode(message) end
    Logs.Custom(category or 'all', title, message, color, fields)
end)

RegisterNetEvent('discord-logs:server:logKill', function(killerName, killerId, victimName, victimId, weapon)
    local source = source
    if not source or not killerName or not victimName then return end
    Logs.Kill(killerName, killerId, victimName, victimId, weapon)
end)

RegisterNetEvent('discord-logs:server:logBank', function(citizenId, type, amount, reason)
    local source = source
    if not source or not citizenId then return end
    Logs.BankTransaction(citizenId, type, amount, reason)
end)

RegisterNetEvent('discord-logs:server:logAdmin', function(adminName, action, targetName)
    local source = source
    if not source then return end
    Logs.AdminAction(adminName, action, targetName)
end)

RegisterNetEvent('discord-logs:server:logInventory', function(playerName, item, amount, fromContainer, toContainer)
    local source = source
    if not source then return end
    Logs.InventoryAction(playerName, item, amount, fromContainer, toContainer)
end)

RegisterNetEvent('discord-logs:server:logAntiCheat', function(playerId, reason, metadata)
    local source = source
    if not source then return end
    if type(metadata) ~= 'table' then metadata = {} end
    Logs.AntiCheat(playerId, reason, metadata)
end)

RegisterNetEvent('discord-logs:server:logVehicle', function(playerName, action, plate, vehicleName)
    local source = source
    if not source then return end
    Logs.VehicleAction(playerName, action, plate, vehicleName)
end)

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    deferrals.update('Loading...')
    Logs.PlayerJoin(playerName, source)
    deferrals.done()
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local playerName = GetPlayerName(source)
    Logs.PlayerLeave(playerName or 'Unknown', source)
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[discord-logs] Discord logging system initialized.^7')
end)

exports('SendLog', Logs.Send)
exports('LogKill', Logs.Kill)
exports('LogBank', Logs.BankTransaction)
exports('LogAdmin', Logs.AdminAction)
exports('LogInventory', Logs.InventoryAction)
exports('LogAntiCheat', Logs.AntiCheat)
exports('LogVehicle', Logs.VehicleAction)
exports('LogCustom', Logs.Custom)
