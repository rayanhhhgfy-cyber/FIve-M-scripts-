local isSelecting = false
local saveTimer = 0

RegisterNetEvent('character:receiveCharacters', function(characters)
    SendNUIMessage({
        type = 'showSelector',
        characters = characters,
        spawnLocations = Config.CharacterSystem.spawnLocations,
        spawnMap = Config.CharacterSystem.SpawnMap,
    })
    SetNuiFocus(true, true)
    isSelecting = true
end)

RegisterNetEvent('character:characterCreated', function(charData)
    SendNUIMessage({ type = 'characterCreated', character = charData })
end)

RegisterNetEvent('character:creationFailed', function(err)
    SendNUIMessage({ type = 'creationFailed', error = err })
end)

RegisterNetEvent('character:spawnPlayer', function(citizenid, coords)
    SetNuiFocus(false, false)
    isSelecting = false
    DoScreenFadeOut(500)
    Citizen.Wait(500)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
    SetEntityHeading(ped, coords.heading or 0.0)
    ShutdownLoadingScreen()
    DoScreenFadeIn(500)
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    LocalPlayer.state:set('cid', citizenid, true)
end)

RegisterNetEvent('character:openSelector', function()
    TriggerServerEvent('character:requestCharacters')
end)

RegisterNetEvent('character:saveMyPosition', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    TriggerServerEvent('character:savePosition', { x = coords.x, y = coords.y, z = coords.z, heading = heading })
end)

-- NUI callbacks
RegisterNUICallback('selectCharacter', function(data, cb)
    SetNuiFocus(false, false)
    if data.spawnType == 'custom' and data.customCoords then
        TriggerServerEvent('character:selectCharacter', data.citizenid, 'custom', data.customCoords)
    else
        TriggerServerEvent('character:selectCharacter', data.citizenid, data.spawnType)
    end
    cb({ ok = true })
end)

RegisterNUICallback('getJobSpawns', function(data, cb)
    local jobSpawns = lib.callback.await('character:getJobSpawns', false, data.citizenid)
    cb({ jobSpawns = jobSpawns })
end)

RegisterNUICallback('createCharacter', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('character:createCharacter', data)
    cb({ ok = true })
end)

RegisterNUICallback('cancelSelection', function(data, cb)
    SetNuiFocus(false, false)
    isSelecting = false
    cb({ ok = true })
end)

RegisterNUICallback('requestCharacters', function(data, cb)
    TriggerServerEvent('character:requestCharacters')
    cb({ ok = true })
end)

-- Auto-show on first load (after loading screen)
Citizen.CreateThread(function()
    Citizen.Wait(3000)
    if not isSelecting then
        TriggerServerEvent('character:requestCharacters')
    end
end)

-- Periodic position save
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000)
        if not isSelecting then
            TriggerEvent('character:saveMyPosition')
        end
    end
end)
