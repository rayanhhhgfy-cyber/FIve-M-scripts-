RegisterNetEvent('InteractSound:server:playSound', function(soundName, volume, distance)
    local source = source
    if not source then return end
    local soundConfig = Config.Sounds[soundName]
    if not soundConfig then
        soundConfig = { name = soundName, volume = volume or Config.InteractSound.defaultVolume, distance = distance or Config.InteractSound.maxDistance }
    end
    local coords = GetEntityCoords(GetPlayerPed(source))
    TriggerClientEvent('InteractSound:client:playSound', -1, soundConfig.name or soundName, soundConfig.volume or volume or Config.InteractSound.defaultVolume, soundConfig.distance or distance or Config.InteractSound.maxDistance, coords)
end)

RegisterNetEvent('InteractSound:server:playSoundAtCoords', function(soundName, coords, volume, distance)
    local source = source
    if not source then return end
    local soundConfig = Config.Sounds[soundName]
    TriggerClientEvent('InteractSound:client:playSound', -1, soundConfig.name or soundName, soundConfig.volume or volume or Config.InteractSound.defaultVolume, soundConfig.distance or distance or Config.InteractSound.maxDistance, coords)
end)

RegisterNetEvent('InteractSound:server:playSoundToPlayer', function(target, soundName, volume, distance)
    local soundConfig = Config.Sounds[soundName]
    local coords = GetEntityCoords(GetPlayerPed(target))
    TriggerClientEvent('InteractSound:client:playSound', target, soundConfig.name or soundName, soundConfig.volume or volume or Config.InteractSound.defaultVolume, soundConfig.distance or distance or Config.InteractSound.maxDistance, coords)
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[InteractSound] Sound system initialized. %d sound presets.^7', #Config.Sounds)
end)
