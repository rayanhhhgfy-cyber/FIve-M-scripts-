local snakeCamActive = false
local snakeCamObj = nil
local snakeCamCam = nil

-- Helper to calculate forward position
function GetForwardVector(rotation)
    local z = rotation.z * (math.pi / 180.0)
    local x = rotation.x * (math.pi / 180.0)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

function StartSnakeCam()
    local ped = PlayerPedId()
    if snakeCamActive then return end

    -- Check if player is near a wall or door
    local coords = GetEntityCoords(ped)
    local rot = GetEntityRotation(ped, 2)
    local forward = GetForwardVector(rot)
    local targetCoords = coords + (forward * 1.5)

    -- Play peering/kneeling animation
    RequestAnimDict('amb@medic@standing@kneel@base')
    while not HasAnimDictLoaded('amb@medic@standing@kneel@base') do Wait(10) end

    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Spawn snake cam prop
    local model = `prop_spy_camera`
    if not IsModelInCdimage(model) then model = `prop_amb_phone` end -- Safe fallback
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local attachCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.5, -0.6)
    snakeCamObj = CreateObject(model, attachCoords.x, attachCoords.y, attachCoords.z, true, true, false)
    AttachEntityToEntity(snakeCamObj, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    -- Create scripted camera peering forward
    local camCoords = coords + (forward * 1.8) + vector3(0.0, 0.0, -0.7) -- Lowered to ground level
    local camRot = GetEntityRotation(ped, 2)

    snakeCamCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(snakeCamCam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(snakeCamCam, camRot.x - 10.0, camRot.y, camRot.z, 2)
    SetCamActive(snakeCamCam, true)
    RenderScriptCams(true, false, 0, true, true)

    -- Apply high-tech camera night-vision / green-filtered overlay
    SetNightvision(true)
    snakeCamActive = true

    lib.notify({ type = 'info', description = 'Snake Cam Active. Press [BACKSPACE] or [ESC] to exit.' })

    CreateThread(function()
        while snakeCamActive do
            Wait(0)
            -- Intercept exit keys (Backspace / ESC)
            DisableControlAction(0, 177, true) -- Backspace
            DisableControlAction(0, 200, true) -- ESC

            if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) then
                ExitSnakeCam()
            end
        end
    end)
end

RegisterCommand('snakecam', function()
    StartSnakeCam()
end, false)

RegisterNetEvent('snakecam:client:use', function()
    StartSnakeCam()
end)

function ExitSnakeCam()
    snakeCamActive = false
    local ped = PlayerPedId()

    -- Restore camera rendering
    RenderScriptCams(false, false, 0, true, true)
    if snakeCamCam then
        DestroyCam(snakeCamCam, false)
        snakeCamCam = nil
    end

    -- Disable nightvision
    SetNightvision(false)

    -- Clean up prop & anims
    if snakeCamObj and DoesEntityExist(snakeCamObj) then
        DeleteEntity(snakeCamObj)
        snakeCamObj = nil
    end
    ClearPedTasks(ped)
    lib.notify({ type = 'info', description = 'Snake Cam deactivated.' })
end

AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() and snakeCamActive then
        ExitSnakeCam()
    end
end)

exports('useSnakecam', function()
    StartSnakeCam()
end)
