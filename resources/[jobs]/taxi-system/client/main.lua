local QBox = exports['qbx-core']:GetCoreObject()
local isTaxiDriver = false
local activeFare = nil
local fareStart = nil
local distanceTraveled = 0
local lastPos = nil
local crashes = 0
local speedViolations = 0
local smoothScore = 100
local lastSpeed = 0

local function isInTaxiJob()
    local job = QBox.Functions.GetPlayerData().job
    return job and job.name == Config.Taxi.driverJob
end

RegisterCommand('taxiui', function()
    if isInTaxiJob() then TriggerServerEvent('taxi:toggleDuty') end
end, false)
RegisterKeyMapping('taxiui', 'Toggle Taxi Duty', 'keyboard', 'u')

RegisterNetEvent('taxi:dutyToggled', function(onDuty)
    isTaxiDriver = onDuty
    if onDuty then
        Wrappers.Notify('You are now ON DUTY. Check your phone for fares.', 'success')
    else
        if activeFare then
            TriggerServerEvent('taxi:endRide')
        end
        isTaxiDriver = false
        Wrappers.Notify('You are now OFF DUTY', 'info')
    end
end)

RegisterNetEvent('taxi:npcFareCreated', function(fareId, route)
    if not isTaxiDriver then return end
    activeFare = fareId
    fareStart = os.time()
    distanceTraveled = 0
    lastPos = GetEntityCoords(PlayerPedId())
    crashes = 0
    speedViolations = 0
    smoothScore = 100
    lastSpeed = 0

    SetNewWaypoint(route.pickup.coords.x, route.pickup.coords.y)
    Wrappers.Notify('New fare: Pick up at ' .. route.pickup.name, 'info')

    Citizen.CreateThread(function()
        local blip = AddBlipForCoord(route.pickup.coords.x, route.pickup.coords.y, route.pickup.coords.z)
        SetBlipSprite(blip, 198)
        SetBlipColour(blip, 5)
        SetBlipScale(blip, 1.2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Taxi Pickup')
        EndTextCommandSetBlipName(blip)

        while activeFare == fareId do
            Citizen.Wait(1000)
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                local pos = GetEntityCoords(veh)
                if lastPos then
                    local dist = #(pos - lastPos)
                    distanceTraveled = distanceTraveled + dist
                end
                lastPos = pos
                local speed = GetEntitySpeed(veh) * 2.23694
                if speed > Config.Taxi.maxSpeedLimit then
                    speedViolations = speedViolations + 1
                end
                local accel = math.abs(speed - lastSpeed)
                if accel > Config.Taxi.smoothAccelDelta then
                    smoothScore = math.max(0, smoothScore - 2)
                end
                lastSpeed = speed
                local miles = distanceTraveled / 1609.34
                local fare = Config.Taxi.baseFare + (miles * Config.Taxi.perMileRate)
                TriggerServerEvent('taxi:updateFarePos', fareId, fare, miles)
            end
            local pickupDist = #(GetEntityCoords(PlayerPedId()) - route.pickup.coords)
            if pickupDist < 15.0 then
                Wrappers.Notify('Passenger picked up. Navigate to ' .. route.dropoff.name, 'success')
                SetNewWaypoint(route.dropoff.coords.x, route.dropoff.coords.y)
                RemoveBlip(blip)
                local destBlip = AddBlipForCoord(route.dropoff.coords.x, route.dropoff.coords.y, route.dropoff.coords.z)
                SetBlipSprite(destBlip, 198)
                SetBlipColour(destBlip, 2)
                SetBlipScale(destBlip, 1.2)
                SetBlipAsShortRange(destBlip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString('Drop-off')
                EndTextCommandSetBlipName(destBlip)

                while activeFare == fareId do
                    Citizen.Wait(100)
                    local destDist = #(GetEntityCoords(PlayerPedId()) - route.dropoff.coords)
                    if destDist < 15.0 then
                        RemoveBlip(destBlip)
                        TriggerServerEvent('taxi:completeNpcFare', fareId)
                        return
                    end
                end
            end
        end
        RemoveBlip(blip)
    end)
end)

RegisterNetEvent('taxi:fareCompleted', function(fareTotal, tipAmount, quality)
    activeFare = nil
    local crashPenalty = math.max(0, 5 - math.floor(crashes / 1))
    local speedPenalty = math.max(0, 5 - math.floor(speedViolations / 3))
    local smoothRating = math.min(5, math.floor(smoothScore / 20))
    local overallQuality = math.max(1, math.floor((crashPenalty + speedPenalty + smoothRating) / 3))

    local msg = 'Fare completed: $' .. string.format('%.2f', fareTotal)
    if tipAmount > 0 then msg = msg .. ' + $' .. string.format('%.2f', tipAmount) .. ' tip' end
    msg = msg .. ' | Quality: ' .. overallQuality .. '/5'
    if quality then msg = msg .. ' | ' .. quality end
    Wrappers.Notify(msg, 'success')
end)

RegisterNetEvent('taxi:crashDetected', function()
    if activeFare then
        crashes = crashes + 1
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local speed = GetEntitySpeed(veh) * 2.23694
            if speed > 5.0 then
                local isCrashed = IsEntityCollidedWithAnything(ped) or IsEntityCollidedWithAnything(veh)
                if isCrashed then
                    TriggerServerEvent('taxi:crashDetected')
                    Citizen.Wait(1000)
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    for _, loc in ipairs(Config.Taxi.dispatchLocations) do
        exports.ox_target:addBoxZone({
            coords = loc.coords,
            size = vector3(3.0, 3.0, 2.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    label = 'Taxi Stand - ' .. loc.name,
                    icon = 'fas fa-taxi',
                    distance = 2.5,
                    onSelect = function()
                        if isTaxiDriver then
                            Wrappers.Notify('Waiting at ' .. loc.name, 'info')
                        else
                            TriggerServerEvent('taxi:requestRide')
                        end
                    end,
                },
            },
        })
    end
end)
