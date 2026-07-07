local activeZones = {}
local zoneCallbacks = {}
local playerInZones = {}

function CreateBoxZone(name, center, size, options, callbacks)
    local opts = {
        heading = options.heading or Config.Defaults.box.heading,
        minZ = options.minZ or Config.Defaults.box.minZ,
        maxZ = options.maxZ or Config.Defaults.box.maxZ,
        debugPoly = options.debugPoly or Config.Defaults.box.debugPoly
    }
    local zone = BoxZone:Create(center, size.x, size.y, opts)
    activeZones[name] = zone
    zoneCallbacks[name] = callbacks or {}
    playerInZones[name] = false
    if callbacks and callbacks.onEnter then
        zone:onPlayerInOut(function(isInside, point)
            if isInside and not playerInZones[name] then
                playerInZones[name] = true
                callbacks.onEnter(point)
            elseif not isInside and playerInZones[name] then
                playerInZones[name] = false
                if callbacks.onExit then
                    callbacks.onExit(point)
                end
            end
        end)
    end
    return zone
end

function CreateCircleZone(name, center, radius, options, callbacks)
    local opts = {
        debugPoly = options.debugPoly or Config.Defaults.circle.debugPoly
    }
    local zone = CircleZone:Create(center, radius, opts)
    activeZones[name] = zone
    zoneCallbacks[name] = callbacks or {}
    playerInZones[name] = false
    if callbacks and callbacks.onEnter then
        zone:onPlayerInOut(function(isInside, point)
            if isInside and not playerInZones[name] then
                playerInZones[name] = true
                callbacks.onEnter(point)
            elseif not isInside and playerInZones[name] then
                playerInZones[name] = false
                if callbacks.onExit then
                    callbacks.onExit(point)
                end
            end
        end)
    end
    return zone
end

function CreatePolyZone(name, points, options, callbacks)
    local opts = {
        minZ = options.minZ or Config.Defaults.poly.minZ,
        maxZ = options.maxZ or Config.Defaults.poly.maxZ,
        debugPoly = options.debugPoly or Config.Defaults.poly.debugPoly
    }
    local zone = PolyZone:Create(points, opts)
    activeZones[name] = zone
    zoneCallbacks[name] = callbacks or {}
    playerInZones[name] = false
    if callbacks and callbacks.onEnter then
        zone:onPlayerInOut(function(isInside, point)
            if isInside and not playerInZones[name] then
                playerInZones[name] = true
                callbacks.onEnter(point)
            elseif not isInside and playerInZones[name] then
                playerInZones[name] = false
                if callbacks.onExit then
                    callbacks.onExit(point)
                end
            end
        end)
    end
    return zone
end

function DestroyZone(name)
    if activeZones[name] then
        activeZones[name]:destroy()
        activeZones[name] = nil
        zoneCallbacks[name] = nil
        playerInZones[name] = nil
    end
end

function IsPlayerInZone(name)
    if not activeZones[name] then return false end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return activeZones[name]:isPointInside(coords)
end

function GetPlayerZone()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for name, zone in pairs(activeZones) do
        if zone:isPointInside(coords) then
            return name, zone
        end
    end
    return nil, nil
end

function GetAllZones()
    local result = {}
    for name in pairs(activeZones) do
        table.insert(result, name)
    end
    return result
end

if Config.PolyZone.debugMode then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(100)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            for name, zone in pairs(activeZones) do
                local inside = zone:isPointInside(coords)
                if inside then
                    DrawText3D(coords.x, coords.y, coords.z + 1.0, '[ZONE] ' .. name, 0, 255, 0)
                end
            end
        end
    end)
end

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[polyzone-init] PolyZone spatial module initialized.^7')
end)

exports('CreateBoxZone', CreateBoxZone)
exports('CreateCircleZone', CreateCircleZone)
exports('CreatePolyZone', CreatePolyZone)
exports('DestroyZone', DestroyZone)
exports('IsPlayerInZone', IsPlayerInZone)
exports('GetPlayerZone', GetPlayerZone)
exports('GetAllZones', GetAllZones)
