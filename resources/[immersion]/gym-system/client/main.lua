local QBCore = exports['qbx_core']:GetCoreObject()
local workingOut = false

local function UseEquipment(equipmentName)
    if workingOut then
        Wrappers.Notify({ type = 'error', description = 'Already working out' })
        return
    end
    local equipment = Config.Equipment[equipmentName]
    if not equipment then return end
    workingOut = true
    local success = lib.callback.await('gym-system:server:performRep', false, equipmentName)
    if not success then
        Wrappers.Notify({ type = 'error', description = 'Cannot use this equipment' })
        workingOut = false
        return
    end
    local progress = exports['ox_lib']:progressBar({
        duration = Config.Gym.repTime,
        label = equipment.label,
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
        anim = {
            dict = equipment.animDict,
            clip = equipment.animClip
        }
    })
    if progress then
        local success, result = lib.callback.await('gym-system:server:performRep', false, equipmentName)
        if success then
            Wrappers.Notify({ type = 'success', description = 'Rep complete!' })
        else
            Wrappers.Notify({ type = 'error', description = result or 'Failed' })
        end
    end
    workingOut = false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for name, equip in pairs(Config.Equipment) do
            local dist = #(coords - vector3(equip.coords.x, equip.coords.y, equip.coords.z))
            if dist < 3.0 then
                exports['ox_target']:addLocalEntity(ped, {
                    {
                        name = 'gym_' .. name,
                        label = equip.label,
                        icon = equip.icon,
                        distance = 2.0,
                        onSelect = function()
                            UseEquipment(name)
                        end
                    }
                })
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000)
        local ped = PlayerPedId()
        local strength = lib.callback.await('gym-system:server:getGymData', false)
        if strength then
            local speedMult = Config.StrengthEffects.runningSpeed.min + (strength.strength / Config.Gym.maxStrength) * (Config.StrengthEffects.runningSpeed.max - Config.StrengthEffects.runningSpeed.min)
            SetRunSprintMultiplierForPlayer(PlayerId(), speedMult)
        end
    end
end)

RegisterCommand('gymrest', function()
    TriggerServerEvent('gym-system:server:rest')
end, false)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[gym-system] Client gym system ready.^7')
end)

exports('IsWorkingOut', function() return workingOut end)
