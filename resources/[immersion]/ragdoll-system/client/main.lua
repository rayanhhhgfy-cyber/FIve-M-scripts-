local QBCore = exports['qbx_core']:GetCoreObject()
local manualRagdoll = false
local lastFallHeight = 0.0

function TriggerRagdoll(duration, force)
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end
    local dur = duration or math.random(Config.Ragdoll.ragdollMinDuration, Config.Ragdoll.ragdollMaxDuration)
    SetPedRagdoll(ped, dur, dur, 0, 0, 0, 0)
end

local function CheckFallDamage()
    if not Config.FallDamage.enabled then return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end
    if IsPedFalling(ped) then
        local z = GetEntityCoords(ped).z
        if lastFallHeight == 0 then
            lastFallHeight = z
        end
        local fallDistance = lastFallHeight - z
        if fallDistance > Config.FallDamage.minHeightForDamage then
            local damage = math.min(math.floor(fallDistance * Config.FallDamage.damageMultiplier), Config.FallDamage.maxDamage)
            if damage > 0 then
                SetEntityHealth(ped, GetEntityHealth(ped) - damage)
                TriggerServerEvent('player-status:server:addStress', math.floor(damage / 2))
                if Config.FallDamage.ragdollOnFall then
                    TriggerRagdoll(math.min(math.floor(fallDistance * 500), 5000))
                end
                Wrappers.Notify({ type = 'error', description = 'Fall damage: -' .. damage .. ' HP', duration = 2000 })
            end
        end
        lastFallHeight = z
    else
        lastFallHeight = GetEntityCoords(ped).z
    end
end

local function CheckVehicleImpact()
    if not Config.VehicleImpact.enabled then return end
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 then return end
    local speed = GetEntitySpeed(vehicle) * 3.6
    if speed > Config.VehicleImpact.minSpeed then
        local health = GetEntityHealth(vehicle)
        if health < 500 then
            local ragdollChance = (speed - Config.VehicleImpact.minSpeed) / 100.0
            if math.random() < ragdollChance then
                TaskLeaveAnyVehicle(ped, 0, 16)
                Citizen.Wait(100)
                TriggerRagdoll(Config.VehicleImpact.ragdollDuration)
                TriggerServerEvent('player-status:server:addStress', Config.VehicleImpact.stressAmount)
            end
        end
    end
end

local function ToggleManualRagdoll()
    manualRagdoll = not manualRagdoll
    if manualRagdoll then
        SetPedRagdoll(PlayerPedId(), 999999, 999999, 0, 0, 0, 0)
    end
    Wrappers.Notify({ type = 'info', description = manualRagdoll and 'Ragdoll ON' or 'Ragdoll OFF' })
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        if not Config.Ragdoll.enabled then Citizen.Wait(1000) end
        CheckFallDamage()
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        CheckVehicleImpact()
    end
end)

RegisterCommand(Config.Ragdoll.toggleCommand, function()
    ToggleManualRagdoll()
end, false)

if Config.Ragdoll.enableCommand then
    RegisterKeyMapping(Config.Ragdoll.toggleCommand, 'Toggle Manual Ragdoll', 'keyboard', Config.Ragdoll.toggleKey)
end

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[ragdoll-system] Physics-driven ragdoll active.^7')
end)

exports('TriggerRagdoll', TriggerRagdoll)
