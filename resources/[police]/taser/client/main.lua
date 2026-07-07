local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local taserCooldown = false
local isTasing = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

local function hasTaser()
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    return weapon == GetHashKey(Config.Taser.WeaponHash)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(50)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) and IsPedArmed(ped, 4) then
            local weapon = GetSelectedPedWeapon(ped)
            if weapon == GetHashKey(Config.Taser.WeaponHash) then
                if IsPlayerFreeAiming(PlayerId()) and IsControlJustPressed(0, 24) then
                    if taserCooldown then
                        Wrappers.Notify(Locale('police.cooldown_active'), 'error')
                        Citizen.Wait(100)
                    else
                        TriggerEvent('taser:fire')
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('taser:fire', function()
    if isTasing then return end
    if Config.Taser.RequireDuty and not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    isTasing = true
    taserCooldown = true
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local camCoords = GetGameplayCamCoord()
    local direction = GetCamForwardVector()
    local hit, hitCoords, hitEntity, hitNormal = GetShapeTestResult(StartShapeTestCapsule(coords.x, coords.y, coords.z, coords.x + direction.x * Config.Taser.MaxRange, coords.y + direction.y * Config.Taser.MaxRange, coords.z + direction.z * Config.Taser.MaxRange, 0.3, 1, ped, 4))
    if hit and DoesEntityExist(hitEntity) and IsEntityAPed(hitEntity) then
        if IsPedAPlayer(hitEntity) then
            local playerId = NetworkGetPlayerIndexFromPed(hitEntity)
            if playerId and playerId ~= -1 then
                TriggerServerEvent('taser:server:tase', GetPlayerServerId(playerId))
            end
        else
            ClearPedTasksImmediately(hitEntity)
            SetPedToRagdoll(hitEntity, Config.Taser.RagdollDuration, Config.Taser.RagdollDuration, 0, false, false, false)
        end
        if Config.Taser.Effects.SoundEnabled then
            PlaySoundFromCoord(-1, Config.Taser.Effects.SoundName, coords.x, coords.y, coords.z, Config.Taser.Effects.SoundDict, false, 50, false)
        end
        if Config.Taser.Effects.FlashEffect then
            DoScreenFadeOut(Config.Taser.Effects.FlashDuration)
            Citizen.Wait(Config.Taser.Effects.FlashDuration)
            DoScreenFadeIn(Config.Taser.Effects.FlashDuration)
        end
        if Config.Taser.Arcs.Enabled then
            local startCoords = GetPedBoneCoords(ped, 0x796e, 0.0, 0.0, 0.0)
            local endCoords = GetEntityCoords(hitEntity)
            local handles = {}
            for i = 1, 3 do
                local offset = vector3(math.random(-50, 50) / 100, math.random(-50, 50) / 100, math.random(-50, 50) / 100)
                local handle = AddBolas(startCoords.x, startCoords.y, startCoords.z, 5)
                if handle then
                    handles[i] = handle
                end
            end
            SetTimeout(Config.Taser.Arcs.Duration, function()
                for _, handle in ipairs(handles) do
                    if handle then
                        DeleteEntity(handle)
                    end
                end
            end)
        end
    end
    SetTimeout(Config.Taser.Cooldown, function()
        taserCooldown = false
    end)
    SetTimeout(1000, function()
        isTasing = false
    end)
end)

RegisterNetEvent('taser:client:getTased', function()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    SetPedToRagdoll(ped, Config.Taser.RagdollDuration, Config.Taser.RagdollDuration, 0, false, false, false)
    if Config.Taser.DamageEnabled then
        ApplyDamageToPed(ped, Config.Taser.DamageAmount, false)
    end
    if Config.Taser.Effects.ScreenShake then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', Config.Taser.Effects.ScreenShakeIntensity)
    end
    SetPedMinGroundTimeForStungun(ped, Config.Taser.StunDuration)
    Wrappers.Notify(Locale('police.you_were_tased'), 'error')
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local ped = PlayerPedId()
        if IsPedBeingStunned(ped, 0) then
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 21, true)
        end
    end
end)
