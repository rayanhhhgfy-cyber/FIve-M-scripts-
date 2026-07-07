local playerRadio = {}
local playerVoiceRange = {}
local playerMegaphone = {}

local function SetPlayerRadio(source, frequency)
    if frequency then
        playerRadio[source] = frequency
        exports['pma-voice']:setPlayerRadio(source, true, frequency)
        TriggerClientEvent('pma-voice-cfg:client:radioJoined', source, frequency)
    else
        playerRadio[source] = nil
        exports['pma-voice']:setPlayerRadio(source, false)
        TriggerClientEvent('pma-voice-cfg:client:radioLeft', source)
    end
end

local function ValidateRadioAccess(source, frequency)
    local player = exports['qbx_core']:GetPlayer(source)
    if not player then return false end
    local jobName = player.PlayerData.job.name
    local jobType = player.PlayerData.job.type
    for jobTypeKey, jobConfig in pairs(Config.Radio.allowedJobs) do
        if jobName == jobTypeKey or jobType == jobTypeKey then
            for _, freq in ipairs(jobConfig.frequencies) do
                if freq == frequency then
                    return true
                end
            end
        end
    end
    local lowestFreq = 10
    local highestFreq = 20
    if frequency >= lowestFreq and frequency <= highestFreq then
        return true
    end
    return false
end

lib.callback.register('pma-voice-cfg:server:joinRadio', function(source, frequency)
    if not Config.Radio.enableRadio then
        return false, 'Radio is disabled'
    end
    frequency = tonumber(frequency)
    if not frequency then return false, 'Invalid frequency' end
    if frequency < Config.Radio.frequencyRangeMin or frequency > Config.Radio.frequencyRangeMax then
        return false, 'Frequency out of range'
    end
    if Config.Radio.requireRadioItem then
        local hasRadio = exports['ox_inventory']:Search(source, 'count', Config.Radio.radioItem)
        if not hasRadio or hasRadio < 1 then
            return false, 'You need a radio'
        end
    end
    if not ValidateRadioAccess(source, frequency) then
        return false, 'Access denied for this frequency'
    end
    SetPlayerRadio(source, frequency)
    return true, string.format('Joined frequency %d', frequency)
end)

lib.callback.register('pma-voice-cfg:server:leaveRadio', function(source)
    if not playerRadio[source] then return false, 'Not on a radio' end
    SetPlayerRadio(source, nil)
    return true, 'Left radio'
end)

lib.callback.register('pma-voice-cfg:server:setVoiceRange', function(source, range)
    range = tonumber(range)
    if not range then return false end
    local valid = false
    for _, mode in ipairs(Config.Voice.voiceModes) do
        if mode.range == range then
            valid = true
            break
        end
    end
    if not valid then return false end
    playerVoiceRange[source] = range
    exports['pma-voice']:setVoiceProperty(source, 'radioRange', range)
    return true
end)

lib.callback.register('pma-voice-cfg:server:toggleMegaphone', function(source)
    if not Config.Megaphone.enableInVehicle then
        local ped = GetPlayerPed(source)
        if IsPedInAnyVehicle(ped, false) then return false end
    end
    if Config.Megaphone.requirePoliceVehicle then
        local ped = GetPlayerPed(source)
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle and vehicle > 0 then
            local class = GetVehicleClass(vehicle)
            local isPolice = false
            for _, c in ipairs(Config.Megaphone.policeVehicleClasses) do
                if class == c then isPolice = true end
            end
            if not isPolice then
                playerMegaphone[source] = not playerMegaphone[source]
                exports['pma-voice']:setVoiceProperty(source, 'megaphone', playerMegaphone[source])
                return playerMegaphone[source]
            end
        end
    else
        playerMegaphone[source] = not playerMegaphone[source]
        exports['pma-voice']:setVoiceProperty(source, 'megaphone', playerMegaphone[source])
        return playerMegaphone[source]
    end
    return false
end)

RegisterCommand('radio', function(source, args)
    if not source or source == 0 then return end
    if not args[1] then
        TriggerClientEvent('ox_lib:notify', source, { type = 'info', description = 'Usage: /radio [frequency] or /radio leave' })
        return
    end
    if args[1] == 'leave' then
        lib.callback.await('pma-voice-cfg:server:leaveRadio', source)
        return
    end
    local freq = tonumber(args[1])
    if not freq then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Invalid frequency' })
        return
    end
    local success, msg = lib.callback.await('pma-voice-cfg:server:joinRadio', source, freq)
    TriggerClientEvent('ox_lib:notify', source, { type = success and 'success' or 'error', description = msg })
end, false)

RegisterCommand(Config.Megaphone.toggleCommand, function(source)
    if not source or source == 0 then return end
    local state = lib.callback.await('pma-voice-cfg:server:toggleMegaphone', source)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'info',
        description = state and 'Megaphone ON' or 'Megaphone OFF'
    })
end, false)

RegisterNetEvent('pma-voice-cfg:server:voiceRangeChanged', function(range)
    local source = source
    if not source then return end
    lib.callback.await('pma-voice-cfg:server:setVoiceRange', source, range)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    if playerRadio[source] then
        SetPlayerRadio(source, nil)
    end
    playerRadio[source] = nil
    playerVoiceRange[source] = nil
    playerMegaphone[source] = nil
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[pma-voice-cfg] Voice system configured. Grid-based 3D audio active.^7')
end)

exports('GetPlayerRadio', function(source) return playerRadio[source] end)
exports('IsPlayerOnRadio', function(source) return playerRadio[source] ~= nil end)
exports('GetPlayerVoiceRange', function(source) return playerVoiceRange[source] or Config.Voice.defaultRange end)
