local QBox = exports['qbx-core']:GetCoreObject()
local showroomOpen = false
local previewVehicle = nil
local testDriveVehicle = nil
local testDriveTimer = 0

--- Create dealership entrance zones
Citizen.CreateThread(function()
    for name, location in pairs(Config.PremiumDealership.Locations) do
        exports.ox_target:addBoxZone({
            coords = location.coords,
            size = vector3(3.0, 3.0, 2.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    label = 'Enter ' .. location.label,
                    icon = 'fas fa-store',
                    distance = 2.0,
                    onSelect = function()
                        openShowroom(name)
                    end,
                },
            }
        })
    end
end)

local function openShowroom(locationName)
    local location = Config.PremiumDealership.Locations[locationName]
    if not location then return end

    showroomOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openShowroom',
        data = {
            locationName = locationName,
            locationLabel = location.label,
            category = location.category,
            categories = Config.PremiumDealership.Categories,
            testDriveDuration = Config.PremiumDealership.TestDriveDuration,
            tradeInMultiplier = Config.PremiumDealership.TradeInMultiplier,
            plateMaxLength = Config.PremiumDealership.PlateMaxLength,
            financeOptions = Config.PremiumDealership.FinanceOptions,
        }
    })
end

--- Preview vehicle (spawn frozen on display)
RegisterNUICallback('previewVehicle', function(data, cb)
    local location = Config.PremiumDealership.Locations[data.locationName]
    if not location then cb({ error = 'Invalid location' }) return end

    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteVehicle(previewVehicle)
    end

    local showcase = location.showcase
    QBox.Functions.SpawnVehicle(data.model, function(vehicle)
        previewVehicle = vehicle
        SetVehicleOnGroundProperly(vehicle)
        FreezeEntityPosition(vehicle, true)
        SetEntityCollision(vehicle, false)
        SetVehicleDoorsLocked(vehicle, 4)
        SetVehicleEngineOn(vehicle, false, true, false)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        Citizen.Wait(100)
        SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleColours(vehicle, math.random(0, 160), math.random(0, 160))

        -- Rotating showcase
        Citizen.CreateThread(function()
            local heading = 0.0
            while previewVehicle == vehicle and DoesEntityExist(vehicle) do
                Citizen.Wait(0)
                heading = heading + 0.3
                SetEntityHeading(vehicle, heading)
                SetEntityCoords(vehicle, showcase.coords.x, showcase.coords.y, showcase.coords.z, false, false, false, false)
            end
        end)
    end, showcase.coords, true)

    cb({ success = true })
end)

--- Stop preview
RegisterNUICallback('stopPreview', function(_, cb)
    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteVehicle(previewVehicle)
        previewVehicle = nil
    end
    cb({ success = true })
end)

--- Test drive
RegisterNUICallback('startTestDrive', function(data, cb)
    local location = Config.PremiumDealership.Locations[data.locationName]
    if not location then cb({ error = 'Invalid location' }) return end
    local spawn = location.spawn

    if testDriveVehicle and DoesEntityExist(testDriveVehicle) then
        DeleteVehicle(testDriveVehicle)
    end

    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteVehicle(previewVehicle)
        previewVehicle = nil
    end

    QBox.Functions.SpawnVehicle(data.model, function(vehicle)
        testDriveVehicle = vehicle
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleDirtLevel(vehicle, 0.0)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        SetVehicleFuelLevel(vehicle, 100.0)
        testDriveTimer = Config.PremiumDealership.TestDriveDuration

        Citizen.CreateThread(function()
            while testDriveVehicle and DoesEntityExist(testDriveVehicle) and testDriveTimer > 0 do
                Citizen.Wait(1000)
                testDriveTimer = testDriveTimer - 1
                SendNUIMessage({ action = 'testDriveTimer', time = testDriveTimer })
                if testDriveTimer <= 0 then
                    -- Return to showroom
                    DeleteVehicle(testDriveVehicle)
                    testDriveVehicle = nil
                    local ped = PlayerPedId()
                    SetEntityCoords(ped, location.coords.x, location.coords.y, location.coords.z - 2.0)
                    SetEntityHeading(ped, location.coords.heading or 0.0)
                    Wrappers.Notify('Test drive ended. Return to showroom.', 'info')
                end
            end
        end)
    end, spawn.coords, true)

    cb({ success = true })
end)

--- End test drive early
RegisterNUICallback('endTestDrive', function(_, cb)
    if testDriveVehicle and DoesEntityExist(testDriveVehicle) then
        DeleteVehicle(testDriveVehicle)
        testDriveVehicle = nil
    end
    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteVehicle(previewVehicle)
        previewVehicle = nil
    end
    cb({ success = true })
end)

--- Purchase a vehicle
RegisterNUICallback('purchaseVehicle', function(data, cb)
    local src = GetPlayerServerId(PlayerId())
    TriggerServerEvent('dealership:server:buyVehicle', {
        vehicleData = data.vehicleData,
        plate = data.plate,
        paymentType = data.paymentType,
        financeWeeks = data.financeWeeks,
        tradeInValue = data.tradeInValue or 0,
    })
    cb({ success = true })
end)

--- Get owned vehicles for trade-in
RegisterNUICallback('getOwnedVehicles', function(_, cb)
    QBox.Functions.TriggerCallback('dealership:server:getOwnedVehicles', function(vehicles)
        cb({ vehicles = vehicles or {} })
    end)
end)

--- Calc trade-in value
RegisterNUICallback('calcTradeIn', function(data, cb)
    QBox.Functions.TriggerCallback('dealership:server:calcTradeIn', function(value)
        cb({ value = value })
    end, data.plate)
end)

--- Check plate
RegisterNUICallback('checkPlate', function(data, cb)
    QBox.Functions.TriggerCallback('dealership:server:checkPlate', function(available)
        cb({ available = available })
    end, data.plate)
end)

--- Purchase complete
RegisterNetEvent('dealership:client:purchaseComplete', function(plate)
    SendNUIMessage({ action = 'purchaseComplete', plate = plate })
end)

--- Close showroom
RegisterNUICallback('closeShowroom', function(_, cb)
    showroomOpen = false
    SetNuiFocus(false, false)
    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteVehicle(previewVehicle)
        previewVehicle = nil
    end
    if testDriveVehicle and DoesEntityExist(testDriveVehicle) then
        DeleteVehicle(testDriveVehicle)
        testDriveVehicle = nil
    end
    cb({ success = true })
end)

--- Cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if showroomOpen then
            SetNuiFocus(false, false)
        end
        if previewVehicle and DoesEntityExist(previewVehicle) then
            DeleteVehicle(previewVehicle)
        end
        if testDriveVehicle and DoesEntityExist(testDriveVehicle) then
            DeleteVehicle(testDriveVehicle)
        end
    end
end)
