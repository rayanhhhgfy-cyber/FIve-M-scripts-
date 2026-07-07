local QBox = exports['qbx-core']:GetCoreObject()
local radioVolume = Config.RadioSystem.DefaultVolume
local hudTimeout = nil
local isTransmitting = false
local currentAnim = nil

local function hasRadio()
    return QBox.Functions.HasItem('radio')
end

local function showHUD()
    SendNUIMessage({
        action = 'showRadioHUD',
        volume = radioVolume,
    })
    if hudTimeout then
        Citizen.ClearTimeout(hudTimeout)
    end
    hudTimeout = Citizen.SetTimeout(Config.RadioSystem.HUDDisplayTime, function()
        SendNUIMessage({ action = 'hideRadioHUD' })
        hudTimeout = nil
    end)
end

local function setVolume(level)
    radioVolume = math.max(Config.RadioSystem.MinVolume, math.min(Config.RadioSystem.MaxVolume, level))
    exports['pma-voice']:setVoiceProperty('radioVolume', radioVolume / 100)
    showHUD()
end

RegisterCommand('+radioVolUp', function()
    if not hasRadio() then return end
    local freq = exports['pma-voice']:getRadioChannel()
    if not freq or freq <= 0 then
        Wrappers.Notify('No radio frequency tuned', 'error')
        return
    end
    setVolume(radioVolume + Config.RadioSystem.VolumeStep)
end, false)

RegisterKeyMapping('+radioVolUp', 'Radio Volume Up', 'keyboard', Config.RadioSystem.KeyVolumeUp:lower())

RegisterCommand('+radioVolDown', function()
    if not hasRadio() then return end
    local freq = exports['pma-voice']:getRadioChannel()
    if not freq or freq <= 0 then
        Wrappers.Notify('No radio frequency tuned', 'error')
        return
    end
    setVolume(radioVolume - Config.RadioSystem.VolumeStep)
end, false)

RegisterKeyMapping('+radioVolDown', 'Radio Volume Down', 'keyboard', Config.RadioSystem.KeyVolumeUp:lower())

local function playTransmitAnim()
    local ped = PlayerPedId()
    if not IsEntityPlayingAnim(ped, Config.RadioSystem.AnimDict, Config.RadioSystem.AnimName, 3) then
        QBox.Functions.RequestAnimDict(Config.RadioSystem.AnimDict, function()
            TaskPlayAnim(ped, Config.RadioSystem.AnimDict, Config.RadioSystem.AnimName, 8.0, 8.0, -1, 50, 0, false, false, false)
        end)
    end
end

local function stopTransmitAnim()
    local ped = PlayerPedId()
    if IsEntityPlayingAnim(ped, Config.RadioSystem.AnimDict, Config.RadioSystem.AnimName, 3) then
        ClearPedTasks(ped)
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.RadioSystem.TransmitCheckInterval)
        if not hasRadio() then
            if isTransmitting then
                isTransmitting = false
                stopTransmitAnim()
            end
            goto continue
        end
        local freq = exports['pma-voice']:getRadioChannel()
        if not freq or freq <= 0 then
            if isTransmitting then
                isTransmitting = false
                stopTransmitAnim()
            end
            goto continue
        end
        local talking = exports['pma-voice']:isTalking()
        if talking and not isTransmitting then
            isTransmitting = true
            playTransmitAnim()
        elseif not talking and isTransmitting then
            isTransmitting = false
            stopTransmitAnim()
        end
        ::continue::
    end
end)

RegisterCommand('radio', function(source, args)
    if not hasRadio() then
        Wrappers.Notify('You do not have a radio', 'error')
        return
    end
    local freq = tonumber(args[1])
    if not freq or freq < 1 or freq > 999 then
        Wrappers.Notify('Usage: /radio [1-999]', 'error')
        return
    end
    exports['pma-voice']:setRadioChannel(freq)
    Wrappers.Notify('Radio tuned to ' .. freq, 'success')
    setVolume(radioVolume)
end, false)

RegisterCommand('radiooff', function()
    exports['pma-voice']:removeRadioChannel()
    Wrappers.Notify('Radio turned off', 'info')
    if isTransmitting then
        isTransmitting = false
        stopTransmitAnim()
    end
end, false)
