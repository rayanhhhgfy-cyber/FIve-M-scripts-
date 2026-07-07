local currentWeather = 'EXTRASUNNY'
local currentTime = { hour = 12, minute = 0 }
local blackoutActive = false
local blackoutEndTime = 0
local weatherChangeTimer = nil
local weatherHistory = {}

local function GetWeightedRandomWeather()
    local totalWeight = 0
    for weather, weight in pairs(Config.WeatherWeights) do
        totalWeight = totalWeight + weight
    end
    local roll = math.random() * totalWeight
    local cumulative = 0
    for weather, weight in pairs(Config.WeatherWeights) do
        cumulative = cumulative + weight
        if roll <= cumulative then
            return weather
        end
    end
    return 'EXTRASUNNY'
end

function SetWeather(weatherType, force)
    if not force then
        local current = Config.Weather.forcedWeatherType
        if Config.Weather.forceWeather then
            weatherType = current
        end
    end
    currentWeather = weatherType
    table.insert(weatherHistory, { weather = weatherType, time = os.time() })
    if #weatherHistory > 100 then
        table.remove(weatherHistory, 1)
    end
    TriggerClientEvent('weathersync:client:setWeather', -1, weatherType)
end

function SetTime(hour, minute)
    currentTime.hour = hour
    currentTime.minute = minute
    TriggerClientEvent('weathersync:client:setTime', -1, hour, minute)
end

local function ProgressTime()
    if Config.Time.freezeTime then return end
    local minutesPerInterval = Config.Time.syncInterval / 60000 * Config.Time.timeScaleMultiplier * 6
    currentTime.minute = currentTime.minute + minutesPerInterval
    while currentTime.minute >= 60 do
        currentTime.minute = currentTime.minute - 60
        currentTime.hour = currentTime.hour + 1
        if currentTime.hour >= 24 then
            currentTime.hour = 0
        end
    end
    TriggerClientEvent('weathersync:client:setTime', -1, currentTime.hour, currentTime.minute)
end

local function TryStartBlackout()
    if not Config.Blackout.enabled or blackoutActive then return end
    if Config.Blackout.triggerOnAdminCommand then return end
    if math.random() < Config.Weather.blackoutChance then
        local duration = math.random(Config.Blackout.minDuration, Config.Blackout.maxDuration)
        blackoutActive = true
        blackoutEndTime = GetGameTimer() + duration
        TriggerClientEvent('weathersync:client:setBlackout', -1, true)
        TriggerClientEvent('ox_lib:notify', -1, { type = 'warning', description = Locales['blackout_active'], duration = 8000 })
        SetTimeout(duration, function()
            blackoutActive = false
            TriggerClientEvent('weathersync:client:setBlackout', -1, false)
            TriggerClientEvent('ox_lib:notify', -1, { type = 'success', description = Locales['blackout_ended'], duration = 5000 })
        end)
    end
end

RegisterNetEvent('weathersync:server:setWeather', function(weatherType, force)
    local source = source
    if not IsPlayerAceAllowed(source, Config.Weather.adminAce) then return end
    local valid = false
    for _, wt in ipairs(Config.WeatherTypes) do
        if wt == weatherType then
            valid = true
            break
        end
    end
    if not valid then return end
    SetWeather(weatherType, force or false)
    TriggerClientEvent('ox_lib:notify', -1, { type = 'info', description = string.format(Locales['weather_changed'], weatherType) })
end)

RegisterNetEvent('weathersync:server:setTime', function(hour, minute)
    local source = source
    if not IsPlayerAceAllowed(source, Config.Weather.adminAce) then return end
    hour = tonumber(hour) or 12
    minute = tonumber(minute) or 0
    hour = math.max(0, math.min(23, hour))
    minute = math.max(0, math.min(59, minute))
    SetTime(hour, minute)
    TriggerClientEvent('ox_lib:notify', -1, { type = 'info', description = string.format(Locales['time_changed'], string.format('%02d:%02d', hour, minute)) })
end)

RegisterNetEvent('weathersync:server:toggleBlackout', function()
    local source = source
    if not IsPlayerAceAllowed(source, Config.Weather.adminAce) then return end
    if blackoutActive then
        blackoutActive = false
        TriggerClientEvent('weathersync:client:setBlackout', -1, false)
        TriggerClientEvent('ox_lib:notify', -1, { type = 'success', description = Locales['blackout_ended'] })
    else
        blackoutActive = true
        local duration = math.random(Config.Blackout.minDuration, Config.Blackout.maxDuration)
        blackoutEndTime = GetGameTimer() + duration
        TriggerClientEvent('weathersync:client:setBlackout', -1, true)
        TriggerClientEvent('ox_lib:notify', -1, { type = 'warning', description = Locales['blackout_active'] })
        SetTimeout(duration, function()
            blackoutActive = false
            TriggerClientEvent('weathersync:client:setBlackout', -1, false)
            TriggerClientEvent('ox_lib:notify', -1, { type = 'success', description = Locales['blackout_ended'] })
        end)
    end
end)

lib.callback.register('weathersync:server:getWeather', function(source)
    return currentWeather
end)

lib.callback.register('weathersync:server:getTime', function(source)
    return currentTime
end)

lib.callback.register('weathersync:server:isBlackoutActive', function(source)
    return blackoutActive
end)

RegisterCommand('weather', function(source, args)
    if source == 0 then return end
    if not IsPlayerAceAllowed(source, Config.Weather.adminAce) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Locales['no_permission'] })
        return
    end
    if not args[1] then
        TriggerClientEvent('ox_lib:notify', source, { type = 'info', description = 'Current weather: ' .. currentWeather })
        return
    end
    local weatherArg = string.upper(args[1])
    TriggerEvent('weathersync:server:setWeather', weatherArg, true)
end, true)

RegisterCommand('time', function(source, args)
    if source == 0 then return end
    if not IsPlayerAceAllowed(source, Config.Weather.adminAce) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Locales['no_permission'] })
        return
    end
    if not args[1] then
        TriggerClientEvent('ox_lib:notify', source, { type = 'info', description = string.format('Current time: %02d:%02d', currentTime.hour, currentTime.minute) })
        return
    end
    local hour = tonumber(args[1]) or 12
    local minute = tonumber(args[2]) or 0
    TriggerEvent('weathersync:server:setTime', hour, minute)
end, true)

RegisterCommand('blackout', function(source)
    if source == 0 then return end
    if not IsPlayerAceAllowed(source, Config.Weather.adminAce) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Locales['no_permission'] })
        return
    end
    TriggerEvent('weathersync:server:toggleBlackout')
end, true)

AddEventHandler('playerConnecting', function()
    local source = source
    if not source then return end
    SetTimeout(3000, function()
        TriggerClientEvent('weathersync:client:setWeather', source, currentWeather)
        TriggerClientEvent('weathersync:client:setTime', source, currentTime.hour, currentTime.minute)
        TriggerClientEvent('weathersync:client:setBlackout', source, blackoutActive)
    end)
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[weathersync] Weather authority initialized.^7')
    if not Config.Weather.enabled then return end
    SetWeather('EXTRASUNNY', true)
    SetTime(12, 0)
    if Config.Weather.dynamicWeather then
        SetTimeout(Config.Weather.weatherChangeTime, function()
            Citizen.CreateThread(function()
                while true do
                    Citizen.Wait(Config.Weather.weatherChangeTime)
                    local newWeather = GetWeightedRandomWeather()
                    SetWeather(newWeather, false)
                    TryStartBlackout()
                end
            end)
        end)
    end
    if Config.Time.enabled then
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(Config.Time.syncInterval)
                ProgressTime()
            end
        end)
    end
end)

exports('GetCurrentWeather', function() return currentWeather end)
exports('GetCurrentTime', function() return currentTime end)
exports('IsBlackoutActive', function() return blackoutActive end)
exports('SetWeather', SetWeather)
exports('SetTime', SetTime)
exports('GetWeatherHistory', function() return weatherHistory end)
