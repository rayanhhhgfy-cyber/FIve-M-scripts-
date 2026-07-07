local QBox = exports['qbx-core']:GetCoreObject()
local playerJob = nil
local actionCooldowns = {}
local currentLockpickAttempts = 0

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerJob = QBox.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerJob = job
end)

local function isAllowed()
    if not playerJob then return false end
    for _, j in ipairs(Config.CovertEntry.AllowedJobs) do
        if playerJob.name == j and playerJob.onduty then return true end
    end
    return false
end

local function canDoAction(actionName)
    if not isAllowed() then return false end
    local cooldownKey = playerJob.name .. ':' .. actionName
    if actionCooldowns[cooldownKey] and actionCooldowns[cooldownKey] > GetGameTimer() then
        local remaining = math.ceil((actionCooldowns[cooldownKey] - GetGameTimer()) / 1000)
        TriggerEvent('ox_lib:notify', { type = 'error', description = 'Cooldown: wait ' .. remaining .. 's' })
        return false
    end
    return true
end

local function setCooldown(actionName)
    local cooldownKey = playerJob.name .. ':' .. actionName
    actionCooldowns[cooldownKey] = GetGameTimer() + Config.CovertEntry.Cooldown
end

--- Door lockpick mini-game (rotation alignment)
local function startLockpickMiniGame(callback)
    local success = lib.skillCheck({ areaSize = 40, speedMultiplier = 3 }, { 'medium', 'medium', 'hard' })
    callback(success)
end

--- Alarm bypass mini-game (pattern memory)
local function startAlarmBypassMiniGame(callback)
    local success = lib.skillCheck({ areaSize = 50, speedMultiplier = 2.5 }, { 'easy', 'medium', 'medium' })
    callback(success)
end

--- Door target options
Citizen.CreateThread(function()
    for _, model in ipairs(Config.CovertEntry.DoorModels) do
        exports.ox_target:addModel(model, {
            {
                label = 'Silent Lockpick',
                icon = 'fas fa-lock-open',
                distance = 1.5,
                canInteract = function()
                    return canDoAction('lockpick') and exports.ox_inventory:Search('count', 'covert_lockpick') > 0
                end,
                onSelect = function(data)
                    local entity = data.entity
                    if not entity then return end
                    local coords = GetEntityCoords(entity)
                    local doorModel = GetEntityModel(entity)

                    QBox.Functions.Progressbar('covert_lockpick', 'Picking lock silently...', Config.CovertEntry.Lockpick.duration, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = 'mp_common',
                        anim = 'givetake1_a',
                        flags = 1,
                    }, function(cancelled)
                        if cancelled then return end
                        startLockpickMiniGame(function(lockpickSuccess)
                            if lockpickSuccess then
                                TriggerServerEvent('covert:server:lockpickSuccess', doorModel, { x = coords.x, y = coords.y, z = coords.z })
                                Wrappers.Notify('Lockpick successful', 'success')
                                setCooldown('lockpick')

                                -- Plant evidence option after successful entry
                                local shouldPlant = lib.alertDialog({
                                    header = 'Covert Entry',
                                    content = 'Plant evidence?',
                                    buttons = { { label = 'Yes', type = 'confirm' }, { label = 'No', type = 'cancel' } }
                                })
                                if shouldPlant == 'confirm' then
                                    local targetInput = lib.inputDialog('Plant Evidence', {
                                        { type = 'input', label = 'Target Citizen ID', placeholder = 'e.g. CIT-12345', required = true },
                                        { type = 'input', label = 'Location note', placeholder = 'e.g. Inside office, desk drawer' },
                                    })
                                    if targetInput and targetInput[1] and targetInput[1] ~= '' then
                                        local targetCid = targetInput[1]
                                        local location = targetInput[2] or 'Unknown location'
                                        QBox.Functions.Progressbar('plant_evidence', 'Planting evidence...', 3000, false, true, {
                                            disableMovement = true,
                                            disableCarMovement = true,
                                            disableMouse = false,
                                            disableCombat = true,
                                        }, {
                                            animDict = 'mp_common',
                                            anim = 'givetake1_a',
                                            flags = 1,
                                        }, function(cancelled2)
                                            if not cancelled2 then
                                                TriggerServerEvent('covert:server:plantEvidence', targetCid, location)
                                            end
                                        end)
                                    end
                                end
                            else
                                setCooldown('lockpick')
                                currentLockpickAttempts = currentLockpickAttempts + 1
                                if currentLockpickAttempts >= 3 then
                                    Wrappers.Notify('Lock jammed! Wait 30 seconds.', 'error')
                                    Citizen.Wait(Config.CovertEntry.Lockpick.jamDuration)
                                    currentLockpickAttempts = 0
                                else
                                    Wrappers.Notify('Lockpick failed - pins reset', 'error')
                                end
                            end
                        end)
                    end)
                end,
            },
            {
                label = 'Bypass Alarm',
                icon = 'fas fa-bolt',
                distance = 1.5,
                canInteract = function()
                    return canDoAction('alarm_bypass') and exports.ox_inventory:Search('count', 'alarm_bypass') > 0
                end,
                onSelect = function(data)
                    local entity = data.entity
                    if not entity then return end
                    local coords = GetEntityCoords(entity)
                    local doorModel = GetEntityModel(entity)

                    QBox.Functions.Progressbar('alarm_bypass', 'Bypassing alarm system...', Config.CovertEntry.AlarmBypass.duration, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = 'mp_common',
                        anim = 'givetake1_a',
                        flags = 1,
                    }, function(cancelled)
                        if cancelled then return end
                        startAlarmBypassMiniGame(function(bypassSuccess)
                            if bypassSuccess then
                                TriggerServerEvent('covert:server:alarmBypass', doorModel, { x = coords.x, y = coords.y, z = coords.z })
                                Wrappers.Notify('Alarm bypassed successfully', 'success')
                                setCooldown('alarm_bypass')
                                currentLockpickAttempts = 0
                            else
                                TriggerServerEvent('covert:server:failAlarm', 'Door alarm bypass failed at ' .. tostring(coords.x) .. ', ' .. tostring(coords.y), { x = coords.x, y = coords.y, z = coords.z })
                                setCooldown('alarm_bypass')
                                Wrappers.Notify('Alarm triggered! Police dispatched.', 'error')
                            end
                        end)
                    end)
                end,
            }
        })
    end
end)

--- Vehicle silent entry
exports.ox_target:addGlobalVehicle({
    label = 'Silent Entry',
    icon = 'fas fa-car-side',
    distance = 2.0,
    canInteract = function(entity)
        if not canDoAction('lockpick') then return false end
        if not exports.ox_inventory:Search('count', 'covert_lockpick') then return false end
        local veh = entity
        local locked = GetVehicleDoorLockStatus(veh)
        return locked == 2 or locked == 3
    end,
    onSelect = function(data)
        local entity = data.entity
        if not entity then return end

        QBox.Functions.Progressbar('vehicle_entry', 'Picking vehicle lock...', Config.CovertEntry.Lockpick.vehicleDuration, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = 'veh@mec@low',
            anim = 'sit_low_idle',
            flags = 1,
        }, function(cancelled)
            if cancelled then return end
            startLockpickMiniGame(function(lockpickSuccess)
                if lockpickSuccess then
                    SetVehicleDoorsLocked(entity, 1)
                    SetVehicleDoorsLockedForAllPlayers(entity, false)
                    Wrappers.Notify('Vehicle unlocked', 'success')
                    setCooldown('lockpick')
                else
                    Wrappers.Notify('Lockpick failed - vehicle still locked', 'error')
                    setCooldown('lockpick')
                end
            end)
        end)
    end,
})

--- Leave no trace option
RegisterCommand('leavenotrace', function()
    if not isAllowed() then return end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    Wrappers.ProgressBar({
        label = 'Erasing traces...',
        duration = 5000,
        useWhileDead = false,
        canCancel = false,
        anim = { dict = 'mp_common', clip = 'givetake1_a' },
    }, function(cancelled)
        if cancelled then return end
        Wrappers.Notify('Entry traces erased. No evidence left behind.', 'success')
    end)
end, false)

--- Unlock door event (server -> all clients)
RegisterNetEvent('covert:client:unlockDoor', function(doorModel, x, y, z)
    local door = GetClosestDoorToPosition(vector3(x, y, z), 5.0, 0, false)
    if door ~= 0 then
        SetEntityAsMissionEntity(door, true, true)
        if DoesEntityExist(door) then
            FreezeEntityPosition(door, false)
            SetStateOfClosestDoorOfType(doorModel, x, y, z, false, 0.0)
        end
    end
end)

--- Cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        actionCooldowns = {}
    end
end)
