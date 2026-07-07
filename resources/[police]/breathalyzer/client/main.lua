local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local testCooldown = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

local function hasBreathalyzer()
    return QBox.Functions.HasItem(Config.Breathalyzer.ItemName)
end

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do
        Citizen.Wait(100)
    end
    playerData = QBox.Functions.GetPlayerData()

    exports.ox_target:addGlobalPlayer({
        options = {
            {
                name = 'breathalyzer_test',
                icon = Config.Breathalyzer.TargetOptions.icon,
                label = Config.Breathalyzer.TargetOptions.label,
                group = Config.Breathalyzer.TargetOptions.group,
                distance = Config.Breathalyzer.TargetOptions.distance,
                canInteract = function()
                    if Config.Breathalyzer.RequireDuty and not isOnDuty() then return false end
                    if testCooldown then return false end
                    return hasBreathalyzer()
                end,
                onSelect = function(entity)
                    local playerId = NetworkGetPlayerIndexFromPed(entity)
                    if playerId and playerId ~= -1 then
                        TriggerEvent('breathalyzer:test', GetPlayerServerId(playerId))
                    end
                end
            }
        }
    })
end)

RegisterNetEvent('breathalyzer:test', function(targetId)
    if testCooldown then
        Wrappers.Notify(Locale('police.cooldown_active'), 'error')
        return
    end
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    if not hasBreathalyzer() then
        Wrappers.Notify(Locale('police.no_breathalyzer'), 'error')
        return
    end
    local closestPlayer, closestDist = QBox.Functions.GetClosestPlayer()
    if closestPlayer == -1 or closestDist > Config.Breathalyzer.Range then
        Wrappers.Notify(Locale('police.no_player_near'), 'error')
        return
    end
    testCooldown = true
    Wrappers.ProgressBar({
        label = Locale('police.testing_breath'),
        duration = Config.Breathalyzer.TestTime,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then
            testCooldown = false
            return
        end
        TriggerServerEvent('breathalyzer:server:test', targetId or GetPlayerServerId(closestPlayer))
        SetTimeout(Config.Breathalyzer.Cooldown, function()
            testCooldown = false
        end)
    end)
end)

RegisterNetEvent('breathalyzer:client:result', function(bac)
    local level
    if bac >= Config.Breathalyzer.ExtremeDrunkThreshold then
        level = 'Extreme'
    elseif bac >= Config.Breathalyzer.VeryDrunkThreshold then
        level = 'Very Drunk'
    elseif bac >= Config.Breathalyzer.DrunkThreshold then
        level = 'Drunk'
    else
        level = 'Sober'
    end
    Wrappers.Notify(Locale('police.bac_result', string.format('%.3f', bac), level), 'info')
end)
