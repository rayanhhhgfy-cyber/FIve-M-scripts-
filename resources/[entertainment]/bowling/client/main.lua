local QBCore = exports['qbx-core']:GetCoreObject()
local inGame = false
local aiming = false
local aimAngle = 0.5
local power = 0.5
local currentSession = nil

local function setupBowlingTarget()
    local model = GetHashKey('prop_bowling_pin')
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 50 do
        Wait(10)
        attempts = attempts + 1
    end

    local obj = GetClosestObjectOfType(Config.Bowling.alleyCoords.x, Config.Bowling.alleyCoords.y, Config.Bowling.alleyCoords.z, 2.0, model, false, false, false)
    if obj == 0 then
        obj = CreateObject(model, Config.Bowling.alleyCoords.x, Config.Bowling.alleyCoords.y, Config.Bowling.alleyCoords.z, false, false, false)
        FreezeEntityPosition(obj, true)
    end

    exports.ox_target:addLocalEntity(obj, {
        {
            name = 'bowling_start_game',
            label = Locale('bowling.start_game'),
            icon = 'fa-solid fa-bowling-ball',
            onSelect = function()
                TriggerServerEvent('bowling:startGame')
            end,
        },
    })
end

RegisterNetEvent('bowling:gameStarted', function(pins)
    inGame = true
    currentSession = { pins = pins }
    Wrappers.Notify(Locale('bowling.start_game'), 'success')

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, Config.Bowling.cameraPos.x, Config.Bowling.cameraPos.y, Config.Bowling.cameraPos.z)
    PointCamAtCoord(cam, Config.Bowling.pinArea.x, Config.Bowling.pinArea.y, Config.Bowling.pinArea.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)
end)

RegisterNetEvent('bowling:throwResult', function(score, pins, frameScores, currentFrame, currentThrow, totalScore)
    currentSession.pins = pins
    currentSession.frameScores = frameScores
    currentSession.currentFrame = currentFrame
    currentSession.currentThrow = currentThrow
    currentSession.totalScore = totalScore

    Wrappers.TextUI(Locale('bowling.frame_result', score) .. ' | ' .. Locale('bowling.final_score', totalScore))
    Wait(3000)
    Wrappers.HideTextUI()

    if currentThrow == 1 then
        Wrappers.Notify(Locale('bowling.throw'), 'info')
    end
end)

RegisterNetEvent('bowling:gameOver', function(session)
    inGame = false
    local totalScore = 0
    for i = 1, Config.Bowling.frames do
        totalScore = totalScore + (session.frameScores[i] and session.frameScores[i].total or 0)
    end
    Wrappers.Notify(Locale('bowling.game_over', totalScore), 'info')
    TriggerServerEvent('bowling:endGame')
end)

RegisterNetEvent('bowling:gameFinalized', function(totalScore)
    RenderScriptCams(false, true, 1000, true, true)
    DestroyAllCams(true)
    currentSession = nil
end)

local function startAiming()
    aiming = true
    aimAngle = 0.5
    power = 0.0

    Wrappers.ProgressBar({
        duration = 3000,
        label = Locale('bowling.aiming'),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'anim@amb@medic@standing@kneel@base', clip = 'base' },
        prop = {},
    })

    local progress = 0.0
    local aimDir = 1
    local powerDir = 1

    CreateThread(function()
        while aiming do
            if IsControlPressed(0, 34) then
                aimAngle = aimAngle + aimDir * 0.01
                if aimAngle >= 1.0 then aimDir = -1
                elseif aimAngle <= 0.0 then aimDir = 1 end
            end
            if IsControlPressed(0, 35) then
                power = power + powerDir * 0.01
                if power >= 1.0 then powerDir = -1
                elseif power <= 0.0 then powerDir = 1 end
            end
            if IsControlJustReleased(0, 24) then
                aiming = false
                TriggerServerEvent('bowling:throwBall', aimAngle, power)
                break
            end
            Wait(10)
        end
    end)
end

CreateThread(function()
    setupBowlingTarget()
end)

CreateThread(function()
    while true do
        Wait(0)
        if inGame then
            Wrappers.TextUI(Locale('bowling.throw') .. ' | ' .. Locale('bowling.final_score', currentSession and currentSession.totalScore or 0))
            if IsControlJustPressed(0, 24) then
                startAiming()
            end
        end
        Wait(500)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        RenderScriptCams(false, true, 1000, true, true)
        DestroyAllCams(true)
    end
end)
