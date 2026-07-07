local removedCounts = { vehicles = 0, peds = 0, objects = 0, props = 0 }
local entityTimestamps = {}
local lastCleanup = 0

local function IsInSafeZone(coords)
    for _, zone in ipairs(Config.SafeZones) do
        if #(coords - zone.coords) <= zone.radius then
            return true
        end
    end
    return false
end

local function IsJobVehicle(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    for _, job in ipairs(Config.VehicleThresholds.jobVehicles) do
        if string.find(string.lower(plate), job) then
            return true
        end
    end
    return false
end

local function GetNearbyPlayerCount(coords, radius)
    local count = 0
    local players = GetPlayers()
    for i = 1, #players do
        local ped = GetPlayerPed(tonumber(players[i]))
        if ped and ped > 0 then
            local pcoords = GetEntityCoords(ped)
            if #(pcoords - coords) <= radius then
                count = count + 1
            end
        end
    end
    return count
end

local function CleanupVehicles()
    local removed = 0
    local vehicles = GetGamePool('CVehicle')
    for i = 1, #vehicles do
        if removed >= Config.VehicleThresholds.maxToRemove then break end
        local vehicle = vehicles[i]
        if DoesEntityExist(vehicle) then
            local coords = GetEntityCoords(vehicle)
            if IsInSafeZone(coords) then goto continue end
            if Config.VehicleThresholds.excludeJobVehicles and IsJobVehicle(vehicle) then
                goto continue
            end
            local isEngineOn = GetIsVehicleEngineRunning(vehicle)
            if Config.VehicleThresholds.engineOff and isEngineOn then goto continue end
            local hasPlayers = false
            for seat = -1, 6 do
                if IsPedInVehicle(GetPlayerPed(-1), vehicle, false) then
                    hasPlayers = true
                    break
                end
            end
            if Config.VehicleThresholds.noPlayersInVehicle and hasPlayers then goto continue end
            local nearby = GetNearbyPlayerCount(coords, Config.VehicleThresholds.abandonedDistance)
            if nearby > 1 then goto continue end
            local model = GetEntityModel(vehicle)
            local modelName = GetDisplayNameFromVehicleModel(model)
            local modelNameLower = string.lower(modelName)
            local isBlacklisted = false
            for _, bl in ipairs(Config.VehicleThresholds.blacklistModels) do
                if modelNameLower == bl then
                    isBlacklisted = true
                    break
                end
            end
            if isBlacklisted then goto continue end
            if not Config.Cleaner.dryRun then
                DeleteEntity(vehicle)
            end
            removed = removed + 1
        end
        ::continue::
    end
    removedCounts.vehicles = removedCounts.vehicles + removed
    return removed
end

local function CleanupPeds()
    local removed = 0
    local peds = GetGamePool('CPed')
    for i = 1, #peds do
        if removed >= Config.PedThresholds.maxToRemove then break end
        local ped = peds[i]
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            if Config.PedThresholds.excludePlayerPeds and IsPedAPlayer(ped) then goto continue end
            local coords = GetEntityCoords(ped)
            if IsInSafeZone(coords) then goto continue end
            local nearby = GetNearbyPlayerCount(coords, Config.PedThresholds.abandonedDistance)
            if nearby > 1 then goto continue end
            if not Config.Cleaner.dryRun then
                DeleteEntity(ped)
            end
            removed = removed + 1
        end
        ::continue::
    end
    removedCounts.peds = removedCounts.peds + removed
    return removed
end

local function CleanupObjects()
    local removed = 0
    local objects = GetGamePool('CObject')
    for i = 1, #objects do
        if removed >= Config.ObjectThresholds.maxToRemove then break end
        local obj = objects[i]
        if DoesEntityExist(obj) then
            if Config.ObjectThresholds.excludeMissionObjects and IsEntityAMissionEntity(obj) then goto continue end
            local coords = GetEntityCoords(obj)
            if IsInSafeZone(coords) then goto continue end
            local nearby = GetNearbyPlayerCount(coords, Config.ObjectThresholds.abandonedDistance)
            if nearby > 1 then goto continue end
            local model = GetEntityModel(obj)
            for _, bl in ipairs(Config.ObjectThresholds.blacklistModels) do
                if model == bl then goto continue end
            end
            if not Config.Cleaner.dryRun then
                DeleteEntity(obj)
            end
            removed = removed + 1
        end
        ::continue::
    end
    removedCounts.objects = removedCounts.objects + removed
    return removed
end

local function CleanupProps()
    local removed = 0
    local objects = GetGamePool('CObject')
    for i = 1, #objects do
        if removed >= Config.PropThresholds.maxProps then break end
        local obj = objects[i]
        if DoesEntityExist(obj) then
            if IsEntityAttached(obj) then goto continue end
            if IsEntityAMissionEntity(obj) then goto continue end
            if not Config.Cleaner.dryRun then
                DeleteEntity(obj)
            end
            removed = removed + 1
        end
        ::continue::
    end
    removedCounts.props = removedCounts.props + removed
    return removed
end

local function RunCleanup()
    if not Config.Cleaner.enabled then return end
    local vCount = CleanupVehicles()
    local pCount = CleanupPeds()
    local oCount = CleanupObjects()
    local prCount = CleanupProps()
    local total = vCount + pCount + oCount + prCount
    lastCleanup = GetGameTimer()
    if total > 0 and Config.Cleaner.logCleanups then
        print(string.format('^5[entity-cleaner] Removed %d entities (%d vehicles, %d peds, %d objects, %d props)^7',
            total, vCount, pCount, oCount, prCount))
    end
end

lib.callback.register('entity-cleaner:server:getStats', function(source)
    return {
        removedCounts = removedCounts,
        lastCleanup = lastCleanup,
        runtime = GetGameTimer()
    }
end)

lib.callback.register('entity-cleaner:server:forceCleanup', function(source)
    RunCleanup()
    return removedCounts
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[entity-cleaner] Entity cleaner initialized.^7')
    if not Config.Cleaner.enabled then return end
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.Cleaner.interval)
            RunCleanup()
        end
    end)
end)

AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
end)

exports('GetTotalRemoved', function() return removedCounts end)
exports('ForceCleanup', RunCleanup)
