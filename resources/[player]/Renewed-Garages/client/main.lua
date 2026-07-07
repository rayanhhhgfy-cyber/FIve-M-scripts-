local QBCore = exports['qbx_core']:GetCoreObject()
local currentGarage = nil

local function OpenGarageMenu(garage)
    currentGarage = garage
    local vehicles = lib.callback.await('Renewed-Garages:server:getVehicles', false)
    local options = {}
    for _, v in ipairs(vehicles) do
        if v.state == 0 then
            local mods = v.mods or {}
            local label = string.format('%s | %s | Fuel: %d%%', v.vehicle, v.plate, v.fuel or 100)
            table.insert(options, {
                title = label,
                description = string.format('Engine: %d%% | Body: %d%% | Garage: %s', v.engine_damage or 0, v.body_damage or 0, v.garage),
                icon = 'fas fa-car',
                onSelect = function()
                    local success, result = lib.callback.await('Renewed-Garages:server:spawnVehicle', false, v.plate, garage.name)
                    if success then
                        Wrappers.Notify({ type = 'success', description = v.vehicle .. ' spawned' })
                    else
                        Wrappers.Notify({ type = 'error', description = result or 'Spawn failed' })
                    end
                end
            })
        end
    end
    if #options == 0 then
        table.insert(options, { title = 'No vehicles stored', readOnly = true })
    end
    lib.registerContext({
        id = 'garage_menu',
        title = garage.name .. ' (' .. garage.type .. ')',
        options = options,
        onBack = function() OpenGarageSelector() end
    })
    lib.showContext('garage_menu')
end

local function OpenGarageSelector()
    local garages = lib.callback.await('Renewed-Garages:server:getGarages', false)
    local options = {}
    for _, g in ipairs(garages) do
        local feeLabel = g.type == 'impound' and ' ($' .. Config.Garages.impoundFee .. ' fee)' or ''
        table.insert(options, {
            title = g.name .. feeLabel,
            description = 'Type: ' .. g.type,
            icon = 'fas fa-warehouse',
            onSelect = function()
                OpenGarageMenu(g)
            end
        })
    end
    lib.registerContext({
        id = 'garage_selector',
        title = 'Select Garage',
        options = options
    })
    lib.showContext('garage_selector')
end

lib.callback.register('Renewed-Garages:client:spawnVehicle', function(source, vehicleModel, spawnCoords, mods)
    local model = GetHashKey(vehicleModel)
    if not IsModelInCdimage(model) then return nil end
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if not HasModelLoaded(model) then return nil end
    local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.h or 0.0, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetModelAsNoLongerNeeded(model)
    if mods then
        if mods.color1 then SetVehicleColours(vehicle, mods.color1, mods.color2 or 0) end
        if mods.neonColor then SetVehicleNeonLightsColour(vehicle, mods.neonColor.r, mods.neonColor.g, mods.neonColor.b) end
        if mods.wheelType then SetVehicleWheelType(vehicle, mods.wheelType) end
        if mods.modData then
            for modType, modIndex in pairs(mods.modData) do
                SetVehicleMod(vehicle, tonumber(modType), modIndex, false)
            end
        end
    end
    SetVehicleFuelLevel(vehicle, mods.fuel or 100.0)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    return NetworkGetNetworkIdFromEntity(vehicle)
end)

RegisterNetEvent('Renewed-Garages:client:openGarage', function(garageName)
    if garageName then
        local garages = lib.callback.await('Renewed-Garages:server:getGarages', false)
        for _, g in ipairs(garages) do
            if g.name == garageName then
                OpenGarageMenu(g)
                return
            end
        end
    end
    OpenGarageSelector()
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[Renewed-Garages] Client garage system ready.^7')
end)

exports('OpenGarage', OpenGarageSelector)
exports('ParkVehicle', function(plate, fuel, engineDam, bodyDam, mods)
    TriggerServerEvent('Renewed-Garages:server:saveVehicle', plate, fuel, engineDam, bodyDam, mods)
end)
