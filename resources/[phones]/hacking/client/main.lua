local QBox = exports['qbx-core']:GetCoreObject()
local hackingActive = false
local hackAttempts = 0
local hackMaxAttempts = 0
local hackSequence = {}
local hackCurrentStep = 0

local function hasTool() return QBox.Functions.HasItem(Config.Hacking.ItemName) end

RegisterNetEvent('hacking:start', function(hackType, difficulty, onSuccess, onFail)
    if hackingActive then return end
    if Config.Hacking.RequireItem and not hasTool() then Wrappers.Notify(Locale('phone.no_hack_tool'), 'error') return end
    local diffData = Config.Hacking.DifficultyLevels[difficulty]
    if not diffData then Wrappers.Notify(Locale('phone.invalid_hack'), 'error') return end
    hackingActive = true
    hackAttempts = diffData.attempts
    hackMaxAttempts = diffData.attempts
    hackCurrentStep = 0
    hackSequence = {}
    for i = 1, Config.Hacking.Minigame.SequenceLength do
        hackSequence[i] = math.random(1, Config.Hacking.Minigame.GridSize * Config.Hacking.Minigame.GridSize)
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'startHack', config = Config.Hacking.Minigame, sequence = hackSequence, attempts = hackAttempts, time = diffData.time })
end)

RegisterNUICallback('hackStep', function(data, cb)
    if not hackingActive then cb('error') return end
    if data and data.step == hackSequence[hackCurrentStep + 1] then
        hackCurrentStep = hackCurrentStep + 1
        if hackCurrentStep >= #hackSequence then
            hackingActive = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'hackComplete' })
            Wrappers.Notify(Locale('phone.hack_success'), 'success')
            cb({ complete = true, success = true })
            return
        end
        cb({ complete = false, step = hackCurrentStep, total = #hackSequence })
    else
        hackAttempts = hackAttempts - 1
        if hackAttempts <= 0 then
            hackingActive = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'hackFailed' })
            Wrappers.Notify(Locale('phone.hack_failed'), 'error')
            cb({ complete = true, success = false })
        else
            cb({ complete = false, attempts = hackAttempts, error = true })
        end
    end
end)

RegisterNUICallback('cancelHack', function(_, cb)
    if hackingActive then
        hackingActive = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'hackCancelled' })
        Wrappers.Notify(Locale('phone.hack_cancelled'), 'info')
    end
    cb('ok')
end)

AddEventHandler('onResourceStop', function(r)
    if GetCurrentResourceName() == r and hackingActive then SetNuiFocus(false, false) end
end)
