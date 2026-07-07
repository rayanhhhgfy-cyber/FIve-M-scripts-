local QBox = exports['qbx-core']:GetCoreObject()
local bunkerRocks = {}
local bunkerOpen = {}
local interiorZones = {}
local activeVehicles = {}
local roofProps = {}
local roofOpen = false
local heliSpawned = nil

local function hasAccess()
    local group = QBox.Functions.GetPlayerData().group
    if not group then return false end
    for _, g in ipairs(Config.SecretBunkers.adminGroups) do
        if group == g then return true end
    end
    return false
end

local function loadInterior(interiorName)
    RequestIpl(interiorName)
end

local function spawnRocks(location)
    for i, rockData in ipairs(location.entrance.rocks) do
        RequestModel(rockData.model)
        while not HasModelLoaded(rockData.model) do Citizen.Wait(10) end
        local obj = CreateObject(rockData.model, rockData.coords.x, rockData.coords.y, rockData.coords.z - 1.0, false, false, false)
        SetEntityHeading(obj, rockData.heading)
        FreezeEntityPosition(obj, true)
        SetEntityCollision(obj, true, false)
        SetEntityDynamic(obj, true)
        SetEntityAlpha(obj, 255, false)
        bunkerRocks[rockData] = obj
    end
end

local function animateRocks(location, open)
    local dist = open and Config.SecretBunkers.rockSlideDistance or 0
    for rockData, obj in pairs(bunkerRocks) do
        if rockData.coords.x == location.entrance.rocks[1].coords.x then
            local targetX = rockData.coords.x + (open and rockData.slideDir.x or 0)
            local targetY = rockData.coords.y + (open and rockData.slideDir.y or 0)
            local targetZ = rockData.coords.z + (open and rockData.slideDir.z or 0)
            FreezeEntityPosition(obj, false)
            MoveObject(obj, targetX - 1.0, targetY, targetZ + 1.0, Config.SecretBunkers.rockSlideDuration, 0.0, 0.0, 0.0)
        end
    end
    if open then
        PlaySoundFromCoord(-1, 'BASE_JUMP_COUNTDOWN', location.entrance.coords.x, location.entrance.coords.y, location.entrance.coords.z, 'HUD_MINI_GAME_SOUNDSET', 0, 0, 0)
        Citizen.Wait(Config.SecretBunkers.rockSlideDuration)
        PlaySoundFromCoord(-1, 'BASE_JUMP_COUNTDOWN', location.entrance.coords.x, location.entrance.coords.y, location.entrance.coords.z, 'HUD_MINI_GAME_SOUNDSET', 0, 0, 0)
    else
        for rockData, obj in pairs(bunkerRocks) do
            if rockData.coords.x == location.entrance.rocks[1].coords.x then
                FreezeEntityPosition(obj, false)
                MoveObject(obj, rockData.coords.x - 1.0, rockData.coords.y, rockData.coords.z + 1.0, Config.SecretBunkers.rockSlideDuration, 0.0, 0.0, 0.0)
            end
        end
        Citizen.Wait(Config.SecretBunkers.rockSlideDuration)
        for rockData, obj in pairs(bunkerRocks) do
            FreezeEntityPosition(obj, true)
        end
    end
end

local function hasJobAccess()
    if hasAccess() then return true end
    local player = QBox.Functions.GetPlayerData()
    if not player or not player.job then return false end
    local jobName = player.job.name
    local grade = player.job.grade
    return (jobName == 'cid' or jobName == 'police' or jobName == 'sheriff' or jobName == 'statepolice') and grade >= 3
end

local function setupBunkerTargets(locId, location)
    local inside = false
    local requiresJobAccess = location.allowedJobs ~= nil
    exports.ox_target:addBoxZone({
        coords = location.entrance.coords,
        size = vector3(3.0, 3.0, 3.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'bunker_toggle_' .. locId,
                icon = 'fas fa-mountain',
                label = bunkerOpen[locId] and 'Close ' .. location.label or 'Open ' .. location.label,
                distance = Config.SecretBunkers.maxDistance,
                canInteract = function()
                    if requiresJobAccess then
                        return hasJobAccess()
                    end
                    return hasAccess()
                end,
                onSelect = function()
                    if not bunkerOpen[locId] then
                        TriggerServerEvent('bunker:open', locId)
                    else
                        TriggerServerEvent('bunker:close', locId)
                    end
                end,
            },
        },
    })
end

local function createInteriorArmory(location, locId)
    local armory = location.armory
    exports.ox_target:addBoxZone({
        coords = vector3(location.interior.coords.x + 2.0, location.interior.coords.y + 1.0, location.interior.coords.z),
        size = vector3(1.5, 1.5, 2.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'bunker_armory_weapons_' .. locId,
                icon = 'fas fa-gun',
                label = 'Weapons Locker',
                distance = 2.0,
                onSelect = function()
                    local items = {}
                    for _, w in ipairs(armory.weapons) do
                        table.insert(items, {
                            title = w.label,
                            description = 'Rank ' .. w.rank .. '+',
                            onSelect = function()
                                TriggerServerEvent('bunker:takeWeapon', locId, w.weapon)
                            end
                        })
                    end
                    Wrappers.ContextMenu({ id = 'bunker_armory_weapons_' .. locId, title = 'Weapons Locker', menuItems = items })
                end,
            },
            {
                name = 'bunker_armory_ammo_' .. locId,
                icon = 'fas fa-bullets',
                label = 'Ammo Crate',
                distance = 2.0,
                onSelect = function()
                    local items = {}
                    for _, a in ipairs(armory.ammo) do
                        table.insert(items, {
                            title = a.label .. ' x' .. a.count,
                            onSelect = function()
                                TriggerServerEvent('bunker:takeAmmo', locId, a.item)
                            end
                        })
                    end
                    Wrappers.ContextMenu({ id = 'bunker_armory_ammo_' .. locId, title = 'Ammo Crate', menuItems = items })
                end,
            },
            {
                name = 'bunker_armory_equip_' .. locId,
                icon = 'fas fa-box',
                label = 'Equipment',
                distance = 2.0,
                onSelect = function()
                    local items = {}
                    for _, e in ipairs(armory.equipment) do
                        table.insert(items, {
                            title = e.label,
                            onSelect = function()
                                TriggerServerEvent('bunker:takeEquipment', locId, e.item)
                            end
                        })
                    end
                    Wrappers.ContextMenu({ id = 'bunker_armory_equip_' .. locId, title = 'Equipment', menuItems = items })
                end,
            },
        },
    })
end

local function createVehicleSpawner(location, locId)
    local spawn = location.interior.vehicleSpawn
    exports.ox_target:addBoxZone({
        coords = spawn.coords,
        size = vector3(2.0, 2.0, 2.5),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'bunker_vehicle_' .. locId,
                icon = 'fas fa-car',
                label = 'Vehicle Terminal',
                distance = 2.0,
                onSelect = function()
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = 'openTerminal',
                        categories = Config.SecretBunkers.vehicleCategories,
                        locationId = locId,
                    })
                end,
            },
        },
    })
end

local function createDroneStation(location, locId)
    local spawn = location.interior.droneSpawn
    exports.ox_target:addBoxZone({
        coords = spawn.coords,
        size = vector3(1.0, 1.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'bunker_drone_' .. locId,
                icon = 'fas fa-drone',
                label = 'Deploy Recon Drone',
                distance = 2.0,
                onSelect = function()
                    Wrappers.ProgressBar({
                        duration = 3000,
                        label = 'Deploying drone...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, car = true, combat = true },
                        anim = { dict = 'anim@heists@narcotics@trash', clip = 'walk' },
                    }, function(cancelled)
                        if not cancelled then
                            TriggerServerEvent('bunker:spawnDrone', locId)
                        end
                    end)
                end,
            },
        },
    })
end

local function createGarageDoor(location, locId)
    local exit = location.interior.exit
    exports.ox_target:addBoxZone({
        coords = exit.coords,
        size = vector3(2.0, 2.0, 2.5),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'bunker_exit_' .. locId,
                icon = 'fas fa-door-open',
                label = 'Exit Bunker',
                distance = 2.5,
                onSelect = function()
                    DoScreenFadeOut(300)
                    while not IsScreenFadedOut() do Citizen.Wait(10) end
                    SetEntityCoords(PlayerPedId(), location.entrance.coords.x, location.entrance.coords.y, location.entrance.coords.z + 1.0)
                    SetEntityHeading(PlayerPedId(), location.entrance.heading)
                    Citizen.Wait(300)
                    DoScreenFadeIn(300)
                    Wrappers.Notify('Exited ' .. location.label, 'success')
                end,
            },
        },
    })
end

local function spawnRoofProps(location)
    if not location.interior.roofProps then return end
    for i, propData in ipairs(location.interior.roofProps) do
        RequestModel(propData.model)
        while not HasModelLoaded(propData.model) do Citizen.Wait(10) end
        local obj = CreateObject(propData.model, propData.coords.x, propData.coords.y, propData.coords.z, false, false, false)
        SetEntityHeading(obj, propData.heading)
        FreezeEntityPosition(obj, true)
        SetEntityCollision(obj, true, false)
        SetEntityDynamic(obj, true)
        SetEntityAlpha(obj, 255, false)
        roofProps[#roofProps + 1] = { obj = obj, data = propData }
    end
end

local function animateRoof(open)
    if #roofProps == 0 then return end
    local dist = open and 6.0 or -6.0
    for _, prop in ipairs(roofProps) do
        FreezeEntityPosition(prop.obj, false)
        local targetZ = open
            and (prop.data.coords.z + prop.data.slideDir.z)
            or prop.data.coords.z
        MoveObject(prop.obj, prop.data.coords.x, prop.data.coords.y, targetZ, 2500, 0.0, 0.0, 0.0)
    end
    if open then
        PlaySoundFromCoord(-1, 'BASE_JUMP_COUNTDOWN', 1000.0, -3004.0, -36.0, 'HUD_MINI_GAME_SOUNDSET', 0, 0, 0)
    else
        PlaySoundFromCoord(-1, 'BASE_JUMP_COUNTDOWN', 1000.0, -3004.0, -36.0, 'HUD_MINI_GAME_SOUNDSET', 0, 0, 0)
    end
    roofOpen = open
end

local function createHelipad(location, locId)
    if not location.interior.heliSpawn then return end
    local spawn = location.interior.heliSpawn
    exports.ox_target:addBoxZone({
        coords = spawn.coords,
        size = vector3(3.0, 3.0, 2.5),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'bunker_heli_' .. locId,
                icon = 'fas fa-helicopter',
                label = 'Spawn Helicopter',
                distance = 3.0,
                onSelect = function()
                    local heliModels = {
                        { model = 'buzzard2', label = 'Armed Buzzard' },
                        { model = 'hunter', label = 'Hunter Attack' },
                        { model = 'akula', label = 'Akula Stealth' },
                        { model = 'savage', label = 'Savage Attack' },
                    }
                    local options = {}
                    for _, h in ipairs(heliModels) do
                        table.insert(options, {
                            title = h.label,
                            icon = 'fas fa-helicopter',
                            onSelect = function()
                                TriggerServerEvent('bunker:spawnHeli', locId, h.model)
                            end,
                        })
                    end
                    Wrappers.ContextMenu({ id = 'bunker_heli_menu_' .. locId, title = 'Select Aircraft', menuItems = options })
                end,
            },
        },
    })
end

local function setupInteriorTargets(locId, location)
    createInteriorArmory(location, locId)
    createVehicleSpawner(location, locId)
    createDroneStation(location, locId)
    createGarageDoor(location, locId)
    createHelipad(location, locId)
    interiorZones[locId] = true
end

RegisterNUICallback('spawnVehicle', function(data, cb)
    local model = data.model
    local _category = data.category
    if not model then cb({}) return end
    SetNuiFocus(false, false)
    TriggerServerEvent('bunker:spawnVehicle', model)
    cb({})
end)

RegisterNUICallback('closeTerminal', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNetEvent('bunker:rockOpen', function(locId)
    local location = Config.SecretBunkers.locations[locId]
    if not location then return end
    bunkerOpen[locId] = true
    animateRocks(location, true)
    Wrappers.Notify('Bunker entrance revealed', 'success')
end)

RegisterNetEvent('bunker:rockClose', function(locId)
    local location = Config.SecretBunkers.locations[locId]
    if not location then return end
    bunkerOpen[locId] = false
    animateRocks(location, false)
    Wrappers.Notify('Bunker entrance sealed', 'info')
end)

RegisterNetEvent('bunker:teleportToInterior', function(locId)
    local location = Config.SecretBunkers.locations[locId]
    if not location then return end
    loadInterior(location.interiorName)
    Citizen.Wait(500)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Citizen.Wait(10) end
    SetEntityCoords(PlayerPedId(), location.interior.coords.x, location.interior.coords.y, location.interior.coords.z)
    SetEntityHeading(PlayerPedId(), location.interior.heading)
    Citizen.Wait(500)
    DoScreenFadeIn(500)
    if not interiorZones[locId] then
        setupInteriorTargets(locId, location)
        if location.interior.roofProps then
            spawnRoofProps(location)
        end
    end
end)

RegisterNetEvent('bunker:spawnDroneClient', function(netId)
    local drone = NetToVeh(netId)
    if not drone or drone == 0 then
        local pCoords = GetEntityCoords(PlayerPedId())
        drone = CreateVehicle('akula', pCoords.x + 3.0, pCoords.y, pCoords.z + 2.0, 0.0, true, false)
    end
    TaskWarpPedIntoVehicle(PlayerPedId(), drone, -1)
    Wrappers.Notify('Drone deployed. Use arrow keys to fly.', 'success')
end)

RegisterNetEvent('bunker:roofOpenHelipad', function(locId)
    local location = Config.SecretBunkers.locations[locId]
    if not location or not location.interior.roofProps then return end
    if #roofProps == 0 then
        spawnRoofProps(location)
    end
    animateRoof(true)
end)

RegisterNetEvent('bunker:roofCloseHelipad', function(locId)
    animateRoof(false)
    heliSpawned = nil
end)

RegisterNetEvent('bunker:vehicleSpawned', function(netId)
    local veh = NetToVeh(netId)
    if veh and veh ~= 0 then
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        heliSpawned = veh
        Wrappers.Notify('Helicopter deployed — roof opening', 'success')

        -- Track helicopter: close roof when it leaves the hangar
        Citizen.CreateThread(function()
            local startTime = GetGameTimer()
            while heliSpawned and DoesEntityExist(heliSpawned) do
                Citizen.Wait(2000)
                local coords = GetEntityCoords(heliSpawned)
                local hangarCoords = vector3(1000.0, -3000.0, -40.0)
                local dist = #(coords - hangarCoords)
                if dist > 30.0 or GetGameTimer() - startTime > 120000 then
                    TriggerServerEvent('bunker:roofCloseHelipad', 'cid_bunker')
                    break
                end
            end
        end)
    end
end)

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end
    for locId, location in pairs(Config.SecretBunkers.locations) do
        spawnRocks(location)
        setupBunkerTargets(locId, location)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if GetCurrentResourceName() ~= r then return end
    for _, obj in pairs(bunkerRocks) do
        if DoesEntityExist(obj) then DeleteObject(obj) end
    end
    for _, prop in ipairs(roofProps) do
        if DoesEntityExist(prop.obj) then DeleteObject(prop.obj) end
    end
end)
