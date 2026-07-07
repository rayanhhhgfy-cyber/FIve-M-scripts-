local playerActivity = {}
local playerAFKTime = {}

local function IsPlayerExempt(source)
    if IsPlayerAceAllowed(source, Config.AFK.exemptAce) then
        return true
    end
    local player = exports['qbx_core']:GetPlayer(source)
    if player then
        local jobName = player.PlayerData.job.name
        for _, exemptJob in ipairs(Config.AFK.exemptJobs) do
            if jobName == exemptJob then
                return true
            end
        end
    end
    return false
end

local function WarnPlayer(source, timeRemaining)
    if not source then return end
    TriggerClientEvent('afk-kicker:client:warning', source, math.ceil(timeRemaining / 1000))
end

local function KickPlayer(source)
    if not source then return end
    local reason = Config.Messages.afk_kick
    local afkTime = playerAFKTime[source] or 0
    if afkTime > 0 then
        reason = reason .. ' | ' .. string.format(Config.Messages.afk_additional, math.ceil(afkTime / 60000))
    end
    DropPlayer(source, reason)
    playerActivity[source] = nil
    playerAFKTime[source] = nil
end

local function ProcessAFKCheck()
    local currentTime = GetGameTimer()
    local players = GetPlayers()
    for i = 1, #players do
        local src = tonumber(players[i])
        if src then
            if IsPlayerExempt(src) then
                playerActivity[src] = currentTime
                playerAFKTime[src] = 0
                goto continue
            end
            local lastActivity = playerActivity[src] or currentTime
            local afkDuration = currentTime - lastActivity
            playerAFKTime[src] = afkDuration
            if afkDuration >= Config.AFK.gracePeriod then
                if Config.AFK.kickOnAFK then
                    KickPlayer(src)
                end
            elseif afkDuration >= (Config.AFK.gracePeriod - Config.AFK.warningTime) then
                local remaining = Config.AFK.gracePeriod - afkDuration
                if math.floor(remaining / Config.AFK.warningInterval) ~= math.floor((remaining + Config.AFK.checkInterval) / Config.AFK.warningInterval) then
                    WarnPlayer(src, remaining)
                end
            end
        end
        ::continue::
    end
end

RegisterNetEvent('afk-kicker:server:activity')
AddEventHandler('afk-kicker:server:activity', function()
    local source = source
    if not source then return end
    playerActivity[source] = GetGameTimer()
end)

AddEventHandler('playerConnecting', function(playerName)
    local source = source
    playerActivity[source] = GetGameTimer()
    playerAFKTime[source] = 0
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    playerActivity[source] = nil
    playerAFKTime[source] = nil
end)

lib.callback.register('afk-kicker:server:getAFKTime', function(source)
    return playerAFKTime[source] or 0
end)

lib.callback.register('afk-kicker:server:resetAFK', function(source)
    if not source then return false end
    playerActivity[source] = GetGameTimer()
    playerAFKTime[source] = 0
    return true
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[afk-kicker] AFK monitoring initialized.^7')
    if not Config.AFK.enabled then return end
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.AFK.checkInterval)
            ProcessAFKCheck()
        end
    end)
end)

exports('IsPlayerAFK', function(source)
    if not source then return false end
    local afkTime = playerAFKTime[source] or 0
    return afkTime > Config.AFK.gracePeriod
end)

exports('GetPlayerAFKTime', function(source)
    return playerAFKTime[source] or 0
end)

exports('ResetPlayerAFK', function(source)
    if source then
        playerActivity[source] = GetGameTimer()
        playerAFKTime[source] = 0
        return true
    end
    return false
end)
