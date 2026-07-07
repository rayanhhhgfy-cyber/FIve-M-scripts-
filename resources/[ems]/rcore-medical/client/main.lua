local QBCore = exports['qbx_core']:GetCoreObject()
local currentReceptionZone = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, bed in ipairs(Config.BedLocations) do
            local dist = #(coords - vector3(bed.coords.x, bed.coords.y, bed.coords.z))
            if dist < 2.0 then
                exports['ox_target']:addLocalEntity(ped, {
                    {
                        name = 'bed_heal_' .. bed.name,
                        label = 'Lie on Bed',
                        icon = 'fas fa-bed',
                        distance = 2.0,
                        canInteract = function()
                            local downState = exports['wasabi-ambulance']:GetDownState()
                            return downState ~= nil
                        end,
                        onSelect = function()
                            local progress = exports['ox_lib']:progressBar({
                                duration = Config.MedicalBeds.healTime,
                                label = 'Resting on bed...',
                                useWhileDead = true,
                                canCancel = false,
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                                anim = {
                                    dict = Config.BedHealEffects.animDict,
                                    clip = Config.BedHealEffects.animClip
                                }
                            })
                            if progress then
                                local success, msg = lib.callback.await('rcore-medical:server:healOnBed', false, bed.name)
                                Wrappers.Notify({ type = success and 'success' or 'error', description = msg or 'Healed' })
                            end
                        end
                    },
                    {
                        name = 'bed_iv_' .. bed.name,
                        label = 'Use IV',
                        icon = 'fas fa-syringe',
                        distance = 2.0,
                        onSelect = function()
                            local success, msg = lib.callback.await('rcore-medical:server:startIV', false)
                            Wrappers.Notify({ type = success and 'success' or 'error', description = msg or 'IV started' })
                        end
                    }
                })
            end
        end
    end
end)

if Config.Reception.enabled then
    CreateThread(function()
        while true do
            Wait(1000)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local downState = exports['wasabi-ambulance']:GetDownState()

            for _, loc in ipairs(Config.Reception.locations) do
                local dist = #(coords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))
                if dist < loc.radius then
                    if downState ~= nil and currentReceptionZone ~= loc.name then
                        currentReceptionZone = loc.name
                        exports['ox_target']:addLocalEntity(ped, {
                            {
                                name = 'reception_checkin_' .. loc.name,
                                label = 'Check In ($' .. Config.Reception.checkInPrice .. ')',
                                icon = 'fas fa-clipboard-list',
                                distance = 2.0,
                                canInteract = function()
                                    return exports['wasabi-ambulance']:GetDownState() ~= nil
                                end,
                                onSelect = function()
                                    local progress = exports['ox_lib']:progressBar({
                                        duration = Config.Reception.checkInTime,
                                        label = 'Checking in at reception...',
                                        useWhileDead = true,
                                        canCancel = false,
                                        disableMovement = true,
                                        disableCarMovement = true,
                                        disableMouse = false,
                                        disableCombat = true,
                                    })
                                    if progress then
                                        local success, bedName = lib.callback.await('rcore-medical:server:receptionCheckIn', false, loc.name)
                                        if success and bedName then
                                            local bed = nil
                                            for _, b in ipairs(Config.BedLocations) do
                                                if b.name == bedName then bed = b end
                                            end
                                            if bed then
                                                DoScreenFadeOut(500)
                                                Wait(500)
                                                SetEntityCoords(ped, bed.coords.x, bed.coords.y, bed.coords.z, false, false, false, false)
                                                SetEntityHeading(ped, bed.heading)
                                                SetEntityHealth(ped, 200)
                                                ClearPedTasks(ped)
                                                ClearPedTasksImmediately(ped)
                                                DoScreenFadeIn(500)
                                                Wrappers.Notify({ type = 'success', description = 'You have been admitted. Rest well.' })
                                            end
                                        else
                                            Wrappers.Notify({ type = 'error', description = bedName or 'Check-in failed.' })
                                        end
                                    end
                                end
                            }
                        })
                    elseif downState == nil then
                        currentReceptionZone = nil
                    end
                end
            end
        end
    end)
end

RegisterNetEvent('rcore-medical:client:startIV', function()
    local ped = PlayerPedId()
    local prop = CreateObject(GetHashKey(Config.MedicalBeds.BedHealEffects.ivProp), 0, 0, 0, true, true, true)
    local bone = GetPedBoneIndex(ped, Config.MedicalBeds.BedHealEffects.ivPropBone)
    AttachEntityToEntity(prop, ped, bone, 0, 0, 0, 0, 0, 0, true, true, false, true, 2, true)
    local startHealth = GetEntityHealth(ped)
    Citizen.CreateThread(function()
        local elapsed = 0
        while elapsed < Config.IV.duration do
            Citizen.Wait(Config.IV.tickInterval)
            elapsed = elapsed + Config.IV.tickInterval
            local health = GetEntityHealth(ped)
            SetEntityHealth(ped, math.min(health + Config.IV.healRate, GetEntityMaxHealth(ped)))
        end
        if DoesEntityExist(prop) then DeleteEntity(prop) end
    end)
    Wrappers.Notify({ type = 'success', description = 'IV started. Healing in progress.' })
end)

RegisterNetEvent('rcore-medical:client:applyIV', function()
    local ped = PlayerPedId()
    local targetPed = GetPlayerPed(-1)
    local prop = CreateObject(GetHashKey(Config.MedicalBeds.BedHealEffects.ivProp), 0, 0, 0, true, true, true)
    local bone = GetPedBoneIndex(targetPed, Config.MedicalBeds.BedHealEffects.ivPropBone)
    AttachEntityToEntity(prop, targetPed, bone, 0, 0, 0, 0, 0, 0, true, true, false, true, 2, true)
    local startHealth = GetEntityHealth(targetPed)
    Citizen.CreateThread(function()
        local elapsed = 0
        while elapsed < Config.IV.duration do
            Citizen.Wait(Config.IV.tickInterval)
            elapsed = elapsed + Config.IV.tickInterval
            local health = GetEntityHealth(targetPed)
            SetEntityHealth(targetPed, math.min(health + Config.IV.healRate, GetEntityMaxHealth(targetPed)))
        end
        if DoesEntityExist(prop) then DeleteEntity(prop) end
    end)
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[rcore-medical] Client hospital beds ready.^7')
end)
