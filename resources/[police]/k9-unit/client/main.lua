local QBox = exports['qbx-core']:GetCoreObject()
local activeDogs = {}
local dogBreadcrumbs = {}
local searchResults = {}

--- Spawn the dog ped
RegisterNetEvent('k9:client:spawnDog', function(unit)
    if activeDogs[unit.id] then return end

    local model = GetHashKey(Config.K9.dogModel)
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if not HasModelLoaded(model) then
        Wrappers.Notify('Failed to load K9 model', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 2.0
    local dog = CreatePed(28, model, coords.x, coords.y, coords.z - 1.0, GetEntityHeading(ped), true, false)
    SetEntityInvincible(dog, true)
    SetBlockingOfNonTemporaryEvents(dog, true)
    SetPedCombatAttributes(dog, 46, true)
    SetPedFleeAttributes(dog, 0, false)
    SetPedCanRagdoll(dog, false)
    SetPedCanRagdollFromPlayerImpact(dog, false)
    SetPedAlertness(dog, 3)
    SetPedSeeingRange(dog, 100.0)
    SetPedHearingRange(dog, 100.0)
    SetPedVisualFieldMaxAngle(dog, 360.0)

    activeDogs[unit.id] = {
        ped = dog,
        unit = unit,
        mode = 'follow',
        target = nil,
        lastBark = 0,
        lastBite = 0,
    }

    SetTimeout(60000, function()
        if activeDogs[unit.id] then
            DeletePed(dog)
            activeDogs[unit.id] = nil
        end
    end)
end)

--- Dog follow behavior thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        for id, dogData in pairs(activeDogs) do
            if not DoesEntityExist(dogData.ped) then
                activeDogs[id] = nil
                goto continue
            end

            local dogPed = dogData.ped
            local dogCoords = GetEntityCoords(dogPed)
            local dist = #(pCoords - dogCoords)

            if dogData.mode == 'follow' then
                if dist > Config.K9.followDistance then
                    local targetCoords = pCoords + GetEntityForwardVector(ped) * -0.5
                    TaskGoStraightToCoord(dogPed, targetCoords.x, targetCoords.y, targetCoords.z, Config.K9.runSpeed, -1, GetEntityHeading(ped), 0.0)
                elseif dist < Config.K9.followDistance - 0.5 then
                    TaskGoStraightToCoord(dogPed, pCoords.x, pCoords.y, pCoords.z, Config.K9.walkSpeed, -1, GetEntityHeading(ped), 0.0)
                else
                    if not IsPedWalking(dogPed) and not IsPedRunning(dogPed) then
                        TaskStandStill(dogPed, 1000)
                    end
                end
                TriggerServerEvent('k9:server:syncDogPosition', id, { x = dogCoords.x, y = dogCoords.y, z = dogCoords.z })

            elseif dogData.mode == 'tracking' and dogData.target then
                local targetPed = GetPlayerPed(dogData.target)
                if DoesEntityExist(targetPed) then
                    local tCoords = GetEntityCoords(targetPed)
                    local trackDist = #(dogCoords - tCoords)
                    if trackDist > 2.0 then
                        TaskGoStraightToCoord(dogPed, tCoords.x, tCoords.y, tCoords.z, Config.K9.runSpeed, -1, 0.0, 5.0)
                    else
                        TaskStandStill(dogPed, 500)
                        if GetGameTimer() - dogData.lastBark > Config.K9.barkInterval then
                            PlaySoundFromCoord(-1, Config.K9.alertSound.ref, Config.K9.alertSound.dict, dogCoords, 'K9', false, 0, false)
                            dogData.lastBark = GetGameTimer()
                            TriggerServerEvent('k9:server:dogBark', id)
                        end
                    end
                end

            elseif dogData.mode == 'apprehending' and dogData.target then
                local targetPed = GetPlayerPed(dogData.target)
                if DoesEntityExist(targetPed) then
                    local tCoords = GetEntityCoords(targetPed)
                    local biteDist = #(dogCoords - tCoords)
                    if biteDist > 1.5 then
                        TaskGoStraightToCoord(dogPed, tCoords.x, tCoords.y, tCoords.z, Config.K9.runSpeed * 1.3, -1, 0.0, 2.0)
                    else
                        TaskStandStill(dogPed, 100)
                        if GetGameTimer() - dogData.lastBite > Config.K9.biteCooldown then
                            ApplyDamageToPed(targetPed, Config.K9.biteDamage, false)
                            dogData.lastBite = GetGameTimer()
                            TriggerServerEvent('k9:server:reportApprehension', id, dogData.target)
                        end
                    end
                end

            elseif dogData.mode == 'searching_narc' or dogData.mode == 'searching_exp' then
                if dist < Config.K9.searchRadius then
                    local nearbyPeds = GetGamePool('CPed')
                    for _, np in ipairs(nearbyPeds) do
                        if IsPedAPlayer(np) then
                            local nCoords = GetEntityCoords(np)
                            local searchDist = #(dogCoords - nCoords)
                            if searchDist < 5.0 then
                                local isRagdoll = IsPedRagdoll(np)
                                if not isRagdoll then
                                    if dogData.mode == 'searching_narc' then
                                        Wrappers.Notify('K9 alerting on player — possible narcotics', 'warning')
                                        PlaySoundFromCoord(-1, Config.K9.alertSound.ref, Config.K9.alertSound.dict, dogCoords, 'K9', false, 0, false)
                                        TriggerServerEvent('k9:server:searchResult', id, true, 'Narcotics')
                                    elseif dogData.mode == 'searching_exp' then
                                        Wrappers.Notify('K9 alerting on player — possible explosives', 'warning')
                                        PlaySoundFromCoord(-1, Config.K9.alertSound.ref, Config.K9.alertSound.dict, dogCoords, 'K9', false, 0, false)
                                        TriggerServerEvent('k9:server:searchResult', id, true, 'Explosives')
                                    end
                                end
                            end
                        end
                    end
                    if not IsPedWalking(dogPed) and not IsPedRunning(dogPed) then
                        TaskWanderStandard(dogPed, 10.0, 10)
                    end
                else
                    TaskGoStraightToCoord(dogPed, pCoords.x, pCoords.y, pCoords.z, Config.K9.runSpeed, -1, 0.0, 10.0)
                end

            elseif dogData.mode == 'guarding' then
                TaskStandStill(dogPed, 500)
                local nearbyPeds = GetGamePool('CPed')
                for _, np in ipairs(nearbyPeds) do
                    if IsPedAPlayer(np) then
                        local nCoords = GetEntityCoords(np)
                        local guardDist = #(dogCoords - nCoords)
                        if guardDist < 8.0 and np ~= ped then
                            SetPedSeeingRange(dogPed, 50.0)
                            TaskLookAtEntity(dogPed, np, 1000, 2048, 3)
                            if GetGameTimer() - dogData.lastBark > Config.K9.barkInterval then
                                PlaySoundFromCoord(-1, Config.K9.alertSound.ref, Config.K9.alertSound.dict, dogCoords, 'K9', false, 0, false)
                                dogData.lastBark = GetGameTimer()
                                Wrappers.Notify('K9 barking — intruder detected', 'warning')
                            end
                        end
                    end
                end

            elseif dogData.mode == 'staying' then
                TaskStandStill(dogPed, 500)
            end

            ::continue::
        end
    end
end)

--- Command handlers
RegisterNetEvent('k9:client:track', function(unitId, targetSrc)
    if activeDogs[unitId] then
        activeDogs[unitId].mode = 'tracking'
        activeDogs[unitId].target = targetSrc
        Wrappers.Notify('K9 tracking suspect', 'info')
    end
end)

RegisterNetEvent('k9:client:apprehend', function(unitId, targetSrc)
    if activeDogs[unitId] then
        activeDogs[unitId].mode = 'apprehending'
        activeDogs[unitId].target = targetSrc
        Wrappers.Notify('K9 pursuing suspect', 'warning')
    end
end)

RegisterNetEvent('k9:client:searchNarcotics', function(unitId)
    if activeDogs[unitId] then
        activeDogs[unitId].mode = 'searching_narc'
        Wrappers.Notify('K9 searching for narcotics', 'info')
    end
end)

RegisterNetEvent('k9:client:searchExplosives', function(unitId)
    if activeDogs[unitId] then
        activeDogs[unitId].mode = 'searching_exp'
        Wrappers.Notify('K9 searching for explosives', 'info')
    end
end)

RegisterNetEvent('k9:client:guard', function(unitId)
    if activeDogs[unitId] then
        activeDogs[unitId].mode = 'guarding'
        Wrappers.Notify('K9 guarding position', 'info')
    end
end)

RegisterNetEvent('k9:client:stay', function(unitId)
    if activeDogs[unitId] then
        activeDogs[unitId].mode = 'staying'
        Wrappers.Notify('K9 staying', 'info')
    end
end)

RegisterNetEvent('k9:client:heel', function(unitId)
    if activeDogs[unitId] then
        activeDogs[unitId].mode = 'follow'
        activeDogs[unitId].target = nil
        Wrappers.Notify('K9 heeling', 'success')
    end
end)

RegisterNetEvent('k9:client:recallDog', function(unitId)
    if activeDogs[unitId] then
        local dog = activeDogs[unitId].ped
        if DoesEntityExist(dog) then
            DeletePed(dog)
        end
        activeDogs[unitId] = nil
        TriggerServerEvent('k9:server:dogDespawned', unitId)
    end
end)

--- Held-by-dog state on target
RegisterNetEvent('k9:client:heldByDog', function()
    local ped = PlayerPedId()
    SetPedCanRagdoll(ped, false)
    SetPedCanBeKnockedOffVehicle(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    Citizen.CreateThread(function()
        local start = GetGameTimer()
        while GetGameTimer() - start < 5000 do
            Citizen.Wait(0)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            SetPedMinGroundTimeForStungun(ped, 100000)
        end
        SetPedCanRagdoll(ped, true)
        SetPedCanBeKnockedOffVehicle(ped, true)
        SetPedCanRagdollFromPlayerImpact(ped, true)
    end)
end)

--- Cleanup
AddEventHandler('onResourceStop', function(r)
    if GetCurrentResourceName() == r then
        for _, dogData in pairs(activeDogs) do
            if DoesEntityExist(dogData.ped) then
                DeletePed(dogData.ped)
            end
        end
        activeDogs = {}
    end
end)
