local QBCore = exports['qbx_core']:GetCoreObject()
local defibProp = nil
local cprInProgress = false

local function UseDefibrillator(target)
    local progress = exports['ox_lib']:progressBar({
        duration = Config.Defibrillator.useTime,
        label = 'Using Defibrillator...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
        anim = {
            dict = Config.Animations.defibrillator.dict,
            clip = Config.Animations.defibrillator.clip
        }
    })
    if progress then
        local success, msg = lib.callback.await('ems-defibrillator:server:useDefibrillator', false, target)
        Wrappers.Notify({ type = success and 'success' or 'error', description = msg })
        if success then
            TriggerEvent('InteractSound:client:playSound', 'revive_success', 0.7, 10.0, GetEntityCoords(PlayerPedId()))
        end
    end
end

local function UseCPR(target)
    if cprInProgress then return end
    cprInProgress = true
    local progress = exports['ox_lib']:progressBar({
        duration = Config.Defibrillator.cprTime,
        label = 'Performing CPR...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
        anim = {
            dict = Config.Animations.cpr.dict,
            clip = Config.Animations.cpr.clip
        }
    })
    if progress then
        local success, msg = lib.callback.await('ems-defibrillator:server:useCPR', false, target)
        Wrappers.Notify({ type = success and 'success' or 'error', description = msg })
    end
    cprInProgress = false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local closest, dist = exports['ox_lib']:getClosestPlayer(coords, 2.0)
        if closest and dist < 2.0 then
            local target = GetPlayerServerId(closest)
            exports['ox_target']:addLocalEntity(ped, {
                {
                    name = 'use_defib_' .. target,
                    label = 'Use Defibrillator',
                    icon = 'fas fa-bolt',
                    distance = 2.0,
                    canInteract = function()
                        return lib.callback.await('wasabi-ambulance:server:getDownState', false) ~= nil
                    end,
                    onSelect = function()
                        UseDefibrillator(target)
                    end
                },
                {
                    name = 'use_cpr_' .. target,
                    label = 'Perform CPR',
                    icon = 'fas fa-hand-holding-heart',
                    distance = 2.0,
                    canInteract = function()
                        return lib.callback.await('wasabi-ambulance:server:getDownState', false) ~= nil
                    end,
                    onSelect = function()
                        UseCPR(target)
                    end
                }
            })
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[ems-defibrillator] Client defibrillator ready.^7')
end)
