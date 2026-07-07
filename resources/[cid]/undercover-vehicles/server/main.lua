local QBox = exports['qbx-core']:GetCoreObject()
local activeTrackers = {}

local function generateTrackerId()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local id = 'TRK-'
    for i = 1, 8 do
        id = id .. chars:sub(math.random(#chars), math.random(#chars))
    end
    return id
end

--- Deploy GPS tracker on a vehicle
RegisterNetEvent('ucv:server:deployTracker', function(plate, coords)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local cleanPlate = string.upper(plate:gsub('%s+', ''))
    local trackerId = generateTrackerId()
    local placedAt = os.time()

    MySQL.insert('INSERT INTO cid_trackers (plate, tracker_id, placed_by, placed_at, last_x, last_y, last_z, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        cleanPlate, trackerId, player.PlayerData.citizenid, placedAt, coords.x, coords.y, coords.z, true
    })

    activeTrackers[trackerId] = {
        plate = cleanPlate,
        placedBy = player.PlayerData.citizenid,
        placedAt = placedAt,
        active = true,
    }

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'GPS Tracker deployed on ' .. cleanPlate })
end)

--- Sweep a vehicle for trackers
QBox.Functions.CreateCallback('ucv:server:sweepTracker', function(source, cb, plate)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then cb({ found = false, trackers = {} }) return end
    local cleanPlate = string.upper(plate:gsub('%s+', ''))

    MySQL.query('SELECT * FROM cid_trackers WHERE plate = ? AND active = TRUE', { cleanPlate }, function(trackers)
        if not trackers or #trackers == 0 then
            cb({ found = false, trackers = {} })
        else
            cb({ found = true, trackers = trackers })
        end
    end)
end)

--- Remove a specific tracker
RegisterNetEvent('ucv:server:removeTracker', function(trackerId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    MySQL.update('UPDATE cid_trackers SET active = FALSE WHERE tracker_id = ?', { trackerId })
    if activeTrackers[trackerId] then
        activeTrackers[trackerId].active = false
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Tracker removed' })
end)

--- Get all active trackers for signal scanner
QBox.Functions.CreateCallback('ucv:server:getActiveTrackers', function(source, cb)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then cb({}) return end

    MySQL.query('SELECT * FROM cid_trackers WHERE active = TRUE AND last_x IS NOT NULL', function(trackers)
        cb(trackers or {})
    end)
end)

--- GPS position update thread for active trackers
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.UndercoverVehicles.GpsSyncInterval)
        MySQL.query('SELECT * FROM cid_trackers WHERE active = TRUE', function(trackers)
            if trackers then
                for _, t in ipairs(trackers) do
                    activeTrackers[t.tracker_id] = {
                        id = t.id,
                        plate = t.plate,
                        trackerId = t.tracker_id,
                        placedBy = t.placed_by,
                        placedAt = t.placed_at,
                        coords = { x = t.last_x, y = t.last_y, z = t.last_z },
                        active = t.active,
                    }
                end
            end
        end)
    end
end)

--- Vehicle spawn event for UC fleet
RegisterNetEvent('ucv:server:spawnVehicle', function(model, locationName)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local location = Config.UndercoverVehicles.Locations[locationName]
    if not location then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Invalid location' })
        return
    end
    local spawn = location.spawns[math.random(#location.spawns)]
    TriggerClientEvent('ucv:client:spawnVehicle', src, model, spawn.coords, spawn.heading)
end)
