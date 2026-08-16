local activeBlips = {}
local isCop = false
local currentJob = nil

-- Drone Variables
local droneActive = false
local droneObj = nil
local droneCam = nil
local droneCoords = nil
local droneRot = 0.0

-- Dashcam Variables
local dashcamActive = false
local dashcamCam = nil

-- Simple Framework Check for Job
function GetPlayerJob()
    if GetResourceState('qbx_core') == 'started' then
        local PlayerData = exports.qbx_core:GetPlayerData()
        if PlayerData and PlayerData.job then
            return PlayerData.job.name
        end
    end
    if GetResourceState('qb-core') == 'started' then
        local QB = exports['qb-core']:GetCoreObject()
        if QB and QB.Functions and QB.Functions.GetPlayerData then
            local PlayerData = QB.Functions.GetPlayerData()
            if PlayerData and PlayerData.job then
                return PlayerData.job.name
            end
        end
    end
    if GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        if ESX and ESX.GetPlayerData then
            local PlayerData = ESX.GetPlayerData()
            if PlayerData and PlayerData.job then
                return PlayerData.job.name
            end
        end
    end
    return nil
end

function CheckDuty()
    local job = GetPlayerJob()
    currentJob = job
    isCop = (job == 'police' or job == 'leo' or job == 'sheriff')
    return isCop
end

-- Draw text helper for drone HUD
function DrawTxt(text, x, y, scale, r, g, b)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, 255)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- HELPER: Get vector forward
function GetForwardVector(rotation)
    local z = rotation * (math.pi / 180.0)
    return vector3(-math.sin(z), math.cos(z), 0.0)
end

-- ==================== POLICE DRONE ====================
RegisterCommand('drone', function()
    if not CheckDuty() then
        lib.notify({ type = 'error', description = 'Access denied: Police officers only!' })
        return
    end

    if droneActive then return end

    local ped = PlayerPedId()
    droneCoords = GetEntityCoords(ped) + vector3(0.0, 1.0, 1.5)
    droneRot = GetEntityHeading(ped)

    -- Spawn drone entity
    local model = `prop_host_drone`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    droneObj = CreateObject(model, droneCoords.x, droneCoords.y, droneCoords.z, true, true, false)
    SetEntityCollision(droneObj, true, true)
    FreezeEntityPosition(ped, true)

    -- Play animation
    RequestAnimDict('amb@world_human_stand_guard@male@base')
    while not HasAnimDictLoaded('amb@world_human_stand_guard@male@base') do Wait(10) end
    TaskPlayAnim(ped, 'amb@world_human_stand_guard@male@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Attach Camera
    droneCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(droneCam, droneCoords.x, droneCoords.y, droneCoords.z - 0.2)
    SetCamRot(droneCam, -15.0, 0.0, droneRot, 2)
    SetCamActive(droneCam, true)
    RenderScriptCams(true, false, 0, true, true)

    droneActive = true
    SetSeethrough(true) -- High-tech drone thermal lens!

    lib.notify({ type = 'info', description = 'Drone Deployed. Use W/S/A/D to move and Arrow Keys to rotate. Backspace/ESC to exit.' })

    CreateThread(function()
        while droneActive do
            Wait(0)
            -- Drone HUD overlay
            DrawTxt("POLICE SURVEILLANCE DRONE SYSTEM - THERMAL IMAGING ACTIVE", 0.35, 0.05, 0.45, 39, 201, 63)
            DrawTxt(string.format("ALT: %.2fm  |  YAW: %.2f", droneCoords.z, droneRot), 0.45, 0.1, 0.45, 255, 255, 255)

            -- Pilot controls
            local forward = GetForwardVector(droneRot)
            local right = vector3(-forward.y, forward.x, 0.0)
            local moveVec = vector3(0.0, 0.0, 0.0)

            if IsControlPressed(0, 32) then moveVec = moveVec + (forward * 0.15) end -- W
            if IsControlPressed(0, 33) then moveVec = moveVec - (forward * 0.15) end -- S
            if IsControlPressed(0, 34) then droneRot = droneRot + 2.0 end -- A (Yaw)
            if IsControlPressed(0, 35) then droneRot = droneRot - 2.0 end -- D (Yaw)

            if IsControlPressed(0, 22) then moveVec = moveVec + vector3(0.0, 0.0, 0.12) end -- Space (Altitude +)
            if IsControlPressed(0, 210) then moveVec = moveVec - vector3(0.0, 0.0, 0.12) end -- Control (Altitude -)

            droneCoords = droneCoords + moveVec
            SetEntityCoords(droneObj, droneCoords.x, droneCoords.y, droneCoords.z, false, false, false, false)
            SetEntityHeading(droneObj, droneRot)

            -- Camera rot & coordinate lock
            SetCamCoord(droneCam, droneCoords.x, droneCoords.y - 0.2, droneCoords.z - 0.1)
            SetCamRot(droneCam, -15.0, 0.0, droneRot, 2)

            -- Intercept exit keys
            DisableControlAction(0, 177, true)
            DisableControlAction(0, 200, true)

            if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) then
                ExitDrone()
            end
        end
    end)
end, false)

function ExitDrone()
    droneActive = false
    local ped = PlayerPedId()

    RenderScriptCams(false, false, 0, true, true)
    if droneCam then
        DestroyCam(droneCam, false)
        droneCam = nil
    end

    SetSeethrough(false)

    if droneObj and DoesEntityExist(droneObj) then
        DeleteEntity(droneObj)
        droneObj = nil
    end

    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    lib.notify({ type = 'info', description = 'Drone returned to base.' })
end

-- ==================== DASHCAM SYSTEM ====================
RegisterCommand('dashcam', function(source, args)
    if not CheckDuty() then
        lib.notify({ type = 'error', description = 'Access denied: Police officers only!' })
        return
    end

    if dashcamActive then return end

    local target = args[1]
    if not target then
        lib.notify({ type = 'error', description = 'Usage: /dashcam [plate / officer_id]' })
        return
    end

    local ped = PlayerPedId()
    local isId = tonumber(target) ~= nil

    if isId then
        -- Bodycam Peeking
        local targetId = tonumber(target)
        local targetPed = GetPlayerPed(targetId)
        if targetPed == 0 or not DoesEntityExist(targetPed) then
            lib.notify({ type = 'error', description = 'Officer is currently offline or unreachable.' })
            return
        end

        dashcamCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        AttachCamToEntity(dashcamCam, targetPed, GetPedBoneIndex(targetPed, 31086), 0.15, 0.15, 0.0, false) -- Head level bone
        SetCamRot(dashcamCam, -10.0, 0.0, GetEntityHeading(targetPed), 2)
        SetCamActive(dashcamCam, true)
        RenderScriptCams(true, false, 0, true, true)
        dashcamActive = true

        lib.notify({ type = 'info', description = 'Connected to Officer Bodycam feed. Backspace/ESC to disconnect.' })
    else
        -- Vehicle Dashcam Peeking
        local vehicles = GetGamePool('CVehicle')
        local foundVeh = nil
        for _, veh in ipairs(vehicles) do
            local plate = GetVehicleNumberPlateText(veh)
            plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
            if string.lower(plate) == string.lower(target) then
                foundVeh = veh
                break
            end
        end

        if not foundVeh then
            lib.notify({ type = 'error', description = 'Vehicle dashcam feed unreachable or plate not found.' })
            return
        end

        dashcamCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        AttachCamToEntity(dashcamCam, foundVeh, 0, 0.0, 0.5, 0.8, false) -- Front windshield offset
        SetCamRot(dashcamCam, -5.0, 0.0, GetEntityHeading(foundVeh), 2)
        SetCamActive(dashcamCam, true)
        RenderScriptCams(true, false, 0, true, true)
        dashcamActive = true

        lib.notify({ type = 'info', description = 'Connected to Cruiser Dashcam feed. Backspace/ESC to disconnect.' })
    end

    CreateThread(function()
        while dashcamActive do
            Wait(0)
            -- REC flashing bodycam icon overlay
            if (GetGameTimer() % 1000) < 500 then
                DrawTxt("● REC", 0.08, 0.08, 0.5, 255, 39, 39)
            end
            DrawTxt("DASHCAM / BODYCAM REAL-TIME CARRIER STREAM", 0.14, 0.08, 0.45, 255, 255, 255)

            -- Intercept exit keys
            DisableControlAction(0, 177, true)
            DisableControlAction(0, 200, true)

            if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) then
                ExitDashcam()
            end
        end
    end)
end, false)

function ExitDashcam()
    dashcamActive = false
    RenderScriptCams(false, false, 0, true, true)
    if dashcamCam then
        DestroyCam(dashcamCam, false)
        dashcamCam = nil
    end
    lib.notify({ type = 'info', description = 'Dashcam feed disconnected.' })
end

-- ==================== ACTIVE PERSONNEL '/plist' ====================
RegisterCommand('plist', function()
    if not CheckDuty() then
        lib.notify({ type = 'error', description = 'Access denied: Police officers only!' })
        return
    end

    lib.callback('police-suite:server:getOnlineCops', false, function(cops)
        local options = {}
        for _, cop in ipairs(cops) do
            table.insert(options, {
                title = cop.name .. ' (ID: ' .. cop.id .. ')',
                description = 'Callsign: ' .. (cop.callsign or 'None') .. ' | Status: Active & On-Duty',
                icon = 'fas fa-shield-alt',
                onSelect = function()
                    local actions = {
                        { title = 'Ping Officer GPS', icon = 'fas fa-map-marker-alt', onSelect = function()
                            SetNewWaypoint(cop.coords.x, cop.coords.y)
                            lib.notify({ type = 'success', description = 'Pinned GPS location for ' .. cop.name })
                        end },
                        { title = 'Join Radio Frequency', icon = 'fas fa-broadcast-tower', onSelect = function()
                            TriggerEvent('qb-radialmenu:radio:frequencies')
                        end }
                    }
                    lib.registerContext({
                        id = 'plist_cop_opts_' .. cop.id,
                        title = cop.name,
                        options = actions
                    })
                    lib.showContext('plist_cop_opts_' .. cop.id)
                end
            })
        end

        if #options == 0 then
            table.insert(options, { title = 'No other officers online', disabled = true })
        end

        lib.registerContext({
            id = 'plist_main',
            title = 'Active Police Roster (P-List)',
            options = options
        })
        lib.showContext('plist_main')
    end)
end, false)

-- ==================== GPS REAL-TIME ON-DUTY TRACKING ====================
CreateThread(function()
    while true do
        Wait(3000) -- Update blips every 3 seconds
        if CheckDuty() then
            -- Fetch all cop locations from server
            lib.callback('police-suite:server:getOnlineCops', false, function(cops)
                -- Clear current blips
                for _, b in pairs(activeBlips) do
                    RemoveBlip(b)
                end
                activeBlips = {}

                local myId = GetPlayerServerId(PlayerId())
                for _, cop in ipairs(cops) do
                    if cop.id ~= myId then
                        local blip = AddBlipForCoords(cop.coords.x, cop.coords.y, cop.coords.z)
                        SetBlipSprite(blip, 60) -- Police car/officer sprite
                        SetBlipColour(blip, 3)  -- Police blue color
                        SetBlipScale(blip, 0.85)
                        SetBlipAsShortRange(blip, true)
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentString("Officer " .. cop.name)
                        EndTextCommandSetBlipName(blip)

                        activeBlips[cop.id] = blip
                    end
                end
            end)
        else
            -- If off-duty, remove any active police blips
            for _, b in pairs(activeBlips) do
                RemoveBlip(b)
            end
            activeBlips = {}
        end
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if droneActive then ExitDrone() end
        if dashcamActive then ExitDashcam() end
        for _, b in pairs(activeBlips) do RemoveBlip(b) end
    end
end)
