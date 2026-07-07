local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local shieldActive = false
local shieldObject = nil
local shieldHealth = Config.Shields.Health

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

local function getMyRank()
    if not playerData.job then return 0 end
    return playerData.job.grade.level or 0
end

local function hasShield()
    return QBox.Functions.HasItem(Config.Shields.ItemName)
end

RegisterCommand('+shield', function()
    TriggerEvent('shields:toggle')
end, false)

RegisterKeyMapping('+shield', 'Deploy/Store Shield', 'keyboard', 'b')

RegisterNetEvent('shields:toggle', function()
    if shieldActive then
        TriggerEvent('shields:store')
    else
        TriggerEvent('shields:deploy')
    end
end)

RegisterNetEvent('shields:deploy', function()
    if shieldActive then
        Wrappers.Notify(Locale('police.shield_active'), 'error')
        return
    end
    if Config.Shields.RequireDuty and not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    if getMyRank() < Config.Shields.MinRank then
        Wrappers.Notify(Locale('police.rank_too_low'), 'error')
        return
    end
    if not hasShield() then
        Wrappers.Notify(Locale('police.no_shield'), 'error')
        return
    end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        Wrappers.Notify(Locale('police.cannot_in_vehicle'), 'error')
        return
    end
    local dict = Config.Shields.Animations.Deploy.dict
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(0)
    end
    Wrappers.ProgressBar({
        label = Locale('police.deploying_shield'),
        duration = Config.Shields.DeployTime,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then return end
        TaskPlayAnim(ped, dict, Config.Shields.Animations.Deploy.clip, 8.0, -8.0, Config.Shields.Animations.Deploy.duration, Config.Shields.Animations.Deploy.flags, 0, false, false, false)
        local modelHash = GetHashKey(Config.Shields.ObjectModel)
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(0)
        end
        shieldObject = CreateObject(modelHash, 0.0, 0.0, 0.0, true, true, false)
        AttachEntityToEntity(shieldObject, ped, GetPedBoneIndex(ped, Config.Shields.Bone), Config.Shields.Offset.x, Config.Shields.Offset.y, Config.Shields.Offset.z, Config.Shields.Rotation.x, Config.Shields.Rotation.y, Config.Shields.Rotation.z, true, true, false, true, 1, true)
        shieldActive = true
        shieldHealth = Config.Shields.Health
        TriggerServerEvent('shields:server:deployed')
        Wrappers.Notify(Locale('police.shield_deployed'), 'success')
        if Config.Shields.DisableWeapons then
            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
        end
    end)
end)

RegisterNetEvent('shields:store', function()
    if not shieldActive then return end
    local ped = PlayerPedId()
    local dict = Config.Shields.Animations.Store.dict
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(0)
    end
    Wrappers.ProgressBar({
        label = Locale('police.storing_shield'),
        duration = Config.Shields.StoreTime,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then return end
        if shieldObject then
            DeleteObject(shieldObject)
            shieldObject = nil
        end
        shieldActive = false
        ClearPedTasks(ped)
        Wrappers.Notify(Locale('police.shield_stored'), 'success')
        TriggerServerEvent('shields:server:stored')
    end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if shieldActive and shieldObject then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                TriggerEvent('shields:store')
                Wrappers.Notify(Locale('police.shield_stored_vehicle'), 'info')
            end
            if Config.Shields.DisableWeapons then
                local weapon = GetSelectedPedWeapon(ped)
                if weapon ~= GetHashKey('WEAPON_UNARMED') then
                    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
                end
            end
            local carryDict = Config.Shields.Animations.Carry.dict
            RequestAnimDict(carryDict)
            while not HasAnimDictLoaded(carryDict) do
                Citizen.Wait(0)
            end
            if not IsEntityPlayingAnim(ped, carryDict, Config.Shields.Animations.Carry.clip, 3) then
                TaskPlayAnim(ped, carryDict, Config.Shields.Animations.Carry.clip, 8.0, -8.0, -1, Config.Shields.Animations.Carry.flags, 0, false, false, false)
            end
            SetPedMoveRateOverride(ped, Config.Shields.SpeedReduction)
            local bulletHit, bulletCoords = GetPedLastDamageBone(ped, 1)
            if bulletHit and shieldHealth > 0 then
                if math.random(100) <= Config.Shields.BlockChance then
                    shieldHealth = shieldHealth - 10
                    if shieldHealth <= 0 then
                        TriggerEvent('shields:store')
                        Wrappers.Notify(Locale('police.shield_destroyed'), 'error')
                    end
                else
                    ApplyDamageToPed(ped, 25, false)
                end
            end
        else
            Citizen.Wait(500)
        end
        Citizen.Wait(0)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if shieldObject then
            DeleteObject(shieldObject)
        end
    end
end)
