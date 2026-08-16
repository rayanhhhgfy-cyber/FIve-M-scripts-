local radioActive = false
local currentChannel = Config.Radio.defaultChannel

local function toggleRadio()
    radioActive = not radioActive
    if radioActive then
        TriggerServerEvent('radio:join', currentChannel)
        Wrappers.Notify(Locale('radio.on') .. ' | ' .. Locale('radio.channel') .. ': ' .. currentChannel, 'success')
    else
        TriggerServerEvent('radio:leave')
        Wrappers.Notify(Locale('radio.off'), 'info')
    end
end

local function cycleChannelUp()
    if not radioActive then return end
    TriggerServerEvent('radio:cycleChannel', 'up')
end

local function cycleChannelDown()
    if not radioActive then return end
    TriggerServerEvent('radio:cycleChannel', 'down')
end

RegisterNetEvent('radio:client:setChannel', function(channel)
    currentChannel = channel
end)

RegisterNetEvent('radio:client:updateStatus', function(active, channel)
    radioActive = active
    if channel then currentChannel = channel end
end)

CreateThread(function()
    while true do
        Wait(100)
        if radioActive then
            Wrappers.TextUI(Locale('radio.channel') .. ': ' .. currentChannel)
        else
            Wait(500)
        end
    end
end)

RegisterCommand('+radioToggle', toggleRadio, false)
RegisterCommand('+radioCycleUp', cycleChannelUp, false)
RegisterCommand('+radioCycleDown', cycleChannelDown, false)

RegisterKeyMapping('+radioToggle', Locale('radio.toggle'), 'keyboard', Config.Radio.toggleKey)
RegisterKeyMapping('+radioCycleUp', Locale('radio.channel') .. ' +', 'keyboard', Config.Radio.cycleKey)
