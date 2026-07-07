local currentRange = Config.Voice.defaultRange
local currentRadio = nil
local megaphoneActive = false
local voiceModes = Config.Voice.voiceModes

local function SetVoiceRange(range)
    currentRange = range
    exports['pma-voice']:setVoiceProperty('radioRange', range)
    TriggerServerEvent('pma-voice-cfg:server:voiceRangeChanged', range)
end

local function CycleVoiceRange()
    local nextIndex = nil
    for i, mode in ipairs(voiceModes) do
        if mode.range == currentRange then
            nextIndex = i + 1
            break
        end
    end
    if not nextIndex or nextIndex > #voiceModes then
        nextIndex = 1
    end
    SetVoiceRange(voiceModes[nextIndex].range)
    Wrappers.Notify({ type = 'info', description = 'Voice: ' .. voiceModes[nextIndex].name })
end

RegisterCommand('voicerange', function()
    CycleVoiceRange()
end, false)

RegisterKeyMapping('voicerange', 'Cycle Voice Range', 'keyboard', 'z')

RegisterNetEvent('pma-voice-cfg:client:radioJoined', function(frequency)
    currentRadio = frequency
    Wrappers.Notify({ type = 'success', description = string.format('Radio: Frequency %d', frequency) })
end)

RegisterNetEvent('pma-voice-cfg:client:radioLeft', function()
    currentRadio = nil
    Wrappers.Notify({ type = 'info', description = 'Radio: Disconnected' })
end)

local function InitializeVoiceClient()
    exports['pma-voice']:setVoiceProperty('radioRange', currentRange)
    exports['pma-voice']:setVoiceProperty('megaphone', false)
    exports['pma-voice']:setVoiceProperty('micClicks', true)
    exports['pma-voice']:setVoiceProperty('3dAudio', true)
    print('^2[pma-voice-cfg] Client voice initialized.^7')
end

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    InitializeVoiceClient()
end)

AddEventHandler('pma-voice:radio:join', function(frequency)
    currentRadio = frequency
end)

AddEventHandler('pma-voice:radio:leave', function()
    currentRadio = nil
end)

exports('GetVoiceRange', function() return currentRange end)
exports('GetRadioFrequency', function() return currentRadio end)
exports('IsMegaphoneActive', function() return megaphoneActive end)
