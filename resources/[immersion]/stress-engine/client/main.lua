local QBCore = exports['qbx_core']:GetCoreObject()
local lastStress = 0
local isRelaxing = false
local stillTimer = 0

local function ApplyEffects(stressLevel)
    if not Config.Stress.enabled then return end
    local intensity = math.min(stressLevel / Config.Stress.maxStress, 1.0)
    if stressLevel < Config.Stress.minStressForEffects then
        intensity = 0
    end
    if Config.VisualEffects.screenShake.enabled and intensity > 0 then
        local shakeIntensity = Config.VisualEffects.screenShake.minIntensity + intensity * (Config.VisualEffects.screenShake.maxIntensity - Config.VisualEffects.screenShake.minIntensity)
        ShakeGameplayCam(Config.VisualEffects.screenShake.shakeType, shakeIntensity)
    end
    if Config.VisualEffects.aimJitter.enabled and intensity > 0 and IsPedArmed(PlayerPedId(), 4) then
        local jitter = Config.VisualEffects.aimJitter.minJitter + intensity * (Config.VisualEffects.aimJitter.maxJitter - Config.VisualEffects.aimJitter.minJitter)
        local jitterX = math.sin(GetGameTimer() * Config.VisualEffects.aimJitter.jitterSpeed) * jitter
        local jitterY = math.cos(GetGameTimer() * Config.VisualEffects.aimJitter.jitterSpeed) * jitter
        SetGameplayCamRelativeHeading(GetGameplayCamRelativeHeading() + jitterX)
        SetGameplayCamPitch(GetGameplayCamPitch() + jitterY, 1.0)
    end
    if intensity > 0 then
        local fadeTo = 150 + intensity * 100
        SetArtificialLightsState(false)
    end
end

local function CheckRelaxation()
    local ped = PlayerPedId()
    local stress = lib.callback.await('stress-engine:server:getStress', false)
    if not stress then return end
    lastStress = stress
    if stress <= 0 then return end
    local isStill = not IsPedWalking(ped) and not IsPedRunning(ped) and not IsPedSprinting(ped) and not IsPedInAnyVehicle(ped, false)
    local isSitting = IsPedUsingScenario(ped, 'PROP_HUMAN_SEAT_CHAIR') or IsPedUsingScenario(ped, 'PROP_HUMAN_SEAT_BENCH')
    local isSmoking = IsPedUsingScenario(ped, 'WORLD_HUMAN_SMOKING') or IsPedUsingScenario(ped, 'WORLD_HUMAN_DRINKING')
    if isSitting then
        TriggerServerEvent('stress-engine:server:relax', 'sitting')
    elseif isSmoking then
        TriggerServerEvent('stress-engine:server:relax', 'smoking')
    elseif isStill and stillTimer > Config.Relaxation.idle.stillTime then
        TriggerServerEvent('stress-engine:server:relax', 'idle')
        stillTimer = 0
    end
    if isStill then
        stillTimer = stillTimer + 1000
    else
        stillTimer = 0
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local stress = lib.callback.await('stress-engine:server:getStress', false)
        ApplyEffects(stress or 0)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Stress.updateInterval)
        CheckRelaxation()
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle and vehicle > 0 then
                local speed = GetEntitySpeed(vehicle) * 3.6
                if speed > 120 then
                    TriggerServerEvent('stress-engine:server:addStress', 2)
                elseif speed > 80 then
                    TriggerServerEvent('stress-engine:server:addStress', 1)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[stress-engine] Client stress effects active.^7')
end)

exports('GetStressLevel', function() return lastStress end)
