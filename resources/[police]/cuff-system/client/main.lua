local isCuffed = false
local cufferSrc = nil
local cuffedDriveOverride = false
local cuffedDriveVehicle = nil

--- Apply cuff state
RegisterNetEvent('cuff:client:doCuff', function(cuffer)
    isCuffed = true
    cufferSrc = cuffer
    cuffedDriveOverride = false
    cuffedDriveVehicle = nil

    -- Load anim dict
    local dict = Config.CuffSystem.cuffAnim.dict
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end

    -- Play cuff animation on target
    local ped = PlayerPedId()
    TaskPlayAnim(ped, dict, Config.CuffSystem.cuffAnim.cuff, 8.0, -8.0, -1, 2, 0, false, false, false)
    SetPedCurrentWeaponVisible(ped, false, true, false, false)
    SetEnableHandcuffs(ped, true)
    DisableControlAction(0, 21, true) -- SHIFT (sprint)
    DisableControlAction(0, 22, true) -- Jump
    DisableControlAction(0, 24, true) -- Attack
    DisableControlAction(0, 25, true) -- Aim
    DisableControlAction(0, 37, true) -- Weapon wheel
    DisableControlAction(0, 140, true) -- Melee
    DisableControlAction(0, 141, true) -- Melee2
    DisableControlAction(0, 142, true) -- Melee3
    DisableControlAction(0, 263, true) -- Melee heavy
    DisableControlAction(0, 264, true) -- Melee light

    SetPedMoveRateOverride(ped, Config.CuffSystem.cuffedWalkSpeed)

    -- Play idle cuff anim continuously
    Citizen.CreateThread(function()
        while isCuffed do
            Citizen.Wait(1000)
            if not IsEntityPlayingAnim(ped, dict, Config.CuffSystem.cuffAnim.idle, 3) then
                TaskPlayAnim(ped, dict, Config.CuffSystem.cuffAnim.idle, 8.0, -8.0, -1, 2, 0, false, false, false)
            end
        end
    end)

    Wrappers.Notify('You have been cuffed', 'warning')
end)

--- Uncuff
RegisterNetEvent('cuff:client:doUncuff', function()
    isCuffed = false
    cuffedDriveOverride = false
    cuffedDriveVehicle = nil
    cufferSrc = nil

    local ped = PlayerPedId()
    ClearPedTasks(ped)
    SetEnableHandcuffs(ped, false)
    SetPedMoveRateOverride(ped, 1.0)
    SetPedCurrentWeaponVisible(ped, true, true, false, false)
    Wrappers.Notify('You have been uncuffed', 'info')
end)

--- Request lockpick uncuff (from non-cuffer)
RegisterNetEvent('cuff:client:requestLockpickUncuff', function(targetSrc, targetCID)
    local ped = PlayerPedId()
    local dict = Config.CuffSystem.uncuffAnim.dict
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
    TaskPlayAnim(ped, dict, Config.CuffSystem.uncuffAnim.clip, 8.0, -8.0, Config.CuffSystem.lockpickTime, 1, 0, false, false, false)

    Wrappers.ProgressBar({
        label = 'Picking cuffs...',
        duration = Config.CuffSystem.lockpickTime,
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, function(cancelled)
        ClearPedTasks(ped)
        if not cancelled then
            TriggerServerEvent('cuff:server:lockpickUncuff', targetSrc, targetCID)
        end
    end)
end)

--- Allow cuffed player to drive (after lockpick)
RegisterNetEvent('cuff:client:allowCuffedDrive', function(vehicleNetId)
    cuffedDriveOverride = true
    cuffedDriveVehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    Wrappers.Notify('Engine hotwired, you can drive', 'success')
end)

--- Main restriction thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isCuffed then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            -- Prevent sprint / weapons / jumping
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)

            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                -- Cuffed player is in driver seat
                if cuffedDriveOverride and cuffedDriveVehicle == vehicle then
                    -- They lockpicked it, allow driving
                else
                    -- Block driving — force engine off and notify
                    SetVehicleEngineOn(vehicle, false, true, true)
                    DisableControlAction(0, 71, true) -- Accelerate
                    DisableControlAction(0, 72, true) -- Brake
                    DisableControlAction(0, 75, true) -- Exit vehicle (keep them in)

                    -- Lockpick prompt
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to lockpick the ignition (requires lockpick)')
                    EndTextCommandDisplayHelp(0, false, true, -1)

                    if IsControlJustPressed(0, 51) then -- E
                        TriggerServerEvent('cuff:server:lockpickCar', NetworkGetNetworkIdFromEntity(vehicle))
                    end
                end
            end
        end
        Citizen.Wait(0)
    end
end)

--- ox_target interaction for cuffing/uncuffing
Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end

    exports['ox_target']:addGlobalPlayer({
        options = {
            {
                name = 'cuff_player',
                icon = 'fas fa-handcuffs',
                label = 'Cuff / Uncuff',
                distance = Config.CuffSystem.maxCuffDistance,
                canInteract = function(entity)
                    local playerData = QBox.Functions.GetPlayerData()
                    if not playerData or not playerData.job then return false end
                    for _, j in ipairs(Config.CuffSystem.allowedCuffJobs) do
                        if playerData.job.name == j then return true end
                    end
                    for _, g in ipairs(Config.CuffSystem.adminGroups) do
                        if playerData.group == g then return true end
                    end
                    return false
                end,
                onSelect = function(data)
                    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                    -- Check if they're cuffed
                    TriggerServerEvent('cuff:server:checkAndShow', targetServerId)
                end,
            },
        },
    })
end)

--- Show cuff/uncuff menu based on state
RegisterNetEvent('cuff:client:showMenu', function(targetSrc, isTargetCuffed)
    local items = {}
    if isTargetCuffed then
        table.insert(items, { title = 'Uncuff Player', icon = 'fas fa-handcuffs', onSelect = function()
            TriggerServerEvent('cuff:server:uncuff', targetSrc)
        end})
    else
        table.insert(items, { title = 'Cuff Player', icon = 'fas fa-handcuffs', onSelect = function()
            TriggerServerEvent('cuff:server:cuff', targetSrc)
        end})
    end
    Wrappers.ContextMenu({ id = 'cuff_menu', title = 'Cuff Options', menuItems = items })
end)
