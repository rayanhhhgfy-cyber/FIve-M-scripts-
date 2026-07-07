local isOnJob = false
local currentStop = 1
local currentVehicle = nil
local isBusy = false
local jobStartTime = 0
local packagesDelivered = 0
local maxPackages = 4

local function spawnVehicle()
    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
    end

    local model = joaat(Config.VehicleModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(100)
    end

    currentVehicle = CreateVehicle(model, Config.Spawn.x, Config.Spawn.y, Config.Spawn.z, 0.0, true, false)
    SetVehicleNumberPlateText(currentVehicle, 'DELIVERY')
    TaskWarpPedIntoVehicle(cache.ped, currentVehicle, -1)
    SetModelAsNoLongerNeeded(model)
end

local function setRouteGPS()
    ClearGpsMultiRoute()
    SetGpsMultiRoute(true)
    StartGpsMultiRoute(6, true, true)
    for _, coord in ipairs(Config.DeliveryLocations) do
        AddPointToGpsMultiRoute(coord.x, coord.y, coord.z)
    end
    AddPointToGpsMultiRoute(Config.Depot.x, Config.Depot.y, Config.Depot.z)
    SetGpsMultiRoute(false)
end

local function startJob()
    if isOnJob then
        return lib.notify({ title = 'Already Working', description = 'Return to depot for more packages.', type = 'error' })
    end

    isOnJob = true
    currentStop = 1
    packagesDelivered = 0
    jobStartTime = GetGameTimer()
    spawnVehicle()
    setRouteGPS()
    TriggerServerEvent('delivery:startJob')

    lib.notify({
        title = 'Delivery Job',
        description = 'Collect packages from the depot and deliver them all! Return for more after each round.',
        type = 'info',
        duration = 5000,
    })
end

local function collectPackages()
    if isBusy then return end
    isBusy = true

    local success = lib.progressCircle({
        duration = Config.PackageCollectTime,
        position = 'bottom',
        label = 'Loading packages...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        anim = {
            dict = 'random@domestic',
            clip = 'pickup_low',
            flags = 49,
        },
    })

    if success then
        packagesDelivered = 0
        maxPackages = 4
        lib.notify({ title = 'Packages Loaded', description = 'Deliver ' .. maxPackages .. ' packages to the marked locations!', type = 'success' })
        setRouteGPS()
    end

    isBusy = false
end

local function deliverPackage()
    if isBusy then return end
    isBusy = true

    local coords = GetEntityCoords(cache.ped)
    local stopCoords = Config.DeliveryLocations[currentStop]

    if #(coords - stopCoords) > 5.0 then
        isBusy = false
        return lib.notify({ title = 'Too Far', description = 'Get closer to the delivery point.', type = 'error' })
    end

    TaskTurnPedToFaceCoord(cache.ped, stopCoords.x, stopCoords.y, 500)

    local success = lib.progressCircle({
        duration = Config.DeliveryTime,
        position = 'bottom',
        label = 'Delivering package...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        anim = {
            dict = 'anim@heists@box_carry@',
            clip = 'idle',
            flags = 49,
        },
    })

    if success then
        packagesDelivered = packagesDelivered + 1
        currentStop = currentStop + 1

        TriggerServerEvent('delivery:deliverPackage', currentStop - 1)

        if currentStop > #Config.DeliveryLocations or packagesDelivered >= maxPackages then
            lib.notify({ title = 'Round Complete', description = 'Return to depot for more packages!', type = 'success' })
            ClearGpsMultiRoute()
            SetNewWaypoint(Config.Depot.x, Config.Depot.y)

            local elapsed = (GetGameTimer() - jobStartTime) / 1000
            local bonus = false
            if elapsed < Config.BonusTime then
                bonus = true
                TriggerServerEvent('delivery:bonusPayment')
                lib.notify({ title = 'Speed Bonus!', description = '+$' .. Config.BonusAmount, type = 'success' })
            end

            isOnJob = false
            TriggerServerEvent('delivery:completeRoute')
        else
            lib.notify({ title = 'Package Delivered', description = packagesDelivered .. '/' .. maxPackages .. ' delivered.', type = 'success' })
        end
    end

    isBusy = false
end

local function finishJob()
    if isOnJob then
        return lib.notify({ title = 'Still Working', description = 'Deliver remaining packages first.', type = 'error' })
    end

    local coords = GetEntityCoords(cache.ped)
    if #(coords - Config.Depot) > 10.0 then
        return lib.notify({ title = 'Wrong Location', description = 'Return to the depot.', type = 'error' })
    end

    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
        currentVehicle = nil
    end

    lib.notify({ title = 'Job Complete', description = 'Start a new shift when ready!', type = 'success' })
    currentStop = 1
    packagesDelivered = 0
end

Citizen.CreateThread(function()
    while true do
        if isOnJob and not isBusy then
            Citizen.Wait(200)
            local coords = GetEntityCoords(cache.ped)

            if currentStop <= #Config.DeliveryLocations and packagesDelivered < maxPackages then
                local target = Config.DeliveryLocations[currentStop]
                if #(coords - target) < 5.0 then
                    lib.showTextUI('[E] Deliver Package')
                    if IsControlJustPressed(0, 38) then
                        deliverPackage()
                    end
                else
                    lib.hideTextUI()
                end
            end
        else
            Citizen.Wait(500)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        if not isOnJob then
            Citizen.Wait(200)
            local coords = GetEntityCoords(cache.ped)
            if #(coords - Config.Depot) < 8.0 then
                lib.showTextUI('[E] Collect Packages')
                if IsControlJustPressed(0, 38) then
                    collectPackages()
                end
            else
                lib.hideTextUI()
            end
        else
            Citizen.Wait(500)
        end
    end
end)

local depotZone = lib.target.addZone({
    coords = Config.Depot,
    size = vec3(4.0, 4.0, 2.0),
    debug = false,
    options = {
        {
            name = 'start_delivery',
            label = 'Start Delivery Shift',
            onSelect = startJob,
            icon = 'fas fa-box',
            canInteract = function()
                return not isOnJob
            end,
        },
        {
            name = 'finish_delivery',
            label = 'Finish Shift & Park Vehicle',
            onSelect = finishJob,
            icon = 'fas fa-check',
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
