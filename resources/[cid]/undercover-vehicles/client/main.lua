local QBox = exports['qbx-core']:GetCoreObject()
local playerJob = nil
local currentUCVehicle = nil
local currentIdentityIndex = 1
local vehicleIdentities = {}
local isSignalScannerActive = false
local trackerBlips = {}
local ucSirenActive = false
local ucLightsActive = false
local ucSilentMode = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerJob = QBox.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerJob = job
end)

local function isAllowed()
    if not playerJob then return false end
    for _, j in ipairs(Config.UndercoverVehicles.AllowedJobs) do
        if playerJob.name == j and playerJob.onduty then return true end
    end
    return false
end

--- Spawn UC vehicle
RegisterNetEvent('ucv:client:spawnVehicle', function(model, coords, heading)
    if currentUCVehicle and DoesEntityExist(currentUCVehicle) then
        DeleteVehicle(currentUCVehicle)
    end
    QBox.Functions.SpawnVehicle(model, function(vehicle)
        currentUCVehicle = vehicle
        local plate = Config.UndercoverVehicles.Identities[1].platePrefix .. math.random(100, 999)
        SetVehicleNumberPlateText(vehicle, plate)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleOnGroundProperly(vehicle)
        SetEntityInvincible(vehicle, false)
        SetVehicleFuelLevel(vehicle, 100.0)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

        -- Initialize identities for this vehicle
        local idStr = tostring(vehicle)
        vehicleIdentities[idStr] = 1
        currentIdentityIndex = 1

        -- Apply identity 1
        applyVehicleIdentity(vehicle, 1)

        TriggerEvent('ox_lib:notify', { type = 'success', description = 'UC Vehicle spawned - ' .. model .. ' [' .. plate .. ']' })
    end, coords, true)
end)

--- Apply identity plate/livery/extras
local function applyVehicleIdentity(vehicle, identityIndex)
    if not DoesEntityExist(vehicle) then return end
    local identity = Config.UndercoverVehicles.Identities[identityIndex]
    if not identity then return end
    local plate = identity.platePrefix .. math.random(100, 999)
    SetVehicleNumberPlateText(vehicle, plate)
    SetVehicleModKit(vehicle, 0)
    SetVehicleLivery(vehicle, identity.livery)
    SetVehicleColours(vehicle, math.random(0, 160), math.random(0, 160))
    local idStr = tostring(vehicle)
    vehicleIdentities[idStr] = identityIndex
    currentIdentityIndex = identityIndex

    local QBox = exports['qbx-core']:GetCoreObject()
    QBox.Functions.Notify('Identity swapped: ' .. identity.label, 'success')
end

--- Garage locations
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isAllowed() then
            for name, location in pairs(Config.UndercoverVehicles.Locations) do
                if not location._created then
                    exports.ox_target:addBoxZone({
                        coords = location.coords,
                        size = vector3(3.0, 3.0, 2.0),
                        rotation = 0,
                        debug = false,
                        options = {
                            {
                                label = 'UC Vehicle Pool - ' .. location.label,
                                icon = 'fas fa-car-side',
                                group = Config.UndercoverVehicles.AllowedJobs,
                                distance = Config.UndercoverVehicles.AllowedJobs,
                                canInteract = function()
                                    return isAllowed()
                                end,
                                onSelect = function()
                                    openGarageMenu(location.label, name)
                                end,
                            }
                        }
                    })
                    location._created = true
                end
            end
        end
    end
end)

--- Garage vehicle selection menu
local function openGarageMenu(locationLabel, locationName)
    local vehicleOptions = {}
    for _, v in ipairs(Config.UndercoverVehicles.Vehicles) do
        table.insert(vehicleOptions, {
            title = v.label,
            description = 'Speed: ' .. v.speed .. ' | Seats: ' .. v.seats,
            icon = 'fas fa-car',
            onSelect = function()
                TriggerServerEvent('ucv:server:spawnVehicle', v.model, locationName)
            end
        })
    end
    lib.registerContext({
        id = 'ucv_garage_menu',
        title = 'UC Vehicle Pool - ' .. locationLabel,
        options = vehicleOptions,
    })
    lib.showContext('ucv_garage_menu')
end

--- Trunk identity swap
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isAllowed() and currentUCVehicle and DoesEntityExist(currentUCVehicle) then
            if not exports.ox_target:isLocalEntity(currentUCVehicle) then
                exports.ox_target:addLocalEntity(currentUCVehicle, {
                    {
                        label = 'Swap Identity',
                        icon = 'fas fa-sync-alt',
                        distance = 2.0,
                        canInteract = function(entity)
                            return entity == currentUCVehicle and isAllowed()
                        end,
                        onSelect = function()
                            local veh = currentUCVehicle
                            QBox.Functions.Progressbar('swap_identity', 'Swapping vehicle identity...', Config.UndercoverVehicles.IdentitySwapDuration, false, true, {
                                disableMovement = false,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                            }, {
                                animDict = 'mp_common',
                                anim = 'givetake1_a',
                                flags = 1,
                            }, function(cancelled)
                                if cancelled then return end
                                local nextIdx = (currentIdentityIndex % #Config.UndercoverVehicles.Identities) + 1
                                applyVehicleIdentity(veh, nextIdx)
                            end)
                        end
                    }
                })
            end
        end
    end
end)

--- Hidden lightbar (H key)
RegisterCommand('+ucLights', function()
    if not isAllowed() or not currentUCVehicle or not DoesEntityExist(currentUCVehicle) then return end
    if not IsPedInVehicle(PlayerPedId(), currentUCVehicle, false) then return end
    ucLightsActive = not ucLightsActive
    if ucSilentMode and ucLightsActive then
        SetVehicleLights(currentUCVehicle, 2)
        SetVehicleLightMultiplier(currentUCVehicle, 1.0)
    elseif ucLightsActive then
        SetVehicleSiren(currentUCVehicle, true)
        SetVehicleLights(currentUCVehicle, 2)
        SetVehicleLightMultiplier(currentUCVehicle, 1.0)
    else
        SetVehicleSiren(currentUCVehicle, false)
        SetVehicleLights(currentUCVehicle, 0)
        SetVehicleLightMultiplier(currentUCVehicle, 0.0)
    end
    TriggerEvent('ox_lib:notify', { type = 'info', description = ucLightsActive and 'Lightbar activated' or 'Lightbar deactivated' })
end, false)

RegisterKeyMapping('+ucLights', 'Toggle UC Lightbar', 'keyboard', 'h')

--- Siren (J key)
RegisterCommand('+ucSiren', function()
    if not isAllowed() or not currentUCVehicle or not DoesEntityExist(currentUCVehicle) then return end
    if not IsPedInVehicle(PlayerPedId(), currentUCVehicle, false) then return end
    if ucSilentMode then
        TriggerEvent('ox_lib:notify', { type = 'error', description = 'Siren disabled in silent mode (press K)' })
        return
    end
    ucSirenActive = not ucSirenActive
    SetVehicleSiren(currentUCVehicle, ucSirenActive)
    TriggerEvent('ox_lib:notify', { type = 'info', description = ucSirenActive and 'Siren on' or 'Siren off' })
end, false)

RegisterKeyMapping('+ucSiren', 'Toggle UC Siren', 'keyboard', 'j')

--- Silent mode (K key)
RegisterCommand('+ucSilent', function()
    if not isAllowed() or not currentUCVehicle or not DoesEntityExist(currentUCVehicle) then return end
    if not IsPedInVehicle(PlayerPedId(), currentUCVehicle, false) then return end
    ucSilentMode = not ucSilentMode
    if ucSilentMode and ucSirenActive then
        SetVehicleSiren(currentUCVehicle, false)
        ucSirenActive = false
    end
    if ucSilentMode and ucLightsActive then
        SetVehicleSiren(currentUCVehicle, false)
        SetVehicleLights(currentUCVehicle, 2)
        SetVehicleLightMultiplier(currentUCVehicle, 1.0)
    end
    TriggerEvent('ox_lib:notify', { type = 'info', description = ucSilentMode and 'Silent mode ON (lights only)' or 'Silent mode OFF' })
end, false)

RegisterKeyMapping('+ucSilent', 'Toggle UC Silent Mode', 'keyboard', 'k')

--- Vehicle target options (global)
Citizen.CreateThread(function()
    exports.ox_target:addGlobalVehicle({
        {
            label = 'Deploy GPS Tracker',
            icon = 'fas fa-map-pin',
            distance = 2.5,
            canInteract = function(entity)
                if not isAllowed() then return false end
                local ped = PlayerPedId()
                local _, veh = GetClosestVehicle(GetEntityCoords(ped), 3.0)
                return veh == entity and exports.ox_inventory:Search('count', 'gps_tracker') > 0
            end,
            onSelect = function(data)
                local entity = data.entity
                if not entity then return end
                local plate = GetVehicleNumberPlateText(entity)
                local coords = GetEntityCoords(entity)
                if not plate or plate == '' then return end

                QBox.Functions.Progressbar('deploy_tracker', 'Deploying GPS tracker...', Config.UndercoverVehicles.TrackerDeployDuration, false, true, {
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
                    TriggerServerEvent('ucv:server:deployTracker', plate, { x = coords.x, y = coords.y, z = coords.z })
                end)
            end
        },
        {
            label = 'Sweep for Trackers',
            icon = 'fas fa-rss',
            distance = 2.5,
            canInteract = function(entity)
                if not isAllowed() then return false end
                local ped = PlayerPedId()
                return exports.ox_inventory:Search('count', 'tracker_sweeper') > 0
            end,
            onSelect = function(data)
                local entity = data.entity
                if not entity then return end
                local plate = GetVehicleNumberPlateText(entity)
                if not plate or plate == '' then return end

                QBox.Functions.Progressbar('sweep_tracker', 'Sweeping for trackers...', Config.UndercoverVehicles.TrackerSweepDuration, false, true, {
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
                    QBox.Functions.TriggerCallback('ucv:server:sweepTracker', function(result)
                        if result and result.found then
                            TriggerEvent('ox_lib:notify', { type = 'warning', description = 'Tracker found! GPS device detected under vehicle.' })
                            local blip = AddBlipForEntity(entity)
                            SetBlipColour(blip, 1)
                            SetBlipSprite(blip, 1)
                            SetBlipAsShortRange(blip, true)
                            BeginTextCommandSetBlipName('STRING')
                            AddTextComponentString('Tracked Vehicle')
                            EndTextCommandSetBlipName(blip)
                            for _, t in ipairs(result.trackers) do
                                TriggerServerEvent('ucv:server:removeTracker', t.tracker_id)
                            end
                        else
                            TriggerEvent('ox_lib:notify', { type = 'success', description = 'Vehicle is clean. No trackers detected.' })
                        end
                    end, plate)
                end)
            end
        }
    })
end)

--- Signal scanner (B key) - requires tracker_sweeper equipped
RegisterCommand('+ucScanner', function()
    if not isAllowed() then return end
    if exports.ox_inventory:Search('count', 'tracker_sweeper') == 0 then
        TriggerEvent('ox_lib:notify', { type = 'error', description = 'You need a Tracker Sweeper to use the signal scanner' })
        return
    end
    isSignalScannerActive = not isSignalScannerActive
    if not isSignalScannerActive then
        clearScannerBlips()
        TriggerEvent('ox_lib:notify', { type = 'info', description = 'Signal scanner deactivated' })
        return
    end
    TriggerEvent('ox_lib:notify', { type = 'info', description = 'Signal scanner active. Scanning for nearby trackers...' })

    Citizen.CreateThread(function()
        while isSignalScannerActive do
            Citizen.Wait(2000)
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            QBox.Functions.TriggerCallback('ucv:server:getActiveTrackers', function(trackers)
                clearScannerBlips()
                if not trackers or #trackers == 0 then return end
                for _, t in ipairs(trackers) do
                    local tPos = vector3(t.last_x, t.last_y, t.last_z)
                    local dist = #(pos - tPos)
                    if dist <= Config.UndercoverVehicles.SignalScannerRange then
                        local blip = AddBlipForCoord(tPos.x, tPos.y, tPos.z)
                        SetBlipColour(blip, 66)
                        SetBlipSprite(blip, 480)
                        SetBlipScale(blip, 0.8)
                        SetBlipAsShortRange(blip, true)
                        BeginTextCommandSetBlipName('STRING')
                        AddTextComponentString('GPS Tracker - ' .. (t.plate or 'Unknown'))
                        EndTextCommandSetBlipName(blip)
                        table.insert(trackerBlips, blip)
                    end
                end
            end)
        end
    end)
end, false)

RegisterKeyMapping('+ucScanner', 'Toggle Signal Scanner', 'keyboard', 'b')

local function clearScannerBlips()
    for _, blip in ipairs(trackerBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    trackerBlips = {}
end

exports('deployTracker', function()
    local ped = PlayerPedId()
    local _, vehicle = GetClosestVehicle(GetEntityCoords(ped), 3.0)
    if not vehicle or not DoesEntityExist(vehicle) then
        TriggerEvent('ox_lib:notify', { type = 'error', description = 'No vehicle nearby' })
        return
    end
    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate or plate == '' then return end
    local coords = GetEntityCoords(vehicle)
    QBox.Functions.Progressbar('deploy_tracker', 'Deploying GPS tracker...', 5000, false, true, {
        disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true,
    }, { animDict = 'mp_common', anim = 'givetake1_a', flags = 1 }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('ucv:server:deployTracker', plate, { x = coords.x, y = coords.y, z = coords.z })
    end)
end)

exports('sweepTrackers', function()
    local ped = PlayerPedId()
    local _, vehicle = GetClosestVehicle(GetEntityCoords(ped), 3.0)
    if not vehicle or not DoesEntityExist(vehicle) then
        TriggerEvent('ox_lib:notify', { type = 'error', description = 'No vehicle nearby' })
        return
    end
    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate or plate == '' then return end
    QBox.Functions.Progressbar('sweep_tracker', 'Sweeping for trackers...', 5000, false, true, {
        disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true,
    }, { animDict = 'mp_common', anim = 'givetake1_a', flags = 1 }, function(cancelled)
        if cancelled then return end
        QBox.Functions.TriggerCallback('ucv:server:sweepTracker', function(result)
            if result and result.found then
                TriggerEvent('ox_lib:notify', { type = 'warning', description = 'Tracker found!' })
                for _, t in ipairs(result.trackers) do
                    TriggerServerEvent('ucv:server:removeTracker', t.tracker_id)
                end
            else
                TriggerEvent('ox_lib:notify', { type = 'success', description = 'Vehicle is clean.' })
            end
        end, plate)
    end)
end)

--- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        clearScannerBlips()
        if currentUCVehicle and DoesEntityExist(currentUCVehicle) then
            DeleteVehicle(currentUCVehicle)
        end
    end
end)
