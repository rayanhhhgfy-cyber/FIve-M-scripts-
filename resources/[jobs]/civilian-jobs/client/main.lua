local busSpawned = false
local currentRoute = nil
local currentStop = 0

-- Spawn bus for bus driver job
RegisterCommand('busstart', function()
    local ped = PlayerPedId()
    local coords = Config.CivilianJobs.busDriver.vehicleSpawn
    local model = GetHashKey(Config.CivilianJobs.busDriver.busModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(100) end
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, 0.0, true, false)
    SetPedIntoVehicle(ped, veh, -1)
    busSpawned = true
    Wrappers.Notify('Bus spawned. Select a route:', 'info')
    local items = {}
    for _, r in ipairs(Config.CivilianJobs.busDriver.routes) do
        table.insert(items, { title = r.name, description = '$' .. r.pay .. ' | ' .. #r.stops .. ' stops', onSelect = function()
            currentRoute = r
            currentStop = 1
            SetNewWaypoint(r.stops[1].x, r.stops[1].y)
            Wrappers.Notify('Route started! Navigate to stop 1/' .. #r.stops, 'success')
        end })
    end
    Wrappers.ContextMenu({ id = 'bus_routes', title = 'Bus Routes', menuItems = items })
end)

-- Check for bus stop proximity
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if currentRoute and currentStop <= #currentRoute.stops then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                local coords = GetEntityCoords(veh)
                local stop = currentRoute.stops[currentStop]
                if #(coords - stop) < 15.0 then
                    Wrappers.Notify('Stop ' .. currentStop .. '/' .. #currentRoute.stops .. ' - press E to service', 'info')
                    if IsControlJustPressed(0, 38) then -- E
                        Wrappers.ProgressBar({ label = 'Servicing stop...', duration = 3000, onFinish = function()
                            TriggerServerEvent('civilianjobs:busCompleteStop', currentRoute.id, currentStop)
                            currentStop = currentStop + 1
                            if currentStop <= #currentRoute.stops then
                                SetNewWaypoint(currentRoute.stops[currentStop].x, currentRoute.stops[currentStop].y)
                            end
                        end })
                    end
                end
            end
        end
    end
end)

-- Garbage collector
RegisterCommand('garbagestart', function()
    local coords = Config.CivilianJobs.garbageCollector.vehicleSpawn
    local model = GetHashKey(Config.CivilianJobs.garbageCollector.truckModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(100) end
    local ped = PlayerPedId()
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, 0.0, true, false)
    SetPedIntoVehicle(ped, veh, -1)
    Wrappers.Notify('Garbage truck spawned! Drive to stops and service them.', 'info')
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local p = PlayerPedId()
        local veh = GetVehiclePedIsIn(p, false)
        if veh ~= 0 and GetEntityModel(veh) == GetHashKey(Config.CivilianJobs.garbageCollector.truckModel) then
            for i, stop in ipairs(Config.CivilianJobs.garbageCollector.stops) do
                if #(GetEntityCoords(veh) - stop) < 10.0 then
                    Wrappers.TextUI('Press E to collect garbage', 100)
                    if IsControlJustPressed(0, 38) then
                        Wrappers.ProgressBar({ label = 'Collecting garbage...', duration = 4000, onFinish = function()
                            TriggerServerEvent('civilianjobs:garbageCollect', i)
                        end })
                    end
                    break
                end
            end
        end
    end
end)

-- Mail carrier
RegisterCommand('mailstart', function()
    local coords = Config.CivilianJobs.mailCarrier.vehicleSpawn
    local model = GetHashKey(Config.CivilianJobs.mailCarrier.vanModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(100) end
    local ped = PlayerPedId()
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, 0.0, true, false)
    SetPedIntoVehicle(ped, veh, -1)
    local items = {}
    for _, r in ipairs(Config.CivilianJobs.mailCarrier.routes) do
        table.insert(items, { title = r.name, description = #r.deliveries .. ' deliveries, $' .. Config.CivilianJobs.mailCarrier.payPerDelivery .. '/ea', onSelect = function()
            currentRoute = r
            currentStop = 1
            SetNewWaypoint(r.deliveries[1].x, r.deliveries[1].y)
            Wrappers.Notify('Mail route started!', 'success')
        end })
    end
    Wrappers.ContextMenu({ id = 'mail_routes', title = 'Mail Routes', menuItems = items })
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if currentRoute and currentStop <= #currentRoute.deliveries then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local delivery = currentRoute.deliveries[currentStop]
            if #(coords - delivery) < 10.0 then
                Wrappers.TextUI('Press E to deliver mail', 100)
                if IsControlJustPressed(0, 38) then
                    Wrappers.ProgressBar({ label = 'Delivering mail...', duration = 3000, onFinish = function()
                        TriggerServerEvent('civilianjobs:mailDeliver', currentRoute.id, currentStop)
                        currentStop = currentStop + 1
                        if currentStop <= #currentRoute.deliveries then
                            SetNewWaypoint(currentRoute.deliveries[currentStop].x, currentRoute.deliveries[currentStop].y)
                        end
                    end })
                end
            end
        end
    end
end)

-- Tow truck
RegisterCommand('towstart', function()
    local coords = Config.CivilianJobs.towTruck.vehicleSpawn
    local model = GetHashKey(Config.CivilianJobs.towTruck.truckModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(100) end
    local ped = PlayerPedId()
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, 0.0, true, false)
    SetPedIntoVehicle(ped, veh, -1)
    Wrappers.Notify('Tow truck spawned! Wait for tow calls.', 'info')
end)

RegisterCommand('requesttow', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent('civilianjobs:requestTow', coords)
end)

RegisterNetEvent('civilianjobs:towCallNotification', function(callId, location, callerName)
    Wrappers.Notify('Tow call from ' .. callerName, 'warning')
    local input = Wrappers.InputDialog({ title = 'Tow Call from ' .. callerName, options = {
        { type = 'select', label = 'Accept?', options = { { value = 'yes', label = 'Accept' }, { value = 'no', label = 'Decline' } } },
    }})
    if input and input[1] == 'yes' then
        TriggerServerEvent('civilianjobs:acceptTow', callId)
    end
end)

RegisterNetEvent('civilianjobs:towGPS', function(location)
    SetNewWaypoint(location.x, location.y)
    Wrappers.Notify('Tow GPS set! Navigate to caller.', 'success')
end)

RegisterNetEvent('civilianjobs:routeDone', function()
    currentRoute = nil
    currentStop = 0
end)
