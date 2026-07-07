local QBCore = exports['qbx_core']:GetCoreObject()
local activeVehicles = {}

local function getGarageConfig(name)
    for _, garages in pairs(Config.Garages) do
        for _, g in ipairs(garages) do
            if g.name == name then return g end
        end
    end
    return nil
end

local function getMaxSlots(garageType)
    if garageType == 'personal' then return Config.GarageSettings.PersonalSlots end
    if garageType == 'apartment' then return Config.GarageSettings.ApartmentSlots end
    if garageType == 'public' then return Config.GarageSettings.PublicSlots end
    return 10
end

local function countStoredVehicles(citizenid, garageName)
    return MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ? AND garage = ?', { citizenid, garageName })
end

local function calculateImpoundFee(impoundId)
    local data = MySQL.single.await('SELECT * FROM impounded_vehicles WHERE id = ? AND released = 0', { impoundId })
    if not data then return 0 end
    local minutesHeld = math.floor((os.time() - data.impound_time) / 60)
    local grace = Config.GarageSettings.ImpoundGraceMinutes
    local feePerMin = Config.GarageSettings.ImpoundFeePerMinute
    local maxFee = Config.GarageSettings.MaxImpoundFee
    if minutesHeld <= grace then return 0 end
    local fee = (minutesHeld - grace) * feePerMin
    return math.min(fee, maxFee)
end

lib.callback.register('garage:server:getPlayerVehicles', function(src, garageName)
    local source = src
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    local citizenid = Player.PlayerData.citizenid

    if garageName then
        local garage = getGarageConfig(garageName)
        if not garage then return {} end
        if garage.type == 'impound' then
            local impounded = MySQL.query.await([[
                SELECT pv.plate, pv.model, iv.id as impound_id, iv.impound_time, iv.fee as base_fee, iv.reason
                FROM impounded_vehicles iv
                JOIN player_vehicles pv ON iv.vehicle_plate = pv.plate
                WHERE iv.citizenid = ? AND iv.released = 0
            ]], { citizenid })
            local result = {}
            for _, v in ipairs(impounded) do
                table.insert(result, {
                    plate = v.plate,
                    model = v.model,
                    state = 'impounded',
                    impoundId = v.impound_id,
                    fee = calculateImpoundFee(v.impound_id),
                    reason = v.reason
                })
            end
            return result
        end

        local vehicles = MySQL.query.await('SELECT plate, model, garage FROM player_vehicles WHERE citizenid = ? ORDER BY id DESC', { citizenid })
        local result = {}
        for _, v in ipairs(vehicles) do
            local state = 'stored'
            if v.garage == 'out' then state = 'out' end
            if activeVehicles[v.plate] then
                state = 'out'
                local netId = activeVehicles[v.plate]
                local entity = NetworkGetEntityFromNetworkId(netId)
                if DoesEntityExist(entity) then
                    v.location = { x = GetEntityCoords(entity).x, y = GetEntityCoords(entity).y }
                end
            end
            table.insert(result, {
                plate = v.plate,
                model = v.model,
                state = state,
                location = v.location
            })
        end
        return result
    else
        local vehicles = MySQL.query.await('SELECT plate, model, garage FROM player_vehicles WHERE citizenid = ? ORDER BY id DESC', { citizenid })
        local result = {}
        for _, v in ipairs(vehicles) do
            local state = 'stored'
            if v.garage ~= 'out' and v.garage then state = 'stored' end
            if v.garage == 'out' then state = 'out' end
            table.insert(result, {
                plate = v.plate,
                model = v.model,
                state = state,
                garage = v.garage
            })
        end
        return result
    end
end)

lib.callback.register('garage:server:spawnVehicle', function(src, plate, garageName)
    local source = src
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return { success = false, error = 'Player not found' } end
    local citizenid = Player.PlayerData.citizenid

    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, citizenid })
    if not vehicle then
        return { success = false, error = 'Vehicle not found' }
    end

    if activeVehicles[plate] then
        local existingNet = activeVehicles[plate]
        local existingEnt = NetworkGetEntityFromNetworkId(existingNet)
        if DoesEntityExist(existingEnt) then
            DeleteEntity(existingEnt)
        end
        activeVehicles[plate] = nil
    end

    local garage = getGarageConfig(garageName)
    if not garage then return { success = false, error = 'Garage not found' } end

    local ped = GetPlayerPed(source)
    local coords = garage.spawn
    local spawnCoords = vec3(coords.x, coords.y, coords.z)

    local model = joaat(vehicle.model)
    RequestModel(model)
    local timeout = 100
    while not HasModelLoaded(model) do
        timeout = timeout - 1
        if timeout <= 0 then return { success = false, error = 'Model load timeout' } end
        Citizen.Wait(10)
    end

    local spawned = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, coords.w, true, false)
    SetVehicleOnGroundProperly(spawned)
    SetVehicleNumberPlateText(spawned, plate)
    SetModelAsNoLongerNeeded(model)

    local netId = NetworkGetNetworkIdFromEntity(spawned)
    activeVehicles[plate] = netId

    MySQL.update.await('UPDATE player_vehicles SET garage = ? WHERE plate = ?', { 'out', plate })
    SetVehicleEngineOn(spawned, true, true, false)

    return { success = true }
end)

lib.callback.register('garage:server:storeVehicle', function(src, garageName)
    local source = src
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return { success = false, error = 'Player not found' } end
    local citizenid = Player.PlayerData.citizenid

    local ped = GetPlayerPed(source)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or not DoesEntityExist(vehicle) then
        vehicle = GetClosestVehicle(GetEntityCoords(ped), Config.GarageSettings.StoreVehicleRadius, nil, 70)
        if not vehicle or not DoesEntityExist(vehicle) then
            return { success = false, error = 'No vehicle nearby' }
        end
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    plate = plate:gsub('%s+', '')

    local owned = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, citizenid })
    if not owned then
        return { success = false, error = 'Not your vehicle' }
    end

    local garage = getGarageConfig(garageName)
    if not garage then return { success = false, error = 'Garage not found' } end

    local stored = countStoredVehicles(citizenid, garageName)
    local maxSlots = getMaxSlots(garage.type)
    if stored >= maxSlots then
        return { success = false, error = 'Garage is full (' .. maxSlots .. ' slots)' }
    end

    local model = GetEntityModel(vehicle)
    local modelData = {}
    local health = GetVehicleBodyHealth(vehicle)
    local engine = GetVehicleEngineHealth(vehicle)
    local fuel = GetVehicleFuelLevel(vehicle)
    local color1, color2 = GetVehicleColours(vehicle)
    modelData.health = health
    modelData.engine = engine
    modelData.fuel = fuel
    modelData.color1 = color1
    modelData.color2 = color2

    MySQL.update.await('UPDATE player_vehicles SET garage = ?, model_data = ? WHERE plate = ?', {
        garageName, json.encode(modelData), plate
    })

    if activeVehicles[plate] then
        activeVehicles[plate] = nil
    end

    DeleteEntity(vehicle)

    return { success = true }
end)

lib.callback.register('garage:server:retrieveImpound', function(src, plate, garageName)
    local source = src
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return { success = false, error = 'Player not found' } end
    local citizenid = Player.PlayerData.citizenid

    local impounded = MySQL.single.await([[
        SELECT iv.* FROM impounded_vehicles iv
        JOIN player_vehicles pv ON iv.vehicle_plate = pv.plate
        WHERE pv.plate = ? AND pv.citizenid = ? AND iv.released = 0
    ]], { plate, citizenid })

    if not impounded then
        return { success = false, error = 'Vehicle not found in impound' }
    end

    local fee = calculateImpoundFee(impounded.id)
    local bank = Player.PlayerData.money.bank or 0

    if bank < fee then
        return { success = false, error = 'Insufficient funds. Fee: $' .. fee }
    end

    Player.Functions.RemoveMoney('bank', fee, 'impound-retrieval')
    MySQL.update.await('UPDATE impounded_vehicles SET released = 1 WHERE id = ?', { impounded.id })
    MySQL.update.await("UPDATE player_vehicles SET garage = 'A' WHERE plate = ?", { plate })

    return { success = true, fee = fee }
end)

RegisterNetEvent('garage:server:impoundVehicle', function(plate, reason)
    local src = source
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicle then return end

    MySQL.insert.await('INSERT INTO impounded_vehicles (vehicle_plate, citizenid, impound_time, reason) VALUES (?, ?, UNIX_TIMESTAMP(), ?)', {
        plate, vehicle.citizenid, reason or 'Police impound'
    })
    MySQL.update.await("UPDATE player_vehicles SET garage = 'impound' WHERE plate = ?", { plate })

    local target = QBCore.Functions.GetPlayerByCitizenId(vehicle.citizenid)
    if target then
        Wrappers.Notify(target.PlayerData.source, 'Impound', 'Your vehicle (' .. plate .. ') has been impounded. Reason: ' .. (reason or 'N/A'), 'error')
    end
end)

QBCore.Commands.Add('impound', 'Impound a vehicle (Police)', {}, true, function(source, args)
    local plate = args[1]
    local reason = table.concat(args, ' ', 2)
    if not plate then
        Wrappers.Notify(source, 'Impound', 'Usage: /impound [plate] [reason]', 'error')
        return
    end
    TriggerEvent('garage:server:impoundVehicle', plate:upper(), reason)
    Wrappers.Notify(source, 'Impound', 'Vehicle ' .. plate:upper() .. ' impounded', 'success')
end, 'police')
