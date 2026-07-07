local QBox = exports['qbx-core']:GetCoreObject()
local activeVehicles = {}

local RATE_LIMITS = {}
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

RegisterNetEvent('cid:garage:server:vehicleSpawned', function(model, plate)
    local src = source
    if not checkRateLimit(src, 'vehicleSpawn', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    activeVehicles[src] = { model = model, plate = plate, time = os.time() }
    MySQL.insert('INSERT INTO police_vehicle_logs (citizenid, vehicle, plate, action, timestamp) VALUES (?, ?, ?, ?, ?)',
        { player.PlayerData.citizenid, model, plate, 'spawned', os.time() })
end)

RegisterNetEvent('cid:garage:server:vehicleStored', function(plate)
    local src = source
    if not checkRateLimit(src, 'vehicleStore', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    activeVehicles[src] = nil
    MySQL.insert('INSERT INTO police_vehicle_logs (citizenid, vehicle, plate, action, timestamp) VALUES (?, ?, ?, ?, ?)',
        { player.PlayerData.citizenid, 'unknown', plate, 'stored', os.time() })
end)

local function impoundAllVehicles()
    for src, vData in pairs(activeVehicles) do
        local player = QBox.Functions.GetPlayer(src)
        if player then
            TriggerClientEvent('cid:garage:client:impoundVehicle', src)
        end
    end
    activeVehicles = {}
end

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    if activeVehicles[src] then
        local player = QBox.Functions.GetPlayer(src)
        if player then
            MySQL.insert('INSERT INTO police_vehicle_logs (citizenid, vehicle, plate, action, timestamp) VALUES (?, ?, ?, ?, ?)',
                { player.PlayerData.citizenid, activeVehicles[src].model, activeVehicles[src].plate, 'impounded_disconnect', os.time() })
        end
        activeVehicles[src] = nil
    end
end)

QBox.Functions.CreateCallback('cid:garage:server:getAvailableVehicles', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then cb({}) return end
    local rank = player.PlayerData.job.grade.level or 0
    local vehicles = {}
    for catName, catData in pairs(Config.CIDGarage.Categories) do
        if rank >= catData.rank then
            vehicles[catName] = catData
        end
    end
    cb(vehicles)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000)
        local now = os.time()
        for src, vData in pairs(activeVehicles) do
            local player = QBox.Functions.GetPlayer(src)
            if player then
                local job = player.PlayerData.job
                if job.name ~= 'cid' or not job.onduty then
                    if Config.CIDGarage.SpawnSettings.impoundOnDutyEnd then
                        TriggerClientEvent('cid:garage:client:impoundVehicle', src)
                        activeVehicles[src] = nil
                    end
                end
            end
        end
    end
end)
