local isOnShift = false
local currentVehicle = nil
local activeFare = nil
local fareMeterThread = nil
local isHailing = false
local playerPed = PlayerPedId()

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function Notify(msg, type)
    lib.notify({ title = 'Taxi', description = msg, type = type or 'info' })
end

local function HasDriverLicense()
    return true
end

local function SpawnTaxi()
    if currentVehicle and DoesEntityExist(currentVehicle) then
        Notify('You already have a taxi out', 'error')
        return false
    end
    local model = Config.TaxiModels[math.random(#Config.TaxiModels)]
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        Notify('Invalid vehicle model', 'error')
        return false
    end
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if not HasModelLoaded(model) then
        Notify('Failed to load vehicle model', 'error')
        return false
    end
    currentVehicle = CreateVehicle(model, Config.Garage.x, Config.Garage.y, Config.Garage.z, Config.GarageHeading, true, false)
    SetVehicleNumberPlateText(currentVehicle, 'TAXI' .. tostring(math.random(100, 999)))
    SetVehicleColours(currentVehicle, 6, 6)
    TaskWarpPedIntoVehicle(playerPed, currentVehicle, -1)
    SetModelAsNoLongerNeeded(model)
    Notify('Taxi spawned, good luck!', 'success')
    return true
end

local function ReturnTaxi()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        Notify('No taxi to return', 'error')
        return
    end
    if not IsPedInVehicle(playerPed, currentVehicle, false) and GetPedInVehicleSeat(currentVehicle, -1) ~= playerPed then
        local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(currentVehicle))
        if dist > 50.0 then
            Notify('Taxi is too far away', 'error')
            return
        end
    end
    DeleteVehicle(currentVehicle)
    currentVehicle = nil
    Notify('Taxi returned', 'success')
end

local function StartShift()
    if isOnShift then
        Notify('You are already on shift', 'error')
        return
    end
    if not HasDriverLicense() then
        Notify('You need a drivers license', 'error')
        return
    end
    TriggerServerEvent('taxi:server:startShift')
end

local function EndShift()
    if not isOnShift then
        Notify('You are not on shift', 'error')
        return
    end
    if activeFare then
        Notify('Complete your current fare first', 'error')
        return
    end
    ReturnTaxi()
    TriggerServerEvent('taxi:server:endShift')
end

local function StartFareMeter(pickup, dest)
    if fareMeterThread then return end
    local startPos = GetEntityCoords(currentVehicle)
    local totalDistance = 0
    local currentFare = Config.BaseFare
    fareMeterThread = Citizen.CreateThread(function()
        while activeFare and DoesEntityExist(currentVehicle) do
            local vehPos = GetEntityCoords(currentVehicle)
            local distToDest = #(vehPos - dest)
            if distToDest < 20.0 then
                activeFare.destinationReached = true
                Notify('Destination reached! Fare: $' .. string.format('%.2f', currentFare), 'success')
                break
            end
            if totalDistance < Config.MaxDistance then
                totalDistance = totalDistance + 1
                if totalDistance % 1000 == 0 then
                    currentFare = currentFare + Config.MeterRate
                end
            end
            DrawText3D(vehPos.x, vehPos.y, vehPos.z + 1.5, 'Fare: $' .. string.format('%.2f', currentFare) .. ' | Distance: ' .. string.format('%.1f', totalDistance / 1000) .. 'km')
            Citizen.Wait(Config.MeterUpdateInterval)
        end
        if activeFare and not activeFare.destinationReached then
            currentFare = currentFare * 0.5
            Notify('Fare cancelled. Partial charge: $' .. string.format('%.2f', currentFare), 'warning')
        end
        if DoesEntityExist(currentVehicle) and IsPedInVehicle(playerPed, currentVehicle, false) then
            TriggerServerEvent('taxi:server:completeFare', currentFare, activeFare.passengerType)
        end
        activeFare = nil
        fareMeterThread = nil
    end)
end

local function AcceptTaxiCall(fareData)
    if not isOnShift or not currentVehicle or not DoesEntityExist(currentVehicle) then
        Notify('You need to be on shift with a taxi', 'error')
        return
    end
    if activeFare then
        Notify('You already have an active fare', 'error')
        return
    end
    activeFare = {
        pickup = fareData.pickup,
        destination = fareData.destination,
        passengerType = fareData.passengerType or 'npc',
        destinationReached = false
    }
    SetNewWaypoint(fareData.pickup.x, fareData.pickup.y)
    Notify('New fare! Pick up the passenger.', 'info')
    local pickupBlip = AddBlipForCoord(fareData.pickup.x, fareData.pickup.y, fareData.pickup.z)
    SetBlipSprite(pickupBlip, 280)
    SetBlipColour(pickupBlip, 5)
    SetBlipRoute(pickupBlip, true)
    SetBlipAsShortRange(pickupBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Pickup')
    EndTextCommandSetBlipName(pickupBlip)
    Citizen.CreateThread(function()
        while activeFare and not activeFare.destinationReached do
            Citizen.Wait(0)
            if DoesEntityExist(currentVehicle) then
                local vehPos = GetEntityCoords(currentVehicle)
                local distPickup = #(vehPos - fareData.pickup)
                if distPickup < 15.0 then
                    RemoveBlip(pickupBlip)
                    Notify('Passenger picked up! GPS set to destination.', 'success')
                    SetNewWaypoint(fareData.destination.x, fareData.destination.y)
                    local destBlip = AddBlipForCoord(fareData.destination.x, fareData.destination.y, fareData.destination.z)
                    SetBlipSprite(destBlip, 280)
                    SetBlipColour(destBlip, 2)
                    SetBlipRoute(destBlip, true)
                    SetBlipAsShortRange(destBlip, true)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentString('Destination')
                    EndTextCommandSetBlipName(destBlip)
                    StartFareMeter(fareData.pickup, fareData.destination)
                    Citizen.CreateThread(function()
                        while DoesBlipExist(destBlip) do Citizen.Wait(10) end
                        RemoveBlip(destBlip)
                    end)
                    break
                end
                DrawText3D(fareData.pickup.x, fareData.pickup.y, fareData.pickup.z + 1.0, '~y~Passenger~w~ (' .. string.format('%.0fm', distPickup) .. ')')
            end
        end
        RemoveBlip(pickupBlip)
    end)
end

local function HailTaxi()
    if isHailing then return end
    isHailing = true
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local closestTaxi = nil
    local closestDist = Config.HailRange + 1
    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local plate = GetVehicleNumberPlateText(veh)
            local vehPos = GetEntityCoords(veh)
            local dist = #(coords - vehPos)
            if dist < closestDist then
                closestDist = dist
                closestTaxi = veh
            end
        end
    end
    if closestTaxi and closestDist <= Config.HailRange then
        local driver = GetPedInVehicleSeat(closestTaxi, -1)
        if driver and driver ~= 0 and IsPedAPlayer(driver) then
            local netId = NetworkGetNetworkIdFromEntity(closestTaxi)
            TriggerServerEvent('taxi:server:hailTaxi', netId, coords)
            Notify('Hailing taxi...', 'info')
        else
            Notify('No available taxi nearby', 'error')
        end
    else
        Notify('No taxi in range', 'error')
    end
    isHailing = false
end

RegisterNetEvent('taxi:client:startShift', function()
    isOnShift = true
    if SpawnTaxi() then
        Notify('Shift started! Pick up passengers.', 'success')
    else
        isOnShift = false
        TriggerServerEvent('taxi:server:endShift')
    end
end)

RegisterNetEvent('taxi:client:endShift', function()
    isOnShift = false
    Notify('Shift ended', 'info')
end)

RegisterNetEvent('taxi:client:fareCall', function(fareData)
    AcceptTaxiCall(fareData)
end)

RegisterNetEvent('taxi:client:passengerHail', function(driverNetId, pickupCoords)
    local dest = Config.NPCFares[math.random(#Config.NPCFares)]
    AcceptTaxiCall({
        pickup = pickupCoords,
        destination = dest.coords,
        passengerType = 'player'
    })
end)

RegisterNetEvent('taxi:client:syncMeter', function(fare, dist)
    if activeFare then
        activeFare.currentFare = fare
    end
end)

RegisterNetEvent('taxi:client:forceEndShift', function()
    if activeFare then
        activeFare = nil
        if fareMeterThread then
            Citizen.StopThread(fareMeterThread)
            fareMeterThread = nil
        end
    end
    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
        currentVehicle = nil
    end
    isOnShift = false
    Notify('Your shift has been forcefully ended', 'error')
end)

Citizen.CreateThread(function()
    local depotZone = lib.zones.sphere({
        coords = Config.Garage,
        radius = 3.0,
        debug = false
    })
    exports.ox_target:addSphereZone({
        coords = Config.Garage,
        radius = 2.0,
        debug = false,
        options = {
            {
                name = 'taxi_start_shift',
                label = 'Start Taxi Shift',
                icon = 'fas fa-taxi',
                distance = 2.5,
                canInteract = function()
                    return not isOnShift
                end,
                onSelect = function()
                    StartShift()
                end
            },
            {
                name = 'taxi_end_shift',
                label = 'End Taxi Shift',
                icon = 'fas fa-stop-circle',
                distance = 2.5,
                canInteract = function()
                    return isOnShift
                end,
                onSelect = function()
                    EndShift()
                end
            },
            {
                name = 'taxi_return_vehicle',
                label = 'Return Taxi',
                icon = 'fas fa-undo',
                distance = 2.5,
                canInteract = function()
                    return isOnShift and currentVehicle and DoesEntityExist(currentVehicle)
                end,
                onSelect = function()
                    ReturnTaxi()
                end
            },
            {
                name = 'taxi_spawn_vehicle',
                label = 'Spawn Taxi',
                icon = 'fas fa-car',
                distance = 2.5,
                canInteract = function()
                    return isOnShift and (not currentVehicle or not DoesEntityExist(currentVehicle))
                end,
                onSelect = function()
                    SpawnTaxi()
                end
            }
        }
    })
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, Config.HailKey) and not IsPedInAnyVehicle(playerPed, false) then
            HailTaxi()
        end
        if activeFare and DoesEntityExist(currentVehicle) and IsPedInVehicle(playerPed, currentVehicle, false) then
            local speed = GetEntitySpeed(currentVehicle) * 3.6
            local fuel = GetVehicleFuelLevel(currentVehicle)
            local vehPos = GetEntityCoords(currentVehicle)
            DrawText3D(vehPos.x, vehPos.y, vehPos.z + 2.5, 'Speed: ' .. string.format('%.0f', speed) .. ' km/h | Fuel: ' .. string.format('%.0f', fuel) .. '%')
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if currentVehicle and DoesEntityExist(currentVehicle) then
            DeleteVehicle(currentVehicle)
            currentVehicle = nil
        end
        if fareMeterThread then
            Citizen.StopThread(fareMeterThread)
            fareMeterThread = nil
        end
    end
end)
