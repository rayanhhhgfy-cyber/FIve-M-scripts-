local QBCore = exports['qbx_core']:GetCoreObject()
local playerDownState = {}
local playerBleeding = {}
local playerDamageState = {}

function SetDownState(source, state)
    playerDownState[source] = state
    TriggerClientEvent('wasabi-ambulance:client:setDownState', source, state)
end

function GetDownState(source)
    return playerDownState[source] or nil
end

function SetBleeding(source, level)
    playerBleeding[source] = level
    TriggerClientEvent('wasabi-ambulance:client:setBleeding', source, level)
end

function GetBleeding(source)
    return playerBleeding[source] or nil
end

local function SetDamageState(source, bodyPart, state)
    if not playerDamageState[source] then playerDamageState[source] = {} end
    playerDamageState[source][bodyPart] = state
    TriggerClientEvent('wasabi-ambulance:client:setDamageState', source, bodyPart, state)
end

function GetDamageState(source)
    return playerDamageState[source] or {}
end

function DownPlayer(source, reason)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local downCount = player.PlayerData.metadata.down_count or 0
    downCount = downCount + 1
    player.Functions.SetMetaData('down_count', downCount)
    player.Functions.SetMetaData('is_dead', true)
    SetDownState(source, 'injured')
    if downCount >= Config.Ambulance.maxDownsBeforeDeath then
        SetDownState(source, 'critical')
    end
    local downTime = player.PlayerData.metadata.down_time or 0
    local totalDownTime = downTime + Config.Ambulance.downTimer
    player.Functions.SetMetaData('down_time', totalDownTime)
    SetBleeding(source, 'moderate')
    TriggerClientEvent('wasabi-ambulance:client:down', source, reason)
    SetTimeout(Config.Ambulance.bleedoutTime, function()
        if GetDownState(source) then
            SetDownState(source, 'dying')
        end
    end)
end

function RevivePlayer(source, reviveType)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    local reviveConfig = Config.RevivalMethods[reviveType]
    if not reviveConfig then return false end
    if math.random() > reviveConfig.successRate then
        return false
    end
    SetDownState(source, nil)
    SetBleeding(source, nil)
    playerDamageState[source] = nil
    player.Functions.SetMetaData('is_dead', false)
    player.Functions.SetMetaData('down_count', math.max(0, (player.PlayerData.metadata.down_count or 0) - 1))
    player.Functions.SetMetaData('down_time', 0)
    TriggerClientEvent('wasabi-ambulance:client:revive', source)
    return true
end

local function RespawnPlayer(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    SetDownState(source, nil)
    SetBleeding(source, nil)
    playerDamageState[source] = nil
    player.Functions.SetMetaData('is_dead', true)
    local locations = Config.Ambulance.RespawnLocations
    local loc = locations[math.random(#locations)]
    TriggerClientEvent('wasabi-ambulance:client:respawn', source, loc)
end

function HealPlayer(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    player.Functions.SetMetaData('is_dead', false)
    player.Functions.SetMetaData('down_count', 0)
    player.Functions.SetMetaData('down_time', 0)
    TriggerClientEvent('wasabi-ambulance:client:heal', source)
end

lib.callback.register('wasabi-ambulance:server:getDownState', function(source)
    return GetDownState(source)
end)

lib.callback.register('wasabi-ambulance:server:getBleeding', function(source)
    return GetBleeding(source)
end)

lib.callback.register('wasabi-ambulance:server:getDamageState', function(source)
    return GetDamageState(source)
end)

lib.callback.register('wasabi-ambulance:server:downPlayer', function(source, reason)
    DownPlayer(source, reason)
    return true
end)

lib.callback.register('wasabi-ambulance:server:revivePlayer', function(source, target, reviveType)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    if player.PlayerData.job.name ~= Config.Ambulance.jobName then return false end
    local success = RevivePlayer(target, reviveType)
    return success
end)

lib.callback.register('wasabi-ambulance:server:healPlayer', function(source, target)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    if player.PlayerData.job.name ~= Config.Ambulance.jobName then return false end
    HealPlayer(target)
    return true
end)

lib.callback.register('wasabi-ambulance:server:respawnPlayer', function(source)
    RespawnPlayer(source)
    return true
end)

lib.callback.register('wasabi-ambulance:server:applyBandage', function(source)
    local bleeding = GetBleeding(source)
    if not bleeding then return false, 'Not bleeding' end
    local levels = Config.Bleeding.levels
    local currentIndex = 0
    for i, l in ipairs(levels) do
        if l == bleeding then
            currentIndex = i
            break
        end
    end
    if currentIndex <= 1 then
        SetBleeding(source, nil)
    else
        SetBleeding(source, levels[currentIndex - 1])
    end
    return true, 'Bleeding reduced'
end)

lib.callback.register('wasabi-ambulance:server:getEmsCount', function(source)
    local count = 0
    for _, id in ipairs(GetPlayers()) do
        local p = QBCore.Functions.GetPlayer(tonumber(id))
        if p and p.PlayerData.job.name == Config.Ambulance.jobName and p.PlayerData.job.onduty then
            count = count + 1
        end
    end
    return count
end)

RegisterNetEvent('wasabi-ambulance:server:playerDied', function(reason)
    local source = source
    if not source then return end
    DownPlayer(source, reason)
end)

RegisterNetEvent('wasabi-ambulance:server:requestRevive', function(target)
    local source = source
    if not source then return end
    TriggerClientEvent('wasabi-ambulance:client:reviveRequest', target, source)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Bleeding.tickInterval)
        for src in pairs(playerBleeding) do
            local level = playerBleeding[src]
            if level then
                local levels = Config.Bleeding.levels
                local damagePerTick = Config.Bleeding.damagePerTick[level] or 0
                if damagePerTick > 0 then
                    local ped = GetPlayerPed(src)
                    if ped and ped > 0 then
                        local health = GetEntityHealth(ped)
                        SetEntityHealth(ped, health - damagePerTick)
                    end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[wasabi-ambulance] EMS framework loaded. Down states, bleeding, damage tracking active.^7')
end)

exports('IsPlayerDown', function(source) return GetDownState(source) ~= nil end)
exports('GetDownState', GetDownState)
exports('GetBleeding', GetBleeding)
exports('GetDamageState', GetDamageState)
exports('SetDownState', SetDownState)
exports('SetBleeding', SetBleeding)
exports('RevivePlayer', RevivePlayer)
exports('DownPlayer', DownPlayer)
exports('HealPlayer', HealPlayer)
