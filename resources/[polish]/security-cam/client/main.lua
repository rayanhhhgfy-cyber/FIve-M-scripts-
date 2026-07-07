local QBCore = exports['qbx_core']:GetCoreObject()
local camActive = false
local currentCam = nil
local renderCam = nil

RegisterNetEvent('security_cam:client:view', function(camera)
    camActive = true
    currentCam = camera
    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    SetPlayerInvincible(PlayerId(), true)
    renderCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(renderCam, camera.coords.x, camera.coords.y, camera.coords.z)
    SetCamRot(renderCam, camera.rot.x, camera.rot.y, camera.rot.z)
    SetCamFov(renderCam, camera.fov)
    RenderScriptCams(true, true, 500, true, true)
    Wrappers.Notify(Locale('security_cam.view') .. ': ' .. camera.label, 'info')
end)

RegisterNetEvent('security_cam:client:switch', function(camera)
    if not camActive then return end
    currentCam = camera
    if renderCam then
        SetCamCoord(renderCam, camera.coords.x, camera.coords.y, camera.coords.z)
        SetCamRot(renderCam, camera.rot.x, camera.rot.y, camera.rot.z)
        SetCamFov(renderCam, camera.fov)
        RenderScriptCams(true, true, Config.SecurityCam.switchDelay, true, true)
    end
    Wrappers.Notify(Locale('security_cam.switch') .. ': ' .. camera.label, 'info')
end)

RegisterNetEvent('security_cam:client:stop', function()
    if not camActive then return end
    camActive = false
    currentCam = nil
    if renderCam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(renderCam, false)
        renderCam = nil
    end
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetPlayerInvincible(PlayerId(), false)
    ClearPedTasks(ped)
    Wrappers.Notify(Locale('security_cam.stop'), 'info')
end)

CreateThread(function()
    while true do
        Wait(0)
        if camActive then
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            if IsControlJustPressed(0, 108) then
                TriggerServerEvent('security_cam:switch', 'next')
            end
            if IsControlJustPressed(0, 127) then
                TriggerServerEvent('security_cam:switch', 'prev')
            end
            if IsControlJustPressed(0, 177) then
                TriggerServerEvent('security_cam:stop')
            end
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    for _, model in ipairs(Config.SecurityCam.monitorModels) do
        exports['ox_target']:addModel(model, {
            {
                name = 'security_cam_view',
                label = Locale('security_cam.view'),
                icon = 'fas fa-video',
                distance = Config.SecurityCam.maxDistance,
                onSelect = function()
                    Wrappers.ContextMenu({
                        id = 'security_cam_menu',
                        title = Locale('security_cam.title'),
                        options = {},
                    })
                    local options = {}
                    for i, cam in ipairs(Config.SecurityCam.cameras) do
                        options[#options + 1] = {
                            title = cam.label,
                            description = Locale('security_cam.camera') .. ' ' .. cam.id,
                            onSelect = function()
                                TriggerServerEvent('security_cam:view', cam.id)
                            end,
                        }
                    end
                    Wrappers.ContextMenu({
                        id = 'security_cam_menu',
                        title = Locale('security_cam.title'),
                        options = options,
                    })
                    Wrappers.ShowContextMenu('security_cam_menu')
                end,
            },
        })
    end
end)
