local activeSounds = {}

RegisterNetEvent('InteractSound:client:playSound', function(soundName, volume, distance, coords)
    local soundId = GetSoundId()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local dist = #(playerCoords - coords)
    if dist > distance then return end
    local adjustedVolume = volume * (1 - (dist / distance))
    PlaySound(soundId, soundName, 'interact_sounds', false, adjustedVolume, false)
    table.insert(activeSounds, { id = soundId, name = soundName, startTime = GetGameTimer(), duration = 3000 })
    if #activeSounds > 20 then
        local old = table.remove(activeSounds, 1)
        StopSound(old.id)
        ReleaseSoundId(old.id)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        local now = GetGameTimer()
        local i = 1
        while i <= #activeSounds do
            if now - activeSounds[i].startTime > activeSounds[i].duration then
                StopSound(activeSounds[i].id)
                ReleaseSoundId(activeSounds[i].id)
                table.remove(activeSounds, i)
            else
                i = i + 1
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[InteractSound] Client sound player ready.^7')
end)
