local isOnJob = false
local currentStop = 1
local currentVehicle = nil
local isBusy = false
local routeCompleted = 0
local wageTimer = 0

local function spawnBus()
    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
    end

    local model = joaat(Config.BusModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(100)
    end

    currentVehicle = CreateVehicle(model, Config.Spawn.x, Config.Spawn.y, Config.Spawn.z, 0.0, true, false)
    SetVehicleNumberPlateText(currentVehicle, 'BUS ' .. math.random(100, 999))
    TaskWarpPedIntoVehicle(cache.ped, currentVehicle, -1)
    SetModelAsNoLongerNeeded(model)
end

local function setBusRouteGPS()
    ClearGpsMultiRoute()
    SetGpsMultiRoute(true)
    StartGpsMultiRoute(6, true, true)
    for i = 1, #Config.Stops do
        AddPointToGpsMultiRoute(Config.Stops[i].x, Config.Stops[i].y, Config.Stops[i].z)
    end
    AddPointToGpsMultiRoute(Config.Depot.x, Config.Depot.y, Config.Depot.z)
    SetGpsMultiRoute(false)
end

local function openBusDoors()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then return end

    if GetVehicleDoorAngleRatio(currentVehicle, 2) > 0.1 then return end

    SetVehicleDoorOpen(currentVehicle, 2, false, false)
    SetVehicleDoorOpen(currentVehicle, 3, false, false)
end

local function closeBusDoors()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then return end

    SetVehicleDoorShut(currentVehicle, 2, false)
    SetVehicleDoorShut(currentVehicle, 3, false)
end

local function startJob()
    if isOnJob then
        return lib.notify({ title = 'Already Working', description = 'Finish your route first.', type = 'error' })
    end

    isOnJob = true
    currentStop = 1
    routeCompleted = 0
    wageTimer = GetGameTimer()
    spawnBus()
    setBusRouteGPS()
    TriggerServerEvent('bus:startJob')

    lib.notify({
        title = 'Bus Driver',
        description = 'Follow the route and stop at each bus stop. Open doors to let passengers on/off. You earn $' .. Config.HourlyWage .. '/hour!',
        type = 'info',
        duration = 7000,
    })
end

local function serviceStop()
    if isBusy then return end

    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        return lib.notify({ title = 'No Bus', description = 'Get back in your bus.', type = 'error' })
    end

    local playerVehicle = GetVehiclePedIsIn(cache.ped, false)
    if playerVehicle ~= currentVehicle then
        return lib.notify({ title = 'Wrong Vehicle', description = 'Get in the bus.', type = 'error' })
    end

    if GetPedInVehicleSeat(currentVehicle, -1) ~= cache.ped then
        return lib.notify({ title = 'Driver Seat', description = 'Sit in the driver seat.', type = 'error' })
    end

    isBusy = true

    openBusDoors()

    local success = lib.progressCircle({
        duration = Config.StopWaitTime,
        position = 'bottom',
        label = 'Passengers boarding...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = false,
        disableCarMovement = true,
    })

    closeBusDoors()

    if success then
        currentStop = currentStop + 1
        routeCompleted = routeCompleted + 1

        if currentStop > #Config.Stops then
            lib.notify({
                title = 'Route Complete',
                description = 'Return to the depot to finish your shift!',
                type = 'success',
            })
            ClearGpsMultiRoute()
            SetNewWaypoint(Config.Depot.x, Config.Depot.y)
        else
            lib.notify({
                title = 'Stop ' .. (currentStop - 1) .. '/' .. #Config.Stops,
                description = 'Proceed to the next stop.',
                type = 'success',
            })
        end
    else
        lib.notify({ title = 'Cancelled', description = 'Boarding cancelled.', type = 'error' })
    end

    isBusy = false
end

local function finishJob()
    if isBusy then return end

    if currentStop <= #Config.Stops then
        return lib.notify({ title = 'Route Incomplete', description = 'Service all stops before returning.', type = 'error' })
    end

    local coords = GetEntityCoords(cache.ped)
    if #(coords - Config.Depot) > 10.0 then
        return lib.notify({ title = 'Wrong Location', description = 'Return to the bus depot.', type = 'error' })
    end

    isBusy = true

    local success = lib.progressCircle({
        duration = 3000,
        position = 'bottom',
        label = 'Parking bus...',
        useWhileDead = false,
        canCancel = false,
        disableMovement = true,
        disableCarMovement = true,
    })

    if success then
        isOnJob = false
        currentStop = 1

        local wageCycles = math.floor((GetGameTimer() - wageTimer) / Config.WageInterval)
        local totalPay = wageCycles * Config.HourlyWage

        if totalPay > 0 then
            TriggerServerEvent('bus:payWage', totalPay)
        end

        TriggerServerEvent('bus:completeRoute', routeCompleted)
        ClearGpsMultiRoute()

        if currentVehicle and DoesEntityExist(currentVehicle) then
            DeleteVehicle(currentVehicle)
            currentVehicle = nil
        end

        lib.notify({
            title = 'Shift Complete',
            description = totalPay > 0 and 'You earned $' .. totalPay .. ' this shift!' or 'Shift logged.',
            type = 'success',
        })
    end

    isBusy = false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isOnJob and not isBusy then
            local coords = GetEntityCoords(cache.ped)

            if currentStop <= #Config.Stops then
                local target = Config.Stops[currentStop]
                if #(coords - target) < 10.0 then
                    lib.showTextUI('[E] Service Bus Stop')
                    if IsControlJustPressed(0, 38) then
                        serviceStop()
                    end
                else
                    lib.hideTextUI()
                end
            end

            if currentStop > #Config.Stops and #(coords - Config.Depot) < 10.0 then
                lib.showTextUI('[E] Park Bus & Finish Shift')
                if IsControlJustPressed(0, 38) then
                    finishJob()
                end
            end
        else
            Citizen.Wait(500)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        if isOnJob then
            local elapsed = GetGameTimer() - wageTimer
            local cycles = math.floor(elapsed / Config.WageInterval)
            if cycles > 0 and currentStop <= #Config.Stops then
                local wage = cycles * Config.HourlyWage
                TriggerServerEvent('bus:payWage', wage)
                lib.notify({
                    title = 'Hourly Wage',
                    description = '+$' .. wage,
                    type = 'success',
                })
                wageTimer = wageTimer + (cycles * Config.WageInterval)
            end
        end
    end
end)

local depotZone = lib.target.addZone({
    coords = Config.Depot,
    size = vec3(5.0, 5.0, 3.0),
    debug = false,
    options = {
        {
            name = 'start_bus',
            label = 'Start Bus Shift',
            onSelect = startJob,
            icon = 'fas fa-bus',
            canInteract = function()
                return not isOnJob
            end,
        }
    }
})

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if depotZone then
            lib.target.removeZone(depotZone)
        end
    end
end)
