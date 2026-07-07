local fuelLevels = {}
local isRefueling = false
local currentFuel = 0
local fuelTimer = 0
local lowFuelNotified = false
local gasStationJob = false
local assignedPump = nil
local jobBlip = nil

Citizen.CreateThread(function()
    for _, station in ipairs(Config.Fuel.Stations) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, 361)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 4)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Locale('fuel', 'blip_name') or 'Gas Station')
        EndTextCommandSetBlipName(blip)
    end

    local jobBlipCoord = Config.Fuel.Stations[1].coords
    jobBlip = AddBlipForCoord(jobBlipCoord.x, jobBlipCoord.y, jobBlipCoord.z)
    SetBlipSprite(jobBlip, 525)
    SetBlipScale(jobBlip, 0.7)
    SetBlipColour(jobBlip, 5)
    SetBlipAsShortRange(jobBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Locale('fuel', 'job_blip') or 'Gas Station Job')
    EndTextCommandSetBlipName(jobBlip)
end)

Citizen.CreateThread(function()
    for _, station in ipairs(Config.Fuel.Stations) do
        for _, pump in ipairs(station.pumps) do
            exports.ox_target:addBoxZone({
                coords = pump,
                size = vec3(1.2, 1.2, 1.0),
                rotation = 0,
                debug = false,
                options = {
                    {
                        icon = Config.Fuel.TargetOptions.pump.icon,
                        label = Config.Fuel.TargetOptions.pump.label,
                        distance = Config.Fuel.TargetOptions.pump.distance,
                        canInteract = function()
                            return not isRefueling
                        end,
                        onSelect = function()
                            if Config.Fuel.JobOnly and not gasStationJob then
                                Wrappers.Notify(Locale('fuel', 'job_only'), 'error')
                                return
                            end
                            StartRefuel()
                        end
                    }
                }
            })
        end
    end

    local jobCoord = Config.Fuel.Stations[1].coords
    exports.ox_target:addBoxZone({
        coords = jobCoord,
        size = vec3(2.0, 2.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            {
                icon = Config.Fuel.TargetOptions.job.icon,
                label = Config.Fuel.TargetOptions.job.label,
                distance = Config.Fuel.TargetOptions.job.distance,
                onSelect = function()
                    ToggleGasStationJob()
                end
            }
        }
    })
end)

local function StartRefuel()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        vehicle = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 70)
        if vehicle == 0 then
            Wrappers.Notify(Locale('fuel', 'no_vehicle_nearby') or 'No vehicle nearby', 'error')
            return
        end
    end

    local fuelLevel = GetFuelLevel(vehicle)
    if fuelLevel >= Config.Fuel.MaxFuel then
        Wrappers.Notify(Locale('fuel', 'full') or 'Tank is already full', 'info')
        return
    end

    isRefueling = true
    local nozzle = CreateObject(GetHashKey(Config.Fuel.NozzleModel), GetEntityCoords(ped), true, false, false)
    AttachEntityToEntity(nozzle, ped, GetPedBoneIndex(ped, 60309), 0.15, 0.1, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

    local vehicleCoords = GetEntityCoords(vehicle)
    local fuelCapPos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 0.5, 0.3)

    local success = lib.progressBar({
        duration = math.ceil((Config.Fuel.MaxFuel - fuelLevel) / Config.Fuel.RefillSpeed) * 100,
        label = Locale('fuel', 'refueling') or 'Refueling...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        allowRagdoll = false,
        anim = {
            dict = 'timetable@gardener@filling_can',
            clip = 'gar_ig_5_filling_can',
            flag = 50
        }
    })

    if nozzle ~= 0 then DeleteObject(nozzle) end

    if success then
        SetFuelLevel(vehicle, Config.Fuel.MaxFuel)
        currentFuel = Config.Fuel.MaxFuel
        local cost = Config.Fuel.MaxFuel * Config.Fuel.Prices.regular
        TriggerServerEvent('fuel:purchase', cost)
        Wrappers.Notify(Locale('fuel', 'refuel_complete', math.floor(cost * 100) / 100) or string.format('Refueled - $%.2f', cost), 'success')
    else
        Wrappers.Notify(Locale('fuel', 'cancelled') or 'Refuel cancelled', 'error')
    end

    isRefueling = false
end

local function GetFuelLevel(vehicle)
    local vehState = Entity(vehicle).state
    local fuel = vehState.fuel
    if fuel == nil then
        local model = GetEntityModel(vehicle)
        local tankSize = GetVehicleHandlingFloat(vehicle, 'CAdvancedFlags', 'PetrolTankVolume')
        if tankSize <= 0 then tankSize = Config.Fuel.MaxFuel end
        fuel = tankSize
        TriggerServerEvent('fuel:requestLevel', VehToNet(vehicle))
    end
    return fuel or Config.Fuel.MaxFuel
end

local function SetFuelLevel(vehicle, level)
    level = math.max(0, math.min(level, Config.Fuel.MaxFuel))
    Entity(vehicle).state:set('fuel', level, true)
    currentFuel = level
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            local speed = GetEntitySpeed(vehicle) * 3.6
            local consumption = 0.0
            local rpm = GetVehicleCurrentRpm(vehicle)
            local gear = GetVehicleHandbrake(vehicle)

            if speed > 0 then
                consumption = (speed / 500) + (rpm * 0.01)
            end

            if GetVehicleEngineHealth(vehicle) > 0 then
                local fuel = GetFuelLevel(vehicle)
                if fuel > 0 then
                    local newFuel = fuel - consumption
                    SetFuelLevel(vehicle, newFuel)
                    if newFuel < 15 and not lowFuelNotified then
                        lowFuelNotified = true
                        Wrappers.Notify(Locale('fuel', 'low_fuel') or 'Low fuel! Refuel soon.', 'warning')
                    elseif newFuel >= 15 then
                        lowFuelNotified = false
                    end
                else
                    SetVehicleEngineOn(vehicle, false, true, true)
                    Wrappers.Notify(Locale('fuel', 'empty') or 'Out of fuel!', 'error')
                end
            end
        else
            lowFuelNotified = false
        end
    end
end)

local function ToggleGasStationJob()
    if not gasStationJob then
        TriggerServerEvent('fuel:startJob')
        gasStationJob = true
        assignedPump = nil
        Wrappers.Notify(Locale('fuel', 'job_started') or 'Gas station job started!', 'success')
        StartAssignedPumpTimer()
    else
        TriggerServerEvent('fuel:stopJob')
        gasStationJob = false
        assignedPump = nil
        if jobBlip then
            RemoveBlip(jobBlip)
            jobBlip = nil
        end
        Wrappers.Notify(Locale('fuel', 'job_ended') or 'Gas station job ended.', 'info')
    end
end

local function StartAssignedPumpTimer()
    Citizen.CreateThread(function()
        while gasStationJob do
            Citizen.Wait(120000)
            if gasStationJob then
                TriggerServerEvent('fuel:jobPayment')
                local station = Config.Fuel.Stations[1]
                local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
                SetBlipSprite(blip, 361)
                SetBlipColour(blip, 2)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(Locale('fuel', 'job_payment') or 'Job Payment')
                EndTextCommandSetBlipName(blip)
                Citizen.Wait(5000)
                RemoveBlip(blip)
            end
        end
    end)
end

RegisterNetEvent('fuel:setLevel', function(netId, level)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        Entity(vehicle).state:set('fuel', level, true)
    end
end)

RegisterNetEvent('fuel:jobStatus', function(active)
    gasStationJob = active
    if not active then
        assignedPump = nil
        if jobBlip then
            RemoveBlip(jobBlip)
            jobBlip = nil
        end
        Wrappers.Notify(Locale('fuel', 'job_ended') or 'Gas station job ended.', 'info')
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if jobBlip then
            RemoveBlip(jobBlip)
        end
    end
end)
