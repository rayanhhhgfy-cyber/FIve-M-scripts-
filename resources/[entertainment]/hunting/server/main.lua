local QBCore = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    if not RATE_LIMITS[key] then
        RATE_LIMITS[key] = { count = 1, resetAt = now + 60 }
        return true
    end
    if now > RATE_LIMITS[key].resetAt then
        RATE_LIMITS[key] = { count = 1, resetAt = now + 60 }
        return true
    end
    RATE_LIMITS[key].count = RATE_LIMITS[key].count + 1
    if RATE_LIMITS[key].count > maxPerMin then
        return false
    end
    return true
end

local ActiveHunts = {}
local AnimalCarcasses = {}

local function spawnAnimal(huntId, animalIndex)
    local animal = Config.Hunting.animals[animalIndex]
    local zone = Config.Hunting.spawnZones[math.random(#Config.Hunting.spawnZones)]
    local angle = math.random() * 2.0 * math.pi
    local dist = math.random() * zone.radius
    local x = zone.coords.x + math.cos(angle) * dist
    local y = zone.coords.y + math.sin(angle) * dist
    local z = zone.coords.z
    local spawnCoords = vector3(x, y, z)

    local _, netPed = GetRandomPlayer(0)
    local model = GetHashKey(animal.model)
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end
    local ped = CreatePed(0, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 3, true)
    local netId = NetworkGetNetworkIdFromEntity(ped)
    SetNetworkIdExistsOnNetwork(netId, true)

    ActiveHunts[huntId] = {
        src = huntId,
        animalIndex = animalIndex,
        ped = ped,
        netPed = netId,
        coords = spawnCoords,
        killed = false,
        skinned = false,
    }

    return spawnCoords, netId
end

RegisterNetEvent('hunting:startHunt', function()
    local src = source
    if not checkRateLimit(src, 'startHunt', 3) then
        return Wrappers.Notify(src, Locale('hunting.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if ActiveHunts[src] and not ActiveHunts[src].killed then
        return Wrappers.Notify(src, Locale('hunting.already_hunting'), 'error')
    end

    local animalIndex = math.random(#Config.Hunting.animals)
    local coords, netId = spawnAnimal(src, animalIndex)
    if not coords then
        return Wrappers.Notify(src, Locale('hunting.error_spawn'), 'error')
    end

    TriggerClientEvent('hunting:animalSpawned', src, coords, netId, animalIndex)
    Wrappers.Notify(src, Locale('hunting.hunt_started'), 'success')
end)

RegisterNetEvent('hunting:killAnimal', function(netPed)
    local src = source
    if not checkRateLimit(src, 'killAnimal', 1) then
        return Wrappers.Notify(src, Locale('hunting.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local hunt = ActiveHunts[src]
    if not hunt or hunt.killed then
        return Wrappers.Notify(src, Locale('hunting.no_active_hunt'), 'error')
    end

    local ped = NetworkGetEntityFromNetworkId(netPed)
    if not DoesEntityExist(ped) then
        return Wrappers.Notify(src, Locale('hunting.invalid_animal'), 'error')
    end

    local pedCoords = GetEntityCoords(ped)
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dist = #(playerCoords - pedCoords)
    if dist > 100.0 then
        return Wrappers.Notify(src, Locale('hunting.too_far'), 'error')
    end

    local _, weapon = GetCurrentPedWeapon(GetPlayerPed(src))
    local weaponGroup = GetWeapontypeGroup(weapon)
    local validGroups = {
        GetHashKey('GROUP_RIFLE'),
        GetHashKey('GROUP_SNIPER'),
        GetHashKey('GROUP_SHOTGUN'),
        GetHashKey('GROUP_PISTOL'),
        GetHashKey('GROUP_REVOLVER'),
    }
    local valid = false
    for _, g in ipairs(validGroups) do
        if weaponGroup == g then
            valid = true
            break
        end
    end
    if not valid then
        return Wrappers.Notify(src, Locale('hunting.need_weapon'), 'error')
    end

    SetPedAsNoLongerNeeded(ped)
    DeleteEntity(ped)

    local animal = Config.Hunting.animals[hunt.animalIndex]
    local meatCount = math.random(animal.meatCount[1], animal.meatCount[2])
    local items = {}
    for i = 1, meatCount do
        Player.Functions.AddItem(animal.meat, 1)
        table.insert(items, animal.meat)
    end
    Player.Functions.AddItem(animal.pelt, 1)
    table.insert(items, animal.pelt)

    hunt.killed = true
    AnimalCarcasses[src] = {
        coords = pedCoords,
        animalIndex = hunt.animalIndex,
        src = src,
    }

    TriggerClientEvent('hunting:carcassSpawned', src, pedCoords, hunt.animalIndex)
    Wrappers.Notify(src, Locale('hunting.animal_killed'), 'success')
end)

RegisterNetEvent('hunting:skinAnimal', function()
    local src = source
    if not checkRateLimit(src, 'skinAnimal', 2) then
        return Wrappers.Notify(src, Locale('hunting.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local carcass = AnimalCarcasses[src]
    if not carcass then
        return Wrappers.Notify(src, Locale('hunting.no_carcass'), 'error')
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dist = #(playerCoords - carcass.coords)
    if dist > 5.0 then
        return Wrappers.Notify(src, Locale('hunting.too_far'), 'error')
    end

    TriggerClientEvent('hunting:doSkinProgress', src, Config.Hunting.skinTime)

    local animal = Config.Hunting.animals[carcass.animalIndex]
    local meatCount = math.random(animal.meatCount[1], animal.meatCount[2])
    for i = 1, meatCount do
        Player.Functions.AddItem(animal.meat, 1)
    end
    Player.Functions.AddItem(animal.pelt, 1)

    AnimalCarcasses[src] = nil
    ActiveHunts[src] = nil

    Wrappers.Notify(src, Locale('hunting.skin_complete'), 'success')
end)

RegisterNetEvent('hunting:sellHunt', function()
    local src = source
    if not checkRateLimit(src, 'sellHunt', 2) then
        return Wrappers.Notify(src, Locale('hunting.too_fast'), 'error')
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local sellLoc = Config.Hunting.sellLocation
    local dist = #(playerCoords - sellLoc)
    if dist > 10.0 then
        return Wrappers.Notify(src, Locale('hunting.too_far'), 'error')
    end

    local totalPayout = 0
    local itemsToRemove = {}

    for _, animal in ipairs(Config.Hunting.animals) do
        local meatCount = Player.Functions.GetItemByName(animal.meat)
        local peltCount = Player.Functions.GetItemByName(animal.pelt)
        if meatCount and meatCount.amount > 0 then
            Player.Functions.RemoveItem(animal.meat, meatCount.amount)
            totalPayout = totalPayout + (meatCount.amount * math.floor(animal.price * 0.5))
        end
        if peltCount and peltCount.amount > 0 then
            Player.Functions.RemoveItem(animal.pelt, peltCount.amount)
            totalPayout = totalPayout + (peltCount.amount * math.floor(animal.price * 0.5))
        end
    end

    if totalPayout <= 0 then
        return Wrappers.Notify(src, Locale('hunting.nothing_to_sell'), 'error')
    end

    Player.Functions.AddMoney('cash', totalPayout)
    Wrappers.Notify(src, Locale('hunting.payment', totalPayout), 'success')
end)

AddEventHandler('playerDropped', function()
    local src = source
    if ActiveHunts[src] then
        if DoesEntityExist(ActiveHunts[src].ped) then
            DeleteEntity(ActiveHunts[src].ped)
        end
        ActiveHunts[src] = nil
    end
    AnimalCarcasses[src] = nil
end)
