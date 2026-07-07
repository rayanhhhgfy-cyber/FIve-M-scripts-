local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local tackleCooldown = false
local isTackling = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

local function isTackleable()
    if tackleCooldown then return false end
    if isTackling then return false end
    return true
end

local function doTackleAnimation()
    local ped = PlayerPedId()
    local dict = 'melee@unarmed@streamed_core@meta_b'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(0)
    end
    TaskPlayAnim(ped, dict, 'heavy_attack_l', 8.0, -8.0, Config.Tackle.AnimationDuration, 0, 0, false, false, false)
    SetPedUsingActionMode(ped, true, -1, dict)
end

RegisterNetEvent('tackle:client:tackle', function()
    if not isTackleable() then
        Wrappers.Notify(Locale('police.cooldown_active'), 'error')
        return
    end
    if Config.Tackle.RequireDuty and not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    local closestPlayer, closestDist = QBox.Functions.GetClosestPlayer()
    if closestPlayer == -1 or closestDist > Config.Tackle.Range then
        Wrappers.Notify(Locale('police.no_player_near'), 'error')
        return
    end
    local targetPed = GetPlayerPed(closestPlayer)
    local targetSpeed = #(GetEntityVelocity(targetPed))
    if Config.Tackle.TackleOnRun and targetSpeed < Config.Tackle.MaxSpeedForTackle then
        Wrappers.Notify(Locale('police.too_slow_tackle'), 'error')
        return
    end
    isTackling = true
    tackleCooldown = true
    doTackleAnimation()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    local heading = GetHeadingFromVector_2d(targetCoords.x - playerCoords.x, targetCoords.y - playerCoords.y)
    SetEntityHeading(playerPed, heading)
    SetPedToRagdoll(playerPed, 500, 500, 0, false, false, false)
    TriggerServerEvent('tackle:server:tackle', GetPlayerServerId(closestPlayer))
    SetTimeout(Config.Tackle.StunDuration, function()
        isTackling = false
    end)
    SetTimeout(Config.Tackle.Cooldown, function()
        tackleCooldown = false
    end)
end)

RegisterNetEvent('tackle:client:getTackled', function()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    SetPedToRagdoll(ped, Config.Tackle.RagdollDuration, Config.Tackle.RagdollDuration, 0, false, false, false)
    local dict = 'combat@damage@rb_belly@angry@idle'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(0)
    end
    TaskPlayAnim(ped, dict, 'idle', 8.0, -8.0, Config.Tackle.StunDuration, 2, 0, false, false, false)
    ApplyDamageToPed(ped, Config.Tackle.Damage, false)
    Wrappers.Notify(Locale('police.you_were_tackled'), 'error')
end)

RegisterCommand('+tackle', function()
    TriggerEvent('tackle:client:tackle')
end, false)

RegisterKeyMapping('+tackle', 'Tackle Player', 'keyboard', 'f')
