local QBox = exports['qbx-core']:GetCoreObject()

--- Spawn an aircraft at the given coordinates
local function spawnAircraft(model, coords, heading)
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)

    local modelHash = joaat(model)
    RequestModel(modelHash)
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    if not HasModelLoaded(modelHash) then
        Wrappers.Notify('Failed to load aircraft model', 'error')
        return
    end

    local spawnHeight = Config.Helipads.SpawnHeightOffset
    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z + spawnHeight, heading, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, true)
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehRadioStation(vehicle, 'OFF')

    -- Plate
    local plate = 'HELI' .. tostring(math.random(100, 999))
    SetVehicleNumberPlateText(vehicle, plate)

    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    TriggerServerEvent('helipads:server:spawnAircraft', model, coords, heading)

    SetModelAsNoLongerNeeded(modelHash)
end

--- Create helipad target zones
Citizen.CreateThread(function()
    Wait(1500)

    for _, loc in ipairs(Config.Helipads.Locations) do
        -- Blip
        local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
        SetBlipSprite(blip, loc.blip.sprite)
        SetBlipColour(blip, loc.blip.color)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(loc.label)
        EndTextCommandSetBlipName(blip)

        -- Target zone
        exports.ox_target:addSphereZone({
            coords = loc.coords,
            radius = 2.0,
            debug = false,
            options = {
                {
                    name = 'helipad_' .. loc.id,
                    icon = 'fas fa-helicopter',
                    label = 'Open Helipad Menu',
                    distance = Config.Helipads.InteractionDistance,
                    groups = loc.type == 'police' and { 'police', 'cid', 'sheriff', 'statepolice' } or nil,
                    onSelect = function()
                        openHelipadMenu(loc)
                    end,
                }
            }
        })
    end
end)

--- Open the helipad context menu
function openHelipadMenu(location)
    local player = QBox.Functions.GetPlayerData()
    if not player or not player.job then return end

    local jobName = player.job.name
    local grade = player.job.grade

    if location.type == 'police' then
        local isLeo = jobName == 'police' or jobName == 'sheriff' or jobName == 'statepolice' or jobName == 'cid'
        if not isLeo then
            Wrappers.Notify('Police/CID access only', 'error')
            return
        end

        local vehicles = lib.callback.await('helipads:server:getAircraft', false)
        if not vehicles or #vehicles == 0 then
            Wrappers.Notify('No aircraft available for your rank', 'error')
            return
        end

        local options = {}
        for _, v in ipairs(vehicles) do
            table.insert(options, {
                title = v.label,
                description = ('Speed: %s | Seats: %s | Rank: %s'):format(v.speed, v.seats, v.rank),
                icon = 'fas fa-helicopter',
                onSelect = function()
                    spawnAircraft(v.model, location.coords, location.heading)
                end,
            })
        end

        Wrappers.ContextMenu({
            id = 'helipad_' .. location.id,
            title = location.label,
            menuItems = options,
        })
    else
        -- Public helipad: spawn a civilian helicopter
        local publicHelis = {
            { model = 'maverick', label = 'Maverick' },
            { model = 'frogger', label = 'Frogger' },
            { model = 'buzzard', label = 'Buzzard' },
            { model = 'seasparrow', label = 'Sea Sparrow' },
        }

        local options = {}
        for _, v in ipairs(publicHelis) do
            table.insert(options, {
                title = v.label,
                icon = 'fas fa-helicopter',
                onSelect = function()
                    spawnAircraft(v.model, location.coords, location.heading)
                end,
            })
        end

        Wrappers.ContextMenu({
            id = 'helipad_' .. location.id,
            title = location.label,
            menuItems = options,
        })
    end
end

--- Client-side spawn handler
RegisterNetEvent('helipads:client:spawnVehicle', function(model, coords, heading)
    spawnAircraft(model, coords, heading)
end)
