local QBox = exports['qbx-core']:GetCoreObject()
local cutsceneActive = false

RegisterNetEvent('jail:client:playCutscene', function(sentenceTime, charges)
    if cutsceneActive then return end
    cutsceneActive = true
    local ped = PlayerPedId()

    DoScreenFadeOut(Config.JailCutscene.FadeOutDuration)
    Citizen.Wait(Config.JailCutscene.FadeOutDuration)

    local cam = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', Config.JailCutscene.Camera.Position, vector3(0.0, 0.0, 0.0), Config.JailCutscene.Camera.FOV)
    PointCamAtCoord(cam, Config.JailCutscene.Camera.Target.x, Config.JailCutscene.Camera.Target.y, Config.JailCutscene.Camera.Target.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)

    SetEntityCoords(ped, Config.JailCutscene.Camera.Target)
    SetEntityHeading(ped, 180.0)
    FreezeEntityPosition(ped, true)
    ClearPedTasks(ped)

    DoScreenFadeIn(Config.JailCutscene.FadeInDuration)
    Citizen.Wait(Config.JailCutscene.FadeInDuration)

    if Config.JailCutscene.Sound.Enabled then
        PlaySound(-1, Config.JailCutscene.Sound.Name, Config.JailCutscene.Sound.Dict, false, 0, true)
    end

    local totalDuration = 0
    for _, stage in ipairs(Config.JailCutscene.BookingStages) do
        if not cutsceneActive then break end
        totalDuration = totalDuration + stage.duration

        SetTextFont(4)
        SetTextScale(0.6, 0.6)
        SetTextColour(255, 255, 255, 255)
        SetTextCentre(true)
        SetTextEntry('STRING')
        AddTextComponentString(stage.label .. '...')
        DrawText(0.5, 0.5)

        SetTextFont(4)
        SetTextScale(0.3, 0.3)
        SetTextColour(200, 200, 200, 200)
        SetTextCentre(true)
        SetTextEntry('STRING')
        AddTextComponentString(Locale('police.press_to_skip'))
        DrawText(0.5, 0.55)

        local currentProgress = 0
        while currentProgress < stage.duration and cutsceneActive do
            Citizen.Wait(100)
            currentProgress = currentProgress + 100
            if IsControlJustPressed(0, Config.JailCutscene.SkipKey) then
                cutsceneActive = false
                break
            end
        end
        if not cutsceneActive then break end
    end

    DoScreenFadeOut(Config.JailCutscene.FadeOutDuration)
    Citizen.Wait(Config.JailCutscene.FadeOutDuration)

    RenderScriptCams(false, true, 1000, true, true)
    DestroyCam(cam, false)

    SetEntityCoords(ped, Config.Prison.SpawnPoint.coords)
    SetEntityHeading(ped, Config.Prison.SpawnPoint.heading)
    FreezeEntityPosition(ped, false)

    DoScreenFadeIn(Config.JailCutscene.FadeInDuration)
    Citizen.Wait(Config.JailCutscene.FadeInDuration)

    cutsceneActive = false
    Wrappers.Notify(Locale('police.booking_complete', sentenceTime, charges), 'info')
    TriggerServerEvent('jail:server:cutsceneComplete')
end)

RegisterNetEvent('police:client:incarcerate', function(cellNumber, time, charges)
    TriggerEvent('jail:client:playCutscene', time, charges)
end)
