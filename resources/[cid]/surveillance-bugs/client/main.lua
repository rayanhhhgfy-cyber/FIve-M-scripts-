local QBox = exports['qbx-core']:GetCoreObject()
local playerJob = nil
local consoleOpen = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerJob = QBox.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerJob = job
end)

local function isAllowed()
    if not playerJob then return false end
    for _, j in ipairs(Config.SurveillanceBugs.AllowedJobs) do
        if playerJob.name == j and playerJob.onduty then return true end
    end
    return false
end

--- Deploy bugs via ox_target on world objects
Citizen.CreateThread(function()
    for _, model in ipairs(Config.SurveillanceBugs.BugTargetModels) do
        exports.ox_target:addModel(model, {
            {
                label = 'Deploy Pen Camera',
                icon = 'fas fa-video',
                distance = 1.5,
                canInteract = function()
                    if not isAllowed() then return false end
                    return exports.ox_inventory:Search('count', 'surveillance_camera') > 0
                end,
                onSelect = function(data)
                    deployBug('surveillance_camera', data.entity)
                end
            },
            {
                label = 'Deploy Audio Bug',
                icon = 'fas fa-microphone',
                distance = 1.5,
                canInteract = function()
                    if not isAllowed() then return false end
                    return exports.ox_inventory:Search('count', 'audio_bug') > 0
                end,
                onSelect = function(data)
                    deployBug('audio_bug', data.entity)
                end
            },
            {
                label = 'Deploy GPS Tracker',
                icon = 'fas fa-map-pin',
                distance = 1.5,
                canInteract = function()
                    if not isAllowed() then return false end
                    return exports.ox_inventory:Search('count', 'gps_tracker') > 0
                end,
                onSelect = function(data)
                    deployBug('gps_tracker', data.entity)
                end
            },
        })
    end
end)

local function deployBug(bugType, entity)
    if not entity then return end
    local coords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    local bugConfig = Config.SurveillanceBugs.BugTypes[bugType]
    if not bugConfig then return end

    QBox.Functions.Progressbar('deploy_bug', 'Deploying ' .. bugConfig.label .. '...', Config.SurveillanceBugs.DeployDuration, false, true, {
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
        TriggerServerEvent('svb:server:deployBug', bugType, { x = coords.x, y = coords.y, z = coords.z }, heading)
    end)
end

--- Open surveillance console (U key)
RegisterCommand('+surveillanceConsole', function()
    if not isAllowed() then return end
    consoleOpen = not consoleOpen
    if consoleOpen then
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'openConsole' })
        refreshBugData()
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeConsole' })
    end
end, false)

RegisterKeyMapping('+surveillanceConsole', 'Toggle Surveillance Console', 'keyboard', 'u')

local function refreshBugData()
    QBox.Functions.TriggerCallback('svb:server:getActiveBugs', function(bugs)
        if bugs then
            SendNUIMessage({ action = 'updateBugs', data = bugs })
        end
    end)
end

--- Periodic refresh while console is open
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.SurveillanceBugs.FeedRefreshInterval)
        if consoleOpen then
            refreshBugData()
        end
    end
end)

--- NUI callbacks
RegisterNUICallback('closeConsole', function(_, cb)
    consoleOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('deactivateBug', function(data, cb)
    TriggerServerEvent('svb:server:deactivateBug', data.bugId)
    cb('ok')
end)

--- Bug deployment at CID HQ surveillance room
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isAllowed() then
            local hqCoords = vector3(110.0, -750.0, 45.0)
            if not exports.ox_target:isExistingZone('svb_hq_terminal') then
                exports.ox_target:addBoxZone({
                    coords = hqCoords,
                    size = vector3(2.0, 2.0, 2.0),
                    rotation = 0,
                    debug = false,
                    options = {
                        {
                            label = 'Surveillance Console',
                            icon = 'fas fa-desktop',
                            distance = 2.0,
                            canInteract = function() return isAllowed() end,
                            onSelect = function()
                                consoleOpen = true
                                SetNuiFocus(true, true)
                                SendNUIMessage({ action = 'openConsole' })
                                refreshBugData()
                            end,
                        }
                    }
                })
            end
        end
    end
end)

--- Cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if consoleOpen then
            SetNuiFocus(false, false)
        end
    end
end)
