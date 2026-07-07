local QBCore = exports['qbx-core']:GetCoreObject()
local isFishing = false

RegisterNetEvent('fishing:castClient', function(catchTime, targetFish)
    isFishing = true
    local ped = PlayerPedId()
    local pedPos = GetEntityCoords(ped)

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, pedPos.x, pedPos.y, pedPos.z + 2.0)
    SetCamRot(cam, -15.0, 0.0, GetEntityHeading(ped), 2)
    RenderScriptCams(true, true, 500, true, true)

    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_FISHING', 0, true)

    Wrappers.TextUI(Locale('fishing.waiting'))

    local elapsed = 0
    while elapsed < catchTime and isFishing do
        Wait(100)
        elapsed = elapsed + 100
        if not IsPedStill(ped) then
            isFishing = false
            break
        end
    end

    Wrappers.HideTextUI()
    ClearPedTasks(ped)

    if not isFishing then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(cam, false)
        Wrappers.Notify(Locale('fishing.fish_lost'), 'error')
        TriggerServerEvent('fishing:reel', { success = false })
        return
    end

    RenderScriptCams(false, true, 200, true, true)
    DestroyCam(cam, false)

    Wrappers.TextUI(Locale('fishing.reel_in'))
    Wrappers.SkillCheck(Config.Fishing.skillCheckDifficulty, function(success)
        Wrappers.HideTextUI()
        TriggerServerEvent('fishing:reel', { success = success })
        isFishing = false
    end)
end)

CreateThread(function()
    for _, spot in ipairs(Config.Fishing.spots) do
        exports.ox_target:addBoxZone({
            coords = spot,
            size = vec3(2.0, 2.0, 1.0),
            rotation = 0,
            options = {
                {
                    name = 'fish_spot_' .. _,
                    label = Locale('fishing.cast_line'),
                    icon = 'fas fa-fish',
                    onSelect = function()
                        if isFishing then return end
                        TriggerServerEvent('fishing:cast', { spot = { x = spot.x, y = spot.y, z = spot.z } })
                    end,
                },
            },
        })
    end

    local sellCoords = Config.Fishing.spots[1]
    if sellCoords then
        local sellPos = vector3(sellCoords.x - 5.0, sellCoords.y - 5.0, sellCoords.z)
        exports.ox_target:addBoxZone({
            coords = sellPos,
            size = vec3(2.0, 2.0, 1.5),
            rotation = 0,
            options = {
                {
                    name = 'fish_sell',
                    label = Locale('fishing.sell_fish'),
                    icon = 'fas fa-dollar-sign',
                    onSelect = function()
                        TriggerServerEvent('fishing:sellFish')
                    end,
                },
            },
        })
    end
end)
