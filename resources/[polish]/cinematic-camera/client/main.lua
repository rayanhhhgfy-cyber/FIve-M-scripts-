local cinematicActive = false
local colorGradeIdx = 1
local dofActive = false

RegisterCommand('cinematic', function()
    cinematicActive = not cinematicActive
    if cinematicActive then
        TriggerEvent('cinematic:activate')
    else
        TriggerEvent('cinematic:deactivate')
    end
end, false)

RegisterKeyMapping('cinematic', 'Toggle Cinematic Mode', 'keyboard', Config.Cinematic.toggleKey)

RegisterNetEvent('cinematic:activate', function()
    cinematicActive = true
    DoScreenFadeOut(Config.Cinematic.letterboxSpeed)
    Wait(Config.Cinematic.letterboxSpeed)
    DoScreenFadeIn(Config.Cinematic.letterboxSpeed)
end)

RegisterNetEvent('cinematic:deactivate', function()
    cinematicActive = false
    ClearTimecycleModifier()
    SetTimecycleModifierStrength(0.0)
    SetCamFov(GetCamFov(GetRenderingCam()), 50.0)
    DoScreenFadeOut(Config.Cinematic.letterboxSpeed)
    Wait(Config.Cinematic.letterboxSpeed)
    DoScreenFadeIn(Config.Cinematic.letterboxSpeed)
end)

CreateThread(function()
    while true do
        Wait(0)
        if cinematicActive then
            local resX, resY = GetActiveScreenResolution()
            local barH = resY * Config.Cinematic.letterboxHeight
            DrawRect(0.5, 0.0, 1.0, barH / resY, 0, 0, 0, 255)
            DrawRect(0.5, 1.0, 1.0, barH / resY, 0, 0, 0, 255)

            if IsControlJustPressed(0, 38) then
                colorGradeIdx = (colorGradeIdx % #Config.Cinematic.effects.colorGrade) + 1
                SetTimecycleModifier(Config.Cinematic.effects.colorGrade[colorGradeIdx])
                Wrappers.Notify('Color: ' .. Config.Cinematic.effects.colorGrade[colorGradeIdx], 'info')
            end
            if IsControlJustPressed(0, 39) then
                dofActive = not dofActive
                if dofActive then
                    SetCamDofStrength(GetRenderingCam(), Config.Cinematic.effects.depthOfField.strength)
                    SetCamDofPlane(GetRenderingCam(), 5.0)
                else
                    SetCamDofStrength(GetRenderingCam(), 0.0)
                end
                Wrappers.Notify(dofActive and 'DOF ON' or 'DOF OFF', 'info')
            end
            HideHudAndRadarThisFrame()
        end
    end
end)
