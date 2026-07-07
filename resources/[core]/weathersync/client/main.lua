local currentWeather = 'EXTRASUNNY'
local currentTime = { hour = 12, minute = 0 }
local blackoutActive = false

RegisterNetEvent('weathersync:client:setWeather', function(weatherType)
    currentWeather = weatherType
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypeNowPersist(weatherType)
    SetWeatherTypePersist(weatherType)
    SetWeatherTypeNow(weatherType)
    if weatherType == 'XMAS' or weatherType == 'SNOW' or weatherType == 'BLIZZARD' or weatherType == 'SNOWLIGHT' then
        SetForceVehicleTrails(true)
        SetForcePedFootstepsTracks(true)
    else
        SetForceVehicleTrails(false)
        SetForcePedFootstepsTracks(false)
    end
end)

RegisterNetEvent('weathersync:client:setTime', function(hour, minute)
    currentTime.hour = hour
    currentTime.minute = minute
    NetworkOverrideClockTime(hour, minute, 0)
end)

RegisterNetEvent('weathersync:client:setBlackout', function(state)
    blackoutActive = state
    if state then
        SetArtificialLightsState(true)
        SetArtificialLightsStateAffectsVehicles(true)
    else
        SetArtificialLightsState(false)
        SetArtificialLightsStateAffectsVehicles(false)
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    NetworkOverrideClockTime(currentTime.hour, currentTime.minute, 0)
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if Config.Weather.forceWeather then
        TriggerServerEvent('weathersync:client:setWeather', Config.Weather.forcedWeatherType)
    end
    if Config.Time.freezeTime then
        NetworkOverrideClockTime(Config.Time.frozenHour, Config.Time.frozenMinute, 0)
    end
    print('^2[weathersync] Client weather synced.^7')
end)

exports('GetWeather', function() return currentWeather end)
exports('GetTime', function() return currentTime end)
exports('IsBlackoutActive', function() return blackoutActive end)
