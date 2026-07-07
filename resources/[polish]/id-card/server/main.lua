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

RegisterNetEvent('idcard:show', function()
    local src = source
    if not src then return end
    if not checkRateLimit(src, 'show', 2) then return Notify(src, Locale('id_card.refused'), 'error') end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local charinfo = player.PlayerData.charinfo
    local data = {
        firstName = charinfo.firstname,
        lastName = charinfo.lastname,
        dob = charinfo.birthdate,
        sex = charinfo.gender == 0 and 'Male' or 'Female',
        citizenid = player.PlayerData.citizenid,
        nationality = charinfo.nationality,
        issued = player.PlayerData.charinfo.account,
    }
    TriggerClientEvent('idcard:client:display', src, data)
end)

RegisterNetEvent('idcard:request', function(target)
    local src = source
    if not src or not target then return end
    if not checkRateLimit(src, 'request', 2) then return Notify(src, Locale('id_card.refused'), 'error') end
    if not QBCore.Functions.GetPlayer(target) then return Notify(src, Locale('id_card.no_player'), 'error') end
    TriggerClientEvent('idcard:client:request', target, src)
end)

RegisterNetEvent('idcard:respond', function(target, accepted)
    local src = source
    if not src or not target then return end
    if accepted then
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return end
        local charinfo = player.PlayerData.charinfo
        local data = {
            firstName = charinfo.firstname,
            lastName = charinfo.lastname,
            dob = charinfo.birthdate,
            sex = charinfo.gender == 0 and 'Male' or 'Female',
            citizenid = player.PlayerData.citizenid,
            nationality = charinfo.nationality,
            issued = player.PlayerData.charinfo.account,
        }
        TriggerClientEvent('idcard:client:display', target, data)
    else
        Notify(target, Locale('id_card.refused'), 'error')
    end
end)
