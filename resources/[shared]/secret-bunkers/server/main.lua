local QBox = exports['qbx_core']:GetCoreObject()
local RATE_LIMITS = {}
local bunkerStates = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.SecretBunkers.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

local function hasBunkerAccess(src, locId)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    if isAdmin(src) then return true end

    local location = Config.SecretBunkers.locations[locId]
    if not location then return false end
    if not location.allowedJobs then return false end

    local jobName = player.PlayerData.job.name
    local grade = player.PlayerData.job.grade

    local jobMatch = false
    for _, j in ipairs(location.allowedJobs) do
        if jobName == j then jobMatch = true break end
    end
    if not jobMatch then return false end
    if grade < (location.minRank or 0) then return false end

    return true
end

RegisterNetEvent('bunker:open', function(locId)
    local src = source
    if not checkRateLimit(src, 'bunkerOpen', 5) then return end
    if not hasBunkerAccess(src, locId) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
        return
    end
    local location = Config.SecretBunkers.locations[locId]
    if not location then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    if #(coords - location.entrance.coords) > Config.SecretBunkers.maxDistance then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Too far' })
        return
    end
    bunkerStates[locId] = true
    TriggerClientEvent('bunker:rockOpen', -1, locId)
end)

RegisterNetEvent('bunker:close', function(locId)
    local src = source
    if not checkRateLimit(src, 'bunkerClose', 5) then return end
    if not hasBunkerAccess(src, locId) then return end
    local location = Config.SecretBunkers.locations[locId]
    if not location then return end
    bunkerStates[locId] = false
    TriggerClientEvent('bunker:rockClose', -1, locId)
end)

RegisterNetEvent('bunker:spawnVehicle', function(model)
    local src = source
    if not checkRateLimit(src, 'spawnVeh', 3) then return end
    if not isAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
        return
    end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local veh = CreateVehicle(model, coords.x + 3.0, coords.y, coords.z, GetEntityHeading(ped), true, false)
    if veh == 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Failed to spawn vehicle' })
        return
    end
    SetVehicleNumberPlateText(veh, 'BUNKER' .. math.random(100, 999))
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleNeedsToBeHotwired(veh, false)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerClientEvent('bunker:vehicleSpawned', src, netId)
end)

RegisterNetEvent('bunker:spawnHeli', function(locId, model)
    local src = source
    if not checkRateLimit(src, 'spawnHeli', 2) then return end
    if not hasBunkerAccess(src, locId) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
        return
    end
    local location = Config.SecretBunkers.locations[locId]
    if not location or not location.interior.heliSpawn then return end

    local heliModel = model or 'buzzard2'
    local spawn = location.interior.heliSpawn

    -- Open roof globally
    TriggerClientEvent('bunker:roofOpenHelipad', -1, locId)

    -- Small delay for roof animation
    Citizen.Wait(3000)

    -- Spawn helicopter
    local heli = CreateVehicle(heliModel, spawn.coords.x, spawn.coords.y, spawn.coords.z, spawn.heading, true, false)
    if heli == 0 then return end
    SetVehicleNumberPlateText(heli, 'CID' .. math.random(100, 999))
    SetVehicleEngineOn(heli, true, true, false)
    SetVehicleNeedsToBeHotwired(heli, false)
    SetHeliBladesSpeed(heli, 1.0)
    local netId = NetworkGetNetworkIdFromEntity(heli)
    TriggerClientEvent('bunker:vehicleSpawned', src, netId)
end)

RegisterNetEvent('bunker:roofCloseHelipad', function(locId)
    TriggerClientEvent('bunker:roofCloseHelipad', -1, locId)
end)

RegisterNetEvent('bunker:spawnDrone', function(locId)
    local src = source
    if not checkRateLimit(src, 'spawnDrone', 2) then return end
    if not isAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
        return
    end
    local location = Config.SecretBunkers.locations[locId]
    if not location then return end
    local droneModel = 'akula'
    local spawn = location.interior.droneSpawn
    local drone = CreateVehicle(droneModel, spawn.coords.x, spawn.coords.y, spawn.coords.z, spawn.heading, true, false)
    if drone == 0 then return end
    SetVehicleNumberPlateText(drone, 'DRONE' .. math.random(10, 99))
    SetVehicleEngineOn(drone, true, true, false)
    SetVehicleNeedsToBeHotwired(drone, false)
    local netId = NetworkGetNetworkIdFromEntity(drone)
    TriggerClientEvent('bunker:spawnDroneClient', src, netId)
end)

RegisterNetEvent('bunker:takeWeapon', function(locId, weaponName)
    local src = source
    if not checkRateLimit(src, 'bunkerWeapon', 10) then return end
    local location = Config.SecretBunkers.locations[locId]
    if not location then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if not isAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
        return
    end
    local wepConfig = nil
    for _, w in ipairs(location.armory.weapons) do
        if w.weapon == weaponName then wepConfig = w end
    end
    if not wepConfig then return end
    if player.Functions.AddItem(weaponName, 1) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Took ' .. wepConfig.label })
    end
end)

RegisterNetEvent('bunker:takeAmmo', function(locId, ammoItem)
    local src = source
    if not checkRateLimit(src, 'bunkerAmmo', 10) then return end
    local location = Config.SecretBunkers.locations[locId]
    if not location then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not isAdmin(src) then return end
    local ammoConfig = nil
    for _, a in ipairs(location.armory.ammo) do
        if a.item == ammoItem then ammoConfig = a end
    end
    if not ammoConfig then return end
    if player.Functions.AddItem(ammoItem, ammoConfig.count) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Took ' .. ammoConfig.label })
    end
end)

RegisterNetEvent('bunker:takeEquipment', function(locId, equipItem)
    local src = source
    if not checkRateLimit(src, 'bunkerEquip', 10) then return end
    local location = Config.SecretBunkers.locations[locId]
    if not location then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not isAdmin(src) then return end
    local equipConfig = nil
    for _, e in ipairs(location.armory.equipment) do
        if e.item == equipItem then equipConfig = e end
    end
    if not equipConfig then return end
    if player.Functions.AddItem(equipItem, 1) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Took ' .. equipConfig.label })
    end
end)
