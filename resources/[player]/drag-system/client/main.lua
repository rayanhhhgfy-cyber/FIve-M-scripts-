local isDragging = false
local isBeingDragged = false
local dragTarget = nil
local dragTimer = 0

--- ox_target option for cuffed/downed players
local function getNearbyPlayers()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local players = GetActivePlayers()
    local nearby = {}
    for _, p in ipairs(players) do
        local pPed = GetPlayerPed(p)
        local pCoords = GetEntityCoords(pPed)
        local dist = #(coords - pCoords)
        if dist < Config.Drag.dragDistance and pPed ~= ped then
            nearby[#nearby + 1] = { src = GetPlayerServerId(p), ped = pPed, dist = dist }
        end
    end
    table.sort(nearby, function(a, b) return a.dist < b.dist end)
    return nearby
end

-- Dynamic target for nearest draggable player
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if not isDragging and not isBeingDragged then
            local nearby = getNearbyPlayers()
            local hasOption = false
            for _, p in ipairs(nearby) do
                local cuffed = exports['cuff-system']:IsCuffed(p.src)
                local downed = exports['wasabi-ambulance']:IsPlayerDown(p.src)
                if cuffed or downed then
                    exports.ox_target:addLocalEntity(p.ped, {{
                        name = 'drag_player_' .. p.src,
                        label = cuffed and '🔗 Drag Cuffed Player' or '🏥 Drag Injured Player',
                        icon = 'fas fa-hand-paper',
                        distance = Config.Drag.dragDistance,
                        onSelect = function()
                            TriggerServerEvent('drag:server:startDrag', p.src)
                        end,
                    }})
                    hasOption = true
                    break
                end
            end
            if not hasOption then
                -- Clear old targets (done automatically by ox_target on ped change)
            end
        end
    end
end)

-- Dragger loop: follow the target
RegisterNetEvent('drag:client:startDrag', function(targetSrc)
    isDragging = true
    dragTarget = targetSrc
    CreateThread(function()
        while isDragging do
            Citizen.Wait(0)
            local targetPed = GetPlayerPed(GetPlayerFromServerId(dragTarget))
            if not DoesEntityExist(targetPed) then
                TriggerServerEvent('drag:server:stopDrag')
                break
            end
            -- Keep target close
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(myCoords - targetCoords)
            if dist > 3.0 then
                Wrappers.Notify('Drag', 'Target too far', 'error')
                TriggerServerEvent('drag:server:stopDrag')
                break
            end
            -- Force target position to be near dragger
            local offset = GetOffsetFromEntityInWorldCoords(myPed, 0.0, -1.0, 0.0)
            SetEntityCoords(targetPed, offset.x, offset.y, offset.z, false, false, false, false)
            FreezeEntityPosition(targetPed, true)
            SetEntityCollision(targetPed, false, false)

            local actionTaken = false

            -- If target is in a vehicle → extract
            if IsPedInAnyVehicle(targetPed, false) then
                Wrappers.Notify('Drag', 'Press E to pull out of vehicle', 'info')
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent('drag:server:forceOutOfVehicle', dragTarget)
                    actionTaken = true
                end
            else
                -- Check for open vehicle door → force into
                local vehicle = GetClosestVehicle(myCoords, Config.Drag.forceCarDistance, 0, 70)
                if DoesEntityExist(vehicle) then
                    local vehicleNet = NetworkGetNetworkIdFromEntity(vehicle)
                    local doors = { 0, 1, 2, 3, 4, 5 }
                    for _, door in ipairs(doors) do
                        if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
                            local doorCoords = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, door == 0 and 'door_dside_f' or door == 1 and 'door_dside_r' or door == 2 and 'door_pside_f' or door == 3 and 'door_pside_r' or 'door_dside_f'))
                            local doorDist = #(myCoords - doorCoords)
                            if doorDist < 2.0 then
                                Wrappers.Notify('Drag', 'Press E to force into vehicle', 'info')
                                if IsControlJustPressed(0, 38) then
                                    local seat = door <= 1 and -1 or -2
                                    TriggerServerEvent('drag:server:forceIntoVehicle', dragTarget, vehicleNet, seat)
                                    actionTaken = true
                                    break
                                end
                            end
                        end
                    end
                end
            end

            -- Release drag (only if no other action consumed E)
            if not actionTaken and IsControlJustPressed(0, 38) then
                TriggerServerEvent('drag:server:stopDrag')
                break
            end
        end
        isDragging = false
    end)
end)

-- Being dragged: ragdoll / follow
RegisterNetEvent('drag:client:beingDragged', function(draggerSrc)
    isBeingDragged = true
    CreateThread(function()
        while isBeingDragged do
            Citizen.Wait(0)
            local ped = PlayerPedId()
            if not IsPedRagdoll(ped) then
                SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
            end
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
        end
    end)
end)

-- Force into vehicle
RegisterNetEvent('drag:client:forceIntoVehicle', function(vehicleNetId, seat)
    local vehicle = NetToVeh(vehicleNetId)
    if DoesEntityExist(vehicle) then
        local ped = PlayerPedId()
        SetPedIntoVehicle(ped, vehicle, seat)
    end
end)

-- Force out of vehicle (extract target from seated vehicle)
RegisterNetEvent('drag:client:forceOutOfVehicle', function(draggerSrc)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, vehicle, 16)
        Citizen.Wait(500)
        -- Place near the dragger
        local draggerPed = GetPlayerPed(GetPlayerFromServerId(draggerSrc))
        if DoesEntityExist(draggerPed) then
            local coords = GetEntityCoords(draggerPed)
            SetEntityCoords(ped, coords.x + 1.0, coords.y + 1.0, coords.z, false, false, false, false)
        end
        SetPedToRagdoll(ped, 500, 500, 0, false, false, false)
    end
end)

-- Stop being dragged
RegisterNetEvent('drag:client:stopBeingDragged', function()
    isBeingDragged = false
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetPedToRagdoll(ped, 100, 100, 0, false, false, false)
end)

-- Stop dragging
RegisterNetEvent('drag:client:stopDrag', function()
    isDragging = false
    dragTarget = nil
    if dragSessions then
        for _, t in pairs(dragSessions) do
            if t.target then
                FreezeEntityPosition(GetPlayerPed(GetPlayerFromServerId(t.target)), false)
                SetEntityCollision(GetPlayerPed(GetPlayerFromServerId(t.target)), true, true)
            end
        end
    end
end)
