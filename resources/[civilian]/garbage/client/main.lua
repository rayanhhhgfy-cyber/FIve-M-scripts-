local isOnJob = false
local currentStop = 1
local currentVehicle = nil
local isBusy = false

local function spawnTruck()
    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
    end

    local model = joaat(Config.TruckModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(100)
    end

    currentVehicle = CreateVehicle(model, Config.TruckSpawn.x, Config.TruckSpawn.y, Config.TruckSpawn.z, 0.0, true, false)
    SetVehicleNumberPlateText(currentVehicle, 'GARBAGE')
    TaskWarpPedIntoVehicle(cache.ped, currentVehicle, -1)
    SetModelAsNoLongerNeeded(model)
end

local function startJob()
    if isOnJob then
        return lib.notify({ title = 'Already Working', description = 'Finish your current route first.', type = 'error' })
    end

    isOnJob = true
    currentStop = 1
    spawnTruck()
    TriggerServerEvent('garbage:startJob')

    lib.notify({ title = 'Garbage Collection', description = 'Drive to the trash cans and press E to collect. Head to the landfill when done!', type = 'info', duration = 5000 })

    SetGpsMultiRoute(true)
    StartGpsMultiRoute(6, true, true)
    for _, coord in ipairs(Config.Route) do
        AddPointToGpsMultiRoute(coord.x, coord.y, coord.z)
    end
    AddPointToGpsMultiRoute(Config.Landfill.x, Config.Landfill.y, Config.Landfill.z)
    SetGpsMultiRoute(false)
end

local function collectTrash()
    if isBusy then return end
    isBusy = true

    TaskTurnPedToFaceCoord(cache.ped, Config.Route[currentStop].x, Config.Route[currentStop].y, 500)

    local success = lib.progressCircle({
        duration = Config.CollectTime,
        position = 'bottom',
        label = 'Collecting trash...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        anim = {
            dict = 'amb@prop_human_movie_bulb@base',
            clip = 'base',
            flags = 49,
        },
    })

    if success then
        currentStop = currentStop + 1
        if currentStop > #Config.Route then
            lib.notify({ title = 'Route Complete', description = 'Head to the landfill to drop off!', type = 'success' })
            ClearGpsMultiRoute()
            SetNewWaypoint(Config.Landfill.x, Config.Landfill.y)
        else
            lib.notify({ title = 'Collected', description = 'Move to the next trash can.', type = 'success' })
        end
    end

    isBusy = false
end

local function finishJob()
    if isBusy then return end

    if currentStop <= #Config.Route then
        return lib.notify({ title = 'Incomplete', description = 'Collect all trash first!', type = 'error' })
    end

    local coords = GetEntityCoords(cache.ped)
    if #(coords - Config.Landfill) > 10.0 then
        return lib.notify({ title = 'Wrong Location', description = 'Go to the landfill to finish.', type = 'error' })
    end

    isBusy = true

    local success = lib.progressCircle({
        duration = 4000,
        position = 'bottom',
        label = 'Dumping trash...',
        useWhileDead = false,
        canCancel = false,
        disableMovement = true,
        disableCarMovement = true,
        anim = {
            dict = 'amb@prop_human_movie_bulb@base',
            clip = 'base',
            flags = 49,
        },
    })

    if success then
        isOnJob = false
        currentStop = 1
        TriggerServerEvent('garbage:completeJob')
        ClearGpsMultiRoute()
        lib.notify({ title = 'Job Complete', description = 'You earned $' .. Config.PaymentPerRoute, type = 'success' })
        if currentVehicle and DoesEntityExist(currentVehicle) then
            DeleteVehicle(currentVehicle)
            currentVehicle = nil
        end
    end

    isBusy = false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isOnJob and not isBusy then
            local coords = GetEntityCoords(cache.ped)

            if currentStop <= #Config.Route then
                local target = Config.Route[currentStop]
                if #(coords - target) < 3.0 then
                    lib.showTextUI('[E] Collect Trash')
                    if IsControlJustPressed(0, 38) then
                        collectTrash()
                    end
                else
                    lib.hideTextUI()
                end
            end

            if #(coords - Config.Landfill) < 15.0 then
                lib.showTextUI('[E] Drop Off Trash')
                if IsControlJustPressed(0, 38) then
                    finishJob()
                end
            end
        else
            Citizen.Wait(500)
        end
    end
end)

local depotZone = lib.target.addZone({
    coords = Config.Depot,
    size = vec3(3.0, 3.0, 2.0),
    debug = false,
    options = {
        {
            name = 'start_garbage',
            label = 'Start Garbage Job',
            onSelect = startJob,
            icon = 'fas fa-trash',
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
