local QBCore = exports['qbx_core']:GetCoreObject()
local spawnMenuOpen = false
local selectedLocation = Config.Locations[1]

local function PlayCinematicFlyover(location)
    if not Config.Camera.enableFlyover then return end
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local startCoords = GetEntityCoords(PlayerPedId())
    local endCoords = vector3(location.coords.x, location.coords.y, location.coords.z + Config.Camera.flyoverHeight)
    SetCamCoord(cam, startCoords.x, startCoords.y, startCoords.z + 20.0)
    SetCamRot(cam, -90.0, 0.0, 0.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)
    local startTime = GetGameTimer()
    Citizen.CreateThread(function()
        while GetGameTimer() - startTime < Config.Camera.flyoverDuration do
            local progress = (GetGameTimer() - startTime) / Config.Camera.flyoverDuration
            local current = startCoords + (endCoords - startCoords) * progress
            SetCamCoord(cam, current.x, current.y, current.z)
            Citizen.Wait(10)
        end
        RenderScriptCams(false, true, 1000, true, true)
        DestroyCam(cam, false)
    end)
end

function OpenSpawnMenu()
    if spawnMenuOpen then return end
    spawnMenuOpen = true
    local locations = lib.callback.await('qbox-spawn:server:getSpawnLocations', false)
    local options = {}
    for _, loc in ipairs(locations or Config.Locations) do
        table.insert(options, {
            title = loc.name,
            description = loc.description,
            icon = 'fas fa-map-marker-alt',
            onSelect = function()
                selectedLocation = loc
                TriggerServerEvent('qbox-spawn:server:spawnPlayer', loc.coords)
                spawnMenuOpen = false
            end
        })
    end
    lib.registerContext({
        id = 'spawn_menu',
        title = 'Select Spawn Location',
        options = options
    })
    lib.showContext('spawn_menu')
end

RegisterNetEvent('qbox-spawn:client:openSpawnMenu', function()
    Citizen.Wait(3000)
    if Config.Spawn.enableCinematic then
        DoScreenFadeOut(500)
        Citizen.Wait(1000)
        SetEntityCoords(PlayerPedId(), Config.Spawn.defaultSpawn.x, Config.Spawn.defaultSpawn.y, Config.Spawn.defaultSpawn.z)
        Citizen.Wait(500)
        DoScreenFadeIn(500)
    end
    OpenSpawnMenu()
end)

RegisterNetEvent('qbox-spawn:client:doSpawn', function(location)
    DoScreenFadeOut(500)
    Citizen.Wait(1000)
    SetEntityCoords(PlayerPedId(), location.x, location.y, location.z)
    SetEntityHeading(PlayerPedId(), location.h or 0.0)
    DoScreenFadeIn(1000)
    TriggerServerEvent('welcome-system:server:playerSpawned')
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[qbox-spawn] Client spawn handler ready.^7')
end)

exports('OpenSpawnMenu', OpenSpawnMenu)
