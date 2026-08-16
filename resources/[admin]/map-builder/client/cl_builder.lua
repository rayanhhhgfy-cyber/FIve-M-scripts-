local builderActive = false
local freeCamActive = false
local cam = nil
local camSpeed = 0.5
local camHeading = 0.0
local camPitch = 0.0
local altitudeLocked = false
local altitudeLockHeight = 0.0

local editorMode = 'simple' -- simple or advanced
local gridSnapValue = 0.0 -- 0.0 = no snap, or e.g., 0.5, 1.0, 5.0
local alignToNormal = true
local collisionEnabled = true
local frozenState = true

local ghostEntity = nil
local ghostModel = nil
local hoveredEntity = nil
local currentEditingLightId = nil

local placedProps = {} -- Tracks client-side prop handles
local pointLights = {} -- Tracks client-side light definitions

-- Multi-prop / Brush tools
local activeBrushType = nil -- 'scatter', 'erase', 'measure', 'array'
local brushRadius = 5.0
local scatterModels = { 'prop_veg_crop_03_shrub', 'prop_veg_grass_01', 'prop_tree_birch_05' }

-- Distance measuring
local measureStartCoords = nil
local measureEndCoords = nil

-- Simple notification wrapper
local function ShowNotification(text, nType)
    exports.ox_lib:notify({ type = nType or 'info', description = text })
end

-- Robust hash getter (handles both strings and numbers)
function GetHash(model)
    if type(model) == 'number' then
        return model
    elseif type(model) == 'string' then
        return joaat(model)
    else
        return 0
    end
end

-- Raycasting helper
local function GetRaycastResult(maxDist)
    local cameraCoords = GetCamCoord(cam)
    local cameraRotation = GetCamRot(cam, 2)
    local forwardVector = RotationToDirection(cameraRotation)
    local targetCoords = cameraCoords + (forwardVector * (maxDist or 100.0))

    local handle = StartShapeTestRay(cameraCoords.x, cameraCoords.y, cameraCoords.z, targetCoords.x, targetCoords.y, targetCoords.z, -1, PlayerPedId(), 4)
    local _, hit, hitCoords, hitNormal, entityHit = GetShapeTestResult(handle)
    return hit, hitCoords, hitNormal, entityHit
end

function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return vector3(direction.x, direction.y, direction.z)
end

-- Command to toggle map builder
RegisterCommand(Config.MapBuilder.command, function()
    TriggerServerEvent('map-builder:server:checkAuth')
end, false)

RegisterNetEvent('map-builder:client:startBuilder', function(authorized)
    if not authorized then
        ShowNotification('You are not authorized to use the Map Builder', 'error')
        return
    end
    builderActive = not builderActive
    ToggleBuilderMode(builderActive)
end)

function ToggleBuilderMode(active)
    if active then
        StartFreeCam()
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        SendNUIMessage({ action = 'openBuilder', mode = editorMode })
        ShowNotification('Map Builder Mode Activated. Hold Right Click to rotate camera!', 'success')
    else
        StopFreeCam()
        DeleteGhostEntity()
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = 'closeBuilder' })
        ShowNotification('Map Builder Mode Deactivated', 'info')
    end
end

-- Free Cam implementation
function StartFreeCam()
    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)

    local coords = GetEntityCoords(ped)
    camHeading = GetEntityHeading(ped)
    camPitch = 0.0

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, coords.x, coords.y, coords.z + 5.0)
    SetCamRot(cam, camPitch, 0.0, camHeading, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    freeCamActive = true

    CreateThread(function()
        while freeCamActive do
            Wait(0)
            HandleFreeCamMovement()
            UpdateGhostAndHoverState()
        end
    end)
end

function StopFreeCam()
    freeCamActive = false
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)

    if cam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        cam = nil
    end
end

function HandleFreeCamMovement()
    local camCoords = GetCamCoord(cam)
    local camRot = GetCamRot(cam, 2)
    local dir = RotationToDirection(camRot)
    local right = RotationToDirection(vector3(camRot.x, camRot.y, camRot.z + 90.0))

    local speed = camSpeed
    if IsControlPressed(0, 21) then speed = camSpeed * Config.MapBuilder.maxFlySpeed end -- Shift for boost

    local moveVec = vector3(0, 0, 0)
    if IsControlPressed(0, 32) then moveVec = moveVec + (dir * speed) end -- W
    if IsControlPressed(0, 33) then moveVec = moveVec - (dir * speed) end -- S
    if IsControlPressed(0, 34) then moveVec = moveVec - (right * speed) end -- A
    if IsControlPressed(0, 35) then moveVec = moveVec + (right * speed) end -- D

    -- Altitude lock
    local newZ = camCoords.z + moveVec.z
    if altitudeLocked then
        newZ = altitudeLockHeight
    else
        if IsControlPressed(0, 51) then newZ = camCoords.z + speed end -- E (Up)
        if IsControlPressed(0, 52) then newZ = camCoords.z - speed end -- Q (Down)
    end

    SetCamCoord(cam, camCoords.x + moveVec.x, camCoords.y + moveVec.y, newZ)

    -- Disable standard conflicting keys during freecam
    DisableControlAction(0, 24, true) -- Left Click (Shoot)
    DisableControlAction(0, 25, true) -- Right Click (Aim)
    DisableControlAction(0, 142, true) -- Melee
    DisableControlAction(0, 18, true) -- Enter vehicle
    DisableControlAction(0, 37, true) -- Weapon Wheel
    DisableControlAction(0, 106, true) -- Vehicle Mouse Control

    -- Prop editing arrow key inputs (Left / Right keys to rotate smoothly)
    if IsControlPressed(0, 174) then -- Arrow Left
        camHeading = camHeading - 1.5
    end
    if IsControlPressed(0, 175) then -- Arrow Right
        camHeading = camHeading + 1.5
    end

    -- Camera rotation mouse controls (Only when Right Click is held down)
    if IsDisabledControlPressed(1, 25) then
        local mouseX = GetDisabledControlNormal(1, 1) * -4.0
        local mouseY = GetDisabledControlNormal(1, 2) * -4.0

        camHeading = camHeading + mouseX
        camPitch = math.max(-85.0, math.min(85.0, camPitch + mouseY))
    end
    SetCamRot(cam, camPitch, 0.0, camHeading, 2)
end

-- Dynamic Placement, Ghosting, and Hover states
function UpdateGhostAndHoverState()
    local hit, coords, normal, entity = GetRaycastResult(100.0)
    hoveredEntity = entity

    -- Custom distance measuring
    if activeBrushType == 'measure' and measureStartCoords then
        measureEndCoords = coords
        local dist = #(measureStartCoords - measureEndCoords)
        SendNUIMessage({ action = 'updateMeasure', distance = dist })
    end

    if not ghostModel then
        DeleteGhostEntity()
        return
    end

    -- Handle grid snap
    local finalCoords = coords
    if gridSnapValue > 0.0 then
        finalCoords = vector3(
            math.floor(coords.x / gridSnapValue + 0.5) * gridSnapValue,
            math.floor(coords.y / gridSnapValue + 0.5) * gridSnapValue,
            math.floor(coords.z / gridSnapValue + 0.5) * gridSnapValue
        )
    end

    local modelHash = GetHash(ghostModel)
    if not ghostEntity or GetEntityModel(ghostEntity) ~= modelHash then
        DeleteGhostEntity()
        RequestModel(modelHash)
        local timer = 0
        while not HasModelLoaded(modelHash) and timer < 100 do
            Wait(10)
            timer = timer + 1
        end
        ghostEntity = CreateObject(modelHash, finalCoords.x, finalCoords.y, finalCoords.z, false, false, false)
        SetEntityAlpha(ghostEntity, 150, false)
        SetEntityCollision(ghostEntity, false, false)
        FreezeEntityPosition(ghostEntity, true)
    else
        SetEntityCoords(ghostEntity, finalCoords.x, finalCoords.y, finalCoords.z, false, false, false, false)
        if alignToNormal then
            SetEntityRotation(ghostEntity, normal.x * 90.0, normal.y * 90.0, camHeading, 2, true)
        else
            SetEntityRotation(ghostEntity, 0.0, 0.0, camHeading, 2, true)
        end
    end
end

function DeleteGhostEntity()
    if ghostEntity and DoesEntityExist(ghostEntity) then
        DeleteEntity(ghostEntity)
        ghostEntity = nil
    end
end

-- UI and NUI communication
RegisterNUICallback('selectCatalogProp', function(data, cb)
    ghostModel = data.model
    cb('ok')
end)

RegisterNUICallback('eyedropperSelect', function(_, cb)
    local hit, coords, normal, entity = GetRaycastResult(100.0)
    if entity and DoesEntityExist(entity) then
        local modelHash = GetEntityModel(entity)
        ghostModel = modelHash
        ShowNotification('Eyedropper sampled entity model: ' .. tostring(modelHash), 'success')
    else
        ShowNotification('No entity hit by eyedropper', 'error')
    end
    cb('ok')
end)

RegisterNUICallback('placeProp', function(data, cb)
    local hit, coords, normal, entity = GetRaycastResult(100.0)
    if not ghostModel then
        ShowNotification('No prop selected to place', 'error')
        cb('ok')
        return
    end

    local rot = GetEntityRot(ghostEntity, 2)
    TriggerServerEvent('map-builder:server:saveProp', {
        model = ghostModel,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        rotation = { x = rot.x, y = rot.y, z = rot.z },
        collision = collisionEnabled,
        frozen = frozenState,
        logic = data.logic or nil
    })
    cb('ok')
end)

RegisterNetEvent('map-builder:client:propPlaced', function(propData)
    -- On client, we only cache the handles list.
    -- The networked entity itself is spawned safely server-side to avoid duplication desync!
end)

-- Measure utility
RegisterNUICallback('toggleMeasureTool', function(_, cb)
    if activeBrushType == 'measure' then
        activeBrushType = nil
        measureStartCoords = nil
        measureEndCoords = nil
        ShowNotification('Measurement tool disabled', 'info')
    else
        activeBrushType = 'measure'
        local hit, coords = GetRaycastResult(100.0)
        measureStartCoords = coords
        ShowNotification('Point-to-point measuring tool enabled. Click again to set endpoint.', 'info')
    end
    cb('ok')
end)

-- Brush tools (Scatter, Erase, Array)
RegisterNUICallback('setBrushTool', function(data, cb)
    activeBrushType = data.type -- 'scatter', 'erase', 'array' or nil
    brushRadius = data.radius or 5.0
    cb('ok')
end)

CreateThread(function()
    while true do
        Wait(0)
        if builderActive then
            if activeBrushType == 'scatter' then
                local pos = GetCamCoord(cam) + (RotationToDirection(GetCamRot(cam, 2)) * 10.0)
                DrawMarker(1, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, brushRadius, brushRadius, 1.0, 39, 201, 63, 100, false, true, 2, false, nil, false, false)
                if IsControlJustPressed(0, 24) then -- Left click to paint
                    local hit, coords, normal = GetRaycastResult(100.0)
                    if hit then
                        for i = 1, 5 do
                            local offsetX = (math.random() - 0.5) * brushRadius
                            local offsetY = (math.random() - 0.5) * brushRadius
                            local randomModel = scatterModels[math.random(#scatterModels)]
                            local scCoords = vector3(coords.x + offsetX, coords.y + offsetY, coords.z)

                            TriggerServerEvent('map-builder:server:saveProp', {
                                model = randomModel,
                                coords = { x = scCoords.x, y = scCoords.y, z = scCoords.z },
                                rotation = { x = 0.0, y = 0.0, z = math.random() * 360.0 },
                                collision = true,
                                frozen = true
                            })
                        end
                    end
                end
            elseif activeBrushType == 'erase' then
                local pos = GetCamCoord(cam) + (RotationToDirection(GetCamRot(cam, 2)) * 10.0)
                DrawMarker(1, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, brushRadius, brushRadius, 1.0, 255, 69, 58, 100, false, true, 2, false, nil, false, false)
                if IsControlJustPressed(0, 24) then -- Left click to erase
                    local hit, coords, normal, entity = GetRaycastResult(100.0)
                    if hit then
                        local modelHash = 0
                        if entity ~= 0 and DoesEntityExist(entity) then
                            modelHash = GetEntityModel(entity)
                        else
                            -- Find closest static map object (with full fallback!)
                            local closestObj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, 0, false, false, false)
                            if closestObj ~= 0 and DoesEntityExist(closestObj) then
                                modelHash = GetEntityModel(closestObj)
                            end
                        end

                        if modelHash and modelHash ~= 0 then
                            TriggerServerEvent('map-builder:server:deletePropByCoords', coords)
                            TriggerServerEvent('map-builder:server:eraseWorldProp', coords, modelHash)
                            ShowNotification('Permanently removed and hid map entity!', 'success')
                        end
                    end
                end
            elseif activeBrushType == 'array' then
                local pos = GetCamCoord(cam) + (RotationToDirection(GetCamRot(cam, 2)) * 10.0)
                DrawMarker(1, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, brushRadius, brushRadius, 1.0, 0, 122, 255, 100, false, true, 2, false, nil, false, false)
                if IsControlJustPressed(0, 24) and ghostModel then -- Line procedural duplication
                    local hit, coords = GetRaycastResult(100.0)
                    if hit then
                        for i = 1, 5 do
                            local scCoords = coords + (RotationToDirection(GetCamRot(cam, 2)) * (i * 2.0))
                            TriggerServerEvent('map-builder:server:saveProp', {
                                model = ghostModel,
                                coords = { x = scCoords.x, y = scCoords.y, z = scCoords.z },
                                rotation = { x = 0.0, y = 0.0, z = camHeading },
                                collision = true,
                                frozen = true
                            })
                        end
                        ShowNotification('Created procedural array successfully', 'success')
                    end
                end
            end
        end

        -- Draw all active point lights dynamically in real-time
        for _, l in pairs(pointLights) do
            DrawLightWithRange(l.coords.x, l.coords.y, l.coords.z, l.color.r, l.color.g, l.color.b, l.range, l.intensity)
        end
    end
end)

-- Core builder toggles from NUI
RegisterNUICallback('setBuilderMode', function(data, cb)
    editorMode = data.mode
    cb('ok')
end)

RegisterNUICallback('toggleCollision', function(data, cb)
    collisionEnabled = data.state
    if ghostEntity then
        SetEntityCollision(ghostEntity, collisionEnabled, collisionEnabled)
    end
    cb('ok')
end)

RegisterNUICallback('toggleAlign', function(data, cb)
    alignToNormal = data.state
    cb('ok')
end)

RegisterNUICallback('toggleFreeze', function(data, cb)
    frozenState = data.state
    cb('ok')
end)

RegisterNUICallback('setGridSnap', function(data, cb)
    gridSnapValue = data.value
    cb('ok')
end)

RegisterNUICallback('savePrefab', function(data, cb)
    TriggerServerEvent('map-builder:server:saveAsPrefab', data.name)
    cb('ok')
end)

RegisterNUICallback('exportMap', function(data, cb)
    TriggerServerEvent('map-builder:server:exportMap', data.format)
    cb('ok')
end)

RegisterNUICallback('updateLightSettings', function(data, cb)
    -- Handle spotlight / point light preview adjustments
    -- In lights modification, switch time to night preview automatically!
    TriggerServerEvent('weathersync:server:setTime', 22, 0)
    ShowNotification('Auto-switched environment to Night Preview for light configuration!', 'info')

    local hit, coords = GetRaycastResult(100.0)
    if hit then
        local hex = data.color or "#ffffff"
        hex = hex:gsub("#", "")
        local r = tonumber("0x" .. hex:sub(1, 2)) or 255
        local g = tonumber("0x" .. hex:sub(3, 4)) or 255
        local b = tonumber("0x" .. hex:sub(5, 6)) or 255

        -- Store point light dynamically
        if not currentEditingLightId then
            currentEditingLightId = 'light_' .. os.time() .. '_' .. math.random(1111, 9999)
        end
        pointLights[currentEditingLightId] = {
            coords = coords,
            color = { r = r, g = g, b = b },
            range = data.range or 15.0,
            intensity = data.intensity or 10.0
        }
    end
    cb('ok')
end)

RegisterNUICallback('commitLight', function(_, cb)
    -- Save light permanently in database persistence!
    local l = pointLights[currentEditingLightId]
    if l then
        TriggerServerEvent('map-builder:server:saveProp', {
            model = 'prop_wall_light_01a',
            coords = { x = l.coords.x, y = l.coords.y, z = l.coords.z },
            rotation = { x = 0.0, y = 0.0, z = 0.0 },
            collision = false,
            frozen = true,
            lightData = { color = l.color, range = l.range, intensity = l.intensity }
        })
    end
    currentEditingLightId = nil
    ShowNotification('Point light committed and saved permanently!', 'success')
    cb('ok')
end)

RegisterNetEvent('map-builder:client:syncPointLight', function(lightData)
    local id = 'light_' .. os.time() .. '_' .. math.random(1111, 9999)
    pointLights[id] = {
        coords = vector3(lightData.coords.x, lightData.coords.y, lightData.coords.z),
        color = lightData.color,
        range = lightData.range,
        intensity = lightData.intensity
    }
end)

RegisterNUICallback('notify', function(data, cb)
    ShowNotification(data.text, 'info')
    cb('ok')
end)

-- Exiting Cleanup
AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if builderActive then
            ToggleBuilderMode(false)
        end
    end
end)
