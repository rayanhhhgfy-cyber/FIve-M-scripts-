local QBCore = exports['qbx_core']:GetCoreObject()
local vehicleCache = {}

function GetPlayerVehicles(citizenId)
    if vehicleCache[citizenId] then
        local age = GetGameTimer() - vehicleCache[citizenId].timestamp
        if age < 15000 then return vehicleCache[citizenId].vehicles end
    end
    local result = MySQL.query.await(
        'SELECT * FROM player_vehicles WHERE citizenid = ? ORDER BY garage ASC',
        { citizenId }
    )
    local vehicles = result or {}
    for _, v in ipairs(vehicles) do
        if type(v.mods) == 'string' then
            v.mods = json.decode(v.mods)
        end
    end
    vehicleCache[citizenId] = { vehicles = vehicles, timestamp = GetGameTimer() }
    return vehicles
end

local function GetVehicleByPlate(plate)
    local result = MySQL.query.await('SELECT * FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    if result and #result > 0 then
        if type(result[1].mods) == 'string' then
            result[1].mods = json.decode(result[1].mods)
        end
        return result[1]
    end
    return nil
end

function ParkVehicle(citizenId, plate, garage, fuel, engineDamage, bodyDamage, mods)
    local modsJson = type(mods) == 'table' and json.encode(mods) or mods
    MySQL.update.await(
        'UPDATE player_vehicles SET garage = ?, state = 0, fuel = ?, engine_damage = ?, body_damage = ?, mods = ? WHERE plate = ? AND citizenid = ?',
        { garage, fuel or 100, engineDamage or 0, bodyDamage or 0, modsJson or '{}', plate, citizenId }
    )
    vehicleCache[citizenId] = nil
end

local function SpawnVehicle(source, plate, garage)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    local vehicle = GetVehicleByPlate(plate)
    if not vehicle then return false end
    if vehicle.citizenid ~= player.PlayerData.citizenid then return false end
    local garageConfig = nil
    for _, g in ipairs(Config.GarageLocations) do
        if g.name == garage then
            garageConfig = g
            break
        end
    end
    if not garageConfig then return false end
    if garageConfig.type == 'impound' then
        local money = player.PlayerData.money.cash
        if money < Config.Garages.impoundFee then
            return false, 'Impound fee: $' .. Config.Garages.impoundFee
        end
        player.Functions.RemoveMoney('cash', Config.Garages.impoundFee)
    end
    local spawnCoords = garageConfig.spawn
    local netId = lib.callback.await('Renewed-Garages:client:spawnVehicle', source, vehicle.vehicle, spawnCoords, vehicle.mods)
    if netId then
        MySQL.update.await('UPDATE player_vehicles SET state = 1 WHERE plate = ?', { plate })
        vehicleCache[player.PlayerData.citizenid] = nil
        return true, netId
    end
    return false, 'Spawn failed'
end

lib.callback.register('Renewed-Garages:server:getVehicles', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return {} end
    return GetPlayerVehicles(player.PlayerData.citizenid)
end)

lib.callback.register('Renewed-Garages:server:getGarages', function(source)
    return Config.GarageLocations
end)

lib.callback.register('Renewed-Garages:server:parkVehicle', function(source, plate, garage, fuel, engineDamage, bodyDamage, mods)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    ParkVehicle(player.PlayerData.citizenid, plate, garage, fuel, engineDamage, bodyDamage, mods)
    return true
end)

lib.callback.register('Renewed-Garages:server:spawnVehicle', function(source, plate, garage)
    return SpawnVehicle(source, plate, garage)
end)

lib.callback.register('Renewed-Garages:server:addVehicle', function(source, vehicleProps)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end
    local citizenId = player.PlayerData.citizenid
    local vehicles = GetPlayerVehicles(citizenId)
    if #vehicles >= Config.Garages.maxVehicles then
        return false, 'Max vehicles reached'
    end
    local plate = vehicleProps.plate or ('FIV' .. math.random(10000, 99999))
    MySQL.insert.await(
        'INSERT INTO player_vehicles (citizenid, plate, vehicle, hash, garage, state, fuel, engine_damage, body_damage, mods) VALUES (?, ?, ?, ?, ?, 0, 100, 0, 0, ?)',
        { citizenId, plate, vehicleProps.vehicle, vehicleProps.hash or 0, 'Legion Square Garage', '{}' }
    )
    vehicleCache[citizenId] = nil
    return true, plate
end)

RegisterNetEvent('Renewed-Garages:server:saveVehicle', function(plate, fuel, engineDamage, bodyDamage, mods)
    local source = source
    if not source then return end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    ParkVehicle(player.PlayerData.citizenid, plate, 'out', fuel, engineDamage, bodyDamage, mods)
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[Renewed-Garages] Garage system initialized. %d locations.^7', #Config.GarageLocations)
end)

exports('GetPlayerVehicles', GetPlayerVehicles)
exports('GetVehicle', GetVehicleByPlate)
exports('ParkVehicle', ParkVehicle)
exports('AddVehicle', function(citizenId, vehicleProps)
    MySQL.insert.await(
        'INSERT INTO player_vehicles (citizenid, plate, vehicle, hash, garage, state, fuel, engine_damage, body_damage, mods) VALUES (?, ?, ?, ?, ?, 0, 100, 0, 0, ?)',
        { citizenId, vehicleProps.plate, vehicleProps.vehicle, vehicleProps.hash or 0, 'Legion Square Garage', '{}' }
    )
    vehicleCache[citizenId] = nil
    return vehicleProps.plate
end)
