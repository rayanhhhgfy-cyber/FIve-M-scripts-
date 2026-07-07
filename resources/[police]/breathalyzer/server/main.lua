local QBox = exports['qbx-core']:GetCoreObject()
local playerBAC = {}

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

RegisterNetEvent('breathalyzer:server:test', function(targetId)
    local src = source
    if not checkRateLimit(src, 'breathTest', 20) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then
        Wrappers.Notify(src, Locale('police.not_on_duty'), 'error')
        return
    end
    local target = QBox.Functions.GetPlayer(targetId)
    if not target then
        Wrappers.Notify(src, Locale('police.player_not_found'), 'error')
        return
    end
    local bac = playerBAC[target.PlayerData.citizenid] or 0.0
    bac = bac + (math.random(-5, 5) / 1000)
    bac = math.max(0, math.min(0.40, bac))
    TriggerClientEvent('breathalyzer:client:result', src, bac)
    exports['discord-logs']:LogCustom(src, 'Breathalyzer', target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname .. ' BAC: ' .. string.format('%.3f', bac))
end)

function AddBAC(citizenid, amount)
    playerBAC[citizenid] = (playerBAC[citizenid] or 0.0) + amount
    playerBAC[citizenid] = math.max(0, math.min(0.40, playerBAC[citizenid]))
    MySQL.update('UPDATE players SET bac = ? WHERE citizenid = ?', { playerBAC[citizenid], citizenid })
end

exports('AddBAC', AddBAC)

function GetBAC(citizenid)
    return playerBAC[citizenid] or 0.0
end

exports('GetBAC', GetBAC)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Breathalyzer.BACDecayInterval)
        for citizenid, bac in pairs(playerBAC) do
            if bac > 0 then
                playerBAC[citizenid] = math.max(0, bac - Config.Breathalyzer.BACDecayRate)
                MySQL.update('UPDATE players SET bac = ? WHERE citizenid = ?', { playerBAC[citizenid], citizenid })
            end
        end
    end
end)
