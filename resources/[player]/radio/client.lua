local QBox = exports['qbx_core']:GetCoreObject()
local PlayerData = QBox.Functions.GetPlayerData()
local radioMenu = false
local onRadio = false
local RadioChannel = 0
local RadioVolume = 50
local hasRadio = false
local radioProp = nil

local function LoadAnimDic(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(0) end
    end
end

local function connecttoradio(channel)
    if channel > Config.MaxFrequency or channel <= 0 then exports.ox_lib:notify({ type = 'error', description = 'Invalid or restricted channel' }) return false end
    if Config.RestrictedChannels[channel] ~= nil then
        if not Config.RestrictedChannels[channel][PlayerData.job.name] or not PlayerData.job.onduty then
            exports.ox_lib:notify({ type = 'error', description = 'Restricted channel' })
            return false
        end
    end
    RadioChannel = channel
    if onRadio then
        exports["pma-voice"]:setRadioChannel(0)
    else
        onRadio = true
        exports["pma-voice"]:setVoiceProperty("radioEnabled", true)
    end
    exports["pma-voice"]:setRadioChannel(channel)
    local freq = channel % 1 == 0 and ('%.0f'):format(channel) .. '.00 MHz' or channel .. ' MHz'
    exports.ox_lib:notify({ type = 'success', description = 'Joined channel ' .. freq })
    return true
end

local function leaveradio()
    RadioChannel = 0
    onRadio = false
    exports["pma-voice"]:setRadioChannel(0)
    exports["pma-voice"]:setVoiceProperty("radioEnabled", false)
    exports.ox_lib:notify({ type = 'info', description = 'Left radio' })
end

local function toggleRadioAnimation(pState)
    LoadAnimDic("cellphone@")
    if pState then
        TriggerEvent("attachItemRadio","radio01")
        TaskPlayAnim(PlayerPedId(), "cellphone@", "cellphone_text_read_base", 2.0, 3.0, -1, 49, 0, false, false, false)
        radioProp = CreateObject(`prop_cs_hand_radio`, 1.0, 1.0, 1.0, true, true, false)
        AttachEntityToEntity(radioProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.14, 0.01, -0.02, 110.0, 120.0, -15.0, true, false, false, false, 2, true)
    else
        StopAnimTask(PlayerPedId(), "cellphone@", "cellphone_text_read_base", 1.0)
        ClearPedTasks(PlayerPedId())
        if radioProp ~= 0 then
            DeleteObject(radioProp)
            radioProp = 0
        end
    end
end

local function toggleRadio(toggle)
    radioMenu = toggle
    SetNuiFocus(radioMenu, radioMenu)
    if radioMenu then
        toggleRadioAnimation(true)
        SendNUIMessage({type = "open"})
    else
        toggleRadioAnimation(false)
        SendNUIMessage({type = "close"})
    end
end

local function IsRadioOn()
    return onRadio
end

local function DoRadioCheck()
    hasRadio = QBox.Functions.HasItem(Config.RadioItem, 1)
end

exports("IsRadioOn", IsRadioOn)
exports('connecttoradio', connecttoradio)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBox.Functions.GetPlayerData()
    DoRadioCheck()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    DoRadioCheck()
    PlayerData = {}
    leaveradio()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
    DoRadioCheck()
end)

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        PlayerData = QBox.Functions.GetPlayerData()
        DoRadioCheck()
    end
end)

RegisterNetEvent('qb-radio:use', function()
    toggleRadio(not radioMenu)
end)

RegisterNetEvent('qb-radio:connectToChannel', function(channel)
    channel = tonumber(channel)
    if channel and channel > 0 and channel <= Config.MaxFrequency then
        connecttoradio(channel)
    else
        exports.ox_lib:notify({ type = 'error', description = 'Invalid channel' })
    end
end)

RegisterNetEvent('qb-radio:onRadioDrop', function()
    if RadioChannel ~= 0 then leaveradio() end
end)

RegisterNUICallback('joinRadio', function(data, cb)
    local rchannel = math.floor(tonumber(data.channel) * 100 + 0.5) / 100
    if rchannel ~= nil then
        if rchannel <= Config.MaxFrequency and rchannel > 0 then
            if rchannel ~= RadioChannel then
                local canaccess = connecttoradio(rchannel)
                cb({ canaccess = canaccess, channel = RadioChannel })
                return
            else
                exports.ox_lib:notify({ type = 'error', description = 'Already on that channel' })
            end
        else
            exports.ox_lib:notify({ type = 'error', description = 'Invalid channel' })
        end
    else
        exports.ox_lib:notify({ type = 'error', description = 'Invalid channel' })
    end
    cb({ canaccess = false, channel = RadioChannel })
end)

RegisterNUICallback('leaveRadio', function(_, cb)
    if RadioChannel == 0 then
        exports.ox_lib:notify({ type = 'error', description = 'Not on a channel' })
    else
        leaveradio()
    end
    cb("ok")
end)

RegisterNUICallback("volumeUp", function(_, cb)
    if RadioVolume <= 95 then
        RadioVolume = RadioVolume + 5
        exports.ox_lib:notify({ type = 'success', description = 'Volume: ' .. RadioVolume .. '%' })
        exports["pma-voice"]:setRadioVolume(RadioVolume)
    else
        exports.ox_lib:notify({ type = 'error', description = 'Max volume reached' })
    end
    cb('ok')
end)

RegisterNUICallback("volumeDown", function(_, cb)
    if RadioVolume >= 10 then
        RadioVolume = RadioVolume - 5
        exports.ox_lib:notify({ type = 'success', description = 'Volume: ' .. RadioVolume .. '%' })
        exports["pma-voice"]:setRadioVolume(RadioVolume)
    else
        exports.ox_lib:notify({ type = 'error', description = 'Min volume reached' })
    end
    cb('ok')
end)

RegisterNUICallback("increaseradiochannel", function(_, cb)
    if not onRadio then return end
    local newChannel = math.floor(tonumber(RadioChannel + 1) * 100 + 0.5) / 100
    local canaccess = connecttoradio(newChannel)
    cb({ canaccess = canaccess, channel = newChannel })
end)

RegisterNUICallback("decreaseradiochannel", function(_, cb)
    if not onRadio then return end
    local newChannel = math.floor(tonumber(RadioChannel - 1) * 100 + 0.5) / 100
    local canaccess = connecttoradio(newChannel)
    cb({ canaccess = canaccess, channel = newChannel })
end)

RegisterNUICallback('poweredOff', function(_, cb)
    leaveradio()
    cb("ok")
end)

RegisterNUICallback('escape', function(_, cb)
    toggleRadio(false)
    cb("ok")
end)

local function canUseChannelWithoutItem(channel)
    local job = PlayerData.job
    if not job or not job.onduty then return false end
    local allowedJobs = Config.RestrictedChannels[channel]
    return allowedJobs and allowedJobs[job.name]
end

CreateThread(function()
    while true do
        Wait(1000)
        if LocalPlayer.state.isLoggedIn and onRadio then
            local hasAccess = hasRadio or canUseChannelWithoutItem(RadioChannel)
            if not hasAccess or PlayerData.metadata.isdead or PlayerData.metadata.inlaststand then
                if RadioChannel ~= 0 then leaveradio() end
            end
        end
    end
end)